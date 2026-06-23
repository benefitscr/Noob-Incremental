-- CAPSULE SPEED + CONTROLLED TEST  @Benefit
-- Чистый тест: открываем капсулу ДО изменений (baseline),
-- потом пишем значения и открываем снова - сравниваем
local RS  = game:GetService("ReplicatedStorage")
local LP  = game:GetService("Players").LocalPlayer
local MR  = RS.__Net.MainRemote
local NET = RS.__Net

local function fire(...) pcall(MR.FireServer, MR, ...) end
local function w(path, v)
    local obj = LP.CURRENCIES
    for _, p in ipairs(path:split(".")) do
        obj = obj and obj:FindFirstChild(p)
    end
    if obj then pcall(function() obj.Value = v end) end
end
local function r(path)
    local obj = LP.CURRENCIES
    for _, p in ipairs(path:split(".")) do
        obj = obj and obj:FindFirstChild(p)
    end
    local ok, v = pcall(function() return obj.Value end)
    return ok and v or nil
end

-- ══════════════════════════════════════════════════════════════════
-- BASELINE: открываем капсулу до изменений
-- ══════════════════════════════════════════════════════════════════
print("══════ BASELINE CAPSULE OPEN ══════")
print("MinionCapsuleOpen.TotalMultiplier = " .. tostring(r("MinionCapsuleOpen.TotalMultiplier")))
print("MinionCapsuleLuck.TotalMultiplier = " .. tostring(r("MinionCapsuleLuck.TotalMultiplier")))
print("MinionCapsuleSpeed.TotalMultiplier= " .. tostring(r("MinionCapsuleSpeed.TotalMultiplier")))

local baseMinions = {}
local conn1 = NET.MinionCapsuleOpened.OnClientEvent:Connect(function(ct, minions, luck, count, totalLuck)
    print("[BASELINE] capType=" .. tostring(ct) .. " count=" .. tostring(count)
        .. " luck=" .. tostring(luck) .. " totalLuck=" .. tostring(totalLuck))
    for _, m in ipairs(minions or {}) do
        table.insert(baseMinions, m)
        print("  [" .. tostring(m.rarity) .. "] " .. tostring(m.name))
    end
end)
fire("OpenCapsule", "Super", 1)
task.wait(3)
conn1:Disconnect()
print("Baseline: got " .. #baseMinions .. " minions")

-- ══════════════════════════════════════════════════════════════════
-- ПИШЕМ: x10 открытий, luck=inf, speed=0
-- ══════════════════════════════════════════════════════════════════
print("\n══════ WRITING VALUES ══════")
w("MinionCapsuleOpen.NaturalMultiplier", 60)
w("MinionCapsuleOpen.TotalMultiplier",   60)
w("MinionCapsuleLuck.NaturalMultiplier", math.huge)
w("MinionCapsuleLuck.TotalMultiplier",   math.huge)
w("MinionCapsuleSpeed.NaturalMultiplier", 0.001)
w("MinionCapsuleSpeed.TotalMultiplier",   0.001)

print("MinionCapsuleOpen  → " .. tostring(r("MinionCapsuleOpen.TotalMultiplier")))
print("MinionCapsuleLuck  → " .. tostring(r("MinionCapsuleLuck.TotalMultiplier")))
print("MinionCapsuleSpeed → " .. tostring(r("MinionCapsuleSpeed.TotalMultiplier")))

-- ══════════════════════════════════════════════════════════════════
-- ТЕСТ: открываем снова через ~2.5s (ждём кулдаун)
-- ══════════════════════════════════════════════════════════════════
print("\nWaiting 2.5s for cooldown...")
task.wait(2.5)

local testMinions = {}
local conn2 = NET.MinionCapsuleOpened.OnClientEvent:Connect(function(ct, minions, luck, count, totalLuck)
    print("[MODIFIED] capType=" .. tostring(ct) .. " count=" .. tostring(count)
        .. " luck=" .. tostring(luck) .. " totalLuck=" .. tostring(totalLuck))
    for _, m in ipairs(minions or {}) do
        table.insert(testMinions, m)
        print("  [" .. tostring(m.rarity) .. "] " .. tostring(m.name))
    end
end)
fire("OpenCapsule", "Super", 1)
task.wait(3)
conn2:Disconnect()
print("Modified: got " .. #testMinions .. " minions")

-- ══════════════════════════════════════════════════════════════════
-- СРАВНЕНИЕ
-- ══════════════════════════════════════════════════════════════════
print("\n══════ COMPARISON ══════")
print("Baseline minions: " .. #baseMinions)
print("Modified minions: " .. #testMinions)
if #testMinions > #baseMinions then
    print("[★★★] MORE MINIONS! Exploit confirmed!")
elseif #testMinions == #baseMinions and #testMinions > 0 then
    print("[—] Same count. Check rarities...")
    -- Сравниваем редкости
    local baseRarities, testRarities = {}, {}
    for _, m in ipairs(baseMinions) do baseRarities[m.rarity] = (baseRarities[m.rarity] or 0) + 1 end
    for _, m in ipairs(testMinions) do testRarities[m.rarity] = (testRarities[m.rarity] or 0) + 1 end
    for r2, c in pairs(testRarities) do
        print("  " .. r2 .. ": " .. c .. " (base: " .. (baseRarities[r2] or 0) .. ")")
    end
else
    print("[✗] Server ignores client currency values")
end

-- ══════════════════════════════════════════════════════════════════
-- BONUS: GetPlayerData dump
-- ══════════════════════════════════════════════════════════════════
print("\n══════ GetPlayerData DUMP ══════")
local ok, data = pcall(function() return NET.GetPlayerData:InvokeServer() end)
if ok and type(data) == "table" then
    print("Keys returned:")
    for k, v in pairs(data) do
        print("  " .. tostring(k) .. " [" .. type(v) .. "]")
        if type(v) == "table" and k ~= "Data" then
            for k2, v2 in pairs(v) do
                if type(v2) ~= "table" then
                    print("    " .. tostring(k2) .. " = " .. tostring(v2))
                end
            end
        end
    end
end

print("\n=== DONE ===")
