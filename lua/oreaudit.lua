-- ORE NETWORK INTERCEPT + SPEED AUDIT
-- Перехватывает ВСЕ события NET пока стоим у руды.
-- Спамит все возможные запросы параллельно.
-- Ищет HP value в модели руды.
-- Проверяет можно ли ускорить через дополнительные fire-запросы.

local LP  = game:GetService("Players").LocalPlayer
local RS  = game:GetService("ReplicatedStorage")
local RUN = game:GetService("RunService")
local GC  = workspace:WaitForChild("__GAME_CONTENT", 10)
local NET = RS:WaitForChild("__Net", 10)
local MR  = NET and NET:WaitForChild("MainRemote", 10)
if not (GC and MR) then warn("[Net] Missing"); return end

local function fireMR(...) pcall(MR.FireServer, MR, ...) end
local p = print

-- ══════════════════════════════════════════════════════════════════════════════
-- STEP 1: Hook ALL RemoteEvents in NET — log everything that fires
-- ══════════════════════════════════════════════════════════════════════════════
p("[Net] Hooking all "..#NET:GetChildren().." NET children...")

local eventLog = {}   -- {time, name, args}
local eventCounts = {}

for _, child in ipairs(NET:GetChildren()) do
    if child:IsA("RemoteEvent") then
        local name = child.Name
        eventCounts[name] = 0
        child.OnClientEvent:Connect(function(a1,a2,a3,a4)
            eventCounts[name] = (eventCounts[name] or 0) + 1
            table.insert(eventLog, {t=tick(), name=name, a1=a1, a2=a2, a3=a3, a4=a4})
        end)
    end
end
p("[Net] Hooks active. Baseline 2s (no action)...")
task.wait(2)

-- Snapshot baseline
local baseline = {}
for k,v in pairs(eventCounts) do baseline[k]=v end

-- ══════════════════════════════════════════════════════════════════════════════
-- STEP 2: Find ores + ore HP value
-- ══════════════════════════════════════════════════════════════════════════════
local oreF = GC:FindFirstChild("Ores")
if not oreF then warn("[Net] No GC/Ores"); return end

local function rockPos(rock)
    if not rock then return nil end
    if rock:IsA("BasePart") then return rock.Position end
    local pp = rock.PrimaryPart; if pp then return pp.Position end
    local bp = rock:FindFirstChildWhichIsA("BasePart",true); return bp and bp.Position
end

-- Find the Health TextLabel inside OresTopUI.Bar.Health
-- It has .Text (e.g. "150/500") not .Value
local function findHealthLabel(ore)
    local ui=ore:FindFirstChild("OresTopUI")
    local bar=ui and ui:FindFirstChild("Bar")
    return bar and bar:FindFirstChild("Health")  -- TextLabel
end

local function getLive(nameFilter)
    local list={}
    for _,ore in ipairs(oreF:GetChildren()) do
        if ore.Parent then
            local rock=ore:FindFirstChild("Rock")
            local pos=rock and rockPos(rock)
            if not pos then
                local bp=ore:FindFirstChildWhichIsA("BasePart",true)
                pos=bp and bp.Position
            end
            if pos and (not nameFilter or ore.Name==nameFilter) then
                list[#list+1]={ore=ore,rock=rock,pos=pos,name=ore.Name,hp=findHealthLabel(ore)}
            end
        end
    end
    return list
end

local function getHRP() local c=LP.Character; return c and c:FindFirstChild("HumanoidRootPart") end
local function snap(pos,dy)
    local hrp=getHRP(); if hrp then hrp.CFrame=CFrame.new(pos.X,pos.Y+(dy or 3),pos.Z) end
end
local startCF do local h=getHRP(); startCF=h and h.CFrame or CFrame.new() end

local ores=getLive()
p("[Net] Live ores: "..#ores)
local first=ores[1]
if not first then warn("[Net] No ores found"); return end

-- HP is stored in OresTopUI.Bar.Health (TextLabel.Text = "cur/max")
if first.hp then
    p("[Net] HealthLabel found: "..first.hp:GetFullName())
    p("[Net] Current HP text: '"..tostring(first.hp.Text).."'")
else
    p("[Net] No HealthLabel — dumping all ore descendants:")
    for _,d in ipairs(first.ore:GetDescendants()) do
        local ok,txt=pcall(function() return d:IsA("GuiObject") and d.Text or nil end)
        local v = ok and txt and (' text="'..txt..'"') or ""
        p("  "..d.ClassName..": "..d.Name..v)
    end
end

-- ══════════════════════════════════════════════════════════════════════════════
-- STEP 3: Stand near easy ore 5s — capture ALL network events that fire
-- ══════════════════════════════════════════════════════════════════════════════
p("\n══ PHASE 1: Network capture while standing near "..first.name.." (5s) ══")
local captureStart = {}
for k,v in pairs(eventCounts) do captureStart[k]=v end

local t0=tick(); local conn
conn=RUN.Heartbeat:Connect(function()
    local hrp=getHRP()
    if hrp then hrp.CFrame=CFrame.new(first.pos.X,first.pos.Y+3,first.pos.Z) end
    if tick()-t0>5 then conn:Disconnect() end
end)
task.wait(5.2); conn:Disconnect()

p("Events that fired while standing near ore:")
local anyFired=false
for k,v in pairs(eventCounts) do
    local delta=v-(captureStart[k] or 0)
    if delta>0 then
        p(string.format("  %-30s +%d (%.1f/s)", k, delta, delta/5))
        anyFired=true
        -- Print last args for this event
        for i=#eventLog,1,-1 do
            if eventLog[i].name==k then
                local e=eventLog[i]
                local function fmt(v2) return type(v2)=="table" and "{table}" or tostring(v2) end
                p("    last args: "..fmt(e.a1).." | "..fmt(e.a2).." | "..fmt(e.a3))
                break
            end
        end
    end
end
if not anyFired then p("  (nothing fired — server doesn't notify client on hit?)") end

local hrpBack=getHRP(); if hrpBack then hrpBack.CFrame=startCF end
task.wait(1)

-- ══════════════════════════════════════════════════════════════════════════════
-- STEP 4: SPAM TEST — stand near ore + fire every possible action name every frame
-- Measure: does spamming any event name speed up OreHit?
-- ══════════════════════════════════════════════════════════════════════════════
p("\n══ PHASE 2: Stand near ore + SPAM all known action names simultaneously ══")

-- Reset counts
for k in pairs(eventCounts) do eventCounts[k]=0 end

local spamNames = {
    "OreHit","HitOre","MineOre","DamageOre","BreakOre","AttackOre",
    "OreDamage","OreMine","Mine","Hit","Attack","Damage","Break",
    "Collect","Gather","PickOre","PickaxeHit","PickaxeSwing","Swing",
    "ToolHit","HarvestOre","ExtractOre","OreInteract","Interact",
    "ExchangeOre","OreAction","Mining","AutoMine","FastMine",
    "OreHitFast","SpeedMine","MultiHit","AoEMine","BatchHit"
}

ores=getLive(); if #ores==0 then task.wait(2); ores=getLive() end
local spamOre=ores[1]
p("Spam target: "..spamOre.name)
p("Firing "..#spamNames.." names per frame for 5s...")

local spamStart={}
for k,v in pairs(eventCounts) do spamStart[k]=v end

t0=tick(); conn=RUN.Heartbeat:Connect(function()
    local hrp=getHRP()
    if not hrp or tick()-t0>5 then conn:Disconnect(); return end
    hrp.CFrame=CFrame.new(spamOre.pos.X,spamOre.pos.Y+3,spamOre.pos.Z)
    -- Fire all names every frame
    for _,name in ipairs(spamNames) do
        fireMR(name, spamOre.ore)
    end
end)
task.wait(5.5); conn:Disconnect()

p("Results during spam (vs just standing):")
for k,v in pairs(eventCounts) do
    local delta=v-(spamStart[k] or 0)
    local baseline_rate=(captureStart[k] or 0)-(baseline[k] or 0) -- from phase 1 (no action)
    if delta>0 then
        p(string.format("  %-30s +%d (%.1f/s)", k, delta, delta/5))
    end
end

hrpBack=getHRP(); if hrpBack then hrpBack.CFrame=startCF end
task.wait(1)

-- ══════════════════════════════════════════════════════════════════════════════
-- STEP 5: Watch Infinity ore HP in real-time while hitting it
-- ══════════════════════════════════════════════════════════════════════════════
p("\n══ PHASE 3: Infinity ore — watch HP + try to accelerate ══")
local infOres=getLive("Infinity")
if #infOres==0 then
    p("No Infinity ore found — trying hardest available:")
    local orderByRarity={"Infinity","Voidsteel","Aetherite","Celestium","Palladium"}
    for _,name in ipairs(orderByRarity) do
        infOres=getLive(name); if #infOres>0 then p("  Using: "..name); break end
    end
end

if #infOres>0 then
    local inf=infOres[1]
    p("Target: "..inf.name.." @ "..tostring(inf.pos))

    -- HP is in TextLabel OresTopUI.Bar.Health (.Text = "cur/max")
    local hpLabel=inf.hp
    if hpLabel then
        p("  HP text: '"..tostring(hpLabel.Text).."'")
    else
        p("  No HealthLabel found on this ore")
    end

    -- Watch TextLabel.Text changes (HP going down) + any NumberValue changes
    local valueChanges={}
    if hpLabel then
        local lastText=hpLabel.Text
        hpLabel.Changed:Connect(function(prop)
            if prop=="Text" and hpLabel.Text~=lastText then
                table.insert(valueChanges,{t=tick(),name="HP.Text",old=lastText,new=hpLabel.Text})
                lastText=hpLabel.Text
            end
        end)
    end
    for _,d in ipairs(inf.ore:GetDescendants()) do
        if d:IsA("NumberValue") or d:IsA("IntValue") then
            local lastName=d.Name; local lastVal=d.Value
            d.Changed:Connect(function(newVal)
                table.insert(valueChanges,{t=tick(),name=lastName,old=lastVal,new=newVal})
                lastVal=newVal
            end)
        end
    end

    -- Reset network counts
    for k in pairs(eventCounts) do eventCounts[k]=0 end
    local infStart={}; for k,v in pairs(eventCounts) do infStart[k]=v end

    -- Phase A: just stand still 5s
    p("\n  [A] Stand still near Infinity — 5s")
    t0=tick(); local hitsA=0; local oHitA=0
    conn=RUN.Heartbeat:Connect(function()
        local hrp=getHRP()
        if not hrp or tick()-t0>5 then conn:Disconnect(); return end
        hrp.CFrame=CFrame.new(inf.pos.X,inf.pos.Y+3,inf.pos.Z)
    end)
    task.wait(5.2); conn:Disconnect()
    local evA={}; for k,v in pairs(eventCounts) do evA[k]=(v-(infStart[k] or 0)) end
    p("  Network events:")
    for k,v in pairs(evA) do if v>0 then p("    "..k..": +"..v) end end
    p("  Value changes: "..#valueChanges)
    for _,ch in ipairs(valueChanges) do
        p(string.format("    %s: %s → %s", ch.name, ch.old, ch.new))
    end

    hrpBack=getHRP(); if hrpBack then hrpBack.CFrame=startCF end
    task.wait(0.5)

    -- Phase B: stand still + spam fire every known name every frame for 5s
    p("\n  [B] Spam fire ALL names while standing near Infinity — 5s")
    valueChanges={}
    for k in pairs(eventCounts) do eventCounts[k]=0 end
    local infStartB={}; for k,v in pairs(eventCounts) do infStartB[k]=v end

    t0=tick()
    conn=RUN.Heartbeat:Connect(function()
        local hrp=getHRP()
        if not hrp or tick()-t0>5 then conn:Disconnect(); return end
        hrp.CFrame=CFrame.new(inf.pos.X,inf.pos.Y+3,inf.pos.Z)
        for _,name in ipairs(spamNames) do fireMR(name, inf.ore) end
    end)
    task.wait(5.5); conn:Disconnect()
    local evB={}; for k,v in pairs(eventCounts) do evB[k]=(v-(infStartB[k] or 0)) end
    p("  Network events (spam vs still):")
    for k,v in pairs(evB) do
        if v>0 then
            local va=evA[k] or 0
            local faster = v>va and string.format(" ← FASTER! (+%d)", v-va) or ""
            p("    "..k..": +"..v.." (was "..va.." still)"..faster)
        end
    end
    p("  Value changes during spam: "..#valueChanges)
    for _,ch in ipairs(valueChanges) do
        p(string.format("    %s: %s → %s", ch.name, ch.old, ch.new))
    end

    hrpBack=getHRP(); if hrpBack then hrpBack.CFrame=startCF end
    task.wait(0.5)

    -- Phase C: rapid alternating between 3 Infinity ores (if available)
    if #infOres>=2 then
        p("\n  [C] Rapidly chain between "..#infOres.." Infinity ores (hit multiple at once?)")
        for k in pairs(eventCounts) do eventCounts[k]=0 end
        local infStartC={}; for k,v in pairs(eventCounts) do infStartC[k]=v end
        t0=tick(); local idx=1
        conn=RUN.Heartbeat:Connect(function()
            local hrp=getHRP()
            if not hrp or tick()-t0>5 then conn:Disconnect(); return end
            local ore=infOres[idx]
            hrp.CFrame=CFrame.new(ore.pos.X,ore.pos.Y+3,ore.pos.Z)
            idx=(idx%#infOres)+1
        end)
        task.wait(5.2); conn:Disconnect()
        local evC={}; for k,v in pairs(eventCounts) do evC[k]=(v-(infStartC[k] or 0)) end
        p("  Network events (chaining):")
        for k,v in pairs(evC) do
            if v>0 then
                local va=evA[k] or 0
                p(string.format("    %s: +%d (still=%d)", k, v, va))
            end
        end
        hrpBack=getHRP(); if hrpBack then hrpBack.CFrame=startCF end
    end
else
    p("  No hard ores available")
end

-- ══════════════════════════════════════════════════════════════════════════════
-- STEP 6: FULL summary
-- ══════════════════════════════════════════════════════════════════════════════
p("\n══ SUMMARY ══")
p("Baseline events (no action, 2s):")
for k,v in pairs(baseline) do
    local total=eventCounts[k] or 0
    if total>0 then p("  "..k..": "..total.." total") end
end

p("\nConclusion:")
p("  If spam showed FASTER on any event = that remote accelerates mining")
p("  If A==B on all events = server ignores extra fires (rate-limited per tick)")
p("[Net] Done.")
