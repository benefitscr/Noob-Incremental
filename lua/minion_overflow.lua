-- MINION SLOT OVERFLOW + AUTOOPEN  @Benefit
local RS  = game:GetService("ReplicatedStorage")
local LP  = game:GetService("Players").LocalPlayer
local MR  = RS.__Net.MainRemote
local NET = RS.__Net

local function fire(...) pcall(MR.FireServer, MR, ...) end

-- ══════════════════════════════════════════════════════════════════
-- [1] Находим формат EquipMinion через hook 30s
--     Открой инвентарь миньонов и экипируй/снимай любого
-- ══════════════════════════════════════════════════════════════════
print("══════ MINION EVENT HOOK (15s) ══════")
print("Сейчас открой инвентарь миньонов и кликни экипировать/снять!")

local orig = getrawmetatable(game)
local old_nc = orig.__namecall
setreadonly(orig, false)
orig.__namecall = newcclosure(function(self, ...)
    local method = getnamecallmethod()
    if method == "FireServer" or method == "InvokeServer" then
        local args = {...}
        local name = tostring(self.Name)
        local arg1 = tostring(args[1] or "")
        -- Ловим всё связанное с minion/equip
        if arg1:lower():find("minion") or arg1:lower():find("equip")
        or arg1:lower():find("lock") or arg1:lower():find("unequip")
        or arg1:lower():find("auto") or arg1:lower():find("open")
        or name:lower():find("minion") then
            print("[HOOK] " .. name .. " → " .. arg1 .. " [" .. method .. "]")
            for i = 2, #args do
                print("  arg" .. i .. " [" .. type(args[i]) .. "] = " .. tostring(args[i]):sub(1,100))
            end
        end
    end
    return old_nc(self, ...)
end)
setreadonly(orig, true)

task.wait(15)

-- Восстанавливаем
local orig2 = getrawmetatable(game)
setreadonly(orig2, false)
orig2.__namecall = old_nc
setreadonly(orig2, true)

-- ══════════════════════════════════════════════════════════════════
-- [2] Тест equip overflow — 5+ миньонов одновременно
--     Наши миньоны: ID 1=E-A, 2=E-B, 3=E-C, 4=E-D + 119209=2-G
--     Сейчас equipped: 114721, 114769, 114799 (2-F), 119209 (2-G)
-- ══════════════════════════════════════════════════════════════════
print("\n══════ EQUIP OVERFLOW TEST ══════")

-- Сначала смотрим сколько сейчас экипировано
local equippedBefore = {}
for _, ch in ipairs(LP.FEATURES.LAB.MINIONS.Equipped:GetChildren()) do
    equippedBefore[ch.Name] = true
end
print("Equipped slots BEFORE: " .. #LP.FEATURES.LAB.MINIONS.Equipped:GetChildren())

-- ID наших миньонов (из inventory scan)
local OUR_MINIONS = {
    {id = 1,      name = "E-A"},
    {id = 2,      name = "E-B"},
    {id = 3,      name = "E-C"},
    {id = 4,      name = "E-D"},
    {id = 119209, name = "2-G"},  -- уже экипирован
    {id = 114721, name = "2-F"},  -- уже экипирован
    {id = 114769, name = "2-F"},  -- уже экипирован
    {id = 114799, name = "2-F"},  -- уже экипирован
    {id = 78652,  name = "G"},
    {id = 58578,  name = "G"},
}

-- Пробуем EquipMinion в разных форматах
local EQUIP_ACTIONS = {"EquipMinion","Equip","MinionEquip","EquipMinionSlot"}

for _, action in ipairs(EQUIP_ACTIONS) do
    for _, m in ipairs(OUR_MINIONS) do
        fire(action, m.id)
        fire(action, m.id, true)
        fire(action, tostring(m.id))
    end
    task.wait(0.1)
end

task.wait(1)
local equippedAfter = #LP.FEATURES.LAB.MINIONS.Equipped:GetChildren()
print("Equipped slots AFTER: " .. equippedAfter)
if equippedAfter > #equippedBefore then
    print("[★] More minions equipped than before!")
end

-- ══════════════════════════════════════════════════════════════════
-- [3] AutoOpenZone — ставим зону для авто-открытия
-- ══════════════════════════════════════════════════════════════════
print("\n══════ AUTOOPEN ZONE TEST ══════")

-- Пробуем выставить AutoOpenZone
local ZONES = {"Super", "Classic", "Prism", "Cosmic", "Hacker", "Deepcore"}
local AUTO_ACTIONS = {
    "SetAutoOpenZone", "AutoOpen", "SetCapsuleAutoOpen",
    "ToggleAutoOpen", "SetAutoOpenCapsule",
}

for _, action in ipairs(AUTO_ACTIONS) do
    for _, zone in ipairs(ZONES) do
        fire(action, zone)
        fire(action, zone, true)
        task.wait(0.05)
    end
end

-- Через ApplySettingValue
for _, zone in ipairs(ZONES) do
    fire("ApplySettingValue", "AutoOpenZone", zone)
    fire("ApplySettingValue", "AutoOpen", zone)
end

task.wait(1)
local autoZone = LP.FEATURES.LAB.MINIONS.AutoOpenZone
if autoZone then
    local ok, v = pcall(function() return autoZone.Value end)
    print("AutoOpenZone after: " .. (ok and tostring(v) or "[" .. autoZone.ClassName .. "]"))
end

-- ══════════════════════════════════════════════════════════════════
-- [4] LockMinion / UnlockMinion — попробуем заблокировать чужой ID
-- ══════════════════════════════════════════════════════════════════
print("\n══════ LOCK/UNLOCK MINION ══════")

-- Чужие миньоны из renesansleet:
-- E-A=1, E-B=2, E-C=3, E-D=4 (у них тоже ID 1-4!)
-- Но у нас тоже ID 1-4 есть... сервер должен различать по PlayerData

local LOCK_ACTIONS = {"LockMinion","UnlockMinion","ToggleLock","SetLock"}
-- Пробуем заблокировать наши E-tier (они уже unlocked)
for _, action in ipairs(LOCK_ACTIONS) do
    fire(action, 1, true)   -- lock E-A
    fire(action, 119209, false) -- unlock 2-G
    task.wait(0.05)
end

task.wait(1)
-- Проверяем изменился ли Locked у ID=1 (E-A)
local ea = LP.FEATURES.LAB.MINIONS.Inventory:FindFirstChild("1")
if ea then
    local locked = ea:FindFirstChild("Locked")
    if locked then
        print("E-A (ID=1) Locked: " .. tostring(locked.Value))
    end
end

print("\n=== DONE ===")
