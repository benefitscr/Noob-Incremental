-- UPDATE SCAN v2 — no clicks needed  @Benefit
local GC  = workspace.__GAME_CONTENT
local LP  = game:GetService("Players").LocalPlayer
local RS  = game:GetService("ReplicatedStorage")
local SM  = RS:FindFirstChild("Shared") and RS.Shared:FindFirstChild("Modules")

local function tryReq(name)
    if not SM then return nil end
    local m = SM:FindFirstChild(name, true)
    if not m then return nil end
    local ok, r = pcall(require, m)
    return ok and r or nil
end

local function tableKeys(t, depth)
    depth = depth or 0
    if type(t) ~= "table" then return end
    for k, v in pairs(t) do
        print(string.rep("  ", depth) .. tostring(k))
        if type(v) == "table" and depth < 2 then tableKeys(v, depth+1) end
    end
end

-- ══════════════════════════════════════════════════════════════════
-- [1] SHARED MODULES — dump all top-level module names
-- ══════════════════════════════════════════════════════════════════
print("══════ SHARED MODULES ══════")
if SM then
    local function scanModules(folder, prefix)
        for _, ch in ipairs(folder:GetChildren()) do
            print(prefix .. ch.Name)
            if ch:IsA("Folder") then scanModules(ch, prefix .. "  ") end
        end
    end
    scanModules(SM, "  ")
end

-- ══════════════════════════════════════════════════════════════════
-- [2] NOOBS MODULE
-- ══════════════════════════════════════════════════════════════════
print("\n══════ NOOBS ══════")
for _, name in ipairs({"Noobs","NoobTypes","NoobList","Noob"}) do
    local m = tryReq(name)
    if m then print("[MODULE:" .. name .. "]"); tableKeys(m); break end
end
-- Fallback: GC scan
local noobGC = GC:FindFirstChild("Noobs") or GC:FindFirstChild("NoobTypes")
if noobGC then
    for _, ch in ipairs(noobGC:GetChildren()) do print("  GC: " .. ch.Name) end
end
-- LP.FEATURES
local noobLP = LP.FEATURES:FindFirstChild("NOOBS")
if noobLP then
    for _, ch in ipairs(noobLP:GetChildren()) do
        local ok, v = pcall(function() return ch.Value end)
        print("  LP.FEATURES.NOOBS: " .. ch.Name .. (ok and ("="..tostring(v)) or ""))
    end
end

-- ══════════════════════════════════════════════════════════════════
-- [3] PRESTIGE MODULE
-- ══════════════════════════════════════════════════════════════════
print("\n══════ PRESTIGE ══════")
for _, name in ipairs({"Prestiges","Prestige","Rebirths","Rebirth","PrestigeList"}) do
    local m = tryReq(name)
    if m then print("[MODULE:" .. name .. "]"); tableKeys(m); break end
end
-- GC scan
for _, ch in ipairs(GC:GetChildren()) do
    if ch.Name:lower():find("prestige") or ch.Name:lower():find("rebirth") then
        print("  GC: " .. ch.Name)
        for _, c2 in ipairs(ch:GetChildren()) do print("    " .. c2.Name) end
    end
end
-- LP SIMPLE_VALUES prestige fields
local sv = LP:FindFirstChild("SIMPLE_VALUES")
if sv then
    for _, ch in ipairs(sv:GetChildren()) do
        local n = ch.Name:lower()
        if n:find("prestige") or n:find("rebirth") then
            local ok2, v = pcall(function() return ch.Value end)
            print("  SV." .. ch.Name .. "=" .. (ok2 and tostring(v) or "?"))
        end
    end
end
-- LP.FEATURES prestige
for _, ch in ipairs(LP.FEATURES:GetChildren()) do
    if ch.Name:lower():find("prestige") or ch.Name:lower():find("rebirth") then
        print("  LP.FEATURES." .. ch.Name)
        for _, c2 in ipairs(ch:GetChildren()) do
            local ok3, v = pcall(function() return c2.Value end)
            print("    " .. c2.Name .. (ok3 and ("="..tostring(v)) or ""))
        end
    end
end

-- ══════════════════════════════════════════════════════════════════
-- [4] ORES
-- ══════════════════════════════════════════════════════════════════
print("\n══════ ORES ══════")
local function getOreFolder()
    local f = GC:FindFirstChild("Ores"); if f then return f end
    local ct = GC:FindFirstChild("Contents"); if not ct then return nil end
    for _, w in ipairs(ct:GetChildren()) do
        local wf = w:FindFirstChild("Ores"); if wf then return wf end
    end
end
local oreF = getOreFolder()
local oreNames = {}
if oreF then
    local seen = {}
    for _, ore in ipairs(oreF:GetChildren()) do
        if not seen[ore.Name] then seen[ore.Name]=true; oreNames[#oreNames+1]=ore.Name end
    end
    table.sort(oreNames)
    for _, n in ipairs(oreNames) do print("  " .. n) end
end

-- ══════════════════════════════════════════════════════════════════
-- [5] EQUIPMENT — all items in all slots
-- ══════════════════════════════════════════════════════════════════
print("\n══════ EQUIPMENT INVENTORY ══════")
local SLOTS = {"Necklace","Special","Ring","Geode"}
for _, sn in ipairs(SLOTS) do
    local inv = LP.FEATURES.EQUIPMENT.Inventory:FindFirstChild(sn)
    if inv and #inv:GetChildren() > 0 then
        for _, item in ipairs(inv:GetChildren()) do
            local ok4, v = pcall(function() return item.Value end)
            print("  [" .. sn .. "] " .. item.Name .. " id=" .. (ok4 and tostring(v) or "?"))
        end
    end
end
-- Shared module for equipment/shop items
for _, name in ipairs({"Equipment","EquipmentList","Shop","BasicShop","ShopItems"}) do
    local m = tryReq(name)
    if m then
        print("[MODULE:" .. name .. "]")
        tableKeys(m)
        break
    end
end

-- ══════════════════════════════════════════════════════════════════
-- [6] WATER BUCKET types
-- ══════════════════════════════════════════════════════════════════
print("\n══════ WATER BUCKET ══════")
for _, name in ipairs({"WaterBuckets","Buckets","WaterBucket","Wells","Water"}) do
    local m = tryReq(name)
    if m then print("[MODULE:" .. name .. "]"); tableKeys(m); break end
end
-- GC scan for wells/buckets
for _, desc in ipairs(GC:GetDescendants()) do
    local n = desc.Name:lower()
    if (n:find("bucket") or n:find("well") or n:find("water")) and desc:IsA("Folder") then
        print("  GC FOLDER: " .. desc:GetFullName())
        for _, ch in ipairs(desc:GetChildren()) do print("    " .. ch.Name) end
    end
end
-- LP.CURRENCIES water-related
for _, ch in ipairs(LP.CURRENCIES:GetChildren()) do
    if ch.Name:lower():find("water") or ch.Name:lower():find("bucket") then
        print("  CURRENCY: " .. ch.Name)
    end
end

-- ══════════════════════════════════════════════════════════════════
-- [7] TIER AWAKENING — how many awakenings possible
-- ══════════════════════════════════════════════════════════════════
print("\n══════ TIER AWAKENING ══════")
local tierF = LP.FEATURES:FindFirstChild("TIER")
if tierF then
    for _, ch in ipairs(tierF:GetChildren()) do
        local ok5, v = pcall(function() return ch.Value end)
        print("  " .. ch.Name .. "=" .. (ok5 and tostring(v) or "?"))
    end
end
for _, name in ipairs({"TierAwakenList","TierAwakenings","Awakenings","Tiers","TierList"}) do
    local m = tryReq(name)
    if m then
        print("[MODULE:" .. name .. "]")
        tableKeys(m)
        break
    end
end

-- ══════════════════════════════════════════════════════════════════
-- [8] FULL LP.SIMPLE_VALUES dump
-- ══════════════════════════════════════════════════════════════════
print("\n══════ SIMPLE_VALUES ══════")
if sv then
    for _, ch in ipairs(sv:GetChildren()) do
        local ok6, v = pcall(function() return ch.Value end)
        print("  " .. ch.Name .. "=" .. (ok6 and tostring(v) or "?"))
    end
end

print("\n=== DONE ===")
