-- ═══════════════════════════════════════════════════════════════════════════════
--  Noob Incremental · FOOTBALL AUTO  —  clean build v2  ·  @Benefit
--
--  One toggle → smart overnight football farm. Auto-kicks the ball for Goals, and:
--    • RANK & TROPHY are ALWAYS the priority. If one is affordable it buys it at once.
--    • If it isn't affordable yet, it SAVES for it — stops spending on everything else
--      and just banks Goals (you stay AFK at the ball) until it can buy it.
--    • Only if a target is a long way off (no buy after ~5 min of saving) does it briefly
--      BUILD income (buy useful talents) then go back to saving — so it never hoards
--      forever for something unreachable, and never freezes.
--    • NEVER buys your excluded/"trash" talents (loaded from your saved cfg).
--  Affordability is judged by result (fire once → did the level rise?), never by fragile
--  big-number math. "Not enough" popups are hidden, and reloading replaces the old copy.
-- ═══════════════════════════════════════════════════════════════════════════════

local Players = game:GetService("Players")
local RS      = game:GetService("ReplicatedStorage")
local UIS     = game:GetService("UserInputService")
local LP      = Players.LocalPlayer

-- ── single-instance guard ──────────────────────────────────────────────────────
_G.__NIF = (_G.__NIF or 0) + 1
local GEN = _G.__NIF
local function alive() return _G.__NIF == GEN end
pcall(function() if _G.__NIF_gui then _G.__NIF_gui:Destroy() end end)
local function loop(sec, fn)
    task.spawn(function() while alive() do pcall(fn); task.wait(sec) end end)
end

-- ── anti-AFK ────────────────────────────────────────────────────────────────────
pcall(function()
    local VU = game:GetService("VirtualUser")
    LP.Idled:Connect(function() VU:CaptureController(); VU:ClickButton2(Vector2.new()) end)
end)

-- ── wait for networking ─────────────────────────────────────────────────────────
local MR, GET
do
    local deadline = tick() + 30
    repeat task.wait(0.25)
        local net = RS:FindFirstChild("__Net")
        MR  = net and net:FindFirstChild("MainRemote")
        GET = net and net:FindFirstChild("GetPlayerData")
    until (MR and GET) or tick() > deadline
end
if not (MR and GET) then return end
local function fire(...)
    local args = { ... }
    pcall(function() MR:FireServer(table.unpack(args)) end)
end
local function playerData()
    local ok, d = pcall(function() return GET:InvokeServer() end)
    if ok then return d end
end

-- ── config ──────────────────────────────────────────────────────────────────────
local TREE = require(RS.Shared.Modules.UIFootballTree)
local RANK_MAX, TROPHY_MAX = 6, 10
pcall(function() RANK_MAX   = #require(RS.Shared.Modules.FootballRankings).List end)
pcall(function() TROPHY_MAX = #require(RS.Shared.Modules.Trophy).List end)

local GOAL_KEYS = {}
pcall(function()
    local U = require(RS.Shared.Modules.Upgrades)
    local g = U.List and U.List.Goals
    if type(g) == "table" then for k in pairs(g) do GOAL_KEYS[#GOAL_KEYS + 1] = k end end
end)

local NOOB_REQ = {}
pcall(function()
    local L = require(RS.Shared.Modules.Noobs); L = L.List or L
    for nm, e in pairs(L) do
        if type(e) == "table" and e.requireFootballNode then NOOB_REQ[nm] = e.requireFootballNode end
    end
end)

-- ── excluded talents ("НЕ качать") — baked default = your saved banlist, but the cfg wins ──
local EXCLUDED = {
    PRuneSpeed = true, PRuneBulk = true, B3_WaterMulti = true, B2_OofMul = true, B3_GemMulti = true,
    B2_GemMul = true, B3_HackPointMul = true, B2_HackPointMul = true, B3_PlankMulti = true,
    B3_MineralMul = true, B2_PrismMul = true, B3_OreDamage = true, B3_AuraLuck = true,
    B2_PrismMul2 = true, B3_OofMulti = true, B3_PrismMult = true,
}
pcall(function()
    if isfile and isfile("noob_incremental_v8.cfg") then
        local line = (readfile("noob_incremental_v8.cfg")):match("excludedTalents=([^\r\n]*)")
        if line and #line > 0 then
            EXCLUDED = {}
            for n in line:gmatch("[^,]+") do EXCLUDED[n] = true end
        end
    end
end)

-- ── tree unlock graph ─────────────────────────────────────────────────────────────
local NODE_ML, PARENTS = {}, {}
for name, node in pairs(TREE.Nodes) do NODE_ML[name] = node.maxLevel or 1 end
for name, node in pairs(TREE.Nodes) do
    if type(node.unlocks) == "table" then
        for _, child in ipairs(node.unlocks) do
            PARENTS[child] = PARENTS[child] or {}
            table.insert(PARENTS[child], name)
        end
    end
end
local treeLv, goalLv = {}, {}
local function nodeUnlocked(name)
    local ps = PARENTS[name]
    if not ps then return true end
    for _, p in ipairs(ps) do if (treeLv[p] or 0) >= 1 then return true end end
    return false
end

-- ── live values ────────────────────────────────────────────────────────────────
local FEAT     = LP:FindFirstChild("FEATURES")
local NOOBS_F  = FEAT and FEAT:FindFirstChild("NOOBS")
local RANK_V   = FEAT and FEAT:FindFirstChild("FOOTBALL_RANKING") and FEAT.FOOTBALL_RANKING:FindFirstChild("RankingBought")
local TROPHY_V = FEAT and FEAT:FindFirstChild("TROPHY") and FEAT.TROPHY:FindFirstChild("TrophyBought")
local function rankNow()   return RANK_V   and tonumber(RANK_V.Value)   or 0 end
local function trophyNow() return TROPHY_V and tonumber(TROPHY_V.Value) or 0 end
local function noobLevel(nm)
    local n = NOOBS_F and NOOBS_F:FindFirstChild(nm)
    local l = n and n:FindFirstChild("Level")
    return l and tonumber(l.Value) or 0
end
local function noobBought(nm)
    local n = NOOBS_F and NOOBS_F:FindFirstChild(nm)
    local u = n and n:FindFirstChild("Unlocked")
    return u ~= nil and u.Value == true
end

-- ── result-detection + exponential back-off ───────────────────────────────────────
local stall, fail, snap = {}, {}, {}
local PEND, BACKOFF_MAX = 3, 60
local function blocked(id) local u = stall[id]; return u ~= nil and tick() < u end
local function levelOf(id)
    local p = id:sub(1, 2)
    if id == "rank" then return rankNow()
    elseif id == "trophy" then return trophyNow()
    elseif p == "g:" then return tonumber(goalLv[id:sub(3)]) or 0
    elseif p == "t:" then return treeLv[id:sub(3)] or 0
    elseif p == "u:" then return noobLevel(id:sub(3))
    end
    return 0
end
local function attempt(id, go)
    snap[id] = levelOf(id)
    go()
    stall[id] = tick() + PEND
end
local function resolve(id)
    if snap[id] ~= nil and levelOf(id) <= snap[id] then
        fail[id]  = (fail[id] or 0) + 1
        stall[id] = tick() + math.min(BACKOFF_MAX, PEND * 2 ^ math.min(fail[id], 6))
    else
        fail[id]  = nil
        stall[id] = nil
    end
end

-- ── hide "Not enough X" popups AT THE SOURCE (connect EARLY, before any buying) ────
pcall(function()
    local fs = LP:WaitForChild("PlayerGui"):WaitForChild("FullScreen", 12)
    local popups = fs and fs:WaitForChild("Popups", 12)
    if not popups then return end
    local known = {}
    for _, c in ipairs(popups:GetChildren()) do known[c] = true end   -- never touch pre-existing template(s)
    popups.ChildAdded:Connect(function(child)
        if not alive() or not child:IsA("GuiObject") or known[child] then return end
        task.spawn(function()
            local t = tick()
            while tick() - t < 0.6 do
                local hit = false
                pcall(function()
                    for _, d in ipairs(child:GetDescendants()) do
                        if d:IsA("TextLabel") and type(d.Text) == "string" and d.Text:lower():find("not enough") then
                            hit = true; break
                        end
                    end
                end)
                if hit then pcall(function() child:Destroy() end); return end
                task.wait(0.05)
            end
        end)
    end)
end)

-- ── state + refresh (2s: pull levels, resolve attempts, watch rank/trophy progress) ─
local S = { on = true, buyNoobs = true }
local boughtNoobs = {}
local pending = {}
local phaseStart = tick()          -- start of the current save (or build) phase
local mode = "save"                -- "save" | "build"
local prevRank, prevTrophy = rankNow(), trophyNow()
loop(2, function()
    if not S.on then return end
    local d = playerData()
    if d then
        if type(d.FOOTBALL_UI_UPGRADE_TREE) == "table" then treeLv = d.FOOTBALL_UI_UPGRADE_TREE end
        if d.UPGRADES and type(d.UPGRADES.Goals) == "table" then goalLv = d.UPGRADES.Goals end
    end
    boughtNoobs = {}
    if NOOBS_F then
        for _, n in ipairs(NOOBS_F:GetChildren()) do
            local u = n:FindFirstChild("Unlocked")
            if u and u.Value then boughtNoobs[#boughtNoobs + 1] = n.Name end
        end
    end
    local p = pending; pending = {}
    for id in pairs(p) do resolve(id) end
    local r, t = rankNow(), trophyNow()          -- bought a rank/trophy → restart the save window for the next one
    if r > prevRank or t > prevTrophy then mode = "save"; phaseStart = tick() end
    prevRank, prevTrophy = r, t
end)

-- ── the brain: priority + smart save / build ──────────────────────────────────────
local SAVE_MAX, BUILD_TIME = 300, 90
local MAX_PER_TICK = 2
local statusText = "starting…"
loop(0.4, function()
    if not S.on then statusText = "OFF"; return end
    local priorityPending = (rankNow() < RANK_MAX) or (trophyNow() < TROPHY_MAX)
    -- decide phase
    if not priorityPending then
        mode = "build"
    elseif mode == "save" and tick() - phaseStart > SAVE_MAX then
        mode = "build"; phaseStart = tick()
    elseif mode == "build" and tick() - phaseStart > BUILD_TIME then
        mode = "save"; phaseStart = tick()
    end
    -- candidates in priority order
    local cands = {}
    if rankNow()   < RANK_MAX   then cands[#cands + 1] = { "rank",   function() fire("BuyFootballRanking", rankNow() + 1) end } end
    if trophyNow() < TROPHY_MAX then cands[#cands + 1] = { "trophy", function() fire("BuyTrophy", trophyNow() + 1) end } end
    if mode == "build" or not priorityPending then       -- only spend on the rest when NOT saving
        for _, k in ipairs(GOAL_KEYS) do
            cands[#cands + 1] = { "g:" .. k, function() fire("UpgradeUpgradeMax", "Goals", k) end }
        end
        for name, ml in pairs(NODE_ML) do
            if not EXCLUDED[name] and (treeLv[name] or 0) < ml and nodeUnlocked(name) then
                cands[#cands + 1] = { "t:" .. name, function() fire("BuyFootballUITreeNode", name) end }
            end
        end
        for _, nm in ipairs(boughtNoobs) do
            cands[#cands + 1] = { "u:" .. nm, function() fire("UpgradeNoobMax", nm) end }
        end
    end
    local fired = 0
    for _, c in ipairs(cands) do
        if fired >= MAX_PER_TICK then break end
        if not blocked(c[1]) then attempt(c[1], c[2]); pending[c[1]] = true; fired = fired + 1 end
    end
    if not priorityPending then
        statusText = "rank & trophy maxed — buying everything else"
    elseif mode == "save" then
        statusText = string.format("SAVING for rank/trophy — banking Goals (%ds)", math.floor(tick() - phaseStart))
    else
        statusText = string.format("target far → building income %ds", math.max(0, math.floor(BUILD_TIME - (tick() - phaseStart))))
    end
end)

-- ── auto-kick = income ─────────────────────────────────────────────────────────────
local ballCtrl
local function getCtrl()
    if ballCtrl then
        local ok, st = pcall(function() return ballCtrl._state end)
        if ok and st ~= nil then return ballCtrl end
        ballCtrl = nil
    end
    pcall(function() ballCtrl = require(RS.Framework.Client).GetController("Ctrl_BallShootPrototype") end)
    return ballCtrl
end
loop(0.1, function()
    if not S.on then return end
    local c = getCtrl(); if not c then return end
    if c._state == "idle" and c._ball then
        c._lastKick = 0
        pcall(function() c:_Kick() end)
    end
end)

-- ── noob buy: WALK to the button and back — only while BUILDING (never mid-save) ──
local GC        = workspace:FindFirstChild("__GAME_CONTENT")
local NOOBS_MAP = GC and GC:FindFirstChild("Noobs")
local function getHRP() local ch = LP.Character; return ch and ch:FindFirstChild("HumanoidRootPart") end
local function getHum() local ch = LP.Character; return ch and ch:FindFirstChild("Humanoid") end
local homeCF
loop(1.5, function()
    if not (S.on and S.buyNoobs) or not NOOBS_MAP then return end
    local priorityPending = (rankNow() < RANK_MAX) or (trophyNow() < TROPHY_MAX)
    if priorityPending and mode == "save" then return end          -- don't walk off / spend while saving
    local c = getCtrl()
    if c and c._inZone and getHRP() then homeCF = getHRP().CFrame end
    local zone, nm
    for _, m in ipairs(NOOBS_MAP:GetChildren()) do
        local z   = m:FindFirstChild("_Zone_Buy_Noob")
        local req = NOOB_REQ[m.Name]
        local talentDone = (not req) or ((treeLv[req] or 0) >= 1)
        if z and talentDone and not noobBought(m.Name) and not blocked("nb:" .. m.Name) then zone, nm = z, m.Name; break end
    end
    if not zone then return end
    local hrp, hum = getHRP(), getHum()
    if not (hrp and hum) then return end
    local origin = homeCF or hrp.CFrame
    pcall(function()
        if (zone.Position - hrp.Position).Magnitude > 400 then
            hrp.CFrame = CFrame.new(zone.Position + Vector3.new(0, 3, 0))
        else
            hum:MoveTo(zone.Position)
            local t = tick()
            while tick() - t < 6 do
                local h = getHRP(); if not h or (h.Position - zone.Position).Magnitude < 7 then break end
                task.wait(0.15)
            end
        end
        task.wait(0.6)
        local h2, hm2 = getHRP(), getHum()
        if h2 and hm2 then
            hm2:MoveTo(origin.Position)
            local t2 = tick()
            while tick() - t2 < 6 do
                local h = getHRP(); if not h or (h.Position - origin.Position).Magnitude < 7 then break end
                task.wait(0.15)
            end
            pcall(function() local h = getHRP(); if h then h.CFrame = origin end end)
        end
    end)
    if noobBought(nm) then
        fail["nb:" .. nm] = nil; stall["nb:" .. nm] = nil
    else
        fail["nb:" .. nm] = (fail["nb:" .. nm] or 0) + 1
        stall["nb:" .. nm] = tick() + math.min(BACKOFF_MAX, 10 * 2 ^ math.min(fail["nb:" .. nm], 5))
    end
end)

-- ── minimal GUI: FULL AUTO toggle + live status ───────────────────────────────────
local gui = Instance.new("ScreenGui")
gui.Name = "NIFootballAuto"; gui.ResetOnSpawn = false; gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
pcall(function() gui.Parent = (gethui and gethui()) or game:GetService("CoreGui") end)
if not gui.Parent then gui.Parent = LP:WaitForChild("PlayerGui") end
_G.__NIF_gui = gui

local frame = Instance.new("Frame"); frame.Parent = gui; frame.Active = true
frame.Size = UDim2.fromOffset(276, 104); frame.Position = UDim2.fromOffset(24, 140)
frame.BackgroundColor3 = Color3.fromRGB(18, 18, 24); frame.BorderSizePixel = 0
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)

local title = Instance.new("TextLabel"); title.Parent = frame
title.Size = UDim2.new(1, -14, 0, 22); title.Position = UDim2.fromOffset(7, 5)
title.BackgroundTransparency = 1; title.TextXAlignment = Enum.TextXAlignment.Left
title.Font = Enum.Font.GothamBold; title.TextSize = 14; title.TextColor3 = Color3.fromRGB(120, 200, 255)
title.Text = "⚽ Football Auto · @Benefit"

local btn = Instance.new("TextButton"); btn.Parent = frame
btn.Size = UDim2.new(1, -14, 0, 28); btn.Position = UDim2.fromOffset(7, 30)
btn.Font = Enum.Font.GothamBold; btn.TextSize = 14; btn.BorderSizePixel = 0; btn.AutoButtonColor = true
Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

local status = Instance.new("TextLabel"); status.Parent = frame
status.Size = UDim2.new(1, -14, 0, 38); status.Position = UDim2.fromOffset(7, 62)
status.BackgroundTransparency = 1; status.TextXAlignment = Enum.TextXAlignment.Left
status.TextYAlignment = Enum.TextYAlignment.Top; status.TextWrapped = true
status.Font = Enum.Font.Gotham; status.TextSize = 12; status.TextColor3 = Color3.fromRGB(205, 205, 205)
status.Text = ""

local function paint()
    btn.Text = S.on and "FULL AUTO: ON  (click to stop)" or "FULL AUTO: OFF  (click to start)"
    btn.BackgroundColor3 = S.on and Color3.fromRGB(38, 140, 74) or Color3.fromRGB(120, 52, 52)
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
end
btn.MouseButton1Click:Connect(function() S.on = not S.on; paint() end)
paint()

do
    local dragging, off
    frame.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true; off = Vector2.new(i.Position.X, i.Position.Y) - frame.AbsolutePosition end
    end)
    frame.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)
    UIS.InputChanged:Connect(function(i)
        if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
            frame.Position = UDim2.fromOffset(i.Position.X - off.X, i.Position.Y - off.Y)
        end
    end)
end

loop(0.4, function()
    if not gui.Parent then return end
    status.Text = string.format("Rank %d/%d   Trophy %d/%d\n%s",
        rankNow(), RANK_MAX, trophyNow(), TROPHY_MAX, S.on and statusText or "OFF")
end)

pcall(function()
    game:GetService("StarterGui"):SetCore("SendNotification", { Title = "Football Auto", Text = "Loaded — priority: save for rank/trophy", Duration = 5 })
end)
