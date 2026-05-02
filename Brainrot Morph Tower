if not Compkiller then return end

Compkiller:OptimizeMode(true)
Compkiller:ChangeHighlightColor(Compkiller.Colors.Toggle)

local Notifier = Compkiller.newNotify()
local _BLADEX_LOADING = true
local function notify(content, duration)
    if _BLADEX_LOADING then return end
    Notifier.new({ Title = "BLADEX HUD", Content = content, Duration = duration or 4, Icon = Compkiller.Logo })
end

local ConfigManager = Compkiller:ConfigManager({
    Directory = "BLADEX-HUB",
    Config    = "BLADEX-AutoMorph",
})

-- SERVICIOS
local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local lp = Players.LocalPlayer

-- REMOTES
local MorphRemotes = ReplicatedStorage:FindFirstChild("MorphRemotes")
local RequestMorph = MorphRemotes and MorphRemotes:FindFirstChild("RequestMorph")
local MorphEvent   = ReplicatedStorage:FindFirstChild("MorphEventA")

-- FLAGS
local selectedMorphName = ""

-- FUNCIONES
local function applyMorph(morphName)
    if not morphName or morphName == "" then
        notify("Escribe un nombre de morph primero", 3)
        return
    end
    if RequestMorph then
        local ok, res = pcall(function()
            RequestMorph:FireServer(morphName)
        end)
        if ok then
            notify("Morph aplicado: " .. morphName, 3)
        else
            notify("Error al aplicar morph", 3)
        end
    elseif MorphEvent then
        local ok = pcall(function()
            MorphEvent:FireServer(morphName)
        end)
        if ok then
            notify("Morph via MorphEventA: " .. morphName, 3)
        end
    else
        notify("Remote de morph no encontrado", 3)
    end
end

-- UI
Compkiller:Loader(Compkiller.Logo, 2.5).yield()

local Window = Compkiller.new({
    Name     = "BLADEX HUD",
    Keybind  = "LeftAlt",
    Logo     = Compkiller.Logo,
    Scale    = UDim2.new(0, 480, 0, 340),
    TextSize = 15,
})
Window.Minimized = true

local mainTab = Window:DrawTab({
    Name            = "Auto Morph",
    Icon            = "lucide-user",
    Type            = "Single",
    EnableScrolling = true,
})

local SecMain = mainTab:DrawSection({ Name = "Morph", Position = "full", Minimized = true })

SecMain:AddTextBox({
    Name        = "Nombre del Morph",
    Default     = "",
    Placeholder = "Ej: Tralalero Tralala",
    Numeric     = false,
    Callback    = function(text)
        selectedMorphName = text
    end
})

SecMain:AddButton({
    Name     = "Aplicar Morph",
    Callback = function()
        applyMorph(selectedMorphName)
    end
})

Window:DrawCategory({ Name = "Extra" })

local ajustesTab = Window:DrawTab({
    Name = "Ajustes",
    Icon = "settings",
    Type = "Single",
})
local SecAjustes = ajustesTab:DrawSection({ Name = "UI", Position = "full", Minimized = true })
local themes = {
    Default        = Color3.fromRGB(90, 110, 160),
    ["Dark Blue"]  = Color3.fromRGB(50, 90, 200),
    ["Dark Green"] = Color3.fromRGB(60, 150, 90),
    ["Purple Rose"]= Color3.fromRGB(160, 80, 160),
    Skeet          = Color3.fromRGB(200, 60, 60),
}
SecAjustes:AddDropdown({
    Name     = "Select Theme",
    Default  = "Default",
    Values   = { "Default", "Dark Blue", "Dark Green", "Purple Rose", "Skeet" },
    Callback = function(v) Compkiller:ChangeHighlightColor(themes[v] or themes.Default) end
})
SecAjustes:AddToggle({ Name = "Always Show Frame", Default = false, Risky = false,
    Callback = function(v) pcall(function() Window.AlwaysShowTab = v end) end })

Window:DrawConfig({ Name = "Config", Icon = "folder", Config = ConfigManager }):Init()

_BLADEX_LOADING = false
notify("BLADEX HUD CARGANDO", 5)
