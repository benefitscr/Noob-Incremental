-- ═══════════════════════════════════════════════════════════════════════════════
--  Storage Hunters · ADMIN MENU  ·  @Benefit
--  Структура: сворачиваемые разделы (Category). Клик по заголовку — раскрыть/спрятать.
--  Добавить функцию: cat:Button("Название", function() ... end)  (cat = раздел).
--  Проводка: fireEvent("Категория/Ремоут", ...) / invoke("Категория/Ремоут", ...).
-- ═══════════════════════════════════════════════════════════════════════════════

local Players = game:GetService("Players")
local RS      = game:GetService("ReplicatedStorage")
local UIS     = game:GetService("UserInputService")
local LP      = Players.LocalPlayer

_G.__NIADMIN = (_G.__NIADMIN or 0) + 1
local GEN = _G.__NIADMIN
local function alive() return _G.__NIADMIN == GEN end
pcall(function() if _G.__NIADMIN_gui then _G.__NIADMIN_gui:Destroy() end end)

-- ── wiring: ReplicatedStorage.Events.<Категория>.<Ремоут> ─────────────────────
local Events = RS:WaitForChild("Events")
local function remoteAt(path)
    local o = Events
    for part in path:gmatch("[^/]+") do o = o and o:FindFirstChild(part) end
    return o
end
local function fireEvent(path, ...)
    local r, a = remoteAt(path), { ... }
    if r and r:IsA("RemoteEvent") then pcall(function() r:FireServer(table.unpack(a)) end) end
end
local function invoke(path, ...)
    local r, a = remoteAt(path), { ... }
    if r and r:IsA("RemoteFunction") then
        local ok, res = pcall(function() return r:InvokeServer(table.unpack(a)) end)
        if ok then return res end
    end
end
local function netWorth()
    local ls = LP:FindFirstChild("leaderstats"); local nw = ls and ls:FindFirstChild("Net Worth")
    return nw and tostring(nw.Value) or "?"
end

-- ── Auto-Farm: авто-выигрыш аукционов + сбор добычи в инвентарь ────────────────
local CCU = LP:FindFirstChild("CCUStats")
local function cash() return CCU and CCU.Cash.Value or 0 end
local farm = { on = false, maxBid = 5000, status = "idle" }
pcall(function()
    local A = Events:WaitForChild("Auction")
    A.UpdateCurrentWinningBid.OnClientEvent:Connect(function(currentBid, winnerName, _, nextBid)
        if not farm.on then return end
        if winnerName == LP.Name then
            farm.status = "лидирую: " .. tostring(currentBid)
        elseif winnerName and type(nextBid) == "number" then
            if nextBid <= farm.maxBid and cash() >= nextBid then
                A.Bid:FireServer()
                farm.status = "бид " .. tostring(nextBid) .. " (перебил " .. tostring(winnerName) .. ")"
            else
                farm.status = "стоп: nextBid " .. tostring(nextBid) .. " > бюджет " .. tostring(farm.maxBid)
            end
        end
    end)
    A.AuctionPickupStart.OnClientEvent:Connect(function(bid, itemCount)
        if farm.on then farm.status = "ВЫИГРАЛ " .. tostring(itemCount) .. " шт за " .. tostring(bid) end
    end)
    A.AuctionPickupEnd.OnClientEvent:Connect(function()
        if not farm.on then return end
        task.delay(1.3, function()
            pcall(function() Events.Vehicles.TransferVehicleItemsToInventory:FireServer() end)
            farm.status = "собрал добычу -> инвентарь"
        end)
    end)
end)

-- ── стиль ─────────────────────────────────────────────────────────────────────
local COL_BG, COL_BAR, COL_CAT = Color3.fromRGB(16, 17, 22), Color3.fromRGB(24, 26, 34), Color3.fromRGB(30, 33, 43)
local COL_BTN, COL_ACC = Color3.fromRGB(40, 44, 56), Color3.fromRGB(120, 200, 255)
local COL_ON, COL_OFF, COL_TXT = Color3.fromRGB(38, 140, 74), Color3.fromRGB(90, 46, 46), Color3.fromRGB(230, 230, 235)
local function corner(o, r) local c = Instance.new("UICorner", o); c.CornerRadius = UDim.new(0, r or 6) end
local function padL(o, n) local p = Instance.new("UIPadding", o); p.PaddingLeft = UDim.new(0, n) end

-- ── окно ──────────────────────────────────────────────────────────────────────
local gui = Instance.new("ScreenGui")
gui.Name = "NIAdmin"; gui.ResetOnSpawn = false; gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
pcall(function() gui.Parent = (gethui and gethui()) or game:GetService("CoreGui") end)
if not gui.Parent then gui.Parent = LP:WaitForChild("PlayerGui") end
_G.__NIADMIN_gui = gui

local win = Instance.new("Frame"); win.Parent = gui; win.Active = true
win.Size = UDim2.fromOffset(320, 440); win.Position = UDim2.fromOffset(40, 80)
win.BackgroundColor3 = COL_BG; win.BorderSizePixel = 0; corner(win, 10)

local bar = Instance.new("Frame"); bar.Parent = win; bar.Size = UDim2.new(1, 0, 0, 34)
bar.BackgroundColor3 = COL_BAR; bar.BorderSizePixel = 0; corner(bar, 10)
local barFix = Instance.new("Frame"); barFix.Parent = bar; barFix.Size = UDim2.new(1, 0, 0, 12)
barFix.Position = UDim2.new(0, 0, 1, -12); barFix.BackgroundColor3 = COL_BAR; barFix.BorderSizePixel = 0

local titleLbl = Instance.new("TextLabel"); titleLbl.Parent = bar
titleLbl.Size = UDim2.new(1, -44, 1, 0); titleLbl.Position = UDim2.fromOffset(12, 0)
titleLbl.BackgroundTransparency = 1; titleLbl.TextXAlignment = Enum.TextXAlignment.Left
titleLbl.Font = Enum.Font.GothamBold; titleLbl.TextSize = 15; titleLbl.TextColor3 = COL_ACC
titleLbl.Text = "Admin · Storage Hunters"

local minBtn = Instance.new("TextButton"); minBtn.Parent = bar
minBtn.Size = UDim2.fromOffset(28, 22); minBtn.Position = UDim2.new(1, -34, 0, 6)
minBtn.BackgroundColor3 = COL_BTN; minBtn.Font = Enum.Font.GothamBold; minBtn.TextSize = 16
minBtn.TextColor3 = COL_TXT; minBtn.Text = "—"; corner(minBtn, 5)

local nwLbl = Instance.new("TextLabel"); nwLbl.Parent = win
nwLbl.Position = UDim2.fromOffset(12, 36); nwLbl.Size = UDim2.new(1, -24, 0, 18)
nwLbl.BackgroundTransparency = 1; nwLbl.TextXAlignment = Enum.TextXAlignment.Left
nwLbl.Font = Enum.Font.GothamMedium; nwLbl.TextSize = 12; nwLbl.TextColor3 = Color3.fromRGB(140, 220, 150)
nwLbl.Text = "Net Worth: " .. netWorth()
task.spawn(function() while alive() do nwLbl.Text = "Net Worth: " .. netWorth(); task.wait(1) end end)

local scroll = Instance.new("ScrollingFrame"); scroll.Parent = win
scroll.Position = UDim2.fromOffset(8, 58); scroll.Size = UDim2.new(1, -16, 1, -66)
scroll.BackgroundTransparency = 1; scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 4; scroll.ScrollBarImageColor3 = COL_BTN
scroll.CanvasSize = UDim2.new(0, 0, 0, 0); scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
local rootList = Instance.new("UIListLayout", scroll); rootList.Padding = UDim.new(0, 6)
rootList.SortOrder = Enum.SortOrder.LayoutOrder

-- collapse window + drag
local collapsed = false
minBtn.MouseButton1Click:Connect(function()
    collapsed = not collapsed
    scroll.Visible = not collapsed; nwLbl.Visible = not collapsed
    win.Size = collapsed and UDim2.fromOffset(320, 34) or UDim2.fromOffset(320, 440)
    minBtn.Text = collapsed and "+" or "—"
end)
do
    local dragging, off
    bar.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true; off = Vector2.new(i.Position.X, i.Position.Y) - win.AbsolutePosition end end)
    bar.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end end)
    UIS.InputChanged:Connect(function(i) if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then win.Position = UDim2.fromOffset(i.Position.X - off.X, i.Position.Y - off.Y) end end)
end

-- ── сворачиваемый раздел ──────────────────────────────────────────────────────
local catOrder = 0
local function Category(name, startOpen)
    catOrder = catOrder + 1
    local holder = Instance.new("Frame"); holder.Parent = scroll; holder.LayoutOrder = catOrder
    holder.Size = UDim2.new(1, 0, 0, 0); holder.AutomaticSize = Enum.AutomaticSize.Y
    holder.BackgroundTransparency = 1
    local hl = Instance.new("UIListLayout", holder); hl.Padding = UDim.new(0, 4); hl.SortOrder = Enum.SortOrder.LayoutOrder

    local header = Instance.new("TextButton"); header.Parent = holder; header.LayoutOrder = 0
    header.Size = UDim2.new(1, 0, 0, 30); header.BackgroundColor3 = COL_CAT; header.AutoButtonColor = true
    header.Font = Enum.Font.GothamBold; header.TextSize = 13; header.TextColor3 = COL_ACC
    header.TextXAlignment = Enum.TextXAlignment.Left; corner(header, 6); padL(header, 10)

    local content = Instance.new("Frame"); content.Parent = holder; content.LayoutOrder = 1
    content.Size = UDim2.new(1, 0, 0, 0); content.AutomaticSize = Enum.AutomaticSize.Y
    content.BackgroundTransparency = 1
    local cl = Instance.new("UIListLayout", content); cl.Padding = UDim.new(0, 5); cl.SortOrder = Enum.SortOrder.LayoutOrder
    local cpad = Instance.new("UIPadding", content); cpad.PaddingLeft = UDim.new(0, 8); cpad.PaddingBottom = UDim.new(0, 4)

    local open = startOpen and true or false
    local function paint() header.Text = (open and "[-]  " or "[+]  ") .. name; content.Visible = open end
    paint()
    header.MouseButton1Click:Connect(function() open = not open; paint() end)

    local ord = 0
    local function nextOrd() ord = ord + 1; return ord end
    local api = {}
    function api.Button(text, cb)
        local b = Instance.new("TextButton"); b.Parent = content; b.LayoutOrder = nextOrd()
        b.Size = UDim2.new(1, 0, 0, 28); b.BackgroundColor3 = COL_BTN; b.AutoButtonColor = true
        b.Font = Enum.Font.GothamMedium; b.TextSize = 13; b.TextColor3 = COL_TXT; b.Text = text; corner(b, 6)
        b.MouseButton1Click:Connect(function() pcall(cb) end); return b
    end
    function api.Toggle(text, default, cb)
        local state = default and true or false
        local b = Instance.new("TextButton"); b.Parent = content; b.LayoutOrder = nextOrd()
        b.Size = UDim2.new(1, 0, 0, 28); b.AutoButtonColor = true
        b.Font = Enum.Font.GothamMedium; b.TextSize = 13; b.TextColor3 = COL_TXT; corner(b, 6)
        local function paint2() b.BackgroundColor3 = state and COL_ON or COL_OFF; b.Text = (state and "[x]  " or "[  ]  ") .. text end
        paint2()
        b.MouseButton1Click:Connect(function() state = not state; paint2(); pcall(cb, state) end); return b
    end
    function api.Input(placeholder, btnText, cb)
        local row = Instance.new("Frame"); row.Parent = content; row.LayoutOrder = nextOrd()
        row.Size = UDim2.new(1, 0, 0, 28); row.BackgroundTransparency = 1
        local box = Instance.new("TextBox"); box.Parent = row
        box.Size = UDim2.new(1, -66, 1, 0); box.BackgroundColor3 = COL_BTN
        box.Font = Enum.Font.Gotham; box.TextSize = 13; box.TextColor3 = COL_TXT
        box.PlaceholderText = placeholder; box.Text = ""; box.ClearTextOnFocus = false
        box.TextXAlignment = Enum.TextXAlignment.Left; corner(box, 6); padL(box, 8)
        local b = Instance.new("TextButton"); b.Parent = row
        b.Size = UDim2.new(0, 60, 1, 0); b.Position = UDim2.new(1, -60, 0, 0)
        b.BackgroundColor3 = COL_ACC; b.Font = Enum.Font.GothamBold; b.TextSize = 13
        b.TextColor3 = Color3.fromRGB(10, 10, 10); b.Text = btnText or "OK"; corner(b, 6)
        b.MouseButton1Click:Connect(function() pcall(cb, box.Text) end); return box
    end
    function api.Label(getText)
        local l = Instance.new("TextLabel"); l.Parent = content; l.LayoutOrder = nextOrd()
        l.Size = UDim2.new(1, 0, 0, 32); l.BackgroundTransparency = 1
        l.TextXAlignment = Enum.TextXAlignment.Left; l.TextYAlignment = Enum.TextYAlignment.Top
        l.Font = Enum.Font.Gotham; l.TextSize = 12; l.TextColor3 = Color3.fromRGB(170, 200, 170)
        l.Text = ""; l.TextWrapped = true
        if type(getText) == "function" then
            task.spawn(function() while alive() and l.Parent do l.Text = tostring(getText()); task.wait(0.4) end end)
        end
        return l
    end
    return api
end

-- ═══════════════════════════════════════════════════════════════════════════════
--  РАЗДЕЛЫ  (сюда добавляем функции по твоим запросам)
-- ═══════════════════════════════════════════════════════════════════════════════

local Farm = Category("Auto-Farm - аукцион", true)
Farm.Input("макс ставка за лот", "Set", function(v) local n = tonumber(v); if n then farm.maxBid = n end end)
Farm.Toggle("AUTO-BID (выигрывать + собирать)", false, function(s) farm.on = s end)
Farm.Label(function() return (farm.on and "[ON] " or "[off] ") .. "бюджет " .. tostring(farm.maxBid) .. "  |  " .. farm.status end)

local Custom = Category("Custom / Raw", true)
Custom.Input("путь, напр Auction/UseXRay", "Fire", function(v) if v ~= "" then fireEvent(v) end end)
Custom.Input("путь RemoteFunction", "Invoke", function(v) if v ~= "" then warn("[admin] result:", invoke(v)) end end)

pcall(function()
    game:GetService("StarterGui"):SetCore("SendNotification", { Title = "Admin", Text = "Меню загружено", Duration = 4 })
end)
