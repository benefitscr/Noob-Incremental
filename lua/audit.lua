-- ═══════════════════════════════════════════════════════════════════
--  Noob Incremental · FULL AUDIT SCRIPT  @Benefit
--  Run this FIRST to discover all remotes + try every known call
-- ═══════════════════════════════════════════════════════════════════

local RS   = game:GetService("ReplicatedStorage")
local LP   = game:GetService("Players").LocalPlayer
local HS   = game:GetService("HttpService")

-- ─── HELPERS ────────────────────────────────────────────────────────
local LOG = {}
local function log(tag, msg)
    local line = string.format("[%s][%s] %s", os.date("%H:%M:%S"), tag, tostring(msg))
    table.insert(LOG, line)
    print(line)
end

local function serialize(v, depth)
    depth = depth or 0
    if depth > 3 then return "..." end
    local t = type(v)
    if t == "string"  then return '"'..v:sub(1,40)..'"' end
    if t == "number"  then return tostring(v) end
    if t == "boolean" then return tostring(v) end
    if t == "table"   then
        local parts = {}
        for k,val in pairs(v) do
            parts[#parts+1] = tostring(k).."="..serialize(val, depth+1)
        end
        return "{"..table.concat(parts,", ").."}"
    end
    if t == "userdata" or t == "Instance" then
        local ok, n = pcall(function() return v.Name end)
        return ok and ("Instance:"..n) or tostring(v)
    end
    return tostring(v)
end

-- ─── STEP 1: ENUMERATE ALL REMOTES ──────────────────────────────────
log("ENUM", "=== Remote scan start ===")

local function scanFolder(folder, prefix)
    prefix = prefix or ""
    for _, obj in ipairs(folder:GetDescendants()) do
        if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
            log("REMOTE", prefix..obj:GetFullName().." ["..obj.ClassName.."]")
        end
    end
end

pcall(scanFolder, RS, "RS:")
pcall(function()
    for _, svc in ipairs({"Workspace","Players","ServerStorage"}) do
        pcall(scanFolder, game:GetService(svc), svc..":")
    end
end)

-- ─── STEP 2: HOOK MainRemote TO CAPTURE ALL LIVE CALLS ──────────────
log("HOOK", "=== Hooking MainRemote FireServer ===")

local MR = RS.__Net.MainRemote
local callCounts = {}
local capturedCalls = {}

-- Hook via metatable (works in most executors)
local hooked = false
pcall(function()
    local mt = getrawmetatable(MR)
    local old_namecall = mt.__namecall
    setreadonly(mt, false)
    mt.__namecall = function(self, ...)
        local method = getnamecallmethod()
        if method == "FireServer" then
            local args = {...}
            local key = tostring(args[1])
            callCounts[key] = (callCounts[key] or 0) + 1
            -- Only log first 3 of each type to avoid spam
            if callCounts[key] <= 3 then
                local paramStr = ""
                for i=2,math.min(#args,5) do
                    paramStr = paramStr.." "..serialize(args[i])
                end
                log("CALL", key..paramStr)
                table.insert(capturedCalls, {name=key, args=args})
            end
        end
        return old_namecall(self, ...)
    end
    setreadonly(mt, true)
    hooked = true
end)

if not hooked then
    -- Fallback: wrap FireServer directly
    pcall(function()
        local orig = MR.FireServer
        MR.FireServer = function(self, ...)
            local args = {...}
            local key = tostring(args[1])
            callCounts[key] = (callCounts[key] or 0) + 1
            if callCounts[key] <= 3 then
                local paramStr = ""
                for i=2,math.min(#args,5) do
                    paramStr = paramStr.." "..serialize(args[i])
                end
                log("CALL", key..paramStr)
            end
            return orig(self, ...)
        end
        hooked = true
    end)
end

log("HOOK", hooked and "Hook OK" or "Hook FAILED - calls won't be logged")

-- ─── STEP 3: FIRE ALL KNOWN CALLS + VARIATIONS ──────────────────────
log("TEST", "=== Testing all known remotes ===")
task.wait(1)

local function fire(...)
    local ok, err = pcall(MR.FireServer, MR, ...)
    return ok, err
end

-- Known good ones from autofarm
local KNOWN = {
    "RollTier","DepositWheat","Water","CampfireButton",
    "ConvertWoodToAsh","HireNoob","FillBucket","Factory",
    "Cook","Animals","Mutation","ExchangeAllMinerals",
    "ExchangeAllAnimalProducts","Blaze","AwakenTier",
}
for _, name in ipairs(KNOWN) do
    local ok = fire(name)
    log("KNOWN", name.." → "..(ok and "OK" or "ERR"))
    task.wait(0.1)
end

-- ─── STEP 4: GUESS & BRUTE-FORCE CURRENCY REMOTES ───────────────────
log("GUESS", "=== Guessing currency/reward remotes ===")
task.wait(0.5)

local CURRENCY_GUESSES = {
    -- Direct give attempts
    {"GiveCurrency","Coins",1000},
    {"GiveCurrency","Gems",100},
    {"GiveCurrency","Cash",1000},
    {"AddCurrency","Coins",1000},
    {"AddCoins",1000},
    {"AddGems",100},
    {"RewardPlayer","Coins",1000},
    {"ClaimReward","Daily"},
    {"ClaimReward","Login"},
    {"ClaimDailyReward"},
    {"DailyReward"},
    {"LoginBonus"},
    {"GetDailyReward"},
    {"ClaimCode","FREEGEMS"},
    {"RedeemCode","FREEGEMS"},
    {"EnterCode","FREEGEMS"},
    {"UseCode","FREEGEMS"},
    -- Admin / debug
    {"AdminGive","Coins",99999},
    {"DebugGive",99999},
    {"DevGive",99999},
    {"SetCoins",99999},
    {"SetGems",99999},
    -- Shop / purchase bypass
    {"BuyItem","Coins",1},
    {"PurchaseItem","Coins",1},
    {"BuyGamepass",1},
    {"BypassPurchase",1},
    -- Chest/capsule spam
    {"OpenChest","Chest"},
    {"OpenChest","SuperChest"},
    {"OpenChest","MegaChest"},
    {"OpenChest","LegendaryChest"},
    {"OpenCapsule","Basic"},
    {"OpenCapsule","Super"},
    {"OpenCapsule","Advanced"},
    {"OpenCapsule","Premium"},
    -- Minion give
    {"GiveMinion","Best"},
    {"AddMinion","Best"},
    {"UnlockMinion","All"},
    -- Speed hacks via server
    {"SetSpeed",9999},
    {"SetWalkSpeed",100},
    {"SpeedBoost",999},
    -- Milestone/prestige bypass
    {"DepositCoinMilestone","Max"},
    {"ClaimMilestone","All"},
    {"AutoPrestige"},
    {"Prestige"},
    {"Rebirth"},
    -- Noob upgrades free
    {"UpgradeNoobMax","Fire"},
    {"UpgradeNoobMax","Ice"},
    {"UpgradeNoobMax","Water"},
    {"UpgradeNoobMax","Oof"},
    -- Rune manipulation
    {"GiveRune","Master"},
    {"AddRune","Shadow"},
    {"UnlockRune","All"},
    -- Equipment bypass
    {"GiveEquipment","Best"},
    {"UnlockEquipment","All"},
    {"MaxEquipment"},
}

local interesting = {}

for _, call in ipairs(CURRENCY_GUESSES) do
    local name = call[1]
    local args = {}
    for i=2,#call do args[#args+1] = call[i] end

    local ok, err = fire(name, table.unpack(args))
    local result = ok and "OK" or tostring(err):sub(1,60)

    -- Flag anything that didn't immediately error
    if ok then
        log("INTERESTING", name.." "..table.concat(args," ").." → "..result)
        table.insert(interesting, {name=name, args=args})
    else
        log("GUESS", name.." → "..result)
    end
    task.wait(0.15)
end

-- ─── STEP 5: SCAN ALL STRINGS IN CLIENT SCRIPTS FOR REMOTE NAMES ────
log("SCAN", "=== Scanning LocalScripts for remote strings ===")
task.wait(0.5)

local found_names = {}
local function scanScript(scr)
    local ok, src = pcall(function() return scr.Source end)
    if not ok or not src or src == "" then return end
    for name in src:gmatch('"([A-Z][A-Za-z0-9_]+)"') do
        if #name > 3 and #name < 40 and not found_names[name] then
            found_names[name] = true
            -- Only log if looks like a remote name (CamelCase, not UI string)
            if name:match("^[A-Z][a-z]") and not name:match(" ") then
                log("SRCNAME", name)
            end
        end
    end
end

for _, d in ipairs(LP.PlayerGui:GetDescendants()) do
    if d:IsA("LocalScript") or d:IsA("ModuleScript") then
        pcall(scanScript, d)
    end
end
for _, d in ipairs(game:GetService("ReplicatedFirst"):GetDescendants()) do
    if d:IsA("LocalScript") or d:IsA("ModuleScript") then
        pcall(scanScript, d)
    end
end

-- ─── STEP 6: PRINT SUMMARY ──────────────────────────────────────────
task.wait(1)
log("DONE", "=== AUDIT COMPLETE ===")
log("DONE", "Interesting (returned OK): "..#interesting)
for _, c in ipairs(interesting) do
    log("★", c.name.." "..table.concat(c.args," "))
end
log("DONE", "Unique calls captured by hook: "..#capturedCalls)
log("DONE", "Total log lines: "..#LOG)
print("\n\n=== FULL LOG ===")
for _, line in ipairs(LOG) do print(line) end
