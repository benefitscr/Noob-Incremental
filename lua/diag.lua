-- ═══════════════════════ NOOB INC DIAGNOSTIC ════════════════════════════════
-- Запусти отдельно. Результат скопируй и скинь.
-- ════════════════════════════════════════════════════════════════════════════

local LP  = game:GetService("Players").LocalPlayer
local RS  = game:GetService("ReplicatedStorage")
local out = {}
local function p(...) local s=table.concat({...}," "); table.insert(out,s); print(s) end
local function h(t)   p(""); p("═══ "..t.." ═══") end

-- ── 1. Core paths ─────────────────────────────────────────────────────────────
h("CORE PATHS")
local GC  = workspace:FindFirstChild("__GAME_CONTENT")
local NET = RS:FindFirstChild("__Net")
local MR  = NET and NET:FindFirstChild("MainRemote")
p("GC  (__GAME_CONTENT):", GC  and GC.ClassName  or "NIL ← PROBLEM")
p("NET (__Net):         ", NET and NET.ClassName  or "NIL ← PROBLEM")
p("MR  (MainRemote):   ", MR  and MR.ClassName   or "NIL ← PROBLEM")

-- ── 2. Player folders ──────────────────────────────────────────────────────────
h("PLAYER FOLDERS")
for _, name in ipairs({"CURRENCIES","FEATURES","EXTRA","LAB"}) do
    local f = LP:FindFirstChild(name, true)
    p(name..":", f and (f.ClassName.." @ "..f:GetFullName()) or "NOT FOUND")
end

local prismOk, prismV = pcall(function()
    return LP.CURRENCIES.Prism.Amount:FindFirstChild("1")
end)
p("Prism.Amount[1]:", prismOk and (prismV and tostring(prismV.Value) or "nil child") or "ERROR: "..tostring(prismV))

-- ── 3. NET events (capsule / minion / prism) ──────────────────────────────────
h("NET EVENTS")
if NET then
    for _, child in ipairs(NET:GetChildren()) do
        local n = child.Name:lower()
        if n:find("capsule") or n:find("minion") or n:find("prism") or n:find("open") or n:find("mine") or n:find("ore") or n:find("mineral") then
            p(" "..child.ClassName..": "..child.Name)
        end
    end
    p("Total NET children:", #NET:GetChildren())
else
    p("NET is nil — cannot scan events")
end

-- ── 4. UIZones / Capsule parts ────────────────────────────────────────────────
h("CAPSULE ZONE SCAN")
local uiZ = GC and GC:FindFirstChild("UIZones")
p("UIZones:", uiZ and "FOUND" or "NOT FOUND")
if uiZ then
    p("UIZones children:")
    for _, child in ipairs(uiZ:GetChildren()) do
        p(" "..child.Name.." ["..child.ClassName.."]")
    end
    for _, ctype in ipairs({"Classic","Super"}) do
        local mdl = uiZ:FindFirstChild("__Capsule"..ctype)
        if mdl then
            local tp = mdl:FindFirstChild("TouchPart") or mdl:FindFirstChildWhichIsA("BasePart")
            if tp then
                p("Capsule "..ctype..": "..tp:GetFullName().." pos="..tostring(tp.Position).." size="..tostring(tp.Size))
            else
                p("Capsule "..ctype.." model found but NO BasePart inside")
                for _, c in ipairs(mdl:GetDescendants()) do
                    p("  "..c.ClassName..": "..c.Name)
                end
            end
        else
            p("__Capsule"..ctype..": NOT FOUND in UIZones")
        end
    end
end

-- Broad capsule search
p("--- Broad search for 'capsule' in workspace ---")
local capFound = 0
for _, obj in ipairs(workspace:GetDescendants()) do
    if obj.Name:lower():find("capsule") then
        capFound = capFound + 1
        if capFound <= 25 then
            p(" "..obj.ClassName..": "..obj:GetFullName())
        end
    end
end
p("Total 'capsule' objects:", capFound)

-- OpenCapsule remote
h("OPENCAPSULE REMOTE")
if NET then
    local oc = NET:FindFirstChild("OpenCapsule")
    p("OpenCapsule:", oc and (oc.ClassName.." FOUND ✓") or "NOT FOUND ← capsule open will fail")
    if not oc then
        p("Searching for any 'cap' in NET:")
        for _, c in ipairs(NET:GetChildren()) do
            if c.Name:lower():find("cap") then p("  "..c.ClassName..": "..c.Name) end
        end
    end
end

-- ── 5. Mining / Ore ────────────────────────────────────────────────────────────
h("ORE / MINING SCAN")
local function findOreFolder()
    if not GC then return nil, "GC nil" end
    local f = GC:FindFirstChild("Ores")
    if f then return f, "GC/Ores" end
    local ct = GC:FindFirstChild("Contents")
    if ct then
        for _, w in ipairs(ct:GetChildren()) do
            local wf = w:FindFirstChild("Ores")
            if wf then return wf, "GC/Contents/"..w.Name.."/Ores" end
        end
    end
    return nil, "NOT FOUND"
end
local oreF, orePath = findOreFolder()
p("Ore folder path:", orePath)
if oreF then
    local names, seen = {}, {}
    for _, ore in ipairs(oreF:GetChildren()) do
        if not seen[ore.Name] then seen[ore.Name]=true; names[#names+1]=ore.Name end
    end
    p("Ore types ("..#names.."):", table.concat(names, ", "))
    local first = oreF:GetChildren()[1]
    if first then
        p("First ore '"..first.Name.."' children:")
        for _, c in ipairs(first:GetChildren()) do
            p("  "..c.ClassName..": "..c.Name)
            -- Check Rock
            if c.Name == "Rock" then
                for _, rc in ipairs(c:GetChildren()) do
                    p("    Rock child: "..rc.ClassName..": "..rc.Name)
                end
            end
        end
    end
else
    -- Try to find ores anywhere
    p("Searching workspace for ore-like objects...")
    local kw = {"ore","rock","crystal","gem","mineral","iron","coal","gold","silver","diamond"}
    local found, seen2 = 0, {}
    for _, obj in ipairs(workspace:GetDescendants()) do
        if not seen2[obj.Name] then
            local low = obj.Name:lower()
            for _, k in ipairs(kw) do
                if low:find(k) then
                    seen2[obj.Name]=true; found=found+1
                    if found<=15 then p("  "..obj.ClassName..": "..obj:GetFullName()) end
                    break
                end
            end
        end
    end
    p("Ore-like objects found:", found)
end

-- Mining remotes
p("Mining/exchange remotes:")
if NET then
    for _, child in ipairs(NET:GetChildren()) do
        local n = child.Name:lower()
        if n:find("mine") or n:find("ore") or n:find("mineral") or n:find("exchange") then
            p("  "..child.ClassName..": "..child.Name)
        end
    end
end

-- ── 6. Character position + capsule zone distance ─────────────────────────────
h("CHARACTER & CAPSULE DISTANCE")
local char = LP.Character
local hrp  = char and char:FindFirstChild("HumanoidRootPart")
p("HRP pos:", hrp and tostring(hrp.Position) or "NIL")

if uiZ and hrp then
    for _, ctype in ipairs({"Classic","Super"}) do
        local mdl = uiZ:FindFirstChild("__Capsule"..ctype)
        local tp  = mdl and (mdl:FindFirstChild("TouchPart") or mdl:FindFirstChildWhichIsA("BasePart"))
        if tp then
            local dist = (tp.Position - hrp.Position).Magnitude
            p("Distance to "..ctype.." capsule:", math.floor(dist).."  studs")
            p("  TouchPart size:", tostring(tp.Size))
        end
    end
end

-- ── 7. MINIONS ────────────────────────────────────────────────────────────────
h("MINIONS / LAB")
local labOk, labV = pcall(function() return LP.FEATURES.LAB end)
p("LP.FEATURES.LAB:", labOk and (labV and labV.ClassName or "nil") or "ERROR: "..tostring(labV))
if labOk and labV then
    for _, c in ipairs(labV:GetChildren()) do p("  "..c.Name.." ["..c.ClassName.."]") end
end

-- ── DONE ──────────────────────────────────────────────────────────────────────
h("DONE — copy everything above")
p("Total lines:", #out)
