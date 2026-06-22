-- Benefit Script Loader — Noob Incremental
local Rayfield    = loadstring(game:HttpGet("https://sirius.menu/rayfield", true))()
local Players     = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local LP          = Players.LocalPlayer

local API        = "https://gta6free.app"
local SCRIPT_URL = "https://raw.githubusercontent.com/benefitscr/Noob-Incremental/main/autofarm_luraph.lua"
local DISCORD    = "https://discord.gg/AXSnKF5R"

-- ─── Auto-detect language ─────────────────────────────────────────────────────
local LANG = "en"
pcall(function()
    local loc = LP.LocaleId or ""
    if loc:sub(1,2) == "ru" or loc:sub(1,2) == "uk" then LANG = "ru" end
end)

local T = {
    en = {
        win      = "Noob Incremental",
        load_sub = "by Benefit Script",
        tab      = "Key System",
        sec_key  = "Authentication",
        sec_info = "Info",
        inp_name = "License Key",
        inp_ph   = "BENEFIT-LT-XXXX-XXXX",
        btn_act  = "Activate Script",
        btn_disc = "Get Key on Discord",
        checking = "Checking key...",
        fetching = "Loading script, please wait...",
        welcome  = "Welcome, ",
        invalid  = "Invalid key. Get one on Discord.",
        srv_err  = "Server error. Try again.",
        no_key   = "Please enter your key first.",
        dl_fail  = "Download failed. Try again.",
        copied   = "Discord link copied to clipboard!",
        label1   = "Paste your key above and click Activate.",
        label2   = "Lifetime key — unlimited sessions.",
    },
    ru = {
        win      = "Noob Incremental",
        load_sub = "от Benefit Script",
        tab      = "Ключ",
        sec_key  = "Активация",
        sec_info = "Информация",
        inp_name = "Лицензионный ключ",
        inp_ph   = "BENEFIT-LT-XXXX-XXXX",
        btn_act  = "Активировать скрипт",
        btn_disc = "Получить ключ в Discord",
        checking = "Проверяем ключ...",
        fetching = "Загружаем скрипт, подождите...",
        welcome  = "Добро пожаловать, ",
        invalid  = "Неверный ключ. Получи его в Discord.",
        srv_err  = "Ошибка сервера. Попробуй снова.",
        no_key   = "Сначала введите ключ.",
        dl_fail  = "Ошибка загрузки. Попробуй снова.",
        copied   = "Ссылка на Discord скопирована!",
        label1   = "Вставьте ключ выше и нажмите Активировать.",
        label2   = "Lifetime ключ — без ограничений.",
    },
}
local function L(k) return (T[LANG] and T[LANG][k]) or T.en[k] or k end

-- ─── Pre-fetch main script in background ─────────────────────────────────────
local scriptBody, scriptErr
task.spawn(function()
    local ok, r = pcall(game.HttpGet, game, SCRIPT_URL, true)
    if ok then scriptBody = r else scriptErr = tostring(r) end
end)

-- ─── Window ───────────────────────────────────────────────────────────────────
local Win = Rayfield:CreateWindow({
    Name                   = L("win"),
    Icon                   = "gamepad-2",
    LoadingTitle           = "Noob Incremental",
    LoadingSubtitle        = L("load_sub"),
    Theme                  = "Default",
    DisableRayfieldPrompts = false,
    DisableBuildWarnings   = true,
    ConfigurationSaving    = { Enabled = false },
    KeySystem              = false,
})

local Tab = Win:CreateTab(L("tab"), "key-round")

-- ─── Key section ──────────────────────────────────────────────────────────────
Tab:CreateSection(L("sec_key"))

local currentKey = ""
Tab:CreateInput({
    Name            = L("inp_name"),
    PlaceholderText = L("inp_ph"),
    RemoveTextAfterFocusLost = false,
    Callback = function(v) currentKey = v end,
})

-- Status label (updated dynamically)
local statusLabel = Tab:CreateLabel("  ")

local busy = false
local sessionId = nil

local function setStatus(msg, ok)
    local icon = ok and "✓" or "✗"
    statusLabel:Set(icon .. "  " .. msg)
end

local function startHeartbeat()
    task.spawn(function()
        while true do
            task.wait(60)
            pcall(game.HttpGet, game, API .. "/api/heartbeat?sid=" .. (sessionId or ""), true)
        end
    end)
end

Tab:CreateButton({
    Name = L("btn_act"),
    Callback = function()
        if busy then return end
        local key = currentKey:gsub("%s", ""):upper()
        if key == "" then
            Rayfield:Notify({ Title = "!", Content = L("no_key"), Duration = 4, Image = 4483362458 })
            return
        end

        busy = true
        setStatus(L("checking"), true)

        -- Validate key (game:HttpGet works in all executors)
        local url = API .. "/api/validate?key=" .. key .. "&user=" .. LP.Name
        local ok, body = pcall(game.HttpGet, game, url, true)
        if not ok then
            setStatus(L("srv_err"), false)
            Rayfield:Notify({ Title = "Error", Content = tostring(body):sub(1,80), Duration = 5, Image = 4483362458 })
            busy = false
            return
        end

        local ok2, data = pcall(function() return HttpService:JSONDecode(body) end)
        if not ok2 or not data.valid then
            local msg = (ok2 and data and data.error) or L("invalid")
            setStatus(msg, false)
            Rayfield:Notify({ Title = "Invalid Key", Content = msg, Duration = 6, Image = 4483362458 })
            busy = false
            return
        end

        sessionId = data.sessionId

        -- Wait for background script download
        setStatus(L("fetching"), true)
        local waited = 0
        while not scriptBody and not scriptErr and waited < 30 do
            task.wait(0.5)
            waited = waited + 0.5
        end

        if not scriptBody then
            setStatus(L("dl_fail"), false)
            Rayfield:Notify({ Title = "Error", Content = L("dl_fail"), Duration = 5, Image = 4483362458 })
            busy = false
            return
        end

        -- All good — launch
        startHeartbeat()
        Rayfield:Notify({
            Title   = "✓ " .. L("welcome") .. LP.Name,
            Content = "Noob Incremental · Benefit Script",
            Duration = 4,
            Image   = 4483362458,
        })
        task.wait(1.5)
        pcall(function() Rayfield:Destroy() end)
        task.wait(0.3)
        loadstring(scriptBody)()
    end,
})

-- ─── Info section ─────────────────────────────────────────────────────────────
Tab:CreateSection(L("sec_info"))

Tab:CreateLabel(L("label1"))
Tab:CreateLabel(L("label2"))

Tab:CreateButton({
    Name = L("btn_disc"),
    Callback = function()
        pcall(setclipboard, DISCORD)
        Rayfield:Notify({
            Title   = "Discord",
            Content = L("copied"),
            Duration = 3,
            Image   = 4483362458,
        })
    end,
})
