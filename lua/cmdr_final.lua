-- ═══════════════════════════════════════════════════════════════════
--  CMDR FINAL PROBE  @Benefit
--  Тестируем команды без Player-аргумента + specific item names
-- ═══════════════════════════════════════════════════════════════════

local RS = game:GetService("ReplicatedStorage")
local LP = game:GetService("Players").LocalPlayer
local u  = LP.Name
local fn = RS.CmdrClient.CmdrFunction

local function c(cmd)
    local ok, r = pcall(function() return fn:InvokeServer(cmd) end)
    local resp = ok and tostring(r or "") or ""
    local bad = resp:find("not a valid") or resp:find("Please use") or resp == ""
    if not bad then
        print("[★] " .. cmd)
        print("    → " .. resp:sub(1,200))
    end
    return resp
end

-- ══════════════════════════════════════════════════════════════════
-- [1] Команды без Player аргумента (возможно без прав)
-- ══════════════════════════════════════════════════════════════════
print("[TEST] No-player commands...")
c("listTemplates")
c("uptime")
c("version")
c("blink")
c("hover")

-- ══════════════════════════════════════════════════════════════════
-- [2] giveEquipment с реальными именами предметов
--     Description говорит "or a specific item name"
-- ══════════════════════════════════════════════════════════════════
print("\n[EQ] Testing specific item names as equipmentCategory...")

local ALL_ITEMS = {
    -- Special (из модуля)
    "Grenade","Electric Sword","Axe","Divine Totem",
    "Leaf Sword","Dagger","Sniper","Spear",
    -- Necklace
    "Rust","Mist","Frost","Ember","Dull","Verdant",
    "Copper","Sky","Shadow","Dawn",
    -- Ring
    "Ash","Drift","Clay","Dew","Emberstone",
    "Grove","Tide","Bloom","Shard","Veil",
    -- Geode
    "Azure Glyph","Aether Sigil","Mythos Mark","Elder Glyph",
    -- Category
    "Geode","all",
}
for _, item in ipairs(ALL_ITEMS) do
    c("giveequipment " .. u .. " " .. item)
    task.wait(0.03)
end

-- ══════════════════════════════════════════════════════════════════
-- [3] addRuneCount / setRuneCount с реальными редкостями
-- ══════════════════════════════════════════════════════════════════
print("\n[RUNE] Testing addRuneCount / setRuneCount...")

local RARITIES = {"Common","Uncommon","Rare","Epic","Legendary","Mythical","Secret","Exclusive"}
for _, r in ipairs(RARITIES) do
    c("addRuneCount " .. u .. " " .. r .. " 9999999")
    task.wait(0.03)
end
for _, r in ipairs(RARITIES) do
    c("setRuneCount " .. u .. " " .. r .. " 9999999")
    task.wait(0.03)
end

-- ══════════════════════════════════════════════════════════════════
-- [4] timeWarp / rollRunesForTime
-- ══════════════════════════════════════════════════════════════════
print("\n[WARP] Testing timeWarp / rollRunesForTime...")
c("timeWarp " .. u .. " 86400")          -- 24 часа варп
c("rollRunesForTime " .. u .. " Basic 3600")  -- 1 час рун
c("rollRunesForTime " .. u .. " Super 3600")
c("maxAllTree " .. u)

-- ══════════════════════════════════════════════════════════════════
-- [5] applyTemplate — если есть сохранённые шаблоны
-- ══════════════════════════════════════════════════════════════════
print("\n[TMPL] Testing applyTemplate with guessed names...")
local TEMPLATES = {
    "default","Default","max","Max","test","Test",
    "admin","Admin","starter","Starter","template","Template",
    "debug","Debug","base","Base","full","Full",
}
for _, t in ipairs(TEMPLATES) do
    c("applyTemplate " .. u .. " " .. t)
    task.wait(0.03)
end

-- ══════════════════════════════════════════════════════════════════
-- [6] setCurrency / addCurrency с реальными валютами
--     (из CurrencyName type — валюты известны)
-- ══════════════════════════════════════════════════════════════════
print("\n[CUR] Testing setCurrency / addCurrency...")
local CURRENCIES = {"Coins","Gems","Cash","Prism","HackPoints","Blaze","Fire","Oof","Rebirth"}
for _, cur in ipairs(CURRENCIES) do
    c("addCurrency " .. u .. " " .. cur .. " 999999999999")
    task.wait(0.03)
end

print("\n=== DONE ===")
print("★ = не 'invalid argument' и не пустой ответ")
