-- FULL MAINREMOTE ACTION HOOK  @Benefit
-- Ловим ВСЕ action-имена которые летят на сервер
-- Дедупликация — каждое имя выводим только 1 раз + аргументы
local RS = game:GetService("ReplicatedStorage")
local LP = game:GetService("Players").LocalPlayer
local MR = RS.__Net.MainRemote

local seen    = {}
local log     = {}

print("[HOOK] Перехват всех FireServer на MainRemote — 60 секунд")
print("[HOOK] Кликай ВСЁ: экспедиции, квесты, рунный зал, тайкун, магазин, капсулы!")
print("[HOOK] Каждое уникальное action-имя будет показано один раз\n")

local orig = getrawmetatable(game)
local old_nc = orig.__namecall
setreadonly(orig, false)
orig.__namecall = newcclosure(function(self, ...)
    local method = getnamecallmethod()
    if method == "FireServer" and self == MR then
        local args = {...}
        local action = tostring(args[1] or "")
        if not seen[action] then
            seen[action] = true
            local parts = {"[ACTION] " .. action}
            for i = 2, #args do
                local v = args[i]
                local s = type(v) == "table"
                    and ("{" .. table.concat((function()
                            local t={}
                            for k2,v2 in pairs(v) do
                                t[#t+1] = tostring(k2).."="..tostring(v2)
                            end
                            return t
                        end)(), ", ") .. "}")
                    or tostring(v):sub(1,60)
                parts[#parts+1] = "  arg" .. i .. " [" .. type(v) .. "] = " .. s
            end
            for _, line in ipairs(parts) do print(line) end
            table.insert(log, action)
        end
    end
    return old_nc(self, ...)
end)
setreadonly(orig, true)

task.wait(60)

local orig2 = getrawmetatable(game)
setreadonly(orig2, false)
orig2.__namecall = old_nc
setreadonly(orig2, true)

print("\n══════ UNIQUE ACTIONS SEEN ══════")
print(table.concat(log, "\n"))
print("\nTotal unique: " .. #log)

-- ══════════════════════════════════════════════════════════════════
-- После hook — читаем expedition rewards снова (накопились?)
-- ══════════════════════════════════════════════════════════════════
print("\n══════ EXPEDITION REWARDS NOW ══════")
local exped = LP.FEATURES:FindFirstChild("EXPEDITIONS")
if exped then
    for _, zone in ipairs(exped:GetChildren()) do
        if zone:IsA("Folder") then
            local pending = zone:FindFirstChild("PendingRewards")
            if pending then
                local total = 0
                for _, r in ipairs(pending:GetChildren()) do
                    local ok, v = pcall(function() return r.Value end)
                    if ok then total = total + (tonumber(tostring(v)) or 0) end
                end
                if total > 0 then
                    print("[" .. zone.Name .. "] HAS REWARDS:")
                    for _, r in ipairs(pending:GetChildren()) do
                        local ok, v = pcall(function() return r.Value end)
                        if ok and (tonumber(tostring(v)) or 0) > 0 then
                            print("  " .. r.Name .. " = " .. tostring(v))
                        end
                    end
                else
                    print("[" .. zone.Name .. "] empty")
                end
            end
        end
    end
end
