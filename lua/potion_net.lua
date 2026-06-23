-- POTION + FULL NET SCAN  @Benefit
-- 1. Confirm Capacity=9999999 still persists
-- 2. Full NET dump — find ALL events incl. potion
-- 3. Hook ALL MainRemote traffic for 30s
-- 4. Try to exhaust TimeLeft manually (write 0) + see what server does
-- 5. GUILD_STATS_PENDING scan
local RS  = game:GetService("ReplicatedStorage")
local LP  = game:GetService("Players").LocalPlayer
local MR  = RS.__Net.MainRemote
local NET = RS.__Net

local function fire(...) pcall(MR.FireServer, MR, ...) end

-- ══════════════════════════════════════════════════════════════════
-- [1] Potion Capacity persist check
-- ══════════════════════════════════════════════════════════════════
print("══════ POTION CAPACITY CHECK ══════")
local potions = LP.EXTRA.MONETIZATION.POTIONS
for _, p in ipairs(potions:GetChildren()) do
    local tl  = p:FindFirstChild("TimeLeft")
    local cap = p:FindFirstChild("Capacity")
    print("[" .. p.Name .. "] TimeLeft=" .. tostring(tl and tl.Value)
          .. "  Capacity=" .. tostring(cap and cap.Value))
end

-- ══════════════════════════════════════════════════════════════════
-- [2] ПОЛНЫЙ дамп NET — все дети
-- ══════════════════════════════════════════════════════════════════
print("\n══════ FULL NET DUMP ══════")
local netChildren = {}
for _, ch in ipairs(NET:GetChildren()) do
    table.insert(netChildren, ch.Name .. " [" .. ch.ClassName .. "]")
end
table.sort(netChildren)
for _, n in ipairs(netChildren) do print(n) end

-- ══════════════════════════════════════════════════════════════════
-- [3] Potion-related NET events
-- ══════════════════════════════════════════════════════════════════
print("\n══════ POTION EVENTS SEARCH ══════")
for _, ch in ipairs(NET:GetChildren()) do
    local n = ch.Name:lower()
    if n:find("potion") or n:find("boost") or n:find("buff")
    or n:find("active") or n:find("pause") or n:find("timer")
    or n:find("expire") or n:find("charge") or n:find("duration") then
        print("[POTION-NET] " .. ch.Name .. " [" .. ch.ClassName .. "]")
        if ch:IsA("RemoteFunction") then
            local ok, r = pcall(function() return ch:InvokeServer() end)
            print("  → " .. tostring(r):sub(1,80))
        end
    end
end

-- ══════════════════════════════════════════════════════════════════
-- [4] Hook ALL MainRemote (30s) + TycoonDrop hook
-- ══════════════════════════════════════════════════════════════════
print("\n══════ FULL HOOK 30s ══════")
print("Все события сюда — роллируй руны, собирай с тайкуна!")

-- TycoonDrop hook
local dropCaught = nil
local dropConn = NET.TycoonDrop.OnClientEvent:Connect(function(...)
    local args = {...}
    print("[TYCOON DROP EVENT!] args=" .. #args)
    for i, v in ipairs(args) do
        print("  arg" .. i .. " [" .. type(v) .. "] = " .. tostring(v):sub(1,80))
    end
    dropCaught = args
end)

-- Hook MainRemote namecall
local orig = getrawmetatable(game)
local old_nc = orig.__namecall
setreadonly(orig, false)
orig.__namecall = newcclosure(function(self, ...)
    local method = getnamecallmethod()
    if (method == "FireServer" or method == "InvokeServer") and self == MR then
        local args = {...}
        local action = tostring(args[1] or "")
        -- Печатаем всё кроме SpamEvents
        if not action:find("Heartbeat") and not action:find("Ping") then
            print("[NET→SRV] " .. method .. " → " .. action)
            for i = 2, math.min(#args, 4) do
                print("  a" .. i .. "=" .. tostring(args[i]):sub(1,60))
            end
        end
    end
    return old_nc(self, ...)
end)
setreadonly(orig, true)

task.wait(30)

setreadonly(orig, false)
orig.__namecall = old_nc
setreadonly(orig, true)
dropConn:Disconnect()

-- ══════════════════════════════════════════════════════════════════
-- [5] WRITE TimeLeft=0 → что делает сервер?
--     Если потион истекает → сервер проверяет Capacity?
-- ══════════════════════════════════════════════════════════════════
print("\n══════ FORCE POTION EXPIRE ══════")
-- Пишем TimeLeft=0 для одного потиона
local p1 = potions:FindFirstChild("2x Rune Luck")
if p1 then
    local tl = p1:FindFirstChild("TimeLeft")
    if tl then
        local before = tl.Value
        pcall(function() tl.Value = 0 end)
        print("2x Rune Luck TimeLeft: " .. before .. " → " .. tostring(tl.Value))
        print("(Waiting 5s to see if server reloads/expires...)")
        task.wait(5)
        print("After 5s: TimeLeft=" .. tostring(tl.Value)
              .. "  Capacity=" .. tostring(p1:FindFirstChild("Capacity") and p1:FindFirstChild("Capacity").Value))
    end
end

-- ══════════════════════════════════════════════════════════════════
-- [6] GUILD_STATS_PENDING дамп
-- ══════════════════════════════════════════════════════════════════
print("\n══════ GUILD_STATS_PENDING ══════")
local pending = LP.EXTRA:FindFirstChild("GUILD_STATS_PENDING")
if pending then
    print("Children: " .. #pending:GetChildren())
    for _, ch in ipairs(pending:GetChildren()) do
        local ok, v = pcall(function() return ch.Value end)
        print("  " .. ch.Name .. " = " .. (ok and tostring(v) or "?"))
    end
end

-- ══════════════════════════════════════════════════════════════════
-- [7] LP root folder full scan — что ещё не исследовали
-- ══════════════════════════════════════════════════════════════════
print("\n══════ LP ROOT FOLDERS ══════")
for _, ch in ipairs(LP:GetChildren()) do
    local childCount = #ch:GetChildren()
    local ok, v = pcall(function() return ch.Value end)
    if ok then
        print("[LP] " .. ch.Name .. " = " .. tostring(v))
    else
        print("[LP] " .. ch.Name .. " [" .. ch.ClassName .. "] (" .. childCount .. " children)")
        -- Первый уровень для папок с контентом
        if childCount > 0 and childCount <= 10 then
            for _, c2 in ipairs(ch:GetChildren()) do
                local ok2, v2 = pcall(function() return c2.Value end)
                print("  " .. c2.Name .. " = " .. (ok2 and tostring(v2) or "[folder:" .. #c2:GetChildren() .. "]"))
            end
        end
    end
end

print("\n=== DONE ===")
