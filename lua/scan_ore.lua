-- ORE SPEED TEST — find fastest possible mining method
-- Listens to OreHit (server→client) as the real mining confirmation.
-- Tests: dwell time, distance, chain speed, multi-ore, exchange.

local LP  = game:GetService("Players").LocalPlayer
local RS  = game:GetService("ReplicatedStorage")
local GC  = workspace:WaitForChild("__GAME_CONTENT", 10)
local NET = RS:WaitForChild("__Net", 10)
local MR  = NET and NET:WaitForChild("MainRemote", 10)
if not (GC and MR) then warn("[OreSpd] Missing"); return end

local function fireMR(...) pcall(MR.FireServer, MR, ...) end
local p = print

-- ── Track OreHit (server→client = mining confirmed by server) ─────────────
local OreHitEv    = NET:FindFirstChild("OreHit")
local MineralEv   = NET:FindFirstChild("MineralGained")
local oreHits     = 0
local mineralGots = 0

if OreHitEv then
    OreHitEv.OnClientEvent:Connect(function(a1, a2, a3)
        oreHits = oreHits + 1
        if oreHits <= 3 then
            -- dump args to understand structure
            p("[OreSpd] OreHit args: "..type(a1).." | "..type(a2).." | "..type(a3))
            if type(a1)=="table" then
                local cnt=0
                for k,v in pairs(a1) do
                    cnt=cnt+1
                    if cnt<=8 then p("  ["..tostring(k).."]="..tostring(v)) end
                end
            end
        end
    end)
end
if MineralEv then
    MineralEv.OnClientEvent:Connect(function() mineralGots=mineralGots+1 end)
end
p("[OreSpd] OreHit listener: "..(OreHitEv and "OK" or "NOT FOUND"))
p("[OreSpd] MineralGained listener: "..(MineralEv and "OK" or "NOT FOUND"))

-- ── Ore helpers ───────────────────────────────────────────────────────────────
local oreF = GC:FindFirstChild("Ores")
if not oreF then warn("[OreSpd] No GC/Ores"); return end

local function getLiveOres()
    local list = {}
    for _, ore in ipairs(oreF:GetChildren()) do
        local rock = ore:FindFirstChild("Rock")
        if rock and ore.Parent then list[#list+1] = {ore=ore, rock=rock, pos=rock.Position} end
    end
    return list
end

local function getHRP()
    local c = LP.Character
    return c and c:FindFirstChild("HumanoidRootPart")
end

local function snapTo(pos, yOff)
    local hrp = getHRP()
    if hrp then hrp.CFrame = CFrame.new(pos.X, pos.Y+(yOff or 3), pos.Z) end
end

local function waitHits(prevHits, timeout)
    local t0=tick()
    while oreHits==prevHits and tick()-t0<timeout do task.wait(0.02) end
    return oreHits>prevHits
end

-- Save start position
local startPos
do
    local hrp=getHRP()
    startPos = hrp and hrp.Position or Vector3.new(0,0,0)
end

p("\n[OreSpd] Starting. Stand anywhere — script teleports you.")
task.wait(1)
local ores = getLiveOres()
p("[OreSpd] Live ores: "..#ores)
if #ores==0 then warn("[OreSpd] No ores found"); return end

-- ═══════════════════════════════════════════════════════════════════════════
-- TEST 1: Minimum dwell time — how long must you stand near ore for a hit?
-- ═══════════════════════════════════════════════════════════════════════════
p("\n═══ TEST 1: Minimum dwell time ═══")
local dwellResults = {}
local dwells = {0, 0.05, 0.1, 0.15, 0.2, 0.3, 0.5}

for _, dwell in ipairs(dwells) do
    ores = getLiveOres()
    if #ores == 0 then task.wait(2); ores=getLiveOres() end
    local ore = ores[1]
    local prev = oreHits
    snapTo(ore.pos)
    if dwell > 0 then task.wait(dwell) end
    -- teleport away immediately
    snapTo(startPos)
    task.wait(0.3)
    local hit = oreHits > prev
    table.insert(dwellResults, {dwell=dwell, hit=hit})
    p(string.format("  dwell=%.0fms → %s", dwell*1000, hit and "✓ HIT" or "✗ miss"))
    task.wait(0.5)
end

-- ═══════════════════════════════════════════════════════════════════════════
-- TEST 2: Distance — how far can you be and still get credit?
-- ═══════════════════════════════════════════════════════════════════════════
p("\n═══ TEST 2: Max distance for mining ═══")
ores = getLiveOres()
local testOre = ores[1]

local distances = {2, 5, 8, 12, 16, 20, 30}
for _, dist in ipairs(distances) do
    local prev = oreHits
    local pos = testOre.pos
    local hrp = getHRP()
    if hrp then
        -- stand exactly 'dist' studs away horizontally
        hrp.CFrame = CFrame.new(pos.X + dist, pos.Y + 2, pos.Z)
    end
    task.wait(0.3)
    snapTo(startPos)
    task.wait(0.3)
    local hit = oreHits > prev
    p(string.format("  dist=%2d studs → %s", dist, hit and "✓ HIT" or "✗ miss"))
    task.wait(0.3)
end

-- ═══════════════════════════════════════════════════════════════════════════
-- TEST 3: Chain speed — teleport ore→ore as fast as possible, count hits/sec
-- ═══════════════════════════════════════════════════════════════════════════
p("\n═══ TEST 3: Rapid chain teleport ═══")
local chainResults = {}
local chainWaits = {0, 0.05, 0.1, 0.2}

for _, waitTime in ipairs(chainWaits) do
    ores = getLiveOres()
    local prev = oreHits
    local sends = 0
    local t0 = tick()
    local elapsed = 3  -- test for 3 seconds each

    local idx = 1
    while tick()-t0 < elapsed do
        local ore = ores[idx]
        if ore and ore.ore.Parent then
            snapTo(ore.pos)
            if waitTime > 0 then task.wait(waitTime) end
        end
        idx = (idx % #ores) + 1
        if waitTime == 0 then task.wait() end  -- yield at least 1 frame
        sends = sends + 1
    end
    task.wait(0.4)
    local hits = oreHits - prev
    table.insert(chainResults, {wait=waitTime, hits=hits, sends=sends})
    p(string.format("  wait=%.0fms | teleports=%d in 3s | hits=%d (%.1f hits/s)",
        waitTime*1000, sends, hits, hits/elapsed))
    snapTo(startPos)
    task.wait(0.8)
end

-- ═══════════════════════════════════════════════════════════════════════════
-- TEST 4: Multi-ore — can you hit 2+ ores at once (nearby cluster)?
-- ═══════════════════════════════════════════════════════════════════════════
p("\n═══ TEST 4: Multi-ore proximity (cluster) ═══")
ores = getLiveOres()
-- Find 2 ores close together
local clusterOre1, clusterOre2, clusterDist = nil, nil, math.huge
for i = 1, #ores do
    for j = i+1, #ores do
        local d = (ores[i].pos - ores[j].pos).Magnitude
        if d < clusterDist then
            clusterDist = d
            clusterOre1 = ores[i]
            clusterOre2 = ores[j]
        end
    end
end

if clusterOre1 and clusterOre2 then
    p(string.format("  Closest ore pair: %.1f studs apart", clusterDist))
    -- Stand at midpoint
    local mid = (clusterOre1.pos + clusterOre2.pos) / 2
    local prev = oreHits
    local hrp = getHRP()
    if hrp then hrp.CFrame = CFrame.new(mid.X, mid.Y+3, mid.Z) end
    task.wait(0.5)
    snapTo(startPos)
    task.wait(0.3)
    local hits = oreHits - prev
    p(string.format("  Stand at midpoint 0.5s → %d hits (expected 2 if both register)", hits))
end

-- ═══════════════════════════════════════════════════════════════════════════
-- TEST 5: ExchangeAllMinerals — does it work and what currency does it give?
-- ═══════════════════════════════════════════════════════════════════════════
p("\n═══ TEST 5: ExchangeAllMinerals ═══")

local function readKey(name)
    local ok, cur = pcall(function() return LP.CURRENCIES end)
    if not ok or not cur then return nil end
    local f = cur:FindFirstChild(name)
    local af = f and f:FindFirstChild("Amount")
    local v = af and (af:FindFirstChild("1") or af:GetChildren()[1])
    return v and tonumber(v.Value)
end

-- Mine a few ores first
ores = getLiveOres()
local mined = 0
for i = 1, math.min(5, #ores) do
    snapTo(ores[i].pos)
    task.wait(0.2)
    mined = mined + 1
end
snapTo(startPos)
task.wait(0.5)
p("  Mined "..mined.." ores, now testing exchange...")

local cashBefore = readKey("Cash")
local coinBefore = readKey("Coin")
fireMR("ExchangeAllMinerals")
task.wait(0.5)
local cashAfter = readKey("Cash")
local coinAfter = readKey("Coin")

p("  ExchangeAllMinerals fired")
if cashBefore and cashAfter then
    p(string.format("  Cash: %.2e → %.2e (delta %+.2e)", cashBefore, cashAfter, cashAfter-cashBefore))
end
if coinBefore and coinAfter then
    p(string.format("  Coin: %.2e → %.2e (delta %+.2e)", coinBefore, coinAfter, coinAfter-coinBefore))
end

-- Also try ExchangeOre (alternative name)
fireMR("ExchangeOre")
task.wait(0.3)
p("  ExchangeOre also fired (check if different)")

-- ═══════════════════════════════════════════════════════════════════════════
-- SUMMARY
-- ═══════════════════════════════════════════════════════════════════════════
task.wait(0.3)
p("\n═══ SUMMARY ═══")
p("OreHit events total: "..oreHits)
p("MineralGained total: "..mineralGots)

p("\nDwell time results:")
local minDwell = nil
for _, r in ipairs(dwellResults) do
    p(string.format("  %.0fms → %s", r.dwell*1000, r.hit and "HIT" or "miss"))
    if r.hit and minDwell==nil then minDwell=r.dwell end
end
p("Minimum dwell: "..(minDwell and (minDwell*1000).."ms" or "unknown"))

p("\nChain speed results:")
local bestHPS = 0
for _, r in ipairs(chainResults) do
    local hps = r.hits/3
    if hps > bestHPS then bestHPS = hps end
    p(string.format("  %.0fms wait → %.1f hits/s", r.wait*1000, hps))
end
p("Best: "..string.format("%.1f hits/s", bestHPS))

-- Teleport back
snapTo(startPos)
p("\n[OreSpd] Done. Teleported back to start.")
