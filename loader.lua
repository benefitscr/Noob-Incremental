-- Noob Incremental Loader — Benefit Script
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield", true))()
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local LP = Players.LocalPlayer

local API        = "https://gta6free.app"
local SCRIPT_URL = "https://raw.githubusercontent.com/benefitscr/Noob-Incremental/main/autofarm_luraph.lua"
local DISCORD    = "https://discord.gg/AXSnKF5R"

-- ─── Pre-fetch main script in background immediately ─────────────────────────
local scriptBody = nil
local scriptErr  = nil
task.spawn(function()
    local ok, result = pcall(function()
        return game:HttpGet(SCRIPT_URL, true)
    end)
    if ok then scriptBody = result else scriptErr = result end
end)

-- ─── Lang ─────────────────────────────────────────────────────────────────────
local LANG = "en"
local T = {
    en = {
        win          = "Noob Incremental",
        sec1         = "Activate",
        inp          = "Enter your key",
        ph           = "BENEFIT-LT-XXXX-XXXX",
        btn_activate = "Activate Script",
        btn_discord  = "Get Key on Discord",
        btn_lang     = "Switch to RU",
        checking     = "Checking key...",
        invalid      = "Invalid key! Get one on Discord.",
        welcome      = "Welcome, ",
        loading      = "Loading script...",
        srv_err      = "Server error. Try again.",
        discord_ok   = "Discord link copied!",
        no_key       = "Enter your key first!",
        fetching     = "Downloading script, please wait...",
    },
    ru = {
        win          = "Noob Incremental",
        sec1         = "Активация",
        inp          = "Введите ваш ключ",
        ph           = "BENEFIT-LT-XXXX-XXXX",
        btn_activate = "Активировать скрипт",
        btn_discord  = "Получить ключ в Discord",
        btn_lang     = "Переключить на EN",
        checking     = "Проверяем ключ...",
        invalid      = "Неверный ключ! Получи в Discord.",
        welcome      = "Добро пожаловать, ",
        loading      = "Загружаем скрипт...",
        srv_err      = "Ошибка сервера. Попробуй снова.",
        discord_ok   = "Ссылка скопирована!",
        no_key       = "Сначала введи ключ!",
        fetching     = "Скрипт ещё скачивается, подожди...",
    },
}
local function L(k) return (T[LANG] and T[LANG][k]) or T.en[k] or k end
local function notify(title, content, dur)
    Rayfield:Notify({Title=title, Content=content, Duration=dur or 4, Image="info"})
end

-- ─── Heartbeat ────────────────────────────────────────────────────────────────
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

-- ─── Validate key ─────────────────────────────────────────────────────────────
local function validate(key)
    local url = API.."/api/validate?key="..HttpService:UrlEncode(key).."&user="..HttpService:UrlEncode(LP.Name)
    local ok, body = pcall(function() return HttpService:GetAsync(url) end)
    if not ok then return false, nil, L("srv_err") end
    local ok2, data = pcall(function() return HttpService:JSONDecode(body) end)
    if not ok2 then return false, nil, L("srv_err") end
    if data.valid then return true, data.sessionId, nil end
    return false, nil, data.error or L("invalid")
end

-- ─── UI ───────────────────────────────────────────────────────────────────────
local Win = Rayfield:CreateWindow({
    Name                   = L("win"),
    Icon                   = "key",
    LoadingTitle           = "Noob Incremental",
    LoadingSubtitle        = "by Benefit Script",
    Theme                  = "Default",
    DisableRayfieldPrompts = false,
    DisableBuildWarnings   = true,
    ConfigurationSaving    = {Enabled=false},
    KeySystem              = false,
})

local Tab = Win:CreateTab(L("sec1"), "key")
Tab:CreateSection(L("sec1"))

local currentKey = ""
Tab:CreateInput({
    Name                    = L("inp"),
    PlaceholderText         = L("ph"),
    RemoveTextAfterFocusLost = false,
    Callback                = function(txt) currentKey = txt end,
})

Tab:CreateButton({Name=L("btn_activate"), Callback=function()
    local key = currentKey:gsub("%s",""):upper()
    if key == "" then notify("!", L("no_key"), 3); return end

    notify("...", L("checking"), 3)
    local valid, sid, err = validate(key)

    if not valid then
        notify("X", err or L("invalid"), 6)
        return
    end

    -- Key accepted — wait for background script download if still in progress
    if not scriptBody then
        notify("...", L("fetching"), 5)
        local waited = 0
        while not scriptBody and not scriptErr and waited < 30 do
            task.wait(0.5)
            waited = waited + 0.5
        end
    end

    if scriptErr or not scriptBody then
        notify("X", "Failed to download script. Try again.", 5)
        return
    end

    sessionId = sid
    startHeartbeat()
    notify("OK", L("welcome")..LP.Name, 3)
    task.wait(0.5)
    pcall(function() Rayfield:Destroy() end)
    task.wait(0.3)
    loadstring(scriptBody)()
end})

Tab:CreateButton({Name=L("btn_discord"), Callback=function()
    pcall(setclipboard, DISCORD)
    notify("Discord", L("discord_ok"), 3)
end})

Tab:CreateButton({Name=L("btn_lang"), Callback=function()
    LANG = LANG == "en" and "ru" or "en"
    notify("Lang", LANG == "ru" and "Язык: Русский" or "Language: English", 2)
end})

Tab:CreateSection("")
Tab:CreateLabel("Benefit Script  |  discord.gg/AXSnKF5R")
