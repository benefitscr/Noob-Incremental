-- ═══════════════════════════════════════════════════════════════════════════════
--  Noob Incremental · ADMIN MENU (custom)  ·  @Benefit
--  Каркас: перетаскиваемая панель + секции/кнопки/тумблеры/поля ввода.
--  Добавление действий — тривиально: Button("Название", function() ... end).
--  Ниже (секция ПРИМЕРЫ) показано, как вешать: remote (fire) и Cmdr-команды (cmd).
-- ═══════════════════════════════════════════════════════════════════════════════

local Players = game:GetService("Players")
local RS      = game:GetService("ReplicatedStorage")
local UIS     = game:GetService("UserInputService")
local LP      = Players.LocalPlayer

-- single-instance
_G.__NIADMIN = (_G.__NIADMIN or 0) + 1
local GEN = _G.__NIADMIN
local function alive() return _G.__NIADMIN == GEN end
pcall(function() if _G.__NIADMIN_gui then _G.__NIADMIN_gui:Destroy() end end)

-- ── wiring в игру (Storage Hunters) ───────────────────────────────────────────
-- Сеть: ReplicatedStorage.Events.<Категория>.<Ремоут>. RemoteEvent → FireServer,
-- RemoteFunction → InvokeServer. Путь пишем строкой "Auction/UseXRay".
local Events = RS:WaitForChild("Events")
local function remoteAt(path)
    local o = Events
    for part in path:gmatch("[^/]+") do o = o and o:FindFirstChild(part) end
    return o
end
local function fireEvent(path, ...)
    local r = remoteAt(path); local a = {...}
    if r and r:IsA("RemoteEvent") then pcall(function() r:FireServer(table.unpack(a)) end) end
end
local function invoke(path, ...)
    local r = remoteAt(path); local a = {...}
    if r and r:IsA("RemoteFunction") then
        local ok, res = pcall(function() return r:InvokeServer(table.unpack(a)) end)
        if ok then return res end
    end
end
local function netWorth()
    local ls = LP:FindFirstChild("leaderstats"); local nw = ls and ls:FindFirstChild("Net Worth")
    return nw and tostring(nw.Value) or "?"
end

-- ── GUI каркас ────────────────────────────────────────────────────────────────
local COL_BG   = Color3.fromRGB(16, 17, 22)
local COL_BAR  = Color3.fromRGB(24, 26, 34)
local COL_BTN  = Color3.fromRGB(38, 42, 54)
local COL_ACC  = Color3.fromRGB(120, 200, 255)
local COL_ON   = Color3.fromRGB(38, 140, 74)
local COL_OFF  = Color3.fromRGB(90, 46, 46)
local COL_TXT  = Color3.fromRGB(230, 230, 235)

local function corner(o, r) local c = Instance.new("UICorner", o); c.CornerRadius = UDim.new(0, r or 6) end
local function pad(o, n) local p = Instance.new("UIPadding", o); p.PaddingLeft = UDim.new(0, n); p.PaddingRight = UDim.new(0, n); p.PaddingTop = UDim.new(0, n); p.PaddingBottom = UDim.new(0, n) end

local gui = Instance.new("ScreenGui")
gui.Name = "NIAdmin"; gui.ResetOnSpawn = false; gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
pcall(function() gui.Parent = (gethui and gethui()) or game:GetService("CoreGui") end)
if not gui.Parent then gui.Parent = LP:WaitForChild("PlayerGui") end
_G.__NIADMIN_gui = gui

local win = Instance.new("Frame"); win.Parent = gui; win.Active = true
win.Size = UDim2.fromOffset(320, 420); win.Position = UDim2.fromOffset(40, 90)
win.BackgroundColor3 = COL_BG; win.BorderSizePixel = 0
corner(win, 10)

local bar = Instance.new("Frame"); bar.Parent = win; bar.Size = UDim2.new(1, 0, 0, 34)
bar.BackgroundColor3 = COL_BAR; bar.BorderSizePixel = 0; corner(bar, 10)
local barFix = Instance.new("Frame"); barFix.Parent = bar; barFix.Size = UDim2.new(1, 0, 0, 12)
barFix.Position = UDim2.new(0, 0, 1, -12); barFix.BackgroundColor3 = COL_BAR; barFix.BorderSizePixel = 0

local titleLbl = Instance.new("TextLabel"); titleLbl.Parent = bar
titleLbl.Size = UDim2.new(1, -70, 1, 0); titleLbl.Position = UDim2.fromOffset(12, 0)
titleLbl.BackgroundTransparency = 1; titleLbl.TextXAlignment = Enum.TextXAlignment.Left
titleLbl.Font = Enum.Font.GothamBold; titleLbl.TextSize = 15; titleLbl.TextColor3 = COL_ACC
titleLbl.Text = "🛠 Admin · Storage Hunters"

local minBtn = Instance.new("TextButton"); minBtn.Parent = bar
minBtn.Size = UDim2.fromOffset(28, 22); minBtn.Position = UDim2.new(1, -34, 0, 6)
minBtn.BackgroundColor3 = COL_BTN; minBtn.Font = Enum.Font.GothamBold; minBtn.TextSize = 16
minBtn.TextColor3 = COL_TXT; minBtn.Text = "—"; corner(minBtn, 5)

local scroll = Instance.new("ScrollingFrame"); scroll.Parent = win
scroll.Position = UDim2.fromOffset(0, 34); scroll.Size = UDim2.new(1, 0, 1, -34)
scroll.BackgroundTransparency = 1; scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 4; scroll.ScrollBarImageColor3 = COL_BTN
scroll.CanvasSize = UDim2.new(0, 0, 0, 0); scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
local list = Instance.new("UIListLayout", scroll); list.Padding = UDim.new(0, 6)
list.SortOrder = Enum.SortOrder.LayoutOrder
pad(scroll, 10)

-- collapse / drag
local collapsed = false
minBtn.MouseButton1Click:Connect(function()
    collapsed = not collapsed
    scroll.Visible = not collapsed
    win.Size = collapsed and UDim2.fromOffset(320, 34) or UDim2.fromOffset(320, 420)
    minBtn.Text = collapsed and "+" or "—"
end)
do
    local dragging, off
    bar.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true; off = Vector2.new(i.Position.X, i.Position.Y) - win.AbsolutePosition end end)
    bar.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end end)
    UIS.InputChanged:Connect(function(i) if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then win.Position = UDim2.fromOffset(i.Position.X - off.X, i.Position.Y - off.Y) end end)
end

-- ── API для добавления элементов ──────────────────────────────────────────────
local order = 0
local function nextOrder() order = order + 1; return order end

local function Section(text)
    local l = Instance.new("TextLabel"); l.Parent = scroll; l.LayoutOrder = nextOrder()
    l.Size = UDim2.new(1, 0, 0, 22); l.BackgroundTransparency = 1
    l.TextXAlignment = Enum.TextXAlignment.Left; l.Font = Enum.Font.GothamBold
    l.TextSize = 13; l.TextColor3 = COL_ACC; l.Text = text
    return l
end

local function Button(text, callback)
    local b = Instance.new("TextButton"); b.Parent = scroll; b.LayoutOrder = nextOrder()
    b.Size = UDim2.new(1, 0, 0, 30); b.BackgroundColor3 = COL_BTN; b.AutoButtonColor = true
    b.Font = Enum.Font.GothamMedium; b.TextSize = 13; b.TextColor3 = COL_TXT; b.Text = text
    corner(b, 6)
    b.MouseButton1Click:Connect(function() pcall(callback) end)
    return b
end

local function Toggle(text, default, callback)
    local state = default and true or false
    local b = Instance.new("TextButton"); b.Parent = scroll; b.LayoutOrder = nextOrder()
    b.Size = UDim2.new(1, 0, 0, 30); b.AutoButtonColor = true
    b.Font = Enum.Font.GothamMedium; b.TextSize = 13; b.TextColor3 = COL_TXT
    corner(b, 6)
    local function paint() b.BackgroundColor3 = state and COL_ON or COL_OFF; b.Text = (state and "☑ " or "☐ ") .. text end
    paint()
    b.MouseButton1Click:Connect(function() state = not state; paint(); pcall(callback, state) end)
    return b
end

-- поле ввода + кнопка (для команд с аргументом). callback получает текст поля.
local function Input(placeholder, btnText, callback)
    local row = Instance.new("Frame"); row.Parent = scroll; row.LayoutOrder = nextOrder()
    row.Size = UDim2.new(1, 0, 0, 30); row.BackgroundTransparency = 1
    local box = Instance.new("TextBox"); box.Parent = row
    box.Size = UDim2.new(1, -74, 1, 0); box.BackgroundColor3 = COL_BTN
    box.Font = Enum.Font.Gotham; box.TextSize = 13; box.TextColor3 = COL_TXT
    box.PlaceholderText = placeholder; box.Text = ""; box.ClearTextOnFocus = false
    box.TextXAlignment = Enum.TextXAlignment.Left; corner(box, 6)
    local bpad = Instance.new("UIPadding", box); bpad.PaddingLeft = UDim.new(0, 8)
    local b = Instance.new("TextButton"); b.Parent = row
    b.Size = UDim2.new(0, 68, 1, 0); b.Position = UDim2.new(1, -68, 0, 0)
    b.BackgroundColor3 = COL_ACC; b.Font = Enum.Font.GothamBold; b.TextSize = 13
    b.TextColor3 = Color3.fromRGB(10, 10, 10); b.Text = btnText or "OK"; corner(b, 6)
    b.MouseButton1Click:Connect(function() pcall(callback, box.Text) end)
    return box
end

-- ═══════════════════════════════════════════════════════════════════════════════
--  СЕКЦИИ  (здесь добавляем то, что ты попросишь)
-- ═══════════════════════════════════════════════════════════════════════════════

local nwLabel = Section("Net Worth: " .. netWorth())
task.spawn(function() while alive() do nwLabel.Text = "Net Worth: " .. netWorth(); task.wait(1) end end)

Section("Примеры (скажи — заменю на нужное)")

-- аукцион-хелперы (RemoteFunction → invoke)
Button("Use X-Ray", function() invoke("Auction/UseXRay") end)
Button("Use Calculator", function() invoke("Auction/UseCalculator") end)

-- сырой вызов: путь + жмёшь Fire (RemoteEvent) или Invoke (RemoteFunction)
Input("путь, напр Auction/UseXRay", "Fire", function(v) if v ~= "" then fireEvent(v) end end)
Input("путь RemoteFunction", "Invoke", function(v) if v ~= "" then warn("[admin] result:", invoke(v)) end end)

pcall(function()
    game:GetService("StarterGui"):SetCore("SendNotification", { Title = "Admin", Text = "Меню загружено", Duration = 4 })
end)
