local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local remotes = ReplicatedStorage:WaitForChild("GameRemotes")
local toastRemote = remotes:WaitForChild("Toast")

local STEP = 3
local sessions = {}

local NAMES = {
	"QUICK LIFT",
	"BASE BREAKER",
	"HIGH VALUE HEIST",
	"CREW RAID",
	"MASTER SNATCH",
	"LEGEND RUN",
}

local function rewardFor(completed)
	return math.min(1200, 100 + completed * 55)
end

local function streakGoalFor(completed)
	return math.min(6, 2 + math.floor(completed / 2))
end

local function bonusFor(completed)
	return math.min(900, 80 + completed * 45)
end

local function contractName(completed)
	return NAMES[math.min(#NAMES, completed + 1)]
end
local function publish(player, total)
	local completed = math.floor(math.max(0, total) / STEP)
	local start = completed * STEP
	local target = (completed + 1) * STEP
	local streak = tonumber(player:GetAttribute("CurrentStreak")) or 0

	player:SetAttribute("HeistContractTier", completed + 1)
	player:SetAttribute("HeistContractName", contractName(completed))
	player:SetAttribute("HeistContractStart", start)
	player:SetAttribute("HeistContractTarget", target)
	player:SetAttribute("HeistContractReward", rewardFor(completed))
	player:SetAttribute("HeistContractProgress", total)
	player:SetAttribute("HeistContractStreakGoal", streakGoalFor(completed))
	player:SetAttribute("HeistContractStreak", streak)
	player:SetAttribute("HeistContractBonusReward", bonusFor(completed))
end

local function award(player, profile, coins, amount)
	coins.Value += amount
	local lifetime = profile:FindFirstChild("LifetimeCoinsEarned")
	if lifetime then lifetime.Value += amount end
	local earned = profile:FindFirstChild("SessionEarned")
	if earned then earned.Value += amount end
end

local function start(player)
	while player.Parent == Players and player:GetAttribute("DataReady") ~= true do
		task.wait(0.1)
	end
	if player.Parent ~= Players then return end

	local profile = player:FindFirstChild("Profile")
	local stats = player:FindFirstChild("leaderstats")
	local total = profile and profile:FindFirstChild("TotalSnatches")
	local coins = stats and stats:FindFirstChild("Coins")
	if not profile or not total or not coins then return end
	local session = {last = total.Value}
	sessions[player] = session
	publish(player, total.Value)

	total.Changed:Connect(function()
		if sessions[player] ~= session then return end
		local before = session.last
		local after = total.Value
		session.last = after

		if after > before then
			local oldTier = math.floor(before / STEP)
			local newTier = math.floor(after / STEP)
			for tier = oldTier + 1, newTier do
				local completedIndex = tier - 1
				local base = rewardFor(completedIndex)
				local streakGoal = streakGoalFor(completedIndex)
				local streak = tonumber(player:GetAttribute("CurrentStreak")) or 0
				local bonus = streak >= streakGoal and bonusFor(completedIndex) or 0
				local payout = base + bonus

				award(player, profile, coins, payout)
				player:SetAttribute("HeistContractPulse", (player:GetAttribute("HeistContractPulse") or 0) + 1)
				player:SetAttribute("HeistContractLastPayout", payout)
				player:SetAttribute("HeistContractLastBonus", bonus)

				if bonus > 0 then
					toastRemote:FireClient(player, string.format("HEIST CONTRACT COMPLETE! +$%d • streak bonus +$%d", base, bonus))
				else
					toastRemote:FireClient(player, string.format("HEIST CONTRACT COMPLETE! +$%d", base))
				end
			end
		end
		publish(player, after)
	end)

	player:GetAttributeChangedSignal("CurrentStreak"):Connect(function()
		if sessions[player] == session then
			publish(player, total.Value)
		end
	end)
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
