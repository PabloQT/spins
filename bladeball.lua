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
    MinimizeKey = Enum.KeyCode.LeftControl,
    Logo = "rbxassetid://10590477450"
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

-- UI Inputs
local InputDelay = Tabs.Main:AddInput("InputDelay", {
    Title = "Delay (seconds)",
    Default = "1",
    Placeholder = "Delay between actions (e.g. 1)",
    Numeric = true
})

local InputPlazaJobId = Tabs.Main:AddInput("InputPlazaJobId", {
    Title = "Trade Plaza JobId",
    Default = PLAZA_JOB_ID,
    Placeholder = "Enter Plaza JobId",
    Numeric = false
})

local InputDefaultJobId = Tabs.Main:AddInput("InputDefaultJobId", {
    Title = "Default JobId",
    Default = DEFAULT_JOB_ID,
    Placeholder = "Enter Default JobId",
    Numeric = false
})

local InputRepeatCount = Tabs.Main:AddInput("InputRepeatCount", {
    Title = "Repeat Count",
    Default = "100",
    Placeholder = "How many times to repeat claiming",
    Numeric = true
})

-- UI Toggles
local ToggleUseBuiltInJobId = Tabs.Main:AddToggle("ToggleUseBuiltInJobId", {
    Title = "Use Built-in JobId",
    Default = true
})

local ToggleUseInputJobId = Tabs.Main:AddToggle("ToggleUseInputJobId", {
    Title = "Use Input JobId",
    Default = false
})

local ToggleClaimReward = Tabs.Main:AddToggle("ToggleClaimReward", {
    Title = "Claim Reward",
    Default = true
})

local ToggleRunScript = Tabs.Main:AddToggle("ToggleRunScript", {
    Title = "Run Script",
    Default = false
})

-- Helper function to update status
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

-- Read values from UI
local function getJobIdForPlace(placeId)
    if ToggleUseBuiltInJobId.Value then
        if placeId == PLAZA_PLACE_ID then
            return PLAZA_JOB_ID
        elseif placeId == DEFAULT_PLACE_ID then
            return DEFAULT_JOB_ID
        end
    elseif ToggleUseInputJobId.Value then
        if placeId == PLAZA_PLACE_ID then
            return InputPlazaJobId.Value
        elseif placeId == DEFAULT_PLACE_ID then
            return InputDefaultJobId.Value
        end
    end
    return nil
end

local function getDelay()
    return tonumber(InputDelay.Value) or 1
end

local function getRepeatCount()
    return tonumber(InputRepeatCount.Value) or 100
end

local function claimRewards()
    if not ToggleClaimReward.Value then
        updateStatus("⚠️ Claim reward toggle is off.")
        return
    end

    if not claimRemote then
        updateStatus("⚠️ Claim remote not found!")
        return
    end

    local repeatCount = getRepeatCount()
    updateStatus("🎁 Claiming rewards " .. repeatCount .. " times...")

    local claimedTotal = 0
    for count = 1, repeatCount do
        for i = 1, 3 do
            local success, err = pcall(function()
                claimRemote:FireServer(i)
            end)
            if success then
                claimedTotal += 1
                updateStatus("🎉 Claimed reward " .. i .. " (" .. count .. "/" .. repeatCount .. ")")
            else
                warn("Failed to claim reward", i, err)
                updateStatus("❌ Failed reward " .. i .. " (" .. count .. "/" .. repeatCount .. ")")
            end
            task.wait(0.3)
        end
        task.wait(getDelay())
    end

    if claimedTotal == repeatCount * 3 then
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
        if not ToggleRunScript.Value then
            updateStatus("⏸ Script paused (toggle off)")
            wait(1)
            continue
        end

        local placeId, jobId = game.PlaceId, game.JobId
        local targetJobId = getJobIdForPlace(placeId)

        if placeId == DEFAULT_PLACE_ID or placeId == PLAZA_PLACE_ID then
            if jobId == targetJobId then
                updateStatus("✅ In place with correct JobId")
                claimRewards()
                wait(2)
                if placeId == DEFAULT_PLACE_ID then
                    teleportPlace("TradingPlaza")
                else
                    teleportPlace("Default")
                end
            else
                updateStatus("❌ Wrong JobId, joining correct one...")
                joinJobId(placeId, targetJobId)
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
