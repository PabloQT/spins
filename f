-- ⚡ 1h Server Hop + Smart Rejoin Script
-- ✅ Waits 1h, then decides: rejoin if <=5 players, else hop to lowest-pop server

local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")

local gameId = game.PlaceId
local player = Players.LocalPlayer

-- Get servers
local function getServers(cursor)
    local url = "https://games.roblox.com/v1/games/"..gameId.."/servers/Public?sortOrder=Asc&limit=100"
    if cursor ~= "" then
        url = url .. "&cursor=" .. cursor
    end
    local success, response = pcall(function()
        return game:HttpGet(url)
    end)
    if success then
        return HttpService:JSONDecode(response)
    else
        warn("❌ Failed to fetch servers:", response)
        return {data={}}
    end
end

-- Hop to lowest-player server
local function hopLowest()
    local cursor = ""
    local lowestServer = nil
    local lowestPlayers = 999

    while true do
        local servers = getServers(cursor)
        for _, server in pairs(servers.data) do
            if server.playing < lowestPlayers and server.id ~= game.JobId then
                lowestPlayers = server.playing
                lowestServer = server.id
            end
        end
        if servers.nextPageCursor then
            cursor = servers.nextPageCursor
        else
            break
        end
    end

    if lowestServer then
        print("🌏 Hopping to server with "..lowestPlayers.." players...")
        TeleportService:TeleportToPlaceInstance(gameId, lowestServer, player)
    else
        warn("⚠ No servers found!")
    end
end

-- Rejoin current server
local function rejoinSame()
    print("♻ Rejoining same server (low player count)...")
    TeleportService:TeleportToPlaceInstance(gameId, game.JobId, player)
end

-- Main Loop
task.spawn(function()
    while true do
        print("⏳ Waiting 1 hour before check...")
        task.wait(3600) -- 1 hour

        local playerCount = #Players:GetPlayers()
        print("👥 Current server player count:", playerCount)

        if playerCount <= 5 then
            rejoinSame()
        else
            hopLowest()
        end
    end
end)
