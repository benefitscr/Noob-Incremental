-- CURRENCY VALUE WRITE EXPLOIT  @Benefit
-- ALL LP.CURRENCIES values are WRITABLE from client executor
-- Testing if server uses these values for validation
local RS  = game:GetService("ReplicatedStorage")
local LP  = game:GetService("Players").LocalPlayer
local MR  = RS.__Net.MainRemote
local NET = RS.__Net

local function fire(...) pcall(MR.FireServer, MR, ...) end

local function writeVal(path, value)
    local obj = LP.CURRENCIES
    local parts = path:split(".")
    for i = 1, #parts - 1 do
        obj = obj:FindFirstChild(parts[i])
        if not obj then return false, "not found: " .. parts[i] end
    end
    local leaf = obj:FindFirstChild(parts[#parts])
    if not leaf then return false, "leaf not found" end
    local ok, err = pcall(function() leaf.Value = value end)
    return ok, err
end

local function readVal(path)
    local obj = LP.CURRENCIES
    for _, part in ipairs(path:split(".")) do
        obj = obj:FindFirstChild(part)
        if not obj then return nil end
    end
    local ok, v = pcall(function() return obj.Value end)
    return ok and v or nil
end

-- ══════════════════════════════════════════════════════════════════
-- [1] MINION SLOTS — пишем 10, пробуем экипировать 5-й
-- ══════════════════════════════════════════════════════════════════
print("══════ MINION SLOTS OVERFLOW ══════")
print("Before NaturalMultiplier: " .. tostring(readVal("MinionSlots.NaturalMultiplier")))
print("Before TotalMultiplier:   " .. tostring(readVal("MinionSlots.TotalMultiplier")))
print("Before slots:             " .. #LP.FEATURES.LAB.MINIONS.Equipped:GetChildren())

writeVal("MinionSlots.NaturalMultiplier", 10)
writeVal("MinionSlots.TotalMultiplier",   10)
writeVal("MinionSlots.1",               10)
writeVal("MinionSlots.2",               10)

print("After write - NaturalMultiplier: " .. tostring(readVal("MinionSlots.NaturalMultiplier")))
task.wait(0.3)

-- Пробуем экипировать все наши миньоны
local ALL_IDS = {"1","2","3","4","119209","114721","114769","114799","78652","58578","81280","150028","150031"}
for _, id in ipairs(ALL_IDS) do
    task.spawn(function() fire("EquipMinion", id) end)
end
task.wait(1)
print("Slots after equip attempt: " .. #LP.FEATURES.LAB.MINIONS.Equipped:GetChildren())

-- ══════════════════════════════════════════════════════════════════
-- [2] CAPSULE OPEN COUNT — пишем 60, открываем 1 капсулу
-- ══════════════════════════════════════════════════════════════════
print("\n══════ CAPSULE OPEN AMOUNT ══════")
print("Before MinionCapsuleOpen NaturalMul: " .. tostring(readVal("MinionCapsuleOpen.NaturalMultiplier")))
print("Before MinionCapsuleOpen TotalMul:   " .. tostring(readVal("MinionCapsuleOpen.TotalMultiplier")))

writeVal("MinionCapsuleOpen.NaturalMultiplier", 60)
writeVal("MinionCapsuleOpen.TotalMultiplier",   60)
writeVal("MinionCapsuleOpen.1", 60)
writeVal("MinionCapsuleOpen.2", 60)

local minionCount = 0
local conn = NET.MinionCapsuleOpened.OnClientEvent:Connect(function(capType, minions, luck, count)
    minionCount = minionCount + (count or #minions or 0)
    print("[★] capsule opened: count=" .. tostring(count) .. " minions=" .. tostring(#minions))
    for _, m in ipairs(minions or {}) do
        print("  → " .. tostring(m.name) .. " (" .. tostring(m.rarity) .. ")")
    end
end)

fire("OpenCapsule", "Super", 1)
task.wait(3)
conn:Disconnect()
print("Total minions received: " .. minionCount)

-- ══════════════════════════════════════════════════════════════════
-- [3] CAPSULE LUCK — math.huge
-- ══════════════════════════════════════════════════════════════════
print("\n══════ CAPSULE LUCK → math.huge ══════")
writeVal("MinionCapsuleLuck.NaturalMultiplier", math.huge)
writeVal("MinionCapsuleLuck.TotalMultiplier",   math.huge)
writeVal("MinionCapsuleLuck.1", math.huge)
writeVal("MinionCapsuleLuck.2", math.huge)

print("MinionCapsuleLuck after: " .. tostring(readVal("MinionCapsuleLuck.TotalMultiplier")))

local conn2 = NET.MinionCapsuleOpened.OnClientEvent:Connect(function(capType, minions, luck, count)
    print("[LUCK TEST] luck=" .. tostring(luck) .. " count=" .. tostring(count))
    for _, m in ipairs(minions or {}) do
        print("  → " .. tostring(m.name) .. " (" .. tostring(m.rarity) .. ")" .. (m.autoDeleted and " [DELETED]" or ""))
    end
end)
task.wait(2)
fire("OpenCapsule", "Super", 1)
task.wait(3)
conn2:Disconnect()

-- ══════════════════════════════════════════════════════════════════
-- [4] TIERLUCK И TIERBULK — лучшие тиры из тайкуна
-- ══════════════════════════════════════════════════════════════════
print("\n══════ TIER LUCK / BULK → HUGE ══════")
local TIER_BEFORE = readVal("TierLuck.TotalMultiplier")
local BULK_BEFORE = readVal("TierBulk.TotalMultiplier")
print("TierLuck before: " .. tostring(TIER_BEFORE))
print("TierBulk before: " .. tostring(BULK_BEFORE))

writeVal("TierLuck.NaturalMultiplier", math.huge)
writeVal("TierLuck.TotalMultiplier",   math.huge)
writeVal("TierBulk.NaturalMultiplier", math.huge)
writeVal("TierBulk.TotalMultiplier",   math.huge)

print("TierLuck after: " .. tostring(readVal("TierLuck.TotalMultiplier")))
print("TierBulk after: " .. tostring(readVal("TierBulk.TotalMultiplier")))
print("(roll some tiers now and check if they got better)")

-- ══════════════════════════════════════════════════════════════════
-- [5] WALKSPEED — прямо в персонажа
-- ══════════════════════════════════════════════════════════════════
print("\n══════ WALKSPEED CURRENCY ══════")
local char = LP.Character
local hum  = char and char:FindFirstChild("Humanoid")
print("Humanoid WalkSpeed before: " .. (hum and hum.WalkSpeed or "N/A"))

writeVal("WalkSpeed.TotalMultiplier",   9999)
writeVal("WalkSpeed.NaturalMultiplier", 9999)
writeVal("WalkSpeed.1", 9999)
writeVal("WalkSpeed.2", 9999)
task.wait(0.5)
print("Humanoid WalkSpeed after: " .. (hum and hum.WalkSpeed or "N/A"))
print("WalkSpeed.TotalMultiplier now: " .. tostring(readVal("WalkSpeed.TotalMultiplier")))

-- ══════════════════════════════════════════════════════════════════
-- [6] RUNE SPEED — ускоряем роллинг рун
-- ══════════════════════════════════════════════════════════════════
print("\n══════ RUNE SPEED ══════")
print("Before RuneSpeed TotalMul: " .. tostring(readVal("RuneSpeed.TotalMultiplier")))
writeVal("RuneSpeed.TotalMultiplier",   math.huge)
writeVal("RuneSpeed.NaturalMultiplier", math.huge)
print("After RuneSpeed TotalMul: " .. tostring(readVal("RuneSpeed.TotalMultiplier")))

print("\n=== DONE ===")
print("Проверь: Tycoon тиры улучшились? Кол-во миньонов за капсулу изменилось?")
print("Humanoid WalkSpeed финал: " .. (hum and hum.WalkSpeed or "N/A"))
