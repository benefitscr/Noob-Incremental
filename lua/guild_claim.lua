-- GUILD CLAIM + POTION EXPLOIT  @Benefit
-- 1. Дамп GetMyGuildWeeklyRewards таблицы
-- 2. ClaimGuildWeeklyReward с конкретными ID (13-33)
-- 3. Запись Potion TimeLeft/Capacity (числа!)
-- 4. GAMEPASS_RBX write test
-- 5. GetMyGuildView дамп
local RS  = game:GetService("ReplicatedStorage")
local LP  = game:GetService("Players").LocalPlayer
local MR  = RS.__Net.MainRemote
local NET = RS.__Net

local function fire(...) pcall(MR.FireServer, MR, ...) end

local function deepPrint(t, prefix, depth)
    depth = depth or 0
    if depth > 4 then return end
    prefix = prefix or ""
    if type(t) ~= "table" then print(prefix .. tostring(t)); return end
    for k, v in pairs(t) do
        if type(v) == "table" then
            print(prefix .. tostring(k) .. ":")
            deepPrint(v, prefix .. "  ", depth + 1)
        else
            print(prefix .. tostring(k) .. " = " .. tostring(v))
        end
    end
end

-- ══════════════════════════════════════════════════════════════════
-- [1] GetMyGuildWeeklyRewards — полный дамп
-- ══════════════════════════════════════════════════════════════════
print("══════ GetMyGuildWeeklyRewards ══════")
local ok, rewards = pcall(function() return NET.GetMyGuildWeeklyRewards:InvokeServer() end)
if ok and type(rewards) == "table" then
    deepPrint(rewards)
else
    print("Error: " .. tostring(rewards))
end

-- ══════════════════════════════════════════════════════════════════
-- [2] GetMyGuildView — полный дамп
-- ══════════════════════════════════════════════════════════════════
print("\n══════ GetMyGuildView ══════")
local ok2, guildView = pcall(function() return NET.GetMyGuildView:InvokeServer() end)
if ok2 and type(guildView) == "table" then
    deepPrint(guildView)
end

-- ══════════════════════════════════════════════════════════════════
-- [3] ClaimGuildWeeklyReward с конкретными ID
--     Тест: все unclaimed (13-33) + варианты аргументов
-- ══════════════════════════════════════════════════════════════════
print("\n══════ ClaimGuildWeeklyReward ID SCAN ══════")
-- Текущий weekId = 2946
local WEEKID = "2946"

for id = 1, 33 do
    local ok3, r3 = pcall(function()
        return NET.ClaimGuildWeeklyReward:InvokeServer(id)
    end)
    if not (tostring(r3):find("Invalid") or tostring(r3):find("already") or tostring(r3):find("claimable")) then
        print("[★] ID=" .. id .. " → " .. tostring(r3))
    else
        print("  ID=" .. id .. " → " .. tostring(r3):sub(1,50))
    end
    task.wait(0.05)
end

-- Попробуем с weekId
print("\n-- With weekId=" .. WEEKID)
for id = 13, 20 do
    local ok4, r4 = pcall(function()
        return NET.ClaimGuildWeeklyReward:InvokeServer(id, WEEKID)
    end)
    print("  ID=" .. id .. ",week=" .. WEEKID .. " → " .. tostring(r4):sub(1,60))
    task.wait(0.05)
end

-- ClaimAll снова после паузы
local ok5, r5 = pcall(function()
    return NET.ClaimAllGuildWeeklyRewards:InvokeServer()
end)
print("\nClaimAll → " .. tostring(r5))

-- ══════════════════════════════════════════════════════════════════
-- [4] POTION TimeLeft / Capacity WRITE
--     Если числа writable и сервер читает → бесконечные потионы
-- ══════════════════════════════════════════════════════════════════
print("\n══════ POTION WRITE ══════")
local potions = LP.EXTRA:FindFirstChild("MONETIZATION")
                and LP.EXTRA.MONETIZATION:FindFirstChild("POTIONS")
if potions then
    for _, potion in ipairs(potions:GetChildren()) do
        print("[POTION] " .. potion.Name)
        local tl  = potion:FindFirstChild("TimeLeft")
        local cap = potion:FindFirstChild("Capacity")
        local pa  = potion:FindFirstChild("Paused")

        if tl then
            local before = tl.Value
            pcall(function() tl.Value = 9999999 end)
            print("  TimeLeft: " .. before .. " → " .. tostring(tl.Value))
        end
        if cap then
            local before = cap.Value
            pcall(function() cap.Value = 9999999 end)
            print("  Capacity: " .. before .. " → " .. tostring(cap.Value))
        end
        if pa then
            local before = pa.Value
            pcall(function() pa.Value = false end)
            print("  Paused: " .. tostring(before) .. " → " .. tostring(pa.Value))
        end
    end
end

-- Подождём и проверим не сбросил ли сервер
task.wait(3)
print("\n-- Potion values AFTER 3s (server reset?) --")
if potions then
    for _, potion in ipairs(potions:GetChildren()) do
        local tl  = potion:FindFirstChild("TimeLeft")
        local cap = potion:FindFirstChild("Capacity")
        if tl then print("[" .. potion.Name .. "] TimeLeft=" .. tostring(tl.Value)) end
        if cap then print("[" .. potion.Name .. "] Capacity=" .. tostring(cap.Value)) end
    end
end

-- ══════════════════════════════════════════════════════════════════
-- [5] GAMEPASS_RBX WRITE — что если сервер читает оттуда?
-- ══════════════════════════════════════════════════════════════════
print("\n══════ GAMEPASS_RBX WRITE ══════")
local gpRbx = LP.EXTRA:FindFirstChild("MONETIZATION")
              and LP.EXTRA.MONETIZATION:FindFirstChild("GAMEPASS_RBX")
if gpRbx then
    for _, ch in ipairs(gpRbx:GetChildren()) do
        local before = ch.Value
        local ok = pcall(function() ch.Value = true end)
        print("[GP_RBX] " .. ch.Name .. ": " .. tostring(before) .. " → " .. tostring(ch.Value))
    end
end

-- Также попробуем GAMEPASS (уже все true, но что-то может быть writable)
local gp = LP.EXTRA:FindFirstChild("MONETIZATION")
           and LP.EXTRA.MONETIZATION:FindFirstChild("GAMEPASS")
if gp then
    print("\nGAMEPASS folder (already true, checking):")
    for _, ch in ipairs(gp:GetChildren()) do
        print("  " .. ch.Name .. " = " .. tostring(ch.Value))
    end
end

-- ══════════════════════════════════════════════════════════════════
-- [6] GetVerifiedBadge после записи Verified=true
-- ══════════════════════════════════════════════════════════════════
print("\n══════ GetVerifiedBadge ══════")
-- Пишем ещё раз Verified=true перед вызовом
local ver = LP.EXTRA:FindFirstChild("Verified")
if ver then pcall(function() ver.Value = true end) end
local ok6, r6 = pcall(function() return NET.GetVerifiedBadge:InvokeServer() end)
print("GetVerifiedBadge → " .. tostring(r6))

-- ══════════════════════════════════════════════════════════════════
-- [7] Defender — ищем любые RF с "claim" или "reward" мы пропустили
-- ══════════════════════════════════════════════════════════════════
print("\n══════ ALL CLAIM/REWARD RF ══════")
for _, ch in ipairs(NET:GetChildren()) do
    local n = ch.Name:lower()
    if n:find("claim") or n:find("reward") or n:find("collect")
    or n:find("redeem") or n:find("potion") or n:find("pass") then
        print("[NET] " .. ch.Name .. " [" .. ch.ClassName .. "]")
    end
end

print("\n=== DONE ===")
