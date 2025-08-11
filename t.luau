--// Danh sách scripts
local Scripts = {
    {
        Name = "Blox Fruits",
        PlacesIds = {2753915549, 4442272183, 7449423635},
        UrlPath = "BloxFruits.luau"
    },
    {
        Name = "Meme Sea",
        PlacesIds = {10260193230},
        UrlPath = "MemeSea.luau"
    },
}

--// Tạo biến môi trường
local fetcher, urls = {}, {}
local _ENV = (getgenv and getgenv()) or (getrenv and getrenv()) or getfenv()

--// URL GitHub
urls.Owner = "https://raw.githubusercontent.com/tlredz/"
urls.Repository = urls.Owner .. "Scripts/refs/heads/main/"
urls.Translator = urls.Repository .. "Translator/"
urls.Utils = urls.Repository .. "Utils/"

--// Chống spam exec
do
    local last_exec = _ENV.rz_execute_debounce
    if last_exec and (tick() - last_exec) <= 5 then
        return nil
    end
    _ENV.rz_execute_debounce = tick()
end

--// Hàng đợi khi teleport
do
    local executor = syn or fluxus
    local queueteleport = queue_on_teleport or (executor and executor.queue_on_teleport)
    if not _ENV.rz_added_teleport_queue and type(queueteleport) == "function" then
        local ScriptSettings = {...}
        local SettingsCode = ""
        _ENV.rz_added_teleport_queue = true
        local Success, EncodedSettings = pcall(function()
            return game:GetService("HttpService"):JSONEncode(ScriptSettings)
        end)
        if Success and EncodedSettings then
            SettingsCode = "unpack(game:GetService('HttpService'):JSONDecode('" .. EncodedSettings .. "'))"
        end
        pcall(queueteleport, ("loadstring(game:HttpGet('%smain.luau'))(%s)"):format(urls.Repository, SettingsCode))
    end
end

--// Xử lý lỗi tải
do
    if _ENV.rz_error_message then
        _ENV.rz_error_message:Destroy()
    end
    local identifyexecutor = identifyexecutor or (function() return "Unknown" end)
    local function CreateMessageError(Text)
        _ENV.loadedFarm = nil
        _ENV.OnFarm = false
        local Message = Instance.new("Message", workspace)
        Message.Text = string.gsub(Text, urls.Owner, "")
        _ENV.rz_error_message = Message
        error(Text, 2)
    end
    local function formatUrl(Url)
        for key, path in pairs(urls) do
            if Url:find("{" .. key .. "}") then
                return select(1, Url:gsub("{" .. key .. "}", path))
            end
        end
        return Url
    end
    function fetcher.get(Url)
        local success, response = pcall(function()
            return game:HttpGet(formatUrl(Url))
        end)
        if success then
            return response
        else
            CreateMessageError(string.format("[1] [%s] failed to get http/url/raw: %s\n>>%s<<", identifyexecutor(), Url, response))
        end
    end
    function fetcher.load(Url, concat)
        local raw = fetcher.get(Url) .. (concat or "")
        local runFunction, errorText = loadstring(raw)
        if type(runFunction) ~= "function" then
            CreateMessageError(string.format("[2] [%s] syntax error: %s\n>>%s<<", identifyexecutor(), Url, errorText))
        else
            return runFunction
        end
    end
end

--// Kiểm tra đúng game
local function IsPlace(Script)
    if Script.PlacesIds and table.find(Script.PlacesIds, game.PlaceId) then
        return true
    elseif Script.GameId and Script.GameId == game.GameId then
        return true
    end
end

--// Nếu đúng game thì auto load
for _, Script in ipairs(Scripts) do
    if IsPlace(Script) then
        return fetcher.load(urls.Repository .. "Games/" .. Script.UrlPath)(fetcher, ...)
    end
end

--// Nếu sai game => hiện menu chọn
local OrionLib = loadstring(game:HttpGet('https://raw.githubusercontent.com/shlexware/Orion/main/source'))()
local Window = OrionLib:MakeWindow({
    Name = "Script Loader",
    HidePremium = false,
    SaveConfig = false,
    IntroEnabled = true,
    IntroText = "Welcome!",
})

local ScriptTab = Window:MakeTab({
    Name = "Scripts",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

-- Thêm nút cho từng script
for _, sc in ipairs(Scripts) do
    ScriptTab:AddButton({
        Name = sc.Name,
        Callback = function()
            fetcher.load(urls.Repository .. "Games/" .. sc.UrlPath)(fetcher, ...)
        end
    })
end

OrionLib:Init()
