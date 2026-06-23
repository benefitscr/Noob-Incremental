-- PITY READ + SPECIAL VALUE INJECT  @Benefit
local RS = game:GetService("ReplicatedStorage")
local LP = game:GetService("Players").LocalPlayer
local MR = RS.__Net.MainRemote

local function fire(...) pcall(MR.FireServer, MR, ...) end

-- ══════════════════════════════════════════════════════════════════
-- [1] Читаем наш собственный пити и инвентарь из LP.FEATURES
-- ══════════════════════════════════════════════════════════════════
print("══════ OUR PITY & INVENTORY ══════")

local function scanFolder(folder, prefix)
    prefix = prefix or ""
    for _, ch in ipairs(folder:GetChildren()) do
        local full = prefix .. ch.Name
        if ch:IsA("Folder") then
            print("[DIR] " .. full)
            scanFolder(ch, full .. ".")
        else
            local ok, v = pcall(function() return ch.Value end)
            print("  " .. full .. " = " .. (ok and tostring(v) or "[" .. ch.ClassName .. "]"))
        end
    end
end

-- LAB.MINIONS — пити, инвентарь
local lab = LP.FEATURES:FindFirstChild("LAB")
if lab then
    local minions = lab:FindFirstChild("MINIONS")
    if minions then
        print("[MINIONS]")
        scanFolder(minions, "  ")
    end
    local auras = LP.FEATURES:FindFirstChild("AURAS")
    if auras then
        print("\n[AURAS]")
        scanFolder(auras, "  ")
    end
end

-- ASH_CAMPFIRE — реальный уровень
local camp = LP.FEATURES:FindFirstChild("ASH_CAMPFIRE")
if camp then
    print("\n[CAMPFIRE]")
    scanFolder(camp, "  ")
end

-- CURRENCIES — ищем WalkSpeed, RuneLuck, RuneBulk
local cur = LP:FindFirstChild("CURRENCIES")
if cur then
    print("\n[CURRENCIES WalkSpeed / RuneLuck / RuneBulk]")
    for _, ch in ipairs(cur:GetDescendants()) do
        local n = ch.Name
        if n == "WalkSpeed" or n == "RuneLuck" or n == "RuneBulk"
        or n == "MutationLuck" or n == "WalkSpeed" then
            local ok, v = pcall(function() return ch.Value end)
            print("  " .. ch:GetFullName():sub(#tostring(LP)+2) .. " = " .. (ok and tostring(v) or ch.ClassName))
        end
    end
end

-- ══════════════════════════════════════════════════════════════════
-- [2] SPECIAL VALUES в ApplySettingValue
-- ══════════════════════════════════════════════════════════════════
print("\n══════ SPECIAL VALUE INJECTION ══════")

-- Кампфайр Level BEFORE
local campBefore = 0
pcall(function()
    campBefore = LP.FEATURES.ASH_CAMPFIRE.Level.Value
end)
print("Campfire Level BEFORE: " .. campBefore)

local SPECIALS = {
    math.huge,      -- infinity
    -math.huge,     -- negative infinity
    2^53,           -- max safe integer
    2^63,           -- int64 overflow
    2^1024,         -- lua float overflow → inf
    -1,             -- negative
    0,
    1e308,          -- near float max
    math.huge,
}

for _, val in ipairs(SPECIALS) do
    fire("ApplySettingValue", "Campfire Level", val)
    task.wait(0.2)
end

task.wait(1)
local campAfter = 0
pcall(function()
    campAfter = LP.FEATURES.ASH_CAMPFIRE.Level.Value
end)
print("Campfire Level AFTER: " .. campAfter)
if campAfter ~= campBefore then
    print("[★] Campfire Level changed: " .. campBefore .. " → " .. campAfter)
end

-- ══════════════════════════════════════════════════════════════════
-- [3] GetAPlayerData для СЕБЯ — полный дамп нашего piti
-- ══════════════════════════════════════════════════════════════════
print("\n══════ OUR OWN GetAPlayerData ══════")
task.wait(3)
local ok, data = pcall(function()
    return RS.__Net.GetAPlayerData:InvokeServer(LP.Name)
end)
if ok and type(data) == "table" and data.Data then
    local d = data.Data
    -- SecretPity
    if d.FEATURES and d.FEATURES.LAB and d.FEATURES.LAB.MINIONS then
        local m = d.FEATURES.LAB.MINIONS
        print("[PITY SecretPity]")
        if m.SecretPity then
            for zone, zdata in pairs(m.SecretPity) do
                if type(zdata) == "table" then
                    for tier, count in pairs(zdata) do
                        print("  " .. zone .. "." .. tier .. " = " .. tostring(count))
                    end
                end
            end
        end
        print("[PITY CapsulePity]")
        if m.CapsulePity then
            for zone, zdata in pairs(m.CapsulePity) do
                if type(zdata) == "table" then
                    for k2, v2 in pairs(zdata) do
                        print("  " .. zone .. "." .. tostring(k2) .. " = " .. tostring(v2))
                    end
                end
            end
        end
        -- Minion inventory
        print("[INVENTORY] Equipped minions:")
        if m.Inventory then
            for id, mdata in pairs(m.Inventory) do
                if type(mdata) == "table" and mdata.Equipped then
                    print("  ID=" .. id .. " Name=" .. tostring(mdata.Name))
                end
            end
        end
    end
    -- SIMPLE_VALUES
    if d.SIMPLE_VALUES then
        local sv = d.SIMPLE_VALUES
        print("[SIMPLE] TotalCapsuleOpened: " .. tostring(sv.TotalCapsuleOpened))
        if sv.CapsuleOpenedByName then
            for k, v in pairs(sv.CapsuleOpenedByName) do
                print("[SIMPLE] CapsuleOpened." .. k .. " = " .. tostring(v))
            end
        end
    end
end

print("\n=== DONE ===")
