-- UPDATE SCAN — v7.1 patch recon  @Benefit
-- Finds: new Noob type, new Prestige, new Ore, new Equipment, new Water Bucket
local GC  = workspace.__GAME_CONTENT
local LP  = game:GetService("Players").LocalPlayer
local MR  = game:GetService("ReplicatedStorage").__Net.MainRemote
local NET = game:GetService("ReplicatedStorage").__Net
local RS  = game:GetService("ReplicatedStorage")

print("══════ NOOB TYPES ══════")
-- The Noobs folder or Features
local noobF = LP.FEATURES:FindFirstChild("NOOBS") or GC:FindFirstChild("Noobs")
if noobF then
    for _, ch in ipairs(noobF:GetChildren()) do
        print("  NOOB: " .. ch.Name)
    end
end
-- Also try Shared.Modules
local ok, NoobsM = pcall(require, RS.Shared.Modules:FindFirstChild("Noobs") or RS.Shared.Modules:FindFirstChild("NoobTypes"))
if ok and type(NoobsM) == "table" then
    print("Noobs module keys:")
    for k in pairs(NoobsM) do print("  " .. tostring(k)) end
end
-- LP.CURRENCIES Noob-related
for _, ch in ipairs(LP.CURRENCIES:GetChildren()) do
    if ch.Name:lower():find("noob") then print("  CURRENCY: " .. ch.Name) end
end

print("\n══════ PRESTIGE ══════")
-- Prestige in LP.FEATURES or LP.SIMPLE_VALUES
local feat = LP.FEATURES
for _, ch in ipairs(feat:GetChildren()) do
    if ch.Name:lower():find("prestige") or ch.Name:lower():find("rebirth") then
        print("  FEAT: " .. ch.Name)
        for _, c2 in ipairs(ch:GetChildren()) do print("    " .. c2.Name) end
    end
end
local sv = LP:FindFirstChild("SIMPLE_VALUES")
if sv then
    for _, ch in ipairs(sv:GetChildren()) do
        if ch.Name:lower():find("prestige") or ch.Name:lower():find("rebirth") then
            local ok2, v = pcall(function() return ch.Value end)
            print("  SV: " .. ch.Name .. " = " .. (ok2 and tostring(v) or "?"))
        end
    end
end
-- GC prestige folder
local presF = GC:FindFirstChild("Prestiges") or GC:FindFirstChild("Prestige")
if presF then
    for _, ch in ipairs(presF:GetChildren()) do print("  GC PRESTIGE: " .. ch.Name) end
end
-- Try SharedModules
local ok2, PresM = pcall(require, RS.Shared.Modules:FindFirstChild("Prestiges") or RS.Shared.Modules:FindFirstChild("Prestige"))
if ok2 and type(PresM) == "table" then
    for k in pairs(PresM) do print("  MODULE: " .. tostring(k)) end
end

print("\n══════ ORES ══════")
local function getOreFolder()
    local f = GC:FindFirstChild("Ores"); if f then return f end
    local ct = GC:FindFirstChild("Contents"); if not ct then return nil end
    for _, w in ipairs(ct:GetChildren()) do
        local wf = w:FindFirstChild("Ores"); if wf then return wf end
    end
end
local oreF = getOreFolder()
if oreF then
    local seen = {}
    for _, ore in ipairs(oreF:GetChildren()) do
        if not seen[ore.Name] then
            seen[ore.Name] = true
            print("  ORE: " .. ore.Name)
        end
    end
end

print("\n══════ EQUIPMENT (all slots + inventory) ══════")
local SLOTS = {"Necklace","Special","Ring","Geode"}
for _, sn in ipairs(SLOTS) do
    local inv = LP.FEATURES.EQUIPMENT.Inventory:FindFirstChild(sn)
    if inv then
        for _, item in ipairs(inv:GetChildren()) do
            local ok3, v = pcall(function() return item.Value end)
            print("  [" .. sn .. "] " .. item.Name .. " = " .. (ok3 and tostring(v) or "?"))
        end
    end
end

print("\n══════ WATER BUCKET / FILL BUCKET ══════")
-- Check if there are multiple bucket types
local feat2 = LP.FEATURES
for _, ch in ipairs(feat2:GetChildren()) do
    local n = ch.Name:lower()
    if n:find("water") or n:find("bucket") or n:find("well") then
        print("  FEAT: " .. ch.Name)
        for _, c2 in ipairs(ch:GetChildren()) do print("    " .. c2.Name) end
    end
end
-- Scan GC for bucket-related
for _, desc in ipairs(GC:GetDescendants()) do
    local n = desc.Name:lower()
    if (n:find("bucket") or n:find("water well")) and desc:IsA("Model") then
        print("  GC: " .. desc:GetFullName())
    end
end

print("\n══════ NEW ACTION EVENTS (scan MainRemote hook) ══════")
print("Starting 15s hook — кликай на всё новое: Prestige, новый нуб, новый ore...")
local orig = getrawmetatable(game)
local old_nc = orig.__namecall
setreadonly(orig, false)
orig.__namecall = newcclosure(function(self, ...)
    local method = getnamecallmethod()
    if (method == "FireServer" or method == "InvokeServer")
    and self == game:GetService("ReplicatedStorage").__Net.MainRemote then
        local args = {...}
        local action = tostring(args[1] or "")
        if not action:find("Heartbeat") and not action:find("Ping")
        and not action:find("Rune") and not action:find("Tycoon")
        and not action:find("OpenCapsule") then
            print("[HOOK] " .. action)
            for i = 2, math.min(#args, 3) do
                print("  a" .. i .. "=" .. tostring(args[i]):sub(1,60))
            end
        end
    end
    return old_nc(self, ...)
end)
setreadonly(orig, true)

task.wait(15)

setreadonly(orig, false)
orig.__namecall = old_nc
setreadonly(orig, true)

print("\n══════ TIER AWAKENING COUNT ══════")
local tierF = LP.FEATURES:FindFirstChild("TIER")
if tierF then
    for _, ch in ipairs(tierF:GetChildren()) do
        local ok4, v = pcall(function() return ch.Value end)
        print("  " .. ch.Name .. " = " .. (ok4 and tostring(v) or "?"))
    end
end
-- Check how many awakenings are possible
local ok5, TierM = pcall(require, RS.Shared.Modules:FindFirstChild("Tiers") or RS.Shared.Modules:FindFirstChild("TierList"))
if ok5 and type(TierM) == "table" then
    local maxTier = 0
    for k in pairs(TierM) do
        local n = tonumber(k); if n and n > maxTier then maxTier = n end
    end
    print("Max tier in module: " .. maxTier)
end

print("\n=== DONE ===")
