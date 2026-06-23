-- ═══════════════════════════════════════════════════════════════════
--  CMDR DEEP + CAPSULE DROP TABLE  @Benefit
-- ═══════════════════════════════════════════════════════════════════

local RS  = game:GetService("ReplicatedStorage")
local LP  = game:GetService("Players").LocalPlayer
local username = LP.Name
local cmdrFn = RS.CmdrClient.CmdrFunction

local function cmdr(cmd)
    local ok, r = pcall(function() return cmdrFn:InvokeServer(cmd) end)
    if ok and r then
        print("[CMDR] \"" .. cmd .. "\"\n  → " .. tostring(r):sub(1,120))
    end
    return ok, r
end

-- ══════════════════════════════════════════════════════════════════
-- [1] ПРАВИЛЬНЫЕ ИМЕНА МИНЬОНОВ (без "2-" префикса)
--     Из MinionModels: A B C D E F G E-A E-B E-C E-D
-- ══════════════════════════════════════════════════════════════════
print("[CMDR] Testing valid minion names...")

local VALID_NAMES = {"A","B","C","D","E","F","G","E-A","E-B","E-C","E-D"}

for _, name in ipairs(VALID_NAMES) do
    cmdr("giveminion " .. username .. " " .. name)
    task.wait(0.1)
end

-- С autoEquip=true
print("\n[CMDR] With autoequip=true...")
for _, name in ipairs({"G","E-D","F","E"}) do
    cmdr("giveminion " .. username .. " " .. name .. " true")
    task.wait(0.1)
end

-- ══════════════════════════════════════════════════════════════════
-- [2] CMDR: ДРУГИЕ КОМАНДЫ — что ещё доступно без прав
-- ══════════════════════════════════════════════════════════════════
print("\n[CMDR] Probing other commands...")

local OTHER_CMDS = {
    "help",
    "give " .. username .. " coins 99999",
    "givecurrency " .. username .. " coins 99999",
    "setlevel " .. username .. " 999",
    "unlock " .. username .. " all",
    "giverune " .. username .. " Master",
    "giveequipment " .. username .. " Best",
    "setstat " .. username .. " coins 99999",
    "god " .. username,
    "admin " .. username,
    "promote " .. username,
}
for _, cmd in ipairs(OTHER_CMDS) do
    cmdr(cmd)
    task.wait(0.05)
end

-- ══════════════════════════════════════════════════════════════════
-- [3] ЧИТАЕМ Capsules.List — ДРОП-ТАБЛИЦА
-- ══════════════════════════════════════════════════════════════════
print("\n[DROP] Reading Capsules drop table...")

local function dumpDeep(tbl, prefix, depth)
    depth = depth or 0
    if depth > 5 then return end
    prefix = prefix or ""
    if type(tbl) ~= "table" then
        print(prefix .. tostring(tbl))
        return
    end
    for k, v in pairs(tbl) do
        if type(v) == "table" then
            print(prefix .. tostring(k) .. ":")
            dumpDeep(v, prefix .. "  ", depth+1)
        elseif type(v) ~= "function" then
            print(prefix .. tostring(k) .. " = " .. tostring(v))
        end
    end
end

pcall(function()
    local capMod = require(RS.Shared.Modules.Capsules)
    print("[DROP] Capsules.List contents:")
    dumpDeep(capMod.List, "  ")
end)

-- ══════════════════════════════════════════════════════════════════
-- [4] ЧИТАЕМ MinionName Type — список валидных имён
-- ══════════════════════════════════════════════════════════════════
print("\n[MINION] Reading MinionName type list...")
pcall(function()
    local t = require(RS.CmdrClient.Types.MinionName)
    print("[MINION TYPE] result type:", type(t))
    dumpDeep(t, "  ")
end)

-- ══════════════════════════════════════════════════════════════════
-- [5] ЧИТАЕМ Minions модуль полностью
-- ══════════════════════════════════════════════════════════════════
print("\n[MINION] Reading Minions module fully...")
pcall(function()
    local m = require(RS.Shared.Modules.Minions)
    print("[MINIONS] Top-level keys:")
    for k, v in pairs(m) do
        if type(v) ~= "function" then
            print("  " .. tostring(k) .. " [" .. type(v) .. "]")
            if type(v) == "table" then
                -- Первые 5 записей
                local count = 0
                for k2, v2 in pairs(v) do
                    if count >= 10 then print("  ... (truncated)"); break end
                    if type(v2) ~= "function" then
                        print("    " .. tostring(k2) .. " = " .. tostring(v2))
                        count = count + 1
                    elseif type(v2) == "table" then
                        print("    [table] " .. tostring(k2))
                    end
                end
            end
        end
    end
end)
