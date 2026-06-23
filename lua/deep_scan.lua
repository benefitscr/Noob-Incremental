-- ═══════════════════════════════════════════════════════════════════
--  DEEP SCAN  @Benefit
--  Ищем что-то интересное в местах которые ещё не смотрели
-- ═══════════════════════════════════════════════════════════════════

local RS  = game:GetService("ReplicatedStorage")
local LP  = game:GetService("Players").LocalPlayer
local NET = RS.__Net

local function p(...)  print(...) end
local function h(s) p("\n══════ "..s.." ══════") end

-- ══════════════════════════════════════════════════════════════════
-- [1] _G И shared — глобальные переменные
-- ══════════════════════════════════════════════════════════════════
h("_G SCAN")
local interesting_g = {}
for k, v in pairs(_G) do
    local t = type(v)
    if t == "function" or t == "table" then
        local s = tostring(k)
        -- Пропускаем стандартные lua/roblox globals
        if not s:match("^[a-z]") or s:find("admin") or s:find("give")
        or s:find("cheat") or s:find("debug") or s:find("dev")
        or s:find("god") or s:find("hack") then
            p("_G." .. s .. " [" .. t .. "]")
            table.insert(interesting_g, {k=k, v=v, t=t})
        end
    end
end

h("shared SCAN")
pcall(function()
    for k, v in pairs(shared) do
        p("shared." .. tostring(k) .. " [" .. type(v) .. "] = " .. tostring(v):sub(1,80))
    end
end)

-- ══════════════════════════════════════════════════════════════════
-- [2] FRAMEWORK MODULES — permission config, admin IDs
-- ══════════════════════════════════════════════════════════════════
h("FRAMEWORK MODULES")

local function dumpMod(path, name)
    local ok, m = pcall(require, path)
    if not ok then p("[" .. name .. "] require failed"); return end
    p("[" .. name .. "] type=" .. type(m))
    if type(m) ~= "table" then p("  " .. tostring(m):sub(1,200)); return end
    for k, v in pairs(m) do
        local t = type(v)
        if t ~= "function" then
            if t == "table" then
                p("  [table] " .. tostring(k))
                for k2, v2 in pairs(v) do
                    if type(v2) ~= "function" and type(v2) ~= "table" then
                        p("    " .. tostring(k2) .. " = " .. tostring(v2))
                    end
                end
            else
                p("  " .. tostring(k) .. " = " .. tostring(v))
            end
        end
    end
end

pcall(function()
    local fw = RS.Shared.Modules.Framework
    for _, child in ipairs(fw:GetDescendants()) do
        if child:IsA("ModuleScript") then
            p("\n--- " .. child.Name .. " ---")
            dumpMod(child, child.Name)
        end
    end
end)

-- ══════════════════════════════════════════════════════════════════
-- [3] GetAPlayerData — пробуем с реальными игроками в сервере
-- ══════════════════════════════════════════════════════════════════
h("GetAPlayerData RF DEEP DIVE")

local players = game:GetService("Players"):GetPlayers()
p("Players in server: " .. #players)

for _, player in ipairs(players) do
    p("\n[RF] GetAPlayerData for: " .. player.Name .. " (" .. player.UserId .. ")")
    local ok, data = pcall(function()
        return NET.GetAPlayerData:InvokeServer(player.UserId)
    end)
    if ok and data then
        p("  type=" .. type(data))
        if type(data) == "table" then
            for k, v in pairs(data) do
                if type(v) ~= "table" then
                    p("  " .. tostring(k) .. " = " .. tostring(v))
                else
                    p("  [table] " .. tostring(k))
                    for k2, v2 in pairs(v) do
                        if type(v2) ~= "table" then
                            p("    " .. tostring(k2) .. " = " .. tostring(v2))
                        end
                    end
                end
            end
        else
            p("  " .. tostring(data):sub(1,200))
        end
    else
        p("  ERR: " .. tostring(data):sub(1,100))
    end
    -- Также пробуем с именем
    local ok2, data2 = pcall(function()
        return NET.GetAPlayerData:InvokeServer(player.Name)
    end)
    if ok2 and data2 and type(data2) == "table" then
        p("  [by name] got table with " .. #(data2 or {}) .. " entries")
    end
end

-- ══════════════════════════════════════════════════════════════════
-- [4] BindableEvent / BindableFunction в PlayerGui
-- ══════════════════════════════════════════════════════════════════
h("BINDABLE SCAN")

local function scanBindables(container, prefix)
    for _, obj in ipairs(container:GetDescendants()) do
        if obj:IsA("BindableEvent") or obj:IsA("BindableFunction") then
            p("[BIND] " .. (prefix or "") .. obj:GetFullName() .. " [" .. obj.ClassName .. "]")
            -- Пробуем вызвать BindableFunction
            if obj:IsA("BindableFunction") then
                local ok, r = pcall(function() return obj:Invoke() end)
                if ok and r ~= nil then
                    p("  Invoke() → " .. tostring(r):sub(1,100))
                end
                -- С разными аргументами
                for _, arg in ipairs({"admin","give","max","all",true,99999}) do
                    local ok2, r2 = pcall(function() return obj:Invoke(arg) end)
                    if ok2 and r2 ~= nil then
                        p("  Invoke(" .. tostring(arg) .. ") → " .. tostring(r2):sub(1,100))
                    end
                end
            end
        end
    end
end

pcall(scanBindables, LP.PlayerGui, "GUI:")
pcall(scanBindables, RS, "RS:")
pcall(scanBindables, game:GetService("ReplicatedFirst"), "RF:")

-- ══════════════════════════════════════════════════════════════════
-- [5] TycoonDrop — что летит с сервера
-- ══════════════════════════════════════════════════════════════════
h("TycoonDrop EVENT DATA")

NET.TycoonDrop.OnClientEvent:Connect(function(...)
    local args = {...}
    p("[TycoonDrop] " .. #args .. " args:")
    for i, v in ipairs(args) do
        p("  arg" .. i .. " [" .. type(v) .. "] = " .. tostring(v):sub(1,100))
        if type(v) == "table" then
            for k2, v2 in pairs(v) do
                p("    " .. tostring(k2) .. " = " .. tostring(v2))
            end
        end
    end
end)
p("[TycoonDrop] Hook active — ждём дроп из тайкуна")

-- ══════════════════════════════════════════════════════════════════
-- [6] ПРОВЕРЯЕМ ЕСТЬ ЛИ ADMIN ИГРОКИ В СЕРВЕРЕ
--     GetVerifiedBadge RF — можно ли узнать кто верифицирован
-- ══════════════════════════════════════════════════════════════════
h("ADMIN DETECTION")

pcall(function()
    for _, player in ipairs(game:GetService("Players"):GetPlayers()) do
        -- Проверяем через GetAPlayerData или любой другой способ
        -- определить является ли кто-то в сервере разработчиком
        local ok, badge = pcall(function()
            return NET.GetVerifiedBadge:InvokeServer(player.UserId)
        end)
        if ok then
            p("[BADGE] " .. player.Name .. " → " .. tostring(badge))
        end
    end
end)

-- Также смотрим PublicMembersOnly / GroupId через GroupService
pcall(function()
    local GS = game:GetService("GroupService")
    -- ID разработчиков игры часто в группе — пробуем найти group ID из игры
    -- PlaceId → Owner группа
    local info = GS:GetGroupInfoAsync(game.CreatorId)
    if info then
        p("[GROUP] Game creator: " .. tostring(info.Name))
        p("[GROUP] Owner: " .. tostring(info.Owner and info.Owner.Name))
    end
end)

-- ══════════════════════════════════════════════════════════════════
-- [7] LocalScript source — ищем оставленный debug-код
-- ══════════════════════════════════════════════════════════════════
h("DEBUG CODE IN LOCALSCRIPTS")

local DEBUG_PATTERNS = {
    "admin", "cheat", "debug", "backdoor",
    "bypass", "god", "give", "hack",
    "PermissionLevel", "IsAdmin", "adminIds",
    "ADMIN_IDS", "AdminList", "owners",
}

local function scanDebug(container)
    for _, obj in ipairs(container:GetDescendants()) do
        if obj:IsA("LocalScript") or obj:IsA("ModuleScript") then
            local ok, src = pcall(function() return obj.Source end)
            if ok and src then
                for _, pat in ipairs(DEBUG_PATTERNS) do
                    local idx = src:lower():find(pat:lower(), 1, true)
                    if idx then
                        p("[DEBUG] " .. obj:GetFullName() .. " contains '" .. pat .. "'")
                        p("  " .. src:sub(math.max(1,idx-30), idx+100):gsub("\n"," "))
                        break
                    end
                end
            end
        end
    end
end

pcall(scanDebug, LP.PlayerGui)
pcall(scanDebug, RS)
pcall(scanDebug, game:GetService("ReplicatedFirst"))

p("\n=== DEEP SCAN DONE ===")
