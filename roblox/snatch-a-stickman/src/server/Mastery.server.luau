-- Persistent account mastery for Snatch the Stickman.
-- XP sources come only from server-authored progression state.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local remotes = ReplicatedStorage:WaitForChild("GameRemotes")
local toastRemote = remotes:WaitForChild("Toast")

local sessions = {}

local function xpNeeded(level)
	return Config.MASTERY_BASE_XP + math.max(0, level) * Config.MASTERY_XP_GROWTH
end

local function titleFor(level)
	if level >= 30 then return "STICKMAN LEGEND" end
	if level >= 24 then return "MASTER THIEF" end
	if level >= 18 then return "ELITE COLLECTOR" end
	if level >= 12 then return "HEIST VETERAN" end
	if level >= 6 then return "RISING SNATCHER" end
	return "ROOKIE RECRUITER"
end
local function publish(player, levelValue, xpValue)
	local level = math.clamp(levelValue.Value, 0, Config.MASTERY_MAX_LEVEL)
	local nextXP = level >= Config.MASTERY_MAX_LEVEL and 0 or xpNeeded(level)
	local progress = nextXP > 0 and math.clamp(xpValue.Value / nextXP, 0, 1) or 1
	local incomeBonus = math.min(
		Config.MASTERY_INCOME_BONUS_CAP,
		level * Config.MASTERY_INCOME_BONUS_PER_LEVEL
	)

	player:SetAttribute("MasteryLevel", level)
	player:SetAttribute("MasteryXP", xpValue.Value)
	player:SetAttribute("MasteryXPNext", nextXP)
	player:SetAttribute("MasteryProgress", progress)
	player:SetAttribute("MasteryIncomeBonus", incomeBonus)
	player:SetAttribute("MasteryTitle", titleFor(level))
	player:SetAttribute("MasteryMaxed", level >= Config.MASTERY_MAX_LEVEL)
end

local function levelReward(level)
	return Config.MASTERY_LEVEL_REWARD_BASE + level * Config.MASTERY_LEVEL_REWARD_STEP
end

local function giveLevelReward(player, level)
	local stats = player:FindFirstChild("leaderstats")
	local coins = stats and stats:FindFirstChild("Coins")
	local profile = player:FindFirstChild("Profile")
	if not coins then return end

	local reward = levelReward(level)
	coins.Value += reward
	local lifetime = profile and profile:FindFirstChild("LifetimeCoinsEarned")
	if lifetime then lifetime.Value += reward end

	player:SetAttribute("MasteryPulse", (player:GetAttribute("MasteryPulse") or 0) + 1)
	toastRemote:FireClient(player, string.format("MASTERY LEVEL %d! +$%d • %s", level, reward, titleFor(level)))
end
local function addXP(player, session, amount)
	if sessions[player] ~= session or amount <= 0 then return end
	local levelValue = session.Level
	local xpValue = session.XP
	if levelValue.Value >= Config.MASTERY_MAX_LEVEL then
		xpValue.Value = 0
		publish(player, levelValue, xpValue)
		return
	end

	xpValue.Value += math.floor(amount)
	while levelValue.Value < Config.MASTERY_MAX_LEVEL do
		local needed = xpNeeded(levelValue.Value)
		if xpValue.Value < needed then break end
		xpValue.Value -= needed
		levelValue.Value += 1
		giveLevelReward(player, levelValue.Value)
	end

	if levelValue.Value >= Config.MASTERY_MAX_LEVEL then
		xpValue.Value = 0
	end
	publish(player, levelValue, xpValue)
end

local function start(player)
	while player.Parent == Players and player:GetAttribute("DataReady") ~= true do
		task.wait(0.1)
	end
	if player.Parent ~= Players then return end

	local discoveryDeadline = os.clock() + 25
	while player.Parent == Players
		and player:GetAttribute("CollectionBookReady") ~= true
		and os.clock() < discoveryDeadline
	do
		task.wait(0.1)
	end
	if player.Parent ~= Players then return end

	local profile = player:FindFirstChild("Profile")
	if not profile then return end
	local xpValue = profile:FindFirstChild("MasteryXP")
	local levelValue = profile:FindFirstChild("MasteryLevel")
	local recruits = profile:FindFirstChild("SessionRecruits")
	local snatches = profile:FindFirstChild("SessionSnatches")
	local streak = profile:FindFirstChild("CurrentStreak")
	local sessionEarned = profile:FindFirstChild("SessionEarned")
	if not xpValue or not levelValue or not recruits or not snatches or not streak or not sessionEarned then return end
	local session = {
		XP = xpValue,
		Level = levelValue,
		Recruits = recruits.Value,
		Snatches = snatches.Value,
		Discovery = tonumber(player:GetAttribute("DiscoveryCount")) or 0,
		Streak = streak.Value,
		FastRoutes = (profile:FindFirstChild("FastRouteEscapes") and profile.FastRouteEscapes.Value) or 0,
		SkyRoutes = (profile:FindFirstChild("SkyRouteEscapes") and profile.SkyRouteEscapes.Value) or 0,
		EarnClaims = {},
	}
	sessions[player] = session
	player:SetAttribute("FastRouteEscapes", session.FastRoutes)
	player:SetAttribute("SkyRouteEscapes", session.SkyRoutes)
	player:SetAttribute("RouteVersatility", math.min(session.FastRoutes, session.SkyRoutes))
	publish(player, levelValue, xpValue)

	recruits.Changed:Connect(function(value)
		if sessions[player] ~= session then return end
		local delta = math.max(0, value - session.Recruits)
		session.Recruits = math.max(session.Recruits, value)
		addXP(player, session, delta * Config.MASTERY_RECRUIT_XP)
	end)

	snatches.Changed:Connect(function(value)
		if sessions[player] ~= session then return end
		local delta = math.max(0, value - session.Snatches)
		session.Snatches = math.max(session.Snatches, value)
		addXP(player, session, delta * Config.MASTERY_SNATCH_XP)
	end)

	local function connectRouteMastery(valueObject, key, routeName)
		if not valueObject then return end
		valueObject.Changed:Connect(function(value)
			if sessions[player] ~= session then return end
			local before = session[key] or 0
			local delta = math.max(0, value - before)
			session[key] = math.max(before, value)
			player:SetAttribute(key == "FastRoutes" and "FastRouteEscapes" or "SkyRouteEscapes", session[key])
			player:SetAttribute("RouteVersatility", math.min(session.FastRoutes or 0, session.SkyRoutes or 0))
			if delta > 0 then
				addXP(player, session, delta * Config.MASTERY_ROUTE_XP)
				player:SetAttribute("RouteMasteryPulse", (player:GetAttribute("RouteMasteryPulse") or 0) + delta)
				toastRemote:FireClient(player, string.format("%s ROUTE MASTERED! +%d XP", routeName, delta * Config.MASTERY_ROUTE_XP))
			end
		end)
	end
	connectRouteMastery(profile:FindFirstChild("FastRouteEscapes"), "FastRoutes", "FAST")
	connectRouteMastery(profile:FindFirstChild("SkyRouteEscapes"), "SkyRoutes", "SKY")

	streak.Changed:Connect(function(value)
		if sessions[player] ~= session then return end
		if value > session.Streak then
			addXP(player, session, (value - session.Streak) * Config.MASTERY_STREAK_XP)
		end
		session.Streak = value
	end)
	player:GetAttributeChangedSignal("DiscoveryCount"):Connect(function()
		if sessions[player] ~= session then return end
		local value = tonumber(player:GetAttribute("DiscoveryCount")) or 0
		local delta = math.max(0, value - session.Discovery)
		session.Discovery = math.max(session.Discovery, value)
		addXP(player, session, delta * Config.MASTERY_DISCOVERY_XP)
	end)

	local earnGoals = {
		{Value = 250, XP = 20},
		{Value = 1000, XP = 45},
		{Value = 2500, XP = 80},
		{Value = 5000, XP = 130},
		{Value = 10000, XP = 210},
	}

	local function checkEarnGoals()
		if sessions[player] ~= session then return end
		for _, goal in ipairs(earnGoals) do
			if sessionEarned.Value >= goal.Value and not session.EarnClaims[goal.Value] then
				session.EarnClaims[goal.Value] = true
				addXP(player, session, goal.XP)
				toastRemote:FireClient(player, string.format("MASTERY BONUS: earned $%d this run • +%d XP", goal.Value, goal.XP))
			end
		end
	end
	sessionEarned.Changed:Connect(checkEarnGoals)
	checkEarnGoals()

	xpValue.Changed:Connect(function() publish(player, levelValue, xpValue) end)
	levelValue.Changed:Connect(function() publish(player, levelValue, xpValue) end)
end
Players.PlayerAdded:Connect(function(player)
	task.spawn(start, player)
end)

for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(start, player)
end

Players.PlayerRemoving:Connect(function(player)
	sessions[player] = nil
end)
