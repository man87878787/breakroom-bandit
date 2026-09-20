local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local remotes = ReplicatedStorage:WaitForChild("GameRemotes")
local toastRemote = remotes:WaitForChild("Toast")

local sessions = {}
local rng = Random.new()

local TARGETS = {}
for _, rarity in ipairs(Config.RARITIES) do
	if (rarity.Rank or 1) >= 2 then
		table.insert(TARGETS, rarity)
	end
end

local function countRarity(collectionValue, rarityName)
	local ok, decoded = pcall(HttpService.JSONDecode, HttpService, collectionValue)
	if not ok or type(decoded) ~= "table" then return 0 end
	local count = 0
	for _, name in ipairs(decoded) do
		if tostring(name) == rarityName then count += 1 end
	end
	return count
end

local function rewardFor(rarity)
	return math.floor(100 + (rarity.Rank or 1) ^ 2 * 90)
end
local function publish(player, session)
	local target = session.Target
	player:SetAttribute("RarityBountyTarget", target and target.Name or "")
	player:SetAttribute("RarityBountyRank", target and target.Rank or 0)
	player:SetAttribute("RarityBountyReward", target and rewardFor(target) or 0)
	player:SetAttribute("RarityBountyExpiresAt", session.ExpiresAt or 0)
	player:SetAttribute("RarityBountyNextAt", session.NextAt or 0)
	player:SetAttribute("RarityBountyActive", target ~= nil)
end

local function chooseTarget(session)
	if #TARGETS == 0 then return nil end
	local choices = {}
	for _, rarity in ipairs(TARGETS) do
		if not session.LastTarget or rarity.Name ~= session.LastTarget then
			table.insert(choices, rarity)
		end
	end
	if #choices == 0 then choices = TARGETS end
	return choices[rng:NextInteger(1, #choices)]
end

local function startBounty(player, session)
	local target = chooseTarget(session)
	if not target then return end
	session.Target = target
	session.LastTarget = target.Name
	session.Baseline = countRarity(session.Collection.Value, target.Name)
	session.ExpiresAt = workspace:GetServerTimeNow() + 80
	session.NextAt = 0
	session.Completed = false
	publish(player, session)
	toastRemote:FireClient(player, string.format("RARITY BOUNTY: acquire a %s stickman for +$%d!", target.Name, rewardFor(target)))
end
local function finishBounty(player, session, success)
	local target = session.Target
	if not target then return end

	if success then
		local reward = rewardFor(target)
		local stats = player:FindFirstChild("leaderstats")
		local profile = player:FindFirstChild("Profile")
		local coins = stats and stats:FindFirstChild("Coins")
		if coins then
			coins.Value += reward
			local lifetime = profile and profile:FindFirstChild("LifetimeCoinsEarned")
			local earned = profile and profile:FindFirstChild("SessionEarned")
			if lifetime then lifetime.Value += reward end
			if earned then earned.Value += reward end
		end
		player:SetAttribute("RarityBountyPulse", (player:GetAttribute("RarityBountyPulse") or 0) + 1)
		player:SetAttribute("RarityBountyLastReward", reward)
		toastRemote:FireClient(player, string.format("BOUNTY COMPLETE: %s secured! +$%d", target.Name, reward))
	else
		toastRemote:FireClient(player, target.Name .. " bounty expired. New target soon.")
	end

	session.Target = nil
	session.Completed = success
	session.ExpiresAt = 0
	session.NextAt = workspace:GetServerTimeNow() + 18
	publish(player, session)
end
local function start(player)
	while player.Parent == Players and player:GetAttribute("DataReady") ~= true do task.wait(0.1) end
	if player.Parent ~= Players then return end

	local profile = player:FindFirstChild("Profile")
	local collection = profile and profile:FindFirstChild("CollectionData")
	if not collection then return end

	local session = {
		Collection = collection,
		Target = nil,
		LastTarget = nil,
		Baseline = 0,
		ExpiresAt = 0,
		NextAt = workspace:GetServerTimeNow() + 22,
	}
	sessions[player] = session
	publish(player, session)

	collection.Changed:Connect(function()
		if sessions[player] ~= session or not session.Target then return end
		local current = countRarity(collection.Value, session.Target.Name)
		if current > session.Baseline then
			finishBounty(player, session, true)
		end
	end)

	task.spawn(function()
		while sessions[player] == session and player.Parent == Players do
			local now = workspace:GetServerTimeNow()
			if session.Target then
				if now >= session.ExpiresAt then
					finishBounty(player, session, false)
				end
			elseif now >= session.NextAt then
				startBounty(player, session)
			end
			task.wait(0.5)
		end
	end)
end
Players.PlayerAdded:Connect(function(player) task.spawn(start, player) end)
for _, player in ipairs(Players:GetPlayers()) do task.spawn(start, player) end
Players.PlayerRemoving:Connect(function(player) sessions[player] = nil end)
