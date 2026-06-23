-- ═══════════════════════════════════════════════════════════════════
--  HOOK CAPTURE — пишет ВСЁ что игра отправляет на сервер
--  Запусти → вручную открой Prism капсулу / получи питомца / итем
--  Через 90 сек выведет все уникальные вызовы с параметрами
-- ═══════════════════════════════════════════════════════════════════

local RS = game:GetService("ReplicatedStorage")
local MR = RS.__Net.MainRemote

local seen   = {}   -- key → {args, count}
local order  = {}   -- порядок первого появления

local function capture(...)
    local args = {...}
    local key  = table.concat(args, "|"):sub(1, 200)
    if not seen[key] then
        seen[key]  = {args = args, count = 0}
        order[#order+1] = key
        -- Сразу печатаем первое появление
        local parts = {}
        for _, v in ipairs(args) do parts[#parts+1] = tostring(v) end
        print("[LIVE] " .. table.concat(parts, "  ,  "))
    end
    seen[key].count = seen[key].count + 1
end

-- Хук через метатейбл
local hooked = false
pcall(function()
    local mt = getrawmetatable(MR)
    local orig = mt.__namecall
    setreadonly(mt, false)
    mt.__namecall = function(self, ...)
        if getnamecallmethod() == "FireServer" then
            pcall(capture, ...)
        end
        return orig(self, ...)
    end
    setreadonly(mt, true)
    hooked = true
end)

if not hooked then
    -- Fallback: direct wrap
    local orig = MR.FireServer
    MR.FireServer = function(self, ...)
        pcall(capture, ...)
        return orig(self, ...)
    end
    hooked = true
end

print("=== HOOK ACTIVE ===")
print("Играй вручную: открой Prism капсулу, получи питомца, итемы")
print("Через 90 сек покажу все уникальные вызовы")
print()

task.wait(90)

print("\n════ CAPTURED CALLS (" .. #order .. " unique) ════")
-- Сортируем по частоте (редкие сначала — они интереснее)
table.sort(order, function(a,b)
    return seen[a].count < seen[b].count
end)
for _, key in ipairs(order) do
    local e = seen[key]
    local parts = {}
    for _, v in ipairs(e.args) do parts[#parts+1] = tostring(v) end
    print(string.format("[x%d]  %s", e.count, table.concat(parts, "  ,  ")))
end
print("════════════════════════════════")
