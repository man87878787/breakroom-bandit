local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local world = workspace:WaitForChild("SnatchTheStickmanWorld")
local remotes = ReplicatedStorage:WaitForChild("GameRemotes")
local toastRemote = remotes:WaitForChild("Toast")

local upgradeDebounce = {}
local missionClaims = {}

local UPGRADES = {
	Income = {
		ValueName = "IncomeLevel",
		Costs = Config.INCOME_UPGRADE_COSTS,
		Label = "INCOME",
		Color = Color3.fromRGB(72, 220, 130),
		Offset = Vector3.new(-17, 0.9, -8),
	},
	Capacity = {
		ValueName = "CapacityLevel",
		Costs = Config.CAPACITY_UPGRADE_COSTS,
		Label = "CAPACITY",
		Color = Color3.fromRGB(70, 160, 255),
		Offset = Vector3.new(-17, 0.9, 0),
	},
	Shield = {
		ValueName = "ShieldLevel",
		Costs = Config.SHIELD_UPGRADE_COSTS,
		Label = "SHIELD",
		Color = Color3.fromRGB(155, 105, 255),
		Offset = Vector3.new(-17, 0.9, 8),
	},
}

local function toast(player, message)
	if player and player.Parent == Players then
		toastRemote:FireClient(player, message)
	end
end

local function ownerForPlot(plotIndex)
	for _, player in ipairs(Players:GetPlayers()) do
		if player:GetAttribute("PlotIndex") == plotIndex then
			return player
		end
	end
	return nil
end

local function getProfileValue(player, name)
	local profile = player and player:FindFirstChild("Profile")
	local value = profile and profile:FindFirstChild(name)
	if value and value:IsA("IntValue") then
		return value
	end
	return nil
end

local function getCoins(player)
	local leaderstats = player and player:FindFirstChild("leaderstats")
	local coins = leaderstats and leaderstats:FindFirstChild("Coins")
	if coins and coins:IsA("IntValue") then
		return coins
	end
	return nil
end

local function updateUpgradePrompt(plotIndex, kind, prompt, label)
	local spec = UPGRADES[kind]
	local owner = ownerForPlot(plotIndex)
	if not owner then
		prompt.Enabled = false
		label.Text = spec.Label .. "\nOPEN BASE"
		return
	end

	prompt.Enabled = true
	local levelValue = getProfileValue(owner, spec.ValueName)
	local level = levelValue and levelValue.Value or 0
	local maxLevel = #spec.Costs

	if level >= maxLevel then
		prompt.ActionText = "Maxed"
		prompt.ObjectText = spec.Label .. " Lv." .. tostring(level)
		label.Text = spec.Label .. "\nMAX LEVEL"
	else
		local cost = spec.Costs[level + 1]
		prompt.ActionText = "Upgrade $" .. tostring(cost)
		prompt.ObjectText = spec.Label .. " Lv." .. tostring(level)
		label.Text = string.format("%s\nLv.%d → %d  •  $%d", spec.Label, level, level + 1, cost)
	end
end

local function makeUpgradePad(plotIndex, plot, kind)
	local spec = UPGRADES[kind]
	local floor = plot:WaitForChild("Floor")

	local pad = Instance.new("Part")
	pad.Name = kind .. "UpgradePad"
	pad.Size = Vector3.new(5.5, 0.7, 5.5)
	pad.CFrame = CFrame.new(floor.Position + spec.Offset)
	pad.Anchored = true
	pad.CanCollide = false
	pad.Material = Enum.Material.Neon
	pad.Color = spec.Color
	pad.Parent = plot

	local surface = Instance.new("SurfaceGui")
	surface.Face = Enum.NormalId.Top
	surface.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	surface.PixelsPerStud = 24
	surface.Parent = pad

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.TextColor3 = Color3.fromRGB(15, 18, 24)
	label.TextScaled = true
	label.TextWrapped = true
	label.Font = Enum.Font.GothamBlack
	label.Parent = surface

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = kind .. "UpgradePrompt"
	prompt.HoldDuration = 0.25
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.Parent = pad

	prompt.Triggered:Connect(function(player)
		if player:GetAttribute("PlotIndex") ~= plotIndex then
			toast(player, "Upgrades can only be bought at your own base.")
			return
		end
		if player:GetAttribute("DataReady") ~= true then
			toast(player, "Your profile is still loading.")
			return
		end

		local now = os.clock()
		if upgradeDebounce[player] and now - upgradeDebounce[player] < 0.4 then
			return
		end
		upgradeDebounce[player] = now

		local levelValue = getProfileValue(player, spec.ValueName)
		local coins = getCoins(player)
		if not levelValue or not coins then
			return
		end

		local level = levelValue.Value
		if level >= #spec.Costs then
			toast(player, spec.Label .. " is already maxed.")
			return
		end

		local cost = spec.Costs[level + 1]
		if coins.Value < cost then
			toast(player, string.format("You need $%d more for that upgrade.", cost - coins.Value))
			return
		end

		coins.Value -= cost
		levelValue.Value += 1
		toast(player, string.format("%s upgraded to level %d!", spec.Label, levelValue.Value))

		local originalSize = pad.Size
		pad.Size = originalSize + Vector3.new(0.8, 0.15, 0.8)
		task.delay(0.15, function()
			if pad.Parent then
				pad.Size = originalSize
			end
		end)

		updateUpgradePrompt(plotIndex, kind, prompt, label)
	end)

	task.spawn(function()
		while pad.Parent do
			updateUpgradePrompt(plotIndex, kind, prompt, label)
			task.wait(1)
		end
	end)
end

for plotIndex = 1, 6 do
	local plot = world:WaitForChild("Plot" .. tostring(plotIndex))
	for kind in pairs(UPGRADES) do
		makeUpgradePad(plotIndex, plot, kind)
	end
end

local function missionAttributeName(kind, suffix)
	return "Mission" .. kind .. suffix
end

local function setMissionState(player, kind, progress, claimed)
	local mission = Config.MISSIONS[kind]
	player:SetAttribute(missionAttributeName(kind, "Progress"), math.min(progress, mission.Goal))
	player:SetAttribute(missionAttributeName(kind, "Goal"), mission.Goal)
	player:SetAttribute(missionAttributeName(kind, "Reward"), mission.Reward)
	player:SetAttribute(missionAttributeName(kind, "Claimed"), claimed == true)
end

local function initializeMissions(player)
	local profile = player:WaitForChild("Profile", 15)
	if not profile or player.Parent ~= Players then
		return
	end

	local sessionRecruits = profile:WaitForChild("SessionRecruits", 10)
	local sessionEarned = profile:WaitForChild("SessionEarned", 10)
	local sessionSnatches = profile:WaitForChild("SessionSnatches", 10)
	if not sessionRecruits or not sessionEarned or not sessionSnatches then
		return
	end

	local claims = {
		Recruit = false,
		Earn = false,
		Snatch = false,
	}
	missionClaims[player] = claims

	local function check(kind, progress)
		if player.Parent ~= Players then
			return
		end
		local mission = Config.MISSIONS[kind]
		if not claims[kind] and progress >= mission.Goal then
			claims[kind] = true
			local coins = getCoins(player)
			if coins then
				coins.Value += mission.Reward
			end
			toast(player, string.format("MISSION COMPLETE: %s  +$%d", mission.Label, mission.Reward))
		end
		setMissionState(player, kind, progress, claims[kind])
	end

	local function refreshAll()
		check("Recruit", sessionRecruits.Value)
		check("Earn", sessionEarned.Value)
		check("Snatch", sessionSnatches.Value)
	end

	sessionRecruits.Changed:Connect(refreshAll)
	sessionEarned.Changed:Connect(refreshAll)
	sessionSnatches.Changed:Connect(refreshAll)
	refreshAll()
end

Players.PlayerAdded:Connect(function(player)
	task.spawn(initializeMissions, player)
end)

for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(initializeMissions, player)
end

Players.PlayerRemoving:Connect(function(player)
	upgradeDebounce[player] = nil
	missionClaims[player] = nil
end)
