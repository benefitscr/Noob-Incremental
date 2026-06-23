local Http = game:GetService("HttpService")
local LP   = game:GetService("Players").LocalPlayer

local API  = "https://gta6free.app"
local SRC  = "https://raw.githubusercontent.com/benefitscr/Noob-Incremental/main/lua/autofarm.lua"
local DISC = "https://discord.gg/AXSnKF5R"

-- Rayfield for key-system UI only
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield", true))()

local LANG = "en"
pcall(function()
    local l = LP.LocaleId or ""
    if l:sub(1,2)=="ru" or l:sub(1,2)=="uk" then LANG="ru" end
end)
local TX = {
    en = { tab="Key System", key="License Key", ph="BENEFIT-FREE-XXXX-XXXX",
           act="Activate", disc="Get Key on Discord",
           nokey="Enter your key", checking="Checking...", ok="Loaded! Welcome, ",
           fail="Invalid key", srv="Server error", loading="Loading...", dlf="Download failed" },
    ru = { tab="Ключ", key="Лицензионный ключ", ph="BENEFIT-FREE-XXXX-XXXX",
           act="Активировать", disc="Получить ключ в Discord",
           nokey="Введите ключ", checking="Проверяем...", ok="Загружено! Добро пожаловать, ",
           fail="Неверный ключ", srv="Ошибка сервера", loading="Загружаем...", dlf="Ошибка загрузки" },
}
local function L(k) return (TX[LANG] and TX[LANG][k]) or TX.en[k] or k end

-- Pre-fetch main script in background
local src, srcErr
task.spawn(function()
    local ok, r = pcall(game.HttpGet, game, SRC, true)
    if ok then src=r else srcErr=r end
end)

local Win = Rayfield:CreateWindow({
    Name="Noob Incremental", Icon="gamepad-2",
    LoadingTitle="Noob Incremental", LoadingSubtitle="Benefit Script",
    Theme="Default", DisableRayfieldPrompts=true, DisableBuildWarnings=true,
    ConfigurationSaving={Enabled=false}, KeySystem=false,
})

local Tab = Win:CreateTab(L("tab"), "key-round")

local key = ""
Tab:CreateInput({ Name=L("key"), PlaceholderText=L("ph"),
    RemoveTextAfterFocusLost=false, Callback=function(v) key=v end })

local status = Tab:CreateLabel(" ")
local busy = false

Tab:CreateButton({ Name=L("act"), Callback=function()
    if busy then return end
    local k = key:gsub("%s",""):upper()
    if k=="" then status:Set("✗  "..L("nokey")); return end

    busy=true
    status:Set("•  "..L("checking"))

    local ok, body = pcall(game.HttpGet, game, API.."/api/validate?key="..k.."&user="..LP.Name, true)
    if not ok then
        status:Set("✗  "..L("srv").." ("..tostring(body):sub(1,50)..")")
        busy=false; return
    end

    local ok2, d = pcall(Http.JSONDecode, Http, body)
    if not ok2 or not d.valid then
        status:Set("✗  "..(ok2 and d and d.error or L("fail")))
        busy=false; return
    end

    local sid = d.sessionId
    status:Set("•  "..L("loading"))
    task.spawn(function()
        while true do task.wait(30)
            pcall(game.HttpGet, game, API.."/api/heartbeat?sid="..(sid or ""), true)
        end
    end)

    local w=0
    while not src and not srcErr and w<30 do task.wait(0.5); w=w+0.5 end
    if not src then status:Set("✗  "..L("dlf")); busy=false; return end

    status:Set("✓  "..L("ok")..LP.Name)
    task.wait(0.8)
    pcall(function() Rayfield:Destroy() end)
    task.wait(0.2)
    loadstring(src)()
end })

Tab:CreateButton({ Name=L("disc"), Callback=function()
    pcall(setclipboard, DISC)
    status:Set("✓  "..DISC)
end })