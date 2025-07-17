local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Player = Players.LocalPlayer
local CoreGui = game:GetService("CoreGui")

-- Variables for your script with defaults
local useBuiltInJobId = true
local useInputJobId = false
local claimRewardToggle = true
local repeatCount = 1
local inputDelay = 5
local tradePlazaJobId = "96c12b32-ee1e-43d2-aa65-23a4598f3df0"
local defaultJobId = "8383dc55-82d3-45bb-83d5-d4bbd50e7f41"
local runScript = false

-- Your default constants
local DEFAULT_PLACE_ID = 13772394625
local DEFAULT_JOB_ID = "8383dc55-82d3-45bb-83d5-d4bbd50e7f41"
local PLAZA_PLACE_ID = 16581637217
local PLAZA_JOB_ID = "96c12b32-ee1e-43d2-aa65-23a4598f3df0"

local net = ReplicatedStorage.Packages._Index["sleitnick_net@0.1.0"].net
local placeTeleport = net:FindFirstChild("RE/PlaceTeleport")
local claimRemote = net:FindFirstChild("RE/FriendsList/CollectReward")

-- UI creation
local function createUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "JobTeleportUI"
    screenGui.Parent = CoreGui
    screenGui.ResetOnSpawn = false

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 400, 0, 400)
    frame.Position = UDim2.new(0, 20, 0, 50)
    frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    frame.Parent = screenGui

    local function createLabel(text, posY)
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, -20, 0, 25)
        label.Position = UDim2.new(0, 10, 0, posY)
        label.BackgroundTransparency = 1
        label.TextColor3 = Color3.new(1,1,1)
        label.Text = text
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = frame
        return label
    end

    local function createTextBox(defaultText, posY)
        local textBox = Instance.new("TextBox")
        textBox.Size = UDim2.new(1, -20, 0, 25)
        textBox.Position = UDim2.new(0, 10, 0, posY)
        textBox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        textBox.TextColor3 = Color3.new(1,1,1)
        textBox.Text = defaultText
        textBox.ClearTextOnFocus = false
        textBox.Parent = frame
        return textBox
    end

    local function createToggle(text, posY)
        local checkbox = Instance.new("TextButton")
        checkbox.Size = UDim2.new(0, 20, 0, 20)
        checkbox.Position = UDim2.new(0, 10, 0, posY)
        checkbox.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
        checkbox.Text = ""
        checkbox.Parent = frame

        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, -40, 0, 20)
        label.Position = UDim2.new(0, 40, 0, posY)
        label.BackgroundTransparency = 1
        label.TextColor3 = Color3.new(1,1,1)
        label.Text = text
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = frame

        local checked = false

        local function update()
            if checked then
                checkbox.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
            else
                checkbox.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
            end
        end

        checkbox.MouseButton1Click:Connect(function()
            checked = not checked
            update()
            checkbox.OnToggle(checked)
        end)

        update()

        -- Dummy OnToggle function to be overwritten
        checkbox.OnToggle = function() end
        return checkbox
    end

    -- Inputs and toggles with positions
    local posY = 10

    createLabel("Input Delay (seconds):", posY)
    local inputDelayBox = createTextBox(tostring(inputDelay), posY + 25)
    posY = posY + 60

    createLabel("Trade Plaza JobID:", posY)
    local tradePlazaJobIdBox = createTextBox(tradePlazaJobId, posY + 25)
    posY = posY + 60

    createLabel("Default JobID:", posY)
    local defaultJobIdBox = createTextBox(defaultJobId, posY + 25)
    posY = posY + 60

    local useBuiltInToggle = createToggle("Use Built-in JobID", posY)
    useBuiltInToggle:SetAttribute("checked", true)
    useBuiltInToggle.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
    useBuiltInToggle.OnToggle = function(state)
        useBuiltInJobId = state
        if state then
            useInputJobIdToggle:SetAttribute("checked", false)
            useInputJobIdToggle.BackgroundColor3 = Color3.fromRGB(80,80,80)
            useInputJobId = false
        end
    end
    posY = posY + 35

    local useInputJobIdToggle = createToggle("Use Input JobID", posY)
    useInputJobIdToggle.OnToggle = function(state)
        useInputJobId = state
        if state then
            useBuiltInToggle:SetAttribute("checked", false)
            useBuiltInToggle.BackgroundColor3 = Color3.fromRGB(80,80,80)
            useBuiltInJobId = false
        end
    end
    posY = posY + 35

    local claimRewardToggleBtn = createToggle("Claim Reward", posY)
    claimRewardToggleBtn:SetAttribute("checked", true)
    claimRewardToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
    claimRewardToggleBtn.OnToggle = function(state)
        claimRewardToggle = state
    end
    posY = posY + 35

    createLabel("Repeat Count:", posY)
    local repeatCountBox = createTextBox(tostring(repeatCount), posY + 25)
    posY = posY + 60

    local runScriptToggle = createToggle("Run the Script", posY)
    runScriptToggle.OnToggle = function(state)
        runScript = state
    end
    posY = posY + 35

    -- Input validation on focus lost
    inputDelayBox.FocusLost:Connect(function(enterPressed)
        local val = tonumber(inputDelayBox.Text)
        if val and val >= 0 then
            inputDelay = val
        else
            inputDelayBox.Text = tostring(inputDelay)
        end
    end)

    tradePlazaJobIdBox.FocusLost:Connect(function()
        tradePlazaJobId = tradePlazaJobIdBox.Text
    end)

    defaultJobIdBox.FocusLost:Connect(function()
        defaultJobId = defaultJobIdBox.Text
    end)

    repeatCountBox.FocusLost:Connect(function()
        local val = tonumber(repeatCountBox.Text)
        if val and val > 0 then
            repeatCount = math.floor(val)
        else
            repeatCountBox.Text = tostring(repeatCount)
        end
    end)
end

createUI()

-- Status label creation
local function createStatusGui()
    local gui = Instance.new("ScreenGui", CoreGui)
    gui.Name = "LoopStatus"
    gui.ResetOnSpawn = false

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0, 450, 0, 50)
    label.Position = UDim2.new(0.5, -225, 0, 40)
    label.BackgroundTransparency = 0.3
    label.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.TextScaled = true
    label.Font = Enum.Font.SourceSansBold
    label.Text = "Waiting to start..."
    label.Parent = gui

    return label
end

local status = createStatusGui()

-- Countdown helper
local function countdown(seconds, actionText)
    for i = seconds, 0, -1 do
        status.Text = actionText .. " in " .. i .. "s"
        wait(1)
    end
end

local function teleportPlace(placeName)
    countdown(inputDelay, "🌐 Teleporting to: " .. placeName)
    if placeTeleport then
        placeTeleport:FireServer(placeName)
    else
        status.Text = "⚠️ Teleport remote not found!"
    end
end

local function joinJobId(targetPlaceId, targetJobId)
    countdown(inputDelay, "🛠 Joining correct JobId")
    local success, err = pcall(function()
        TeleportService:TeleportToPlaceInstance(targetPlaceId, targetJobId, Player)
    end)
    if not success then
        warn("TeleportToPlaceInstance failed:", err)
        status.Text = "❌ JobId teleport failed"
    end
end

local function claimRewards()
    if not claimRemote then
        status.Text = "⚠️ Claim remote not found!"
        return
    end
    status.Text = "🎁 Claiming rewards..."
    local claimedCount = 0
    for i = 1, 3 do
        local success, err = pcall(function()
            claimRemote:FireServer(i)
        end)
        if success then
            claimedCount = claimedCount + 1
            status.Text = "🎉 Claimed reward " .. i
        else
            warn("Failed to claim reward", i, err)
            status.Text = "❌ Failed claim reward " .. i
        end
        task.wait(0.3)
    end
    if claimedCount == 3 then
        status.Text = "✅ All rewards claimed!"
    else
        status.Text = "⚠️ Some rewards failed to claim."
    end
end

local function runLoop()
    repeat wait() until game:IsLoaded()

    while true do
        if not runScript then
            status.Text = "⏸ Script paused"
            wait(1)
            continue
        end

        local placeId = game.PlaceId
        local jobId = game.JobId

        -- Choose jobIDs according to toggles
        local curDefaultJobId = useBuiltInJobId and DEFAULT_JOB_ID or defaultJobId
        local curPlazaJobId = useBuiltInJobId and PLAZA_JOB_ID or tradePlazaJobId

        if useInputJobId then
            curDefaultJobId = defaultJobId
            curPlazaJobId = tradePlazaJobId
        end

        if placeId == DEFAULT_PLACE_ID then
            if jobId == curDefaultJobId then
                status.Text = "✅ In Default (correct JobId)"
                if claimRewardToggle then
                    for _ = 1, repeatCount do
                        claimRewards()
                        wait(0.5)
                    end
                end
                wait(2)
                teleportPlace("TradingPlaza")
            else
                status.Text = "❌ In Default but wrong JobId"
                joinJobId(DEFAULT_PLACE_ID, curDefaultJobId)
            end

        elseif placeId == PLAZA_PLACE_ID then
            if jobId == curPlazaJobId then
                status.Text = "✅ In Plaza (correct JobId)"
                if claimRewardToggle then
                    for _ = 1, repeatCount do
                        claimRewards()
                        wait(0.5)
                    end
                end
                wait(2)
                teleportPlace("Default")
            else
                status.Text = "❌ In Plaza but wrong JobId"
                joinJobId(PLAZA_PLACE_ID, curPlazaJobId)
            end

        else
            status.Text = "🚫 Not in recognized place (Default or Plaza)"
            break
        end

        wait(2)
    end
end

-- Run loop in a coroutine to avoid freezing
coroutine.wrap(runLoop)()
