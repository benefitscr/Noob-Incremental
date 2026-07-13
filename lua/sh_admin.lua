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
local farm = { on = false, maxBid = 5000, threshold = 10000, list = true, busy = false, lastEnd = 0, status = "idle", blocked = {} }
local biddingOpen = false
local doListing

-- Диалог "Before you start": запуск аукциона перезапишет ЦЕННЫЙ лут в Lost & Found коробке.
-- Детектим попап и вежливо жмём "No" (отказ) — НЕ теряем ценные предметы. Потом пропускаем этот склад.
local function overrideWarnUp()
    local host = LP.PlayerGui:FindFirstChild("ConfirmPromptHost")
    local cp = host and host:FindFirstChild("ConfirmPrompt")
    if not (cp and cp.Visible) then return nil end
    local dlg = cp:FindFirstChild("Dialog")
    local body = dlg and dlg:FindFirstChild("Body")
    local txt = (body and body.Text) or ""
    if txt:find("Lost") or txt:find("Found") or txt:find("override") then return cp end
    return nil
end
local function declineOverride(cp)
    local btn = cp:FindFirstChild("Dialog"); btn = btn and btn:FindFirstChild("ButtonRow"); btn = btn and btn:FindFirstChild("CancelButton")
    if not btn then return false end
    if typeof(getconnections) == "function" then
        for _, c in ipairs(getconnections(btn.MouseButton1Click)) do pcall(function() c:Fire() end) end
    end
    if typeof(firesignal) == "function" then pcall(firesignal, btn.MouseButton1Click) end
    local t = tick(); repeat task.wait(0.1) until (not cp.Visible) or (tick() - t > 1.5)
    return not cp.Visible
end
pcall(function()
    local A = Events:WaitForChild("Auction")
    A.ToggleBiddingUI.OnClientEvent:Connect(function(open) biddingOpen = open; if not open then farm.lastEnd = tick() end end)
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
        if farm.on then farm.busy = true; farm.status = "ВЫИГРАЛ " .. tostring(itemCount) .. " шт за " .. tostring(bid) end
    end)
    A.AuctionPickupEnd.OnClientEvent:Connect(function()
        if not farm.on then farm.busy = false; return end
        task.delay(1.3, function()
            pcall(function() Events.Vehicles.TransferVehicleItemsToInventory:FireServer() end)
            farm.status = "собрал добычу -> инвентарь"
            task.wait(1.5)
            if farm.list and doListing then pcall(doListing) end
            farm.busy = false
        end)
    end)
end)

-- Авто-вход: когда фармим и торги не идут — телепорт к ближайшему гаражу и запуск аукциона
task.spawn(function()
    while alive() do
        task.wait(2.5)
        if farm.on and not biddingOpen and not farm.busy and (tick() - farm.lastEnd > 3) then
            local ch = LP.Character; local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
            local deb = workspace:FindFirstChild("_Debris")
            local garages = deb and deb:FindFirstChild("Garages")
            if hrp and garages then
                local prompt, wpos, bd, gkey
                for _, g in ipairs(garages:GetChildren()) do
                    local p = g:FindFirstChild("EnterAuction", true)
                    if p and p.Enabled then
                        local pt = p.Parent
                        local wp = (pt:IsA("BasePart") and pt.Position) or (pt:IsA("Attachment") and pt.WorldPosition) or nil
                        if wp then
                            local key = g:GetAttribute("GUID") or (g.Name .. "#" .. math.floor(wp.X) .. "_" .. math.floor(wp.Z))
                            local bt = farm.blocked[key]
                            if not (bt and tick() - bt < 120) then          -- пропуск недавно заблокированных (L&F)
                                local d = (wp - hrp.Position).Magnitude
                                if not bd or d < bd then bd = d; prompt = p; wpos = wp; gkey = key end
                            end
                        end
                    end
                end
                if prompt and wpos then
                    farm.status = "захожу в аукцион…"
                    pcall(function() hrp.CFrame = CFrame.new(wpos + Vector3.new(0, 2, 0)) end)
                    task.wait(0.8)
                    if typeof(fireproximityprompt) == "function" then pcall(fireproximityprompt, prompt) end
                    -- ждём: появится диалог "Before you start" (L&F) ЛИБО откроются торги
                    local cp, t0 = nil, tick()
                    repeat task.wait(0.15); cp = overrideWarnUp() until cp or biddingOpen or (tick() - t0 > 2.2)
                    if cp then
                        declineOverride(cp)                                 -- отказ: НЕ перезаписываем ценный лут в коробке
                        if gkey then farm.blocked[gkey] = tick() end
                        farm.status = "L&F: склад занят твоим лутом — отклонил, пропускаю"
                    end
                elseif farm.on then
                    farm.status = "нет свободных складов (заняты L&F?) — собери коробку"
                end
            end
        end
    end
end)

-- ── Авто-листинг: дешёвые предметы на полки, дорогие/мутированные — в инвентаре ──
local function itemVal(data)
    if type(data) ~= "table" then return 0 end
    local muts = 0
    if type(data.Mutators) == "table" then for _ in pairs(data.Mutators) do muts = muts + 1 end end
    if muts > 0 then return 999999 end                    -- мутированный редкий → всегда keep
    return (tonumber(data.Condition) or 50) * 20          -- грубая оценка дешёвого предмета
end
local function freeSnaps(plot)
    local out = {}
    for _, shelf in ipairs(plot:GetDescendants()) do
        if shelf:IsA("Model") and shelf:GetAttribute("IsShelf") and shelf:GetAttribute("GUID") then
            for _, att in ipairs(shelf:GetDescendants()) do
                if att:IsA("Attachment") and att.Name:find("SnapPoint") then
                    local occ = false
                    for _, m in ipairs(plot:GetDescendants()) do
                        if m:IsA("Model") and m ~= shelf and m.PrimaryPart and (m.PrimaryPart.Position - att.WorldPosition).Magnitude < 1 then occ = true; break end
                    end
                    if not occ then out[#out + 1] = { guid = shelf:GetAttribute("GUID"), name = att.Name, cf = att.WorldCFrame } end
                end
            end
        end
    end
    return out
end
doListing = function()
    local pd = invoke("Plot/RequestPlotData")
    if type(pd) ~= "table" or not pd.PlotName then return end
    local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if hrp and pd.OriginX then pcall(function() hrp.CFrame = CFrame.new(pd.OriginX, (pd.OriginY or 0) + 5, pd.OriginZ) end) end
    task.wait(2.5)
    local plots = workspace:FindFirstChild("_Plots")
    local plot = plots and plots:FindFirstChild(pd.PlotName)
    if not plot then farm.status = "магазин не загрузился"; return end
    local snaps = freeSnaps(plot)
    local inv = invoke("Inventory/GetPlayerInventory")
    if type(inv) ~= "table" then return end
    local si, listed, kept = 1, 0, 0
    for guid, data in pairs(inv) do
        local v = itemVal(data)
        if v > farm.threshold then
            kept = kept + 1
        elseif snaps[si] then
            local s = snaps[si]; si = si + 1
            pcall(function() Events.Plot.PlaceStockItem:FireServer(guid, tostring(data.ItemId), s.cf, math.max(50, math.floor(v)), s.guid, s.name) end)
            listed = listed + 1
            task.wait(0.4)
        end
    end
    farm.status = "листинг: выставил " .. listed .. ", оставил " .. kept
end

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
Farm.Input("порог keep (>цена оставить)", "Set", function(v) local n = tonumber(v); if n then farm.threshold = n end end)
Farm.Toggle("AUTO-BID (заходить + выигрывать + собирать)", false, function(s) farm.on = s end)
Farm.Toggle("Авто-листинг дешёвых в магазин", true, function(s) farm.list = s end)
Farm.Label(function() return (farm.on and "[ON] " or "[off] ") .. "ставка<=" .. tostring(farm.maxBid) .. " keep>" .. tostring(farm.threshold) .. "\n" .. farm.status end)

local Custom = Category("Custom / Raw", true)
Custom.Input("путь, напр Auction/UseXRay", "Fire", function(v) if v ~= "" then fireEvent(v) end end)
Custom.Input("путь RemoteFunction", "Invoke", function(v) if v ~= "" then warn("[admin] result:", invoke(v)) end end)

pcall(function()
    game:GetService("StarterGui"):SetCore("SendNotification", { Title = "Admin", Text = "Меню загружено", Duration = 4 })
end)
