-- ═══════════════════ ORE REMOTE TEST ═════════════════════════════════════════
-- Тестирует: можно ли слать OreHit дистанционно (без телепорта)?
-- Тестирует: разные аргументы, несколько руд сразу.
-- Слушает MineralGained для подтверждения.
-- ══════════════════════════════════════════════════════════════════════════════

local LP  = game:GetService("Players").LocalPlayer
local RS  = game:GetService("ReplicatedStorage")
local GC  = workspace:WaitForChild("__GAME_CONTENT", 10)
local NET = RS:WaitForChild("__Net", 10)
local MR  = NET and NET:WaitForChild("MainRemote", 10)
local OreHitEv = NET and NET:FindFirstChild("OreHit")

if not (GC and MR) then warn("[OreTest] GC/MR not found"); return end

-- ── Helpers ──────────────────────────────────────────────────────────────────
local function fireMR(...) pcall(MR.FireServer, MR, ...) end
local function fireEv(ev, ...) if ev then pcall(ev.FireServer, ev, ...) end end
local p = print

-- ── Find ores ─────────────────────────────────────────────────────────────────
local oreF = GC:FindFirstChild("Ores")
if not oreF then warn("[OreTest] GC/Ores not found"); return end

-- Collect all live ores (max 50)
local allOres = {}
for _, ore in ipairs(oreF:GetChildren()) do
    local rock = ore:FindFirstChild("Rock")
    if rock and rock:IsA("MeshPart") then
        allOres[#allOres+1] = { ore=ore, rock=rock, name=ore.Name }
    end
    if #allOres >= 50 then break end
end
p(string.format("[OreTest] Found %d ores. OreHit RemoteEvent: %s",
    #allOres, OreHitEv and "FOUND ✓" or "NOT FOUND"))
p("[OreTest] OreHit class: "..(OreHitEv and OreHitEv.ClassName or "N/A"))
p("[OreTest] MR class: "..(MR and MR.ClassName or "N/A"))

-- ── Track MineralGained ───────────────────────────────────────────────────────
local mineralLog = {}
local mineralTotal = 0
local mineralEv = NET:FindFirstChild("MineralGained")
local oreHitLog  = {}  -- track if OreHit fires server→client too
if mineralEv then
    mineralEv.OnClientEvent:Connect(function(minType, amount, ...)
        mineralTotal = mineralTotal + 1
        local entry = {t=tick(), typ=tostring(minType), amt=tostring(amount), extra={...}}
        table.insert(mineralLog, entry)
        p(string.format("[OreTest] ✓ MineralGained #%d | type=%s amount=%s extra=%s",
            mineralTotal, entry.typ, entry.amt,
            #entry.extra>0 and table.concat(entry.extra,",") or "none"))
    end)
end
-- Also listen on OreHit as client event (maybe server fires back)
if OreHitEv then
    OreHitEv.OnClientEvent:Connect(function(...)
        local args = {...}
        p("[OreTest] OreHit CLIENT event fired! args: "..#args)
        for i,v in ipairs(args) do p("  arg"..i..": "..tostring(v)) end
    end)
end

-- ── Test helper ───────────────────────────────────────────────────────────────
local function waitMineral(prevTotal, timeout)
    local deadline = tick() + timeout
    while mineralTotal == prevTotal and tick() < deadline do task.wait(0.05) end
    return mineralTotal > prevTotal
end

local first = allOres[1]  -- use first ore for single tests

p("\n[OreTest] ═══ TEST 1: OreHit via MainRemote, arg=ore model ═══")
do
    local prev = mineralTotal
    fireMR("OreHit", first.ore)
    task.wait(0.3)
    p("[OreTest] T1 result: "..(mineralTotal>prev and "✓ MineralGained!" or "✗ no response"))
end

task.wait(0.5)

p("\n[OreTest] ═══ TEST 2: OreHit via MainRemote, arg=Rock MeshPart ═══")
do
    local prev = mineralTotal
    fireMR("OreHit", first.rock)
    task.wait(0.3)
    p("[OreTest] T2 result: "..(mineralTotal>prev and "✓ MineralGained!" or "✗ no response"))
end

task.wait(0.5)

p("\n[OreTest] ═══ TEST 3: OreHit direct RemoteEvent, arg=ore model ═══")
do
    local prev = mineralTotal
    fireEv(OreHitEv, first.ore)
    task.wait(0.3)
    p("[OreTest] T3 result: "..(mineralTotal>prev and "✓ MineralGained!" or "✗ no response"))
end

task.wait(0.5)

p("\n[OreTest] ═══ TEST 4: OreHit direct RemoteEvent, arg=Rock ═══")
do
    local prev = mineralTotal
    fireEv(OreHitEv, first.rock)
    task.wait(0.3)
    p("[OreTest] T4 result: "..(mineralTotal>prev and "✓ MineralGained!" or "✗ no response"))
end

task.wait(0.5)

p("\n[OreTest] ═══ TEST 5: OreHit direct, arg=rock + CFrame ═══")
do
    local prev = mineralTotal
    fireEv(OreHitEv, first.rock, first.rock.CFrame)
    task.wait(0.3)
    p("[OreTest] T5 result: "..(mineralTotal>prev and "✓ MineralGained!" or "✗ no response"))
end

task.wait(0.5)

p("\n[OreTest] ═══ TEST 6: OreHit direct, arg=rock + Vector3 position ═══")
do
    local prev = mineralTotal
    fireEv(OreHitEv, first.rock, first.rock.Position)
    task.wait(0.3)
    p("[OreTest] T6 result: "..(mineralTotal>prev and "✓ MineralGained!" or "✗ no response"))
end

task.wait(0.5)

p("\n[OreTest] ═══ TEST 7: OreHit direct, arg=rock name (string) ═══")
do
    local prev = mineralTotal
    fireEv(OreHitEv, first.name)
    task.wait(0.3)
    p("[OreTest] T7 result: "..(mineralTotal>prev and "✓ MineralGained!" or "✗ no response"))
end

task.wait(0.5)

-- If any test worked, try sending to multiple ores simultaneously
p("\n[OreTest] ═══ TEST 8: Fire OreHit to 5 different ores simultaneously ═══")
do
    local prev = mineralTotal
    -- Figure out which arg format worked from tests above
    -- Try direct rock approach to all 5 ores at once
    local count = math.min(5, #allOres)
    for i = 1, count do
        local entry = allOres[i]
        if entry.rock and entry.rock.Parent then
            fireEv(OreHitEv, entry.rock)
        end
    end
    task.wait(0.5)
    local gained = mineralTotal - prev
    p(string.format("[OreTest] T8 result: sent to %d ores → MineralGained fired %d times",
        count, gained))
end

task.wait(0.5)

p("\n[OreTest] ═══ TEST 9: Rapid fire same ore (DPS test) ═══")
do
    local prev = mineralTotal
    local t0 = tick()
    local sends = 0
    repeat
        fireEv(OreHitEv, first.rock)
        fireMR("OreHit", first.rock)
        sends = sends + 2
        task.wait(0.05)
    until tick() - t0 >= 1
    task.wait(0.3)
    local gained = mineralTotal - prev
    p(string.format("[OreTest] T9: sent %d fires in 1s → MineralGained: %d times", sends, gained))
end

-- ── Summary ───────────────────────────────────────────────────────────────────
task.wait(0.5)
p("\n[OreTest] ═══ SUMMARY ═══")
p("Total MineralGained received: "..mineralTotal)
p("First ore tested: "..first.name.." @ "..tostring(first.rock.Position))
if #mineralLog > 0 then
    p("Sample mineral event args:")
    local s = mineralLog[1]
    p("  type="..s.typ.." amount="..s.amt)
    if #s.extra > 0 then
        for i,v in ipairs(s.extra) do p("  extra"..i.."="..tostring(v)) end
    end
end
p("[OreTest] Done.")
