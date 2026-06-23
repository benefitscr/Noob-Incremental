-- ═══════════════════════════════════════════════════════════════════
--  CAPSULE DEEP AUDIT  @Benefit
--  1. Логируем что сервер шлёт назад при открытии (MinionCapsuleOpened)
--  2. Ищем дроп-таблицы в клиентской памяти
--  3. Проверяем bulk-open механику
--  4. Тестируем rate limit на спаме x1
--  5. Ищем LocalScript который обрабатывает результат
-- ═══════════════════════════════════════════════════════════════════

local RS  = game:GetService("ReplicatedStorage")
local LP  = game:GetService("Players").LocalPlayer
local MR  = RS.__Net.MainRemote
local NET = RS.__Net

local function fire(...) pcall(MR.FireServer, MR, ...) end

-- ══════════════════════════════════════════════════════════════════
-- [1] HOOK MinionCapsuleOpened — что сервер возвращает
-- ══════════════════════════════════════════════════════════════════
print("[CAP] Hooking MinionCapsuleOpened...")

local function deepPrint(v, prefix, depth)
    depth = depth or 0
    if depth > 4 then return end
    prefix = prefix or ""
    local t = type(v)
    if t == "table" then
        for k, val in pairs(v) do
            deepPrint(val, prefix .. tostring(k) .. ".", depth+1)
        end
    elseif t == "userdata" then
        pcall(function()
            print(prefix .. " [Instance:" .. v.ClassName .. "] " .. v.Name)
        end)
    else
        print(prefix .. tostring(v))
    end
end

NET.MinionCapsuleOpened.OnClientEvent:Connect(function(...)
    local args = {...}
    print("\n[SERVER→CLIENT] MinionCapsuleOpened fired:")
    for i, v in ipairs(args) do
        print("  arg" .. i .. " type=" .. type(v))
        deepPrint(v, "    ", 0)
    end
end)

-- Также ChestOpened
NET.ChestOpened.OnClientEvent:Connect(function(...)
    local args = {...}
    print("\n[SERVER→CLIENT] ChestOpened fired:")
    for i, v in ipairs(args) do
        print("  arg" .. i .. " type=" .. type(v))
        deepPrint(v, "    ", 0)
    end
end)

print("[CAP] Hooks active — открой капсулу вручную чтобы увидеть данные")

-- ══════════════════════════════════════════════════════════════════
-- [2] ПОИСК ДРО-ТАБЛИЦ В КЛИЕНТСКОЙ ПАМЯТИ
--     ModuleScript/LocalScript с весами дропа
-- ══════════════════════════════════════════════════════════════════
print("\n[CAP] Scanning for drop tables in client scripts...")

local function scanForDropData(src, scriptName)
    if not src or src == "" then return end
    -- Ищем таблицы с вероятностями / rare / weight / chance
    local patterns = {
        "chance%s*=", "weight%s*=", "probability%s*=",
        "rarity%s*=", "Rare%s*=",  "Common%s*=",
        "dropTable", "DropTable", "DROPS", "Drops",
        "OpenCapsule", "MinionCapsule", "CapsuleData",
        "rollItem", "RollItem", "getReward", "GetReward",
    }
    local hits = {}
    for _, p in ipairs(patterns) do
        if src:find(p) then
            hits[#hits+1] = p
        end
    end
    if #hits > 0 then
        print("[DROPTABLE] " .. scriptName .. " → " .. table.concat(hits, ", "))
        -- Вытащить числа рядом со словом chance/weight
        for num in src:gmatch("chance%s*=%s*([%d%.]+)") do
            print("  chance value: " .. num)
        end
        for num in src:gmatch("weight%s*=%s*([%d%.]+)") do
            print("  weight value: " .. num)
        end
    end
end

local function scanAll(container, prefix)
    for _, obj in ipairs(container:GetDescendants()) do
        if obj:IsA("LocalScript") or obj:IsA("ModuleScript") then
            local ok, src = pcall(function() return obj.Source end)
            if ok and src and src ~= "" then
                scanForDropData(src, (prefix or "") .. obj:GetFullName())
            end
        end
    end
end

pcall(scanAll, LP.PlayerGui, "GUI:")
pcall(scanAll, game:GetService("ReplicatedFirst"), "RF:")
pcall(scanAll, RS, "RS:")

-- ══════════════════════════════════════════════════════════════════
-- [3] ПОИСК CAPSULE DATA В REPLICATEDSTORAGE
--     Иногда дроп-таблицы хранятся как ModuleScript или Value
-- ══════════════════════════════════════════════════════════════════
print("\n[CAP] Scanning ReplicatedStorage for capsule/minion config...")

local function scanRS(obj, depth)
    depth = depth or 0
    if depth > 5 then return end
    local name = obj.Name:lower()
    if name:find("capsule") or name:find("minion") or name:find("drop")
    or name:find("reward") or name:find("rarity") or name:find("chest") then
        print("[RS] " .. obj:GetFullName() .. " [" .. obj.ClassName .. "]")
        -- Если это ModuleScript — читаем
        if obj:IsA("ModuleScript") then
            local ok, src = pcall(function() return obj.Source end)
            if ok and src then
                print("  Source preview: " .. src:sub(1, 300))
            end
        end
        -- Если папка/model — дамп children
        if obj:IsA("Folder") or obj:IsA("Model") or obj:IsA("Configuration") then
            for _, child in ipairs(obj:GetChildren()) do
                print("  child: " .. child.Name .. " [" .. child.ClassName .. "]")
                if child:IsA("NumberValue") or child:IsA("StringValue") then
                    print("    .Value = " .. tostring(child.Value))
                end
            end
        end
    end
    for _, child in ipairs(obj:GetChildren()) do
        pcall(scanRS, child, depth+1)
    end
end

pcall(scanRS, RS)

-- ══════════════════════════════════════════════════════════════════
-- [4] BULK OPEN — RATE LIMIT TEST
--     Спамим OpenCapsule x1 как можно быстрее
--     Считаем сколько реально сервер обработал
-- ══════════════════════════════════════════════════════════════════
print("\n[CAP] Rate limit test — spam OpenCapsule x1 for 3 seconds...")

local openCount = 0
NET.MinionCapsuleOpened.OnClientEvent:Connect(function()
    openCount = openCount + 1
end)

local CAP_TYPE = "Super"  -- меняй на свой тип
local sentCount = 0
local startT = tick()

-- 3 секунды спама
while tick() - startT < 3 do
    fire("OpenCapsule", CAP_TYPE, 1)
    sentCount = sentCount + 1
    task.wait()  -- минимальный yield, ~1 frame
end

task.wait(1)  -- ждём последних ответов от сервера
print(string.format("[RATELIMIT] Sent: %d  |  Server processed: %d  |  Rate: %.1f/s",
    sentCount, openCount, openCount / 3))

if sentCount > openCount * 2 then
    print("[RATELIMIT] ★ Server processed LESS than sent — rate limited or inventory cap")
else
    print("[RATELIMIT] Server processed ~all requests")
end

-- ══════════════════════════════════════════════════════════════════
-- [5] НАЙТИ КАК ИГРА ХРАНИТ КОЛ-ВО КАПСУЛ НА КЛИЕНТЕ
-- ══════════════════════════════════════════════════════════════════
print("\n[CAP] Looking for capsule inventory in LP.FEATURES...")

pcall(function()
    local function dumpFolder(folder, prefix)
        for _, obj in ipairs(folder:GetChildren()) do
            local n = obj.Name:lower()
            if n:find("capsule") or n:find("minion") or n:find("chest") then
                local val = ""
                pcall(function() val = " = " .. tostring(obj.Value) end)
                print("[INV] " .. (prefix or "") .. obj.Name .. " [" .. obj.ClassName .. "]" .. val)
                -- Dump children если папка
                if #obj:GetChildren() > 0 then
                    dumpFolder(obj, (prefix or "") .. obj.Name .. ".")
                end
            end
        end
    end
    dumpFolder(LP.FEATURES)
end)

-- Также LP.PlayerData если есть
pcall(function()
    local pd = LP:FindFirstChild("PlayerData")
    if pd then
        for _, obj in ipairs(pd:GetDescendants()) do
            local n = obj.Name:lower()
            if n:find("capsule") or n:find("minion") then
                print("[PD] " .. obj:GetFullName() .. " = " .. tostring((pcall(function() return obj.Value end))))
            end
        end
    end
end)

print("\n[CAP] AUDIT DONE")
print("Теперь открой капсулу вручную — увидишь что сервер шлёт назад")
