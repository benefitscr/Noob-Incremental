-- APPLYSETTINGVALUE EXPLOIT TEST  @Benefit
-- Confirmed format: MainRemote:FireServer("ApplySettingValue", settingName, value)
local RS  = game:GetService("ReplicatedStorage")
local LP  = game:GetService("Players").LocalPlayer
local MR  = RS.__Net.MainRemote

local function fire(...) pcall(MR.FireServer, MR, ...) end

-- Читаем LP.FEATURES глубоко
local function readFeat(path)
    local obj = LP.FEATURES
    for _, k in ipairs(path) do
        if not obj then return nil end
        obj = obj:FindFirstChild(k)
    end
    if not obj then return nil end
    local ok, v = pcall(function() return obj.Value end)
    return ok and v or nil
end

-- Считываем все доступные валюты через LP.leaderstats
local function stat(name)
    local ls = LP:FindFirstChild("leaderstats")
    if ls then
        local v = ls:FindFirstChild(name)
        if v then return tostring(v.Value) end
    end
    -- Также через LP.FEATURES
    local f = LP.FEATURES
    if f then
        local v = f:FindFirstChild(name)
        if v then return tostring(v.Value) end
        -- Рекурсивно
        for _, ch in ipairs(f:GetDescendants()) do
            if ch.Name == name then
                local ok, val = pcall(function() return ch.Value end)
                if ok then return tostring(val) end
            end
        end
    end
    return "N/A"
end

-- ══════════════════════════════════════════════════════════════════
-- SNAPSHOT ПЕРЕД
-- ══════════════════════════════════════════════════════════════════
print("══════ BEFORE ══════")
print("Oof: " .. stat("Oof"))
print("WalkSpeed (feat): " .. stat("WalkSpeed"))
print("RuneLuck (feat): " .. stat("RuneLuck"))
print("RuneBulk (feat): " .. stat("RuneBulk"))
print("MutationLuck (feat): " .. stat("MutationLuck"))

-- LP.leaderstats и LP.FEATURES полный список
print("\nAll LP children:")
for _, ch in ipairs(LP:GetChildren()) do
    print("  " .. ch.Name .. " [" .. ch.ClassName .. "]")
end

-- ══════════════════════════════════════════════════════════════════
-- ПРИМЕНЯЕМ НАСТРОЙКИ С HUGE VALUES
-- ══════════════════════════════════════════════════════════════════
print("\n══════ FIRING ApplySettingValue ══════")
local BIG = 999999999999

local settings = {
    "Walkspeed",
    "Rune Luck",
    "Rune Bulk",
    "Mutation Luck",
    "Campfire Level",
}

for _, name in ipairs(settings) do
    print("Firing: " .. name .. " = " .. BIG)
    fire("ApplySettingValue", name, BIG)
    task.wait(0.3)
end

task.wait(2)

-- ══════════════════════════════════════════════════════════════════
-- SNAPSHOT ПОСЛЕ
-- ══════════════════════════════════════════════════════════════════
print("\n══════ AFTER ══════")
print("Oof: " .. stat("Oof"))
print("WalkSpeed (feat): " .. stat("WalkSpeed"))
print("RuneLuck (feat): " .. stat("RuneLuck"))
print("RuneBulk (feat): " .. stat("RuneBulk"))
print("MutationLuck (feat): " .. stat("MutationLuck"))

-- Также проверяем реальную WalkSpeed персонажа
local char = LP.Character
if char then
    local hum = char:FindFirstChild("Humanoid")
    if hum then
        print("Character WalkSpeed: " .. hum.WalkSpeed)
    end
end

-- ══════════════════════════════════════════════════════════════════
-- CAMPFIRE LEVEL — особый случай
-- Campfire Level не имеет targetCurrency — возможно напрямую даёт уровень
-- ══════════════════════════════════════════════════════════════════
print("\n══════ CAMPFIRE LEVEL TEST ══════")
-- Проверяем campfire данные
for _, ch in ipairs(LP.FEATURES:GetDescendants()) do
    if ch.Name:lower():find("campfire") or ch.Name:lower():find("ash") then
        local ok, v = pcall(function() return ch.Value end)
        print("[CAMP] " .. ch:GetFullName() .. " = " .. (ok and tostring(v) or ch.ClassName))
    end
end

fire("ApplySettingValue", "Campfire Level", 99999)
task.wait(1)

for _, ch in ipairs(LP.FEATURES:GetDescendants()) do
    if ch.Name:lower():find("campfire") or ch.Name:lower():find("ash") then
        local ok, v = pcall(function() return ch.Value end)
        print("[CAMP AFTER] " .. ch:GetFullName() .. " = " .. (ok and tostring(v) or ch.ClassName))
    end
end

print("\n=== DONE ===")
print("Если что-то изменилось — УЯЗВИМОСТЬ НАЙДЕНА!")
