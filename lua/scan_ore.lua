-- ═══════════════════ ORE REMOTE TEST v2 ══════════════════════════════════════
-- T1 подтвердил: MainRemote("OreHit", oreModel) работает без телепорта!
-- Этот тест: разбирает таблицу MineralGained, тестирует rate limit,
-- тестирует ALL ores сразу, измеряет прирост минералов.
-- ══════════════════════════════════════════════════════════════════════════════

local LP  = game:GetService("Players").LocalPlayer
local RS  = game:GetService("ReplicatedStorage")
local GC  = workspace:WaitForChild("__GAME_CONTENT", 10)
local NET = RS:WaitForChild("__Net", 10)
local MR  = NET and NET:WaitForChild("MainRemote", 10)
if not (GC and MR) then warn("[OreTest2] Missing"); return end

local function fireMR(...) pcall(MR.FireServer, MR, ...) end
local p = print

-- Mineral tracking — dump full table
local mineralEv = NET:FindFirstChild("MineralGained")
local totalFired = 0
local mineralEvents = {}

local function dumpVal(v, depth)
    depth = depth or 0
    local indent = string.rep("  ", depth)
    local t = type(v)
    if t == "table" then
        local lines = {}
        -- try ipairs first
        local hasArr = false
        for i, val in ipairs(v) do
            hasArr = true
            table.insert(lines, indent.."  ["..i.."] = "..dumpVal(val, depth+1))
        end
        -- then pairs (skip numeric keys already printed)
        for k, val in pairs(v) do
            if type(k) ~= "number" then
                table.insert(lines, indent.."  ["..tostring(k).."] = "..dumpVal(val, depth+1))
            end
        end
        if #lines == 0 then return "{}" end
        return "{\n"..table.concat(lines, "\n").."\n"..indent.."}"
    elseif t == "userdata" or t == "Instance" then
        local ok, cn = pcall(function() return v.ClassName end)
        local ok2, nm = pcall(function() return v.Name end)
        return (ok and cn or t)..":"..(ok2 and nm or "?")
    else
        return tostring(v)
    end
end

if mineralEv then
    mineralEv.OnClientEvent:Connect(function(...)
        local args = {...}
        totalFired = totalFired + 1
        if totalFired <= 3 then
            p("[OreTest2] MineralGained #"..totalFired.." — "..#args.." args:")
            for i, v in ipairs(args) do
                p("  arg"..i..": "..dumpVal(v))
            end
        end
        table.insert(mineralEvents, {t=tick(), args=args})
    end)
end

-- Collect ores
local oreF = GC:FindFirstChild("Ores")
if not oreF then warn("[OreTest2] No Ores folder"); return end
local allOres = {}
for _, ore in ipairs(oreF:GetChildren()) do
    local rock = ore:FindFirstChild("Rock")
    if rock then allOres[#allOres+1] = ore end
end
p(string.format("[OreTest2] %d ore models found in GC/Ores", #allOres))

local first = allOres[1]
p("[OreTest2] First ore: "..first.Name)

-- ── TEST A: Inspect MineralGained table ─────────────────────────────────────
p("\n[OreTest2] ═══ A: Single fire — inspect MineralGained table ═══")
do
    local prev = totalFired
    fireMR("OreHit", first)
    task.wait(0.5)
    p("[OreTest2] A: fired 1x → "..( totalFired-prev).." events total")
end

task.wait(1)

-- ── TEST B: Rate limit — how fast can we fire? ───────────────────────────────
p("\n[OreTest2] ═══ B: Rate limit test — fire every 100ms for 3s ═══")
do
    local prev = totalFired
    local sends = 0
    local t0 = tick()
    while tick()-t0 < 3 do
        fireMR("OreHit", first)
        sends = sends + 1
        task.wait(0.1)
    end
    task.wait(0.3)
    local gained = totalFired - prev
    p(string.format("[OreTest2] B: sent %d fires → %d MineralGained (ratio %.1f%%)",
        sends, gained, gained/sends*100))
end

task.wait(1)

-- ── TEST C: Fire ALL ores simultaneously ─────────────────────────────────────
p(string.format("\n[OreTest2] ═══ C: Fire ALL %d ores simultaneously ═══", #allOres))
do
    local prev = totalFired
    local t0 = tick()
    for _, ore in ipairs(allOres) do
        fireMR("OreHit", ore)
    end
    task.wait(0.8)
    local gained = totalFired - prev
    local elapsed = tick()-t0
    p(string.format("[OreTest2] C: fired %d ores → %d MineralGained in %.2fs",
        #allOres, gained, elapsed))
end

task.wait(1)

-- ── TEST D: Fire ALL ores 5x rapid ───────────────────────────────────────────
p("\n[OreTest2] ═══ D: ALL ores × 5 rapid passes ═══")
do
    local prev = totalFired
    for pass = 1, 5 do
        for _, ore in ipairs(allOres) do
            fireMR("OreHit", ore)
        end
        task.wait(0.1)
    end
    task.wait(0.8)
    local gained = totalFired - prev
    p(string.format("[OreTest2] D: 5 passes × %d ores → %d MineralGained", #allOres, gained))
end

task.wait(1)

-- ── TEST E: Measure actual minerals gained from LP.CURRENCIES ────────────────
p("\n[OreTest2] ═══ E: Check LP currency changes ═══")
local function getCurrencies()
    local result = {}
    local ok, cur = pcall(function() return LP.CURRENCIES end)
    if ok and cur then
        for _, c in ipairs(cur:GetChildren()) do
            local amtF = c:FindFirstChild("Amount")
            if amtF then
                local v = amtF:FindFirstChild("1") or amtF:GetChildren()[1]
                if v then
                    result[c.Name] = tonumber(v.Value) or 0
                end
            end
        end
    end
    return result
end

local before = getCurrencies()
p("[OreTest2] E: Currencies before:")
for k,v in pairs(before) do p("  "..k..": "..v) end

fireMR("OreHit", first)
task.wait(0.5)

local after = getCurrencies()
p("[OreTest2] E: Currencies after:")
for k,v in pairs(after) do
    local diff = v - (before[k] or 0)
    if diff ~= 0 then
        p("  "..k..": "..v.." (+"..diff..")")
    else
        p("  "..k..": "..v)
    end
end

-- ── TEST F: Check ore respawn — do same ores refill? ─────────────────────────
p("\n[OreTest2] ═══ F: Ore respawn check ═══")
do
    local countBefore = #oreF:GetChildren()
    fireMR("OreHit", first)  -- try to destroy it
    task.wait(1)
    local countAfter = #oreF:GetChildren()
    p(string.format("[OreTest2] F: ores before=%d after=%d (diff=%d)",
        countBefore, countAfter, countAfter-countBefore))
    -- Is first ore still there?
    local stillThere = first.Parent ~= nil
    p("[OreTest2] F: first ore still exists: "..tostring(stillThere))
end

-- ── SUMMARY ──────────────────────────────────────────────────────────────────
task.wait(0.5)
p("\n[OreTest2] ═══ SUMMARY ═══")
p("Total MineralGained events: "..totalFired)
if #mineralEvents > 0 then
    local span = mineralEvents[#mineralEvents].t - mineralEvents[1].t
    p(string.format("Event timespan: %.2fs (%.1f/s avg)",
        span, span>0 and totalFired/span or 0))
end
p("Conclusion:")
p("  • MainRemote('OreHit', oreModel) = WORKS without teleport")
p("  • Direct OreHit RemoteEvent = server→client only (read-only)")
p("[OreTest2] Done.")
