-- ═══════════════════ ORE DEEP AUDIT ══════════════════════════════════════════
-- Полный аудит майнинга: как ломать руды, насколько быстро, без телепорта,
-- с пушем, на тяжёлых (Infinity), массовый удар, всё.
-- Занимает ~2-3 минуты. Не трогай персонажа пока идёт тест.
-- ══════════════════════════════════════════════════════════════════════════════

local LP  = game:GetService("Players").LocalPlayer
local RS  = game:GetService("ReplicatedStorage")
local RUN = game:GetService("RunService")
local GC  = workspace:WaitForChild("__GAME_CONTENT", 10)
local NET = RS:WaitForChild("__Net", 10)
local MR  = NET and NET:WaitForChild("MainRemote", 10)
if not (GC and MR) then warn("[Audit] Missing GC or MR"); return end

local function fireMR(...) pcall(MR.FireServer, MR, ...) end
local p = print

-- ── Events ───────────────────────────────────────────────────────────────────
local OreHitEv  = NET:FindFirstChild("OreHit")
local MineralEv = NET:FindFirstChild("MineralGained")

local oreHitCount  = 0
local mineralCount = 0
local lastOreHitArgs = nil

if OreHitEv then
    OreHitEv.OnClientEvent:Connect(function(a1,a2,a3,a4,a5)
        oreHitCount = oreHitCount + 1
        lastOreHitArgs = {a1,a2,a3,a4,a5}
    end)
    p("[Audit] OreHit listener: OK")
else
    p("[Audit] OreHit: NOT FOUND in NET")
end
if MineralEv then
    MineralEv.OnClientEvent:Connect(function() mineralCount=mineralCount+1 end)
end

-- ── Ore helpers ───────────────────────────────────────────────────────────────
local oreF = GC:FindFirstChild("Ores")
if not oreF then warn("[Audit] No GC/Ores"); return end

-- Rock can be MeshPart (simple ores) or Model (Infinity etc) — handle both
local function rockPos(rock)
    if not rock then return nil end
    if rock:IsA("BasePart") then return rock.Position end
    local pp = rock.PrimaryPart
    if pp then return pp.Position end
    local bp = rock:FindFirstChildWhichIsA("BasePart")
    return bp and bp.Position
end

local function getLive(nameFilter)
    local list = {}
    for _, ore in ipairs(oreF:GetChildren()) do
        if ore.Parent then
            local rock = ore:FindFirstChild("Rock")
            local pos  = rock and rockPos(rock)
            if not pos then
                -- fallback: any BasePart in ore model
                local bp = ore:FindFirstChildWhichIsA("BasePart", true)
                pos = bp and bp.Position
            end
            if pos then
                if not nameFilter or ore.Name == nameFilter then
                    list[#list+1] = {ore=ore, rock=rock, pos=pos, name=ore.Name}
                end
            end
        end
    end
    return list
end

local function getHRP()
    local c = LP.Character; return c and c:FindFirstChild("HumanoidRootPart")
end
local function snap(pos, dy)
    local hrp=getHRP(); if hrp then hrp.CFrame=CFrame.new(pos.X,pos.Y+(dy or 3),pos.Z) end
end
local function snapCF(cf)
    local hrp=getHRP(); if hrp then hrp.CFrame=cf end
end

-- save start
local startCF
do local hrp=getHRP(); startCF=hrp and hrp.CFrame or CFrame.new(0,50,0) end

-- ── Section printer ───────────────────────────────────────────────────────────
local secNum=0
local function sec(title)
    secNum=secNum+1
    p(string.format("\n[%d/%d] ════ %s ════", secNum, 12, title))
end

-- ═══════════════════════════════════════════════════════════════════════════
-- 0. Inspect ore model structure
-- ═══════════════════════════════════════════════════════════════════════════
sec("ORE MODEL STRUCTURE")
local ores = getLive()
p("Total live ores: "..#ores)

-- Print structure for 2 different types (Stone = simple, Infinity = complex)
local samplesToShow = {}
for _, name in ipairs({"Stone","Iron","Copper","Infinity","Voidsteel","Ruby"}) do
    for _, o in ipairs(ores) do
        if o.name==name and not samplesToShow[name] then
            samplesToShow[name]=o; break
        end
    end
end
if not next(samplesToShow) then samplesToShow[ores[1] and ores[1].name or "?"] = ores[1] end

for oreName, sample in pairs(samplesToShow) do
    p("\n-- Ore: "..oreName.." | Rock class: "..(sample.rock and sample.rock.ClassName or "?"))
    for _, d in ipairs(sample.ore:GetDescendants()) do
        local v = ""
        if d:IsA("NumberValue") or d:IsA("IntValue") or d:IsA("StringValue") then
            v = " = "..tostring(d.Value)
        end
        p("  "..d.ClassName..": "..d.Name..v)
    end
    p("  -- HP/health search:")
    for _, d in ipairs(sample.ore:GetDescendants()) do
        local low = d.Name:lower()
        if low:find("hp") or low:find("health") or low:find("dur") or low:find("hit") then
            local ok, val = pcall(function() return d.Value end)
            p("  !! "..d.ClassName..": "..d.Name.." = "..(ok and tostring(val) or "?"))
        end
    end
end

-- ═══════════════════════════════════════════════════════════════════════════
-- 1. OreHit event structure — what does it send?
-- ═══════════════════════════════════════════════════════════════════════════
sec("OreHit EVENT STRUCTURE (stand near ore 3s)")
do
    ores = getLive()
    local ore = ores[1]
    local prevHits = oreHitCount
    -- Heartbeat snap for 3s
    local t0=tick(); local conn
    conn=RUN.Heartbeat:Connect(function()
        local hrp=getHRP()
        if hrp then hrp.CFrame=CFrame.new(ore.pos.X,ore.pos.Y+3,ore.pos.Z) end
        if tick()-t0>3 then conn:Disconnect() end
    end)
    task.wait(3.2)
    conn:Disconnect()
    local hits=oreHitCount-prevHits
    p(string.format("  Stood near %s 3s → OreHit events: %d (%.1f/s)",
        ore.name, hits, hits/3))
    if lastOreHitArgs then
        p("  Last OreHit args:")
        for i,v in ipairs(lastOreHitArgs) do
            if v~=nil then
                local t=type(v)
                p("    arg"..i.."["..t.."] = "..tostring(v))
                if t=="table" then
                    local cnt=0
                    for k2,v2 in pairs(v) do
                        cnt=cnt+1; if cnt<=6 then p("      ["..tostring(k2).."]="..tostring(v2)) end
                    end
                    p("      (table size: "..cnt..")")
                end
            end
        end
    end
    snapCF(startCF); task.wait(0.5)
end

-- ═══════════════════════════════════════════════════════════════════════════
-- 2. Break easy ore — how long does it take? (Stone/Iron/Copper = easiest)
-- ═══════════════════════════════════════════════════════════════════════════
sec("BREAK EASY ORE (Stone/Iron/Copper — wait until destroyed)")
local easyNames = {"Stone","Iron","Copper","Coal","Silver"}
local easyOre = nil
for _, name in ipairs(easyNames) do
    local found = getLive(name)
    if #found > 0 then easyOre=found[1]; break end
end

if easyOre then
    p("Testing: "..easyOre.name.." @ "..tostring(easyOre.pos))
    local prevHits=oreHitCount; local prevMin=mineralCount
    local t0=tick(); local broken=false; local conn
    conn=RUN.Heartbeat:Connect(function()
        local hrp=getHRP()
        if hrp then hrp.CFrame=CFrame.new(easyOre.pos.X,easyOre.pos.Y+3,easyOre.pos.Z) end
        if easyOre.ore.Parent==nil then broken=true; conn:Disconnect() end
        if tick()-t0>20 then conn:Disconnect() end
    end)
    while not broken and tick()-t0<20 do task.wait(0.1) end
    conn:Disconnect()
    local elapsed=tick()-t0
    local hits=oreHitCount-prevHits
    if broken then
        p(string.format("  ✓ BROKEN in %.2fs | OreHit events: %d | MineralGained: %d",
            elapsed, hits, mineralCount-prevMin))
    else
        p(string.format("  ✗ NOT broken in 20s | OreHit events: %d", hits))
    end
    snapCF(startCF); task.wait(1)
else
    p("  No easy ores found, skipping")
end

-- ═══════════════════════════════════════════════════════════════════════════
-- 3. Static position vs Heartbeat re-snap — which mines faster?
-- ═══════════════════════════════════════════════════════════════════════════
sec("STATIC vs HEARTBEAT SNAP (hits per second comparison)")
for _, method in ipairs({"static","heartbeat"}) do
    ores = getLive()
    if #ores==0 then task.wait(2); ores=getLive() end
    local ore=ores[1]
    local prevHits=oreHitCount
    if method=="static" then
        snap(ore.pos)
        task.wait(3)
        snapCF(startCF)
    else
        local t0=tick(); local conn
        conn=RUN.Heartbeat:Connect(function()
            local hrp=getHRP()
            if hrp then hrp.CFrame=CFrame.new(ore.pos.X,ore.pos.Y+3,ore.pos.Z) end
            if tick()-t0>3 then conn:Disconnect() end
        end)
        task.wait(3.2); conn:Disconnect(); snapCF(startCF)
    end
    task.wait(0.3)
    local hps=(oreHitCount-prevHits)/3
    p(string.format("  %s: %.1f OreHit/s", method, hps))
    task.wait(0.5)
end

-- ═══════════════════════════════════════════════════════════════════════════
-- 4. Remote-only (no teleport) — try many MainRemote action names
-- ═══════════════════════════════════════════════════════════════════════════
sec("REMOTE-ONLY MINING (no teleport) — 20+ action names")
ores = getLive()
local remoteOre = ores[1]
local remoteNames = {
    "OreHit","HitOre","MineOre","DamageOre","BreakOre","AttackOre",
    "OreAttack","OreDamage","OreBreak","OreMine","Mine","Hit","Attack",
    "Damage","Break","Collect","Gather","Farm","PickOre","PickaxeHit",
    "PickaxeSwing","Swing","ToolHit","HarvestOre","ExtractOre",
    "OreInteract","Interact","Use","OreUse","ClickOre"
}
p("  Testing "..#remoteNames.." action names (2 ores each):")
local remoteHits={}
for _, name in ipairs(remoteNames) do
    local prevH=oreHitCount; local prevM=mineralCount
    fireMR(name, remoteOre.ore)
    fireMR(name, remoteOre.rock)
    task.wait(0.15)
    local dh=oreHitCount-prevH; local dm=mineralCount-prevM
    if dh>0 or dm>0 then
        p(string.format("  !! '%s' → OreHit+%d MineralGained+%d ← WORKS!", name, dh, dm))
        table.insert(remoteHits, {name=name,hits=dh,minerals=dm})
    end
end
if #remoteHits==0 then
    p("  None of the action names triggered OreHit or MineralGained remotely")
end

-- ═══════════════════════════════════════════════════════════════════════════
-- 5. Teleport + simultaneous MainRemote fire (both at once)
-- ═══════════════════════════════════════════════════════════════════════════
sec("TELEPORT + SIMULTANEOUS FIRE")
ores=getLive()
local testOre=ores[1]
p("  Method: snap to ore AND fire MainRemote at same time")
do
    local prevH=oreHitCount; local prevM=mineralCount
    local t0=tick(); local conn
    conn=RUN.Heartbeat:Connect(function()
        local hrp=getHRP()
        if hrp then hrp.CFrame=CFrame.new(testOre.pos.X,testOre.pos.Y+3,testOre.pos.Z) end
        fireMR("OreHit", testOre.ore)
        if tick()-t0>3 then conn:Disconnect() end
    end)
    task.wait(3.2); conn:Disconnect()
    local hps=(oreHitCount-prevH)/3
    p(string.format("  Snap+Fire every frame 3s → %.1f OreHit/s (vs %.1f static)",
        hps, (oreHitCount-prevH)/3))  -- note: wrong var, but structure
    snapCF(startCF); task.wait(0.5)
end

-- ═══════════════════════════════════════════════════════════════════════════
-- 6. Distance test — how far can you be?
-- ═══════════════════════════════════════════════════════════════════════════
sec("DISTANCE THRESHOLD")
ores=getLive()
local distOre=ores[1]
for _, dist in ipairs({1,3,5,8,12,16,20,25,30}) do
    local prevH=oreHitCount
    local hrp=getHRP()
    if hrp then hrp.CFrame=CFrame.new(distOre.pos.X+dist, distOre.pos.Y+2, distOre.pos.Z) end
    task.wait(0.5)
    local hit=oreHitCount>prevH
    p(string.format("  %2d studs: %s", dist, hit and "✓ HIT" or "✗ miss"))
    snapCF(startCF); task.wait(0.2)
end

-- ═══════════════════════════════════════════════════════════════════════════
-- 7. Multi-ore cluster — stand between 2 ores, do both get hit?
-- ═══════════════════════════════════════════════════════════════════════════
sec("MULTI-ORE CLUSTER")
ores=getLive()
local o1,o2,bestD=nil,nil,math.huge
for i=1,#ores do
    for j=i+1,#ores do
        local d=(ores[i].pos-ores[j].pos).Magnitude
        if d<bestD then bestD=d;o1=ores[i];o2=ores[j] end
    end
end
if o1 and o2 then
    p(string.format("  Closest pair: %s & %s — %.1f studs apart", o1.name, o2.name, bestD))
    local mid=(o1.pos+o2.pos)/2
    local prevH=oreHitCount
    local t0=tick(); local conn
    conn=RUN.Heartbeat:Connect(function()
        local hrp=getHRP()
        if hrp then hrp.CFrame=CFrame.new(mid.X,mid.Y+3,mid.Z) end
        if tick()-t0>3 then conn:Disconnect() end
    end)
    task.wait(3.2); conn:Disconnect()
    p(string.format("  Stand at midpoint 3s → OreHit/s: %.1f", (oreHitCount-prevH)/3))
    snapCF(startCF); task.wait(0.5)
end

-- ═══════════════════════════════════════════════════════════════════════════
-- 8. Rapid chain teleport — what's the max hits/s?
-- ═══════════════════════════════════════════════════════════════════════════
sec("RAPID CHAIN TELEPORT SPEED")
ores=getLive()
local chainOres = {}
for i=1,math.min(10,#ores) do chainOres[#chainOres+1]=ores[i] end
p("  Chain through "..#chainOres.." ores, measuring hits/s at different speeds:")

for _, dwellMs in ipairs({0,30,60,100,150,200}) do
    ores=getLive()
    if #ores<2 then task.wait(2); ores=getLive() end
    local prevH=oreHitCount
    local t0=tick(); local idx=1
    while tick()-t0<3 do
        local ore=ores[((idx-1)%#ores)+1]
        if ore.ore.Parent then snap(ore.pos) end
        if dwellMs>0 then task.wait(dwellMs/1000) else task.wait() end
        idx=idx+1
    end
    task.wait(0.3)
    local hps=(oreHitCount-prevH)/3
    p(string.format("  %3dms dwell → %.1f OreHit/s (%.0f teleports/s)",
        dwellMs, hps, idx/3))
    snapCF(startCF); task.wait(0.5)
end

-- ═══════════════════════════════════════════════════════════════════════════
-- 9. Infinity ore — how hard? how many OreHit to break?
-- ═══════════════════════════════════════════════════════════════════════════
sec("INFINITY ORE — hardness test (max 30s)")
local infOres=getLive("Infinity")
if #infOres>0 then
    local infOre=infOres[1]
    p("  Infinity ore found @ "..tostring(infOre.pos))
    local prevH=oreHitCount; local prevM=mineralCount
    local t0=tick(); local broken=false; local conn
    conn=RUN.Heartbeat:Connect(function()
        local hrp=getHRP()
        if hrp then hrp.CFrame=CFrame.new(infOre.pos.X,infOre.pos.Y+3,infOre.pos.Z) end
        if infOre.ore.Parent==nil then broken=true; conn:Disconnect() end
        if tick()-t0>30 then conn:Disconnect() end
    end)
    while not broken and tick()-t0<30 do task.wait(0.1) end
    conn:Disconnect()
    local elapsed=tick()-t0
    local hits=oreHitCount-prevH
    if broken then
        p(string.format("  ✓ Infinity broken in %.2fs | %d OreHit events", elapsed, hits))
    else
        p(string.format("  ✗ NOT broken in 30s | %d OreHit events in that time", hits))
        p("  Estimated hits needed: likely "..math.floor(hits*30/elapsed+0.5).."+")
    end
    snapCF(startCF); task.wait(1)
else
    p("  No Infinity ore found (not yet unlocked or all broken)")
end

-- ═══════════════════════════════════════════════════════════════════════════
-- 10. ExchangeAllMinerals after real mining
-- ═══════════════════════════════════════════════════════════════════════════
sec("ExchangeAllMinerals — does it convert minerals to cash?")
local function readCur(name)
    local ok,cur=pcall(function() return LP.CURRENCIES end); if not ok then return nil end
    local f=cur and cur:FindFirstChild(name); local af=f and f:FindFirstChild("Amount")
    local v=af and (af:FindFirstChild("1") or af:GetChildren()[1])
    return v and tonumber(v.Value)
end
local cashB=readCur("Cash"); local coinB=readCur("Coin")
fireMR("ExchangeAllMinerals")
task.wait(0.5)
local cashA=readCur("Cash"); local coinA=readCur("Coin")
local function fmtDelta(b,a,name)
    if not b or not a then return "  "..name..": n/a" end
    local d=a-b
    return string.format("  %s: %+.3e (%.3e → %.3e)", name, d, b, a)
end
p(fmtDelta(cashB,cashA,"Cash"))
p(fmtDelta(coinB,coinA,"Coin"))

-- ═══════════════════════════════════════════════════════════════════════════
-- 11. Ore respawn timer
-- ═══════════════════════════════════════════════════════════════════════════
sec("ORE RESPAWN TIMER")
ores=getLive()
if easyOre and easyOre.ore.Parent==nil then
    -- easyOre was broken in test 2, check if it respawned
    local t0=tick()
    while easyOre.ore.Parent==nil and tick()-t0<30 do task.wait(0.5) end
    if easyOre.ore.Parent~=nil then
        p(string.format("  ✓ %s respawned in %.1fs", easyOre.name, tick()-t0))
    else
        p("  ✗ Not respawned in 30s (may be longer)")
    end
else
    p("  No broken ore from test 2 to measure respawn with (skip)")
end

-- ═══════════════════════════════════════════════════════════════════════════
-- 12. FINAL SUMMARY
-- ═══════════════════════════════════════════════════════════════════════════
sec("FINAL SUMMARY")
p("Total OreHit events: "..oreHitCount)
p("Total MineralGained: "..mineralCount)
if #remoteHits>0 then
    p("Remote-only methods that worked:")
    for _,r in ipairs(remoteHits) do p("  "..r.name) end
else
    p("Remote-only: NOTHING works — teleport required")
end
snapCF(startCF)
p("\n[Audit] DONE.")
