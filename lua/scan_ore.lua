-- ORE REMOTE TEST v2 — rate limit, all ores, currency delta
-- MainRemote("OreHit", oreModel) confirmed working. This test expands on it.

local LP  = game:GetService("Players").LocalPlayer
local RS  = game:GetService("ReplicatedStorage")
local GC  = workspace:WaitForChild("__GAME_CONTENT", 10)
local NET = RS:WaitForChild("__Net", 10)
local MR  = NET and NET:WaitForChild("MainRemote", 10)
if not (GC and MR) then warn("[OreTest2] Missing GC or MR"); return end

local function fireMR(...) pcall(MR.FireServer, MR, ...) end
local p = print

-- Track minerals
local mineralEv   = NET:FindFirstChild("MineralGained")
local totalEvents = 0
local firstArgs   = nil  -- store first event's args for inspection

if mineralEv then
    mineralEv.OnClientEvent:Connect(function(a1, a2, a3, a4, a5)
        totalEvents = totalEvents + 1
        if totalEvents == 1 then
            firstArgs = {a1, a2, a3, a4, a5}
        end
    end)
end

-- Collect ore models
local oreF = GC:FindFirstChild("Ores")
if not oreF then warn("[OreTest2] No GC/Ores"); return end

local ores = {}
for _, ore in ipairs(oreF:GetChildren()) do
    if ore:FindFirstChild("Rock") then
        ores[#ores+1] = ore
    end
end
p("[OreTest2] Ores found: " .. #ores)

local first = ores[1]
p("[OreTest2] Testing with: " .. first.Name)
task.wait(0.5)

-- ─────────────────────────────────────────────────────────────────────────────
-- A: Inspect MineralGained args (single fire, print what comes back)
p("\n[OreTest2] A: Single fire → inspect args")
do
    totalEvents = 0
    firstArgs = nil
    fireMR("OreHit", first)
    task.wait(0.5)
    p("  Events received: " .. totalEvents)
    if firstArgs then
        for i = 1, 5 do
            local v = firstArgs[i]
            if v == nil then break end
            local vt = type(v)
            p("  arg" .. i .. " type=" .. vt)
            if vt == "table" then
                local cnt = 0
                for k, val in pairs(v) do
                    cnt = cnt + 1
                    if cnt <= 15 then
                        p("    [" .. tostring(k) .. "] = " .. tostring(val))
                    end
                end
                p("    (table has " .. cnt .. " keys)")
            else
                p("  arg" .. i .. " value=" .. tostring(v))
            end
        end
    else
        p("  (no MineralGained received)")
    end
end

task.wait(1)

-- ─────────────────────────────────────────────────────────────────────────────
-- B: Rate limit — fire every 50ms for 3s
p("\n[OreTest2] B: Rate limit — fire 1 ore every 50ms for 3s")
do
    local prev = totalEvents
    local sends = 0
    local t0 = tick()
    while tick() - t0 < 3 do
        fireMR("OreHit", first)
        sends = sends + 1
        task.wait(0.05)
    end
    task.wait(0.3)
    local gained = totalEvents - prev
    p(string.format("  Sent: %d | MineralGained: %d | Accepted: %.0f%%",
        sends, gained, sends > 0 and gained/sends*100 or 0))
end

task.wait(1)

-- ─────────────────────────────────────────────────────────────────────────────
-- C: All ores simultaneously (one pass)
p("\n[OreTest2] C: Fire ALL " .. #ores .. " ores in one pass")
do
    local prev = totalEvents
    for _, ore in ipairs(ores) do
        fireMR("OreHit", ore)
    end
    task.wait(0.8)
    local gained = totalEvents - prev
    p("  Sent: " .. #ores .. " | MineralGained: " .. gained)
end

task.wait(1)

-- ─────────────────────────────────────────────────────────────────────────────
-- D: All ores × 3 passes rapid
p("\n[OreTest2] D: ALL ores x3 rapid passes")
do
    local prev = totalEvents
    for pass = 1, 3 do
        for _, ore in ipairs(ores) do
            fireMR("OreHit", ore)
        end
        task.wait(0.08)
    end
    task.wait(0.5)
    local gained = totalEvents - prev
    p("  3 passes x " .. #ores .. " ores → MineralGained: " .. gained)
end

task.wait(1)

-- ─────────────────────────────────────────────────────────────────────────────
-- E: Currency before/after
p("\n[OreTest2] E: Currency delta (before fire → after)")
local function readCurrencies()
    local out = {}
    local ok, cur = pcall(function() return LP.CURRENCIES end)
    if not ok or not cur then return out end
    for _, c in ipairs(cur:GetChildren()) do
        local amtF = c:FindFirstChild("Amount")
        if amtF then
            local v = amtF:FindFirstChild("1") or amtF:GetChildren()[1]
            if v then out[c.Name] = tonumber(v.Value) or 0 end
        end
    end
    return out
end

do
    local before = readCurrencies()
    fireMR("OreHit", first)
    task.wait(0.5)
    local after = readCurrencies()
    local changed = false
    for k, vAfter in pairs(after) do
        local vBefore = before[k] or 0
        local diff = vAfter - vBefore
        if diff ~= 0 then
            p(string.format("  %s: %s → %s (DELTA %+.0f)", k, vBefore, vAfter, diff))
            changed = true
        end
    end
    if not changed then
        p("  No currency change detected after fire")
        p("  Currencies tracked: " .. #(function() local n={} for k in pairs(after) do n[#n+1]=k end return n end)())
    end
end

task.wait(1)

-- ─────────────────────────────────────────────────────────────────────────────
-- F: Does ore disappear after OreHit?
p("\n[OreTest2] F: Does ore model disappear from workspace after OreHit?")
do
    local alive = first.Parent ~= nil
    p("  Before fire — ore exists: " .. tostring(alive))
    fireMR("OreHit", first)
    task.wait(1)
    local aliveAfter = first.Parent ~= nil
    p("  After 1s — ore exists: " .. tostring(aliveAfter))
    if alive and not aliveAfter then
        p("  Ore was DESTROYED by OreHit!")
    elseif alive and aliveAfter then
        p("  Ore survived — server may respawn or it's always there")
    end
end

-- ─────────────────────────────────────────────────────────────────────────────
p("\n[OreTest2] SUMMARY: Total MineralGained: " .. totalEvents)
p("[OreTest2] Done.")
