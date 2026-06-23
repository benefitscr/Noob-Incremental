-- UPGRADE TREE WRITE EXPLOIT  @Benefit
-- LP.UI_UPGRADE_TREE и LP.LAB_UI_UPGRADE_TREE могут быть writeable
-- Если сервер читает из LP.X вместо DataStore — критический эксплоит
local RS  = game:GetService("ReplicatedStorage")
local LP  = game:GetService("Players").LocalPlayer
local MR  = RS.__Net.MainRemote
local NET = RS.__Net

local function fire(...) pcall(MR.FireServer, MR, ...) end

-- ══════════════════════════════════════════════════════════════════
-- [1] Проверяем writeable ли LP.LAB_UI_UPGRADE_TREE
-- ══════════════════════════════════════════════════════════════════
print("══════ LAB UI TREE WRITEABILITY ══════")
local labTree = LP:FindFirstChild("LAB_UI_UPGRADE_TREE")
local uiTree  = LP:FindFirstChild("UI_UPGRADE_TREE")

local function tryWrite(folder, name, val)
    if not folder then return false end
    local ch = folder:FindFirstChild(name)
    if not ch then return false end
    local before = nil
    pcall(function() before = ch.Value end)
    local ok = pcall(function() ch.Value = val end)
    local after = nil
    pcall(function() after = ch.Value end)
    if ok and after == val then
        print("[WRITABLE] " .. folder.Name .. "." .. name .. ": " .. tostring(before) .. " → " .. tostring(after))
        return true
    end
    return false
end

-- Проверяем несколько ключевых значений
local testNodes = {
    "CapsuleLuck_Main","CapsuleLuck_Branch","CapsuleBulk_Main","CapsuleBulk_Branch",
    "MinionStorageIncrease_Main","MinionEquip_Branch","BetterMinions_Branch",
    "TierBulkMul","TierBulkMul1","TierBulkMul2","TierLuckMul1","TierLuckMul2",
    "OofMulti1","OofMulti2","RuneLuckMultiCenter","RuneBulkMultiCenter",
}

for _, name in ipairs(testNodes) do
    tryWrite(labTree, name, 9999)
    tryWrite(uiTree, name, 9999)
end

-- ══════════════════════════════════════════════════════════════════
-- [2] BASELINE и MODIFIED capsule (если tree writable)
-- ══════════════════════════════════════════════════════════════════
print("\n══════ CAPSULE LUCK TREE TEST ══════")
-- Записываем CapsuleLuck
if labTree then
    local cl = labTree:FindFirstChild("CapsuleLuck_Main")
    local cb = labTree:FindFirstChild("CapsuleBulk_Main")
    if cl then pcall(function() cl.Value = 9999 end) end
    if cb then pcall(function() cb.Value = 9999 end) end
    print("CapsuleLuck_Main written: " .. tostring(cl and cl.Value))
    print("CapsuleBulk_Main written: " .. tostring(cb and cb.Value))
end

task.wait(2.5)  -- ждём кулдаун

local conn = NET.MinionCapsuleOpened.OnClientEvent:Connect(function(ct, minions, luck, count, totalLuck)
    print("[TREE TEST] count=" .. tostring(count) .. " luck=" .. tostring(luck) .. " totalLuck=" .. tostring(totalLuck))
    for _, m in ipairs(minions or {}) do
        print("  [" .. tostring(m.rarity) .. "] " .. tostring(m.name))
    end
end)
fire("OpenCapsule", "Super", 1)
task.wait(3)
conn:Disconnect()

-- ══════════════════════════════════════════════════════════════════
-- [3] GUILD WEEKLY CLAIM MANIPULATION
-- ══════════════════════════════════════════════════════════════════
print("\n══════ GUILD CLAIM TEST ══════")
-- EXTRA folder в LP
local extra = LP:FindFirstChild("EXTRA")
if extra then
    print("EXTRA children:")
    for _, ch in ipairs(extra:GetChildren()) do
        local ok, v = pcall(function() return ch.Value end)
        print("  " .. ch.Name .. " [" .. ch.ClassName .. "] = " .. (ok and tostring(v) or "?"))
        -- Пробуем записать has_claimable = true
        if ch.Name == "GUILD_WEEKLY_HAS_CLAIMABLE" then
            pcall(function() ch.Value = true end)
            local ok2, v2 = pcall(function() return ch.Value end)
            print("  → After write: " .. tostring(v2))
        end
    end
end

-- Пробуем клеймить гильдийные награды
local GUILD_ACTIONS = {
    "ClaimGuildReward","GuildWeeklyClaim","ClaimWeeklyGuild",
    "CollectGuildReward","GuildClaim","WeeklyClaim",
}
for _, action in ipairs(GUILD_ACTIONS) do
    fire(action)
    fire(action, true)
    task.wait(0.1)
end

-- ══════════════════════════════════════════════════════════════════
-- [4] SUPPORTER TIER SPOOF
-- ══════════════════════════════════════════════════════════════════
print("\n══════ SUPPORTER TIER ══════")
if extra then
    local tier = extra:FindFirstChild("SupporterTierLevel")
    if tier then
        local before = tier.Value
        pcall(function() tier.Value = 5 end)
        print("SupporterTierLevel: " .. tostring(before) .. " → " .. tostring(tier.Value))
    end
end

-- ══════════════════════════════════════════════════════════════════
-- [5] SIMPLE_VALUES прямая запись
--     TotalCapsuleOpened, TierOpened — вдруг влияют на pity
-- ══════════════════════════════════════════════════════════════════
print("\n══════ SIMPLE_VALUES WRITE ══════")
local sv = LP:FindFirstChild("SIMPLE_VALUES")
if sv then
    for _, ch in ipairs(sv:GetChildren()) do
        local ok, v = pcall(function() return ch.Value end)
        if ok and type(v) == "number" then
            local okW = pcall(function() ch.Value = v end)
            if okW then
                print("[WRITE OK] " .. ch.Name .. " = " .. tostring(v))
            end
        end
    end
end

print("\n=== DONE ===")
