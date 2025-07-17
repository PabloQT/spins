local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

local Window = Fluent:CreateWindow({
    Title = "Teleport + Rewards",
    SubTitle = "by yourname",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl
})

local Tabs = {
    Main = Window:AddTab({ Title = "Main", Icon = "globe" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })
}

local statusParagraph = Tabs.Main:AddParagraph({ Title = "Status", Content = "Waiting..." })

local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Player = Players.LocalPlayer

local DEFAULT_PLACE_ID = 13772394625
local DEFAULT_JOB_ID = "8383dc55-82d3-45bb-83d5-d4bbd50e7f41"
local PLAZA_PLACE_ID = 16581637217
local PLAZA_JOB_ID = "96c12b32-ee1e-43d2-aa65-23a4598f3df0"

local net = ReplicatedStorage.Packages._Index["sleitnick_net@0.1.0"].net
local placeTeleport = net:FindFirstChild("RE/PlaceTeleport")
local claimRemote = net:FindFirstChild("RE/FriendsList/CollectReward")

local function updateStatus(text)
    statusParagraph:SetContent(text)
end

local function countdown(seconds, actionText)
    for i = seconds, 0, -1 do
        updateStatus(actionText .. " in " .. i .. "s")
        task.wait(1)
    end
end

local function teleportPlace(placeName)
    countdown(5, "🌐 Teleporting to: " .. placeName)
    if placeTeleport then
        placeTeleport:FireServer(placeName)
    else
        updateStatus("⚠️ Teleport remote not found!")
    end
end

local function joinJobId(targetPlaceId, targetJobId)
    countdown(5, "🛠 Joining correct JobId")
    local success, err = pcall(function()
        TeleportService:TeleportToPlaceInstance(targetPlaceId, targetJobId, Player)
    end)
    if not success then
        warn("TeleportToPlaceInstance failed:", err)
        updateStatus("❌ JobId teleport failed")
    end
end

local function claimRewards()
    if not claimRemote then
        updateStatus("⚠️ Claim remote not found!")
        return
    end

    updateStatus("🎁 Claiming rewards...")
    local claimedCount = 0
    for i = 1, 3 do
        local success, err = pcall(function()
            claimRemote:FireServer(i)
        end)
        if success then
            claimedCount += 1
            updateStatus("🎉 Claimed reward " .. i)
        else
            warn("Failed to claim reward", i, err)
            updateStatus("❌ Failed reward " .. i)
        end
        task.wait(0.3)
    end

    if claimedCount == 3 then
        updateStatus("✅ All rewards claimed!")
    else
        updateStatus("⚠️ Some rewards failed.")
    end
end

local runningLoop = false

local function runLoop()
    if runningLoop then return end
    runningLoop = true

    repeat wait() until game:IsLoaded()
    while runningLoop do
        local placeId, jobId = game.PlaceId, game.JobId

        if placeId == DEFAULT_PLACE_ID then
            if jobId == DEFAULT_JOB_ID then
                updateStatus("✅ In Default (correct JobId)")
                claimRewards()
                wait(2)
                teleportPlace("TradingPlaza")
            else
                updateStatus("❌ In Default but wrong JobId")
                joinJobId(DEFAULT_PLACE_ID, DEFAULT_JOB_ID)
            end
        elseif placeId == PLAZA_PLACE_ID then
            if jobId == PLAZA_JOB_ID then
                updateStatus("✅ In Plaza (correct JobId)")
                claimRewards()
                wait(2)
                teleportPlace("Default")
            else
                updateStatus("❌ In Plaza but wrong JobId")
                joinJobId(PLAZA_PLACE_ID, PLAZA_JOB_ID)
            end
        else
            updateStatus("🚫 Not in recognized place")
            break
        end
        wait(2)
    end
end

Tabs.Main:AddButton({
    Title = "▶️ Start Loop",
    Description = "Begin auto reward + teleport loop",
    Callback = function()
        Fluent:Notify({ Title = "Loop Started", Content = "Running loop...", Duration = 4 })
        task.spawn(runLoop)
    end
})

Tabs.Main:AddButton({
    Title = "🎁 Claim Rewards",
    Description = "Manually trigger claim",
    Callback = claimRewards
})

Tabs.Main:AddButton({
    Title = "🌍 Teleport: Default",
    Description = "FireServer to teleport to 'Default'",
    Callback = function() teleportPlace("Default") end
})

Tabs.Main:AddButton({
    Title = "🌍 Teleport: Trading Plaza",
    Description = "FireServer to teleport to 'TradingPlaza'",
    Callback = function() teleportPlace("TradingPlaza") end
})

Tabs.Main:AddButton({
    Title = "⛓ Join Default JobId",
    Description = "Force join correct DEFAULT job",
    Callback = function() joinJobId(DEFAULT_PLACE_ID, DEFAULT_JOB_ID) end
})

Tabs.Main:AddButton({
    Title = "⛓ Join Plaza JobId",
    Description = "Force join correct PLAZA job",
    Callback = function() joinJobId(PLAZA_PLACE_ID, PLAZA_JOB_ID) end
})

-- Fluent Addon Integration
SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({})
InterfaceManager:SetFolder("MyScriptHub")
SaveManager:SetFolder("MyScriptHub/MyGame")
InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)
Window:SelectTab(1)

Fluent:Notify({ Title = "Fluent", Content = "Script loaded successfully!", Duration = 6 })
SaveManager:LoadAutoloadConfig()
