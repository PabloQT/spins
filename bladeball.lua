local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Player = Players.LocalPlayer
local CoreGui = game:GetService("CoreGui")

-- Constants
local DEFAULT_PLACE_ID = 13772394625
local DEFAULT_JOB_ID = "8383dc55-82d3-45bb-83d5-d4bbd50e7f41"
local PLAZA_PLACE_ID = 16581637217
local PLAZA_JOB_ID = "96c12b32-ee1e-43d2-aa65-23a4598f3df0"

-- Networking
local net = ReplicatedStorage.Packages._Index["sleitnick_net@0.1.0"].net
local placeTeleport = net:FindFirstChild("RE/PlaceTeleport")
local claimRemote = net:FindFirstChild("RE/FriendsList/CollectReward")

-- UI Setup
local function createUI()
    local gui = Instance.new("ScreenGui")
    gui.Name = "SleekStatusUI"
    gui.ResetOnSpawn = false
    gui.Parent = CoreGui

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 420, 0, 100)
    frame.Position = UDim2.new(0.5, -210, 0, 50)
    frame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    frame.BackgroundTransparency = 0.15
    frame.BorderSizePixel = 0
    frame.AnchorPoint = Vector2.new(0.5, 0)
    frame.ClipsDescendants = true
    frame.Parent = gui

    -- Rounded corners
    local corner = Instance.new("UICorner", frame)
    corner.CornerRadius = UDim.new(0, 15)

    -- Gradient overlay for subtle shine
    local gradient = Instance.new("UIGradient", frame)
    gradient.Rotation = 90
    gradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(80, 80, 100)),
        ColorSequenceKeypoint.new(0.4, Color3.fromRGB(40, 40, 50)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(80, 80, 100))
    }
    gradient.Transparency = NumberSequence.new{
        NumberSequenceKeypoint.new(0, 0.8),
        NumberSequenceKeypoint.new(0.3, 1),
        NumberSequenceKeypoint.new(0.7, 1),
        NumberSequenceKeypoint.new(1, 0.8)
    }

    -- Title label
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 30)
    title.BackgroundTransparency = 1
    title.TextColor3 = Color3.fromRGB(190, 190, 255)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 20
    title.Text = "Teleport + Rewards Manager"
    title.Parent = frame

    -- Status label
    local status = Instance.new("TextLabel")
    status.Size = UDim2.new(1, -40, 0, 50)
    status.Position = UDim2.new(0, 20, 0, 40)
    status.BackgroundTransparency = 1
    status.TextColor3 = Color3.fromRGB(225, 225, 255)
    status.TextWrapped = true
    status.Font = Enum.Font.Gotham
    status.TextSize = 18
    status.TextXAlignment = Enum.TextXAlignment.Left
    status.TextYAlignment = Enum.TextYAlignment.Top
    status.Text = "Initializing..."
    status.Parent = frame

    -- Loading spinner (rotating circle)
    local spinner = Instance.new("ImageLabel")
    spinner.Size = UDim2.new(0, 30, 0, 30)
    spinner.Position = UDim2.new(1, -40, 0, 35)
    spinner.BackgroundTransparency = 1
    spinner.Image = "rbxassetid://2404950086" -- Cool spinner asset (circle)
    spinner.Parent = frame

    -- Animate spinner rotation
    coroutine.wrap(function()
        local angle = 0
        while gui.Parent do
            angle = (angle + 6) % 360
            spinner.Rotation = angle
            RunService.Heartbeat:Wait()
        end
    end)()

    -- Fade in animation
    frame.BackgroundTransparency = 1
    title.TextTransparency = 1
    status.TextTransparency = 1
    spinner.ImageTransparency = 1
    local fadeInSteps = 20
    for i = 1, fadeInSteps do
        local t = i / fadeInSteps
        frame.BackgroundTransparency = 0.15 * (1 - t)
        title.TextTransparency = 1 - t
        status.TextTransparency = 1 - t
        spinner.ImageTransparency = 1 - t
        task.wait(0.03)
    end

    return status
end

local statusLabel = createUI()

-- Utility: update status text with fade effect
local function updateStatus(newText)
    coroutine.wrap(function()
        -- Fade out
        for i = 0, 1, 0.1 do
            statusLabel.TextTransparency = i
            task.wait(0.02)
        end
        statusLabel.Text = newText
        -- Fade in
        for i = 1, 0, -0.1 do
            statusLabel.TextTransparency = i
            task.wait(0.02)
        end
    end)()
end

-- Countdown helper
local function countdown(seconds, actionText)
    for i = seconds, 0, -1 do
        updateStatus(actionText .. " in " .. i .. "s")
        wait(1)
    end
end

-- Teleport helpers
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
            claimedCount = claimedCount + 1
            updateStatus("🎉 Claimed reward " .. i)
        else
            warn("Failed to claim reward", i, err)
            updateStatus("❌ Failed claim reward " .. i)
        end
        task.wait(0.3)
    end
    if claimedCount == 3 then
        updateStatus("✅ All rewards claimed!")
    else
        updateStatus("⚠️ Some rewards failed to claim.")
    end
end

-- Main loop
local function runLoop()
    repeat wait() until game:IsLoaded()
    while true do
        local placeId = game.PlaceId
        local jobId = game.JobId

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
            updateStatus("🚫 Not in recognized place (Default or Plaza)")
            break
        end
        wait(2)
    end
end

-- Start the main loop
runLoop()
