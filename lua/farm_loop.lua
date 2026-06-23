-- ═══════════════════════════════════════════════════════════════════
--  Noob Incremental · FARM LOOP  @Benefit
--  Запускай ВМЕСТО autofarm когда нужен максимальный прогресс
--  Крутит: UpgradeNoobMax ALL + ExchangeAll + DepositMilestone
--  в максимально плотном цикле
-- ═══════════════════════════════════════════════════════════════════

local RS  = game:GetService("ReplicatedStorage")
local LP  = game:GetService("Players").LocalPlayer
local MR  = RS.__Net.MainRemote
local NET = RS.__Net

local function fire(...) pcall(MR.FireServer, MR, ...) end

local NOOB_TYPES = {
    "Fire","Ice","Water","Oof","Rebirth","Wood","Planks",
    "Bread","Cash","Coin","HackPoints","Gem","Blaze","Explorer",
}

local CHESTS = {"SuperChest","LegendaryChest","GoldenChest"}
local CAPS   = {"Classic","Advanced","Premium","Snowy"}

-- Milestone IDs: пробуем числами 1-100 + строками
local MILESTONES = {}
for i=1,100 do MILESTONES[#MILESTONES+1] = i end

local running = true
local cycle   = 0
local startT  = tick()

-- ─── UI — простой print-лог каждые N секунд ────────────────────
local function readStat()
    local ok, v = pcall(function()
        return LP.leaderstats.Oof.Value
    end)
    return ok and tostring(v) or "?"
end

-- ─── MAIN LOOP ─────────────────────────────────────────────────
print("[FARMLOOP] Starting...")
print("[FARMLOOP] Stop: set running=false in console")

task.spawn(function()
    while running do
        task.wait(15)
        cycle = cycle + 1
        print(string.format("[FARMLOOP] cycle=%d  t=%.0fs  Oof=%s",
            cycle, tick()-startT, readStat()))
    end
end)

while running do
    -- 1. Upgrade all noob types to max
    for _, t in ipairs(NOOB_TYPES) do
        fire("UpgradeNoobMax", t)
    end

    -- 2. Exchange all resources → coins
    fire("ExchangeAllAnimalProducts")
    fire("ExchangeAllMinerals")

    -- 3. Deposit all milestones
    for _, m in ipairs(MILESTONES) do
        fire("DepositCoinMilestone", m)
    end

    -- 4. Open available chests/capsules
    for _, c in ipairs(CHESTS) do fire("OpenChest", c) end
    for _, c in ipairs(CAPS)   do fire("OpenCapsule", c) end

    -- 5. RollTier fast
    for _=1,50 do fire("RollTier") end

    -- 6. Claim guild weekly rewards (try slots 1-20)
    pcall(function()
        for i=1,20 do
            NET.ClaimGuildWeeklyReward:InvokeServer(i)
        end
    end)
    pcall(function() NET.ClaimAllGuildWeeklyRewards:InvokeServer() end)

    task.wait(0.1)
end

print("[FARMLOOP] Stopped after", math.floor(tick()-startT), "seconds")
