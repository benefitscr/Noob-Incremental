-- ╔══════════════════════════════════════════════════════════════════╗
-- ║  Noob Incremental Autofarm  v8.0  @Benefit                       ║
-- ║  Custom GUI · Optimized · Stable · No external UI dependencies   ║
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
local _GUI_URL = "https://roblox-mcp.roblox-mcp.workers.dev/module/gui"
local Fluent
do
    local ok, src = pcall(game.HttpGet, game, _GUI_URL, true)
    if ok and src and #src > 500 then
        local fn = loadstring(src)
        if fn then Fluent = fn() end
    end
    if not Fluent then error("[autofarm] Failed to load custom GUI from worker") end
end

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
    autoFbAll=false, autoFbTree=false, autoFbRank=false, autoFbTrophy=false, autoBuyNoob=false,
    autoFbUpNoob=false, autoGoalUpg=false, autoKickBall=false,
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
local selectedFbUpNoobs  = {}
local selectedGoalUps    = {}
local excludedTalents    = {}
local runeBlock          = {}
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
    "autoFbAll","autoFbTree","autoFbRank","autoFbTrophy","autoBuyNoob",
    "autoFbUpNoob","autoGoalUpg","autoKickBall",
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
    if #selectedFbUpNoobs>0  then lines[#lines+1]="selectedFbUpNoobs="..table.concat(selectedFbUpNoobs,",") end
    if #selectedGoalUps>0    then lines[#lines+1]="selectedGoalUps="..table.concat(selectedGoalUps,"|") end
    do local ex={}; for n in pairs(excludedTalents) do ex[#ex+1]=n end; if #ex>0 then lines[#lines+1]="excludedTalents="..table.concat(ex,",") end end
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
            elseif k=="selectedFbUpNoobs" and v~="" then
                selectedFbUpNoobs={}; for r in v:gmatch("[^,]+") do selectedFbUpNoobs[#selectedFbUpNoobs+1]=r end
            elseif k=="selectedGoalUps" and v~="" then
                selectedGoalUps={}; for r in v:gmatch("[^|]+") do selectedGoalUps[#selectedGoalUps+1]=r end
            elseif k=="excludedTalents" and v~="" then
                excludedTalents={}; for r in v:gmatch("[^,]+") do excludedTalents[r]=true end
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
local CAPSULE_PRICE={Classic=1e9, Super=7.5e9, Football=2.5e41}
local CAPSULE_CURRENCY={Classic="Prism", Super="Prism", Football="Goals"}
local prismAmountV=nil
pcall(function() prismAmountV=LP.CURRENCIES.Prism.Amount:FindFirstChild("1") end)
-- Currency amount reader (best-effort; nil = unreadable, e.g. huge Goals → callers attempt anyway, server validates)
local function currencyAmount(name)
    local ok, v = pcall(function()
        local c = LP.CURRENCIES:FindFirstChild(name)
        local a = c and c:FindFirstChild("Amount")
        local one = a and a:FindFirstChild("1")
        return one and tonumber(one.Value) or nil
    end)
    return ok and v or nil
end
-- ─── Football auto-progress data + SMART rate-limiter ─────────────────────────
local FB_MODULE
pcall(function() FB_MODULE = require(RS.Shared.Modules.UIFootballTree) end)
local FB_NODES={}
if FB_MODULE and type(FB_MODULE.Nodes)=="table" then for name in pairs(FB_MODULE.Nodes) do FB_NODES[#FB_NODES+1]=name end end
-- The module's Nodes table is EMPTY at autofarm load (the game fills it lazily) → showed "(0 нод)"
-- and bought nothing. Bake in the 65 known node keys so the list is never empty. Server still validates.
if #FB_NODES==0 then
    FB_NODES={"TheStart","GoalsMulti1","GoalsMulti2","GoalsSpeed","GoalsMulti3","BigGoalMulti","GoalSpeed","GoalMulti1","GoalMulti2","PRuneBulk","PRuneSpeed","UnlockNoob2","UnlockNoob3","UnlockNoob4","UnlockNoob5","UnlockNoob6","UnlockNoob7","UnlockNoob8","UnlockNoob9","UnlockNoob10","UnlockNoob11","RuneLuckNode","RuneBulkNode","UnlockSoccerCapsule","SoccerCapsuleLuck","B3_HackPointMul","B3_OofMulti","B3_AutoNoob1","B3_AutoNoob2","B3_AutoNoob3","B3_AutoNoob4","B3_AutoNoob5","B3_AutoNoob6","B3_AutoNoob7","B3_AutoNoob8","B3_AutoNoob9","B3_AutoNoob10","B3_AutoNoob11","B3_UnlockNoobinials","B3_UnlockSoccerRune","B3_WaterMulti","B3_PlankMulti","B3_GemMulti","B3_AuraLuck","B3_MineralMul","B3_OreDamage","B3_GoalUpgradesFree","B3_RuneSpeed","B3_PrismMult","B3_RuneLuck","B3_TierLuck","B3_RuneBulk","B3_TierBulk","B2_RuneLuck","B2_RuneBulk","B2_RuneSpeed","B2_TierLuck","B2_TierBulk","B2_TierBulk2","B2_PrismMul","B2_HackPointMul","B2_OofMul","B2_GemMul","B2_PrismMul2","B2_GoalsMul"}
end
local FB_TROPHY_COUNT, FB_RANK_MAX = 10, 6
pcall(function() FB_TROPHY_COUNT = #require(RS.Shared.Modules.Trophy).List end)
pcall(function() FB_RANK_MAX = #require(RS.Shared.Modules.FootballRankings).List end)
local FB_RANK_V, FB_TROPHY_V
pcall(function() FB_RANK_V   = LP.FEATURES.FOOTBALL_RANKING:FindFirstChild("RankingBought") end)
pcall(function() FB_TROPHY_V = LP.FEATURES.TROPHY:FindFirstChild("TrophyBought") end)
local function fbRank()     return FB_RANK_V   and (tonumber(FB_RANK_V.Value)   or 0) or 0 end
local function fbTrophies() return FB_TROPHY_V and (tonumber(FB_TROPHY_V.Value) or 0) or 0 end

-- Token-bucket rate limiter shared by ALL football auto fires → cannot trip server rate limits.
local FB_RATE = 5                      -- fires/sec budget (tunable via slider on the Football tab)
local fbTokens, fbLast = FB_RATE, tick()
local function fbAllow()
    local now = tick()
    fbTokens = math.min(FB_RATE, fbTokens + (now - fbLast) * FB_RATE); fbLast = now
    if fbTokens >= 1 then fbTokens = fbTokens - 1; return true end
    return false
end
-- Game's own "is this node buyable right now?" check (prereqs met & not maxed).
-- Falls back to true if the module API differs — the rate limiter still caps volume either way.
local function fbBuyable(name)
    if not FB_MODULE then return true end
    local ok, r = pcall(function() return FB_MODULE.IsNodeUnlocked and FB_MODULE.IsNodeUnlocked(name) end)
    if not ok then ok, r = pcall(function() return FB_MODULE:IsNodeUnlocked(name) end) end
    if not ok then return true end
    return r and true or false
end
local fbCursor = 1

-- Football noob names (for UpgradeNoobMax) — from workspace Noobs folder (reliable at load) + fallback
local FB_NOOB_NAMES={}
do
    local nf = GC:FindFirstChild("Noobs")
    if nf then for _, m in ipairs(nf:GetChildren()) do FB_NOOB_NAMES[#FB_NOOB_NAMES+1]=m.Name end end
    table.sort(FB_NOOB_NAMES)
    if #FB_NOOB_NAMES==0 then
        FB_NOOB_NAMES={"Goalkeeper","RightBack","LeftBack","RightCenterBack","LeftCenterBack","RightWing","LeftWing","Striker","AttackingMid","RightDefensiveMid","LeftDefensiveMid","Starter","Cooker","Farmer","Archer","Hacker 1","Hacker 2","Hacker 3","Hacker 4"}
    end
end

-- Goal (base football) upgrades: Upgrades.List.Goals → selectable {k,label}; numeric fallback k=1..12
local GOAL_UPS, GOAL_LABEL_TO_K, GOAL_UP_LABELS = {}, {}, {}
pcall(function()
    local UP = require(RS.Shared.Modules.Upgrades)
    local list = UP and UP.List and UP.List.Goals
    if type(list)=="table" then
        local keys={}
        for k in pairs(list) do keys[#keys+1]=k end
        table.sort(keys, function(a,b)
            if type(a)=="number" and type(b)=="number" then return a<b end
            return tostring(a)<tostring(b)
        end)
        for _, k in ipairs(keys) do
            local v=list[k]; local title
            if type(v)=="table" then title=v.title or v.name or v.Name or v.desc end
            local label=tostring(k)..(title and (" · "..tostring(title)) or "")
            GOAL_UPS[#GOAL_UPS+1]={k=k, label=label}; GOAL_LABEL_TO_K[label]=k
        end
    end
end)
if #GOAL_UPS==0 then
    for i=1,12 do local label="Goal Upgrade "..i; GOAL_UPS[#GOAL_UPS+1]={k=i,label=label}; GOAL_LABEL_TO_K[label]=i end
end
for _,u in ipairs(GOAL_UPS) do GOAL_UP_LABELS[#GOAL_UP_LABELS+1]=u.label end

-- Talent labels for the "don't upgrade" exclude list: "title · name" → node name
local FB_TALENT_LABELS, FB_LABEL_TO_NODE = {}, {}
do
    local titles = {}
    if FB_MODULE and type(FB_MODULE.Nodes)=="table" then
        for name, node in pairs(FB_MODULE.Nodes) do if type(node)=="table" then titles[name]=node.title end end
    end
    for _, name in ipairs(FB_NODES) do
        local t = titles[name]
        local label = (t and t~="") and (tostring(t).." · "..name) or name
        FB_TALENT_LABELS[#FB_TALENT_LABELS+1] = label
        FB_LABEL_TO_NODE[label] = name
    end
    table.sort(FB_TALENT_LABELS)
end

-- Football tree FRONTIER — fire only buyable nodes (unlocked & not maxed) instead of all 65.
-- Verified live: firing BuyFootballUITreeNode buys a level; the frontier is ~a handful of nodes.
-- Graph (maxLevel + unlocks) from the live module; node levels from GetPlayerData (refreshed).
local FB_ML, FB_UNLOCKS, FB_PARENT = {}, {}, {}
local function buildFbGraph()
    if not (FB_MODULE and type(FB_MODULE.Nodes)=="table") then return end
    local ml, unl, par = {}, {}, {}
    for name, node in pairs(FB_MODULE.Nodes) do
        ml[name]  = node.maxLevel or 1
        unl[name] = node.unlocks or {}
    end
    for p, kids in pairs(unl) do
        if type(kids)=="table" then for _, k in ipairs(kids) do par[k]=par[k] or {}; par[k][#par[k]+1]=p end end
    end
    FB_ML, FB_UNLOCKS, FB_PARENT = ml, unl, par
end
buildFbGraph()
local fbLevels = {}
local function refreshFbLevels()
    local ok, data = pcall(function() return RS.__Net.GetPlayerData:InvokeServer() end)
    if ok and data and type(data.FOOTBALL_UI_UPGRADE_TREE)=="table" then fbLevels = data.FOOTBALL_UI_UPGRADE_TREE end
end
local fbFrontier = {}
local fbPriorityNode = nil
local function computeFbFrontier()
    if next(FB_ML)==nil then buildFbGraph() end          -- module Nodes may have been lazy at load
    local out = {}
    for name, ml in pairs(FB_ML) do
        if not excludedTalents[name] and (fbLevels[name] or 0) < ml then
            local unlocked = (FB_PARENT[name] == nil)     -- root has no parent
            if not unlocked then
                for _, p in ipairs(FB_PARENT[name]) do if (fbLevels[p] or 0) >= 1 then unlocked=true; break end end
            end
            if unlocked then out[#out+1] = name end
        end
    end
    fbFrontier = out
    -- Priority: a noob-unlock talent (UnlockNoob*) whose cost is within +10% of the cheapest frontier
    -- node → buy the noob FIRST (noobs generate income, so unlocking them early compounds).
    fbPriorityNode = nil
    local minCost, costs = math.huge, {}
    for _, name in ipairs(out) do
        local node = FB_MODULE and FB_MODULE.Nodes and FB_MODULE.Nodes[name]
        if node and node.getCost then
            local ok, c = pcall(function() return node.getCost(fbLevels[name] or 0) end)
            if ok and type(c)=="number" then costs[name]=c; if c < minCost then minCost=c end end
        end
    end
    if minCost < math.huge then
        for _, name in ipairs(out) do
            if name:find("^UnlockNoob") and costs[name] and costs[name] <= minCost*1.1 then fbPriorityNode=name; break end
        end
    end
end

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

-- Audit result: single snap + task.wait(250ms) + fire works reliably.
-- 100ms fails, 200ms passes — use 250ms for margin.
-- Heartbeat holds position during the wait so other loops can't move character.
local function holdAndFire(ctype, enterCF, timeout)
    local prev=_lastCapsuleOpen
    local h=getHRP(); if not h then return false end
    -- Single snap into zone. capsuleBusy=true (set by caller) blocks mining/ice
    -- from moving the character, so no continuous re-snap is needed.
    -- No Heartbeat, no spawned loops — zero LEASE risk.
    pcall(function() h.CFrame=enterCF end)
    task.wait(0.25)
    fire("OpenCapsule", ctype)
    local deadline=tick()+timeout
    while _lastCapsuleOpen==prev and tick()<deadline do task.wait(0.05) end
    return _lastCapsuleOpen~=prev
end

local function getCapsulePart(ctype)
    if CAPSULE_PARTS[ctype] and CAPSULE_PARTS[ctype].Parent then
        return CAPSULE_PARTS[ctype]
    end
    local uiZ=GC and GC:FindFirstChild("UIZones")
    local mdl=uiZ and uiZ:FindFirstChild("__Capsule"..ctype)
    local part=mdl and (mdl:FindFirstChild("TouchPart") or mdl:FindFirstChildWhichIsA("BasePart"))
    if part then CAPSULE_PARTS[ctype]=part end
    return part
end

local function withCapsuleZone(ctype)
    local part=getCapsulePart(ctype); local hrp=getHRP()
    if not (part and hrp) then return end  -- never fire without confirmed zone
    local enterCF=capsuleEnterCF(part)
    capsuleBusy=true
    pcall(holdAndFire, ctype, enterCF, 3)
    capsuleBusy=false  -- always released
end

local function bulkCapsules(ctype, cond)
    local timeout=tick()+5
    while capsuleBusy and tick()<timeout do task.wait(0.1) end
    local part=getCapsulePart(ctype)
    if not part then return 0 end
    local enterCF=capsuleEnterCF(part)
    local count=0
    while cond() do
        local h=getHRP(); if not h then break end
        capsuleBusy=true
        local ok=false
        pcall(function() ok=holdAndFire(ctype, enterCF, 3) end)
        capsuleBusy=false  -- always released even if holdAndFire errors
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
        local p=potF:FindFirstChild(name)
        if p then
            local tl=p:FindFirstChild("TimeLeft"); local cap=p:FindFirstChild("Capacity")
            if (cap and tonumber(cap.Value) or 0)>0 and (tl and tonumber(tl.Value) or 0)<60 then
                fire("UsePotion",name,1)
            end
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
    local cur=CAPSULE_CURRENCY[selectedMinCap] or "Prism"
    local have=currencyAmount(cur)
    -- Goals is a big-number currency (single Amount segment misreads) → skip client check, server validates
    if cur~="Goals" and have and have<price then return end
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
        pcall(function()
            if not (S.mining and next(selectedOres)~=nil) or capsuleBusy then
                _miningOre = nil; return
            end
            local folder=getOreFolder(); local hrp=getHRP()
            if not (folder and hrp) then return end
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
        end)
    end
end)

-- Rune rolling — dedicated loop, no safeLoop to keep precise interval
task.spawn(function()
    while true do
        pcall(function()
            if S.runes and #selectedRunes>0 then
                for _, rune in ipairs(selectedRunes) do
                    if not (runeBlock[rune] and tick() < runeBlock[rune]) then   -- 60s post-unlock blocker
                        pcall(MR.FireServer,MR,"RollRune",rune)
                    end
                end
                task.wait(math.max(0.02,runeInterval))
            else task.wait(0.1) end
        end)
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

-- Football auto-progress — SMART: rate-limited, buys only what's actually buyable.
-- Fast 0.1s tick, but the token-bucket (FB_RATE/s) caps real fire volume → no rate-limit kicks.
-- Rank & trophy buy only the NEXT one (not a 1..N spray); TrophyBought is read live so trophies
-- auto-resume after a rank reset. Tree buys only IsNodeUnlocked nodes, round-robin, within budget.
-- ─── SMART affordability via result-detection (no big-number math) ────────────
-- Every ~3s read live state; anything we FIRED that did NOT progress (level/count didn't rise) is
-- unaffordable or already maxed → stall it 20s. Stops blind spam on things you can't afford / maxed.
local NOOBS_F; pcall(function() NOOBS_F = LP.FEATURES:FindFirstChild("NOOBS") end)
local sStall, sFired, sPrev = {}, {}, {}
local saveMode, saveUntil, saveCd = false, 0, 0
local fbUnlockedNoobs = {}
local function sBlocked(k) local u=sStall[k]; return u~=nil and tick()<u end
local function sMark(k) sFired[k]=true end
local function noobLvl(name) local n=NOOBS_F and NOOBS_F:FindFirstChild(name); local l=n and n:FindFirstChild("Level"); return l and (tonumber(l.Value) or 0) or 0 end
local function smartRefresh()
    local ok,data=pcall(function() return RS.__Net.GetPlayerData:InvokeServer() end)
    if ok and data and type(data.FOOTBALL_UI_UPGRADE_TREE)=="table" then fbLevels=data.FOOTBALL_UI_UPGRADE_TREE end
    computeFbFrontier()
    local un={}
    if NOOBS_F then for _,n in ipairs(NOOBS_F:GetChildren()) do local u=n:FindFirstChild("Unlocked"); if u and u.Value then un[#un+1]=n.Name end end end
    fbUnlockedNoobs=un
    local now=tick()
    local cur={ rank=fbRank(), trophy=fbTrophies() }
    for name in pairs(FB_ML) do cur["t:"..name]=fbLevels[name] or 0 end
    for _,nm in ipairs(un) do cur["nu:"..nm]=noobLvl(nm) end
    for k in pairs(sFired) do
        if sPrev[k]~=nil and (cur[k] or 0)<=(sPrev[k] or 0) then sStall[k]=now+20 else sStall[k]=nil end
    end
    -- Rune unlock → block rolling that rune for 60s (a talent opens it; rolling immediately is wasteful)
    for _, pr in ipairs({{"B3_UnlockSoccerRune","Football"},{"B3_UnlockNoobinials","Football"}}) do
        if sPrev["t:"..pr[1]]~=nil and (sPrev["t:"..pr[1]] or 0)<1 and (fbLevels[pr[1]] or 0)>=1 then runeBlock[pr[2]]=now+60 end
    end
    -- SAVE-FOR-BIG-BUY: rank/trophy give big multipliers → priority. If one is pending but unaffordable,
    -- PAUSE Goals-spending on talents/goal-upgrades (up to 5 min) so the balance builds up to afford it.
    -- Income (auto-kick / noobs) keeps running so it accrues faster. Too far in 5 min → resume 2 min.
    local rankUnaff   = (fbRank() < FB_RANK_MAX)         and (S.autoFbAll or S.autoFbRank)   and sBlocked("rank")
    local trophyUnaff = (fbTrophies() < FB_TROPHY_COUNT) and (S.autoFbAll or S.autoFbTrophy) and sBlocked("trophy")
    if saveMode then
        if (not rankUnaff and not trophyUnaff) or now > saveUntil then
            if now > saveUntil then saveCd = now + 120 end
            saveMode = false
        end
    elseif now > saveCd and (rankUnaff or trophyUnaff) then
        saveMode, saveUntil = true, now + 300
    end
    sPrev=cur; sFired={}
end
safeLoop(3, function()
    if not (S.autoFbAll or S.autoFbTree or S.autoFbRank or S.autoFbTrophy or S.autoFbUpNoob or S.autoBuyNoob) then return end
    smartRefresh()
end)
local fbUpCursor, goalUpCursor, fbTurn = 0, 0, 0
safeLoop(0.1, function()
    if not (S.autoFbAll or S.autoFbTree or S.autoFbRank or S.autoFbTrophy or S.autoFbUpNoob or S.autoGoalUpg) then return end
    -- FAIR round-robin across all active football concerns through ONE shared token-bucket.
    -- Each concern contributes at most one fire per rotation, so a stuck rank/trophy can't starve
    -- the tree (that was the "не качает таланты" bug). Total rate is still capped at FB_RATE/s.
    local actions = {}
    if (S.autoFbAll or S.autoFbTree) then
        if next(FB_ML) ~= nil then
            -- SMART: fire only the buyable frontier (unlocked & not maxed), skipping excluded talents
            -- at fire-time (instant — no 4s-window +1 on excluded nodes).
            if #fbFrontier > 0 then
                actions[#actions+1] = function()
                    -- cost-comparable noob-unlock first (income compounds), else round-robin
                    local pn = fbPriorityNode
                    if pn and not excludedTalents[pn] and not sBlocked("t:"..pn) then
                        sMark("t:"..pn); fire("BuyFootballUITreeNode", pn); return
                    end
                    for _=1,#fbFrontier do
                        fbCursor = (fbCursor % #fbFrontier) + 1
                        local name = fbFrontier[fbCursor]
                        if not excludedTalents[name] and not sBlocked("t:"..name) then
                            sMark("t:"..name); fire("BuyFootballUITreeNode", name); return
                        end
                    end
                end
            end
        elseif #FB_NODES > 0 then
            -- Fallback (graph not ready yet): round-robin all nodes, skipping excluded talents.
            actions[#actions+1] = function()
                for _=1,#FB_NODES do
                    fbCursor = (fbCursor % #FB_NODES) + 1
                    local name = FB_NODES[fbCursor]
                    if not excludedTalents[name] then fire("BuyFootballUITreeNode", name); return end
                end
            end
        end
    end
    if (S.autoFbAll or S.autoFbRank) and fbRank() < FB_RANK_MAX and not sBlocked("rank") then
        actions[#actions+1] = function() sMark("rank"); fire("BuyFootballRanking", fbRank()+1) end
    end
    if (S.autoFbAll or S.autoFbTrophy) and fbTrophies() < FB_TROPHY_COUNT and not sBlocked("trophy") then
        actions[#actions+1] = function() sMark("trophy"); fire("BuyTrophy", fbTrophies()+1) end
    end
    if (S.autoFbAll or S.autoFbUpNoob) then
        -- upgrade ALL bought (unlocked) noobs; dropdown (if set) narrows it. Skip stalled = maxed/broke.
        local targets = fbUnlockedNoobs   -- ALL bought noobs, no selection needed
        if #targets > 0 then
            actions[#actions+1] = function()
                for _=1,#targets do
                    fbUpCursor = (fbUpCursor % #targets) + 1
                    local nm = targets[fbUpCursor]
                    if not sBlocked("nu:"..nm) then sMark("nu:"..nm); fire("UpgradeNoobMax", nm); return end
                end
            end
        end
    end
    if (S.autoFbAll or S.autoGoalUpg) then
        -- selected Goal-upgrades, or ALL of them under the master AUTO FOOTBALL toggle
        local gtargets = GOAL_UP_LABELS   -- ALL goal upgrades by default, no selection needed
        if #gtargets > 0 then
            actions[#actions+1] = function()
                goalUpCursor = (goalUpCursor % #gtargets) + 1
                local gk = GOAL_LABEL_TO_K[gtargets[goalUpCursor]]
                if gk ~= nil then fire("UpgradeUpgradeMax", "Goals", gk) end
            end
        end
    end
    local n = #actions
    if n == 0 then return end
    local fired = 0
    while fired < n * 3 and fbAllow() do
        fbTurn = fbTurn + 1
        actions[(fbTurn % n) + 1]()
        fired = fired + 1
    end
end)

-- Auto-kick ball → call the game's own _Kick controller = a REAL kick (RegisterFootballKick +
-- ball animation + ScoreGoal + reward), exactly like a manual kick. Rate is gated naturally by
-- ball flight/respawn (~1 kick / 1.5s); we reset _lastKick to skip the 5s manual cooldown.
-- Verified live: the ball visibly kicks and Goals are credited. Requires being in the football zone.
local BALL_CTRL
local function getBallCtrl()
    -- re-fetch if missing or the cached controller went stale (e.g. after respawn) — stability
    if BALL_CTRL then
        local ok, st = pcall(function() return BALL_CTRL._state end)
        if ok and st ~= nil then return BALL_CTRL end
        BALL_CTRL = nil
    end
    pcall(function() BALL_CTRL = require(RS.Framework.Client).GetController("Ctrl_BallShootPrototype") end)
    return BALL_CTRL
end
safeLoop(0.1, function()
    if not (S.autoKickBall or S.autoFbAll) then return end
    local c = getBallCtrl(); if not c then return end
    if c._state == "idle" and c._ball then
        c._lastKick = 0                       -- skip the 5s manual cooldown
        pcall(function() c:_Kick() end)       -- real kick (visual + reward), auto-scores on landing
    end
end)

-- Auto-buy noobs — standing on _Zone_Buy_Noob BUYS a new (locked) noob if affordable
-- (upgrading is a SEPARATE button). Server-side & position-based (no remote) → we teleport
-- onto the next locked noob's zone and the server buys it if the player can afford it.
local NOOBS_FOLDER = GC:FindFirstChild("Noobs")
local NOOBS_FEAT
pcall(function() NOOBS_FEAT = LP.FEATURES:FindFirstChild("NOOBS") end)
local function noobLocked(name)
    if not NOOBS_FEAT then return true end          -- unknown → treat as buyable
    local n = NOOBS_FEAT:FindFirstChild(name)
    local u = n and n:FindFirstChild("Unlocked")
    return not (u and u.Value)
end
-- A noob is only BUYABLE once its unlock talent (requireFootballNode) is bought. If the talent isn't
-- bought, the buy button isn't available → DON'T teleport there (that was moving us out of the zone).
local NOOB_REQ = {}
pcall(function()
    local cfg = require(RS.Shared.Modules.Noobs); local list = cfg.List or cfg
    for nm, e in pairs(list) do if type(e)=="table" and e.requireFootballNode then NOOB_REQ[nm]=e.requireFootballNode end end
end)
local function noobAvailable(name)
    local req = NOOB_REQ[name]
    if not req then return true end                 -- no talent gate → always available
    return (fbLevels[req] or 0) >= 1                -- required unlock talent bought?
end
local function firstLockedNoobZone()
    if not NOOBS_FOLDER then return nil end
    for _, m in ipairs(NOOBS_FOLDER:GetChildren()) do
        local z = m:FindFirstChild("_Zone_Buy_Noob")
        if z and noobLocked(m.Name) then return z, m.Name end
    end
    return nil
end
safeLoop(1, function()
    if not (S.autoBuyNoob or S.autoFbAll) or capsuleBusy then return end
    -- next LOCKED noob that isn't stalled (a noob that didn't unlock after a try is skipped 30s, so we
    -- don't keep teleporting to noobs that aren't available/affordable yet)
    local z, nm
    if NOOBS_FOLDER then
        for _, m in ipairs(NOOBS_FOLDER:GetChildren()) do
            local zz = m:FindFirstChild("_Zone_Buy_Noob")
            if zz and noobLocked(m.Name) and noobAvailable(m.Name) and not sBlocked("nb:"..m.Name) then z, nm = zz, m.Name; break end
        end
    end
    if not z then return end
    local hrp, hum = getHRP(), getHum()
    if not (hrp and hum) then return end
    capsuleBusy = true                              -- block mining/ice from moving us mid-buy
    local origin = hrp.Position
    pcall(function()
        -- WALK to the button (natural movement; avoids the mid-map teleporter). CFrame-TP is used ONLY
        -- as recovery if we're far away (accidentally left the event).
        if (z.Position - hrp.Position).Magnitude > 500 then
            hrp.CFrame = CFrame.new(z.Position + Vector3.new(0, 3, 0))   -- recovery teleport back
        else
            hum:MoveTo(z.Position)
            local t = tick()
            while tick() - t < 8 do
                local h = getHRP(); if not h then break end
                if (h.Position - z.Position).Magnitude < 7 then break end
                task.wait(0.15)
            end
        end
        task.wait(0.5)                              -- stand on the button so the server buys the noob
        -- walk back to where we were standing
        local h2, hm2 = getHRP(), getHum()
        if h2 and hm2 then
            hm2:MoveTo(origin)
            local t2 = tick()
            while tick() - t2 < 8 do
                local h3 = getHRP(); if not h3 then break end
                if (h3.Position - origin).Magnitude < 7 then break end
                task.wait(0.15)
            end
        end
    end)
    capsuleBusy = false                             -- always released
    if noobLocked(nm) then sStall["nb:"..nm] = tick() + 30 end   -- didn't buy → not available now → skip 30s
end)

-- ─── Stability watchdog ───────────────────────────────────────────────────────
-- If a movement action leaves capsuleBusy stuck true (error/death mid-move) it would block
-- mining/ice/capsule/noob-buy forever. Clear it if it's been held continuously for >12s.
do
    local busySince = 0
    safeLoop(2, function()
        if capsuleBusy then
            if busySince == 0 then busySince = tick()
            elseif tick() - busySince > 12 then capsuleBusy = false; busySince = 0 end
        else busySince = 0 end
    end)
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- GUI — FLUENT
-- ═══════════════════════════════════════════════════════════════════════════════
local Window=Fluent:CreateWindow({
    Title       = "Noob Incremental",
    SubTitle    = "v9.7 · @Benefit",
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
    Football= Window:AddTab({ Title="⚽ Football", Icon="trophy"      }),
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
T:AddDropdown("capZone",{Title="Zone",Values={"Classic","Super","Football"},Multi=false,Default=selectedMinCap}):OnChanged(function(v) selectedMinCap=v; saveSettings() end)
T:AddToggle("autoCap",{Title="🎱  Auto Capsule ON",Default=S.minionCap}):OnChanged(function(v) S.minionCap=v; saveSettings() end)

div(T)
hdr(T,"🎱  Capsule — Bulk Open")
local capLabelPara=T:AddParagraph({Title="Session",Content="Opened: 0"})
T:AddButton({Title="Open All  (until Prism runs out)",Callback=function()
    task.spawn(function()
        local price=CAPSULE_PRICE[selectedMinCap] or 1e9
        local ccur=CAPSULE_CURRENCY[selectedMinCap] or "Prism"
        local n=bulkCapsules(selectedMinCap,function()
            if ccur=="Goals" then return true end       -- big-number → let holdAndFire/server stop it
            local have=currencyAmount(ccur)
            return (have==nil) or have>=price
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
T:AddDropdown("runeZones",{Title="Active Zones",Values={"Basic","Super","Advanced","Cosmic Prism","Hacker","Snowy","Deepcore","Football"},Multi=true,Default=toDict(selectedRunes)}):OnChanged(function(v)
    selectedRunes={}; for k,_ in pairs(v) do selectedRunes[#selectedRunes+1]=k end; saveSettings()
end)
T:AddSlider("runeInt",{Title="Interval (s)  [ниже = чаще, min 0.02]",Default=math.max(runeInterval,0.02),Min=0.02,Max=2.0,Rounding=3}):OnChanged(function(v) runeInterval=math.max(0.02,v); saveSettings() end)
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
        local para=zoneParagraphs[zone.name]
        if para then
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

-- ═══════════════════════════════════════════════════════════════════════════════
-- TAB 7 — ⚽ Football (auto-progress)
-- ═══════════════════════════════════════════════════════════════════════════════
do local T=Tabs.Football

hdr(T,"🤖  Auto Football")
T:AddParagraph({Title="",Content="Умный Full Auto: доход → таланты по карману (приоритет нубов, учёт ⛔ бан-листа) → копит на ранг/трофей → апгрейд всех нубов → покупка новых → все Goal Upgrades. Без слепого спама и рейтлимита. Включил — и спи."})
T:AddToggle("fbAll",{Title="🤖  FULL AUTO (умный — всё)",Default=S.autoFbAll}):OnChanged(function(v) S.autoFbAll=v; saveSettings() end)

div(T)
hdr(T,"🎯  По отдельности")
T:AddToggle("fbTree",  {Title="🌳 Таланты — дерево ("..#FB_NODES.." нод)",         Default=S.autoFbTree  }):OnChanged(function(v) S.autoFbTree=v;   saveSettings() end)
T:AddDropdown("excludeTalents",{Title="⛔ НЕ качать эти таланты",Values=FB_TALENT_LABELS,Multi=true,Default=(function() local d={} for _,lbl in ipairs(FB_TALENT_LABELS) do if excludedTalents[FB_LABEL_TO_NODE[lbl]] then d[lbl]=true end end return d end)()}):OnChanged(function(v)
    excludedTalents={}; for lbl in pairs(v) do local n=FB_LABEL_TO_NODE[lbl]; if n then excludedTalents[n]=true end end; saveSettings()
end)
T:AddToggle("fbRank",  {Title="🏅 Ранг — до "..FB_RANK_MAX.." (сбрасывает трофеи)", Default=S.autoFbRank  }):OnChanged(function(v) S.autoFbRank=v;   saveSettings() end)
T:AddToggle("fbTrophy",{Title="🏆 Трофеи — все 1.."..FB_TROPHY_COUNT,               Default=S.autoFbTrophy}):OnChanged(function(v) S.autoFbTrophy=v; saveSettings() end)
T:AddToggle("fbBuyNoob",{Title="🧍 Авто-покупка нубов (следующий залоченный)",       Default=S.autoBuyNoob }):OnChanged(function(v) S.autoBuyNoob=v; saveSettings() end)

div(T)
hdr(T,"🆙  Прокачка нубов (upgrade)")
T:AddToggle("fbUpNoob",{Title="Авто-качать ВСЕХ купленных нубов",Default=S.autoFbUpNoob}):OnChanged(function(v) S.autoFbUpNoob=v; saveSettings() end)

div(T)
hdr(T,"🥅  Goal Upgrades (базовые)")
T:AddToggle("goalUpg",{Title="Авто-качать ВСЕ Goal Upgrades",Default=S.autoGoalUpg}):OnChanged(function(v) S.autoGoalUpg=v; saveSettings() end)

div(T)
hdr(T,"⚽  Авто-пинок мячика")
T:AddParagraph({Title="",Content="Реально бьёт по мячу (штатный удар: анимация + гол + награда), как ручной. Темп задаёт сам мяч (~удар в 1.5с). Нужно стоять в футбольной зоне. Входит в AUTO FOOTBALL."})
T:AddToggle("autoKick",{Title="⚽ Авто-пинок мячика",Default=S.autoKickBall}):OnChanged(function(v) S.autoKickBall=v; saveSettings() end)

div(T)
hdr(T,"⚙️  Скорость (анти-рейтлимит)")
T:AddParagraph({Title="",Content="Общий лимит покупок/сек на весь футбол-авто (дерево+ранг+трофеи). Ниже = безопаснее от кика, выше = быстрее. По умолчанию 5."})
T:AddSlider("fbRate",{Title="Покупок в секунду",Default=FB_RATE,Min=1,Max=15,Rounding=0}):OnChanged(function(v) FB_RATE=math.max(1,v) end)

div(T)
hdr(T,"⚽  Football Rune & Capsule")
T:AddParagraph({Title="",Content="Руна «Football» — во вкладке 🎲 Runes → Active Zones. Капсула «Football» (за Goals) — во вкладке ❄️ W2/Cap → Zone. Включи там нужные тумблеры (Auto Roll / Auto Capsule)."})

end -- Football

-- ─── Periodic capsule count sync ─────────────────────────────────────────────
safeLoop(5, function()
    pcall(function()
        capLabelPara:Set({Title="Session",Content="Opened: "..capsuleCount})
    end)
end)

-- ─── Final ────────────────────────────────────────────────────────────────────
Window:SelectTab(1)
task.delay(3, function() pcall(updateChances) end)
Fluent:Notify({Title="Noob Incremental v9.7",Content="✅ Loaded | ⚽ FULL AUTO (walk to noobs + watchdog) | @Benefit",Duration=5})

