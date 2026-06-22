-- Noob Incremental Loader — Benefit Script
-- Key validation + auto-load

local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield", true))()
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local LP = Players.LocalPlayer

local API = "https://gta6free.app"
local SCRIPT_URL = "https://raw.githubusercontent.com/benefitscr/Noob-Incremental/main/autofarm_luraph.lua"
local DISCORD = "https://discord.gg/AXSnKF5R"

-- ─── Lang ─────────────────────────────────────────────────────────────────────
local LANG = "en"
local T = {
    en = {
        win   = "Noob Incremental",
        sub   = "Benefit Script · Key Required",
        sec1  = "Activate",
        inp   = "Enter your key",
        ph    = "BENEFIT-LT-XXXX-XXXX",
        btn_activate = "▶  Activate Script",
        btn_discord  = "Get Key on Discord",
        btn_lang     = "RU",
        notif_checking  = "Checking key...",
        notif_invalid   = "Invalid key! Get one at Discord.",
        notif_ok        = "Welcome, ",
        notif_loading   = "Loading script...",
        notif_error     = "Server error. Try again.",
        notif_discord   = "Discord link copied!",
        notif_nokey     = "Enter your key first!",
    },
    ru = {
        win   = "Noob Incremental",
        sub   = "Benefit Script · Нужен ключ",
        sec1  = "Активация",
        inp   = "Введите ваш ключ",
        ph    = "BENEFIT-LT-XXXX-XXXX",
        btn_activate = "▶  Активировать скрипт",
        btn_discord  = "Получить ключ в Discord",
        btn_lang     = "EN",
        notif_checking  = "Проверяем ключ...",
        notif_invalid   = "Неверный ключ! Получи в Discord.",
        notif_ok        = "Добро пожаловать, ",
        notif_loading   = "Загружаем скрипт...",
        notif_error     = "Ошибка сервера. Попробуй снова.",
        notif_discord   = "Ссылка на Discord скопирована!",
        notif_nokey     = "Сначала введи ключ!",
    },
}
local function L(k) return (T[LANG] and T[LANG][k]) or T.en[k] or k end
local function notify(title, content, icon, dur)
    Rayfield:Notify({Title=title, Content=content, Duration=dur or 4, Image=icon or "bell"})
end

-- ─── Session heartbeat ────────────────────────────────────────────────────────
local sessionId = nil
local function startHeartbeat()
    if not sessionId then return end
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

-- ─── Validate key ─────────────────────────────────────────────────────────────
local function validate(key)
    local url = API.."/api/validate?key="..HttpService:UrlEncode(key).."&user="..HttpService:UrlEncode(LP.Name)
    local ok, body = pcall(function() return HttpService:GetAsync(url) end)
    if not ok then return false, nil, L("notif_error") end
    local dec_ok, data = pcall(function() return HttpService:JSONDecode(body) end)
    if not dec_ok then return false, nil, L("notif_error") end
    if data.valid then return true, data.sessionId, nil end
    return false, nil, data.error or L("notif_invalid")
end

-- ─── UI ───────────────────────────────────────────────────────────────────────
local Win = Rayfield:CreateWindow({
    Name            = L("win"),
    Icon            = "key",
    LoadingTitle    = "Noob Incremental",
    LoadingSubtitle = "by Benefit Script",
    Theme           = "Default",
    DisableRayfieldPrompts = false,
    DisableBuildWarnings   = true,
    ConfigurationSaving    = {Enabled=false},
    KeySystem              = false,
})

local Tab = Win:CreateTab(L("sec1"), "key")
Tab:CreateSection(L("sec1"))

-- Key input
local currentKey = ""
Tab:CreateInput({
    Name            = L("inp"),
    PlaceholderText = L("ph"),
    RemoveTextAfterFocusLost = false,
    Flag            = "keyInput",
    Callback        = function(txt) currentKey = txt end,
})

-- Activate button
Tab:CreateButton({Name=L("btn_activate"), Callback=function()
    local key = currentKey:gsub("%s",""):upper()
    if key == "" then notify("⚠️", L("notif_nokey"), "alert-circle"); return end

    notify("🔑", L("notif_checking"), "loader", 3)
    local valid, sid, err = validate(key)

    if valid then
        sessionId = sid
        startHeartbeat()
        notify("✅ "..L("notif_ok")..LP.Name, "Script is loading...", "check-circle", 5)
        task.wait(1)
        Win:Destroy()
        task.wait(0.5)
        notify("Noob Incremental", L("notif_loading"), "download", 3)
        loadstring(game:HttpGet(SCRIPT_URL, true))()
    else
        notify("❌", err or L("notif_invalid"), "x-circle", 6)
    end
end})

-- Discord button — copies link
Tab:CreateButton({Name=L("btn_discord"), Callback=function()
    pcall(setclipboard, DISCORD)
    notify("Discord", L("notif_discord").."\n"..DISCORD, "message-circle", 4)
end})

-- Language toggle
Tab:CreateButton({Name=L("btn_lang"), Callback=function()
    LANG = LANG=="en" and "ru" or "en"
    notify("Language", LANG=="ru" and "Язык: Русский" or "Language: English", "globe", 2)
end})

Tab:CreateSection("")
Tab:CreateLabel("Benefit Script · Noob Incremental")
Tab:CreateLabel("discord.gg/AXSnKF5R")
