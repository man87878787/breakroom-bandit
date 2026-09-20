local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local PlayerData = {}
local store
local cache = {}

local function getStore()
	if not store then
		store = game:GetService("DataStoreService"):GetDataStore(Config.PERSISTENCE.StoreName)
	end
	return store
end

local DEFAULT = {
	DataVersion = Config.DATA_VERSION,
	Coins = Config.PLAYER.StartingCoins,
	TowerLevel = Config.PLAYER.StartingTowerLevel,
	MovementLevel = 0,
	DefenseLevel = 0,
	Steals = 0,
	TimesRobbed = 0,
}

local function cloneDefault()
	local copy = {}
	for key, value in pairs(DEFAULT) do
		copy[key] = value
	end
	return copy
end

local function sanitize(raw)
	local data = cloneDefault()
	if type(raw) == "table" then
		for key, defaultValue in pairs(DEFAULT) do
			local value = raw[key]
			if type(value) == type(defaultValue) then
				data[key] = value
			end
		end
	end

	data.Coins = math.max(0, math.floor(data.Coins))
	data.TowerLevel = math.clamp(math.floor(data.TowerLevel), 1, Config.PLAYER.MaxTowerLevel)
	data.MovementLevel = math.clamp(math.floor(data.MovementLevel), 0, Config.UPGRADES.MaxMovementLevel)
	data.DefenseLevel = math.clamp(math.floor(data.DefenseLevel), 0, Config.UPGRADES.MaxDefenseLevel)
	data.Steals = math.max(0, math.floor(data.Steals))
	data.TimesRobbed = math.max(0, math.floor(data.TimesRobbed))
	data.DataVersion = Config.DATA_VERSION
	return data
end

local function keyFor(player)
	return ("player_%d"):format(player.UserId)
end

local function usePersistentStore()
	return not RunService:IsStudio() or Config.PERSISTENCE.EnableStudioDataStore == true
end

function PlayerData.Load(player)
	if not usePersistentStore() then
		local data = cloneDefault()
		cache[player] = data
		return data
	end

	local dataStore = getStore()
	local loaded
	for attempt = 1, Config.PERSISTENCE.MaxRetries do
		local ok, result = pcall(dataStore.GetAsync, dataStore, keyFor(player))
		if ok then
			loaded = result
			break
		end
		if attempt < Config.PERSISTENCE.MaxRetries then
			task.wait(Config.PERSISTENCE.RetryDelaySeconds * attempt)
		end
	end

	local data = sanitize(loaded)
	cache[player] = data
	return data
end

function PlayerData.Get(player)
	return cache[player]
end

function PlayerData.Update(player, callback)
	local data = cache[player]
	if not data then
		return false
	end
	callback(data)
	return true
end

function PlayerData.Save(player)
	local data = cache[player]
	if not data or not usePersistentStore() then
		return true
	end

	local dataStore = getStore()
	local snapshot = sanitize(data)
	for attempt = 1, Config.PERSISTENCE.MaxRetries do
		local ok = pcall(dataStore.UpdateAsync, dataStore, keyFor(player), function()
			return snapshot
		end)
		if ok then
			return true
		end
		if attempt < Config.PERSISTENCE.MaxRetries then
			task.wait(Config.PERSISTENCE.RetryDelaySeconds * attempt)
		end
	end

	warn(("Failed to save data for %s"):format(player.Name))
	return false
end

function PlayerData.Release(player)
	PlayerData.Save(player)
	cache[player] = nil
end

return PlayerData
