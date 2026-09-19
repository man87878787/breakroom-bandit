-- Durable profile persistence for Snatch the Stickman.
-- Gameplay remains server-authoritative; no client can write profile state directly.

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local STORE_NAME = "SnatchAStickman_PlayerData_v1"
local AUTOSAVE_SECONDS = 45
local MAX_RETRIES = 4
local MAX_REASONABLE_NUMBER = 2_000_000_000
local MAX_COLLECTION_BYTES = 2048

local store = DataStoreService:GetDataStore(STORE_NAME)
local sessions = {}
local shuttingDown = false

local persistentFields = {
	"IncomeLevel",
	"CapacityLevel",
	"ShieldLevel",
	"TotalSnatches",
	"BestStreak",
	"TotalRecruits",
	"LifetimeCoinsEarned",
}

local function keyFor(player)
	return "player_" .. tostring(player.UserId)
end

local function sanitizeInteger(value, minimum, maximum)
	if type(value) ~= "number" or value ~= value then
		return nil
	end
	return math.clamp(math.floor(value), minimum, maximum)
end

local function sanitizeCollection(value)
	if type(value) ~= "string" or #value > MAX_COLLECTION_BYTES then
		return nil
	end
	if value == "" then
		return "[]"
	end
	return value
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

local function waitForProfile(player)
	local leaderstats = player:WaitForChild("leaderstats", 15)
	local profile = player:WaitForChild("Profile", 15)
	if not leaderstats or not profile then
		return nil
	end

	local coins = leaderstats:WaitForChild("Coins", 15)
	local collection = profile:WaitForChild("CollectionData", 15)
	if not coins or not coins:IsA("IntValue") or not collection or not collection:IsA("StringValue") then
		return nil
	end

	for _, name in ipairs(persistentFields) do
		local value = profile:WaitForChild(name, 15)
		if not value or not value:IsA("IntValue") then
			return nil
		end
	end

	return {
		Coins = coins,
		Profile = profile,
		Collection = collection,
	}
end

local function maxLevelFor(name)
	if name == "IncomeLevel" then
		return #Config.INCOME_MULTIPLIERS - 1
	elseif name == "CapacityLevel" then
		return #Config.CAPACITY_BY_LEVEL - 1
	elseif name == "ShieldLevel" then
		return #Config.SHIELD_DURATION_BY_LEVEL - 1
	end
	return MAX_REASONABLE_NUMBER
end

local function snapshot(session)
	local profile = session.Profile
	local data = {
		Version = 2,
		Coins = sanitizeInteger(session.Coins.Value, 0, MAX_REASONABLE_NUMBER) or 0,
		CollectionData = sanitizeCollection(session.Collection.Value) or "[]",
		UpdatedAt = os.time(),
	}

	for _, name in ipairs(persistentFields) do
		local value = profile:FindFirstChild(name)
		if value then
			data[name] = sanitizeInteger(value.Value, 0, maxLevelFor(name)) or 0
		end
	end
	return data
end

local function applyLoadedData(session, data)
	if type(data) ~= "table" then
		return
	end

	local savedCoins = sanitizeInteger(data.Coins, 0, MAX_REASONABLE_NUMBER)
	if savedCoins then
		session.Coins.Value = math.max(session.Coins.Value, savedCoins)
	end

	local savedCollection = sanitizeCollection(data.CollectionData)
	if savedCollection then
		session.Collection.Value = savedCollection
	end

	for _, name in ipairs(persistentFields) do
		local value = session.Profile:FindFirstChild(name)
		local saved = sanitizeInteger(data[name], 0, maxLevelFor(name))
		if value and saved then
			value.Value = math.max(value.Value, saved)
		end
	end
end

local function connectDirtySignals(player, session)
	session.Coins.Changed:Connect(function()
		if sessions[player] == session and session.Loaded then
			session.Dirty = true
		end
	end)
	session.Collection.Changed:Connect(function()
		if sessions[player] == session and session.Loaded then
			session.Dirty = true
		end
	end)
	for _, name in ipairs(persistentFields) do
		local value = session.Profile:FindFirstChild(name)
		if value then
			value.Changed:Connect(function()
				if sessions[player] == session and session.Loaded then
					session.Dirty = true
				end
			end)
		end
	end
end

local function loadPlayer(player)
	player:SetAttribute("DataLoaded", false)
	player:SetAttribute("PersistenceAvailable", false)
	player:SetAttribute("PersistenceStatus", "Loading")

	local handles = waitForProfile(player)
	if not handles or player.Parent ~= Players then
		if player.Parent == Players then
			player:SetAttribute("DataReady", true)
			player:SetAttribute("PersistenceStatus", "Unavailable")
		end
		return
	end

	local session = {
		Coins = handles.Coins,
		Profile = handles.Profile,
		Collection = handles.Collection,
		Loaded = false,
		Dirty = false,
	}
	sessions[player] = session

	local ok, data = retry("load " .. player.Name, function()
		return store:GetAsync(keyFor(player))
	end)

	if player.Parent ~= Players or sessions[player] ~= session then
		return
	end

	if not ok then
		-- Fail open for playability, but never save a session that failed its initial read.
		player:SetAttribute("DataReady", true)
		player:SetAttribute("PersistenceStatus", "Unavailable")
		warn("[Persistence] Data unavailable for " .. player.Name .. "; saving disabled for this session")
		return
	end

	applyLoadedData(session, data)
	session.Loaded = true
	session.Dirty = false
	connectDirtySignals(player, session)

	player:SetAttribute("DataLoaded", true)
	player:SetAttribute("DataReady", true)
	player:SetAttribute("PersistenceAvailable", true)
	player:SetAttribute("PersistenceStatus", "Saved")
end

local function savePlayer(player, force)
	local session = sessions[player]
	if not session or not session.Loaded then
		return false
	end
	if not force and not session.Dirty then
		return true
	end

	local data = snapshot(session)
	player:SetAttribute("PersistenceStatus", "Saving")

	local ok = retry("save " .. player.Name, function()
		return store:UpdateAsync(keyFor(player), function(oldData)
			oldData = type(oldData) == "table" and oldData or {}
			for key, value in pairs(data) do
				oldData[key] = value
			end
			return oldData
		end)
	end)

	if sessions[player] == session then
		if ok then
			session.Dirty = false
			player:SetAttribute("LastDataSave", os.time())
			player:SetAttribute("PersistenceStatus", "Saved")
		else
			player:SetAttribute("PersistenceStatus", "Error")
		end
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
