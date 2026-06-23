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

    -- [РЕАЛЬНЫЕ — из live hook capture]

    -- OpenCapsule: игра шлёт ("Super", 1) → меняем на 9999
    -- РАБОТАЕТ: сервер принял 100, игра сама потом слала 100
    { action = "OpenCapsule", argIdx = 3, newVal = 9999 },

    -- BuyPotionTickets: количество строкой "x1" → "x999"
    { action = "BuyPotionTickets", argIdx = 3, newVal = "x999" },

    -- UsePotion: count=1 → 9999 (использовать 9999 зелий за клик)
    { action = "UsePotion", argIdx = 3, newVal = 9999 },

    -- OpenChest: если есть batch-параметр
    { action = "OpenChest", argIdx = 3, newVal = 9999 },

    -- UpgradeUpgradeMax: второй параметр — уровень/тип прокачки
    -- Оставляем как есть, не ломаем структуру

    -- BuyFactory: был bool "true" — оставляем
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
