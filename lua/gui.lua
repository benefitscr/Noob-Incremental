-- ╔══════════════════════════════════════════════════════════════════╗
-- ║  gui.lua  —  Custom GUI  (drop-in Fluent replacement)           ║
-- ║  API-compatible with autofarm.lua v8.0 · @Benefit               ║
-- ╚══════════════════════════════════════════════════════════════════╝

local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players          = game:GetService("Players")
local LP               = Players.LocalPlayer

-- ─── Palette ──────────────────────────────────────────────────────────────────
local C = {
    WinBg       = Color3.fromRGB(13,  13,  18),
    PanelBg     = Color3.fromRGB(18,  18,  26),
    RowBg       = Color3.fromRGB(24,  24,  36),
    RowHover    = Color3.fromRGB(32,  32,  48),
    Accent      = Color3.fromRGB(108, 96,  220),
    AccentHov   = Color3.fromRGB(128, 116, 240),
    TabSel      = Color3.fromRGB(35,  30,  65),
    Text        = Color3.fromRGB(230, 230, 236),
    SubText     = Color3.fromRGB(140, 140, 155),
    ToggleOn    = Color3.fromRGB(72,  195, 115),
    ToggleOff   = Color3.fromRGB(40,  40,  58),
    InputBg     = Color3.fromRGB(14,  14,  20),
    Border      = Color3.fromRGB(40,  40,  56),
    NotifBg     = Color3.fromRGB(20,  20,  30),
}
local FONT     = Enum.Font.GothamBold
local FONT_REG = Enum.Font.Gotham
local TINFO_FAST = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TINFO_MED  = TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

-- ─── Helpers ──────────────────────────────────────────────────────────────────
local function newInst(cls, props, parent)
    local i = Instance.new(cls)
    for k, v in pairs(props) do i[k] = v end
    if parent then i.Parent = parent end
    return i
end

local function corner(r, parent)
    return newInst("UICorner", {CornerRadius = UDim.new(0, r)}, parent)
end

local function stroke(thickness, color, parent)
    return newInst("UIStroke", {
        Thickness       = thickness,
        Color           = color,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    }, parent)
end

local function tween(obj, props, info)
    TweenService:Create(obj, info or TINFO_FAST, props):Play()
end

local function label(props, parent)
    local defaults = {
        BackgroundTransparency = 1,
        TextColor3             = Color3.fromRGB(230, 230, 236),
        Font                   = Enum.Font.Gotham,
        TextSize               = 13,
        TextXAlignment         = Enum.TextXAlignment.Left,
        TextYAlignment         = Enum.TextYAlignment.Center,
        TextTruncate           = Enum.TextTruncate.AtEnd,
    }
    for k, v in pairs(props) do defaults[k] = v end
    return newInst("TextLabel", defaults, parent)
end

local function countLines(s)
    local n = 1
    for _ in tostring(s):gmatch("\n") do n = n + 1 end
    return n
end

-- ─── ScreenGuis ───────────────────────────────────────────────────────────────
local playerGui = LP:WaitForChild("PlayerGui")

local notifGui = newInst("ScreenGui", {
    Name           = "GuiNotifications",
    ResetOnSpawn   = false,
    DisplayOrder   = 1000,
    IgnoreGuiInset = true,
}, playerGui)

local screenGui = newInst("ScreenGui", {
    Name           = "CustomGui",
    ResetOnSpawn   = false,
    DisplayOrder   = 100,
    IgnoreGuiInset = true,
}, playerGui)

local floatGui = newInst("ScreenGui", {
    Name           = "GuiFloatToggle",
    ResetOnSpawn   = false,
    DisplayOrder   = 999,
    IgnoreGuiInset = true,
}, playerGui)

-- ─── Notification Stack ───────────────────────────────────────────────────────
local notifStack            = {}
local NOTIF_W, NOTIF_H, NOTIF_PAD = 290, 68, 8

local function repositionNotifs()
    for i, frame in ipairs(notifStack) do
        local y = 12 + (i - 1) * (NOTIF_H + NOTIF_PAD)
        tween(frame, {Position = UDim2.new(1, -(NOTIF_W + 12), 0, y)}, TINFO_MED)
    end
end

local function notify(opts)
    local title    = opts.Title    or ""
    local content  = opts.Content  or ""
    local duration = opts.Duration or 4

    local frame = newInst("Frame", {
        Size             = UDim2.fromOffset(NOTIF_W, NOTIF_H),
        Position         = UDim2.new(1, 12, 0, 12),
        BackgroundColor3 = C.NotifBg,
        BorderSizePixel  = 0,
        ZIndex           = 10,
    }, notifGui)
    corner(8, frame)
    stroke(1, C.Border, frame)

    -- purple left accent bar
    newInst("Frame", {
        Size             = UDim2.new(0, 4, 1, 0),
        BackgroundColor3 = C.Accent,
        BorderSizePixel  = 0,
        ZIndex           = 11,
    }, frame)

    label({
        Text     = title,
        Size     = UDim2.new(1, -16, 0, 22),
        Position = UDim2.new(0, 12, 0, 6),
        Font     = FONT,
        TextSize = 13,
        ZIndex   = 11,
    }, frame)

    label({
        Text           = content,
        Size           = UDim2.new(1, -16, 0, 34),
        Position       = UDim2.new(0, 12, 0, 28),
        TextSize       = 12,
        TextColor3     = C.SubText,
        TextWrapped    = true,
        TextYAlignment = Enum.TextYAlignment.Top,
        TextTruncate   = Enum.TextTruncate.None,
        ZIndex         = 11,
    }, frame)

    notifStack[#notifStack + 1] = frame
    repositionNotifs()

    task.delay(duration, function()
        -- slide out to the right
        tween(frame, {Position = UDim2.new(1, 12, 0, frame.Position.Y.Offset)}, TINFO_MED)
        task.wait(0.32)
        -- remove from stack before destroy so repositionNotifs works cleanly
        for i, f in ipairs(notifStack) do
            if f == frame then table.remove(notifStack, i); break end
        end
        pcall(function() frame:Destroy() end)
        repositionNotifs()
    end)
end

-- ─── Window Frame ─────────────────────────────────────────────────────────────
local FULL_HEIGHT = 500
local MINI_HEIGHT = 46
local minimized   = false

local winFrame = newInst("Frame", {
    Size             = UDim2.fromOffset(610, FULL_HEIGHT),
    Position         = UDim2.new(0.5, -305, 0.5, -250),
    BackgroundColor3 = C.WinBg,
    BorderSizePixel  = 0,
    ClipsDescendants = false,
    Visible          = true,
    ZIndex           = 2,
}, screenGui)
corner(12, winFrame)
stroke(1, C.Border, winFrame)

-- Title bar
local titleBar = newInst("Frame", {
    Size             = UDim2.new(1, 0, 0, MINI_HEIGHT),
    BackgroundColor3 = C.PanelBg,
    BorderSizePixel  = 0,
    ZIndex           = 3,
}, winFrame)
newInst("UICorner", {CornerRadius = UDim.new(0, 12)}, titleBar)
-- hide lower rounded corners of title bar
newInst("Frame", {
    Size             = UDim2.new(1, 0, 0, 12),
    Position         = UDim2.new(0, 0, 1, -12),
    BackgroundColor3 = C.PanelBg,
    BorderSizePixel  = 0,
    ZIndex           = 3,
}, titleBar)

local titleLbl = label({
    Text     = "Noob Incremental",
    Size     = UDim2.new(0, 300, 0, 26),
    Position = UDim2.new(0, 14, 0, 4),
    Font     = FONT,
    TextSize = 15,
    ZIndex   = 4,
}, titleBar)

local subLbl = label({
    Text       = "v8.0 · @Benefit",
    Size       = UDim2.new(0, 300, 0, 18),
    Position   = UDim2.new(0, 14, 0, 26),
    TextSize   = 11,
    TextColor3 = C.SubText,
    ZIndex     = 4,
}, titleBar)

-- Close button
local closeBtn = newInst("TextButton", {
    Size             = UDim2.fromOffset(28, 28),
    Position         = UDim2.new(1, -36, 0, 9),
    BackgroundColor3 = Color3.fromRGB(180, 50, 50),
    Text             = "✕",
    TextColor3       = C.Text,
    Font             = FONT,
    TextSize         = 13,
    BorderSizePixel  = 0,
    ZIndex           = 5,
    AutoButtonColor  = false,
}, titleBar)
corner(6, closeBtn)

-- Minimize button
local minimizeBtn = newInst("TextButton", {
    Size             = UDim2.fromOffset(28, 28),
    Position         = UDim2.new(1, -68, 0, 9),
    BackgroundColor3 = C.RowBg,
    Text             = "—",
    TextColor3       = C.Text,
    Font             = FONT,
    TextSize         = 13,
    BorderSizePixel  = 0,
    ZIndex           = 5,
    AutoButtonColor  = false,
}, titleBar)
corner(6, minimizeBtn)

-- Tab strip (34px, below title bar)
local tabStrip = newInst("ScrollingFrame", {
    Size                 = UDim2.new(1, 0, 0, 34),
    Position             = UDim2.new(0, 0, 0, MINI_HEIGHT),
    BackgroundColor3     = C.PanelBg,
    BorderSizePixel      = 0,
    ScrollBarThickness   = 0,
    ScrollingDirection   = Enum.ScrollingDirection.X,
    CanvasSize           = UDim2.fromOffset(0, 34),
    AutomaticCanvasSize  = Enum.AutomaticSize.X,
    ZIndex               = 3,
    ClipsDescendants     = true,
    Visible              = true,
}, winFrame)
newInst("UIListLayout", {
    FillDirection = Enum.FillDirection.Horizontal,
    SortOrder     = Enum.SortOrder.LayoutOrder,
    Padding       = UDim.new(0, 2),
}, tabStrip)
newInst("UIPadding", {
    PaddingLeft   = UDim.new(0, 6),
    PaddingTop    = UDim.new(0, 3),
    PaddingBottom = UDim.new(0, 3),
}, tabStrip)

-- Content area (fills remainder below title+tabs)
local contentArea = newInst("Frame", {
    Size             = UDim2.new(1, 0, 1, -(MINI_HEIGHT + 34)),
    Position         = UDim2.new(0, 0, 0, MINI_HEIGHT + 34),
    BackgroundColor3 = C.WinBg,
    BorderSizePixel  = 0,
    ZIndex           = 2,
    ClipsDescendants = true,
    Visible          = true,
}, winFrame)

-- ─── Floating Toggle Button ───────────────────────────────────────────────────
local floatBtn = newInst("TextButton", {
    Size             = UDim2.fromOffset(48, 48),
    Position         = UDim2.new(1, -58, 0.5, -24),
    BackgroundColor3 = C.Accent,
    Text             = "☰",
    TextColor3       = C.Text,
    Font             = FONT,
    TextSize         = 20,
    BorderSizePixel  = 0,
    ZIndex           = 10,
    AutoButtonColor  = false,
}, floatGui)
corner(12, floatBtn)
stroke(1, C.Border, floatBtn)

-- ─── Dragging (window) ────────────────────────────────────────────────────────
do
    local dragging, dragStart, startPos
    titleBar.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1
        or inp.UserInputType == Enum.UserInputType.Touch then
            dragging  = true
            dragStart = inp.Position
            startPos  = winFrame.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if not dragging then return end
        if inp.UserInputType == Enum.UserInputType.MouseMovement
        or inp.UserInputType == Enum.UserInputType.Touch then
            local d = inp.Position - dragStart
            winFrame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + d.X,
                startPos.Y.Scale, startPos.Y.Offset + d.Y
            )
        end
    end)
    UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1
        or inp.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
end

-- ─── Float button — drag + tap ────────────────────────────────────────────────
do
    local TAP_THRESH = 12
    local pressing   = false
    local pressStart = Vector2.new()
    local btnStart

    floatBtn.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1
        or inp.UserInputType == Enum.UserInputType.Touch then
            pressing   = true
            pressStart = Vector2.new(inp.Position.X, inp.Position.Y)
            btnStart   = floatBtn.Position
        end
    end)

    UserInputService.InputChanged:Connect(function(inp)
        if not pressing then return end
        if inp.UserInputType == Enum.UserInputType.MouseMovement
        or inp.UserInputType == Enum.UserInputType.Touch then
            local delta = Vector2.new(inp.Position.X, inp.Position.Y) - pressStart
            if delta.Magnitude > TAP_THRESH then
                floatBtn.Position = UDim2.new(
                    btnStart.X.Scale, btnStart.X.Offset + delta.X,
                    btnStart.Y.Scale, btnStart.Y.Offset + delta.Y
                )
            end
        end
    end)

    UserInputService.InputEnded:Connect(function(inp)
        if not pressing then return end
        if inp.UserInputType == Enum.UserInputType.MouseButton1
        or inp.UserInputType == Enum.UserInputType.Touch then
            pressing = false
            local delta = Vector2.new(inp.Position.X, inp.Position.Y) - pressStart
            if delta.Magnitude <= TAP_THRESH then
                winFrame.Visible = not winFrame.Visible
                floatBtn.Text    = winFrame.Visible and "☰" or "▶"
            end
        end
    end)
end

-- ─── Minimize / Close ─────────────────────────────────────────────────────────
local function doMinimize()
    minimized = not minimized
    minimizeBtn.Text    = minimized and "▲" or "—"
    local targetH = minimized and MINI_HEIGHT or FULL_HEIGHT
    tween(winFrame, {Size = UDim2.fromOffset(winFrame.AbsoluteSize.X, targetH)}, TINFO_MED)
    contentArea.Visible = not minimized
    tabStrip.Visible    = not minimized
end

minimizeBtn.MouseButton1Click:Connect(doMinimize)

closeBtn.MouseButton1Click:Connect(function()
    winFrame.Visible = false
    floatBtn.Text    = "▶"
end)

-- ─── Dropdown overlay (shared singleton) ──────────────────────────────────────
local activeDropdown = nil

local function closeActiveDropdown()
    if activeDropdown then
        pcall(function() activeDropdown:Destroy() end)
        activeDropdown = nil
    end
end

UserInputService.InputBegan:Connect(function(inp)
    if inp.UserInputType ~= Enum.UserInputType.MouseButton1
    and inp.UserInputType ~= Enum.UserInputType.Touch then return end
    if not activeDropdown then return end
    local mx, my = inp.Position.X, inp.Position.Y
    local ap = activeDropdown.AbsolutePosition
    local as = activeDropdown.AbsoluteSize
    if mx < ap.X or mx > ap.X + as.X or my < ap.Y or my > ap.Y + as.Y then
        closeActiveDropdown()
    end
end)

-- ─── Tab management ───────────────────────────────────────────────────────────
local tabs         = {}
local activeTabIdx = 0

local function selectTab(idx)
    closeActiveDropdown()
    if activeTabIdx == idx then return end
    for _, t in ipairs(tabs) do
        local sel = (t.index == idx)
        tween(t.btn, {BackgroundColor3 = sel and C.TabSel or C.PanelBg}, TINFO_FAST)
        t.scroll.Visible = sel
    end
    activeTabIdx = idx
end

-- ─── Row builder ──────────────────────────────────────────────────────────────
local function makeRow(scroll, minH)
    minH = minH or 44
    local row = newInst("Frame", {
        Size             = UDim2.new(1, 0, 0, minH),
        BackgroundColor3 = C.RowBg,
        BorderSizePixel  = 0,
        ZIndex           = 5,
    }, scroll)
    corner(7, row)

    -- transparent hover overlay
    local hovBtn = newInst("TextButton", {
        Size                  = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text                  = "",
        ZIndex                = 6,
    }, row)
    hovBtn.MouseEnter:Connect(function() tween(row, {BackgroundColor3 = C.RowHover}, TINFO_FAST) end)
    hovBtn.MouseLeave:Connect(function() tween(row, {BackgroundColor3 = C.RowBg},    TINFO_FAST) end)
    return row, hovBtn
end

-- ─── addTab ───────────────────────────────────────────────────────────────────
local function addTab(_window, opts)
    opts = opts or {}
    local title = opts.Title or "Tab"
    local idx   = #tabs + 1

    -- Tab button in strip
    local btn = newInst("TextButton", {
        Size             = UDim2.new(0, 0, 1, 0),
        AutomaticSize    = Enum.AutomaticSize.X,
        BackgroundColor3 = C.PanelBg,
        Text             = title,
        TextColor3       = C.Text,
        Font             = FONT,
        TextSize         = 13,
        BorderSizePixel  = 0,
        ZIndex           = 4,
        AutoButtonColor  = false,
        LayoutOrder      = idx,
    }, tabStrip)
    corner(6, btn)
    newInst("UIPadding", {
        PaddingLeft  = UDim.new(0, 10),
        PaddingRight = UDim.new(0, 10),
    }, btn)

    -- Content scroll for this tab
    local scroll = newInst("ScrollingFrame", {
        Size                 = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        BorderSizePixel      = 0,
        ScrollBarThickness   = 4,
        ScrollBarImageColor3 = C.Border,
        CanvasSize           = UDim2.fromOffset(0, 0),
        AutomaticCanvasSize  = Enum.AutomaticSize.Y,
        ScrollingDirection   = Enum.ScrollingDirection.Y,
        Visible              = false,
        ZIndex               = 3,
    }, contentArea)
    newInst("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding   = UDim.new(0, 4),
    }, scroll)
    newInst("UIPadding", {
        PaddingLeft   = UDim.new(0, 8),
        PaddingRight  = UDim.new(0, 8),
        PaddingTop    = UDim.new(0, 6),
        PaddingBottom = UDim.new(0, 6),
    }, scroll)

    btn.MouseButton1Click:Connect(function() selectTab(idx) end)

    tabs[idx] = {btn = btn, scroll = scroll, index = idx}
    if idx == 1 then selectTab(1) end

    -- ── Helper: get next layout order ─────────────────────────────────────────
    local function nextOrder()
        local n = 0
        for _, c in ipairs(scroll:GetChildren()) do
            if c:IsA("Frame") or c:IsA("ScrollingFrame") then
                n = n + 1
            end
        end
        return n
    end

    local Tab = {}

    -- ── AddParagraph ──────────────────────────────────────────────────────────
    function Tab:AddParagraph(opts2)
        opts2 = opts2 or {}
        local tt = opts2.Title   or ""
        local ct = opts2.Content or ""

        local function calcRowH(t2, c2)
            local lines = countLines(c2)
            local h = (t2 ~= "" and 20 or 0) + math.max(lines, 1) * 16 + 14
            return math.max(h, 28)
        end

        local row = newInst("Frame", {
            Size             = UDim2.new(1, 0, 0, calcRowH(tt, ct)),
            BackgroundColor3 = C.PanelBg,
            BorderSizePixel  = 0,
            ZIndex           = 5,
            LayoutOrder      = nextOrder(),
        }, scroll)
        corner(6, row)

        local lyt = newInst("UIListLayout", {
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding   = UDim.new(0, 2),
        }, row)
        newInst("UIPadding", {
            PaddingLeft   = UDim.new(0, 10),
            PaddingRight  = UDim.new(0, 10),
            PaddingTop    = UDim.new(0, 6),
            PaddingBottom = UDim.new(0, 6),
        }, row)

        local titleLbl2 = nil
        if tt ~= "" then
            titleLbl2 = label({
                Text        = tt,
                Size        = UDim2.new(1, 0, 0, 18),
                Font        = FONT,
                TextSize    = 12,
                TextColor3  = C.SubText,
                ZIndex      = 6,
                LayoutOrder = 1,
            }, row)
        end

        local ctLbl = label({
            Text           = ct,
            Size           = UDim2.new(1, 0, 0, math.max(countLines(ct), 1) * 16),
            TextSize       = 12,
            TextWrapped    = true,
            TextYAlignment = Enum.TextYAlignment.Top,
            TextTruncate   = Enum.TextTruncate.None,
            ZIndex         = 6,
            LayoutOrder    = 2,
        }, row)

        lyt:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            row.Size = UDim2.new(1, 0, 0, math.max(lyt.AbsoluteContentSize.Y + 14, 28))
        end)

        local para = {}
        function para:Set(o)
            o = o or {}
            if o.Title   ~= nil and titleLbl2 then titleLbl2.Text = o.Title end
            if o.Content ~= nil then
                ctLbl.Text = o.Content
                ctLbl.Size = UDim2.new(1, 0, 0, math.max(countLines(o.Content), 1) * 16)
            end
        end
        function para:OnChanged(_fn) return para end
        return para
    end

    -- ── AddToggle ─────────────────────────────────────────────────────────────
    function Tab:AddToggle(_key, opts2)
        opts2 = opts2 or {}
        local titleText = opts2.Title   or ""
        local value     = opts2.Default == true
        local callbacks = {}

        local row, rowBtn = makeRow(scroll, 44)
        row.LayoutOrder = nextOrder()

        label({
            Text     = titleText,
            Size     = UDim2.new(1, -64, 1, 0),
            Position = UDim2.new(0, 12, 0, 0),
            Font     = FONT,
            TextSize = 13,
            ZIndex   = 7,
        }, row)

        -- Track
        local track = newInst("Frame", {
            Size             = UDim2.fromOffset(40, 22),
            Position         = UDim2.new(1, -52, 0.5, -11),
            BackgroundColor3 = value and C.ToggleOn or C.ToggleOff,
            BorderSizePixel  = 0,
            ZIndex           = 7,
        }, row)
        corner(11, track)

        -- Thumb
        local thumb = newInst("Frame", {
            Size             = UDim2.fromOffset(16, 16),
            Position         = value and UDim2.new(0, 21, 0.5, -8) or UDim2.new(0, 3, 0.5, -8),
            BackgroundColor3 = C.Text,
            BorderSizePixel  = 0,
            ZIndex           = 8,
        }, track)
        corner(8, thumb)

        local tog = {}

        local function set(v, fire)
            value = v
            tween(track, {BackgroundColor3 = v and C.ToggleOn or C.ToggleOff}, TINFO_FAST)
            tween(thumb, {
                Position = v and UDim2.new(0, 21, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
            }, TINFO_FAST)
            if fire then
                for _, cb in ipairs(callbacks) do pcall(cb, v) end
            end
        end

        rowBtn.MouseButton1Click:Connect(function() set(not value, true) end)

        function tog:OnChanged(fn) callbacks[#callbacks + 1] = fn; return tog end
        function tog:Set(v)       set(v, true)  end
        function tog:Get()        return value  end
        return tog
    end

    -- ── AddButton ─────────────────────────────────────────────────────────────
    function Tab:AddButton(opts2)
        opts2 = opts2 or {}
        local titleText = opts2.Title    or "Button"
        local callback  = opts2.Callback or function() end

        local row = newInst("Frame", {
            Size             = UDim2.new(1, 0, 0, 44),
            BackgroundColor3 = C.RowBg,
            BorderSizePixel  = 0,
            ZIndex           = 5,
            LayoutOrder      = nextOrder(),
        }, scroll)
        corner(7, row)

        local btn2 = newInst("TextButton", {
            Size             = UDim2.new(1, -24, 0, 32),
            Position         = UDim2.new(0, 12, 0.5, -16),
            BackgroundColor3 = C.Accent,
            Text             = titleText,
            TextColor3       = C.Text,
            Font             = FONT,
            TextSize         = 13,
            BorderSizePixel  = 0,
            ZIndex           = 6,
            AutoButtonColor  = false,
        }, row)
        corner(7, btn2)

        btn2.MouseEnter:Connect(function()
            tween(btn2, {BackgroundColor3 = C.AccentHov}, TINFO_FAST)
        end)
        btn2.MouseLeave:Connect(function()
            tween(btn2, {BackgroundColor3 = C.Accent}, TINFO_FAST)
        end)
        btn2.MouseButton1Click:Connect(function()
            tween(btn2, {BackgroundColor3 = C.AccentHov}, TINFO_FAST)
            task.delay(0.12, function()
                tween(btn2, {BackgroundColor3 = C.Accent}, TINFO_FAST)
            end)
            pcall(callback)
        end)

        return {}
    end

    -- ── AddDropdown ───────────────────────────────────────────────────────────
    function Tab:AddDropdown(_key, opts2)
        opts2 = opts2 or {}
        local titleText = opts2.Title  or ""
        local values    = opts2.Values or {}
        local multi     = opts2.Multi  == true
        local default   = opts2.Default
        local callbacks = {}

        -- Normalise selection state
        local selected  -- string (single) or table keyed {val=true} (multi)
        if multi then
            selected = {}
            if type(default) == "table" then
                for k, v in pairs(default) do if v then selected[k] = true end end
            end
        else
            if type(default) == "string" then
                selected = default
            elseif values[1] then
                selected = values[1]
            else
                selected = ""
            end
        end

        local function displayText()
            if multi then
                local parts = {}
                for k, v in pairs(selected) do if v then parts[#parts + 1] = k end end
                table.sort(parts)
                return #parts == 0 and "None" or table.concat(parts, ", ")
            else
                return tostring(selected or "")
            end
        end

        local row = newInst("Frame", {
            Size             = UDim2.new(1, 0, 0, 72),
            BackgroundColor3 = C.RowBg,
            BorderSizePixel  = 0,
            ZIndex           = 5,
            LayoutOrder      = nextOrder(),
        }, scroll)
        corner(7, row)

        label({
            Text     = titleText,
            Size     = UDim2.new(1, -16, 0, 22),
            Position = UDim2.new(0, 12, 0, 6),
            Font     = FONT,
            TextSize = 13,
            ZIndex   = 6,
        }, row)

        local dropBtn2 = newInst("TextButton", {
            Size             = UDim2.new(1, -24, 0, 30),
            Position         = UDim2.new(0, 12, 0, 32),
            BackgroundColor3 = C.InputBg,
            Text             = "",
            BorderSizePixel  = 0,
            ZIndex           = 6,
            AutoButtonColor  = false,
        }, row)
        corner(6, dropBtn2)
        stroke(1, C.Border, dropBtn2)

        local selLabel = label({
            Text       = displayText(),
            Size       = UDim2.new(1, -36, 1, 0),
            Position   = UDim2.new(0, 10, 0, 0),
            TextSize   = 12,
            TextColor3 = C.Text,
            ZIndex     = 7,
        }, dropBtn2)

        label({
            Text           = "▾",
            Size           = UDim2.new(0, 24, 1, 0),
            Position       = UDim2.new(1, -28, 0, 0),
            TextSize       = 12,
            TextColor3     = C.SubText,
            TextXAlignment = Enum.TextXAlignment.Center,
            ZIndex         = 7,
        }, dropBtn2)

        local function fireCallbacks()
            for _, cb in ipairs(callbacks) do pcall(cb, selected) end
        end

        dropBtn2.MouseButton1Click:Connect(function()
            -- Toggle: if our overlay is already open, close it
            if activeDropdown then
                closeActiveDropdown()
                return
            end

            local ITEM_H    = 36
            local MAX_SHOWN = 7
            local listH     = math.min(#values, MAX_SHOWN) * ITEM_H
            if listH == 0 then return end

            local rowAP = row.AbsolutePosition
            local rowAS = row.AbsoluteSize

            local overlay = newInst("ScrollingFrame", {
                Size                 = UDim2.fromOffset(rowAS.X - 24, listH),
                Position             = UDim2.fromOffset(rowAP.X + 12, rowAP.Y + rowAS.Y),
                BackgroundColor3     = C.PanelBg,
                BorderSizePixel      = 0,
                ScrollBarThickness   = 4,
                ScrollBarImageColor3 = C.Border,
                CanvasSize           = UDim2.fromOffset(0, #values * ITEM_H),
                ZIndex               = 20,
                ClipsDescendants     = true,
            }, screenGui)
            corner(8, overlay)
            stroke(1, C.Border, overlay)
            newInst("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder}, overlay)
            activeDropdown = overlay

            for vi, val in ipairs(values) do
                local isOn = multi and (selected[val] == true) or (selected == val)

                local item = newInst("TextButton", {
                    Size             = UDim2.new(1, 0, 0, ITEM_H),
                    BackgroundColor3 = isOn and C.TabSel or C.PanelBg,
                    Text             = "",
                    BorderSizePixel  = 0,
                    ZIndex           = 21,
                    AutoButtonColor  = false,
                    LayoutOrder      = vi,
                }, overlay)

                label({
                    Text      = val,
                    Size      = UDim2.new(1, -44, 1, 0),
                    Position  = UDim2.new(0, 12, 0, 0),
                    TextSize  = 13,
                    ZIndex    = 22,
                }, item)

                local chk = label({
                    Text           = isOn and "✓" or "",
                    Size           = UDim2.new(0, 28, 1, 0),
                    Position       = UDim2.new(1, -32, 0, 0),
                    TextSize       = 13,
                    TextColor3     = C.ToggleOn,
                    TextXAlignment = Enum.TextXAlignment.Center,
                    ZIndex         = 22,
                }, item)

                item.MouseEnter:Connect(function()
                    tween(item, {BackgroundColor3 = C.RowHover}, TINFO_FAST)
                end)
                item.MouseLeave:Connect(function()
                    local on2 = multi and (selected[val] == true) or (selected == val)
                    tween(item, {BackgroundColor3 = on2 and C.TabSel or C.PanelBg}, TINFO_FAST)
                end)

                item.MouseButton1Click:Connect(function()
                    if multi then
                        selected[val] = not selected[val]
                        local nowOn = selected[val] == true
                        chk.Text = nowOn and "✓" or ""
                        tween(item, {BackgroundColor3 = nowOn and C.TabSel or C.PanelBg}, TINFO_FAST)
                        selLabel.Text = displayText()
                        fireCallbacks()
                    else
                        selected = val
                        selLabel.Text = displayText()
                        fireCallbacks()
                        closeActiveDropdown()
                    end
                end)
            end
        end)

        local dd = {}
        function dd:OnChanged(fn) callbacks[#callbacks + 1] = fn; return dd end
        function dd:Set(v)
            selected = v
            selLabel.Text = displayText()
        end
        function dd:Get() return selected end
        return dd
    end

    -- ── AddSlider ─────────────────────────────────────────────────────────────
    function Tab:AddSlider(_key, opts2)
        opts2 = opts2 or {}
        local titleText = opts2.Title    or ""
        local minVal    = opts2.Min      or 0
        local maxVal    = opts2.Max      or 1
        local rounding  = opts2.Rounding or 2
        local value     = math.clamp(opts2.Default or minVal, minVal, maxVal)
        local callbacks = {}

        local function fmt(v)
            if rounding == 0 then return tostring(math.floor(v + 0.5)) end
            return string.format("%." .. rounding .. "f", v)
        end
        local function pct()
            return (value - minVal) / math.max(maxVal - minVal, 1e-6)
        end

        local row = newInst("Frame", {
            Size             = UDim2.new(1, 0, 0, 72),
            BackgroundColor3 = C.RowBg,
            BorderSizePixel  = 0,
            ZIndex           = 5,
            LayoutOrder      = nextOrder(),
        }, scroll)
        corner(7, row)

        -- header row with title + value
        local hdrRow = newInst("Frame", {
            Size                  = UDim2.new(1, 0, 0, 26),
            Position              = UDim2.new(0, 0, 0, 8),
            BackgroundTransparency = 1,
            ZIndex                = 6,
        }, row)

        label({
            Text     = titleText,
            Size     = UDim2.new(0.7, -12, 1, 0),
            Position = UDim2.new(0, 12, 0, 0),
            Font     = FONT,
            TextSize = 13,
            ZIndex   = 6,
        }, hdrRow)

        local valLbl = label({
            Text           = fmt(value),
            Size           = UDim2.new(0.3, -12, 1, 0),
            Position       = UDim2.new(0.7, 0, 0, 0),
            TextSize       = 12,
            TextColor3     = C.SubText,
            TextXAlignment = Enum.TextXAlignment.Right,
            ZIndex         = 6,
        }, hdrRow)

        -- track background
        local trackBg = newInst("Frame", {
            Size             = UDim2.new(1, -24, 0, 8),
            Position         = UDim2.new(0, 12, 0, 46),
            BackgroundColor3 = C.ToggleOff,
            BorderSizePixel  = 0,
            ZIndex           = 6,
        }, row)
        corner(4, trackBg)

        -- fill
        local fill = newInst("Frame", {
            Size             = UDim2.new(pct(), 0, 1, 0),
            BackgroundColor3 = C.Accent,
            BorderSizePixel  = 0,
            ZIndex           = 7,
        }, trackBg)
        corner(4, fill)

        -- thumb
        local thumb = newInst("Frame", {
            Size             = UDim2.fromOffset(18, 18),
            Position         = UDim2.new(pct(), -9, 0.5, -9),
            BackgroundColor3 = C.Text,
            BorderSizePixel  = 0,
            ZIndex           = 8,
        }, trackBg)
        corner(9, thumb)
        stroke(2, C.Accent, thumb)

        local sliderDrag = false

        local function setFromAbsX(absX)
            local ap  = trackBg.AbsolutePosition.X
            local asz = trackBg.AbsoluteSize.X
            local t   = math.clamp((absX - ap) / asz, 0, 1)
            local raw = minVal + t * (maxVal - minVal)
            if rounding == 0 then
                value = math.floor(raw + 0.5)
            else
                local m = 10 ^ rounding
                value = math.floor(raw * m + 0.5) / m
            end
            value = math.clamp(value, minVal, maxVal)
            local p = pct()
            fill.Size      = UDim2.new(p, 0, 1, 0)
            thumb.Position = UDim2.new(p, -9, 0.5, -9)
            valLbl.Text    = fmt(value)
            for _, cb in ipairs(callbacks) do pcall(cb, value) end
        end

        -- click/drag on the track hit area
        local hitArea = newInst("TextButton", {
            Size                  = UDim2.new(1, 0, 0, 28),
            Position              = UDim2.new(0, 0, 0, 38),
            BackgroundTransparency = 1,
            Text                  = "",
            ZIndex                = 9,
        }, row)

        hitArea.InputBegan:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseButton1
            or inp.UserInputType == Enum.UserInputType.Touch then
                sliderDrag = true
                setFromAbsX(inp.Position.X)
            end
        end)

        UserInputService.InputChanged:Connect(function(inp)
            if not sliderDrag then return end
            if inp.UserInputType == Enum.UserInputType.MouseMovement
            or inp.UserInputType == Enum.UserInputType.Touch then
                setFromAbsX(inp.Position.X)
            end
        end)

        UserInputService.InputEnded:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseButton1
            or inp.UserInputType == Enum.UserInputType.Touch then
                sliderDrag = false
            end
        end)

        local sl = {}
        function sl:OnChanged(fn) callbacks[#callbacks + 1] = fn; return sl end
        function sl:Set(v)
            value = math.clamp(v, minVal, maxVal)
            local p = pct()
            fill.Size      = UDim2.new(p, 0, 1, 0)
            thumb.Position = UDim2.new(p, -9, 0.5, -9)
            valLbl.Text    = fmt(value)
        end
        function sl:Get() return value end
        return sl
    end

    -- ── AddInput ──────────────────────────────────────────────────────────────
    function Tab:AddInput(_key, opts2)
        opts2 = opts2 or {}
        local titleText   = opts2.Title       or ""
        local default     = opts2.Default     or ""
        local placeholder = opts2.Placeholder or ""
        local finished    = opts2.Finished    == true
        local callbacks   = {}

        local row = newInst("Frame", {
            Size             = UDim2.new(1, 0, 0, 72),
            BackgroundColor3 = C.RowBg,
            BorderSizePixel  = 0,
            ZIndex           = 5,
            LayoutOrder      = nextOrder(),
        }, scroll)
        corner(7, row)

        label({
            Text     = titleText,
            Size     = UDim2.new(1, -16, 0, 22),
            Position = UDim2.new(0, 12, 0, 6),
            Font     = FONT,
            TextSize = 13,
            ZIndex   = 6,
        }, row)

        local box = newInst("TextBox", {
            Size              = UDim2.new(1, -24, 0, 30),
            Position          = UDim2.new(0, 12, 0, 34),
            BackgroundColor3  = C.InputBg,
            Text              = tostring(default),
            PlaceholderText   = placeholder,
            PlaceholderColor3 = C.SubText,
            TextColor3        = C.Text,
            Font              = FONT_REG,
            TextSize          = 13,
            BorderSizePixel   = 0,
            ClearTextOnFocus  = false,
            ZIndex            = 6,
        }, row)
        corner(6, box)
        stroke(1, C.Border, box)
        newInst("UIPadding", {PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8)}, box)

        box.Focused:Connect(function()
            tween(box, {BackgroundColor3 = Color3.fromRGB(20, 20, 32)}, TINFO_FAST)
        end)
        box.FocusLost:Connect(function()
            tween(box, {BackgroundColor3 = C.InputBg}, TINFO_FAST)
        end)

        local function fireChange(txt)
            for _, cb in ipairs(callbacks) do pcall(cb, txt) end
        end

        if finished then
            box.FocusLost:Connect(function(enterPressed)
                if enterPressed then fireChange(box.Text) end
            end)
        else
            box:GetPropertyChangedSignal("Text"):Connect(function()
                fireChange(box.Text)
            end)
        end

        local inp = {}
        function inp:OnChanged(fn) callbacks[#callbacks + 1] = fn; return inp end
        function inp:Set(v)        box.Text = tostring(v) end
        function inp:Get()         return box.Text        end
        return inp
    end

    return Tab
end  -- addTab

-- ─── Public GUI table ─────────────────────────────────────────────────────────
local GUI = {}

function GUI:Notify(opts)
    pcall(notify, opts)
end

function GUI:CreateWindow(opts)
    opts = opts or {}

    -- Apply size override
    if opts.Size then
        local s = opts.Size
        FULL_HEIGHT        = s.Y.Offset
        winFrame.Size      = UDim2.fromOffset(s.X.Offset, s.Y.Offset)
        winFrame.Position  = UDim2.new(0.5, -s.X.Offset/2, 0.5, -s.Y.Offset/2)
    end

    -- Apply title / subtitle overrides
    if opts.Title    then titleLbl.Text = opts.Title    end
    if opts.SubTitle then subLbl.Text   = opts.SubTitle end

    -- MinimizeKey binding
    if opts.MinimizeKey then
        UserInputService.InputBegan:Connect(function(inp, gp)
            if gp then return end
            if inp.KeyCode == opts.MinimizeKey then
                doMinimize()
            end
        end)
    end

    local Window = {}

    function Window:AddTab(tabOpts)
        return addTab(Window, tabOpts)
    end

    function Window:SelectTab(n)
        selectTab(n)
    end

    return Window
end

return GUI
