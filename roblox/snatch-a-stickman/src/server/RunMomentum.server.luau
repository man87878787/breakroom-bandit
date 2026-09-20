local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local momentumConfig = Config.RUN_MOMENTUM

local remotes = ReplicatedStorage:WaitForChild("GameRemotes")
local toastRemote = remotes:WaitForChild("Toast")

local sessions = {}

local RANKS = momentumConfig.Ranks

local function award(player, amount)
	local stats = player:FindFirstChild("leaderstats")
	local profile = player:FindFirstChild("Profile")
	local coins = stats and stats:FindFirstChild("Coins")
	if not coins then return end
	coins.Value += amount
	local lifetime = profile and profile:FindFirstChild("LifetimeCoinsEarned")
	local earned = profile and profile:FindFirstChild("SessionEarned")
	if lifetime then lifetime.Value += amount end
	if earned then earned.Value += amount end
end
local function rankFor(score)
	local current = RANKS[1]
	local nextRank = nil
	for index, rank in ipairs(RANKS) do
		if score >= rank.Score then
			current = rank
		else
			nextRank = rank
			break
		end
	end
	return current, nextRank
end

local function calculateScore(player, session)
	local crew = tonumber(player:GetAttribute("CrewCount")) or 0
	local income = tonumber(player:GetAttribute("IncomePerTick")) or 0
	local diversity = tonumber(player:GetAttribute("CrewDiversity")) or 0
	local discoveries = tonumber(player:GetAttribute("DiscoveryCount")) or 0
	local mastery = tonumber(player:GetAttribute("MasteryLevel")) or 0
	local streak = tonumber(player:GetAttribute("CurrentStreak")) or 0
	local snatches = session.snatches.Value
	local earned = session.earned.Value

	local score = momentumConfig.Score
	return crew * score.Crew
		+ math.floor(earned / score.EarnedDivisor)
		+ snatches * score.Snatch
		+ discoveries * score.Discovery
		+ diversity * score.Diversity
		+ mastery * score.Mastery
		+ streak * score.Streak
		+ math.floor(income / score.IncomeDivisor) * score.IncomeStep
end
local function publish(player, session)
	local now = workspace:GetServerTimeNow()
	local elapsed = math.max(0, now - session.startedAt)
	local crew = tonumber(player:GetAttribute("CrewCount")) or 0
	local income = tonumber(player:GetAttribute("IncomePerTick")) or 0
	local diversity = tonumber(player:GetAttribute("CrewDiversity")) or 0
	local discoveries = tonumber(player:GetAttribute("DiscoveryCount")) or 0
	local mastery = tonumber(player:GetAttribute("MasteryLevel")) or 0
	local streak = tonumber(player:GetAttribute("CurrentStreak")) or 0
	local snatches = session.snatches.Value
	local score = calculateScore(player, session)

	local stage
	if crew < 1 then
		stage = "Recruit your first stickman"
	elseif income < 10 then
		stage = "Build income to $10/tick"
	elseif diversity < 2 then
		stage = "Add a second rarity to your crew"
	elseif snatches < 1 then
		stage = "Secure your first rival stickman"
	elseif discoveries < 3 then
		stage = "Discover 3 Stickman Index rarities"
	elseif streak < 3 then
		stage = "Build a 3x snatch streak"
	elseif mastery < 5 then
		stage = "Reach Mastery Level 5"
	elseif income < 100 then
		stage = "Push crew income toward $100/tick"
	elseif elapsed < 480 then
		stage = "Climb the run ranks and diversify your crew"
	else
		stage = "Chase LEGEND rank and max your long-run score"
	end

	local rank, nextRank = rankFor(score)
	player:SetAttribute("SessionRunScore", score)
	player:SetAttribute("SessionRunSeconds", math.floor(elapsed))
	player:SetAttribute("SessionRunObjective", stage)
	player:SetAttribute("SessionRunRank", rank.Name)
	player:SetAttribute("SessionRunNextRank", nextRank and nextRank.Name or "MAX")
	player:SetAttribute("SessionRunNextRankScore", nextRank and nextRank.Score or score)
	player:SetAttribute("SessionRunRankProgress", nextRank and math.clamp((score - rank.Score) / math.max(1, nextRank.Score - rank.Score), 0, 1) or 1)
	return score, rank
end
local function start(player)
	while player.Parent == Players and player:GetAttribute("DataReady") ~= true do task.wait(0.1) end
	if player.Parent ~= Players then return end
	local profile = player:FindFirstChild("Profile")
	if not profile then return end
	local earned = profile:FindFirstChild("SessionEarned")
	local snatches = profile:FindFirstChild("SessionSnatches")
	if not earned or not snatches then return end

	local session = {
		startedAt = workspace:GetServerTimeNow(),
		earned = earned,
		snatches = snatches,
		bonuses = {},
		rankClaims = {},
	}
	sessions[player] = session

	local function milestone(key, condition, amount, message)
		if condition and not session.bonuses[key] then
			session.bonuses[key] = true
			award(player, amount)
			toastRemote:FireClient(player, string.format("RUN BONUS: %s  +$%d", message, amount))
		end
	end

	local function refresh()
		if sessions[player] ~= session then return end
		local crew = tonumber(player:GetAttribute("CrewCount")) or 0
		local income = tonumber(player:GetAttribute("IncomePerTick")) or 0
		local diversity = tonumber(player:GetAttribute("CrewDiversity")) or 0
		local discoveries = tonumber(player:GetAttribute("DiscoveryCount")) or 0
		local mastery = tonumber(player:GetAttribute("MasteryLevel")) or 0
		local streak = tonumber(player:GetAttribute("CurrentStreak")) or 0

		milestone("crew1", crew >= 1, momentumConfig.Bonuses.FirstRecruit, "First recruit")
		milestone("income10", income >= 10, momentumConfig.Bonuses.Income10, "$10/tick income")
		milestone("diversity2", diversity >= 2, momentumConfig.Bonuses.Diversity2, "Two-rarity crew")
		milestone("snatch1", snatches.Value >= 1, momentumConfig.Bonuses.FirstSnatch, "First successful snatch")
		milestone("discovery3", discoveries >= 3, momentumConfig.Bonuses.Discovery3, "Three discoveries")
		milestone("streak3", streak >= 3, momentumConfig.Bonuses.Streak3, "3x snatch streak")
		milestone("crew5", crew >= 5, momentumConfig.Bonuses.Crew5, "Five-stickman crew")
		milestone("income50", income >= 50, momentumConfig.Bonuses.Income50, "$50/tick income")
		milestone("mastery5", mastery >= 5, momentumConfig.Bonuses.Mastery5, "Mastery Level 5")
		milestone("crew8", crew >= 8, momentumConfig.Bonuses.Crew8, "Eight-stickman crew")

		local _, rank = publish(player, session)
		if rank.Reward > 0 and not session.rankClaims[rank.Name] then
			for _, candidate in ipairs(RANKS) do
				if candidate.Score <= rank.Score and candidate.Reward > 0 and not session.rankClaims[candidate.Name] then
					session.rankClaims[candidate.Name] = true
					award(player, candidate.Reward)
					toastRemote:FireClient(player, string.format("%s RUN RANK! +$%d", candidate.Name, candidate.Reward))
					player:SetAttribute("SessionRunRankPulse", (player:GetAttribute("SessionRunRankPulse") or 0) + 1)
				end
			end
		end
	end
	earned.Changed:Connect(refresh)
	snatches.Changed:Connect(refresh)
	for _, attribute in ipairs({
		"CrewCount",
		"IncomePerTick",
		"DiscoveryCount",
		"CrewDiversity",
		"MasteryLevel",
		"CurrentStreak",
	}) do
		player:GetAttributeChangedSignal(attribute):Connect(refresh)
	end
	refresh()

	task.spawn(function()
		while sessions[player] == session and player.Parent == Players do
			publish(player, session)
			task.wait(momentumConfig.PublishInterval)
		end
	end)
end

Players.PlayerAdded:Connect(function(player) task.spawn(start, player) end)
for _, player in ipairs(Players:GetPlayers()) do task.spawn(start, player) end
Players.PlayerRemoving:Connect(function(player) sessions[player] = nil end)
