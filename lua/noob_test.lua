-- Noob Upgrade Test  @Benefit
-- Проверяем что UpgradeNoobMax принимает Magician и Hacker 1-4
local RS = game:GetService("ReplicatedStorage")
local LP = game:GetService("Players").LocalPlayer
local MR = RS.__Net.MainRemote

-- Читаем XP/уровень нубов ДО
local function getNoobLevel(name)
    local noobF = LP.FEATURES:FindFirstChild("NOOBS")
    if not noobF then return nil end
    local n = noobF:FindFirstChild(name)
    if not n then return nil end
    local lv = n:FindFirstChild("Level") or n:FindFirstChild("XP") or n:FindFirstChild("Amount")
    return lv and lv.Value
end

local TEST_NOOBS = {"Magician","Hacker 1","Hacker 2","Hacker 3","Hacker 4"}

print("=== NOOB UPGRADE TEST ===")
print("--- before ---")
for _, n in ipairs(TEST_NOOBS) do
    print(n .. " = " .. tostring(getNoobLevel(n)))
end

-- Хукаем чтобы видеть что реально уходит на сервер
local fired = {}
local orig = getrawmetatable(game)
local old_nc = orig.__namecall
setreadonly(orig, false)
orig.__namecall = newcclosure(function(self, ...)
    local method = getnamecallmethod()
    if method == "FireServer" and self == MR then
        local args = {...}
        local action = tostring(args[1] or "")
        if action:find("Noob") or action:find("noob") then
            print("[HOOK] " .. action .. " arg2=" .. tostring(args[2]))
            fired[#fired+1] = action
        end
    end
    return old_nc(self, ...)
end)
setreadonly(orig, true)

-- Стреляем UpgradeNoobMax для каждого
for _, n in ipairs(TEST_NOOBS) do
    pcall(MR.FireServer, MR, "UpgradeNoobMax", n)
    task.wait(0.3)
end

task.wait(1)

setreadonly(orig, false)
orig.__namecall = old_nc
setreadonly(orig, true)

print("\n--- after ---")
for _, n in ipairs(TEST_NOOBS) do
    print(n .. " = " .. tostring(getNoobLevel(n)))
end
print("Fired events: " .. #fired)
