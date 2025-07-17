-- Load Fluent and managers
local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

-- Roblox services
local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")
local Player = Players.LocalPlayer

-- Teleport settings (defaults)
local DEFAULT_PLACE_ID = 13772394625
local DEFAULT_JOB_ID = "8383dc55-82d3-45bb-83d5-d4bbd50e7f41"
local PLAZA_PLACE_ID = 16581637217
local PLAZA_JOB_ID = "96c12b32-ee1e-43d2-aa65-23a4598f3df0"

-- UI setup
local Window = Fluent:CreateWindow({
    Title = "Teleport + Reward Hub " .. Fluent.Version,
    SubTitle = "By You",
    TabWidth = 160,
    Size = UDim2.fromOffset(600, 450),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.RightControl,
})

local Tabs = {
    Main = Window:AddTab({Title = "Main", Icon = "home"}),
    Settings = Window:AddTab({Title = "Settings", Icon = "settings"})
}

-- Remotes
local net = ReplicatedStorage:FindFirstChild("Packages") and ReplicatedStorage.Packages:FindFirstChild("_Index"):FindFirstChild("sleitnick_net@0.1.0").net
local placeTeleport = net and net:FindFirstChild("RE/PlaceTeleport")
local claimRemote = net and net:FindFirstChild("RE/FriendsList/CollectReward")

local Options = Fluent.Options

-- Input fields
Tabs.Settings:AddInput("DelayInput", {Title = "Teleport Delay", Default = "5", Placeholder = "Seconds"})
Tabs.Settings:AddInput("DefaultJobInput", {Title = "Default JobId", Default = DEFAULT_JOB_ID})
Tabs.Settings:AddInput("PlazaJobInput", {Title = "Plaza JobId", Default = PLAZA_JOB_ID})
Tabs.Settings:AddInput("RepeatCount", {Title = "Repeat Count", Default = "1", Placeholder = "e.g. 100"})

Tabs.Settings:AddToggle("UseBuiltInJobId", {Title = "Use Built-in JobIds", Default = true})
Tabs.Settings:AddToggle("UseInputJobId", {Title = "Use Input JobIds", Default = false})
Tabs.Settings:AddToggle("AutoClaim", {Title = "Auto Claim Rewards", Default = true})
Tabs.Settings:AddToggle("RunScript", {Title = "Run Script", Default = false})

-- Claim function
local function claimRewards()
    if not claimRemote then return end
    for i = 1, 3 do
        local success = pcall(function()
            claimRemote:FireServer(i)
        end)
        task.wait(0.3)
    end
end

-- Main loop
local function runScript()
    local repeatCount = tonumber(Options.RepeatCount.Value) or 1
    local delay = tonumber(Options.DelayInput.Value) or 5
    local defaultJobId = Options.UseBuiltInJobId.Value and DEFAULT_JOB_ID or Options.DefaultJobInput.Value
    local plazaJobId = Options.UseBuiltInJobId.Value and PLAZA_JOB_ID or Options.PlazaJobInput.Value

    task.spawn(function()
        local count = 0
        while Options.RunScript.Value and count < repeatCount do
            local placeId = game.PlaceId
            local jobId = game.JobId

            if placeId == DEFAULT_PLACE_ID and jobId == defaultJobId then
                if Options.AutoClaim.Value then claimRewards() end
                if placeTeleport then placeTeleport:FireServer("TradingPlaza") end
                count += 1

            elseif placeId == PLAZA_PLACE_ID and jobId == plazaJobId then
                if Options.AutoClaim.Value then claimRewards() end
                if placeTeleport then placeTeleport:FireServer("Default") end
                count += 1
            end

            task.wait(delay)
        end
    end)
end

-- Hook to toggle
Options.RunScript:OnChanged(function(val)
    if val then runScript() end
end)

-- Save + interface managers
SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)
SaveManager:IgnoreThemeSettings()
InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)
SaveManager:LoadAutoloadConfig()

-- Logo button
local logo = Instance.new("ImageButton")
logo.Name = "FluentDock"
logo.Size = UDim2.new(0, 40, 0, 40)
logo.Position = UDim2.new(0, 10, 0, 10)
logo.BackgroundTransparency = 1
logo.Image = "rbxassetid://10590477450"
logo.ZIndex = 50
logo.Parent = CoreGui
logo.MouseButton1Click:Connect(function()
    Window.Visible = not Window.Visible
end)

Fluent:Notify({Title="Loaded!", Content="Hub initialized.", Duration=5})
Window:SelectTab(1)
