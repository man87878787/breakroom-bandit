-- Durable economy persistence for Snatch a Stickman.
-- Main.server.luau remains authoritative for gameplay; this service only loads/saves
-- the replicated Coins value and never trusts client input.

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local STORE_NAME = "SnatchAStickman_PlayerData_v1"
local AUTOSAVE_SECONDS = 60
local MAX_RETRIES = 4
local MAX_REASONABLE_COINS = 2_000_000_000

local store = DataStoreService:GetDataStore(STORE_NAME)
local sessions = {}
local shuttingDown = false

local function keyFor(player)
	return "player_" .. tostring(player.UserId)
end

local function sanitizeCoins(value)
	if type(value) ~= "number" or value ~= value then
		return nil
	end
	return math.clamp(math.floor(value), 0, MAX_REASONABLE_COINS)
end

local function retry(label, callback)
	local lastError
	for attempt = 1, MAX_RETRIES do
		local ok, result = pcall(callback)
		if ok then
			return true, result
		end
		lastError = result
		warn(string.format("[Persistence] %s attempt %d/%d failed: %s", label, attempt, MAX_RETRIES, tostring(result)))
		if attempt < MAX_RETRIES then
			task.wait(0.75 * (2 ^ (attempt - 1)))
		end
	end
	return false, lastError
end

local function waitForCoins(player)
	local leaderstats = player:WaitForChild("leaderstats", 15)
	if not leaderstats then
		return nil
	end
	local coins = leaderstats:WaitForChild("Coins", 15)
	if coins and coins:IsA("IntValue") then
		return coins
	end
	return nil
end

local function loadPlayer(player)
	local coins = waitForCoins(player)
	if not coins or player.Parent ~= Players then
		return
	end

	local session = {
		Coins = coins,
		Loaded = false,
		Dirty = false,
		LastSavedCoins = coins.Value,
	}
	sessions[player] = session

	local ok, data = retry("load " .. player.Name, function()
		return store:GetAsync(keyFor(player))
	end)

	if player.Parent ~= Players or sessions[player] ~= session then
		return
	end

	if ok and type(data) == "table" then
		local savedCoins = sanitizeCoins(data.Coins)
		if savedCoins then
			-- Never let a delayed load erase money earned while joining.
			coins.Value = math.max(coins.Value, savedCoins)
		end
	elseif not ok then
		-- Fail open: gameplay remains available. We deliberately avoid saving this
		-- session until a successful load so an outage cannot overwrite good data.
		warn("[Persistence] Data unavailable for " .. player.Name .. "; persistence disabled for this session")
		return
	end

	session.Loaded = true
	session.LastSavedCoins = coins.Value
	player:SetAttribute("DataLoaded", true)

	coins.Changed:Connect(function()
		if sessions[player] == session and session.Loaded then
			session.Dirty = true
		end
	end)
end

local function savePlayer(player, force)
	local session = sessions[player]
	if not session or not session.Loaded then
		return false
	end

	local currentCoins = sanitizeCoins(session.Coins.Value)
	if not currentCoins then
		return false
	end
	if not force and not session.Dirty and currentCoins == session.LastSavedCoins then
		return true
	end

	local ok = retry("save " .. player.Name, function()
		return store:UpdateAsync(keyFor(player), function(oldData)
			oldData = type(oldData) == "table" and oldData or {}
			oldData.Coins = currentCoins
			oldData.Version = 1
			oldData.UpdatedAt = os.time()
			return oldData
		end)
	end)

	if ok and sessions[player] == session then
		session.LastSavedCoins = currentCoins
		session.Dirty = false
		player:SetAttribute("LastDataSave", os.time())
	end
	return ok
end

Players.PlayerAdded:Connect(function(player)
	task.spawn(loadPlayer, player)
end)

for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(loadPlayer, player)
end

Players.PlayerRemoving:Connect(function(player)
	if not shuttingDown then
		savePlayer(player, true)
	end
	sessions[player] = nil
end)

task.spawn(function()
	while not shuttingDown do
		task.wait(AUTOSAVE_SECONDS)
		for player in pairs(sessions) do
			if player.Parent == Players then
				task.spawn(savePlayer, player, false)
			end
		end
	end
end)

game:BindToClose(function()
	shuttingDown = true
	local pending = 0
	local finished = Instance.new("BindableEvent")

	for player, session in pairs(sessions) do
		if session.Loaded then
			pending += 1
			task.spawn(function()
				savePlayer(player, true)
				pending -= 1
				if pending == 0 then
					finished:Fire()
				end
			end)
		end
	end

	if pending > 0 then
		local timedOut = false
		task.delay(25, function()
			timedOut = true
			finished:Fire()
		end)
		finished.Event:Wait()
		if timedOut then
			warn("[Persistence] Shutdown save window expired")
		end
	end
	finished:Destroy()
end)

if RunService:IsStudio() then
	print("[Persistence] Studio note: DataStore access requires a published experience with API Services enabled.")
end
