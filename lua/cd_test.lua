-- CAPSULE COOLDOWN PRECISE TEST  @Benefit
local RS  = game:GetService("ReplicatedStorage")
local LP  = game:GetService("Players").LocalPlayer
local MR  = RS.__Net.MainRemote
local CAP = "Super"  -- меняй на свой тип

local function fire(...) pcall(MR.FireServer, MR, ...) end

local gaps  = {}
local lastT = 0
local count = 0

RS.__Net.MinionCapsuleOpened.OnClientEvent:Connect(function()
    local now = tick()
    count = count + 1
    if lastT > 0 then
        local gap = now - lastT
        table.insert(gaps, gap)
        print(string.format("[OPEN #%d]  gap = %.3fs", count, gap))
    else
        print(string.format("[OPEN #1]  (baseline)"))
    end
    lastT = now
end)

print("[CD] Sending probes every 0.5s for 60s...")
print("[CD] Следи за [OPEN] строками — gap = реальный кулдаун")
print()

local sent = 0
local startT = tick()
while tick() - startT < 60 do
    fire("OpenCapsule", CAP, 1)
    sent = sent + 1
    task.wait(0.5)
end

task.wait(3)

print(string.format("\n[CD] Sent: %d  |  Received: %d", sent, count))
if #gaps > 0 then
    local sum, mn, mx = 0, math.huge, 0
    for _, g in ipairs(gaps) do
        sum = sum + g
        if g < mn then mn = g end
        if g > mx then mx = g end
    end
    print(string.format("[CD] Min gap: %.3fs", mn))
    print(string.format("[CD] Max gap: %.3fs", mx))
    print(string.format("[CD] Avg gap: %.3fs", sum / #gaps))
    print(string.format("[CD] ★ Optimal autoOpen interval: %.2fs", mn + 0.1))
end
