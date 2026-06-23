-- ═══════════════════ CAPSULE TIMING TEST ═════════════════════════════════════
-- Тестирует разные задержки перед fire("OpenCapsule").
-- Слушает MinionCapsuleOpened чтобы знать реальный момент открытия.
-- Запусти, подожди ~30 секунд, посмотри вывод.
-- ══════════════════════════════════════════════════════════════════════════════

local LP  = game:GetService("Players").LocalPlayer
local RS  = game:GetService("ReplicatedStorage")
local GC  = workspace:WaitForChild("__GAME_CONTENT", 10)
local NET = RS:WaitForChild("__Net", 10)
local MR  = NET and NET:WaitForChild("MainRemote", 10)

if not (GC and MR) then
    warn("[CapsTest] GC or MR not found"); return
end

local function fire(...) pcall(MR.FireServer, MR, ...) end

-- Find capsule TouchPart
local uiZ = GC:FindFirstChild("UIZones")
local PARTS = {}
for _, ctype in ipairs({"Classic","Super"}) do
    local mdl = uiZ and uiZ:FindFirstChild("__Capsule"..ctype)
    local tp  = mdl and (mdl:FindFirstChild("TouchPart") or mdl:FindFirstChildWhichIsA("BasePart"))
    PARTS[ctype] = tp
    if tp then
        print(string.format("[CapsTest] %s: found at %s  size %s",
            ctype, tostring(tp.Position), tostring(tp.Size)))
    else
        warn("[CapsTest] "..ctype.." TouchPart NOT FOUND")
    end
end

-- Track open events with timestamp
local openLog = {}
local openCount = 0
pcall(function()
    NET.MinionCapsuleOpened.OnClientEvent:Connect(function(_, _, _, cnt)
        openCount = openCount + 1
        local entry = openLog[#openLog]
        local elapsed = entry and (tick() - entry.fired) or -1
        print(string.format("[CapsTest] ✓ OPENED #%d  delay_since_fire=%.3fs  cnt=%s",
            openCount, elapsed, tostring(cnt)))
        if entry then entry.confirmed=true; entry.elapsed=elapsed end
    end)
end)

-- Test: teleport → wait N → fire once → wait for confirmation
local function testOpen(ctype, waitBeforeFire, label)
    local part = PARTS[ctype]
    local hrp  = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if not (part and hrp) then warn("[CapsTest] No HRP"); return false end

    local enterCF = CFrame.new(part.Position)
    local prevCount = openCount

    hrp.CFrame = enterCF
    print(string.format("[CapsTest] [%s] snapped in, waiting %.0fms...", label, waitBeforeFire*1000))
    task.wait(waitBeforeFire)

    -- Keep re-snapping while waiting (server physics needs it)
    local function keepSnapping()
        local h2 = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
        if h2 then h2.CFrame = enterCF end
    end

    local fireT = tick()
    openLog[#openLog+1] = {fired=fireT, label=label}
    fire("OpenCapsule", ctype)
    print(string.format("[CapsTest] [%s] fired OpenCapsule", label))

    local deadline = tick() + 5
    while openCount == prevCount and tick() < deadline do
        keepSnapping()
        task.wait(0.05)
    end

    if openCount > prevCount then
        print(string.format("[CapsTest] [%s] ✓ SUCCESS", label))
        return true
    else
        warn(string.format("[CapsTest] [%s] ✗ FAIL — no response in 5s", label))
        openLog[#openLog].confirmed = false
        return false
    end
end

-- Run timing ladder
local CTYPE = PARTS.Super and "Super" or "Classic"
print("\n[CapsTest] Testing "..CTYPE.." capsule — 6 delay values:")

task.spawn(function()
    local tests = {
        {0.00, "0ms"},
        {0.05, "50ms"},
        {0.10, "100ms"},
        {0.20, "200ms"},
        {0.30, "300ms"},
        {0.50, "500ms"},
    }

    for _, t in ipairs(tests) do
        task.wait(3)   -- server cooldown between capsule opens
        testOpen(CTYPE, t[1], t[2])
    end

    task.wait(2)
    print("\n[CapsTest] ═══ SUMMARY ═══")
    for _, e in ipairs(openLog) do
        if e.confirmed then
            print(string.format("  %-8s → ✓ opened in %.3fs after fire", e.label, e.elapsed))
        else
            print(string.format("  %-8s → ✗ TIMEOUT", e.label))
        end
    end
    print("[CapsTest] Done.")
end)
