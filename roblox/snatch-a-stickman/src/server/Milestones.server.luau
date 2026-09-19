-- Lifetime milestone rewards for Snatch the Stickman.
-- Rewards only fire when a player crosses a threshold during the current server session,
-- so reconnecting with an already-earned lifetime total cannot duplicate rewards.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local remotes = ReplicatedStorage:WaitForChild("GameRemotes")
local toastRemote = remotes:WaitForChild("Toast")

local MILESTONES = {
	TotalRecruits = {
		Label = "RECRUITER",
		Unit = "recruits",
		Thresholds = {
			{Goal = 10, Reward = 250},
			{Goal = 25, Reward = 600},
			{Goal = 50, Reward = 1400},
			{Goal = 100, Reward = 3500},
			{Goal = 250, Reward = 9000},
		},
	},
	TotalSnatches = {
		Label = "SNATCHER",
		Unit = "successful snatches",
		Thresholds = {
			{Goal = 5, Reward = 400},
			{Goal = 15, Reward = 1000},
			{Goal = 30, Reward = 2400},
			{Goal = 75, Reward = 6500},
			{Goal = 150, Reward = 15000},
		},
	},
	LifetimeCoinsEarned = {
		Label = "MOGUL",
		Unit = "lifetime coins",
		Thresholds = {
			{Goal = 2500, Reward = 300},
			{Goal = 10000, Reward = 900},
			{Goal = 50000, Reward = 3000},
			{Goal = 250000, Reward = 10000},
			{Goal = 1000000, Reward = 30000},
		},
	},
	BestStreak = {
		Label = "ESCAPE ARTIST",
		Unit = "best streak",
		Thresholds = {
			{Goal = 3, Reward = 350},
			{Goal = 5, Reward = 800},
			{Goal = 10, Reward = 2200},
			{Goal = 20, Reward = 6000},
		},
	},
}

local connections = {}

local function toast(player, message)
	if player.Parent == Players then
		toastRemote:FireClient(player, message)
	end
end

local function getCoins(player)
	local leaderstats = player:FindFirstChild("leaderstats")
	local coins = leaderstats and leaderstats:FindFirstChild("Coins")
	if coins and coins:IsA("IntValue") then
		return coins
	end
	return nil
end

local function waitForDataReady(player)
	if player:GetAttribute("DataReady") == true then
		return true
	end

	local deadline = os.clock() + 25
	while player.Parent == Players and player:GetAttribute("DataReady") ~= true and os.clock() < deadline do
		task.wait(0.1)
	end
	return player.Parent == Players and player:GetAttribute("DataReady") == true
end

local function nextMilestone(spec, value)
	for _, milestone in ipairs(spec.Thresholds) do
		if value < milestone.Goal then
			return milestone
		end
	end
	return nil
end

local function publishProgress(player, fieldName, spec, value)
	local nextGoal = nextMilestone(spec, value)
	player:SetAttribute("Milestone_" .. fieldName .. "_Value", value)
	player:SetAttribute("Milestone_" .. fieldName .. "_NextGoal", nextGoal and nextGoal.Goal or 0)
	player:SetAttribute("Milestone_" .. fieldName .. "_NextReward", nextGoal and nextGoal.Reward or 0)
	player:SetAttribute("Milestone_" .. fieldName .. "_Complete", nextGoal == nil)
end

local function attachPlayer(player)
	local profile = player:WaitForChild("Profile", 20)
	if not profile or not waitForDataReady(player) then
		return
	end

	local playerConnections = {}
	connections[player] = playerConnections

	for fieldName, spec in pairs(MILESTONES) do
		local valueObject = profile:WaitForChild(fieldName, 10)
		if valueObject and valueObject:IsA("IntValue") then
			-- Baseline only after persistence has loaded. Existing lifetime progress is never re-paid.
			local previous = valueObject.Value
			publishProgress(player, fieldName, spec, previous)

			local connection = valueObject.Changed:Connect(function(newValue)
				if player.Parent ~= Players then
					return
				end

				newValue = math.max(0, math.floor(tonumber(newValue) or 0))
				if newValue > previous then
					for _, milestone in ipairs(spec.Thresholds) do
						if previous < milestone.Goal and newValue >= milestone.Goal then
							local coins = getCoins(player)
							if coins then
								coins.Value += milestone.Reward
								toast(player, string.format("%s MILESTONE: %d %s! +$%d", spec.Label, milestone.Goal, spec.Unit, milestone.Reward))
							end
						end
					end
				end

				previous = math.max(previous, newValue)
				publishProgress(player, fieldName, spec, newValue)
			end)
			table.insert(playerConnections, connection)
		end
	end
end

Players.PlayerAdded:Connect(function(player)
	task.spawn(attachPlayer, player)
end)

for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(attachPlayer, player)
end

Players.PlayerRemoving:Connect(function(player)
	local playerConnections = connections[player]
	if playerConnections then
		for _, connection in ipairs(playerConnections) do
			connection:Disconnect()
		end
	end
	connections[player] = nil
end)
