local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local remotes = ReplicatedStorage:WaitForChild("GameRemotes")
local toastRemote = remotes:WaitForChild("Toast")

local sessions = {}

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

local function publish(player, session)
	local now = workspace:GetServerTimeNow()
	local elapsed = math.max(0, now - session.startedAt)
	local crew = player:GetAttribute("CrewCount") or 0
	local income = player:GetAttribute("IncomePerTick") or 0
	local snatches = session.snatches.Value
	local discoveries = player:GetAttribute("DiscoveryCount") or 0
	local score = crew * 20 + math.floor(session.earned.Value / 20) + snatches * 80 + discoveries * 45

	local stage
	if crew < 1 then
		stage = "Recruit your first stickman"
	elseif income < 7 then
		stage = "Build income to $7/tick"
	elseif snatches < 1 then
		stage = "Secure your first rival stickman"
	elseif discoveries < 3 then
		stage = "Discover 3 Stickman Index rarities"
	elseif elapsed < 360 then
		stage = "Grow your crew, index, and protect your base"
	else
		stage = "Push upgrades and extend your snatch streak"
	end

	player:SetAttribute("SessionRunScore", score)
	player:SetAttribute("SessionRunSeconds", math.floor(elapsed))
	player:SetAttribute("SessionRunObjective", stage)
end

local function start(player)
	while player.Parent == Players and player:GetAttribute("DataReady") ~= true do task.wait(0.1) end
	if player.Parent ~= Players then return end
	local profile = player:FindFirstChild("Profile")
	if not profile then return end
	local earned = profile:FindFirstChild("SessionEarned")
	local snatches = profile:FindFirstChild("SessionSnatches")
	if not earned or not snatches then return end

	local session = {startedAt = workspace:GetServerTimeNow(), earned = earned, snatches = snatches, bonuses = {}}
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
		local crew = player:GetAttribute("CrewCount") or 0
		local income = player:GetAttribute("IncomePerTick") or 0
		milestone("crew1", crew >= 1, 35, "First recruit")
		milestone("income7", income >= 7, 75, "$7/tick income")
		milestone("snatch1", snatches.Value >= 1, 125, "First successful snatch")
		milestone("crew5", crew >= 5, 175, "Five-stickman crew")
		publish(player, session)
	end

	earned.Changed:Connect(refresh)
	snatches.Changed:Connect(refresh)
	player:GetAttributeChangedSignal("CrewCount"):Connect(refresh)
	player:GetAttributeChangedSignal("IncomePerTick"):Connect(refresh)
	player:GetAttributeChangedSignal("DiscoveryCount"):Connect(refresh)
	refresh()

	task.spawn(function()
		while sessions[player] == session and player.Parent == Players do
			publish(player, session)
			task.wait(5)
		end
	end)
end

Players.PlayerAdded:Connect(function(player) task.spawn(start, player) end)
for _, player in ipairs(Players:GetPlayers()) do task.spawn(start, player) end
Players.PlayerRemoving:Connect(function(player) sessions[player] = nil end)