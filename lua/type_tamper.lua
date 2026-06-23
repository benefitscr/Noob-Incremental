-- ═══════════════════════════════════════════════════════════════════
--  TYPE TAMPER + REPLAY ATTACK  @Benefit
--  Вектор: не count (сервер валидирует), а TYPE подмена
--  + TycoonDropSell replay (продать дроп дважды)
-- ═══════════════════════════════════════════════════════════════════

local RS  = game:GetService("ReplicatedStorage")
local LP  = game:GetService("Players").LocalPlayer
local MR  = RS.__Net.MainRemote
local NET = RS.__Net

local function fire(...) pcall(MR.FireServer, MR, ...) end
local function stat()
    local ok, v = pcall(function() return LP.leaderstats.Oof.Value end)
    return ok and tostring(v) or "?"
end

-- ══════════════════════════════════════════════════════════════════
-- [A] REPLAY ATTACK — TycoonDropSell
--     Если сервер не помечает дроп как продан мгновенно →
--     можно продать один и тот же ID несколько раз подряд
--     (race condition window обычно ~50-100ms)
-- ══════════════════════════════════════════════════════════════════
print("[REPLAY] Capturing TycoonDropSell IDs...")

local capturedDropIds = {}
local hooked = false
pcall(function()
    local mt   = getrawmetatable(MR)
    local orig = mt.__namecall
    setreadonly(mt, false)
    mt.__namecall = function(self, ...)
        local args = {...}
        if getnamecallmethod() == "FireServer" and args[1] == "TycoonDropSell" then
            local id = tostring(args[2])
            if not capturedDropIds[id] then
                capturedDropIds[id] = true
                table.insert(capturedDropIds, id)
                print("[REPLAY] Captured drop ID:", id)
                -- Немедленно replay x10 параллельно
                for _=1,10 do
                    task.spawn(function()
                        fire("TycoonDropSell", id)
                    end)
                end
                print("[REPLAY] Fired x10 for:", id)
            end
        end
        return orig(self, ...)
    end
    setreadonly(mt, true)
    hooked = true
end)

if hooked then
    print("[REPLAY] Hook active — каждый TycoonDropSell будет replay x10")
else
    print("[REPLAY] Hook failed")
end

-- ══════════════════════════════════════════════════════════════════
-- [B] CAPSULE TYPE SUBSTITUTION
--     Открываем тип капсулы лучше чем есть
--     Сервер может проверять только "есть ли хоть одна капсула"
--     но не конкретный тип
-- ══════════════════════════════════════════════════════════════════
print("\n[CAPSULE] Testing type substitution...")

local CAPSULE_TYPES = {
    "Classic","Super","Advanced","Premium",
    "Hacker","Snowy","Prism","Legendary",
    "Cosmic","Noobinial","Deepcore","Ultimate",
}

local before = stat()
for _, t in ipairs(CAPSULE_TYPES) do
    fire("OpenCapsule", t, 1)
    task.wait(0.15)
end
task.wait(0.5)
local after = stat()
print("[CAPSULE] Before:", before, "After:", after)
if before ~= after then
    print("[CAPSULE] ★ STAT CHANGED — type sub may work!")
end

-- ══════════════════════════════════════════════════════════════════
-- [C] POTION NAME SPOOF
--     BuyPotionTickets с именем зелья которого у нас нет
--     Если сервер ищет зелье по имени и не проверяет инвентарь
-- ══════════════════════════════════════════════════════════════════
print("\n[POTION] Testing name spoof...")

local BETTER_POTIONS = {
    "10x Rune Luck", "100x Rune Luck",
    "10x Rune Speed", "100x Rune Speed",
    "10x Rune Bulk",  "100x Rune Bulk",
    "2x Rune Luck",   "5x Rune Luck",
    "Infinite Luck",  "Max Luck",
    "God Potion",     "Debug Potion",
}

before = stat()
for _, p in ipairs(BETTER_POTIONS) do
    fire("BuyPotionTickets", p, "x1")
    fire("UsePotion",        p, 1)
    task.wait(0.1)
end
task.wait(0.5)
after = stat()
print("[POTION] Before:", before, "After:", after)

-- ══════════════════════════════════════════════════════════════════
-- [D] POTION TICKET → FREE (цена = 0 или отрицательная)
--     BuyPotionTickets("2x Rune Bulk", "x1")
--     Пробуем: x0 (бесплатно), x-1 (возврат денег)
-- ══════════════════════════════════════════════════════════════════
print("\n[POTION] Testing free/negative purchase...")

before = stat()
local realPotions = {"2x Rune Luck","2x Rune Speed","2x Rune Bulk"}
for _, p in ipairs(realPotions) do
    fire("BuyPotionTickets", p, "x0")    -- бесплатно?
    fire("BuyPotionTickets", p, "x-1")   -- возврат?
    fire("BuyPotionTickets", p, -1)      -- отрицательный int
    task.wait(0.15)
end
task.wait(0.5)
after = stat()
print("[POTION FREE] Before:", before, "After:", after)

-- ══════════════════════════════════════════════════════════════════
-- [E] AURA EQUIP SPOOF
--     EquipAura "Eternal" — игра уже шлёт это
--     Пробуем экипировать ауры которых нет
-- ══════════════════════════════════════════════════════════════════
print("\n[AURA] Testing non-owned aura equip...")

local AURAS = {
    "Eternal","Divine","God","Ultimate","Prismatic",
    "Void","Cosmic","Legendary","Secret","Admin",
    "Developer","Debug","Rainbow","Infinite",
}
before = stat()
for _, a in ipairs(AURAS) do
    fire("EquipAura", a)
    task.wait(0.05)
end
task.wait(0.5)
after = stat()
print("[AURA] Before:", before, "After:", after)
-- Проверяем что реально экипировано
pcall(function()
    local equipped = LP.FEATURES.AURAS.Equipped.Value
    print("[AURA] Currently equipped:", tostring(equipped))
end)

print("\n=== TYPE_TAMPER DONE ===")
print("TycoonDropSell hook still active — каждый новый дроп = replay x10")
