-- Persistent discovery progression. Watches the authoritative owned-crew snapshot instead of trusting client claims.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local milestoneRewards = {
	[1] = 50,
	[3] = 175,
	[5] = 500,
}

local rarityByName = {}
for _, rarity in ipairs(Config.RARITIES) do
	rarityByName[rarity.Name] = rarity
end

local function decodeSet(raw)
	local result = {}
	local ok, decoded = pcall(HttpService.JSONDecode, HttpService, raw or "[]")
	if ok and type(decoded) == "table" then
		for _, name in ipairs(decoded) do
			if rarityByName[tostring(name)] then
				result[tostring(name)] = true
			end
		end
	end
	return result
end

local function encodeSet(set)
	local ordered = {}
	for _, rarity in ipairs(Config.RARITIES) do
		if set[rarity.Name] then
			table.insert(ordered, rarity.Name)
		end
	end
	local ok, encoded = pcall(HttpService.JSONEncode, HttpService, ordered)
	return ok and encoded or "[]", #ordered
end

local function ensureDiscoveryValue(profile)
	local value = profile:FindFirstChild("DiscoveryData")
	if value and value:IsA("StringValue") then
		return value
	end
	if value then value:Destroy() end
	value = Instance.new("StringValue")
	value.Name = "DiscoveryData"
	value.Value = "[]"
	value.Parent = profile
	return value
end

local function setup(player)
	local profile = player:WaitForChild("Profile", 20)
	if not profile or player.Parent ~= Players then return end
	local collection = profile:WaitForChild("CollectionData", 20)
	if not collection then return end
	local discovery = ensureDiscoveryValue(profile)

	local function scanOwned()
		if player.Parent ~= Players or player:GetAttribute("DataReady") ~= true then return end
		local discovered = decodeSet(discovery.Value)
		local beforeCount = 0
		for _ in pairs(discovered) do beforeCount += 1 end

		local ok, owned = pcall(HttpService.JSONDecode, HttpService, collection.Value)
		if not ok or type(owned) ~= "table" then return end
		local newest
		for _, rawName in ipairs(owned) do
			local name = tostring(rawName)
			if rarityByName[name] and not discovered[name] then
				discovered[name] = true
				newest = name
			end
		end

		local encoded, count = encodeSet(discovered)
		if count == beforeCount then return end
		discovery.Value = encoded
		player:SetAttribute("DiscoveryCount", count)
		player:SetAttribute("DiscoveryTotal", #Config.RARITIES)

		local reward = milestoneRewards[count]
		local leaderstats = player:FindFirstChild("leaderstats")
		local coins = leaderstats and leaderstats:FindFirstChild("Coins")
		if reward and coins and coins:IsA("IntValue") then
			coins.Value += reward
			player:SetAttribute("DiscoveryRewardMessage", string.format("COLLECTION %d/%d • +$%d", count, #Config.RARITIES, reward))
		else
			player:SetAttribute("DiscoveryRewardMessage", string.format("NEW DISCOVERY: %s • %d/%d", newest or "Stickman", count, #Config.RARITIES))
		end
		player:SetAttribute("DiscoveryPulse", (player:GetAttribute("DiscoveryPulse") or 0) + 1)
	end

	local initialSet = decodeSet(discovery.Value)
	local _, initialCount = encodeSet(initialSet)
	player:SetAttribute("DiscoveryCount", initialCount)
	player:SetAttribute("DiscoveryTotal", #Config.RARITIES)

	collection.Changed:Connect(scanOwned)
	discovery.Changed:Connect(function()
		local _, count = encodeSet(decodeSet(discovery.Value))
		player:SetAttribute("DiscoveryCount", count)
		player:SetAttribute("DiscoveryTotal", #Config.RARITIES)
	end)

	task.spawn(function()
		while player.Parent == Players and player:GetAttribute("DataReady") ~= true do task.wait(0.1) end
		if player.Parent == Players then scanOwned() end
	end)
end

Players.PlayerAdded:Connect(function(player) task.spawn(setup, player) end)
for _, player in ipairs(Players:GetPlayers()) do task.spawn(setup, player) end
