-- ╔══════════════════════════════════════════════════════════════════╗
-- ║  Noob Incremental Autofarm  v8.0  @Benefit                       ║
-- ║  Fluent UI · Optimized · Stable · No external timeouts           ║
-- ╚══════════════════════════════════════════════════════════════════╝

-- ─── Services ─────────────────────────────────────────────────────────────────
local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local LP         = Players.LocalPlayer
local RS         = game:GetService("ReplicatedStorage")

-- Wait for critical game objects to replicate (up to 30s)
local GC, MR, NET
do
    local deadline = tick() + 30
    repeat task.wait(0.5)
        GC  = workspace:FindFirstChild("__GAME_CONTENT")
        NET = RS:FindFirstChild("__Net")
        MR  = NET and NET:FindFirstChild("MainRemote")
    until (GC and MR) or tick() > deadline
    if not GC or not MR then
        error("[autofarm] Game content not found after 30s — wrong game?")
    end
end

-- ─── Load UI ──────────────────────────────────────────────────────────────────
local FLUENT_URLS = {
    "https://raw.githubusercontent.com/dawid-scripts/Fluent/refs/heads/main/dist/main.lua",
    "https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua",
}
local Fluent
for _, url in ipairs(FLUENT_URLS) do
    local ok, src = pcall(game.HttpGet, game, url, true)
    if ok and src and #src > 100 then
        local fn, err = loadstring(src)
        if fn then Fluent = fn(); break end
    end
end
if not Fluent then error("[autofarm] Failed to load Fluent UI") end

-- ─── Anti-AFK ─────────────────────────────────────────────────────────────────
local VU = game:GetService("VirtualUser")
LP.Idled:Connect(function() VU:CaptureController(); VU:ClickButton2(Vector2.new()) end)

-- ─── Core Helpers ─────────────────────────────────────────────────────────────
local function getChar() return LP.Character end
local function getHRP()  local c=getChar(); return c and c:FindFirstChild("HumanoidRootPart") end
local function getHum()  local c=getChar(); return c and c:FindFirstChild("Humanoid") end
local function fire(...) pcall(MR.FireServer, MR, ...) end
local function cdet(d)   pcall(fireclickdetector, d) end
local function notify(title, content, dur)
    pcall(Fluent.Notify, Fluent, { Title=title, Content=content, Duration=dur or 4 })
end
local function safeLoop(sec, fn)
    task.spawn(function() while true do pcall(fn); task.wait(sec) end end)
end

-- ─── Number Utilities ─────────────────────────────────────────────────────────
local SFXLIST = {
    {1e120,"NoTg"},{1e117,"OcTg"},{1e114,"SpTg"},{1e111,"SxTg"},{1e108,"QnTg"},
    {1e105,"QdTg"},{1e102,"TdTg"},{1e99,"DDTg"},{1e96,"UTg"},{1e93,"Tg"},
    {1e90,"NoNo"},{1e87,"OcNo"},{1e84,"SpNo"},{1e81,"SxNo"},{1e78,"QnNo"},
    {1e75,"QdNo"},{1e72,"TNo"},{1e69,"DNo"},{1e66,"UNo"},{1e63,"Vt"},
    {1e60,"NoDe"},{1e57,"OcDe"},{1e54,"SpDe"},{1e51,"SxDe"},{1e48,"QnDe"},
    {1e45,"QdDe"},{1e42,"TDe"},{1e39,"DDe"},{1e36,"UDe"},{1e33,"De"},
    {1e30,"No"},{1e27,"Oc"},{1e24,"Sp"},{1e21,"Sx"},{1e18,"Qn"},
    {1e15,"Qd"},{1e12,"t"},{1e9,"b"},{1e6,"m"},{1e3,"k"},
}
local function parseNum(s)
    if not s or s=="" then return nil end
    s=tostring(s):gsub("%s",""):gsub(",",""):gsub("^[xX]","")
    local n=tonumber(s); if n then return n end
    for _, p in ipairs(SFXLIST) do
        local esc=p[2]:gsub("([%^%$%(%)%%%.%[%]%*%+%-%?])","%%%1")
        local m=s:match("^([%d%.]+)"..esc.."$")
        if m then return (tonumber(m) or 0)*p[1] end
    end
    return nil
end
local function fmtNum(n)
    if not n or n~=n then return "?" end
    if n==math.huge then return "∞" end
    for _, p in ipairs(SFXLIST) do
        if n>=p[1] then return string.format("%.2f",n/p[1])..p[2] end
    end
    return string.format("%.3g",n)
end
local function fmtTime(s)
    if not s or s~=s then return "?" end
    if s==math.huge or s>1e30 then return "∞" end
    if s<60   then return string.format("%.1fs",s) end
    if s<3600 then return string.format("%dm%ds",math.floor(s/60),math.floor(s%60)) end
    if s<86400 then return string.format("%dh%dm",math.floor(s/3600),math.floor(s%3600/60)) end
    local d=math.floor(s/86400)
    if d<365 then return string.format("%dd%dh",d,math.floor(s%86400/3600)) end
    return string.format("%.1fy",s/31536000)
end

-- ─── State ────────────────────────────────────────────────────────────────────
local S = {
    wheat=false, deposit=false, blaze=false,
    chest=false, minionCap=false,
    iceFarm=false, waterFarm=false, campfire=false, ashConvert=false,
    hireNoob=false, fillBucket=false, autoNoob=false,
    factory=false, cook=false, animals=false, mutation=false,
    mining=false, exchangeOre=false, miningMode="teleport",
    runes=false, tier=false, awaken=false, upgradeQuest=false,
    prismEquip=false, autoCoinFarm=false, autoPrism=false, autoPot=false, autoGuildClaim=false,
    StarterTree=false, TycoonTree=false, FarmTree=false,
    PrismTree=false, IceTree=false, MiningTree=false,
    Ice=false, Fire=false, Blaze=false, Water=false, Oof=false,
    Rebirth=false, Wood=false, Planks=false, Bread=false,
    Cash=false, Coin=false, HackPoints=false, Gem=false,
}
local selectedRunes      = {}
local runeInterval       = 0.15
local rollCount          = 500
local selectedIceBtn     = 12
local iceTeleportWait    = 0.15
local capsuleOpenWait    = 2.5
local selectedOres       = {}
local selectedNoobs      = {}
local selectedChest      = "Chest"
local selectedMinCap     = "Classic"
local prismEquipPat      = 1
local prismThreshold     = 3
local coinInterval       = 60
local selectedMilestones = {}
local selectedPotions    = {}
local manualRuneLuck     = nil
local capsuleBusy        = false
local capsuleCount       = 0

-- ─── Settings Save / Load ─────────────────────────────────────────────────────
local SAVE_FILE = "noob_incremental_v8.cfg"
local BOOL_KEYS = {
    "wheat","deposit","blaze","chest","minionCap",
    "iceFarm","waterFarm","campfire","ashConvert","hireNoob","fillBucket","autoNoob",
    "factory","cook","animals","mutation","mining","exchangeOre",
    "runes","tier","awaken","upgradeQuest","prismEquip",
    "StarterTree","TycoonTree","FarmTree","PrismTree","IceTree","MiningTree",
    "Ice","Fire","Blaze","Water","Oof","Rebirth","Wood","Planks",
    "Bread","Cash","Coin","HackPoints","Gem",
    "autoPot","autoGuildClaim","autoCoinFarm","autoPrism",
}
local function saveSettings()
    local lines = {
        "runeInterval="..runeInterval, "rollCount="..rollCount,
        "selectedChest="..selectedChest, "selectedMinCap="..selectedMinCap,
        "prismThreshold="..prismThreshold, "prismEquipPat="..prismEquipPat,
        "miningMode="..S.miningMode, "coinInterval="..coinInterval,
        "selectedIceBtn="..selectedIceBtn, "iceTeleportWait="..iceTeleportWait,
        "capsuleOpenWait="..capsuleOpenWait,
    }
    if manualRuneLuck then lines[#lines+1]="runeLuck="..manualRuneLuck end
    local on={}
    for _, k in ipairs(BOOL_KEYS) do if S[k] then on[#on+1]=k end end
    if #on>0 then lines[#lines+1]="toggles="..table.concat(on,",") end
    if #selectedRunes>0      then lines[#lines+1]="selectedRunes="..table.concat(selectedRunes,",") end
    if #selectedNoobs>0      then lines[#lines+1]="selectedNoobs="..table.concat(selectedNoobs,",") end
    if #selectedMilestones>0 then lines[#lines+1]="selectedMilestones="..table.concat(selectedMilestones,",") end
    if #selectedPotions>0    then lines[#lines+1]="selectedPotions="..table.concat(selectedPotions,",") end
    local ores={}
    for nm,v in pairs(selectedOres) do if v then ores[#ores+1]=nm end end
    if #ores>0 then lines[#lines+1]="selectedOres="..table.concat(ores,",") end
    pcall(writefile, SAVE_FILE, table.concat(lines,"\n"))
end
local function loadSettings()
    local ok,txt=pcall(readfile, SAVE_FILE)
    if not ok or not txt then return end
    for line in txt:gmatch("[^\n]+") do
        local k,v=line:match("^(.-)=(.*)$")
        if k then
            if     k=="runeInterval"    then runeInterval    =tonumber(v) or 0.15
            elseif k=="rollCount"       then rollCount       =tonumber(v) or 500
            elseif k=="selectedChest"   then selectedChest   =v or "Chest"
            elseif k=="selectedMinCap"  then selectedMinCap  =v or "Classic"
            elseif k=="prismThreshold"  then prismThreshold  =tonumber(v) or 3
            elseif k=="prismEquipPat"   then prismEquipPat   =tonumber(v) or 1
            elseif k=="coinInterval"    then coinInterval    =tonumber(v) or 60
            elseif k=="miningMode"      then S.miningMode    =v or "teleport"
            elseif k=="selectedIceBtn"  then selectedIceBtn  =tonumber(v) or 12
            elseif k=="iceTeleportWait" then iceTeleportWait =tonumber(v) or 0.15
            elseif k=="capsuleOpenWait" then capsuleOpenWait =tonumber(v) or 2.5
            elseif k=="runeLuck"        then manualRuneLuck  =tonumber(v)
            elseif k=="toggles" and v~="" then
                for key in v:gmatch("[^,]+") do S[key]=true end
            elseif k=="selectedRunes" and v~="" then
                selectedRunes={}; for r in v:gmatch("[^,]+") do selectedRunes[#selectedRunes+1]=r end
            elseif k=="selectedNoobs" and v~="" then
                selectedNoobs={}; for r in v:gmatch("[^,]+") do selectedNoobs[#selectedNoobs+1]=r end
            elseif k=="selectedMilestones" and v~="" then
                selectedMilestones={}; for r in v:gmatch("[^,]+") do selectedMilestones[#selectedMilestones+1]=r end
            elseif k=="selectedPotions" and v~="" then
                selectedPotions={}; for r in v:gmatch("[^,]+") do selectedPotions[#selectedPotions+1]=r end
            elseif k=="selectedOres" and v~="" then
                selectedOres={}; for r in v:gmatch("[^,]+") do selectedOres[r]=true end
            end
        end
    end
end
loadSettings()

-- Convert array → dict for Fluent Multi-dropdown Default (Fluent expects {key=true})
local function toDict(arr)
    local d={}; for _,v in ipairs(arr) do d[v]=true end; return d
end

-- ─── Game Object Cache ────────────────────────────────────────────────────────
-- Wheat click-detectors (once at start)
local wheatCDs={}
do
    local farm=GC:FindFirstChild("Farm")
    if farm then
        for _, w in ipairs(farm:GetChildren()) do
            local c=w:FindFirstChildWhichIsA("ClickDetector")
            if c then wheatCDs[#wheatCDs+1]=c end
        end
    end
end

-- Upgrade tree click-detectors (once at start)
local TREE_NAMES={"StarterTree","TycoonTree","FarmTree","PrismTree","IceTree","MiningTree"}
local treeCDs={}
do
    local ut=GC:FindFirstChild("UpgradeTree")
    if ut then
        for _, tn in ipairs(TREE_NAMES) do
            treeCDs[tn]={}
            local tree=ut:FindFirstChild(tn)
            if tree then
                for _, node in ipairs(tree:GetChildren()) do
                    for _, d in ipairs(node:GetDescendants()) do
                        if d:IsA("ClickDetector") then treeCDs[tn][#treeCDs[tn]+1]=d; break end
                    end
                end
            end
        end
    end
end

-- Ore folder — lazy-cached, re-resolved only when parent is gone
local _oreFolder=nil
local function getOreFolder()
    if _oreFolder and _oreFolder.Parent then return _oreFolder end
    local f=GC:FindFirstChild("Ores"); if f then _oreFolder=f; return f end
    local ct=GC:FindFirstChild("Contents"); if not ct then return nil end
    for _, w in ipairs(ct:GetChildren()) do
        local wf=w:FindFirstChild("Ores"); if wf then _oreFolder=wf; return wf end
    end
    return nil
end
local function getOreTypes()
    local f=getOreFolder(); if not f then return {} end
    local seen,t={},{}
    for _, ore in ipairs(f:GetChildren()) do
        if not seen[ore.Name] then seen[ore.Name]=true; t[#t+1]=ore.Name end
    end
    table.sort(t); return t
end
local ORE_TYPES=getOreTypes()

-- Capsule parts
local CAPSULE_PARTS={}
do
    local uiZ=GC:FindFirstChild("UIZones")
    if uiZ then
        for _, ct2 in ipairs({"Classic","Super"}) do
            local mdl=uiZ:FindFirstChild("__Capsule"..ct2)
            if mdl then
                CAPSULE_PARTS[ct2]=mdl:FindFirstChild("TouchPart")
                    or mdl:FindFirstChildWhichIsA("BasePart")
                    or mdl:FindFirstChildOfClass("Part")
            end
        end
        if not CAPSULE_PARTS.Classic then
            for _, obj in ipairs(uiZ:GetDescendants()) do
                if obj:IsA("BasePart") then
                    local pn=obj.Parent and obj.Parent.Name or ""
                    if pn:lower():find("capsule") then
                        if pn:lower():find("super") then
                            CAPSULE_PARTS.Super=CAPSULE_PARTS.Super or obj
                        else
                            CAPSULE_PARTS.Classic=CAPSULE_PARTS.Classic or obj
                        end
                    end
                end
            end
        end
    end
end
local CAPSULE_PRICE={Classic=1e9, Super=1e10}
local prismAmountV=nil
pcall(function() prismAmountV=LP.CURRENCIES.Prism.Amount:FindFirstChild("1") end)

-- Hide capsule opening UI overlay
LP.PlayerGui.ChildAdded:Connect(function(child)
    if child.Name=="CapsuleOpeningDisplayFrame" then child.Enabled=false end
end)

-- Potion list (from server)
local POTION_NAMES={}
pcall(function()
    local potF=LP.EXTRA.MONETIZATION.POTIONS
    for _, p in ipairs(potF:GetChildren()) do POTION_NAMES[#POTION_NAMES+1]=p.Name end
    table.sort(POTION_NAMES)
end)
if #POTION_NAMES==0 then POTION_NAMES={"2x Rune Luck","2x Rune Speed","2x Rune Bulk"} end

-- Capsule opened event — server fires this when it detects player in zone
-- Track timestamp so zone-hold loop knows when open was confirmed
local _lastCapsuleOpen = 0
pcall(function()
    NET.MinionCapsuleOpened.OnClientEvent:Connect(function(_,_,_,count)
        capsuleCount=capsuleCount+math.max(tonumber(count) or 1,1)
        _lastCapsuleOpen=tick()
    end)
end)

-- Ice buttons
local ICE_BTN={}
do
    local ct=GC:FindFirstChild("Contents")
    local w2=ct and ct:FindFirstChild("WORLD - 2")
    local ib=w2 and w2:FindFirstChild("IceButtons")
    if ib then
        for i=1,12 do
            local mdl=ib:FindFirstChild(tostring(i))
            if mdl then
                local d={}
                for _, desc in ipairs(mdl:GetDescendants()) do
                    if desc:IsA("ClickDetector") then d.cd=desc; break end
                end
                d.part=mdl:FindFirstChild("ButtonUI") or mdl:FindFirstChildWhichIsA("BasePart")
                ICE_BTN[i]=d
            end
        end
    end
end

-- Equipment helpers
local SLOTS={"Necklace","Special","Ring","Geode"}
local function readEquipped()
    local t={}
    for _, sn in ipairs(SLOTS) do
        t[sn]={}
        local invSlot=LP.FEATURES.EQUIPMENT.Inventory:FindFirstChild(sn)
        local eqSlot =LP.FEATURES.EQUIPMENT.Equipped:FindFirstChild(sn)
        if invSlot then
            for _, item in ipairs(invSlot:GetChildren()) do
                if item:IsA("StringValue") then
                    local eqV=eqSlot and eqSlot:FindFirstChild(item.Name)
                    if eqV and eqV.Value then t[sn][#t[sn]+1]=item.Name end
                end
            end
        elseif eqSlot then
            for _, item in ipairs(eqSlot:GetChildren()) do
                if item:IsA("BoolValue") and item.Value then t[sn][#t[sn]+1]=item.Name end
            end
        end
    end
    return t
end
local function equipItem(sn,id)   pcall(MR.FireServer,MR,"EquipEquipment",  sn,id) end
local function unequipItem(sn,id) pcall(MR.FireServer,MR,"UnequipEquipment",sn,id) end
local function unequipSlot(sn)
    local ef=LP.FEATURES.EQUIPMENT.Equipped:FindFirstChild(sn); if not ef then return end
    for _, item in ipairs(ef:GetChildren()) do
        if item.Value then unequipItem(sn,item.Name); task.wait(0.08) end
    end
end

-- Minion helpers
local MINIONS_F=nil
pcall(function() MINIONS_F=LP.FEATURES.LAB:FindFirstChild("MINIONS") end)
local function equipMinion(id)   pcall(MR.FireServer,MR,"EquipMinion",  id) end
local function unequipMinion(id) pcall(MR.FireServer,MR,"UnequipMinion",id) end
local function unequipAllMinions()
    local ef=MINIONS_F and MINIONS_F:FindFirstChild("Equipped")
    if ef then
        for _, item in ipairs(ef:GetChildren()) do
            if item.Value then unequipMinion(item.Name); task.wait(0.08) end
        end
        return
    end
    local invF=MINIONS_F and MINIONS_F:FindFirstChild("Inventory")
    if not invF then return end
    for _, item in ipairs(invF:GetChildren()) do
        local eqV=item:FindFirstChild("Equipped")
        if eqV and eqV.Value then unequipMinion(item.Name); task.wait(0.08) end
    end
end
local function readMinionEquipped()
    local ids={}
    local ef=MINIONS_F and MINIONS_F:FindFirstChild("Equipped")
    if ef then
        for _, item in ipairs(ef:GetChildren()) do if item.Value then ids[#ids+1]=item.Name end end
    else
        local invF=MINIONS_F and MINIONS_F:FindFirstChild("Inventory")
        if invF then
            for _, item in ipairs(invF:GetChildren()) do
                local eqV=item:FindFirstChild("Equipped")
                if eqV and eqV.Value then ids[#ids+1]=item.Name end
            end
        end
    end
    return ids
end

-- Restore only Special + Minions after prism/coin swap
local RESTORE_SLOTS={"Special"}
local function restoreEquipment(savedEquip, savedMinions)
    if savedEquip then
        for _, sn in ipairs(RESTORE_SLOTS) do
            local ids=savedEquip[sn]
            if ids and #ids>0 then
                unequipSlot(sn); task.wait(0.3)
                for _, id in ipairs(ids) do equipItem(sn,tostring(id)); task.wait(0.18) end
            end
        end
    end
    if savedMinions and #savedMinions>0 then
        unequipAllMinions(); task.wait(0.3)
        for _, id in ipairs(savedMinions) do equipMinion(id); task.wait(0.12) end
    end
end

-- Ore position — Rock can be MeshPart (simple) or Model (Infinity)
local function getOrePos(ore)
    if not (ore and ore.Parent) then return nil end
    local rock=ore:FindFirstChild("Rock"); if not rock then return nil end
    if rock:IsA("BasePart") then return rock.Position end
    local pp=rock.PrimaryPart; if pp then return pp.Position end
    local bp=rock:FindFirstChildWhichIsA("BasePart",true); return bp and bp.Position
end

-- Ore HP from OresTopUI.Bar.Health (TextLabel, text = "cur/max" or "cur")
-- Returns 0 if broken, -1 if no label (assume alive), >0 if alive
local function getOreHP(ore)
    if not (ore and ore.Parent) then return 0 end
    local ui=ore:FindFirstChild("OresTopUI")
    local bar=ui and ui:FindFirstChild("Bar")
    local lbl=bar and bar:FindFirstChild("Health")
    if not lbl then return -1 end
    local cur=tonumber(lbl.Text:match("^([%d%.]+)")) or 0
    return cur
end

-- Snap BELOW center of TouchPart — puts HRP inside the lower half of the zone
-- Center is too high if physics pushes character up; -3 keeps feet inside zone
local function capsuleEnterCF(part)
    local p=part.Position
    return CFrame.new(p.X, p.Y - 3, p.Z)
end

-- Test result: server needs ≥50ms in zone before accepting OpenCapsule fire.
-- Phase 1: snap 60ms (1+ server tick) → Phase 2: fire once → Phase 3: wait confirm.
-- Total per capsule: ~60ms snap + ~85ms confirm = ~145ms, then release.
local function holdAndFire(ctype, enterCF, hrp, timeout)
    local prev=_lastCapsuleOpen
    local t0=tick()
    repeat hrp.CFrame=enterCF; task.wait(0.02) until tick()-t0>=0.06
    fire("OpenCapsule", ctype)
    local tFire=tick()
    repeat hrp.CFrame=enterCF; task.wait(0.02) until _lastCapsuleOpen~=prev or tick()-tFire>timeout
    return _lastCapsuleOpen~=prev
end

local function withCapsuleZone(ctype)
    local part=CAPSULE_PARTS[ctype]; local hrp=getHRP()
    if not (part and hrp) then fire("OpenCapsule",ctype); return end
    local enterCF=capsuleEnterCF(part)
    capsuleBusy=true
    holdAndFire(ctype, enterCF, hrp, 3)
    capsuleBusy=false
end

local function bulkCapsules(ctype, cond)
    local timeout=tick()+5
    while capsuleBusy and tick()<timeout do task.wait(0.1) end
    local part=CAPSULE_PARTS[ctype]
    if not part then return 0 end
    local enterCF=capsuleEnterCF(part)
    local count=0
    while cond() do
        local h=getHRP(); if not h then break end
        capsuleBusy=true
        local ok=holdAndFire(ctype, enterCF, h, 3)
        capsuleBusy=false
        if not ok then break end
        count=count+1
        task.wait(0.3)
    end
    return count
end

-- Aura inventory
local ownedAuras={}
do
    local ai=LP.FEATURES.AURAS:FindFirstChild("Inventory")
    if ai then
        for _, v in ipairs(ai:GetChildren()) do
            if v:IsA("BoolValue") and v.Value then ownedAuras[#ownedAuras+1]=v.Name end
        end
        table.sort(ownedAuras)
    end
end
local prismCooldownV=nil
pcall(function() prismCooldownV=LP.FEATURES.PRISMS:FindFirstChild("_cooldown") end)

-- ─── Character Respawn — reset position locks ──────────────────────────────
LP.CharacterAdded:Connect(function()
    capsuleBusy=false
end)

-- ─── Rune Data ────────────────────────────────────────────────────────────────
local RUNE_ZONES={
    {name="Basic Rune", invKey="Basic", runes={
        {n="Rookie",c=1.25,cl="Basic"},{n="Learner",c=6.67,cl="Basic"},
        {n="Trained",c=33.29,cl="Basic"},{n="Skilled",c=200,cl="Basic"},
        {n="Expert",c=5e4,cl="Basic"},{n="Master",c=1e6,cl="Basic"},
        {n="Grandmaster",c=4e7,cl="Basic"},{n="Celestial",c=6.25e11,cl="Basic"},
        {n="Immortal",c=7.69e26,cl="Basic"},
        {n="Shadow",c=1e22,cl="Noobinial"},{n="Phantom",c=1e28,cl="Noobinial"},
        {n="Atomic",c=1.33e48,cl="Noobinial"},{n="Chronos Core",c=3.08e49,cl="Noobinial"},
    }},
    {name="Super Runes", invKey="Super", runes={
        {n="Initiate",c=1.11,cl="Basic"},{n="Adept",c=13.3,cl="Basic"},
        {n="Veteran",c=50,cl="Basic"},{n="Elite",c=5e3,cl="Basic"},
        {n="Champion",c=2e5,cl="Basic"},{n="Ascended",c=2e6,cl="Basic"},
        {n="Transcendent",c=5e7,cl="Basic"},{n="Universal",c=2e19,cl="Basic"},
        {n="Omnipotent",c=1.75e28,cl="Basic"},
        {n="Eclipse",c=1e24,cl="Noobinial"},{n="Void",c=1e31,cl="Noobinial"},
        {n="Primordial",c=2.5e37,cl="Noobinial"},{n="Oblivion Sigil",c=2.35e51,cl="Noobinial"},
    }},
    {name="Advanced Runes", invKey="Advanced", runes={
        {n="Little",c=1.01,cl="Basic"},{n="Lesser",c=1e5,cl="Basic"},
        {n="Standard",c=1e6,cl="Basic"},{n="Greater",c=5e7,cl="Basic"},
        {n="Superior",c=2e8,cl="Basic"},{n="Prime",c=1e11,cl="Basic"},
        {n="Apex",c=1e12,cl="Basic"},{n="Ethereal",c=5e13,cl="Basic"},
        {n="Divine",c=2e17,cl="Basic"},{n="Infinite",c=1.75e28,cl="Basic"},
        {n="Abyss",c=1e26,cl="Noobinial"},{n="Enigma",c=1e34,cl="Noobinial"},
        {n="Seraphim's Tear",c=4e44,cl="Noobinial"},{n="Aetherion",c=1.21e53,cl="Noobinial"},
    }},
    {name="Cosmic Prism", invKey="Cosmic Prism", special=true, runes={
        {n="Lucent",c=2.5,cl="Basic"},{n="Chroma",c=4,cl="Basic"},
        {n="Fractal",c=20,cl="Basic"},{n="Refraction",c=100,cl="Basic"},
        {n="Tessellation",c=200,cl="Basic"},{n="Hyperlight",c=333,cl="Basic"},
        {n="PrismGod",c=1e3,cl="Basic"},{n="Voidglass",c=1e6,cl="Basic"},
        {n="Godshard",c=1e8,cl="Noobinial"},{n="Ultimate Shard",c=6.67e11,cl="Noobinial"},
    }},
    {name="Hacker Runes", invKey="Hacker", runes={
        {n="Script",c=1.01,cl="Basic"},{n="Protocol",c=1e17,cl="Basic"},
        {n="Cipher",c=1e22,cl="Basic"},{n="Exploit",c=1e27,cl="Basic"},
        {n="Kernel",c=1e30,cl="Basic"},{n="Root",c=1e33,cl="Basic"},
        {n="Backdoor",c=1e36,cl="Basic"},
        {n="Rootkit",c=1e27,cl="Noobinial"},{n="Masterkey",c=2e28,cl="Noobinial"},
        {n="Stuxnet",c=6.98e31,cl="Noobinial"},
    }},
    {name="Snowy Runes", invKey="Snowy", runes={
        {n="Snow",c=1.01,cl="Basic"},{n="Frost",c=1e18,cl="Basic"},
        {n="Ice",c=1e20,cl="Basic"},{n="Hail",c=2e21,cl="Basic"},
        {n="Glacier",c=1e26,cl="Basic"},{n="Blizzard",c=5e41,cl="Basic"},
        {n="Tundra",c=2e45,cl="Basic"},{n="Arctic",c=4e59,cl="Basic"},
        {n="Permafrost",c=1.9e65,cl="Basic"},
        {n="Whiteout",c=4e53,cl="Noobinial"},{n="Icebound",c=3.33e56,cl="Noobinial"},
        {n="Everfrost",c=2.5e59,cl="Noobinial"},
    }},
}

-- ─── Profile Stat Reader ──────────────────────────────────────────────────────
local function readProfileStats()
    local rps,cd,luck,rawRps,rawCd,rawLuck=nil,nil,nil,"?","?","?"
    pcall(function()
        local profileGui=LP.PlayerGui:FindFirstChild("Profile")
        local statsF=profileGui and profileGui:FindFirstChild("Stats",true)
        if not statsF then
            local ok2,s=pcall(function()
                return LP.PlayerGui.Profile.Main.Frame.Main.ScrollingFrame.MainProfile.Profile.Stats
            end)
            if ok2 then statsF=s end
        end
        if not statsF then return end
        local function readStat(name)
            local node=statsF:FindFirstChild(name)
            if not node then return nil,"missing:"..name end
            for _, child in ipairs({"Amount","Value","Label"}) do
                local c=node:FindFirstChild(child)
                if c and c:IsA("TextLabel") and c.Text and c.Text~="" then
                    return parseNum(c.Text),c.Text
                end
            end
            if node:IsA("TextLabel") and node.Text and node.Text~="" then
                return parseNum(node.Text),node.Text
            end
            return nil,"no-text"
        end
        rps,rawRps=readStat("RPS")
        cd,rawCd  =readStat("RuneSpeed")
        luck,rawLuck=readStat("RuneLuck")
    end)
    if (not rps or rps<=0) and (cd and cd>0) then rps=1/cd end
    return rps,cd,luck,rawRps,rawCd,rawLuck
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- GAME LOOPS
-- ═══════════════════════════════════════════════════════════════════════════════
local UPGRADE_TYPES={"Ice","Fire","Blaze","Water","Oof","Rebirth","Wood","Planks","Bread","Cash","Coin","HackPoints","Gem"}

-- Tier (fast)
safeLoop(0.1, function()
    if S.tier then fire("RollTier") end
end)

-- Farm / combat (1s)
safeLoop(1, function()
    if S.wheat   then for _, w in ipairs(wheatCDs) do cdet(w) end end
    if S.deposit then fire("DepositWheat") end
    if S.waterFarm  then fire("Water") end
    if S.campfire   then fire("CampfireButton") end
    if S.ashConvert then fire("ConvertWoodToAsh") end
    if S.hireNoob   then fire("HireNoob") end
    if S.fillBucket then fire("FillBucket") end
    if S.factory    then fire("Factory") end
    if S.cook       then fire("Cook") end
    if S.animals    then fire("Animals") end
    if S.mutation   then fire("Mutation") end
    if S.autoNoob and #selectedNoobs>0 then
        for _, nt in ipairs(selectedNoobs) do fire("UpgradeNoobMax",nt) end
    end
    if S.exchangeOre then fire("ExchangeAllMinerals") end
    if S.blaze or S.upgradeQuest then fire("Blaze") end
    if S.chest then fire("OpenChest",selectedChest) end
end)

-- Automations (3s)
safeLoop(3, function()
    for _, ut in ipairs(UPGRADE_TYPES) do
        if S[ut] or (ut=="Fire" and S.upgradeQuest) then
            fire("SetUpgradeAutomationPaused",ut,false)
        end
    end
    if S.awaken then fire("AwakenTier") end
end)

-- Potions (15s)
safeLoop(15, function()
    if not S.autoPot or #selectedPotions==0 then return end
    local potF=LP.EXTRA:FindFirstChild("MONETIZATION") and LP.EXTRA.MONETIZATION:FindFirstChild("POTIONS")
    if not potF then return end
    for _, name in ipairs(selectedPotions) do
        local p=potF:FindFirstChild(name); if not p then continue end
        local tl=p:FindFirstChild("TimeLeft"); local cap=p:FindFirstChild("Capacity")
        if (cap and tonumber(cap.Value) or 0)>0 and (tl and tonumber(tl.Value) or 0)<60 then
            fire("UsePotion",name,1)
        end
    end
end)

-- Guild rewards (120s)
safeLoop(120, function()
    if not S.autoGuildClaim then return end
    task.spawn(function()
        local ok,r=pcall(function() return NET.ClaimAllGuildWeeklyRewards:InvokeServer() end)
        if ok and r and tostring(r)~="false" and tostring(r)~="" then
            notify("🏛 Guild","Rewards claimed!",5)
        end
    end)
end)

-- Capsule auto-open (4s)
safeLoop(4, function()
    if not S.minionCap then return end
    local price=CAPSULE_PRICE[selectedMinCap] or 1e9
    if (prismAmountV and tonumber(prismAmountV.Value) or 0)<price then return end
    withCapsuleZone(selectedMinCap, function() fire("OpenCapsule",selectedMinCap) end)
end)

-- Upgrade trees (5s)
task.spawn(function()
    while true do
        pcall(function()
            for _, tn in ipairs(TREE_NAMES) do
                if S[tn] and treeCDs[tn] then
                    for _, d in ipairs(treeCDs[tn]) do cdet(d); task.wait(0.05) end
                end
            end
        end)
        task.wait(5)
    end
end)

-- Ice farm (2s) — skipped while capsuleBusy; position restored only if still safe
safeLoop(2, function()
    if not S.iceFarm or capsuleBusy then return end
    local d=ICE_BTN[selectedIceBtn]
    if not (d and d.part) then fire("Ice",selectedIceBtn); return end
    local hrp=getHRP(); if not hrp then return end
    local origin=hrp.CFrame
    hrp.CFrame=CFrame.new(d.part.Position+Vector3.new(0,3,0))
    task.wait(iceTeleportWait)
    fire("Ice",selectedIceBtn)
    task.wait(0.15)
    if not capsuleBusy then hrp.CFrame=origin end
end)

-- Mining loop — stay on current ore until HP = 0, then pick nearest next
local _miningOre = nil
task.spawn(function()
    while true do
        task.wait(0.1)
        if not (S.mining and next(selectedOres)~=nil) or capsuleBusy then
            _miningOre = nil
        else
            local folder=getOreFolder(); local hrp=getHRP()
            if folder and hrp then
                -- Check if current ore is still alive
                local alive = _miningOre
                    and _miningOre.Parent
                    and getOreHP(_miningOre) ~= 0
                if not alive then
                    -- Pick nearest live ore
                    local best,bd=nil,math.huge
                    for _,ore in ipairs(folder:GetChildren()) do
                        if selectedOres[ore.Name] and ore.Parent and getOreHP(ore)~=0 then
                            local pos=getOrePos(ore)
                            if pos then
                                local dd=(pos-hrp.Position).Magnitude
                                if dd<bd then bd=dd; best=ore end
                            end
                        end
                    end
                    _miningOre=best
                end
                -- Teleport/walk to current ore
                if _miningOre and _miningOre.Parent then
                    local pos=getOrePos(_miningOre)
                    if pos then
                        if S.miningMode=="teleport" then
                            hrp.CFrame=CFrame.new(pos.X, pos.Y, pos.Z)
                        else
                            local hum=getHum(); if hum then hum:MoveTo(pos) end
                        end
                    end
                end
            end
        end
    end
end)

-- Rune rolling — dedicated loop, no safeLoop to keep precise interval
task.spawn(function()
    while true do
        if S.runes and #selectedRunes>0 then
            for _, rune in ipairs(selectedRunes) do
                pcall(MR.FireServer,MR,"RollRune",rune)
            end
            task.wait(math.max(0.155,runeInterval))
        else task.wait(0.1) end
    end
end)

-- Auto Prism
local prismArmed=false
safeLoop(0.5, function()
    if not (S.autoPrism and prismCooldownV) then return end
    local secs=tonumber(prismCooldownV.Value)
    if secs and secs<=3 and not prismArmed then
        prismArmed=true
        local savedEquip  =readEquipped()
        local savedMinions=readMinionEquipped()
        fire("EquipBestMinions","Prism")
        fire("EquipBest","Prism")
        notify("⭐ Prism","~"..math.floor(secs).."s before payout",4)
        pcall(function()
            task.wait(math.max(secs,0.5)+1.5)
            restoreEquipment(savedEquip,savedMinions)
        end)
        notify("⭐ Prism","✅ Restored",3)
        task.wait(3)
        prismArmed=false
    end
end)

-- Auto Coin Farm
local coinArmed=false
task.spawn(function()
    while true do
        if S.autoCoinFarm and not coinArmed then
            coinArmed=true
            pcall(function()
                local savedEquip  =readEquipped()
                local savedMinions=readMinionEquipped()
                fire("EquipBest","Coin")
                fire("EquipBestMinions","Coin")
                task.wait(2)
                fire("ExchangeAllAnimalProducts")
                task.wait(0.5)
                for _, m in ipairs(selectedMilestones) do fire("DepositCoinMilestone",m); task.wait(0.2) end
                task.wait(0.5)
                restoreEquipment(savedEquip,savedMinions)
                task.wait(0.5)
            end)
            coinArmed=false
            task.wait(coinInterval)
        else task.wait(2) end
    end
end)

-- ═══════════════════════════════════════════════════════════════════════════════
-- GUI — FLUENT
-- ═══════════════════════════════════════════════════════════════════════════════
local Window=Fluent:CreateWindow({
    Title       = "Noob Incremental",
    SubTitle    = "v8.0 · @Benefit",
    TabWidth    = 155,
    Size        = UDim2.fromOffset(610, 500),
    Theme       = "Dark",
    MinimizeKey = Enum.KeyCode.RightControl,
})

local Tabs={
    Farm    = Window:AddTab({ Title="🌾 Farm",    Icon="wheat"       }),
    W2      = Window:AddTab({ Title="❄️ W2 / Cap",Icon="snowflake"   }),
    Mine    = Window:AddTab({ Title="⛏️ Mine",    Icon="pickaxe"     }),
    Runes   = Window:AddTab({ Title="🎲 Runes",   Icon="shuffle"     }),
    Upgrade = Window:AddTab({ Title="⬆️ Upgrade", Icon="trending-up" }),
    Gear    = Window:AddTab({ Title="🎒 Gear",    Icon="shield"      }),
}

-- Visual divider — horizontal line between sections
local function div(T)
    T:AddParagraph({Title="",Content="━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"})
end
-- Section header
local function hdr(T, text)
    T:AddParagraph({Title=text, Content=""})
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- TAB 1 — 🌾 Farm
-- ═══════════════════════════════════════════════════════════════════════════════
do local T=Tabs.Farm

hdr(T,"🌾  Wheat")
T:AddToggle("farmWheat",  {Title="Auto Wheat",  Default=S.wheat  }):OnChanged(function(v) S.wheat=v;   saveSettings() end)
T:AddToggle("farmDeposit",{Title="Auto Deposit",Default=S.deposit}):OnChanged(function(v) S.deposit=v; saveSettings() end)

div(T)
hdr(T,"🏭  Processing")
T:AddToggle("factory", {Title="Factory",  Default=S.factory  }):OnChanged(function(v) S.factory=v;   saveSettings() end)
T:AddToggle("cook",    {Title="Cook",     Default=S.cook     }):OnChanged(function(v) S.cook=v;      saveSettings() end)
T:AddToggle("animals", {Title="Animals",  Default=S.animals  }):OnChanged(function(v) S.animals=v;   saveSettings() end)
T:AddToggle("mutation",{Title="Mutation", Default=S.mutation }):OnChanged(function(v) S.mutation=v;  saveSettings() end)

div(T)
hdr(T,"🔧  Extras")
T:AddToggle("campfire",  {Title="Campfire",   Default=S.campfire  }):OnChanged(function(v) S.campfire=v;   saveSettings() end)
T:AddToggle("waterFarm", {Title="Water",      Default=S.waterFarm }):OnChanged(function(v) S.waterFarm=v;  saveSettings() end)
T:AddToggle("ashConvert",{Title="Wood → Ash", Default=S.ashConvert}):OnChanged(function(v) S.ashConvert=v; saveSettings() end)
T:AddToggle("fillBucket",{Title="Fill Bucket",Default=S.fillBucket}):OnChanged(function(v) S.fillBucket=v; saveSettings() end)
T:AddToggle("hireNoob",  {Title="Hire Noob",  Default=S.hireNoob  }):OnChanged(function(v) S.hireNoob=v;  saveSettings() end)

div(T)
hdr(T,"👶  Noob Upgrades")
T:AddDropdown("noobTypes",{Title="Types",Values={"Starter","Explorer","Knight","Fisherman","Cooker","Farmer","Archer","Soldier","Magician","Hacker 1","Hacker 2","Hacker 3","Hacker 4"},Multi=true,Default=toDict(selectedNoobs)}):OnChanged(function(v)
    selectedNoobs={}; for k,_ in pairs(v) do selectedNoobs[#selectedNoobs+1]=k end; saveSettings()
end)
T:AddToggle("autoNoob",{Title="Auto Upgrade",Default=S.autoNoob}):OnChanged(function(v) S.autoNoob=v; saveSettings() end)
T:AddButton({Title="Upgrade Now ×30",Callback=function()
    if #selectedNoobs==0 then notify("👶","Select types first",3); return end
    task.spawn(function()
        for _, nt in ipairs(selectedNoobs) do
            for _=1,30 do pcall(MR.FireServer,MR,"UpgradeNoobMax",nt); task.wait(0.15) end
        end; notify("👶","Done",3)
    end)
end})

div(T)
hdr(T,"📦  Chests")
T:AddDropdown("chestType",{Title="Type",Values={"Chest","GoldenChest"},Multi=false,Default=selectedChest}):OnChanged(function(v) selectedChest=v; saveSettings() end)
T:AddToggle("autoChest",{Title="Auto Open",Default=S.chest}):OnChanged(function(v) S.chest=v; saveSettings() end)
T:AddButton({Title="Open 200 Now",Callback=function()
    task.spawn(function()
        for _=1,200 do fire("OpenChest",selectedChest); task.wait(0.5) end
        notify("📦","200 opened",4)
    end)
end})

div(T)
hdr(T,"🏛  Guild")
T:AddToggle("autoGuild",{Title="Auto Claim  (every 2 min)",Default=S.autoGuildClaim}):OnChanged(function(v) S.autoGuildClaim=v; saveSettings() end)
T:AddButton({Title="Claim Now",Callback=function()
    task.spawn(function()
        local ok,r=pcall(function() return NET.ClaimAllGuildWeeklyRewards:InvokeServer() end)
        notify("🏛",ok and tostring(r) or "Error",5)
    end)
end})
T:AddButton({Title="Check Status",Callback=function()
    task.spawn(function()
        local ok,d=pcall(function() return NET.GetMyGuildWeeklyRewards:InvokeServer() end)
        if not ok or type(d)~="table" then notify("🏛","No data",4); return end
        local pts=tonumber(d.Points) or 0; local cl,tot=0,0
        if type(d.Rewards)=="table" then
            for _, rw in ipairs(d.Rewards) do tot=tot+1; if rw.CanClaim and not rw.Claimed then cl=cl+1 end end
        end
        notify("🏛","Pts "..fmtNum(pts).."  |  "..cl.."/"..tot.." claimable",8)
    end)
end})

end -- Farm

-- ═══════════════════════════════════════════════════════════════════════════════
-- TAB 2 — ❄️ W2 / Cap
-- ═══════════════════════════════════════════════════════════════════════════════
do local T=Tabs.W2

hdr(T,"❄️  Ice Farm")
T:AddDropdown("iceBtn",{Title="Ice Button",Values={"1","2","3","4","5","6","7","8","9","10","11","12"},Multi=false,Default=tostring(selectedIceBtn)}):OnChanged(function(v) selectedIceBtn=tonumber(v) or 12; saveSettings() end)
T:AddSlider("iceTW",{Title="Teleport Delay (s)",Default=iceTeleportWait,Min=0.05,Max=2.0,Rounding=2}):OnChanged(function(v) iceTeleportWait=v; saveSettings() end)
T:AddToggle("iceFarm",{Title="❄️  Ice Farm ON",Default=S.iceFarm}):OnChanged(function(v) S.iceFarm=v; saveSettings() end)

div(T)
hdr(T,"🎱  Capsule — Auto Open")
T:AddDropdown("capZone",{Title="Zone",Values={"Classic","Super"},Multi=false,Default=selectedMinCap}):OnChanged(function(v) selectedMinCap=v; saveSettings() end)
T:AddToggle("autoCap",{Title="🎱  Auto Capsule ON",Default=S.minionCap}):OnChanged(function(v) S.minionCap=v; saveSettings() end)

div(T)
hdr(T,"🎱  Capsule — Bulk Open")
local capLabelPara=T:AddParagraph({Title="Session",Content="Opened: 0"})
T:AddButton({Title="Open All  (until Prism runs out)",Callback=function()
    task.spawn(function()
        local price=CAPSULE_PRICE[selectedMinCap] or 1e9
        local n=bulkCapsules(selectedMinCap,function()
            return (prismAmountV and tonumber(prismAmountV.Value) or 0)>=price
        end)
        notify("🎱","Opened "..n,4)
    end)
end})

div(T)
hdr(T,"🗺️  Teleport")
T:AddButton({Title="→ Classic Capsule Zone",Callback=function()
    local p=CAPSULE_PARTS.Classic; local h=getHRP()
    if p and h then h.CFrame=CFrame.new(p.Position+Vector3.new(0,4,0)) else notify("❌","Not found",3) end
end})
T:AddButton({Title="→ Super Capsule Zone",Callback=function()
    local p=CAPSULE_PARTS.Super; local h=getHRP()
    if p and h then h.CFrame=CFrame.new(p.Position+Vector3.new(0,4,0)) else notify("❌","Not found",3) end
end})

end -- W2

-- ═══════════════════════════════════════════════════════════════════════════════
-- TAB 3 — ⛏️ Mine
-- ═══════════════════════════════════════════════════════════════════════════════
do local T=Tabs.Mine

hdr(T,"⛏️  Ore Selection  ("..(#ORE_TYPES>0 and #ORE_TYPES.." found" or "scan failed")..")")
local savedOreList={}
for nm,v in pairs(selectedOres) do if v then savedOreList[#savedOreList+1]=nm end end
T:AddDropdown("oreList",{Title="Ore Types",Values=(#ORE_TYPES>0 and ORE_TYPES or {"(none)"}),Multi=true,Default=toDict(savedOreList)}):OnChanged(function(v)
    selectedOres={}; for k,_ in pairs(v) do selectedOres[k]=true end; saveSettings()
end)
T:AddButton({Title="Select All",Callback=function()
    selectedOres={}
    for _, nm in ipairs(getOreTypes()) do selectedOres[nm]=true end
    local c=0; for _ in pairs(selectedOres) do c=c+1 end
    saveSettings(); notify("⛏️",c.." types selected",4)
end})

div(T)
hdr(T,"⚙️  Settings")
T:AddToggle("miningTeleport",{Title="Teleport  (OFF = walk)",Default=S.miningMode=="teleport"}):OnChanged(function(v) S.miningMode=v and "teleport" or "walk"; saveSettings() end)
T:AddToggle("autoMine",    {Title="⛏️  Auto Mine ON",      Default=S.mining     }):OnChanged(function(v) S.mining=v;       saveSettings() end)
T:AddToggle("exchangeOre", {Title="Auto Exchange Minerals", Default=S.exchangeOre}):OnChanged(function(v) S.exchangeOre=v; saveSettings() end)

end -- Mine

-- ═══════════════════════════════════════════════════════════════════════════════
-- TAB 4 — 🎲 Runes
-- ═══════════════════════════════════════════════════════════════════════════════
do local T=Tabs.Runes

hdr(T,"🎲  Zone Roll")
T:AddDropdown("runeZones",{Title="Active Zones",Values={"Basic","Super","Advanced","Cosmic Prism","Hacker","Snowy","Deepcore"},Multi=true,Default=toDict(selectedRunes)}):OnChanged(function(v)
    selectedRunes={}; for k,_ in pairs(v) do selectedRunes[#selectedRunes+1]=k end; saveSettings()
end)
T:AddSlider("runeInt",{Title="Interval (s)  [min 0.155]",Default=math.max(runeInterval,0.155),Min=0.15,Max=2.0,Rounding=2}):OnChanged(function(v) runeInterval=v; saveSettings() end)
T:AddToggle("runeToggle",{Title="🎲  Auto Roll ON",Default=S.runes}):OnChanged(function(v) S.runes=v; saveSettings() end)

div(T)
hdr(T,"🎰  Aura Roll")
T:AddSlider("rollCnt",{Title="Count",Default=rollCount,Min=100,Max=2000,Rounding=0}):OnChanged(function(v) rollCount=v; saveSettings() end)
local rollActive=false
local rollPara=T:AddParagraph({Title="Status",Content="—"})
T:AddButton({Title="▶  Roll Auras",Callback=function()
    if rollActive then return end; rollActive=true
    task.spawn(function()
        local total=rollCount; notify("🎰",total.." rolls…",3)
        for i=1,total do
            if not rollActive then break end
            pcall(MR.FireServer,MR,"RollAura")
            if i%25==0 then
                local ok,au=pcall(function() return LP.FEATURES.AURAS.Equipped.Value end)
                rollPara:Set({Title="Rolling",Content=i.."/"..total.."  "..(ok and au or "?")})
            end
            task.wait(0.15)
        end
        local ok2,au2=pcall(function() return LP.FEATURES.AURAS.Equipped.Value end)
        rollPara:Set({Title="Done",Content=total.." rolls  |  "..(ok2 and au2 or "?")})
        notify("🎰 Done","Aura: "..(ok2 and au2 or "?"),6); rollActive=false
    end)
end})
T:AddButton({Title="⏹  Stop",Callback=function()
    rollActive=false; rollPara:Set({Title="Stopped",Content="—"})
end})

div(T)
hdr(T,"📊  Stats")
local rpsPara  =T:AddParagraph({Title="⚡ RPS",   Content="—"})
local luckPara =T:AddParagraph({Title="🍀 Luck",  Content="—"})
local cdPara   =T:AddParagraph({Title="⏱ CD",     Content="—"})
local pressPara=T:AddParagraph({Title="🏆 Tier",  Content="—"})
T:AddInput("runeLuck",{Title="Luck Override",Default=manualRuneLuck and tostring(manualRuneLuck) or "",Placeholder="e.g. 1e6",Numeric=false,Finished=true}):OnChanged(function(txt)
    local v=parseNum(txt)
    if v and v>0 then manualRuneLuck=v; saveSettings(); notify("🍀","Luck = "..fmtNum(v),4) end
end)

div(T)
hdr(T,"📐  Rune ETA  (★ = Noobinial / no luck)")
local zoneParagraphs={}
for _, zone in ipairs(RUNE_ZONES) do
    zoneParagraphs[zone.name]=T:AddParagraph({Title=zone.name,Content="—"})
end

local function updateChances()
    pcall(function()
        local tierF=LP.FEATURES:FindFirstChild("TIER")
        local pr=LP.FEATURES:FindFirstChild("PrestigeAmount") and tonumber(LP.FEATURES.PrestigeAmount.Value) or 0
        local aw=tierF and tierF:FindFirstChild("Awakening") and tonumber(tierF.Awakening.Value) or 0
        local ti=tierF and tierF:FindFirstChild("Tier")      and tonumber(tierF.Tier.Value)      or 0
        pressPara:Set({Title="🏆 Tier",Content="Prestige "..pr.."  |  Tier "..ti.."  |  Awaken "..aw})
    end)
    local rps,cd,autoLuck,rawRps,rawCd,rawLuck=readProfileStats()
    local luck=manualRuneLuck or autoLuck
    rpsPara:Set( {Title="⚡ RPS",  Content=(rps  and fmtNum(rps)               or "?").."  (raw: "..(rawRps or "?")..")"})
    cdPara:Set(  {Title="⏱ CD",   Content=(cd   and string.format("%.3fs",cd)  or "?").."  (raw: "..(rawCd  or "?")..")"})
    luckPara:Set({Title="🍀 Luck", Content=(luck and fmtNum(luck)              or "? — enter above").."  (raw: "..(rawLuck or "?")..")"})
    for _, zone in ipairs(RUNE_ZONES) do
        local para=zoneParagraphs[zone.name]; if not para then continue end
        local invF=nil
        pcall(function() invF=LP.FEATURES.RUNES.INVENTORY:FindFirstChild(zone.invKey) end)
        local lines={}
        for _, rune in ipairs(zone.runes) do
            local owned=0
            if invF then
                local rv=invF:FindFirstChild(rune.n)
                    or (rune.n=="Exploit"        and invF:FindFirstChild("Expliot"))
                    or (rune.n=="Ultimate Shard" and invF:FindFirstChild("UltimateShard"))
                if rv then local ok,v2=pcall(function() return rv.Value end); if ok then owned=tonumber(v2) or 0 end end
            end
            local eta="?"
            if rps and rps>0 then
                local power
                if zone.special then power=rps
                elseif rune.cl=="Noobinial" then power=rps
                else if luck and luck>0 then power=rps*luck end end
                eta=power and fmtTime(rune.c/power) or "need luck"
            end
            lines[#lines+1]=(rune.cl=="Noobinial" and "★ " or "  ")
                ..rune.n..(owned>0 and " ["..owned.."]" or "").."  →  "..eta
        end
        para:Set({Title=zone.name,Content=table.concat(lines,"\n")})
    end
end

T:AddButton({Title="📐  Calculate ETA",Callback=function() task.spawn(updateChances) end})

div(T)
hdr(T,"🗺️  Go to Zone")
for _, zn in ipairs({"Basic","Super","Advanced","Cosmic Prism","Hacker","Snowy","Deepcore"}) do
    local z=zn
    T:AddButton({Title="→  "..z,Callback=function()
        local hrp=getHRP(); if not hrp then return end
        pcall(function()
            local zonesF=GC:FindFirstChild("RuneZones")
            local zone=zonesF and zonesF:FindFirstChild(z)
            if zone then local p=zone:GetPivot(); hrp.CFrame=CFrame.new(p.X,p.Y+5,p.Z); return end
            for _, obj in ipairs(workspace:GetDescendants()) do
                if obj.Name==z and (obj:IsA("Model") or obj:IsA("BasePart")) then
                    local pos=obj:IsA("Model") and obj:GetPivot().Position or obj.Position
                    hrp.CFrame=CFrame.new(pos.X,pos.Y+5,pos.Z); return
                end
            end
            notify("❌",z.." not found",3)
        end)
    end})
end

end -- Runes

-- ═══════════════════════════════════════════════════════════════════════════════
-- TAB 5 — ⬆️ Upgrade
-- ═══════════════════════════════════════════════════════════════════════════════
do local T=Tabs.Upgrade

hdr(T,"⚔️  Tier & Combat")
T:AddToggle("autoTier",    {Title="Auto Tier Roll",    Default=S.tier        }):OnChanged(function(v) S.tier=v;          saveSettings() end)
T:AddToggle("awaken",      {Title="Auto Awaken",       Default=S.awaken      }):OnChanged(function(v) S.awaken=v;        saveSettings() end)
T:AddToggle("blaze",       {Title="Auto Blaze",        Default=S.blaze       }):OnChanged(function(v) S.blaze=v;         saveSettings() end)
T:AddToggle("upgradeQuest",{Title="Auto Quest Upgrade", Default=S.upgradeQuest}):OnChanged(function(v)
    S.upgradeQuest=v; saveSettings()
    if v then fire("SetUpgradeAutomationPaused","Fire",false) end
end)

div(T)
hdr(T,"🌳  Upgrade Trees  (auto-click every 5s)")
local upgradeTreeF=GC:FindFirstChild("UpgradeTree")
for _, entry in ipairs({
    {"🌱 Starter","StarterTree"},{"🏙️ Tycoon","TycoonTree"},
    {"🌾 Farm","FarmTree"},{"💎 Prism","PrismTree"},
    {"❄️ Ice","IceTree"},{"⛏️ Mining","MiningTree"},
}) do
    local label,tnKey=entry[1],entry[2]
    local cnt=treeCDs[tnKey] and #treeCDs[tnKey] or 0
    T:AddToggle("tree_"..tnKey,{Title=label..(cnt>0 and "  ("..cnt..")" or ""),Default=S[tnKey]}):OnChanged(function(v) S[tnKey]=v; saveSettings() end)
end

div(T)
hdr(T,"🗺️  Go to Tree")
for _, entry in ipairs({
    {"🌱 Starter","StarterTree"},{"🏙️ Tycoon","TycoonTree"},
    {"🌾 Farm","FarmTree"},{"💎 Prism","PrismTree"},
    {"❄️ Ice","IceTree"},{"⛏️ Mining","MiningTree"},
}) do
    local label,treeName=entry[1],entry[2]
    T:AddButton({Title="→  "..label,Callback=function()
        local hrp=getHRP(); if not hrp then return end
        pcall(function()
            local tree=upgradeTreeF and upgradeTreeF:FindFirstChild(treeName)
            if tree then local p=tree:GetPivot(); hrp.CFrame=CFrame.new(p.X,p.Y+5,p.Z)
            else notify("❌",treeName.." not found",3) end
        end)
    end})
end

div(T)
hdr(T,"🤖  Automations  (kept unpaused every 3s)")
local upgradesF=LP.FEATURES:FindFirstChild("AUTOMATIONS") and LP.FEATURES.AUTOMATIONS:FindFirstChild("Upgrades")
for _, ut in ipairs(UPGRADE_TYPES) do
    local folder=upgradesF and upgradesF:FindFirstChild(ut)
    if folder then
        local locked=(function() local uV=folder:FindFirstChild("Unlocked"); return uV and not uV.Value end)()
        local utKey=ut
        T:AddToggle("upg_"..utKey,{Title=ut..(locked and "  🔒" or ""),Default=S[utKey]}):OnChanged(function(v) S[utKey]=v; saveSettings() end)
    end
end

end -- Upgrade

-- ═══════════════════════════════════════════════════════════════════════════════
-- TAB 6 — 🎒 Gear
-- ═══════════════════════════════════════════════════════════════════════════════
do local T=Tabs.Gear

hdr(T,"⭐  Auto Prism")
T:AddParagraph({Title="",Content="Equips best Prism gear ~3s before payout, then restores"})
T:AddToggle("autoPrism",{Title="⭐  Auto Prism ON",Default=S.autoPrism}):OnChanged(function(v) S.autoPrism=v; saveSettings() end)

div(T)
hdr(T,"🪙  Coin Farm")
T:AddParagraph({Title="",Content="Equip Coin gear → exchange animals → deposit milestones → restore"})
T:AddToggle("autoCoinFarm",{Title="🪙  Auto Coin Farm ON",Default=S.autoCoinFarm}):OnChanged(function(v) S.autoCoinFarm=v; saveSettings() end)
T:AddSlider("coinInt",{Title="Interval (s)",Default=coinInterval,Min=10,Max=300,Rounding=0}):OnChanged(function(v) coinInterval=v; saveSettings() end)
T:AddDropdown("milestones",{Title="Milestones to Deposit",Values={"Milk","Egg","RuneLuck","RuneSpeed","RuneBulk","TierLuck"},Multi=true,Default=toDict(selectedMilestones)}):OnChanged(function(v)
    selectedMilestones={}; for k,_ in pairs(v) do selectedMilestones[#selectedMilestones+1]=k end; saveSettings()
end)

div(T)
hdr(T,"🧪  Potions  (auto-use when < 60s left)")
T:AddDropdown("potList",{Title="Potions",Values=POTION_NAMES,Multi=true,Default=toDict(selectedPotions)}):OnChanged(function(v)
    selectedPotions={}; for k,_ in pairs(v) do selectedPotions[#selectedPotions+1]=k end; saveSettings()
end)
T:AddToggle("autoPot",{Title="Auto Use ON",Default=S.autoPot}):OnChanged(function(v) S.autoPot=v; saveSettings() end)
T:AddButton({Title="Check Timers",Callback=function()
    task.spawn(function()
        local potF=LP.EXTRA:FindFirstChild("MONETIZATION") and LP.EXTRA.MONETIZATION:FindFirstChild("POTIONS")
        if not potF then notify("🧪","No POTIONS folder",4); return end
        local lines={}
        for _, p in ipairs(potF:GetChildren()) do
            local tl=p:FindFirstChild("TimeLeft"); local cap=p:FindFirstChild("Capacity")
            local t=tl and tonumber(tl.Value) or 0; local c=cap and tonumber(cap.Value) or 0
            lines[#lines+1]=p.Name..": "..fmtTime(t).." (cap "..math.floor(c)..")"
        end
        notify("🧪",table.concat(lines,"\n"),10)
    end)
end})

div(T)
hdr(T,"🏃  Player")
T:AddSlider("wspd",{Title="Walk Speed",Default=16,Min=16,Max=300,Rounding=0}):OnChanged(function(v) pcall(function() local h=getHum(); if h then h.WalkSpeed=v end end) end)
T:AddSlider("jmpw",{Title="Jump Power",Default=50,Min=50,Max=500,Rounding=0}):OnChanged(function(v) pcall(function() local h=getHum(); if h then h.JumpPower=v end end) end)
T:AddButton({Title="Reset",Callback=function()
    pcall(function() local h=getHum(); if h then h.WalkSpeed=16; h.JumpPower=50 end end)
end})

end -- Gear

-- ─── Periodic capsule count sync ─────────────────────────────────────────────
safeLoop(5, function()
    pcall(function()
        capLabelPara:Set({Title="Session",Content="Opened: "..capsuleCount})
    end)
end)

-- ─── Final ────────────────────────────────────────────────────────────────────
Window:SelectTab(1)
task.delay(3, function() pcall(updateChances) end)
Fluent:Notify({Title="Noob Incremental v8.0",Content="✅ Loaded | @Benefit",Duration=5})

-- ─── Mobile toggle button ─────────────────────────────────────────────────────
-- Draggable ☰ button always visible — tap to show/hide Fluent window.
-- Finds the Fluent ScreenGui and toggles its main frame.
task.spawn(function()
    task.wait(1)
    pcall(function()
        -- Find Fluent's ScreenGui in PlayerGui
        local pGui    = LP:WaitForChild("PlayerGui", 5)
        local fluentSG= nil
        for _, sg in ipairs(pGui:GetChildren()) do
            if sg:IsA("ScreenGui") and sg:FindFirstChild("Main") then
                fluentSG = sg; break
            end
        end
        if not fluentSG then return end
        local mainFrame = fluentSG:FindFirstChild("Main")
        if not mainFrame then return end

        -- Build toggle button ScreenGui
        local sg = Instance.new("ScreenGui")
        sg.Name            = "BenefitToggle"
        sg.ResetOnSpawn    = false
        sg.DisplayOrder    = 999
        sg.ZIndexBehavior  = Enum.ZIndexBehavior.Sibling
        sg.IgnoreGuiInset  = true
        sg.Parent          = pGui

        local btn = Instance.new("TextButton")
        btn.Name            = "Btn"
        btn.Size            = UDim2.fromOffset(48, 48)
        btn.Position        = UDim2.new(1, -58, 0.5, -24)
        btn.AnchorPoint     = Vector2.new(0, 0)
        btn.BackgroundColor3= Color3.fromRGB(30, 30, 35)
        btn.TextColor3      = Color3.fromRGB(230, 230, 230)
        btn.Font            = Enum.Font.GothamBold
        btn.TextSize        = 22
        btn.Text            = "☰"
        btn.BorderSizePixel = 0
        btn.ZIndex          = 10
        btn.Parent          = sg

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 10)
        corner.Parent = btn

        -- Toggle Fluent window on tap
        btn.MouseButton1Click:Connect(function()
            mainFrame.Visible = not mainFrame.Visible
            btn.Text = mainFrame.Visible and "☰" or "▶"
        end)

        -- Drag support
        local dragging, dragStart, startPos = false, nil, nil
        btn.InputBegan:Connect(function(inp)
            if inp.UserInputType==Enum.UserInputType.Touch or inp.UserInputType==Enum.UserInputType.MouseButton1 then
                dragging  = true
                dragStart = inp.Position
                startPos  = btn.Position
            end
        end)
        btn.InputChanged:Connect(function(inp)
            if dragging and (inp.UserInputType==Enum.UserInputType.Touch or inp.UserInputType==Enum.UserInputType.MouseMovement) then
                local delta = inp.Position - dragStart
                btn.Position = UDim2.new(
                    startPos.X.Scale, startPos.X.Offset + delta.X,
                    startPos.Y.Scale, startPos.Y.Offset + delta.Y
                )
            end
        end)
        btn.InputEnded:Connect(function(inp)
            if inp.UserInputType==Enum.UserInputType.Touch or inp.UserInputType==Enum.UserInputType.MouseButton1 then
                dragging = false
            end
        end)
    end)
end)
