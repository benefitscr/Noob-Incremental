-- ═══════════════════════════════════════════════════════════════════
--  CMDR EQUIPMENT EXPLOIT  @Benefit
--  giveequipment не требует прав — нужен валидный equipmentCategory
-- ═══════════════════════════════════════════════════════════════════

local RS  = game:GetService("ReplicatedStorage")
local LP  = game:GetService("Players").LocalPlayer
local username = LP.Name
local cmdrFn = RS.CmdrClient.CmdrFunction

local function cmdr(cmd)
    local ok, r = pcall(function() return cmdrFn:InvokeServer(cmd) end)
    local resp = ok and tostring(r or "nil") or "ERR"
    -- Только интересные результаты (не "not a valid")
    local isGood = resp ~= "" and not resp:find("not a valid") and not resp:find("is not a valid")
    print((isGood and "[★] " or "[ ] ") .. cmd:sub(1,60))
    if isGood then print("    → " .. resp:sub(1,150)) end
    return ok, r, resp
end

-- ══════════════════════════════════════════════════════════════════
-- [1] ЧИТАЕМ Equipment модуль — ищем валидные категории
-- ══════════════════════════════════════════════════════════════════
print("[EQ] Reading equipment modules...")

local function dumpDeep(tbl, prefix, depth)
    depth = depth or 0
    if depth > 4 then return end
    prefix = prefix or ""
    if type(tbl) ~= "table" then return end
    for k, v in pairs(tbl) do
        if type(v) == "table" then
            print(prefix .. tostring(k) .. ":")
            dumpDeep(v, prefix.."  ", depth+1)
        elseif type(v) ~= "function" then
            print(prefix .. tostring(k) .. " = " .. tostring(v))
        end
    end
end

-- Ищем Equipment модуль
local eqMod
pcall(function()
    eqMod = require(RS.Shared.Modules:FindFirstChild("Equipment")
                 or RS.Shared.Modules:FindFirstChild("Equipments")
                 or RS.Shared.Modules:FindFirstChild("Items"))
    if eqMod then
        print("[EQ MODULE] Found!")
        dumpDeep(eqMod, "  ")
    end
end)

-- Cmdr Types для equipment
local function tryRequireType(name)
    pcall(function()
        local m = RS.CmdrClient.Types:FindFirstChild(name)
        if not m then return end
        local ok, t = pcall(require, m)
        if ok then
            print("[TYPE:" .. name .. "] type=" .. type(t))
            if type(t) == "table" then dumpDeep(t, "  ") end
        end
    end)
end

print("\n[CMDR] Reading Cmdr type modules...")
for _, child in ipairs(RS.CmdrClient.Types:GetChildren()) do
    print("[CMDR TYPE] " .. child.Name)
    tryRequireType(child.Name)
end

-- Все команды в CmdrClient.Commands
print("\n[CMDR] Available commands:")
for _, child in ipairs(RS.CmdrClient.Commands:GetChildren()) do
    print("[CMD] " .. child.Name)
    -- Читаем исходник команды
    pcall(function()
        local ok2, data = pcall(require, child)
        if ok2 and type(data) == "table" then
            if data.Name then print("  Name: " .. tostring(data.Name)) end
            if data.Args then
                for i, arg in ipairs(data.Args) do
                    print("  Arg" .. i .. ": " .. tostring(arg.Name)
                        .. " [" .. tostring(arg.Type) .. "]"
                        .. (arg.Optional and " (optional)" or ""))
                end
            end
        end
    end)
end

-- ══════════════════════════════════════════════════════════════════
-- [2] BRUTE FORCE equipmentCategory
-- ══════════════════════════════════════════════════════════════════
print("\n[EQ] Brute forcing equipment categories...")

local CATEGORIES = {
    -- Zone-based
    "Basic","Super","Advanced","Hacker","Snowy","Prism","Deepcore","Cosmic",
    "Noobinial","Special","Exclusive","Limited",
    -- Type-based
    "Tool","Accessory","Armor","Weapon","Helmet","Boots","Gloves","Ring",
    "Amulet","Necklace","Cape","Shield","Sword","Staff","Bow",
    -- Rarity-based
    "Common","Uncommon","Rare","Epic","Legendary","Mythical","Secret","Rainbow",
    -- Generic
    "All","Default","None","Normal","Special","Ultimate","Prism","God",
    -- Numbers
    "1","2","3","4","5",
    -- From game zones
    "CoinZone","RuneZone","HackZone","SnowyZone",
}

for _, cat in ipairs(CATEGORIES) do
    cmdr("giveequipment " .. username .. " " .. cat)
    task.wait(0.05)
end

-- ══════════════════════════════════════════════════════════════════
-- [3] ПРОВЕРЯЕМ RuneRarityName — команды для рун
-- ══════════════════════════════════════════════════════════════════
print("\n[RUNE] Testing rune commands...")

local RUNE_CMDS = {
    "giverune " .. username .. " Basic",
    "giverune " .. username .. " Master",
    "giverune " .. username .. " Grandmaster",
    "giverune " .. username .. " Shadow",
    "giverune " .. username .. " Void",
    "giverune " .. username .. " Chronos Core",
    "giverune " .. username .. " Immortal",
    "giverune " .. username .. " Atomic",
}
for _, cmd in ipairs(RUNE_CMDS) do
    cmdr(cmd)
    task.wait(0.05)
end

-- ══════════════════════════════════════════════════════════════════
-- [4] ЧТО ДЕЛАЕТ GiveEquipment — читаем реализацию
-- ══════════════════════════════════════════════════════════════════
print("\n[EQ] Reading GiveEquipment command implementation...")
pcall(function()
    local m = RS.CmdrClient.Commands:FindFirstChild("GiveEquipment")
             or RS.CmdrClient.Commands:FindFirstChild("giveequipment")
    if m then
        local ok, data = pcall(require, m)
        if ok then
            print("[GIVEEQ] Name:", data.Name)
            print("[GIVEEQ] Description:", data.Description)
            if data.Args then
                for i, a in ipairs(data.Args) do
                    print("[GIVEEQ] Arg"..i..": name="..tostring(a.Name)
                        .." type="..tostring(a.Type)
                        .." opt="..tostring(a.Optional))
                end
            end
        end
    end
end)
