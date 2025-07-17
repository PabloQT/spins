local Players = game:GetService("Players")

local TeleportService = game:GetService("TeleportService")

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Player = Players.LocalPlayer

local CoreGui = game:GetService("CoreGui")



-- Target info

local DEFAULT_PLACE_ID = 13772394625

local DEFAULT_JOB_ID = "8383dc55-82d3-45bb-83d5-d4bbd50e7f41"

local PLAZA_PLACE_ID = 16581637217

local PLAZA_JOB_ID = "96c12b32-ee1e-43d2-aa65-23a4598f3df0"



-- Replicated teleport path

local net = ReplicatedStorage.Packages._Index["sleitnick_net@0.1.0"].net

local placeTeleport = net:FindFirstChild("RE/PlaceTeleport")



-- Reward claim remote

local claimRemote = net:FindFirstChild("RE/FriendsList/CollectReward")



-- Create UI label to show process

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

    label.Text = "Starting..."

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



-- Helper: teleport using FireServer with countdown

local function teleportPlace(placeName)

    countdown(5, "🌐 Teleporting to: " .. placeName)

    if placeTeleport then

        placeTeleport:FireServer(placeName)

    else

        status.Text = "⚠️ Teleport remote not found!"

    end

end



-- Helper: join exact JobId with countdown

local function joinJobId(targetPlaceId, targetJobId)

    countdown(5, "🛠 Joining correct JobId")

    local success, err = pcall(function()

        TeleportService:TeleportToPlaceInstance(targetPlaceId, targetJobId, Player)

    end)

    if not success then

        warn("TeleportToPlaceInstance failed:", err)

        status.Text = "❌ JobId teleport failed"

    end

end



-- Claim rewards only if jobid matches

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



-- Main loop

local function runLoop()

    repeat wait() until game:IsLoaded()

    while true do

        local placeId = game.PlaceId

        local jobId = game.JobId



        if placeId == DEFAULT_PLACE_ID then

            if jobId == DEFAULT_JOB_ID then

                status.Text = "✅ In Default (correct JobId)"

                claimRewards()

                wait(2)

                teleportPlace("TradingPlaza")

            else

                status.Text = "❌ In Default but wrong JobId"

                joinJobId(DEFAULT_PLACE_ID, DEFAULT_JOB_ID)

            end



        elseif placeId == PLAZA_PLACE_ID then

            if jobId == PLAZA_JOB_ID then

                status.Text = "✅ In Plaza (correct JobId)"

                claimRewards()

                wait(2)

                teleportPlace("Default")

            else

                status.Text = "❌ In Plaza but wrong JobId"

                joinJobId(PLAZA_PLACE_ID, PLAZA_JOB_ID)

            end



        else

            status.Text = "🚫 Not in recognized place (Default or Plaza)"

            break

        end



        wait(2) -- small buffer before next loop

    end

end



runLoop()
