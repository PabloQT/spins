-- ✅ ROBLOX TELEPORT GUI WITH USER CONFIG SAVE (Rayfield + Custom JSON Config)

-- Load Rayfield UI Library
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

-- Roblox services
local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local Player = Players.LocalPlayer
local username = Player.Name

-- File config
local configName = "Teleport_" .. username .. ".config"

-- Default values
local settings = {
    customDefaultJobId = "",
    customPlazaJobId = "",
    delay = 5,
    useBuiltIn = true,
    useCustom = false,
    autoClaim = false
}

-- Load settings from file if available
local function loadSettings()
    if isfile(configName) then
        local data = readfile(configName)
        local success, saved = pcall(function()
            return HttpService:JSONDecode(data)
        end)
        if success then
            for k, v in pairs(saved) do
                settings[k] = v
            end
        end
    end
end

-- Save settings to file
local function saveSettings()
    local data = HttpService:JSONEncode(settings)
    writefile(configName, data)
end

-- Initialize settings
loadSettings()

-- Job and Place IDs
local DEFAULT_PLACE_ID = 13772394625
local DEFAULT_JOB_ID = "8383dc55-82d3-45bb-83d5-d4bbd50e7f41"
local PLAZA_PLACE_ID = 16581637217
local PLAZA_JOB_ID = "96c12b32-ee1e-43d2-aa65-23a4598f3df0"

-- Claim reward remote
local claimRemote = ReplicatedStorage:FindFirstChild("ClaimRewardRemote")
if not claimRemote and ReplicatedStorage:FindFirstChild("RE") then
    claimRemote = ReplicatedStorage.RE:FindFirstChild("ClaimReward")
end

-- Rayfield UI
local Window = Rayfield:CreateWindow({
    Name = "Teleport GUI 🌐",
    LoadingTitle = "Teleport GUI",
    LoadingSubtitle = "By Fluxus",
    ConfigurationSaving = {
        Enabled = false
    },
    KeySystem = false
})

local TeleportTab = Window:CreateTab("Teleport", "globe")
local RewardTab = Window:CreateTab("Rewards", "gift")

-- Inputs
TeleportTab:CreateInput({
    Name = "Default JobId",
    PlaceholderText = "Enter JobId for Default",
    RemoveTextAfterFocusLost = true,
    Callback = function(text)
        settings.customDefaultJobId = text
        saveSettings()
    end
})

TeleportTab:CreateInput({
    Name = "Plaza JobId",
    PlaceholderText = "Enter JobId for Plaza",
    RemoveTextAfterFocusLost = true,
    Callback = function(text)
        settings.customPlazaJobId = text
        saveSettings()
    end
})

TeleportTab:CreateInput({
    Name = "Teleport Delay (sec)",
    PlaceholderText = "e.g. 5",
    RemoveTextAfterFocusLost = true,
    Callback = function(text)
        local n = tonumber(text)
        if n then settings.delay = math.clamp(n, 0, 30) saveSettings() end
    end
})

-- Toggles
TeleportTab:CreateToggle({
    Name = "Use Built-in JobIds",
    CurrentValue = settings.useBuiltIn,
    Callback = function(val)
        settings.useBuiltIn = val
        saveSettings()
    end
})

TeleportTab:CreateToggle({
    Name = "Use Custom JobIds",
    CurrentValue = settings.useCustom,
    Callback = function(val)
        settings.useCustom = val
        saveSettings()
    end
})

RewardTab:CreateToggle({
    Name = "Auto Claim Rewards 🎁",
    CurrentValue = settings.autoClaim,
    Callback = function(val)
        settings.autoClaim = val
        saveSettings()

        if val and claimRemote then
            task.spawn(function()
                while settings.autoClaim do
                    pcall(function()
                        claimRemote:FireServer()
                    end)
                    task.wait(10)
                end
            end)
        end
    end
})

-- Teleport Helpers
local function getJobId(placeId)
    if settings.useCustom then
        if placeId == DEFAULT_PLACE_ID then return settings.customDefaultJobId end
        if placeId == PLAZA_PLACE_ID then return settings.customPlazaJobId end
    end
    if settings.useBuiltIn then
        if placeId == DEFAULT_PLACE_ID then return DEFAULT_JOB_ID end
        if placeId == PLAZA_PLACE_ID then return PLAZA_JOB_ID end
    end
    return nil
end

local function teleportTo(placeId, jobId)
    if not jobId or jobId == "" then
        Rayfield:Notify({Title = "⚠️ No JobId", Content = "Please enter a valid JobId", Duration = 4})
        return
    end

    Rayfield:Notify({Title = "Teleporting", Content = "Waiting " .. settings.delay .. "s", Duration = settings.delay})
    task.wait(settings.delay)
    pcall(function()
        TeleportService:TeleportToPlaceInstance(placeId, jobId, Player)
    end)
end

-- Loop Toggle
TeleportTab:CreateToggle({
    Name = "Auto Server Switch 🔁",
    CurrentValue = false,
    Callback = function(val)
        if val then
            task.spawn(function()
                while val do
                    local place = game.PlaceId
                    local nextPlace, nextJob

                    if place == DEFAULT_PLACE_ID then
                        nextPlace = PLAZA_PLACE_ID
                        nextJob = getJobId(PLAZA_PLACE_ID)
                    elseif place == PLAZA_PLACE_ID then
                        nextPlace = DEFAULT_PLACE_ID
                        nextJob = getJobId(DEFAULT_PLACE_ID)
                    else
                        Rayfield:Notify({Title = "Unsupported Place", Content = "You're not in Default or Plaza", Duration = 5})
                        break
                    end

                    teleportTo(nextPlace, nextJob)
                    task.wait(settings.delay + 1)
                end
            end)
        end
    end
})
