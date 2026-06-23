-- DEEP SCAN 2  @Benefit
-- 1. TycoonDrop replay attack (ID intercept → spam sell)
-- 2. LP.CURRENCIES type audit (writeable?)
-- 3. LocalScript module cache poisoning (drop rates)
-- 4. SetPlayerData / WriteData RF scan
local RS  = game:GetService("ReplicatedStorage")
local LP  = game:GetService("Players").LocalPlayer
local MR  = RS.__Net.MainRemote
local NET = RS.__Net

local function fire(...) pcall(MR.FireServer, MR, ...) end
local function p(...) print(...) end

-- ══════════════════════════════════════════════════════════════════
-- [1] TYCOON DROP REPLAY ATTACK
--     TycoonDrop(id, value, mutation) → TycoonDropSell(id) ×10
-- ══════════════════════════════════════════════════════════════════
p("══════ TYCOON DROP REPLAY ══════")

-- Читаем валюту до
local function getCash()
    local f = LP.CURRENCIES:FindFirstChild("Cash")
    if not f then return "N/A" end
    local a = f:FindFirstChild("Amount")
    if a then
        local v = a:FindFirstChild("1") or a:FindFirstChild("2")
        if v then local ok, val = pcall(function() return v.Value end); return ok and tostring(val) or "?" end
    end
    return "N/A"
end
p("Cash before hook: " .. getCash())

local replayCounts = {}

NET.TycoonDrop.OnClientEvent:Connect(function(...)
    local args = {...}
    p("[DROP] received: " .. #args .. " args")
    for i, v in ipairs(args) do
        p("  arg" .. i .. " [" .. type(v) .. "] = " .. tostring(v):sub(1,80))
    end

    -- arg1 обычно dropId или dropData
    local dropId = nil
    if type(args[1]) == "number" or type(args[1]) == "string" then
        dropId = args[1]
    elseif type(args[1]) == "table" then
        dropId = args[1].id or args[1].Id or args[1][1]
    end

    if dropId then
        p("[★] Replaying TycoonDropSell ×15 with id=" .. tostring(dropId))
        replayCounts[tostring(dropId)] = (replayCounts[tostring(dropId)] or 0) + 1

        -- Спамим без задержки
        for i = 1, 15 do
            task.spawn(function()
                fire("TycoonDropSell", dropId)
                fire("TycoonDropSell", dropId, true)
                fire("TycoonDropSell", dropId, 1)
            end)
        end

        task.wait(0.5)
        p("Cash after replay: " .. getCash())
    end
end)

-- Также перехватываем что именно летит при продаже
local orig = getrawmetatable(game)
local old_nc = orig.__namecall
setreadonly(orig, false)
orig.__namecall = newcclosure(function(self, ...)
    local method = getnamecallmethod()
    if method == "FireServer" and self == MR then
        local args = {...}
        local action = tostring(args[1] or "")
        if action:lower():find("drop") or action:lower():find("sell")
        or action:lower():find("tycoon") then
            p("[SELL HOOK] " .. action)
            for i = 2, #args do
                p("  arg" .. i .. " = " .. tostring(args[i]):sub(1,60))
            end
        end
    end
    return old_nc(self, ...)
end)
setreadonly(orig, true)

p("TycoonDrop hook active — жди дропов с тайкуна (30s)...")
task.wait(30)

setreadonly(orig, false)
orig.__namecall = old_nc
setreadonly(orig, true)

p("Cash after 30s: " .. getCash())

-- ══════════════════════════════════════════════════════════════════
-- [2] LP.CURRENCIES TYPE AUDIT — кто создал эти instances?
-- ══════════════════════════════════════════════════════════════════
p("\n══════ CURRENCIES TYPE AUDIT ══════")
local cur = LP:FindFirstChild("CURRENCIES")
if cur then
    for _, child in ipairs(cur:GetChildren()) do
        p("[CUR] " .. child.Name .. " [" .. child.ClassName .. "]")
        for _, ch2 in ipairs(child:GetDescendants()) do
            local ok, v = pcall(function() return ch2.Value end)
            if ok then
                -- Пробуем записать — если это client-owned, сработает
                local okW = pcall(function() ch2.Value = ch2.Value end)
                if okW then
                    p("  [WRITABLE!] " .. ch2.Name .. " = " .. tostring(v))
                end
            end
        end
    end
end

-- ══════════════════════════════════════════════════════════════════
-- [3] MODULE CACHE POISON — меняем дроп-таблицу в кэше
--     Если клиентские скрипты используют require(Capsules)
--     и мы модифицируем таблицу — их расчёты изменятся
-- ══════════════════════════════════════════════════════════════════
p("\n══════ MODULE CACHE POISON ══════")
local ok, Capsules = pcall(require, RS.Shared.Modules.Capsules)
if ok and type(Capsules) == "table" then
    -- Смотрим структуру List
    p("Capsules.List type: " .. type(Capsules.List))
    if type(Capsules.List) == "table" then
        for zone, data in pairs(Capsules.List) do
            p("[ZONE] " .. tostring(zone))
            if type(data) == "table" and data.Tiers then
                for tier, tdata in pairs(data.Tiers) do
                    if type(tdata) == "table" then
                        local origChance = tdata.Chance
                        -- Пробуем изменить шанс
                        local okM = pcall(function()
                            tdata.Chance = 100  -- 100% шанс этого тира
                        end)
                        if okM and tdata.Chance == 100 then
                            p("  [POISONED] " .. tostring(zone) .. "." .. tostring(tier) .. " Chance: " .. tostring(origChance) .. " → 100%")
                        end
                    end
                end
            end
        end
    end
    -- Восстанавливаем через перезагрузку не нужно — проверяем влияет ли на сервер
    -- Открываем капсулу и смотрим что придёт
    p("[POISON] Opening capsule after cache poison...")
    local poisonResult = nil
    local conn = NET.MinionCapsuleOpened.OnClientEvent:Connect(function(_, minions)
        for _, m in ipairs(minions or {}) do
            p("[AFTER POISON] Got: " .. tostring(m.name) .. " (" .. tostring(m.rarity) .. ")")
        end
        poisonResult = minions
    end)
    fire("OpenCapsule", "Super", 1)
    task.wait(3)
    conn:Disconnect()
    if not poisonResult then
        p("[POISON] No capsule response (rate limited or no capsules)")
    end
end

-- ══════════════════════════════════════════════════════════════════
-- [4] SCAN FOR SetPlayerData / WriteData / SaveData REMOTEFUNCTIONS
-- ══════════════════════════════════════════════════════════════════
p("\n══════ WRITE/SAVE RF SCAN ══════")
for _, child in ipairs(NET:GetChildren()) do
    local name = child.Name:lower()
    if name:find("set") or name:find("write") or name:find("save")
    or name:find("update") or name:find("put") or name:find("store")
    or name:find("data") then
        p("[RF/RE] NET." .. child.Name .. " [" .. child.ClassName .. "]")
        if child:IsA("RemoteFunction") then
            local ok2, r2 = pcall(function()
                return child:InvokeServer()
            end)
            p("  InvokeServer() → " .. tostring(r2):sub(1,100))
        end
    end
end

p("\n=== DONE ===")
