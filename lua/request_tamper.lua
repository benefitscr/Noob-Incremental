-- ═══════════════════════════════════════════════════════════════════
--  REQUEST TAMPER — перехват и подмена аргументов на сервер
--
--  Работает через __namecall hook:
--  Игра вызывает FireServer("BuyItem","Coins",100)
--  Мы подменяем на FireServer("BuyItem","Coins",-999)
--  до того как пакет уходит — сервер получает наши данные
-- ═══════════════════════════════════════════════════════════════════

local RS = game:GetService("ReplicatedStorage")
local MR = RS.__Net.MainRemote

-- ─── ПРАВИЛА ПОДМЕНЫ ───────────────────────────────────────────────
--  Каждое правило: { action, argIndex, oldVal→newVal }
--  argIndex = 1 это сам action, 2 = первый доп аргумент, и т.д.
--  match = nil → срабатывает на любое значение этого аргумента

local TAMPER_RULES = {

    -- [1] Подмена количества при покупке: cost 100 → -100
    --     Сервер: price = args[3]; currency -= price  → += price
    { action = "BuyItem",      argIdx = 3, newVal = -math.huge },
    { action = "Purchase",     argIdx = 2, newVal = -math.huge },
    { action = "Buy",          argIdx = 3, newVal = -math.huge },
    { action = "ShopBuy",      argIdx = 3, newVal = -math.huge },

    -- [2] Подмена кол-ва капсул при batch-open
    --     Если игра шлёт OpenCapsule("Prism", 1) → меняем на 9999
    { action = "OpenCapsule",      argIdx = 3, oldVal = 1, newVal = 9999 },
    { action = "OpenCapsule",      argIdx = 3, oldVal = nil, newVal = 100 },
    { action = "OpenMinionCapsule",argIdx = 3, newVal = 9999 },
    { action = "OpenChest",        argIdx = 3, oldVal = nil, newVal = 100 },

    -- [3] Подмена уровня при upgrade
    --     UpgradeNoob("Fire", 1) → UpgradeNoob("Fire", 9999)
    { action = "UpgradeNoob",  argIdx = 3, newVal = 9999 },
    { action = "UpgradeLevel", argIdx = 3, newVal = 9999 },

    -- [4] Подмена валюты при транзакции
    --     Если сервер принимает тип валюты как аргумент
    { action = "SpendCurrency", argIdx = 2, newVal = "FakeCoin" },

    -- [5] Подмена tier при roll (роллим лучший tier)
    --     RollTier("Common") → RollTier("Legendary")
    { action = "RollTier",  argIdx = 2, newVal = "Legendary" },
    { action = "RollTier",  argIdx = 2, newVal = "Divine"    },

    -- [6] При redeemCode — пробуем подставить известные коды
    { action = "RedeemCode", argIdx = 2, newVal = "ADMIN"   },
    { action = "UseCode",    argIdx = 2, newVal = "DEBUG"   },
    { action = "ClaimCode",  argIdx = 2, newVal = "INTERNAL"},
}

-- Быстрый поиск правил по action + argIdx
local ruleMap = {}
for _, rule in ipairs(TAMPER_RULES) do
    local k = rule.action
    if not ruleMap[k] then ruleMap[k] = {} end
    ruleMap[k][#ruleMap[k]+1] = rule
end

-- ─── HOOK ──────────────────────────────────────────────────────────
local hooked   = false
local tampered = {}   -- action → count
local logged   = {}   -- для дедупа лога

local function applyTamper(args)
    local action = tostring(args[1])
    local rules  = ruleMap[action]
    if not rules then return args end

    local modified = false
    for _, rule in ipairs(rules) do
        local idx = rule.argIdx
        if idx <= #args + 1 then
            -- Проверяем oldVal (nil = любое)
            if rule.oldVal == nil or args[idx] == rule.oldVal then
                args[idx] = rule.newVal
                modified   = true
                tampered[action] = (tampered[action] or 0) + 1
                -- Лог первого случая
                local logKey = action..tostring(idx)
                if not logged[logKey] then
                    logged[logKey] = true
                    local parts = {}
                    for _, v in ipairs(args) do parts[#parts+1] = tostring(v) end
                    print("[TAMPER] "..table.concat(parts, " , "))
                end
            end
        end
    end
    return args, modified
end

pcall(function()
    local mt   = getrawmetatable(MR)
    local orig = mt.__namecall
    setreadonly(mt, false)
    mt.__namecall = function(self, ...)
        local args = {...}
        if getnamecallmethod() == "FireServer" then
            applyTamper(args)
            return orig(self, table.unpack(args))
        end
        return orig(self, table.unpack(args))
    end
    setreadonly(mt, true)
    hooked = true
end)

if not hooked then
    local orig = MR.FireServer
    MR.FireServer = function(self, ...)
        local args = {...}
        applyTamper(args)
        return orig(self, table.unpack(args))
    end
    hooked = true
end

print("[TAMPER] Hook active —", hooked and "OK" or "FAILED")
print("[TAMPER] Теперь все вызовы игры проходят через фильтр")
print("[TAMPER] При покупке/открытии — аргументы подменяются")
print()
print("Добавить правило вручную:")
print("  TAMPER_RULES[#TAMPER_RULES+1] = {action='X', argIdx=2, newVal=-999}")

-- ─── СТАТУС КАЖДЫЕ 30 СЕК ──────────────────────────────────────────
task.spawn(function()
    while true do
        task.wait(30)
        local total = 0
        for a, c in pairs(tampered) do
            print(string.format("[TAMPER] %s: %d подмен", a, c))
            total = total + c
        end
        if total > 0 then
            print("[TAMPER] Итого подмен: "..total)
        end
    end
end)
