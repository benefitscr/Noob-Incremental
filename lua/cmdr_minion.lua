-- ═══════════════════════════════════════════════════════════════════
--  CMDR + MODULE READER + AUTO-OPENER  @Benefit
--  1. Пробуем GiveMinion через CmdrFunction
--  2. Читаем Capsules/Minions ModuleScript
--  3. Дамп GameMinions папки
--  4. autoOpen с правильным кулдауном 1.5s
-- ═══════════════════════════════════════════════════════════════════

local RS  = game:GetService("ReplicatedStorage")
local LP  = game:GetService("Players").LocalPlayer
local MR  = RS.__Net.MainRemote

local function fire(...) pcall(MR.FireServer, MR, ...) end
local username = LP.Name

-- ══════════════════════════════════════════════════════════════════
-- [1] CMDR — пробуем GiveMinion команду
-- ══════════════════════════════════════════════════════════════════
print("[CMDR] Trying GiveMinion command...")

local cmdrFn = RS.CmdrClient.CmdrFunction
local cmdrEv = RS.CmdrClient.CmdrEvent

-- Форматы команды Cmdr (разные варианты синтаксиса)
local CMDR_ATTEMPTS = {
    "giveminion " .. username .. " 2-E",
    "giveminion " .. username .. " 2-G",
    "GiveMinion " .. username .. " 2-E",
    "GiveMinion " .. username .. " G",
    "give minion " .. username .. " 2-E",
    "giveminion " .. username .. " 2-E Legendary",
    "giveminion " .. username .. " 2-E 100",
}

for _, cmd in ipairs(CMDR_ATTEMPTS) do
    local ok, result = pcall(function()
        return cmdrFn:InvokeServer(cmd)
    end)
    if ok and result then
        print("[CMDR] ★ Got response for: " .. cmd)
        print("  → " .. tostring(result):sub(1, 200))
    else
        print("[CMDR] no response: " .. cmd)
    end
    task.wait(0.1)
end

-- Пробуем через Event тоже
pcall(function()
    cmdrEv:FireServer("giveminion " .. username .. " 2-E")
    task.wait(0.3)
    cmdrEv:FireServer("giveminion " .. username .. " 2-G")
end)

-- ══════════════════════════════════════════════════════════════════
-- [2] ЧИТАЕМ ModuleScript источники
-- ══════════════════════════════════════════════════════════════════
print("\n[MODULE] Reading Capsules module...")
pcall(function()
    local m = RS.Shared.Modules.Capsules
    local ok, src = pcall(function() return m.Source end)
    if ok and src and src ~= "" then
        print("[CAPSULES SRC] " .. src:sub(1, 1000))
    else
        -- Пробуем require
        local ok2, data = pcall(require, m)
        if ok2 and data then
            print("[CAPSULES REQ] type=" .. type(data))
            if type(data) == "table" then
                for k, v in pairs(data) do
                    if type(v) ~= "table" and type(v) ~= "function" then
                        print("  " .. tostring(k) .. " = " .. tostring(v))
                    elseif type(v) == "table" then
                        print("  [table] " .. tostring(k))
                        for k2, v2 in pairs(v) do
                            if type(v2) ~= "table" and type(v2) ~= "function" then
                                print("    " .. tostring(k2) .. " = " .. tostring(v2))
                            end
                        end
                    end
                end
            end
        else
            print("[CAPSULES] No source, require failed: " .. tostring(data))
        end
    end
end)

print("\n[MODULE] Reading Minions module...")
pcall(function()
    local m = RS.Shared.Modules.Minions
    local ok, src = pcall(function() return m.Source end)
    if ok and src and src ~= "" then
        print("[MINIONS SRC] " .. src:sub(1, 1000))
    else
        local ok2, data = pcall(require, m)
        if ok2 and data then
            print("[MINIONS REQ] type=" .. type(data))
            if type(data) == "table" then
                for k, v in pairs(data) do
                    if type(v) ~= "table" and type(v) ~= "function" then
                        print("  " .. tostring(k) .. " = " .. tostring(v))
                    elseif type(v) == "table" and k:lower():find("rarity") then
                        print("  [RARITY] " .. tostring(k) .. ":")
                        for r, w in pairs(v) do
                            print("    " .. tostring(r) .. " = " .. tostring(w))
                        end
                    end
                end
            end
        end
    end
end)

print("\n[MODULE] Reading GiveMinion Cmdr command...")
pcall(function()
    local m = RS.CmdrClient.Commands.GiveMinion
    local ok, src = pcall(function() return m.Source end)
    if ok and src and src ~= "" then
        print("[GIVEMINION SRC]\n" .. src:sub(1, 800))
    else
        local ok2, data = pcall(require, m)
        if ok2 then print("[GIVEMINION REQ] ok, type=" .. type(data)) end
    end
end)

-- ══════════════════════════════════════════════════════════════════
-- [3] DUMP GameMinions FOLDER
-- ══════════════════════════════════════════════════════════════════
print("\n[GAME] GameMinions folder contents:")
pcall(function()
    local gm = RS.GameMinions
    local function dumpFolder(folder, prefix)
        prefix = prefix or ""
        for _, child in ipairs(folder:GetChildren()) do
            local val = ""
            pcall(function() val = " = " .. tostring(child.Value) end)
            print("[GM] " .. prefix .. child.Name .. " [" .. child.ClassName .. "]" .. val)
            if #child:GetChildren() > 0 then
                dumpFolder(child, prefix .. child.Name .. ".")
            end
        end
    end
    dumpFolder(gm)
end)

-- ══════════════════════════════════════════════════════════════════
-- [4] AUTO-OPENER с правильным кулдауном 1.5s
-- ══════════════════════════════════════════════════════════════════
print("\n[OPEN] autoOpen ready — call: autoOpen('Super', 100)")

local openCount = 0
RS.__Net.MinionCapsuleOpened.OnClientEvent:Connect(function(_, minions)
    openCount = openCount + 1
    local leg = 0
    for _, m in ipairs(minions or {}) do
        if m.rarity == "Legendary" or m.rarity == "Mythical"
        or m.rarity == "Secret"   or m.rarity == "Rainbow" then
            leg = leg + 1
            print("[RARE] " .. m.name .. " (" .. m.rarity .. ") from open #" .. openCount)
        end
    end
end)

function autoOpen(capType, count)
    capType = capType or "Super"
    count   = count   or 50
    print(string.format("[OPEN] Starting: %d x %s (cooldown 1.55s)", count, capType))
    local done = 0
    while done < count do
        fire("OpenCapsule", capType, 1)
        done = done + 1
        if done % 10 == 0 then
            print(string.format("[OPEN] %d/%d  rare=%d", done, count, 0))
        end
        task.wait(1.55)
    end
    print("[OPEN] Done. Total opens confirmed by server: " .. openCount)
end
