-- ⚡ 1h Smart Spam-Hop + Rejoin Script
-- ✅ Wait 1h → if ≤5 players rejoin, else spam hop lowest-pop server until success

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

-- Find lowest-pop server (not current one)
local function findLowestServer()
    local cursor = ""
    local lowestServer, lowestPlayers = nil, 999

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

    return lowestServer, lowestPlayers
end

-- Spam hop until success
local function spamHop()
    while true do
        local serverId, count = findLowestServer()
        if serverId then
            print("🌏 Trying to hop → server with "..count.." players...")
            local success, err = pcall(function()
                TeleportService:TeleportToPlaceInstance(gameId, serverId, player)
            end)
            if success then
                break -- should leave game if teleport works
            else
                warn("⚠ Hop failed, retrying...", err)
            end
        else
            warn("⚠ No server found, retrying...")
        end
        task.wait(2) -- small retry delay
    end
end

-- Rejoin same server
local function rejoinSame()
    print("♻ Rejoining same server (≤5 players)...")
    TeleportService:TeleportToPlaceInstance(gameId, game.JobId, player)
end

-- Main loop
task.spawn(function()
    while true do
        print("⏳ Waiting 1 hour before hop/rejoin...")
        task.wait(3600) -- 1h

        local playerCount = #Players:GetPlayers()
        print("👥 Current player count:", playerCount)

        if playerCount <= 5 then
            rejoinSame()
        else
            spamHop()
        end
    end
end)
