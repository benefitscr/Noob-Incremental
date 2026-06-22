-- Noob Incremental Autofarm v7.0  @Benefit
-- Rayfield UI · ru/en · Chances tab

-- ─── LOAD UI ──────────────────────────────────────────────────────────────────
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield", true))()
-- Patch broken Notify (sirius.menu version has missing Icon child in notification template)
local _rn = Rayfield.Notify
Rayfield.Notify = function(self, t)
    if t then t.Image = nil end
    task.spawn(function() pcall(_rn, self, t) end)
end

-- ─── SERVICES ─────────────────────────────────────────────────────────────────
local Players = game:GetService("Players")
local LP      = Players.LocalPlayer
local GC      = workspace.__GAME_CONTENT
local MR      = game:GetService("ReplicatedStorage").__Net.MainRemote

-- ─── LOCALIZATION ─────────────────────────────────────────────────────────────
local LANG = "en"
local L_TABLE = {
    en = {
        win_title="Noob Incremental", win_sub="v7 · Benefit",
        tab_farm="Farm", tab_combat="Combat", tab_mine="Mine",
        tab_upgrades="Upgrades", tab_equip="Equipment",
        tab_tele="Teleport", tab_chances="Chances",
        sec_wheat="Wheat", sec_chests="Chests", sec_capsules="Capsules",
        sec_world2="World 2", sec_world1="World 1",
        sec_blaze="Blaze", sec_runes="Rune Rolling",
        sec_runetele="Rune Zones", sec_tier="Tier & Awakening",
        sec_oreTypes="Ore Types", sec_mineSettings="Settings",
        sec_automation="Automation", sec_trees="Upgrade Trees",
        sec_aura="Aura", sec_slots="Equipment Slots",
        sec_minions="Minions", sec_minionPat="Minion Patterns",
        sec_bestMinion="Best Minions", sec_equipPat="Equipment Patterns",
        sec_prismEquip="Prism Auto-Equip",
        sec_capsuleZones="Capsule Zones", sec_treeTele="Trees",
        sec_stats="Your Stats", sec_runeChances="Rune ETA by Zone",
        tog_farmWheat="Farm Wheat", tog_depositWheat="Deposit Wheat",
        tog_autoChest="Auto Open Chest", tog_autoCap="Auto Open Capsule",
        tog_iceFarm="Ice Farm", tog_waterFarm="Water Farm",
        tog_campfire="Campfire", tog_ashConvert="Wood → Ash",
        tog_fillBucket="Fill Bucket", tog_hireNoob="Hire Noob",
        tog_factory="Factory", tog_cook="Cook",
        tog_animals="Animals", tog_mutation="Mutation",
        tog_blaze="Auto Blaze", tog_runes="Roll Runes",
        tog_tier="Roll Tier", tog_awaken="Awaken",
        tog_upgradeQuest="Auto Upgrade Quest",
        tog_teleportMode="Teleport Mode",
        tog_autoMine="Auto Mine", tog_exchangeOre="Exchange All Minerals",
        tog_prismEquip="Enable Auto-Equip",
        btn_open200="Open 200 Chests", btn_openAll="Open All Now",
        btn_mineAll="Mine All Ores", btn_calcEta="Calculate ETA",
        lbl_runeInterval="Roll Interval (s)",
        lbl_iceTeleWait="Ice Teleport Wait (s)",
        lbl_prismTrigger="Trigger (sec before payout)",
        lbl_runeLuck="Rune Luck (manual input)",
        inp_runeLuck="e.g. 1000000 or 1e6",
        lbl_noobNote="★ Noobinial class: no luck needed",
        lbl_prismNote="★ Cosmic Prism zone: no luck regardless",
        lbl_rps="RPS: ", lbl_cd="Cooldown: ", lbl_loading="loading...",
        lbl_equippedNow="Equipped: ", lbl_none="—",
        notif_capZone="Capsule Zone", notif_capOpened="Capsules opened: ",
        notif_mineAll="Mine All", notif_oresSelected=" ore types selected",
        notif_bestMinions="equipped", notif_notSaved="Pattern not saved",
        notif_prismReady="Prism — pattern ",
        notif_error="Error", notif_notFound=" not found",
    },
    ru = {
        win_title="Noob Incremental", win_sub="v7 · Benefit",
        tab_farm="Фарм", tab_combat="Бой", tab_mine="Шахта",
        tab_upgrades="Апгрейды", tab_equip="Снаряжение",
        tab_tele="Телепорт", tab_chances="Шансы",
        sec_wheat="Пшеница", sec_chests="Сундуки", sec_capsules="Капсулы",
        sec_world2="Мир 2", sec_world1="Мир 1",
        sec_blaze="Блейз", sec_runes="Прокатка рун",
        sec_runetele="Зоны рун", sec_tier="Уровень и пробуждение",
        sec_oreTypes="Типы руды", sec_mineSettings="Настройки",
        sec_automation="Автоматизация", sec_trees="Деревья апгрейдов",
        sec_aura="Аура", sec_slots="Слоты снаряжения",
        sec_minions="Миньоны", sec_minionPat="Шаблоны миньонов",
        sec_bestMinion="Лучшие миньоны", sec_equipPat="Шаблоны снаряжения",
        sec_prismEquip="Авто-экип призмы",
        sec_capsuleZones="Зоны капсул", sec_treeTele="Деревья",
        sec_stats="Ваши статы", sec_runeChances="ETA рун по зонам",
        tog_farmWheat="Фарм пшеницы", tog_depositWheat="Сдать пшеницу",
        tog_autoChest="Авто-сундук", tog_autoCap="Авто-капсула",
        tog_iceFarm="Ледяной фарм", tog_waterFarm="Водный фарм",
        tog_campfire="Костёр", tog_ashConvert="Дерево → Зола",
        tog_fillBucket="Заполнить ведро", tog_hireNoob="Нанять нуба",
        tog_factory="Фабрика", tog_cook="Готовка",
        tog_animals="Животные", tog_mutation="Мутация",
        tog_blaze="Авто-блейз", tog_runes="Катать руны",
        tog_tier="Катать уровень", tog_awaken="Пробуждение",
        tog_upgradeQuest="Авто-квест апгрейда",
        tog_teleportMode="Режим телепорта",
        tog_autoMine="Авто-добыча", tog_exchangeOre="Обменять минералы",
        tog_prismEquip="Включить авто-экип",
        btn_open200="Открыть 200 сундуков", btn_openAll="Открыть всё",
        btn_mineAll="Добыть все руды", btn_calcEta="Вычислить ETA",
        lbl_runeInterval="Интервал броска (с)",
        lbl_iceTeleWait="Ожидание телепорта (с)",
        lbl_prismTrigger="Триггер (сек до выплаты)",
        lbl_runeLuck="Рунная удача (вручную)",
        inp_runeLuck="напр. 1000000 или 1e6",
        lbl_noobNote="★ Нубиниальные руны: удача не нужна",
        lbl_prismNote="★ Космическая призма: без удачи",
        lbl_rps="RPS: ", lbl_cd="Перезарядка: ", lbl_loading="загрузка...",
        lbl_equippedNow="Надето: ", lbl_none="—",
        notif_capZone="Зона капсул", notif_capOpened="Открыто капсул: ",
        notif_mineAll="Добыча", notif_oresSelected=" типов руды выбрано",
        notif_bestMinions="одеты", notif_notSaved="Шаблон не сохранён",
        notif_prismReady="Призма — шаблон ",
        notif_error="Ошибка", notif_notFound=" не найдена",
    },
}
local function L(k) return (L_TABLE[LANG] and L_TABLE[LANG][k]) or (L_TABLE.en[k]) or k end

-- ─── NUMBER UTILITIES ─────────────────────────────────────────────────────────
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
    if not s or s == "" then return nil end
    s = tostring(s):gsub("%s",""):gsub(",",""):gsub("^[xX]","")
    local n = tonumber(s); if n then return n end
    for _, p in ipairs(SFXLIST) do
        local esc = p[2]:gsub("([%^%$%(%)%%%.%[%]%*%+%-%?])","%%%1")
        local m = s:match("^([%d%.]+)"..esc.."$")
        if m then return (tonumber(m) or 0) * p[1] end
    end
    local ms = s:match("^([%d%.]+)s$"); if ms then return tonumber(ms) end
    return nil
end
local function fmtNum(n)
    if not n or n ~= n then return "?" end
    if n == math.huge then return "inf" end
    for _, p in ipairs(SFXLIST) do
        if n >= p[1] then return string.format("%.2f",n/p[1])..p[2] end
    end
    return string.format("%.3g",n)
end
local function fmtTime(s)
    if not s or s ~= s then return "?" end
    if s == math.huge or s > 1e30 then return "∞" end
    if s < 60   then return string.format("%.1fs",s) end
    if s < 3600 then return string.format("%dm%ds",math.floor(s/60),math.floor(s%60)) end
    if s < 86400 then return string.format("%dh%dm",math.floor(s/3600),math.floor(s%3600/60)) end
    local d = math.floor(s/86400)
    if d < 365 then return string.format("%dd%dh",d,math.floor(s%86400/3600)) end
    return string.format("%.1fy",s/31536000)
end

-- ─── HELPERS ──────────────────────────────────────────────────────────────────
local function getChar() return LP.Character end
local function getHRP()  local c=getChar(); return c and c:FindFirstChild("HumanoidRootPart") end
local function getHum()  local c=getChar(); return c and c:FindFirstChild("Humanoid") end
local function fire(...) pcall(MR.FireServer, MR, ...) end
local function cdet(d)   pcall(fireclickdetector, d) end
local function notify(title, content, _icon, dur)
    task.spawn(function()
        pcall(Rayfield.Notify, Rayfield, {
            Title=title, Content=content, Duration=dur or 4,
            Image=4483362458,
        })
    end)
end
local function safeLoop(interval, fn)
    task.spawn(function() while true do pcall(fn); task.wait(interval) end end)
end

-- ─── STATE ────────────────────────────────────────────────────────────────────
local S = {
    wheat=false, deposit=false, blaze=false,
    chest=false, minionCap=false,
    iceFarm=false, waterFarm=false, campfire=false, ashConvert=false,
    hireNoob=false, fillBucket=false,
    factory=false, cook=false, animals=false, mutation=false,
    mining=false, exchangeOre=false, miningMode="teleport",
    runes=false, tier=false, awaken=false, upgradeQuest=false,
    prismEquip=false,
    StarterTree=false, TycoonTree=false, FarmTree=false,
    PrismTree=false, IceTree=false, MiningTree=false,
    Ice=false, Fire=false, Blaze=false, Water=false, Oof=false,
    Rebirth=false, Wood=false, Planks=false, Bread=false,
    Cash=false, Coin=false, HackPoints=false, Gem=false,
}
local selectedRunes   = {}
local runeInterval    = 0.1
local selectedIceBtn  = 12
local iceTeleportWait = 0.15
local capsuleOpenWait = 2.5
local selectedOres    = {}
local selectedChest   = "Chest"
local selectedMinCap  = "Classic"
local prismEquipPat   = 1
local prismThreshold  = 3
local patterns        = {nil,nil,nil}
local minionPatterns  = {nil,nil,nil}
local manualRuneLuck  = nil

-- ─── SETTINGS ─────────────────────────────────────────────────────────────────
local SAVE_FILE = "noob_incremental.cfg"
local BOOL_KEYS = {
    "wheat","deposit","blaze","chest","minionCap",
    "iceFarm","waterFarm","campfire","ashConvert","hireNoob","fillBucket",
    "factory","cook","animals","mutation","mining","exchangeOre",
    "runes","tier","awaken","upgradeQuest","prismEquip",
    "StarterTree","TycoonTree","FarmTree","PrismTree","IceTree","MiningTree",
    "Ice","Fire","Blaze","Water","Oof","Rebirth","Wood","Planks",
    "Bread","Cash","Coin","HackPoints","Gem",
}
local function saveSettings()
    local lines = {
        "runeInterval="..runeInterval, "selectedChest="..selectedChest,
        "selectedMinCap="..selectedMinCap, "prismThreshold="..prismThreshold,
        "prismEquipPat="..prismEquipPat, "miningMode="..S.miningMode,
        "selectedIceBtn="..selectedIceBtn, "iceTeleportWait="..iceTeleportWait,
        "capsuleOpenWait="..capsuleOpenWait,
        "lang="..LANG,
    }
    if manualRuneLuck then lines[#lines+1] = "runeLuck="..manualRuneLuck end
    local on = {}
    for _, k in ipairs(BOOL_KEYS) do if S[k] then on[#on+1] = k end end
    if #on > 0 then lines[#lines+1] = "toggles="..table.concat(on,",") end
    if #selectedRunes > 0 then lines[#lines+1] = "selectedRunes="..table.concat(selectedRunes,",") end
    local ores = {}
    for nm, v in pairs(selectedOres) do if v then ores[#ores+1] = nm end end
    if #ores > 0 then lines[#lines+1] = "selectedOres="..table.concat(ores,",") end
    -- Equipment patterns
    for i=1,3 do
        if patterns[i] then
            for _, sn in ipairs(SLOTS) do
                local ids = patterns[i][sn]
                if ids and #ids>0 then
                    lines[#lines+1]="pat"..i.."_"..sn.."="..table.concat(ids,",")
                end
            end
        end
        if minionPatterns[i] and #minionPatterns[i]>0 then
            lines[#lines+1]="minPat"..i.."="..table.concat(minionPatterns[i],",")
        end
    end
    pcall(writefile, SAVE_FILE, table.concat(lines,"\n"))
end
local function loadSettings()
    local ok, txt = pcall(readfile, SAVE_FILE)
    if not ok or not txt then return end
    for line in txt:gmatch("[^\n]+") do
        local k, v = line:match("^(.-)=(.*)$")
        if k then
            if     k=="runeInterval"    then runeInterval    = tonumber(v) or 0.1
            elseif k=="selectedChest"   then selectedChest   = v or "Chest"
            elseif k=="selectedMinCap"  then selectedMinCap  = v or "Classic"
            elseif k=="prismThreshold"  then prismThreshold  = tonumber(v) or 3
            elseif k=="prismEquipPat"   then prismEquipPat   = tonumber(v) or 1
            elseif k=="miningMode"      then S.miningMode    = v or "teleport"
            elseif k=="selectedIceBtn"  then selectedIceBtn  = tonumber(v) or 12
            elseif k=="iceTeleportWait" then iceTeleportWait = tonumber(v) or 0.15
            elseif k=="capsuleOpenWait" then capsuleOpenWait = tonumber(v) or 2.5
            elseif k=="lang"            then if v=="ru" or v=="en" then LANG=v end
            elseif k=="runeLuck"        then manualRuneLuck  = tonumber(v)
            elseif k=="toggles" and v~="" then
                for key in v:gmatch("[^,]+") do S[key]=true end
            elseif k=="selectedRunes" and v~="" then
                selectedRunes={}; for r in v:gmatch("[^,]+") do selectedRunes[#selectedRunes+1]=r end
            elseif k=="selectedOres" and v~="" then
                selectedOres={}; for r in v:gmatch("[^,]+") do selectedOres[r]=true end
            elseif k:match("^pat(%d)_(.+)$") then
                local pi,sn=k:match("^pat(%d)_(.+)$"); pi=tonumber(pi)
                if pi and pi>=1 and pi<=3 then
                    if not patterns[pi] then patterns[pi]={} end
                    patterns[pi][sn]={}
                    for id in v:gmatch("[^,]+") do patterns[pi][sn][#patterns[pi][sn]+1]=id end
                end
            elseif k:match("^minPat(%d)$") then
                local pi=tonumber(k:match("^minPat(%d)$"))
                if pi and pi>=1 and pi<=3 and v~="" then
                    minionPatterns[pi]={}
                    for id in v:gmatch("[^,]+") do minionPatterns[pi][#minionPatterns[pi]+1]=id end
                end
            end
        end
    end
end
loadSettings()

-- ─── CACHE ────────────────────────────────────────────────────────────────────
local wheatCDs = {}
do
    local farm = GC:FindFirstChild("Farm")
    if farm then
        for _, w in ipairs(farm:GetChildren()) do
            local c = w:FindFirstChildWhichIsA("ClickDetector")
            if c then wheatCDs[#wheatCDs+1] = c end
        end
    end
end

local TREE_NAMES = {"StarterTree","TycoonTree","FarmTree","PrismTree","IceTree","MiningTree"}
local treeCDs = {}
do
    local ut = GC:FindFirstChild("UpgradeTree")
    if ut then
        for _, tn in ipairs(TREE_NAMES) do
            treeCDs[tn] = {}
            local tree = ut:FindFirstChild(tn)
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

local function getOreFolder()
    local f = GC:FindFirstChild("Ores"); if f then return f end
    local ct = GC:FindFirstChild("Contents"); if not ct then return nil end
    for _, w in ipairs(ct:GetChildren()) do
        local wf = w:FindFirstChild("Ores"); if wf then return wf end
    end
end
local function getOreTypes()
    local f = getOreFolder(); if not f then return {} end
    local seen, t = {}, {}
    for _, ore in ipairs(f:GetChildren()) do
        if not seen[ore.Name] then seen[ore.Name]=true; t[#t+1]=ore.Name end
    end
    table.sort(t); return t
end
local ORE_TYPES = getOreTypes()

local CAPSULE_PARTS = {}
do
    local uiZ = GC:FindFirstChild("UIZones")
    if uiZ then
        for _, ct2 in ipairs({"Classic","Super"}) do
            local mdl = uiZ:FindFirstChild("__Capsule"..ct2)
            if mdl then
                local tp = mdl:FindFirstChild("TouchPart")
                    or mdl:FindFirstChildWhichIsA("BasePart")
                    or mdl:FindFirstChildOfClass("Part")
                CAPSULE_PARTS[ct2] = tp
            end
        end
    end
    -- fallback: search whole UIZones for any part with "Capsule" in parent name
    if uiZ and (not CAPSULE_PARTS.Classic) then
        for _, obj in ipairs(uiZ:GetDescendants()) do
            if obj:IsA("BasePart") then
                local pn = obj.Parent and obj.Parent.Name or ""
                if pn:lower():find("capsule") then
                    if pn:lower():find("super") then
                        CAPSULE_PARTS.Super = CAPSULE_PARTS.Super or obj
                    else
                        CAPSULE_PARTS.Classic = CAPSULE_PARTS.Classic or obj
                    end
                end
            end
        end
    end
end
local CAPSULE_PRICE = {Classic=1e9, Super=1e10}
local prismAmountV  = LP.CURRENCIES.Prism.Amount:FindFirstChild("1")

LP.PlayerGui.ChildAdded:Connect(function(child)
    if child.Name=="CapsuleOpeningDisplayFrame" then child.Enabled=false end
end)

local function withCapsuleZone(ctype, fn)
    local part=CAPSULE_PARTS[ctype]; local hrp=getHRP()
    if not hrp then fn(); return end
    if not part then fn(); return end
    local origin=hrp.CFrame
    hrp.CFrame = part.CFrame
    task.wait(0.5)
    fn()
    task.wait(0.2)
    hrp.CFrame=origin
end

local ICE_BTN = {}
do
    local ct = GC:FindFirstChild("Contents")
    local w2 = ct and ct:FindFirstChild("WORLD - 2")
    local ib = w2 and w2:FindFirstChild("IceButtons")
    if ib then
        for i=1,12 do
            local mdl = ib:FindFirstChild(tostring(i))
            if mdl then
                local d = {}
                for _, desc in ipairs(mdl:GetDescendants()) do
                    if desc:IsA("ClickDetector") then d.cd=desc; break end
                end
                d.part = mdl:FindFirstChild("ButtonUI") or mdl:FindFirstChildWhichIsA("BasePart")
                ICE_BTN[i] = d
            end
        end
    end
end

local currentTierV = LP.FEATURES.TIER.Tier
local function getAwakenCost()
    local wui = LP.PlayerGui:FindFirstChild("WorldUI"); if not wui then return nil end
    for _, gui in ipairs(wui:GetChildren()) do
        if gui:IsA("SurfaceGui") then
            local aw=gui:FindFirstChild("Awaken"); local rq=gui:FindFirstChild("Req")
            if aw and aw:IsA("TextButton") and rq then return rq:FindFirstChild("Cost") end
        end
    end
end
local awakenCostV = getAwakenCost()

-- ─── EQUIPMENT ────────────────────────────────────────────────────────────────
local SLOTS = {"Necklace","Special","Ring","Geode"}
local function readEquipped()
    local t = {}
    for _, sn in ipairs(SLOTS) do
        t[sn] = {}
        -- Read from Inventory (same IDs used by equipItem/dropdown), cross-check Equipped
        local invSlot = LP.FEATURES.EQUIPMENT.Inventory:FindFirstChild(sn)
        local eqSlot  = LP.FEATURES.EQUIPMENT.Equipped:FindFirstChild(sn)
        if invSlot then
            for _, item in ipairs(invSlot:GetChildren()) do
                if item:IsA("StringValue") then
                    local eqV = eqSlot and eqSlot:FindFirstChild(item.Name)
                    if eqV and eqV.Value then t[sn][#t[sn]+1]=item.Name end
                end
            end
        else
            -- Fallback: read directly from Equipped folder
            if eqSlot then
                for _, item in ipairs(eqSlot:GetChildren()) do
                    if item:IsA("BoolValue") and item.Value then t[sn][#t[sn]+1]=item.Name end
                end
            end
        end
    end
    return t
end
local function readInventory()
    local t = {}
    for _, sn in ipairs(SLOTS) do
        t[sn] = {}
        local sf = LP.FEATURES.EQUIPMENT.Inventory:FindFirstChild(sn)
        if sf then
            for _, item in ipairs(sf:GetChildren()) do
                if item:IsA("StringValue") then t[sn][item.Name]=item.Value end
            end
        end
    end
    return t
end
local function equipItem(sn, id)   pcall(MR.FireServer,MR,"EquipEquipment",  sn,id) end
local function unequipItem(sn, id) pcall(MR.FireServer,MR,"UnequipEquipment",sn,id) end
local function unequipSlot(sn)
    local ef=LP.FEATURES.EQUIPMENT.Equipped:FindFirstChild(sn); if not ef then return end
    for _, item in ipairs(ef:GetChildren()) do
        if item.Value then unequipItem(sn,item.Name); task.wait(0.08) end
    end
end

-- ─── MINIONS ──────────────────────────────────────────────────────────────────
local MINIONS_F = LP.FEATURES.LAB:FindFirstChild("MINIONS")
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
    -- Fallback: iterate inventory and unequip anything marked Equipped=true
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
        -- Fallback via inventory Equipped BoolValue
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

-- ─── PATTERNS ─────────────────────────────────────────────────────────────────
local function applyPattern(n)
    if not patterns[n] then return end
    for _, sn in ipairs(SLOTS) do
        local ids=patterns[n][sn]
        if ids then
            unequipSlot(sn); task.wait(0.1)
            for _, id in ipairs(ids) do equipItem(sn,tostring(id)); task.wait(0.1) end
        end
    end
end

-- ─── AURA / PRISM ─────────────────────────────────────────────────────────────
local ownedAuras = {}
do
    local ai=LP.FEATURES.AURAS:FindFirstChild("Inventory")
    if ai then
        for _, v in ipairs(ai:GetChildren()) do
            if v:IsA("BoolValue") and v.Value then ownedAuras[#ownedAuras+1]=v.Name end
        end
        table.sort(ownedAuras)
    end
end
local currentAura = ""
pcall(function()
    local eq=LP.FEATURES.AURAS:FindFirstChild("Equipped")
    if not eq then return end
    if eq:IsA("StringValue") then
        currentAura = eq.Value or ""
    elseif eq:IsA("Folder") then
        for _, v in ipairs(eq:GetChildren()) do
            if v:IsA("BoolValue") and v.Value then currentAura=v.Name; break end
        end
    end
end)
local prismCooldownV = LP.FEATURES.PRISMS:FindFirstChild("_cooldown")

-- ─── MINING ───────────────────────────────────────────────────────────────────
local function getOrePos(ore)
    if not (ore and ore.Parent) then return nil end
    local rock=ore:FindFirstChild("Rock"); if not rock then return nil end
    if rock:IsA("BasePart") or rock:IsA("MeshPart") then return rock.Position end
    local p=rock:FindFirstChildWhichIsA("BasePart") or rock:FindFirstChildWhichIsA("MeshPart")
    return p and p.Position
end

-- ─── RUNE DATA ────────────────────────────────────────────────────────────────
-- c = 1-in-N chance  |  cl = "Basic" (luck applies) | "Noobinial" (no luck)
-- special = true → zone ignores luck entirely (Cosmic Prism)
local RUNE_ZONES = {
    {name="Basic Rune", invKey="Basic", runes={
        {n="Rookie",       c=1.25,     cl="Basic"},
        {n="Learner",      c=6.67,     cl="Basic"},
        {n="Trained",      c=33.29,    cl="Basic"},
        {n="Skilled",      c=200,      cl="Basic"},
        {n="Expert",       c=5e4,      cl="Basic"},
        {n="Master",       c=1e6,      cl="Basic"},
        {n="Grandmaster",  c=4e7,      cl="Basic"},
        {n="Celestial",    c=6.25e11,  cl="Basic"},
        {n="Immortal",     c=7.69e26,  cl="Basic"},
        {n="Shadow",       c=1e22,     cl="Noobinial"},
        {n="Phantom",      c=1e28,     cl="Noobinial"},
        {n="Atomic",       c=1.33e48,  cl="Noobinial"},
        {n="Chronos Core", c=3.08e49,  cl="Noobinial"},
    }},
    {name="Super Runes", invKey="Super", runes={
        {n="Initiate",       c=1.11,    cl="Basic"},
        {n="Adept",          c=13.3,    cl="Basic"},
        {n="Veteran",        c=50,      cl="Basic"},
        {n="Elite",          c=5e3,     cl="Basic"},
        {n="Champion",       c=2e5,     cl="Basic"},
        {n="Ascended",       c=2e6,     cl="Basic"},
        {n="Transcendent",   c=5e7,     cl="Basic"},
        {n="Universal",      c=2e19,    cl="Basic"},
        {n="Omnipotent",     c=1.75e28, cl="Basic"},
        {n="Eclipse",        c=1e24,    cl="Noobinial"},
        {n="Void",           c=1e31,    cl="Noobinial"},
        {n="Primordial",     c=2.5e37,  cl="Noobinial"},
        {n="Oblivion Sigil", c=2.35e51, cl="Noobinial"},
    }},
    {name="Advanced Runes", invKey="Advanced", runes={
        {n="Little",           c=1.01,     cl="Basic"},
        {n="Lesser",           c=1e5,      cl="Basic"},
        {n="Standard",         c=1e6,      cl="Basic"},
        {n="Greater",          c=5e7,      cl="Basic"},
        {n="Superior",         c=2e8,      cl="Basic"},
        {n="Prime",            c=1e11,     cl="Basic"},
        {n="Apex",             c=1e12,     cl="Basic"},
        {n="Ethereal",         c=5e13,     cl="Basic"},
        {n="Divine",           c=2e17,     cl="Basic"},
        {n="Infinite",         c=1.75e28,  cl="Basic"},
        {n="Abyss",            c=1e26,     cl="Noobinial"},
        {n="Enigma",           c=1e34,     cl="Noobinial"},
        {n="Seraphim's Tear",  c=4e44,     cl="Noobinial"},
        {n="Aetherion",        c=1.21e53,  cl="Noobinial"},
    }},
    {name="Cosmic Prism", invKey="Cosmic Prism", special=true, runes={
        {n="Lucent",        c=2.5,     cl="Basic"},
        {n="Chroma",        c=4,       cl="Basic"},
        {n="Fractal",       c=20,      cl="Basic"},
        {n="Refraction",    c=100,     cl="Basic"},
        {n="Tessellation",  c=200,     cl="Basic"},
        {n="Hyperlight",    c=333,     cl="Basic"},
        {n="PrismGod",      c=1e3,     cl="Basic"},
        {n="Voidglass",     c=1e6,     cl="Basic"},
        {n="Godshard",      c=1e8,     cl="Noobinial"},
        {n="Ultimate Shard",c=6.67e11, cl="Noobinial"},
    }},
    {name="Hacker Runes", invKey="Hacker", runes={
        {n="Script",    c=1.01,    cl="Basic"},
        {n="Protocol",  c=1e17,    cl="Basic"},
        {n="Cipher",    c=1e22,    cl="Basic"},
        {n="Exploit",   c=1e27,    cl="Basic"},
        {n="Kernel",    c=1e30,    cl="Basic"},
        {n="Root",      c=1e33,    cl="Basic"},
        {n="Backdoor",  c=1e36,    cl="Basic"},
        {n="Rootkit",   c=1e27,    cl="Noobinial"},
        {n="Masterkey", c=2e28,    cl="Noobinial"},
        {n="Stuxnet",   c=6.98e31, cl="Noobinial"},
    }},
    {name="Snowy Runes", invKey="Snowy", runes={
        {n="Snow",       c=1.01,    cl="Basic"},
        {n="Frost",      c=1e18,    cl="Basic"},
        {n="Ice",        c=1e20,    cl="Basic"},
        {n="Hail",       c=2e21,    cl="Basic"},
        {n="Glacier",    c=1e26,    cl="Basic"},
        {n="Blizzard",   c=5e41,    cl="Basic"},
        {n="Tundra",     c=2e45,    cl="Basic"},
        {n="Arctic",     c=4e59,    cl="Basic"},
        {n="Permafrost", c=1.9e65,  cl="Basic"},
        {n="Whiteout",   c=4e53,    cl="Noobinial"},
        {n="Icebound",   c=3.33e56, cl="Noobinial"},
        {n="Everfrost",  c=2.5e59,  cl="Noobinial"},
    }},
}

-- ─── PROFILE STAT READER ──────────────────────────────────────────────────────
local function readProfileStats()
    local rps, cd, luck
    pcall(function()
        local statsF = LP.PlayerGui.Profile.Main.Frame.Main.ScrollingFrame.MainProfile.Profile.Stats
        rps  = parseNum(statsF.RPS.Amount.Text)
        cd   = parseNum(statsF.RuneSpeed.Amount.Text)
        luck = parseNum(statsF.RuneLuck.Amount.Text)
    end)
    return rps, cd, luck
end

-- ─── GAME LOOPS ───────────────────────────────────────────────────────────────
local UPGRADE_TYPES = {"Ice","Fire","Blaze","Water","Oof","Rebirth","Wood","Planks","Bread","Cash","Coin","HackPoints","Gem"}

safeLoop(0.1, function()
    if S.tier then fire("RollTier") end
end)

safeLoop(1, function()
    if S.wheat      then for _, w in ipairs(wheatCDs) do cdet(w) end end
    if S.deposit    then fire("DepositWheat")        end
    if S.waterFarm  then fire("Water")               end
    if S.campfire   then fire("CampfireButton")      end
    if S.ashConvert then fire("ConvertWoodToAsh")    end
    if S.hireNoob   then fire("HireNoob")            end
    if S.fillBucket then fire("FillBucket")          end
    if S.factory    then fire("Factory")             end
    if S.cook       then fire("Cook")                end
    if S.animals    then fire("Animals")             end
    if S.mutation   then fire("Mutation")            end
    if S.exchangeOre then fire("ExchangeAllMinerals") end
    if S.blaze or S.upgradeQuest then fire("Blaze") end
    if S.chest      then fire("OpenChest",selectedChest) end
end)

safeLoop(3, function()
    for _, ut in ipairs(UPGRADE_TYPES) do
        if S[ut] or (ut=="Fire" and S.upgradeQuest) then
            fire("SetUpgradeAutomationPaused",ut,false)
        end
    end
    if S.awaken then
        if awakenCostV and awakenCostV.Text then
            local needed  = tonumber(awakenCostV.Text:match("%(#(%d+)%)") or awakenCostV.Text:match("(%d+)"))
            local current = tonumber(currentTierV and currentTierV.Value) or 0
            if not needed or current >= needed then fire("AwakenTier") end
        else fire("AwakenTier") end
    end
    if S.minionCap then
        local prism = prismAmountV and tonumber(prismAmountV.Value) or 0
        local price = CAPSULE_PRICE[selectedMinCap] or 1e9
        if prism >= price then
            withCapsuleZone(selectedMinCap, function()
                -- open as many as affordable in one zone visit
                while true do
                    local p2 = prismAmountV and tonumber(prismAmountV.Value) or 0
                    if p2 < price or not S.minionCap then break end
                    fire("OpenCapsule", selectedMinCap)
                    task.wait(0.3)
                end
            end)
        end
    end
end)

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

safeLoop(2, function()
    if not S.iceFarm then return end
    local d=ICE_BTN[selectedIceBtn]
    if not (d and d.part) then fire("Ice",selectedIceBtn); return end
    local hrp=getHRP(); if not hrp then return end
    local origin=hrp.CFrame
    hrp.CFrame=HIDE_CF; task.wait(0.05)
    hrp.CFrame=CFrame.new(d.part.Position+Vector3.new(0,3,0)); task.wait(iceTeleportWait)
    fire("Ice",selectedIceBtn); task.wait(0.15); hrp.CFrame=origin
end)

safeLoop(0.4, function()
    if not (S.mining and next(selectedOres)~=nil) then return end
    local folder=getOreFolder(); local hrp=getHRP()
    if not (folder and hrp) then return end
    local best, bd = nil, math.huge
    for _, ore in ipairs(folder:GetChildren()) do
        if selectedOres[ore.Name] and ore.Parent then
            local pos=getOrePos(ore)
            if pos then
                local dd=(pos-hrp.Position).Magnitude
                if dd < bd then bd=dd; best=pos end
            end
        end
    end
    if best then
        if S.miningMode=="teleport" then hrp.CFrame=CFrame.new(best+Vector3.new(0,4,0))
        else local hum=getHum(); if hum then hum:MoveTo(best) end end
    end
end)

task.spawn(function()
    while true do
        if S.runes and #selectedRunes > 0 then
            for _, rune in ipairs(selectedRunes) do
                pcall(MR.FireServer,MR,"RollRune",rune)
                task.wait(math.max(0.05,runeInterval))
            end
        else task.wait(0.1) end
    end
end)

local prismArmed = false
local prismSaved = {equip=nil, minions=nil}
safeLoop(0.5, function()
    if not (S.prismEquip and prismCooldownV) then return end
    local secs=tonumber(prismCooldownV.Value)
    if secs and secs<=prismThreshold and not prismArmed then
        prismArmed=true
        -- Save current equipment + minion state before swapping
        prismSaved.equip   = readEquipped()
        prismSaved.minions = readMinionEquipped()
        local letter=({"A","B","C"})[prismEquipPat]
        task.spawn(function()
            applyPattern(prismEquipPat)
            local mp=minionPatterns[prismEquipPat]
            if mp and #mp>0 then
                unequipAllMinions(); task.wait(0.2)
                for _, id in ipairs(mp) do equipMinion(id); task.wait(0.1) end
            end
        end)
        notify(L("notif_prismReady")..letter, "~"..secs.."s","zap")
    elseif secs and secs>prismThreshold and prismArmed then
        -- Prism just fired — restore previous equipment + minions
        prismArmed=false
        local savedEquip   = prismSaved.equip
        local savedMinions = prismSaved.minions
        prismSaved={equip=nil, minions=nil}
        task.spawn(function()
            task.wait(0.5)
            if savedEquip then
                for _, sn in ipairs(SLOTS) do
                    local ids=savedEquip[sn]
                    if ids and #ids>0 then
                        unequipSlot(sn); task.wait(0.15)
                        for _, id in ipairs(ids) do equipItem(sn,tostring(id)); task.wait(0.1) end
                    end
                end
            end
            if savedMinions and #savedMinions>0 then
                unequipAllMinions(); task.wait(0.2)
                for _, id in ipairs(savedMinions) do equipMinion(id); task.wait(0.1) end
            end
        end)
        notify("Prism","Снаряжение восстановлено","check")
    end
end)

-- ─── GUI WINDOW ───────────────────────────────────────────────────────────────
local Win = Rayfield:CreateWindow({
    Name            = L("win_title"),
    Icon            = "star",
    LoadingTitle    = "Noob Incremental",
    LoadingSubtitle = "v7 · Benefit",
    Theme           = "Default",
    DisableRayfieldPrompts = false,
    DisableBuildWarnings   = true,
    ConfigurationSaving    = {Enabled=false},
    KeySystem              = false,
})

local TabFarm    = Win:CreateTab(L("tab_farm"),     "wheat")
local TabCombat  = Win:CreateTab(L("tab_combat"),   "swords")
local TabMine    = Win:CreateTab(L("tab_mine"),     "pickaxe")
local TabUpgrade = Win:CreateTab(L("tab_upgrades"), "trending-up")
local TabEquip   = Win:CreateTab(L("tab_equip"),    "backpack")
local TabTele    = Win:CreateTab(L("tab_tele"),     "map-pin")
local TabChances = Win:CreateTab(L("tab_chances"),  "percent")

-- ══ LANGUAGE ══════════════════════════════════════════════════════════════════
TabFarm:CreateSection("Language / Язык")
TabFarm:CreateDropdown({
    Name="Language", Options={"English","Русский"}, MultipleOptions=false,
    CurrentOption={LANG=="ru" and "Русский" or "English"}, Flag="lang",
    Callback=function(o)
        LANG=(o[1]=="Русский") and "ru" or "en"; saveSettings()
        notify("Language","Reload script to apply","globe")
    end,
})

-- ══ FARM ══════════════════════════════════════════════════════════════════════
TabFarm:CreateSection(L("sec_wheat"))
TabFarm:CreateToggle({Name=L("tog_farmWheat"),    CurrentValue=S.wheat,   Flag="fw",  Callback=function(v) S.wheat=v;   saveSettings() end})
TabFarm:CreateToggle({Name=L("tog_depositWheat"), CurrentValue=S.deposit, Flag="dw",  Callback=function(v) S.deposit=v; saveSettings() end})

TabFarm:CreateSection(L("sec_chests"))
TabFarm:CreateDropdown({
    Name="Chest Type", Options={"Chest","GoldenChest"},
    CurrentOption={selectedChest}, MultipleOptions=false, Flag="chestType",
    Callback=function(o) selectedChest=o[1] or "Chest"; saveSettings() end,
})
TabFarm:CreateToggle({Name=L("tog_autoChest"), CurrentValue=S.chest, Flag="ach", Callback=function(v) S.chest=v; saveSettings() end})
TabFarm:CreateButton({Name=L("btn_open200"), Callback=function()
    task.spawn(function() for _=1,200 do fire("OpenChest",selectedChest); task.wait(0.5) end end)
end})

TabFarm:CreateSection(L("sec_capsules"))
TabFarm:CreateDropdown({
    Name="Capsule Zone", Options={"Classic","Super"},
    CurrentOption={selectedMinCap}, MultipleOptions=false, Flag="capZone",
    Callback=function(o) selectedMinCap=o[1] or "Classic"; saveSettings() end,
})
TabFarm:CreateToggle({Name=L("tog_autoCap"), CurrentValue=S.minionCap, Flag="acap", Callback=function(v)
    S.minionCap=v; saveSettings()
end})
TabFarm:CreateButton({Name=L("btn_openAll"), Callback=function()
    task.spawn(function()
        local count=0
        local price=CAPSULE_PRICE[selectedMinCap] or 1e9
        withCapsuleZone(selectedMinCap, function()
            while true do
                local prism=prismAmountV and tonumber(prismAmountV.Value) or 0
                if prism<price then break end
                fire("OpenCapsule",selectedMinCap); count=count+1; task.wait(0.3)
            end
        end)
        notify(L("notif_capZone"),L("notif_capOpened")..count,"package")
    end)
end})

TabFarm:CreateSection(L("sec_world2"))
TabFarm:CreateDropdown({
    Name="Ice Button", Flag="iceBtn",
    Options={"1","2","3","4","5","6","7","8","9","10","11","12"},
    CurrentOption={tostring(selectedIceBtn)}, MultipleOptions=false,
    Callback=function(o) selectedIceBtn=tonumber(o[1]) or 12; saveSettings() end,
})
TabFarm:CreateSlider({
    Name=L("lbl_iceTeleWait"), Range={0.05,2.0}, Increment=0.05,
    CurrentValue=iceTeleportWait, Flag="iceTW",
    Callback=function(v) iceTeleportWait=v; saveSettings() end,
})
TabFarm:CreateToggle({Name=L("tog_iceFarm"),    CurrentValue=S.iceFarm,    Flag="if_", Callback=function(v) S.iceFarm=v;    saveSettings() end})
TabFarm:CreateToggle({Name=L("tog_waterFarm"),  CurrentValue=S.waterFarm,  Flag="wf_", Callback=function(v) S.waterFarm=v;  saveSettings() end})
TabFarm:CreateToggle({Name=L("tog_campfire"),   CurrentValue=S.campfire,   Flag="cf_", Callback=function(v) S.campfire=v;   saveSettings() end})
TabFarm:CreateToggle({Name=L("tog_ashConvert"), CurrentValue=S.ashConvert, Flag="ac_", Callback=function(v) S.ashConvert=v; saveSettings() end})
TabFarm:CreateToggle({Name=L("tog_fillBucket"), CurrentValue=S.fillBucket, Flag="fb_", Callback=function(v) S.fillBucket=v; saveSettings() end})
TabFarm:CreateToggle({Name=L("tog_hireNoob"),   CurrentValue=S.hireNoob,   Flag="hn_", Callback=function(v) S.hireNoob=v;   saveSettings() end})

TabFarm:CreateSection(L("sec_world1"))
TabFarm:CreateToggle({Name=L("tog_factory"),  CurrentValue=S.factory,  Flag="fac", Callback=function(v) S.factory=v;  saveSettings() end})
TabFarm:CreateToggle({Name=L("tog_cook"),     CurrentValue=S.cook,     Flag="ck_", Callback=function(v) S.cook=v;     saveSettings() end})
TabFarm:CreateToggle({Name=L("tog_animals"),  CurrentValue=S.animals,  Flag="an_", Callback=function(v) S.animals=v;  saveSettings() end})
TabFarm:CreateToggle({Name=L("tog_mutation"), CurrentValue=S.mutation, Flag="mut", Callback=function(v) S.mutation=v; saveSettings() end})

TabFarm:CreateSection("Player Speed & Jump")
TabFarm:CreateSlider({
    Name="Walk Speed", Range={16,300}, Increment=1, CurrentValue=16, Flag="wspd",
    Callback=function(v)
        pcall(function() local h=getHum(); if h then h.WalkSpeed=v end end)
    end,
})
TabFarm:CreateSlider({
    Name="Jump Power", Range={50,500}, Increment=5, CurrentValue=50, Flag="jmpw",
    Callback=function(v)
        pcall(function() local h=getHum(); if h then h.JumpPower=v end end)
    end,
})
TabFarm:CreateButton({Name="Reset Speed & Jump", Callback=function()
    pcall(function() local h=getHum(); if h then h.WalkSpeed=16; h.JumpPower=50 end end)
    notify("Player","Speed & Jump reset","check")
end})

-- ══ COMBAT ════════════════════════════════════════════════════════════════════
TabCombat:CreateSection(L("sec_blaze"))
TabCombat:CreateToggle({Name=L("tog_blaze"), CurrentValue=S.blaze, Flag="blz", Callback=function(v) S.blaze=v; saveSettings() end})

TabCombat:CreateSection(L("sec_runes"))
TabCombat:CreateDropdown({
    Name="Zones", Flag="runeZones",
    Options={"Basic","Super","Advanced","Cosmic Prism","Hacker","Snowy","Deepcore"},
    CurrentOption=selectedRunes, MultipleOptions=true,
    Callback=function(o) selectedRunes=o; saveSettings() end,
})
TabCombat:CreateSlider({
    Name=L("lbl_runeInterval"), Range={0.05,2}, Increment=0.05,
    CurrentValue=runeInterval, Flag="runeInt",
    Callback=function(v) runeInterval=v; saveSettings() end,
})
TabCombat:CreateToggle({Name=L("tog_runes"), CurrentValue=S.runes, Flag="rn_", Callback=function(v) S.runes=v; saveSettings() end})

TabCombat:CreateSection(L("sec_tier"))
TabCombat:CreateToggle({Name=L("tog_tier"),         CurrentValue=S.tier,         Flag="tr_", Callback=function(v) S.tier=v;         saveSettings() end})
TabCombat:CreateToggle({Name=L("tog_awaken"),        CurrentValue=S.awaken,       Flag="aw_", Callback=function(v) S.awaken=v;       saveSettings() end})
TabCombat:CreateToggle({Name=L("tog_upgradeQuest"),  CurrentValue=S.upgradeQuest, Flag="uq_",
    Callback=function(v)
        S.upgradeQuest=v; saveSettings()
        if v then fire("SetUpgradeAutomationPaused","Fire",false) end
    end,
})

-- ══ MINE ══════════════════════════════════════════════════════════════════════
TabMine:CreateSection(L("sec_oreTypes"))
local savedOreList={}
for nm, v in pairs(selectedOres) do if v then savedOreList[#savedOreList+1]=nm end end
TabMine:CreateDropdown({
    Name="Select Ores", Flag="oreList",
    Options=(#ORE_TYPES>0 and ORE_TYPES or {"(none)"}),
    CurrentOption=savedOreList, MultipleOptions=true,
    Callback=function(o)
        selectedOres={}; for _, nm in ipairs(o) do selectedOres[nm]=true end; saveSettings()
    end,
})
TabMine:CreateButton({Name=L("btn_mineAll"), Callback=function()
    selectedOres={}; local r=getOreTypes()
    for _, nm in ipairs(r) do selectedOres[nm]=true end
    local c=0; for _ in pairs(selectedOres) do c=c+1 end
    saveSettings(); notify(L("notif_mineAll"),c..L("notif_oresSelected"),"pickaxe")
end})

TabMine:CreateSection(L("sec_mineSettings"))
TabMine:CreateToggle({Name=L("tog_teleportMode"), CurrentValue=S.miningMode=="teleport", Flag="mtp",
    Callback=function(v) S.miningMode=v and "teleport" or "walk"; saveSettings() end})
TabMine:CreateToggle({Name=L("tog_autoMine"),    CurrentValue=S.mining,      Flag="mn_",  Callback=function(v) S.mining=v;      saveSettings() end})
TabMine:CreateToggle({Name=L("tog_exchangeOre"), CurrentValue=S.exchangeOre, Flag="exo",  Callback=function(v) S.exchangeOre=v; saveSettings() end})

-- ══ UPGRADES ══════════════════════════════════════════════════════════════════
TabUpgrade:CreateSection(L("sec_automation"))
local upgradesF = LP.FEATURES:FindFirstChild("AUTOMATIONS") and LP.FEATURES.AUTOMATIONS:FindFirstChild("Upgrades")
for _, ut in ipairs(UPGRADE_TYPES) do
    local folder=upgradesF and upgradesF:FindFirstChild(ut)
    if folder then
        local locked=(function()
            local uV=folder:FindFirstChild("Unlocked"); return uV and not uV.Value
        end)()
        local utKey=ut
        TabUpgrade:CreateToggle({
            Name=ut..(locked and " [locked]" or ""),
            CurrentValue=S[utKey], Flag="upg_"..utKey,
            Callback=function(v) S[utKey]=v; saveSettings() end,
        })
    end
end

TabUpgrade:CreateSection(L("sec_trees"))
for _, tn in ipairs(TREE_NAMES) do
    local count=treeCDs[tn] and #treeCDs[tn] or 0
    local tnKey=tn
    TabUpgrade:CreateToggle({
        Name=tn.." ("..count..")",
        CurrentValue=S[tnKey], Flag="tree_"..tnKey,
        Callback=function(v) S[tnKey]=v; saveSettings() end,
    })
end

-- ══ EQUIPMENT ══════════════════════════════════════════════════════════════════
if #ownedAuras > 0 then
    TabEquip:CreateSection(L("sec_aura"))
    TabEquip:CreateDropdown({
        Name="Aura", Options=ownedAuras, Flag="aura",
        CurrentOption=(currentAura~="" and {currentAura} or {}), MultipleOptions=false,
        Callback=function(o) if o[1] then fire("EquipAura",o[1]) end end,
    })
end

-- Equipment Slots
TabEquip:CreateSection(L("sec_slots"))
do
    local invF=LP.FEATURES.EQUIPMENT.Inventory
    local eqF2=LP.FEATURES.EQUIPMENT.Equipped
    for _, sn in ipairs(SLOTS) do
        local sf=invF:FindFirstChild(sn)
        local ef=eqF2:FindFirstChild(sn)
        if sf and #sf:GetChildren() > 0 then
            -- Build name→id maps
            local nameById, nameCount = {}, {}
            for _, item in ipairs(sf:GetChildren()) do
                if item:IsA("StringValue") then
                    local base = item.Value~="" and item.Value or ("ID "..item.Name)
                    nameById[item.Name] = base
                    nameCount[base] = (nameCount[base] or 0) + 1
                end
            end

            -- Build clean dropdown options (no [ON]/[OFF])
            local opts, idByOpt, curOpts = {}, {}, {}
            for _, item in ipairs(sf:GetChildren()) do
                if item:IsA("StringValue") then
                    local base = nameById[item.Name]
                    local dedup = (nameCount[base] or 1) > 1 and (" #"..item.Name) or ""
                    local label = base..dedup
                    opts[#opts+1] = label
                    idByOpt[label] = item.Name
                    local eqItem = ef and ef:FindFirstChild(item.Name)
                    if eqItem and eqItem.Value then curOpts[#curOpts+1] = label end
                end
            end
            table.sort(opts)

            local function getEquippedStr()
                if not ef then return L("lbl_none") end
                local names = {}
                for _, item in ipairs(ef:GetChildren()) do
                    if item.Value then
                        local nm = nameById[item.Name]
                        if nm then names[#names+1] = nm end
                    end
                end
                return #names > 0 and table.concat(names, ", ") or L("lbl_none")
            end

            local sname = sn
            local eqLabel = TabEquip:CreateLabel(sname..": "..getEquippedStr())

            TabEquip:CreateDropdown({
                Name=sname, Options=opts, Flag="slot_"..sname,
                CurrentOption=curOpts, MultipleOptions=true,
                Callback=function(selected)
                    if type(selected)=="string" then selected={selected} end
                    if type(selected)~="table" then return end
                    task.spawn(function()
                        unequipSlot(sname); task.wait(0.2)
                        local count = 0
                        for _, lbl in ipairs(selected) do
                            local trimmed = tostring(lbl):gsub("^%s*(.-)%s*$","%1")
                            local sid = idByOpt[trimmed]
                            if sid then equipItem(sname, sid); task.wait(0.12); count=count+1 end
                        end
                        task.wait(0.3)
                        eqLabel:Set(sname..": "..getEquippedStr())
                    end)
                end,
            })
        end
    end
end

-- Minions — grouped by type, individual selection via dropdown
TabEquip:CreateSection(L("sec_minions"))
do
    local invF2=MINIONS_F and MINIONS_F:FindFirstChild("Inventory")
    if invF2 and #invF2:GetChildren() > 0 then
        -- Group by base type name (strip trailing " #123")
        local groups, groupOrder={}, {}
        for _, item in ipairs(invF2:GetChildren()) do
            local nameV=item:FindFirstChild("Name")
            local fullName=(nameV and nameV.Value~="") and nameV.Value or item.Name
            local base=fullName:match("^(.-)%s*#%d+$") or fullName
            if not groups[base] then
                groups[base]={ids={}, displayNames={}, equipped=0}
                groupOrder[#groupOrder+1]=base
            end
            local grp=groups[base]
            grp.ids[#grp.ids+1]=item.Name
            grp.displayNames[item.Name]=fullName
            local eqV=item:FindFirstChild("Equipped")
            if eqV and eqV.Value then grp.equipped=grp.equipped+1 end
        end
        table.sort(groupOrder)

        for _, typeName in ipairs(groupOrder) do
            local grp=groups[typeName]
            local total=#grp.ids
            local tn=typeName
            local grpIds=grp.ids

            -- Build dropdown options — deduplicate names with [id] suffix
            local opts, idByOpt, curOpts, usedNames = {}, {}, {}, {}
            for _, id in ipairs(grpIds) do
                local dname=grp.displayNames[id] or (tn.." #"..id)
                -- Make unique if name collides
                if usedNames[dname] then dname=dname.." ["..id.."]" end
                usedNames[dname]=true
                opts[#opts+1]=dname
                idByOpt[dname]=id
                local itm=invF2:FindFirstChild(id)
                local eqV=itm and itm:FindFirstChild("Equipped")
                if eqV and eqV.Value then curOpts[#curOpts+1]=dname end
            end

            local statLbl=TabEquip:CreateLabel(tn..": "..grp.equipped.."/"..total.." надеты")
            TabEquip:CreateDropdown({
                Name=tn, Options=opts, CurrentOption=curOpts,
                MultipleOptions=true, Flag="min_"..tn:gsub("[^%w]","_"),
                Callback=function(selected)
                    if type(selected)=="string" then selected={selected} end
                    if type(selected)~="table" then return end
                    task.spawn(function()
                        for _, id in ipairs(grpIds) do unequipMinion(id); task.wait(0.08) end
                        task.wait(0.15)
                        local count=0
                        for _, dname in ipairs(selected) do
                            local trimmed=tostring(dname):gsub("^%s*(.-)%s*$","%1")
                            local sid=idByOpt[trimmed]
                            if sid then equipMinion(sid); task.wait(0.1); count=count+1 end
                        end
                        statLbl:Set(tn..": "..count.."/"..total.." надеты")
                    end)
                end,
            })
        end
    else
        TabEquip:CreateLabel("Миньонов в инвентаре нет")
    end
end

TabEquip:CreateSection(L("sec_minionPat"))
for i, letter in ipairs({"A","B","C"}) do
    local idx=i
    TabEquip:CreateButton({Name="Save Minion "..letter, Callback=function()
        minionPatterns[idx]=readMinionEquipped()
        notify("Minion Pattern "..letter, #minionPatterns[idx].." minions saved","save")
    end})
    TabEquip:CreateButton({Name="Apply Minion "..letter, Callback=function()
        local ids=minionPatterns[idx]
        if not ids or #ids==0 then notify(L("notif_error"),L("notif_notSaved"),"alert-circle"); return end
        task.spawn(function()
            unequipAllMinions(); task.wait(0.15)
            for _, id in ipairs(ids) do equipMinion(id); task.wait(0.1) end
            notify("Minion Pattern "..letter, #ids.." minions applied","check")
        end)
    end})
end

TabEquip:CreateSection(L("sec_bestMinion"))
for _, cur in ipairs({"Cash","Coin","Oof","Water","Bread","HackPoints","Rebirth","Wood","Planks","Ice","Ash","Gem"}) do
    local c=cur
    TabEquip:CreateButton({Name="Best "..c, Callback=function()
        fire("EquipBestMinions",c); notify("Best Minions",c.." "..L("notif_bestMinions"),"users")
    end})
end

TabEquip:CreateSection(L("sec_equipPat"))
local function patStr(n)
    if not patterns[n] then return L("notif_notSaved") end
    local inv=readInventory(); local parts={}
    for _, sn in ipairs(SLOTS) do
        local ids=patterns[n][sn]
        if ids and #ids>0 then
            local names={}
            for _, id in ipairs(ids) do names[#names+1]=(inv[sn] and inv[sn][id]) or id end
            parts[#parts+1]=sn..": "..table.concat(names,", ")
        end
    end
    return #parts>0 and table.concat(parts," | ") or "(empty)"
end
for i, letter in ipairs({"A","B","C"}) do
    local idx=i
    TabEquip:CreateButton({Name="Save Pattern "..letter, Callback=function()
        patterns[idx]=readEquipped()
        notify("Pattern "..letter, patStr(idx):sub(1,80),"save")
    end})
    TabEquip:CreateButton({Name="Apply Pattern "..letter, Callback=function()
        if not patterns[idx] then notify(L("notif_error"),L("notif_notSaved"),"alert-circle"); return end
        task.spawn(function() applyPattern(idx) end)
        notify("Pattern "..letter,"Applied","check")
    end})
end

TabEquip:CreateSection(L("sec_prismEquip"))
TabEquip:CreateDropdown({
    Name="Pattern to apply", Options={"A","B","C"}, Flag="prismPat",
    CurrentOption={({"A","B","C"})[prismEquipPat]}, MultipleOptions=false,
    Callback=function(o) local m={A=1,B=2,C=3}; prismEquipPat=m[o[1]] or 1; saveSettings() end,
})
TabEquip:CreateSlider({
    Name=L("lbl_prismTrigger"), Range={1,10}, Increment=1,
    CurrentValue=prismThreshold, Flag="prismThr",
    Callback=function(v) prismThreshold=v; saveSettings() end,
})
TabEquip:CreateToggle({
    Name=L("tog_prismEquip"), CurrentValue=S.prismEquip, Flag="pe_",
    Callback=function(v) S.prismEquip=v; prismArmed=false; saveSettings() end,
})

-- ══ TELEPORT ══════════════════════════════════════════════════════════════════
TabTele:CreateSection(L("sec_capsuleZones"))
TabTele:CreateButton({Name="Classic Zone", Callback=function()
    local p=CAPSULE_PARTS.Classic; local hrp=getHRP()
    if p and hrp then hrp.CFrame=CFrame.new(p.Position+Vector3.new(0,4,0))
    else notify(L("notif_error"),"Classic"..L("notif_notFound"),"alert-circle") end
end})
TabTele:CreateButton({Name="Super Zone", Callback=function()
    local p=CAPSULE_PARTS.Super; local hrp=getHRP()
    if p and hrp then hrp.CFrame=CFrame.new(p.Position+Vector3.new(0,4,0))
    else notify(L("notif_error"),"Super"..L("notif_notFound"),"alert-circle") end
end})

TabTele:CreateSection(L("sec_treeTele"))
local upgradeTreeF = GC:FindFirstChild("UpgradeTree")
for _, entry in ipairs({
    {"Starter Tree","StarterTree"},
    {"Tycoon Tree","TycoonTree"},
    {"Farm Tree","FarmTree"},
    {"Prism Tree","PrismTree"},
    {"Ice Tree","IceTree"},
    {"Mining Tree","MiningTree"},
}) do
    local label, treeName = entry[1], entry[2]
    TabTele:CreateButton({Name=label, Callback=function()
        local hrp=getHRP(); if not hrp then return end
        pcall(function()
            local tree = upgradeTreeF and upgradeTreeF:FindFirstChild(treeName)
            if tree then
                local p=tree:GetPivot()
                hrp.CFrame=CFrame.new(p.X, p.Y+5, p.Z)
            else
                notify(L("notif_error"),label..L("notif_notFound"),"alert-circle")
            end
        end)
    end})
end

TabTele:CreateSection(L("sec_runetele"))
for _, zn in ipairs({"Basic","Super","Advanced","Cosmic Prism","Hacker","Snowy","Deepcore"}) do
    local z=zn
    TabTele:CreateButton({Name=z, Callback=function()
        local hrp=getHRP(); if not hrp then return end
        pcall(function()
            -- Try direct RuneZones folder first
            local zonesF = GC:FindFirstChild("RuneZones")
            local zone = zonesF and zonesF:FindFirstChild(z)
            if zone then
                local p=zone:GetPivot()
                hrp.CFrame=CFrame.new(p.X, p.Y+5, p.Z)
                return
            end
            -- Fallback: search whole workspace for a model named z
            for _, obj in ipairs(workspace:GetDescendants()) do
                if obj.Name==z and (obj:IsA("Model") or obj:IsA("BasePart")) then
                    local pos = obj:IsA("Model") and obj:GetPivot().Position or obj.Position
                    hrp.CFrame=CFrame.new(pos.X, pos.Y+5, pos.Z)
                    return
                end
            end
            notify(L("notif_error"),z..L("notif_notFound"),"alert-circle")
        end)
    end})
end

-- ══ CHANCES ════════════════════════════════════════════════════════════════════
-- Stat display (auto-read from Profile GUI)
TabChances:CreateSection(L("sec_stats"))
local rpsLabel  = TabChances:CreateLabel(L("lbl_rps")..L("lbl_loading"))
local cdLabel   = TabChances:CreateLabel(L("lbl_cd")..L("lbl_loading"))
local luckLabel = TabChances:CreateLabel("Rune Luck: "..L("lbl_loading"))
TabChances:CreateLabel(L("lbl_noobNote"))
TabChances:CreateLabel(L("lbl_prismNote"))

-- Manual luck override (only needed if auto-read fails)
TabChances:CreateInput({
    Name=L("lbl_runeLuck"), PlaceholderText=L("inp_runeLuck"),
    RemoveTextAfterFocusLost=false, Flag="runeLuck",
    Callback=function(txt)
        local v=parseNum(txt)
        if v and v>0 then
            manualRuneLuck=v; saveSettings()
            notify(L("lbl_runeLuck"), "= "..fmtNum(v),"zap")
        end
    end,
})

-- ETA paragraphs per zone
TabChances:CreateSection(L("sec_runeChances"))
local zoneParagraphs={}
for _, zone in ipairs(RUNE_ZONES) do
    zoneParagraphs[zone.name] = TabChances:CreateParagraph({Title=zone.name, Content=L("lbl_loading")})
end

-- Compute and display ETA for all zones
local function updateChances()
    local rps, cd, autoLuck = readProfileStats()
    -- prefer manual override; auto-read from Profile.Stats.RuneLuck.Amount
    local luck = manualRuneLuck or autoLuck

    rpsLabel:Set(L("lbl_rps")..(rps and fmtNum(rps) or "?"))
    cdLabel:Set(L("lbl_cd")..(cd and string.format("%.3fs",cd) or "?"))
    luckLabel:Set("Rune Luck: "..(luck and fmtNum(luck) or "? (enter manually)"))

    for _, zone in ipairs(RUNE_ZONES) do
        local para=zoneParagraphs[zone.name]
        if para then

        local invFolder=nil
        pcall(function() invFolder=LP.FEATURES.RUNES.INVENTORY:FindFirstChild(zone.invKey) end)

        local lines={}
        for _, rune in ipairs(zone.runes) do
            -- Inventory count
            local owned=0
            if invFolder then
                local rv = invFolder:FindFirstChild(rune.n)
                    or (rune.n=="Exploit"       and invFolder:FindFirstChild("Expliot"))
                    or (rune.n=="Ultimate Shard" and invFolder:FindFirstChild("UltimateShard"))
                if rv then
                    local ok,v=pcall(function() return rv.Value end)
                    if ok then owned=tonumber(v) or 0 end
                end
            end

            -- ETA calculation
            local eta="?"
            if rps and rps>0 then
                local power
                if zone.special then
                    power=rps
                elseif rune.cl=="Noobinial" then
                    power=rps
                else
                    if luck and luck>0 then power=rps*luck end
                end
                if power then
                    eta=fmtTime(rune.c/power)
                else
                    eta="нужна удача"
                end
            end

            local ownedStr=owned>0 and " ["..owned.."]" or ""
            local tag=rune.cl=="Noobinial" and "★" or " "
            lines[#lines+1]=tag..rune.n..ownedStr.." → "..eta
        end
        para:Set({Title=zone.name, Content=table.concat(lines,"\n")})
        end
    end
end

TabChances:CreateButton({Name=L("btn_calcEta"), Callback=function() updateChances() end})

-- Auto-calculate on load
task.delay(3, function() updateChances() end)
