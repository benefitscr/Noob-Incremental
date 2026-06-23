-- CAPSULE AUDIT — полный тест всех подходов к открытию капсулы
-- Запусти и скинь весь вывод консоли

local LP  = game:GetService("Players").LocalPlayer
local RS  = game:GetService("ReplicatedStorage")
local RUN = game:GetService("RunService")
local GC  = workspace:WaitForChild("__GAME_CONTENT", 15)
local NET = RS:WaitForChild("__Net", 15)
local MR  = NET and NET:WaitForChild("MainRemote", 15)
if not (GC and MR) then warn("[Audit] missing GC/MR"); return end

local function fire(...) pcall(MR.FireServer, MR, ...) end
local function getHRP() local c=LP.Character; return c and c:FindFirstChild("HumanoidRootPart") end
local function getHum() local c=LP.Character; return c and c:FindFirstChild("Humanoid") end
local p = print

-- ─── Find capsule zone ─────────────────────────────────────────────────────
local uiZ  = GC:FindFirstChild("UIZones")
local mdlS = uiZ and uiZ:FindFirstChild("__CapsuleSuper")
local mdlC = uiZ and uiZ:FindFirstChild("__CapsuleClassic")
local partS = mdlS and (mdlS:FindFirstChild("TouchPart") or mdlS:FindFirstChildWhichIsA("BasePart"))
local partC = mdlC and (mdlC:FindFirstChild("TouchPart") or mdlC:FindFirstChildWhichIsA("BasePart"))

p("═══ CAPSULE ZONE SCAN ═══")
p("UIZones found:", uiZ ~= nil)
p("Super model:  ", mdlS and mdlS:GetFullName() or "NOT FOUND")
p("Classic model:", mdlC and mdlC:GetFullName() or "NOT FOUND")
if partS then
    p(string.format("Super  TouchPart: pos=(%.1f,%.1f,%.1f) size=(%.1f,%.1f,%.1f) CanCollide=%s",
        partS.Position.X, partS.Position.Y, partS.Position.Z,
        partS.Size.X, partS.Size.Y, partS.Size.Z, tostring(partS.CanCollide)))
end
if partC then
    p(string.format("Classic TouchPart: pos=(%.1f,%.1f,%.1f) size=(%.1f,%.1f,%.1f) CanCollide=%s",
        partC.Position.X, partC.Position.Y, partC.Position.Z,
        partC.Size.X, partC.Size.Y, partC.Size.Z, tostring(partC.CanCollide)))
end

local part = partS or partC
local ctype = partS and "Super" or "Classic"
if not part then warn("[Audit] No capsule part found — aborting"); return end

p("\nUsing: "..ctype.." capsule")

-- ─── Track MinionCapsuleOpened ────────────────────────────────────────────
local openCount = 0
local lastOpen  = 0
pcall(function()
    NET:WaitForChild("MinionCapsuleOpened",5).OnClientEvent:Connect(function()
        openCount = openCount + 1
        lastOpen  = tick()
        p("[EVENT] MinionCapsuleOpened #"..openCount.." at t="..string.format("%.3f",tick()))
    end)
end)

-- ─── Save start position ───────────────────────────────────────────────────
local hrp0 = getHRP()
local startCF = hrp0 and hrp0.CFrame or CFrame.new()
p("\nStart pos: "..tostring(startCF.Position))

-- ─── Helper: check if HRP is inside TouchPart bounds ──────────────────────
local function inZone(hrp, tp)
    local rel = tp.CFrame:Inverse() * hrp.CFrame
    local lp  = rel.Position
    local hs  = tp.Size / 2
    return math.abs(lp.X)<=hs.X and math.abs(lp.Y)<=hs.Y and math.abs(lp.Z)<=hs.Z
end

-- ─── TEST RUNNER ──────────────────────────────────────────────────────────
local results = {}

local function runTest(label, setupFn, dwellMs, approach)
    local hrp = getHRP()
    if not hrp then results[#results+1]={label=label,result="NO_HRP"}; return end

    local prevOpen = openCount
    local prevPos  = hrp.Position

    -- Setup (teleport / other)
    setupFn(hrp, part)
    task.wait(0.05) -- let physics settle one frame

    local afterSetupPos = (getHRP() or hrp).Position
    local afterSetupIn  = inZone(getHRP() or hrp, part)

    -- Approach: hold position for dwellMs then fire
    if approach == "heartbeat" then
        local enterCF = CFrame.new(part.Position.X, part.Position.Y - 3, part.Position.Z)
        local conn = RUN.Heartbeat:Connect(function()
            local h2 = getHRP(); if h2 then h2.CFrame = enterCF end
        end)
        task.wait(dwellMs / 1000)
        fire("OpenCapsule", ctype)
        local fireT = tick()
        task.wait(1.5)
        conn:Disconnect()
        local opened = openCount > prevOpen
        results[#results+1] = {
            label      = label,
            dwell      = dwellMs,
            approach   = approach,
            inZoneAfterSetup = afterSetupIn,
            posAfterSetup    = afterSetupPos,
            opened     = opened,
            result     = opened and "OPEN ✓" or "FAIL ✗",
        }
        p(string.format("[%s] dwell=%dms inZone=%s → %s",
            label, dwellMs, tostring(afterSetupIn), opened and "OPEN ✓" or "FAIL ✗"))

    elseif approach == "moveto" then
        -- Walk into zone
        local hum = getHum()
        if hum then hum:MoveTo(part.Position) end
        task.wait(dwellMs / 1000)
        local inZ = inZone(getHRP() or hrp, part)
        fire("OpenCapsule", ctype)
        task.wait(1.5)
        local opened = openCount > prevOpen
        results[#results+1] = {
            label    = label,
            dwell    = dwellMs,
            approach = approach,
            inZoneAtFire = inZ,
            opened   = opened,
            result   = opened and "OPEN ✓" or "FAIL ✗",
        }
        p(string.format("[%s] moveto dwell=%dms inZoneAtFire=%s → %s",
            label, dwellMs, tostring(inZ), opened and "OPEN ✓" or "FAIL ✗"))

    elseif approach == "single_snap" then
        -- Single CFrame set, no Heartbeat
        local enterCF = CFrame.new(part.Position.X, part.Position.Y - 3, part.Position.Z)
        local h2 = getHRP(); if h2 then h2.CFrame = enterCF end
        task.wait(dwellMs / 1000)
        local inZ = inZone(getHRP() or hrp, part)
        fire("OpenCapsule", ctype)
        task.wait(1.5)
        local opened = openCount > prevOpen
        results[#results+1] = {
            label    = label,
            dwell    = dwellMs,
            approach = approach,
            inZoneAtFire = inZ,
            opened   = opened,
            result   = opened and "OPEN ✓" or "FAIL ✗",
        }
        p(string.format("[%s] single_snap dwell=%dms inZoneAtFire=%s → %s",
            label, dwellMs, tostring(inZ), opened and "OPEN ✓" or "FAIL ✗"))
    end

    -- Return to start between tests
    task.wait(0.2)
    local h3 = getHRP(); if h3 then h3.CFrame = startCF end
    task.wait(1)  -- wait away from capsule so server deregisters zone
end

-- ─── TEST SEQUENCE ────────────────────────────────────────────────────────
p("\n═══ BEGIN TESTS ═══\n")

-- Test 0: Fire with NO teleport (user already stood there)
-- Just fire right now and see what server says
p("[T0] Fire OpenCapsule from current position (no teleport)...")
local prevT0 = openCount
fire("OpenCapsule", ctype)
task.wait(1)
p("[T0] result: "..(openCount>prevT0 and "OPEN ✓" or "FAIL ✗").." (currently at "..tostring(getHRP() and getHRP().Position).. ")")

task.wait(1)

-- Setup functions
local function setupFar(hrp, tp)
    -- Teleport far away first, then to zone
    hrp.CFrame = CFrame.new(tp.Position.X + 200, tp.Position.Y, tp.Position.Z)
    task.wait(0.5) -- wait for server to see "far" position
    hrp.CFrame = CFrame.new(tp.Position.X, tp.Position.Y - 3, tp.Position.Z)
end

local function setupNear(hrp, tp)
    -- Teleport directly to zone from close by
    hrp.CFrame = CFrame.new(tp.Position.X + 10, tp.Position.Y, tp.Position.Z)
    task.wait(0.1)
    hrp.CFrame = CFrame.new(tp.Position.X, tp.Position.Y - 3, tp.Position.Z)
end

local function setupDirect(hrp, tp)
    hrp.CFrame = CFrame.new(tp.Position.X, tp.Position.Y - 3, tp.Position.Z)
end

-- T1-T4: Single snap from far, different dwell times
for _, ms in ipairs({100, 200, 400, 600}) do
    runTest("FAR→snap→"..ms.."ms", setupFar, ms, "single_snap")
end

-- T5-T7: Heartbeat from far, different dwell times
for _, ms in ipairs({200, 400, 600}) do
    runTest("FAR→hb→"..ms.."ms", setupFar, ms, "heartbeat")
end

-- T8: MoveTo from nearby
runTest("NEAR→moveto→300ms", setupNear, 300, "moveto")

-- T9: Direct snap no prior far-teleport
for _, ms in ipairs({200, 400}) do
    runTest("DIRECT→snap→"..ms.."ms", setupDirect, ms, "single_snap")
end

-- ─── SUMMARY ──────────────────────────────────────────────────────────────
p("\n═══ SUMMARY ═══")
for _, r in ipairs(results) do
    p(string.format("  %-30s  %s", r.label, r.result))
end
p("\nTotal capsule opens during audit: "..openCount)
p("[Audit] Done.")
