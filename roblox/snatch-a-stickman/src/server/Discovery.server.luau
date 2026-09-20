-- Server-authoritative lifetime Stickman Index progression.
-- Watches owned crew snapshots and only runs after main + discovery persistence are ready.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local remotes = ReplicatedStorage:WaitForChild("GameRemotes")
local toastRemote = remotes:WaitForChild("Toast")

local discoveryEvent = remotes:FindFirstChild("DiscoveryEvent") or Instance.new("RemoteEvent")
discoveryEvent.Name = "DiscoveryEvent"
discoveryEvent.Parent = remotes

local rarityByName = {}
for _, rarity in ipairs(Config.RARITIES) do
	rarityByName[rarity.Name] = rarity
end

local sessions = {}

local function fresh()
	return {Version = 2, Seen = {}, Claimed = {}}
end
local function decode(raw)
	local ok, decoded = pcall(HttpService.JSONDecode, HttpService, tostring(raw or ""))
	if not ok or type(decoded) ~= "table" then return fresh() end

	local clean = fresh()
	if type(decoded.Seen) == "table" then
		for name, timestamp in pairs(decoded.Seen) do
			if rarityByName[name] and timestamp then
				clean.Seen[name] = math.max(1, math.floor(tonumber(timestamp) or 1))
			end
		end
	else
		-- Defensive support for the original discovery array format.
		for _, name in ipairs(decoded) do
			name = tostring(name)
			if rarityByName[name] then clean.Seen[name] = 1 end
		end
	end

	if type(decoded.Claimed) == "table" then
		for _, milestone in ipairs(Config.DISCOVERY_MILESTONES) do
			local key = tostring(milestone.Count)
			if decoded.Claimed[key] == true then clean.Claimed[key] = true end
		end
	end
	return clean
end

local function encode(profile, data)
	local value = profile and profile:FindFirstChild("DiscoveryData")
	if not value then return false end
	local ok, json = pcall(HttpService.JSONEncode, HttpService, data)
	if ok then value.Value = json end
	return ok
end
local function countSeen(data)
	local count = 0
	local highest = 0
	for _, rarity in ipairs(Config.RARITIES) do
		if data.Seen[rarity.Name] then
			count += 1
			highest = math.max(highest, rarity.Rank or 0)
		end
	end
	return count, highest
end

local function nextMilestone(data, count)
	for _, milestone in ipairs(Config.DISCOVERY_MILESTONES) do
		if count < milestone.Count or data.Claimed[tostring(milestone.Count)] ~= true then
			return milestone
		end
	end
	return nil
end

local function publish(player, data)
	local count, highest = countSeen(data)
	local total = #Config.RARITIES
	player:SetAttribute("DiscoveryCount", count)
	player:SetAttribute("DiscoveryTotal", total)
	player:SetAttribute("DiscoveryPercent", total > 0 and math.floor(count / total * 100 + 0.5) or 0)
	player:SetAttribute("DiscoveryHighestRank", highest)
	player:SetAttribute("DiscoveryComplete", count >= total)
	player:SetAttribute("CollectionBookReady", true)

	for _, rarity in ipairs(Config.RARITIES) do
		player:SetAttribute("Discovery_" .. rarity.Name, data.Seen[rarity.Name] ~= nil)
	end

	local nextGoal = nextMilestone(data, count)
	player:SetAttribute("DiscoveryNextGoal", nextGoal and nextGoal.Count or 0)
	player:SetAttribute("DiscoveryNextReward", nextGoal and nextGoal.Reward or 0)
end
local function award(player, amount)
	amount = math.max(0, math.floor(tonumber(amount) or 0))
	if amount <= 0 then return end

	local leaderstats = player:FindFirstChild("leaderstats")
	local profile = player:FindFirstChild("Profile")
	local coins = leaderstats and leaderstats:FindFirstChild("Coins")
	if not coins or not coins:IsA("IntValue") then return end

	coins.Value += amount
	local lifetime = profile and profile:FindFirstChild("LifetimeCoinsEarned")
	local sessionEarned = profile and profile:FindFirstChild("SessionEarned")
	if lifetime then lifetime.Value += amount end
	if sessionEarned then sessionEarned.Value += amount end
end

local function currentOwned(profile)
	local collection = profile and profile:FindFirstChild("CollectionData")
	if not collection then return {} end

	local ok, decoded = pcall(HttpService.JSONDecode, HttpService, collection.Value)
	if not ok or type(decoded) ~= "table" then return {} end

	local result = {}
	for _, rawName in ipairs(decoded) do
		local name = tostring(rawName)
		if rarityByName[name] then result[name] = true end
	end
	return result
end

local function ready(player)
	return player:GetAttribute("DataReady") == true and player:GetAttribute("DiscoveryReady") == true
end
local function processOwned(player, session)
	if sessions[player] ~= session or player.Parent ~= Players or not ready(player) then return end

	local present = currentOwned(session.Profile)
	local discoveries = {}
	for _, rarity in ipairs(Config.RARITIES) do
		if present[rarity.Name] and not session.Data.Seen[rarity.Name] then
			session.Data.Seen[rarity.Name] = os.time()
			table.insert(discoveries, rarity)
		end
	end

	local count = countSeen(session.Data)
	local previousCount = math.max(0, count - #discoveries)
	local milestoneByCount = {}
	local recoveredReward = 0

	for _, milestone in ipairs(Config.DISCOVERY_MILESTONES) do
		local key = tostring(milestone.Count)
		if count >= milestone.Count and session.Data.Claimed[key] ~= true then
			session.Data.Claimed[key] = true
			if milestone.Count > previousCount then
				milestoneByCount[milestone.Count] = (milestoneByCount[milestone.Count] or 0) + milestone.Reward
			else
				recoveredReward += milestone.Reward
			end
		end
	end

	local changed = #discoveries > 0 or recoveredReward > 0 or next(milestoneByCount) ~= nil
	if changed and not encode(session.Profile, session.Data) then
		warn("[Discovery] Could not encode discovery state for " .. player.Name)
		return
	end

	publish(player, session.Data)
	if recoveredReward > 0 then
		award(player, recoveredReward)
		local message = string.format("STICKMAN INDEX milestone recovered! +$%d", recoveredReward)
		player:SetAttribute("DiscoveryRewardMessage", message)
		player:SetAttribute("DiscoveryPulse", (player:GetAttribute("DiscoveryPulse") or 0) + 1)
		toastRemote:FireClient(player, message)
	end

	for index, rarity in ipairs(discoveries) do
		local currentCount = previousCount + index
		local baseReward = Config.DISCOVERY_REWARDS[rarity.Name] or 0
		local milestoneReward = milestoneByCount[currentCount] or 0
		local totalReward = baseReward + milestoneReward
		award(player, totalReward)

		local message = string.format("NEW DISCOVERY: %s • %d/%d • +$%d", rarity.Name, currentCount, #Config.RARITIES, totalReward)
		player:SetAttribute("LastDiscoveryRarity", rarity.Name)
		player:SetAttribute("LastDiscoveryAt", workspace:GetServerTimeNow())
		player:SetAttribute("DiscoveryRewardMessage", message)
		player:SetAttribute("DiscoveryPulse", (player:GetAttribute("DiscoveryPulse") or 0) + 1)

		discoveryEvent:FireClient(
			player,
			rarity.Name,
			baseReward,
			milestoneReward,
			currentCount,
			#Config.RARITIES,
			currentCount >= #Config.RARITIES
		)
	end
end
local function setup(player)
	local profile = player:WaitForChild("Profile", 20)
	if not profile or player.Parent ~= Players then return end
	local collection = profile:WaitForChild("CollectionData", 20)
	local discovery = profile:WaitForChild("DiscoveryData", 20)
	if not collection or not discovery then return end

	local deadline = os.clock() + 30
	while player.Parent == Players and not ready(player) and os.clock() < deadline do
		task.wait(0.1)
	end
	if player.Parent ~= Players or not ready(player) then return end

	local session = {
		Profile = profile,
		Data = decode(discovery.Value),
		Connections = {},
	}
	sessions[player] = session
	publish(player, session.Data)
	processOwned(player, session)

	table.insert(session.Connections, collection.Changed:Connect(function()
		processOwned(player, session)
	end))
	table.insert(session.Connections, player:GetAttributeChangedSignal("DataReady"):Connect(function()
		processOwned(player, session)
	end))
	table.insert(session.Connections, player:GetAttributeChangedSignal("DiscoveryReady"):Connect(function()
		processOwned(player, session)
	end))
end
Players.PlayerAdded:Connect(function(player)
	task.spawn(setup, player)
end)

for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(setup, player)
end

Players.PlayerRemoving:Connect(function(player)
	local session = sessions[player]
	if session then
		for _, connection in ipairs(session.Connections) do
			connection:Disconnect()
		end
	end
	sessions[player] = nil
end)