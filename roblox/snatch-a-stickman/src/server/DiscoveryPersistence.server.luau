-- Isolated persistence for the lifetime Stickman Index.
-- Migrates the original array format into a versioned discovery/claim payload.

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local store = DataStoreService:GetDataStore("SnatchAStickman_Discovery_v1")

local sessions = {}
local closing = false
local MAX_RETRIES = 4
local MAX_BYTES = 4096

local validRarity = {}
for _, rarity in ipairs(Config.RARITIES) do
	validRarity[rarity.Name] = true
end

local function fresh()
	return {
		Version = 2,
		Seen = {},
		Claimed = {},
	}
end
local function retry(label, callback)
	local lastError
	for attempt = 1, MAX_RETRIES do
		local ok, result = pcall(callback)
		if ok then return true, result end
		lastError = result
		warn(string.format("[DiscoveryPersistence] %s attempt %d/%d failed: %s", label, attempt, MAX_RETRIES, tostring(result)))
		if attempt < MAX_RETRIES then
			task.wait(0.6 * (2 ^ (attempt - 1)))
		end
	end
	return false, lastError
end

local function normalize(value)
	local decoded = value
	if type(value) == "string" then
		if #value > MAX_BYTES then return fresh() end
		local ok
		ok, decoded = pcall(HttpService.JSONDecode, HttpService, value)
		if not ok then return fresh() end
	end
	if type(decoded) ~= "table" then return fresh() end

	local clean = fresh()
	if type(decoded.Seen) == "table" then
		for name, timestamp in pairs(decoded.Seen) do
			if validRarity[name] and timestamp then
				clean.Seen[name] = math.max(1, math.floor(tonumber(timestamp) or 1))
			end
		end
	else
		-- v1 migration: ["Common", "Rare", ...]
		for _, name in ipairs(decoded) do
			name = tostring(name)
			if validRarity[name] then
				clean.Seen[name] = 1
			end
		end
	end

	if type(decoded.Claimed) == "table" then
		for _, milestone in ipairs(Config.DISCOVERY_MILESTONES) do
			local key = tostring(milestone.Count)
			if decoded.Claimed[key] == true then
				clean.Claimed[key] = true
			end
		end
	end
	return clean
end

local function encode(data)
	local ok, result = pcall(HttpService.JSONEncode, HttpService, normalize(data))
	if not ok or #result > MAX_BYTES then
		return [[{"Version":2,"Seen":{},"Claimed":{}}]]
	end
	return result
end
local function ensureValue(profile)
	local value = profile:FindFirstChild("DiscoveryData")
	if value and value:IsA("StringValue") then return value end
	if value then value:Destroy() end

	value = Instance.new("StringValue")
	value.Name = "DiscoveryData"
	value.Value = encode(fresh())
	value.Parent = profile
	return value
end

local function setup(player)
	player:SetAttribute("DiscoveryReady", false)

	local profile = player:WaitForChild("Profile", 20)
	if not profile or player.Parent ~= Players then return end
	local value = ensureValue(profile)

	local session = {
		Value = value,
		Loaded = false,
		Dirty = false,
	}
	sessions[player] = session

	local ok, saved = retry("load " .. player.Name, function()
		return store:GetAsync("player_" .. player.UserId)
	end)
	if sessions[player] ~= session or player.Parent ~= Players then return end

	if ok then
		if type(saved) == "table" and saved.DiscoveryData ~= nil then
			saved = saved.DiscoveryData
		end
		value.Value = encode(saved)
		session.Loaded = true
		session.Dirty = false
		value.Changed:Connect(function()
			if sessions[player] == session and session.Loaded then
				session.Dirty = true
			end
		end)
	else
		warn("[DiscoveryPersistence] load unavailable; saving disabled for " .. player.Name)
	end

	player:SetAttribute("DiscoveryReady", true)
end

local function save(player, force)
	local session = sessions[player]
	if not session or not session.Loaded then return false end
	if not force and not session.Dirty then return true end

	local payload = encode(session.Value.Value)
	local ok = retry("save " .. player.Name, function()
		return store:UpdateAsync("player_" .. player.UserId, function(old)
			old = type(old) == "table" and old or {}
			old.Version = 2
			old.DiscoveryData = payload
			old.UpdatedAt = os.time()
			return old
		end)
	end)

	if ok and sessions[player] == session then
		session.Dirty = false
	end
	return ok
end

Players.PlayerAdded:Connect(function(player)
	task.spawn(setup, player)
end)

for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(setup, player)
end

Players.PlayerRemoving:Connect(function(player)
	if not closing then save(player, true) end
	sessions[player] = nil
end)

task.spawn(function()
	while not closing do
		task.wait(60)
		for player in pairs(sessions) do
			if player.Parent == Players then
				task.spawn(save, player, false)
			end
		end
	end
end)
game:BindToClose(function()
	closing = true
	local pending = 0
	local done = Instance.new("BindableEvent")

	for player, session in pairs(sessions) do
		if session.Loaded then
			pending += 1
			task.spawn(function()
				save(player, true)
				pending -= 1
				if pending == 0 then done:Fire() end
			end)
		end
	end

	if pending > 0 then
		task.delay(20, function()
			done:Fire()
		end)
		done.Event:Wait()
	end
	done:Destroy()
end)