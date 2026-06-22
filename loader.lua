-- Benefit Script Loader — Noob Incremental
local Players     = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local TweenService= game:GetService("TweenService")
local LP          = Players.LocalPlayer
local PG          = LP:WaitForChild("PlayerGui")

local API        = "https://gta6free.app"
local SCRIPT_URL = "https://raw.githubusercontent.com/benefitscr/Noob-Incremental/main/autofarm_luraph.lua"
local DISCORD    = "https://discord.gg/AXSnKF5R"

-- ─── Pre-fetch main script immediately in background ─────────────────────────
local scriptBody, scriptErr
task.spawn(function()
    local ok, r = pcall(game.HttpGet, game, SCRIPT_URL, true)
    if ok then scriptBody = r else scriptErr = r end
end)

-- ─── Lang ─────────────────────────────────────────────────────────────────────
local LANG = "en"
local T = {
    en = { title="Noob Incremental", sub="Benefit Script", label="Enter your key:",
           ph="BENEFIT-LT-XXXX-XXXX", activate="Activate", discord="Get key on Discord",
           checking="Checking...", invalid="Invalid key", srv_err="Server error",
           welcome="Welcome, ", fetching="Loading script...", nokey="Enter your key" },
    ru = { title="Noob Incremental", sub="Benefit Script", label="Введите ваш ключ:",
           ph="BENEFIT-LT-XXXX-XXXX", activate="Активировать", discord="Получить ключ в Discord",
           checking="Проверяем...", invalid="Неверный ключ", srv_err="Ошибка сервера",
           welcome="Добро пожаловать, ", fetching="Загружаем скрипт...", nokey="Введите ключ" },
}
local function L(k) return (T[LANG] and T[LANG][k]) or T.en[k] or k end

-- ─── GUI helpers ──────────────────────────────────────────────────────────────
local function make(cls, props, parent)
    local o = Instance.new(cls)
    for k,v in pairs(props) do o[k] = v end
    if parent then o.Parent = parent end
    return o
end
local function corner(r, p) make("UICorner",{CornerRadius=UDim.new(0,r)},p) end
local function tween(obj, t, props)
    TweenService:Create(obj, TweenInfo.new(t, Enum.EasingStyle.Quad), props):Play()
end

-- ─── Colors ───────────────────────────────────────────────────────────────────
local C = {
    bg      = Color3.fromRGB(10, 10, 14),
    surface = Color3.fromRGB(18, 18, 24),
    card    = Color3.fromRGB(24, 24, 32),
    border  = Color3.fromRGB(40, 40, 55),
    accent  = Color3.fromRGB(108, 92, 231),
    accentH = Color3.fromRGB(88, 72, 200),
    discord = Color3.fromRGB(88, 101, 242),
    white   = Color3.fromRGB(232, 232, 240),
    sub     = Color3.fromRGB(140, 140, 160),
    red     = Color3.fromRGB(220, 80, 80),
    green   = Color3.fromRGB(60, 180, 120),
    input   = Color3.fromRGB(14, 14, 20),
}

-- ─── Build GUI ────────────────────────────────────────────────────────────────
local sg = make("ScreenGui", {
    Name="BenefitLoader", ResetOnSpawn=false,
    ZIndexBehavior=Enum.ZIndexBehavior.Sibling,
    IgnoreGuiInset=true,
}, PG)

-- Backdrop
local backdrop = make("Frame", {
    Size=UDim2.fromScale(1,1), BackgroundColor3=Color3.fromRGB(0,0,0),
    BackgroundTransparency=0.4, BorderSizePixel=0,
}, sg)

-- Card
local card = make("Frame", {
    Size=UDim2.fromOffset(400, 0),
    AutomaticSize=Enum.AutomaticSize.Y,
    Position=UDim2.fromScale(0.5,0.5),
    AnchorPoint=Vector2.new(0.5,0.5),
    BackgroundColor3=C.surface,
    BorderSizePixel=0,
}, sg)
corner(14, card)

local pad = make("UIPadding",{
    PaddingTop=UDim.new(0,28), PaddingBottom=UDim.new(0,28),
    PaddingLeft=UDim.new(0,28), PaddingRight=UDim.new(0,28),
}, card)

local layout = make("UIListLayout",{
    FillDirection=Enum.FillDirection.Vertical,
    HorizontalAlignment=Enum.HorizontalAlignment.Center,
    SortOrder=Enum.SortOrder.LayoutOrder,
    Padding=UDim.new(0,12),
}, card)

-- Header row
local headerRow = make("Frame",{
    Size=UDim2.new(1,0,0,42), BackgroundTransparency=1, LayoutOrder=1,
}, card)

local titleLbl = make("TextLabel",{
    Size=UDim2.new(1,-60,1,0),
    BackgroundTransparency=1,
    Text=L("title"),
    TextColor3=C.white,
    TextSize=18,
    Font=Enum.Font.GothamBold,
    TextXAlignment=Enum.TextXAlignment.Left,
}, headerRow)

local subLbl = make("TextLabel",{
    Size=UDim2.new(1,-60,0,0),
    AutomaticSize=Enum.AutomaticSize.Y,
    Position=UDim2.fromOffset(0,22),
    BackgroundTransparency=1,
    Text=L("sub"),
    TextColor3=C.sub,
    TextSize=12,
    Font=Enum.Font.Gotham,
    TextXAlignment=Enum.TextXAlignment.Left,
}, headerRow)

-- Lang toggle button (top-right)
local langBtn = make("TextButton",{
    Size=UDim2.fromOffset(46,26),
    Position=UDim2.new(1,-46,0,8),
    BackgroundColor3=C.card,
    BorderSizePixel=0,
    Text="RU",
    TextColor3=C.sub,
    TextSize=12,
    Font=Enum.Font.GothamSemibold,
}, headerRow)
corner(6, langBtn)

-- Divider
local div = make("Frame",{
    Size=UDim2.new(1,0,0,1),
    BackgroundColor3=C.border,
    BorderSizePixel=0,
    LayoutOrder=2,
}, card)

-- Key label
local keyLbl = make("TextLabel",{
    Size=UDim2.new(1,0,0,16),
    BackgroundTransparency=1,
    Text=L("label"),
    TextColor3=C.sub,
    TextSize=12,
    Font=Enum.Font.GothamSemibold,
    TextXAlignment=Enum.TextXAlignment.Left,
    LayoutOrder=3,
}, card)

-- Input box
local inputFrame = make("Frame",{
    Size=UDim2.new(1,0,0,44),
    BackgroundColor3=C.input,
    BorderSizePixel=0,
    LayoutOrder=4,
}, card)
corner(8, inputFrame)
make("UIStroke",{Color=C.border,Thickness=1},inputFrame)

local inputBox = make("TextBox",{
    Size=UDim2.new(1,-16,1,0),
    Position=UDim2.fromOffset(8,0),
    BackgroundTransparency=1,
    PlaceholderText=L("ph"),
    PlaceholderColor3=C.sub,
    Text="",
    TextColor3=C.white,
    TextSize=14,
    Font=Enum.Font.GothamSemibold,
    ClearTextOnFocus=false,
    TextXAlignment=Enum.TextXAlignment.Left,
}, inputFrame)

-- Status label
local statusLbl = make("TextLabel",{
    Size=UDim2.new(1,0,0,16),
    BackgroundTransparency=1,
    Text="",
    TextColor3=C.sub,
    TextSize=12,
    Font=Enum.Font.Gotham,
    TextXAlignment=Enum.TextXAlignment.Center,
    LayoutOrder=5,
})
statusLbl.Parent = card

local function setStatus(msg, color)
    statusLbl.Text = msg
    statusLbl.TextColor3 = color or C.sub
end

-- Activate button
local activateBtn = make("TextButton",{
    Size=UDim2.new(1,0,0,44),
    BackgroundColor3=C.accent,
    BorderSizePixel=0,
    Text=L("activate"),
    TextColor3=C.white,
    TextSize=14,
    Font=Enum.Font.GothamBold,
    LayoutOrder=6,
}, card)
corner(8, activateBtn)

-- Discord button
local discordBtn = make("TextButton",{
    Size=UDim2.new(1,0,0,40),
    BackgroundColor3=C.card,
    BorderSizePixel=0,
    Text=L("discord"),
    TextColor3=C.sub,
    TextSize=13,
    Font=Enum.Font.Gotham,
    LayoutOrder=7,
}, card)
corner(8, discordBtn)

-- ─── Button hover effects ─────────────────────────────────────────────────────
activateBtn.MouseEnter:Connect(function() tween(activateBtn,.15,{BackgroundColor3=C.accentH}) end)
activateBtn.MouseLeave:Connect(function() tween(activateBtn,.15,{BackgroundColor3=C.accent}) end)
discordBtn.MouseEnter:Connect(function() tween(discordBtn,.15,{BackgroundColor3=C.discord}) end)
discordBtn.MouseLeave:Connect(function() tween(discordBtn,.15,{BackgroundColor3=C.card}) end)

-- ─── Input stroke focus ───────────────────────────────────────────────────────
local stroke = inputFrame:FindFirstChildOfClass("UIStroke")
inputBox.Focused:Connect(function() if stroke then tween(stroke,.15,{Color=C.accent}) end end)
inputBox.FocusLost:Connect(function() if stroke then tween(stroke,.15,{Color=C.border}) end end)

-- ─── Lang toggle ─────────────────────────────────────────────────────────────
langBtn.MouseButton1Click:Connect(function()
    LANG = LANG == "en" and "ru" or "en"
    langBtn.Text        = LANG == "en" and "RU" or "EN"
    titleLbl.Text       = L("title")
    subLbl.Text         = L("sub")
    keyLbl.Text         = L("label")
    inputBox.PlaceholderText = L("ph")
    activateBtn.Text    = L("activate")
    discordBtn.Text     = L("discord")
    setStatus("", C.sub)
end)

-- ─── Validate ─────────────────────────────────────────────────────────────────
local busy = false
local sessionId = nil

local function startHeartbeat()
    task.spawn(function()
        while true do
            task.wait(60)
            pcall(function()
                HttpService:PostAsync(
                    API.."/api/heartbeat",
                    HttpService:JSONEncode({sessionId=sessionId}),
                    Enum.HttpContentType.ApplicationJson
                )
            end)
        end
    end)
end

activateBtn.MouseButton1Click:Connect(function()
    if busy then return end
    local key = inputBox.Text:gsub("%s",""):upper()
    if key == "" then setStatus(L("nokey"), C.red); return end

    busy = true
    activateBtn.Text = L("checking")
    setStatus("", C.sub)

    local url = API.."/api/validate?key="..HttpService:UrlEncode(key).."&user="..HttpService:UrlEncode(LP.Name)
    local ok, body = pcall(function() return HttpService:GetAsync(url) end)

    if not ok then
        setStatus(L("srv_err"), C.red)
        activateBtn.Text = L("activate")
        busy = false
        return
    end

    local ok2, data = pcall(function() return HttpService:JSONDecode(body) end)
    if not ok2 or not data.valid then
        setStatus((ok2 and data and data.error) or L("invalid"), C.red)
        activateBtn.Text = L("activate")
        busy = false
        return
    end

    -- Key valid — wait for script if still downloading
    sessionId = data.sessionId
    setStatus(L("fetching"), C.green)
    activateBtn.Text = "..."

    local waited = 0
    while not scriptBody and not scriptErr and waited < 30 do
        task.wait(0.5); waited += 0.5
    end

    if not scriptBody then
        setStatus("Download failed. Try again.", C.red)
        activateBtn.Text = L("activate")
        busy = false
        return
    end

    startHeartbeat()
    setStatus(L("welcome")..LP.Name, C.green)
    task.wait(0.8)
    sg:Destroy()
    loadstring(scriptBody)()
end)

-- ─── Discord ──────────────────────────────────────────────────────────────────
discordBtn.MouseButton1Click:Connect(function()
    pcall(setclipboard, DISCORD)
    setStatus("Discord link copied!", C.green)
    task.delay(3, function() setStatus("", C.sub) end)
end)
