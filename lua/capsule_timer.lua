-- CAPSULE COOLDOWN FINDER + AUTO-OPENER  @Benefit
-- Запусти после выключения авто-удаления

local RS  = game:GetService("ReplicatedStorage")
local LP  = game:GetService("Players").LocalPlayer
local MR  = RS.__Net.MainRemote
local NET = RS.__Net

local function fire(...) pcall(MR.FireServer, MR, ...) end

local lastOpen  = 0
local openTimes = {}

-- Логируем каждый реальный ответ сервера
NET.MinionCapsuleOpened.OnClientEvent:Connect(function(capType, minions, mult, count)
    local now  = tick()
    local gap  = now - lastOpen
    lastOpen   = now
    table.insert(openTimes, gap)

    local keptCount = 0
    for _, m in ipairs(minions or {}) do
        if not m.autoDeleted then keptCount = keptCount + 1 end
    end

    print(string.format("[OPEN] +%.2fs  type=%s  kept=%d/%d  luck=%.2f",
        gap, tostring(capType), keptCount, #(minions or {}), tonumber(mult) or 0))
end)

print("[TIMER] Hook active — открой несколько капсул вручную для замера")
print("[TIMER] Или запусти авто-opener: autoOpen('Super', 50)")
print()

-- ── АВТО-OPENER — уважает кулдаун ─────────────────────────────────
local function autoOpen(capType, count)
    capType = capType or "Super"
    count   = count or 50

    -- Определяем кулдаун из собранных данных (или дефолт 3.5s)
    local cd = 3.5
    if #openTimes >= 3 then
        local sum = 0
        for i = 2, #openTimes do sum = sum + openTimes[i] end
        cd = (sum / (#openTimes - 1)) + 0.1  -- +100ms буфер
        print(string.format("[OPENER] Detected cooldown: %.2fs", cd))
    else
        print(string.format("[OPENER] Using default cooldown: %.2fs", cd))
    end

    print(string.format("[OPENER] Opening %d x %s capsules", count, capType))

    local done = 0
    while done < count do
        local sentAt = tick()
        fire("OpenCapsule", capType, 1)
        done = done + 1

        if done % 10 == 0 then
            print(string.format("[OPENER] %d/%d opened", done, count))
        end

        -- Ждём точно до следующего открытия
        local elapsed = tick() - sentAt
        local remaining = cd - elapsed
        if remaining > 0 then task.wait(remaining) end
    end

    print("[OPENER] Done — " .. done .. " capsules sent")
end

-- ── НАЙТИ ТОЧНЫЙ КУЛДАУН автоматически ───────────────────────────
local function findCooldown()
    print("[FIND-CD] Sending probes every 0.5s for 30s...")
    local results = {}
    local conn
    conn = NET.MinionCapsuleOpened.OnClientEvent:Connect(function()
        table.insert(results, tick())
        if #results >= 5 then conn:Disconnect() end
    end)

    local sent = {}
    for i = 1, 60 do
        fire("OpenCapsule", "Super", 1)
        table.insert(sent, tick())
        task.wait(0.5)
    end

    task.wait(2)
    conn:Disconnect()

    if #results < 2 then
        print("[FIND-CD] Not enough responses")
        return
    end

    local gaps = {}
    for i = 2, #results do
        gaps[#gaps+1] = results[i] - results[i-1]
    end
    local avg = 0
    for _, g in ipairs(gaps) do avg = avg + g end
    avg = avg / #gaps
    print(string.format("[FIND-CD] ★ Cooldown: %.3fs (from %d samples)", avg, #gaps))
    return avg
end

-- Раскомментируй что нужно:
-- findCooldown()
-- autoOpen("Super", 100)
-- autoOpen("Classic", 200)

print("[TIMER] Functions available:")
print("  findCooldown()          — точный кулдаун")
print("  autoOpen('Super', 100)  — авто-opener 100 капсул")
