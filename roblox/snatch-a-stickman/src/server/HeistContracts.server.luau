local Players = game:GetService("Players")

local STEP = 3
local sessions = {}

local function rewardFor(completed)
	return math.min(650, 90 + completed * 35)
end

local function publish(player, total)
	local completed = math.floor(math.max(0, total) / STEP)
	player:SetAttribute("HeistContractStart", completed * STEP)
	player:SetAttribute("HeistContractTarget", (completed + 1) * STEP)
	player:SetAttribute("HeistContractReward", rewardFor(completed))
	player:SetAttribute("HeistContractProgress", total)
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
				local amount = rewardFor(tier - 1)
				coins.Value += amount
				local lifetime = profile:FindFirstChild("LifetimeCoinsEarned")
				if lifetime then lifetime.Value += amount end
				local earned = profile:FindFirstChild("SessionEarned")
				if earned then earned.Value += amount end
			end
		end
		publish(player, after)
	end)
end

Players.PlayerAdded:Connect(function(player) task.spawn(start, player) end)
for _, player in ipairs(Players:GetPlayers()) do task.spawn(start, player) end
Players.PlayerRemoving:Connect(function(player) sessions[player] = nil end)
