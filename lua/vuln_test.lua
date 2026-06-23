-- ═══════════════════════════════════════════════════════════════════
--  Noob Incremental · VULNERABILITY PoC TESTER  @Benefit
--  Тестирует классические уязвимости Roblox игр:
--  1. Negative values (отрицательная цена = прибыль)
--  2. nil / false injection (обход if-проверок)
--  3. math.huge / overflow
--  4. Race condition (двойной spend)
--  5. RemoteFunction auth bypass
--  6. Prestige/rebirth без требований
--  7. DataStore key injection
--  8. Duplicate claim (клейм одной награды дважды)
-- ═══════════════════════════════════════════════════════════════════

local RS  = game:GetService("ReplicatedStorage")
local LP  = game:GetService("Players").LocalPlayer
local MR  = RS.__Net.MainRemote
local NET = RS.__Net

local function fire(...) pcall(MR.FireServer, MR, ...) end
local function rf(name, ...)
    local args = {...}
    local ok, r = pcall(function() return NET[name]:InvokeServer(table.unpack(args)) end)
    return ok, r
end

-- Читаем Oof из leaderstats как быстрый индикатор изменений
local function stat()
    local ok, v = pcall(function() return LP.leaderstats.Oof.Value end)
    return ok and v or 0
end

local results = {}
local function test(name, fn)
    local before = stat()
    fn()
    task.wait(0.6)
    local after = stat()
    local changed = (after ~= before)
    local marker = changed and "★ VULN?" or "  safe"
    print(string.format("[%s] %s  (%.3e → %.3e)", marker, name, before, after))
    if changed then
        results[#results+1] = name .. " | " .. tostring(before) .. " → " .. tostring(after)
    end
end

print("=== VULN TESTER START ===\n")

-- ══════════════════════════════════════════════════════════════════
-- [1] NEGATIVE VALUES
--     Если сервер делает: currency = currency - cost
--     и cost передаётся клиентом — отрицательное cost = прибыль
-- ══════════════════════════════════════════════════════════════════
print("─── 1. NEGATIVE VALUES ───")

-- Покупка с отрицательной ценой
test("BuyItem price=-1000", function()
    fire("BuyItem", "Coins", -1000)
    fire("BuyItem", "Gems", -1000)
    fire("Purchase", "Coins", -1000)
    fire("Buy", "Coins", -1000)
end)

-- Открытие капсулы с отрицательным кол-вом (batch open)
test("OpenCapsule count=-1", function()
    fire("OpenCapsule", "Classic", -1)
    fire("OpenCapsule", "Prism",   -1)
    fire("OpenMinionCapsule", "Prism", -1)
end)

-- Upgrade с отрицательным уровнем
test("UpgradeNoob level=-1", function()
    fire("UpgradeNoob", "Fire", -1)
    fire("UpgradeNoob", "Coin", -1)
    fire("SetLevel",    "Fire", -9999)
end)

-- Exchange с отрицательным кол-вом
test("Exchange negative qty", function()
    fire("Exchange", "Mineral", -9999)
    fire("ExchangeMinerals", -9999)
    fire("SellItem", "Mineral", -9999)
end)

-- ══════════════════════════════════════════════════════════════════
-- [2] nil / false INJECTION
--     nil в ключевом аргументе может пропустить проверку:
--     if args.cost then ... end  → nil пропускает блок
-- ══════════════════════════════════════════════════════════════════
print("\n─── 2. nil/false INJECTION ───")

test("BuyItem cost=nil", function()
    fire("BuyItem", nil, nil)
    fire("Purchase", nil)
    fire("Buy", nil, nil)
end)

test("OpenCapsule type=nil", function()
    fire("OpenCapsule", nil)
    fire("OpenCapsule", nil, nil)
    fire("OpenMinionCapsule", nil)
end)

test("UpgradeNoobMax type=nil", function()
    fire("UpgradeNoobMax", nil)
end)

test("Prestige with false flag", function()
    fire("Prestige", false)
    fire("Prestige", false, false)
    fire("Rebirth", false)
end)

-- ══════════════════════════════════════════════════════════════════
-- [3] OVERFLOW / math.huge
--     Некоторые серверы принимают число, не проверяя диапазон
-- ══════════════════════════════════════════════════════════════════
print("\n─── 3. OVERFLOW ───")

test("OpenCapsule count=math.huge", function()
    fire("OpenCapsule", "Classic", math.huge)
    fire("OpenCapsule", "Prism",   math.huge)
    fire("OpenMinionCapsule", "Classic", math.huge)
end)

test("BuyItem count=2^53", function()
    fire("BuyItem", "Coins", 2^53)
    fire("Purchase", 2^53)
end)

test("UpgradeNoob level=math.huge", function()
    fire("UpgradeNoob", "Fire", math.huge)
    fire("SetLevel", "Coin", math.huge)
end)

test("RollRune count=math.huge", function()
    fire("RollRune", "Basic", math.huge)
    fire("RollRune", "Prism", math.huge)
end)

-- ══════════════════════════════════════════════════════════════════
-- [4] RACE CONDITION (double spend / double claim)
--     Два одновременных вызова до того как сервер обновил стейт
-- ══════════════════════════════════════════════════════════════════
print("\n─── 4. RACE CONDITION ───")

test("Parallel Prestige x5", function()
    for _=1,5 do
        task.spawn(function() fire("Prestige") end)
    end
end)

test("Parallel Rebirth x5", function()
    for _=1,5 do
        task.spawn(function() fire("Rebirth") end)
    end
end)

test("Parallel ClaimDaily x5", function()
    for _=1,5 do
        task.spawn(function()
            pcall(function() NET.ClaimAllGuildWeeklyRewards:InvokeServer() end)
        end)
    end
end)

test("Parallel AwakenTier x10", function()
    for _=1,10 do
        task.spawn(function() fire("AwakenTier") end)
    end
end)

-- ══════════════════════════════════════════════════════════════════
-- [5] REMOTEFUNTION AUTH BYPASS
--     Если RF не проверяет что вызывающий — admin/owner
-- ══════════════════════════════════════════════════════════════════
print("\n─── 5. RF AUTH BYPASS ───")

-- Пробуем получить данные другого игрока
test("GetAPlayerData (другой игрок)", function()
    -- Ищем других игроков в игре
    local others = {}
    for _, p in ipairs(game:GetService("Players"):GetPlayers()) do
        if p ~= LP then others[#others+1] = p.UserId end
    end
    if #others > 0 then
        local ok, d = rf("GetAPlayerData", others[1])
        if ok and d then
            print("  !! Got data for UserId:", others[1])
            if type(d)=="table" then
                for k,v in pairs(d) do
                    if type(v)~="table" then print("   ", k, "=", v) end
                end
            end
        end
    else
        print("  (no other players in server)")
    end
end)

-- Cmdr (admin panel) - если открыт для всех
test("CmdrFunction give", function()
    pcall(function()
        local cmdr = RS.CmdrClient.CmdrFunction
        cmdr:InvokeServer("give coins 99999")
        cmdr:InvokeServer("give gems 99999")
        cmdr:InvokeServer("setcash 99999")
    end)
end)

-- ══════════════════════════════════════════════════════════════════
-- [6] PRESTIGE / REBIRTH БЕЗ ТРЕБОВАНИЙ
--     Если сервер не валидирует что игрок достиг нужного прогресса
-- ══════════════════════════════════════════════════════════════════
print("\n─── 6. PRESTIGE WITHOUT REQUIREMENTS ───")

test("Prestige x10 spam", function()
    for _=1,10 do fire("Prestige"); task.wait(0.05) end
end)

test("Rebirth x10 spam", function()
    for _=1,10 do fire("Rebirth"); task.wait(0.05) end
end)

test("Ascend / Transcend", function()
    fire("Ascend")
    fire("Transcend")
    fire("AscendPrestige")
    fire("PrestigeAscend")
    task.wait(0.1)
end)

-- ══════════════════════════════════════════════════════════════════
-- [7] DATASTORE KEY INJECTION
--     Если сервер делает DataStore:GetAsync(playerInput)
--     можно попробовать читать чужие данные
-- ══════════════════════════════════════════════════════════════════
print("\n─── 7. KEY INJECTION ───")

test("LoadProfile other user", function()
    fire("LoadProfile", "1")           -- userId как строка
    fire("LoadProfile", 1)             -- userId как число
    fire("GetProfile", 1)
    fire("LoadData", 1)
    task.wait(0.2)
end)

test("RedeemCode with inject", function()
    -- Иногда коды лежат в DataStore с ключём = код
    -- Если не валидируется — можно читать произвольные ключи
    fire("RedeemCode", "../")
    fire("RedeemCode", "Global_1")
    fire("UseCode", "Admin")
    fire("UseCode", "Debug")
    task.wait(0.2)
end)

-- ══════════════════════════════════════════════════════════════════
-- [8] DUPLICATE CLAIM
--     Получить одну и ту же разовую награду несколько раз
-- ══════════════════════════════════════════════════════════════════
print("\n─── 8. DUPLICATE CLAIM ───")

test("ClaimGuildWeeklyReward same slot x20", function()
    for _=1,20 do
        pcall(function() NET.ClaimGuildWeeklyReward:InvokeServer(1) end)
        task.wait(0.05)
    end
end)

test("ClaimAllGuildWeekly x5 rapid", function()
    for _=1,5 do
        task.spawn(function()
            pcall(function() NET.ClaimAllGuildWeeklyRewards:InvokeServer() end)
        end)
    end
    task.wait(0.3)
end)

-- ══════════════════════════════════════════════════════════════════
-- ИТОГ
-- ══════════════════════════════════════════════════════════════════
task.wait(1)
print("\n═══════ RESULTS ═══════")
if #results == 0 then
    print("  No stat changes detected")
else
    for _, r in ipairs(results) do
        print("  ★ " .. r)
    end
end
print("════════════════════════")
