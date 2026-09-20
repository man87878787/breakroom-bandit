local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local rng = Random.new()
local playerState = {}
local openPlots = {}

local remotes = ReplicatedStorage:FindFirstChild("GameRemotes") or Instance.new("Folder")
remotes.Name = "GameRemotes"
remotes.Parent = ReplicatedStorage

local toastRemote = remotes:FindFirstChild("Toast") or Instance.new("RemoteEvent")
toastRemote.Name = "Toast"
toastRemote.Parent = remotes

local carryRemote = remotes:FindFirstChild("CarryState") or Instance.new("RemoteEvent")
carryRemote.Name = "CarryState"
carryRemote.Parent = remotes

local threatRemote = remotes:FindFirstChild("ThreatState") or Instance.new("RemoteEvent")
threatRemote.Name = "ThreatState"
threatRemote.Parent = remotes

local world = workspace:FindFirstChild("SnatchTheStickmanWorld")
if world then
	world:Destroy()
end

world = Instance.new("Folder")
world.Name = "SnatchTheStickmanWorld"
world.Parent = workspace

local function makePart(name, size, cframe, color, material)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = cframe
	part.Anchored = true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	part.Parent = world
	return part
end

makePart(
	"Ground",
	Vector3.new(180, 1, 180),
	CFrame.new(0, -1, 0),
	Color3.fromRGB(22, 24, 30),
	Enum.Material.Slate
)

local marketFloor = makePart(
	"Market",
	Vector3.new(34, 1, 74),
	CFrame.new(0, 0, 0),
	Color3.fromRGB(35, 38, 48),
	Enum.Material.SmoothPlastic
)

local marketLabel = Instance.new("SurfaceGui")
marketLabel.Face = Enum.NormalId.Top
marketLabel.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
marketLabel.PixelsPerStud = 20
marketLabel.Parent = marketFloor

local marketText = Instance.new("TextLabel")
marketText.Size = UDim2.fromScale(1, 1)
marketText.BackgroundTransparency = 1
marketText.Text = "STICKMAN MARKET"
marketText.TextColor3 = Color3.fromRGB(255, 255, 255)
marketText.TextScaled = true
marketText.Font = Enum.Font.GothamBlack
marketText.Parent = marketLabel

local plotPositions = {
	Vector3.new(-58, 0, -52),
	Vector3.new(0, 0, -62),
	Vector3.new(58, 0, -52),
	Vector3.new(-58, 0, 52),
	Vector3.new(0, 0, 62),
	Vector3.new(58, 0, 52),
}

local function toast(player, message)
	if player and player.Parent == Players then
		toastRemote:FireClient(player, message)
	end
end

local function carryState(player, active, message)
	if player and player.Parent == Players then
		carryRemote:FireClient(player, active, message or "")
	end
end

local function threatState(player, active, message)
	if player and player.Parent == Players then
		threatRemote:FireClient(player, active, message or "")
	end
end

local function characterRoot(player)
	local character = player and player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not humanoid or humanoid.Health <= 0 or not root then
		return nil
	end
	return root
end

local function canReachStickman(player, model, maxDistance, extraExclude)
	local root = characterRoot(player)
	local target = model and model.PrimaryPart
	if not root or not target or not target.Parent then
		return false, "That stickman is no longer available."
	end

	local offset = target.Position - (root.Position + Vector3.new(0, 1.2, 0))
	if offset.Magnitude > maxDistance then
		return false, "Move closer before using the snatch hook."
	end

	local excluded = {player.Character}
	if extraExclude then
		table.insert(excluded, extraExclude)
	end

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = excluded
	params.IgnoreWater = true

	local result = workspace:Raycast(root.Position + Vector3.new(0, 1.2, 0), offset, params)
	if result and not result.Instance:IsDescendantOf(model) then
		return false, "Your snatch hook needs a clear path."
	end

	return true
end

local function clearCarryPresentation(player, state, carry)
	if state and state.CarryVisuals then
		for _, item in pairs(state.CarryVisuals) do
			if typeof(item) == "Instance" and item.Parent then
				item:Destroy()
			end
		end
		state.CarryVisuals = nil
	end

	if player then
		player:SetAttribute("CarryRarity", nil)
		player:SetAttribute("CarryVictimName", nil)
		player:SetAttribute("CarryStartedServerTime", nil)
		player:SetAttribute("CarryExpiresServerTime", nil)
		player:SetAttribute("CarryContested", nil)
	end

	local victim = carry and carry.Victim
	if victim then
		victim:SetAttribute("StickmanThreatened", nil)
		victim:SetAttribute("ThreatRarity", nil)
		victim:SetAttribute("ThreatCarrierName", nil)
		victim:SetAttribute("ThreatExpiresServerTime", nil)
		threatState(victim, false)
	end
end

local function startCarryPresentation(player, state, model, rarity, victim)
	clearCarryPresentation(player, state)

	local root = characterRoot(player)
	local target = model and model.PrimaryPart
	if root and target then
		local originAttachment = Instance.new("Attachment")
		originAttachment.Name = "SnatchHookOrigin"
		originAttachment.Position = Vector3.new(0, 0.25, -0.7)
		originAttachment.Parent = root

		local targetAttachment = Instance.new("Attachment")
		targetAttachment.Name = "SnatchHookTarget"
		targetAttachment.Parent = target

		local beam = Instance.new("Beam")
		beam.Name = "SnatchTether"
		beam.Attachment0 = originAttachment
		beam.Attachment1 = targetAttachment
		beam.Width0 = Config.TETHER_WIDTH
		beam.Width1 = Config.TETHER_WIDTH * 0.7
		beam.FaceCamera = true
		beam.Segments = 12
		beam.LightEmission = 0.9
		beam.Color = ColorSequence.new(rarity.Color, Color3.fromRGB(255, 255, 255))
		beam.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.08),
			NumberSequenceKeypoint.new(1, 0.28),
		})
		beam.Parent = root

		local highlight = Instance.new("Highlight")
		highlight.Name = "SnatchCarryHighlight"
		highlight.FillColor = rarity.Color
		highlight.FillTransparency = 0.82
		highlight.OutlineColor = rarity.Color
		highlight.OutlineTransparency = 0.05
		highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
		highlight.Parent = model

		state.CarryVisuals = {
			OriginAttachment = originAttachment,
			TargetAttachment = targetAttachment,
			Beam = beam,
			Highlight = highlight,
		}
	end

	local expiresServerTime = workspace:GetServerTimeNow() + Config.CARRY_TIMEOUT_SECONDS
	player:SetAttribute("CarryRarity", rarity.Name)
	player:SetAttribute("CarryVictimName", victim and victim.DisplayName or "")
	player:SetAttribute("CarryStartedServerTime", workspace:GetServerTimeNow())
	player:SetAttribute("CarryExpiresServerTime", expiresServerTime)

	if victim then
		victim:SetAttribute("StickmanThreatened", true)
		victim:SetAttribute("ThreatRarity", rarity.Name)
		victim:SetAttribute("ThreatCarrierName", player.DisplayName)
		victim:SetAttribute("ThreatExpiresServerTime", expiresServerTime)
		threatState(victim, true, string.format("%s is snatching your %s stickman!", player.DisplayName, rarity.Name))
	end
end

local function broadcastToast(message)
	for _, player in ipairs(Players:GetPlayers()) do
		toast(player, message)
	end
end

local function profileNumber(player, name, defaultValue)
	local profile = player and player:FindFirstChild("Profile")
	local value = profile and profile:FindFirstChild(name)
	if value and value:IsA("IntValue") then
		return value.Value
	end
	return defaultValue
end

local function getCapacity(player)
	local level = math.clamp(profileNumber(player, "CapacityLevel", 0), 0, #Config.CAPACITY_BY_LEVEL - 1)
	return Config.CAPACITY_BY_LEVEL[level + 1]
end

local function getIncomeMultiplier(player)
	local level = math.clamp(profileNumber(player, "IncomeLevel", 0), 0, #Config.INCOME_MULTIPLIERS - 1)
	return Config.INCOME_MULTIPLIERS[level + 1]
end

local function getShieldDuration(player)
	local level = math.clamp(profileNumber(player, "ShieldLevel", 0), 0, #Config.SHIELD_DURATION_BY_LEVEL - 1)
	return Config.SHIELD_DURATION_BY_LEVEL[level + 1]
end

local function getShieldCooldown(player)
	local level = math.clamp(profileNumber(player, "ShieldLevel", 0), 0, #Config.SHIELD_COOLDOWN_BY_LEVEL - 1)
	return Config.SHIELD_COOLDOWN_BY_LEVEL[level + 1]
end

local function canInteract(player)
	return player and player.Parent == Players and player:GetAttribute("DataReady") == true
end

local function awardCoins(state, amount)
	amount = math.max(0, math.floor(amount))
	if amount <= 0 or not state then
		return
	end
	state.Coins.Value += amount
	if state.Profile then
		state.Profile.SessionEarned.Value += amount
		state.Profile.LifetimeCoinsEarned.Value += amount
	end
end

local function refreshState(player, state)
	if not player or not state or player.Parent ~= Players then
		return
	end

	local baseIncome = 0
	local uniqueRarities = {}
	local highestRarityRank = 0
	for _, model in ipairs(state.Sidekicks) do
		if model and model.Parent then
			baseIncome += model:GetAttribute("Income") or 0
			local rarityName = tostring(model:GetAttribute("Rarity") or "Common")
			uniqueRarities[rarityName] = true
			for _, rarity in ipairs(Config.RARITIES) do
				if rarity.Name == rarityName then
					highestRarityRank = math.max(highestRarityRank, rarity.Rank or 0)
					break
				end
			end
		end
	end

	local diversityCount = 0
	for _ in pairs(uniqueRarities) do diversityCount += 1 end
	local diversityBonus = math.min(
		Config.DIVERSITY_BONUS_CAP,
		math.max(0, diversityCount - 1) * Config.DIVERSITY_BONUS_PER_EXTRA_RARITY
	)
	local masteryBonus = math.clamp(tonumber(player:GetAttribute("MasteryIncomeBonus")) or 0, 0, Config.MASTERY_INCOME_BONUS_CAP)
	local marketMultiplier = math.clamp(tonumber(world:GetAttribute("MarketIncomeMultiplier")) or 1, 1, Config.PAYDAY_MULTIPLIER)
	local totalMultiplier = getIncomeMultiplier(player) * (1 + diversityBonus) * (1 + masteryBonus) * marketMultiplier
	local effectiveIncome = math.floor((baseIncome * totalMultiplier) + 0.5)
	local capacity = getCapacity(player)
	player:SetAttribute("CrewCount", #state.Sidekicks)
	player:SetAttribute("Capacity", capacity)
	player:SetAttribute("IncomePerTick", effectiveIncome)
	player:SetAttribute("CrewDiversity", diversityCount)
	player:SetAttribute("CrewDiversityBonus", diversityBonus)
	player:SetAttribute("CrewHighestRarityRank", highestRarityRank)
	player:SetAttribute("IncomeBoostMultiplier", totalMultiplier)
	player:SetAttribute("CurrentStreak", state.Profile and state.Profile.CurrentStreak.Value or 0)
	player:SetAttribute("ShieldUntilServerTime", workspace:GetServerTimeNow() + math.max(0, state.ShieldUntil - os.clock()))
	player:SetAttribute("ShieldReadyServerTime", workspace:GetServerTimeNow() + math.max(0, state.ShieldReadyAt - os.clock()))
	player:SetAttribute("JoinProtectionUntilServerTime", workspace:GetServerTimeNow() + math.max(0, (state.JoinProtectedUntil or 0) - os.clock()))

	local plot = openPlots[state.PlotIndex]
	if plot and plot.Owner == player then
		plot.Label.Text = string.format("%s's Base\n%d/%d • +$%d/tick", player.DisplayName, #state.Sidekicks, capacity, effectiveIncome)
	end
end

local function makePlot(index, position)
	local model = Instance.new("Model")
	model.Name = "Plot" .. index
	model:SetAttribute("PlotIndex", index)
	model:SetAttribute("OwnerUserId", 0)
	model:SetAttribute("OwnerDisplayName", "")
	model:SetAttribute("ShieldUntilServerTime", 0)
	model:SetAttribute("ShieldReadyServerTime", 0)
	model:SetAttribute("JoinProtectionUntilServerTime", 0)
	model.Parent = world

	local floor = Instance.new("Part")
	floor.Name = "Floor"
	floor.Size = Vector3.new(42, 1, 34)
	floor.CFrame = CFrame.new(position)
	floor.Anchored = true
	floor.Color = Color3.fromRGB(42, 46, 58)
	floor.Material = Enum.Material.SmoothPlastic
	floor.Parent = model

	local sign = Instance.new("Part")
	sign.Name = "Sign"
	sign.Size = Vector3.new(14, 5, 1)
	sign.CFrame = CFrame.new(position + Vector3.new(0, 3, 16))
	sign.Anchored = true
	sign.Color = Color3.fromRGB(19, 21, 28)
	sign.Parent = model

	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Back
	gui.Parent = sign

	local label = Instance.new("TextLabel")
	label.Name = "OwnerLabel"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = "OPEN BASE"
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.Parent = gui

	local shield = Instance.new("Part")
	shield.Name = "ShieldVisual"
	shield.Size = Vector3.new(44, 10, 36)
	shield.CFrame = CFrame.new(position + Vector3.new(0, 5, 0))
	shield.Anchored = true
	shield.CanCollide = false
	shield.CanQuery = false
	shield.CanTouch = false
	shield.Transparency = 1
	shield.Material = Enum.Material.ForceField
	shield.Color = Color3.fromRGB(105, 100, 255)
	shield.Parent = model

	local button = Instance.new("Part")
	button.Name = "ShieldButton"
	button.Size = Vector3.new(4, 1, 4)
	button.CFrame = CFrame.new(position + Vector3.new(0, 1, -14))
	button.Anchored = true
	button.Color = Color3.fromRGB(110, 90, 255)
	button.Material = Enum.Material.Neon
	button.Parent = model

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "ShieldPrompt"
	prompt.ActionText = "Activate Shield"
	prompt.ObjectText = "Base Shield"
	prompt.HoldDuration = 0.2
	prompt.MaxActivationDistance = 10
	prompt.Parent = button

	local securePad = Instance.new("Part")
	securePad.Name = "SecurePad"
	securePad.Size = Vector3.new(12, 0.7, 7)
	securePad.CFrame = CFrame.new(position + Vector3.new(0, 0.9, 12))
	securePad.Anchored = true
	securePad.CanCollide = false
	securePad.Color = Color3.fromRGB(65, 255, 140)
	securePad.Material = Enum.Material.Neon
	securePad.Parent = model

	local secureGui = Instance.new("SurfaceGui")
	secureGui.Face = Enum.NormalId.Top
	secureGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	secureGui.PixelsPerStud = 24
	secureGui.Parent = securePad

	local secureText = Instance.new("TextLabel")
	secureText.Size = UDim2.fromScale(1, 1)
	secureText.BackgroundTransparency = 1
	secureText.Text = "SECURE"
	secureText.TextColor3 = Color3.fromRGB(12, 35, 20)
	secureText.TextScaled = true
	secureText.Font = Enum.Font.GothamBlack
	secureText.Parent = secureGui

	local slots = Instance.new("Folder")
	slots.Name = "Slots"
	slots.Parent = model

	for slotIndex = 1, Config.MAX_SIDEKICKS do
		local row = math.floor((slotIndex - 1) / 4)
		local column = (slotIndex - 1) % 4
		local x = -12 + (column * 8)
		local z = -7 + (row * 7)

		local slot = Instance.new("Part")
		slot.Name = tostring(slotIndex)
		slot.Size = Vector3.new(5, 0.4, 5)
		slot.CFrame = CFrame.new(position + Vector3.new(x, 0.75, z))
		slot.Anchored = true
		slot.CanCollide = false
		slot.Color = Color3.fromRGB(61, 66, 82)
		slot.Material = Enum.Material.Neon
		slot.Parent = slots
	end

	openPlots[index] = {
		Model = model,
		Position = position,
		Owner = nil,
		Label = label,
		ShieldVisual = shield,
		ShieldPrompt = prompt,
		SecurePad = securePad,
		Slots = slots,
	}

	prompt.Triggered:Connect(function(player)
		local state = playerState[player]
		if not state or state.PlotIndex ~= index then
			toast(player, "That shield belongs to another base.")
			return
		end

		if not canInteract(player) then
			toast(player, "Loading your profile — one moment.")
			return
		end

		local now = os.clock()
		if now < state.ShieldReadyAt then
			toast(player, string.format("Shield recharging: %ds", math.ceil(state.ShieldReadyAt - now)))
			return
		end

		local duration = getShieldDuration(player)
		local cooldown = getShieldCooldown(player)
		state.ShieldUntil = now + duration
		state.ShieldReadyAt = now + cooldown
		shield.Transparency = 0.72
		refreshState(player, state)
		toast(player, string.format("Base shield active for %ds!", duration))

		task.delay(duration, function()
			if playerState[player] == state and state.ShieldUntil <= os.clock() then
				shield.Transparency = 1
				refreshState(player, state)
			end
		end)
	end)
end

for index, position in ipairs(plotPositions) do
	makePlot(index, position)
end

local function rarityWeight(rarity)
	local weight = rarity.Weight
	if world:GetAttribute("MarketEvent") == "Rare Rush" then
		if (rarity.Rank or 1) >= 3 then
			weight *= Config.RARE_RUSH_EPIC_PLUS_MULTIPLIER
		elseif (rarity.Rank or 1) == 1 then
			weight *= 0.65
		end
	end
	return weight
end

local function weightedRarity()
	local total = 0
	for _, rarity in ipairs(Config.RARITIES) do
		total += rarityWeight(rarity)
	end

	local roll = rng:NextNumber(0, total)
	local running = 0
	for _, rarity in ipairs(Config.RARITIES) do
		running += rarityWeight(rarity)
		if roll <= running then
			return rarity
		end
	end

	return Config.RARITIES[1]
end

local function syncCollection(state)
	if not state or not state.Profile or state.Restoring then
		return
	end

	local encoded = {}
	for _, owned in ipairs(state.Sidekicks) do
		if owned and owned.Parent then
			table.insert(encoded, tostring(owned:GetAttribute("Rarity") or "Common"))
		end
	end

	local ok, json = pcall(HttpService.JSONEncode, HttpService, encoded)
	if ok then
		state.Profile.CollectionData.Value = json
	end
end

local function removeSidekick(state, model)
	if not state then
		return
	end

	for i, owned in ipairs(state.Sidekicks) do
		if owned == model then
			table.remove(state.Sidekicks, i)
			return
		end
	end
end

local function reflowSidekicks(state)
	if not state then
		return
	end

	local plot = openPlots[state.PlotIndex]
	if not plot then
		return
	end

	for slotIndex, owned in ipairs(state.Sidekicks) do
		local targetSlot = plot.Slots:FindFirstChild(tostring(slotIndex))
		if targetSlot and owned and owned.Parent then
			owned:PivotTo(targetSlot.CFrame * CFrame.new(0, 3.2, 0))
		end
	end
	syncCollection(state)
	refreshState(state.Player, state)
end

local function restoreWalkSpeed(player, state)
	if not player or not state then
		return
	end

	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.WalkSpeed = state.CarryOriginalWalkSpeed or 16
	end
	state.CarryOriginalWalkSpeed = nil
end

local secureCarry
local recoverCarry
local dropCarry

local function createStickman(rarity)
	local model = Instance.new("Model")
	model.Name = rarity.Name .. " Stickman"
	model:SetAttribute("Rarity", rarity.Name)
	model:SetAttribute("Cost", rarity.Cost)
	model:SetAttribute("Income", rarity.Income)
	model:SetAttribute("OwnerUserId", 0)
	model:SetAttribute("StealReadyAt", 0)
	model:SetAttribute("CarrierUserId", 0)
	model:SetAttribute("PreviousOwnerUserId", 0)
	model:SetAttribute("TransferState", "Market")
	model:SetAttribute("RarityRank", rarity.Rank or 1)

	local root = Instance.new("Part")
	root.Name = "Root"
	root.Size = Vector3.new(1.2, 2.8, 0.8)
	root.Anchored = true
	root.CanCollide = false
	root.Color = rarity.Color
	root.Material = Enum.Material.SmoothPlastic
	root.Parent = model
	model.PrimaryPart = root

	if rarity.Glow then
		local highlight = Instance.new("Highlight")
		highlight.Name = "RarityGlow"
		highlight.FillColor = rarity.Color
		highlight.FillTransparency = 0.72
		highlight.OutlineColor = rarity.Color
		highlight.OutlineTransparency = 0.1
		highlight.DepthMode = Enum.HighlightDepthMode.Occluded
		highlight.Parent = model
	end

	local head = Instance.new("Part")
	head.Name = "Head"
	head.Shape = Enum.PartType.Ball
	head.Size = Vector3.new(1.5, 1.5, 1.5)
	head.Anchored = true
	head.CanCollide = false
	head.Color = rarity.Color
	head.Parent = model

	local limbSpecs = {
		{"LeftArm", Vector3.new(0.35, 2.2, 0.35)},
		{"RightArm", Vector3.new(0.35, 2.2, 0.35)},
		{"LeftLeg", Vector3.new(0.4, 2.4, 0.4)},
		{"RightLeg", Vector3.new(0.4, 2.4, 0.4)},
	}

	for _, spec in ipairs(limbSpecs) do
		local limb = Instance.new("Part")
		limb.Name = spec[1]
		limb.Size = spec[2]
		limb.Anchored = true
		limb.CanCollide = false
		limb.Color = rarity.Color
		limb.Parent = model
	end

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "Info"
	billboard.Size = UDim2.fromOffset(150, 56)
	billboard.StudsOffset = Vector3.new(0, 3.6, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = root

	local text = Instance.new("TextLabel")
	text.Size = UDim2.fromScale(1, 1)
	text.BackgroundColor3 = Color3.fromRGB(15, 16, 22)
	text.BackgroundTransparency = 0.2
	text.TextColor3 = rarity.Color
	text.TextScaled = true
	text.Font = Enum.Font.GothamBold
	text.Text = string.format("%s\n$%d • +$%d / %ds", rarity.Name, rarity.Cost, rarity.Income, Config.PASSIVE_TICK)
	text.Parent = billboard

	local textCorner = Instance.new("UICorner")
	textCorner.CornerRadius = UDim.new(0, 8)
	textCorner.Parent = text

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "ActionPrompt"
	prompt.ActionText = "Recruit"
	prompt.ObjectText = rarity.Name .. " Stickman"
	prompt.HoldDuration = 0.35
	prompt.MaxActivationDistance = Config.SNATCH_INTERACTION_RANGE
	prompt.RequiresLineOfSight = true
	prompt.Parent = root

	model.Parent = world

	local function moveTo(cframe)
		root.CFrame = cframe
		head.CFrame = cframe * CFrame.new(0, 2.15, 0)

		local leftArm = model:FindFirstChild("LeftArm")
		local rightArm = model:FindFirstChild("RightArm")
		local leftLeg = model:FindFirstChild("LeftLeg")
		local rightLeg = model:FindFirstChild("RightLeg")

		if leftArm then leftArm.CFrame = cframe * CFrame.new(-0.9, 0.1, 0) * CFrame.Angles(0, 0, math.rad(-18)) end
		if rightArm then rightArm.CFrame = cframe * CFrame.new(0.9, 0.1, 0) * CFrame.Angles(0, 0, math.rad(18)) end
		if leftLeg then leftLeg.CFrame = cframe * CFrame.new(-0.4, -2.5, 0) end
		if rightLeg then rightLeg.CFrame = cframe * CFrame.new(0.4, -2.5, 0) end
	end

	prompt.Triggered:Connect(function(player)
		local state = playerState[player]
		if not state then
			return
		end
		if not canInteract(player) then
			toast(player, "Loading your profile — one moment.")
			return
		end

		local canReach, reachMessage = canReachStickman(player, model, Config.SNATCH_INTERACTION_RANGE)
		if not canReach then
			toast(player, reachMessage)
			return
		end

		local carrierUserId = model:GetAttribute("CarrierUserId") or 0
		if carrierUserId ~= 0 then
			local carrier = Players:GetPlayerByUserId(carrierUserId)
			local carrierState = carrier and playerState[carrier]

			if carrier == player then
				toast(player, "Run to your green SECURE pad!")
			elseif carrierState and carrierState.Carrying and carrierState.Carrying.Model == model and carrierState.Carrying.Victim == player then
				recoverCarry(player, carrier)
			else
				toast(player, "That stickman is already being carried.")
			end
			return
		end

		local ownerUserId = model:GetAttribute("OwnerUserId") or 0
		if ownerUserId == 0 then
			if #state.Sidekicks >= getCapacity(player) then
				toast(player, "Your base is full.")
				return
			end

			if state.Coins.Value < rarity.Cost then
				toast(player, string.format("You need $%d more.", rarity.Cost - state.Coins.Value))
				return
			end

			state.Coins.Value -= rarity.Cost
			table.insert(state.Sidekicks, model)
			state.Profile.TotalRecruits.Value += 1
			state.Profile.SessionRecruits.Value += 1
			model:SetAttribute("OwnerUserId", player.UserId)
			model:SetAttribute("StealReadyAt", os.clock() + Config.STEAL_COOLDOWN)
			model:SetAttribute("TransferState", "Owned")
			prompt.ActionText = "Snatch"
			prompt.ObjectText = rarity.Name .. " Stickman"
			reflowSidekicks(state)
			toast(player, rarity.Name .. " stickman recruited!")
			return
		end

		if ownerUserId == player.UserId then
			toast(player, "This stickman already works for you.")
			return
		end

		if state.Carrying then
			toast(player, "Secure the stickman you are already carrying first.")
			return
		end

		if #state.Sidekicks >= getCapacity(player) then
			toast(player, "Your base is full.")
			return
		end

		local victim = Players:GetPlayerByUserId(ownerUserId)
		local victimState = victim and playerState[victim]
		if not victimState then
			toast(player, "That owner is no longer available.")
			return
		end

		if os.clock() < (victimState.JoinProtectedUntil or 0) then
			toast(player, "That base is still under join protection.")
			return
		end

		if os.clock() < victimState.ShieldUntil then
			toast(player, "That base is shielded.")
			return
		end

		local stealReadyAt = model:GetAttribute("StealReadyAt") or 0
		if os.clock() < stealReadyAt then
			toast(player, "That stickman is still protected.")
			return
		end

		removeSidekick(victimState, model)
		reflowSidekicks(victimState)

		local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		state.CarryOriginalWalkSpeed = humanoid and humanoid.WalkSpeed or 16
		if humanoid then
			humanoid.WalkSpeed = Config.CARRY_WALK_SPEED
		end

		local carryStartedAt = os.clock()
		state.Carrying = {
			Model = model,
			Victim = victim,
			VictimState = victimState,
			StartedAt = carryStartedAt,
			ExpiresAt = carryStartedAt + Config.CARRY_TIMEOUT_SECONDS,
			Contested = false,
		}

		model:SetAttribute("CarrierUserId", player.UserId)
		model:SetAttribute("PreviousOwnerUserId", ownerUserId)
		model:SetAttribute("TransferState", "InTransit")
		model:SetAttribute("Contested", false)
		prompt.ActionText = "Recover"
		prompt.ObjectText = rarity.Name .. " • HOOKED"
		prompt.HoldDuration = Config.RECOVER_HOLD_DURATION
		prompt.MaxActivationDistance = Config.RECOVER_INTERACTION_RANGE
		startCarryPresentation(player, state, model, rarity, victim)

		toast(victim, player.DisplayName .. " hooked your " .. rarity.Name .. " stickman — catch them!")
		toast(player, "STOLEN! Escape to your green SECURE pad.")
		carryState(player, true, "ESCAPE! Reach your green SECURE pad before the owner recovers it.")
	end)

	return model, moveTo
end

recoverCarry = function(victim, carrier)
	local carrierState = carrier and playerState[carrier]
	if not carrierState or not carrierState.Carrying then
		return
	end

	local carry = carrierState.Carrying
	if carry.Victim ~= victim then
		return
	end

	local model = carry.Model
	local victimState = playerState[victim]
	if not model or not model.Parent or not victimState then
		dropCarry(carrier, "The carry was cancelled.")
		return
	end

	local canRecover, recoverMessage = canReachStickman(victim, model, Config.RECOVER_INTERACTION_RANGE, carrier.Character)
	if not canRecover then
		toast(victim, recoverMessage)
		return
	end

	clearCarryPresentation(carrier, carrierState, carry)
	carrierState.Carrying = nil
	if carrierState.Profile then
		carrierState.Profile.CurrentStreak.Value = 0
	end
	restoreWalkSpeed(carrier, carrierState)
	refreshState(carrier, carrierState)
	carryState(carrier, false)

	model:SetAttribute("CarrierUserId", 0)
	model:SetAttribute("PreviousOwnerUserId", 0)
	model:SetAttribute("OwnerUserId", victim.UserId)
	model:SetAttribute("StealReadyAt", os.clock() + Config.STEAL_COOLDOWN)
	model:SetAttribute("TransferState", "Owned")
	model:SetAttribute("Contested", false)

	local prompt = model.PrimaryPart and model.PrimaryPart:FindFirstChild("ActionPrompt")
	if prompt then
		prompt.ActionText = "Snatch"
		prompt.ObjectText = (model:GetAttribute("Rarity") or "Stickman") .. " Stickman"
		prompt.HoldDuration = 0.35
		prompt.MaxActivationDistance = Config.SNATCH_INTERACTION_RANGE
	end

	table.insert(victimState.Sidekicks, model)
	reflowSidekicks(victimState)

	toast(victim, "HOOK BROKEN! Your stickman is back.")
	toast(carrier, victim.DisplayName .. " broke your snatch hook.")
end

secureCarry = function(player)
	local state = playerState[player]
	if not state or not state.Carrying then
		return
	end

	local carry = state.Carrying
	local model = carry.Model
	if not model or not model.Parent then
		clearCarryPresentation(player, state, carry)
		state.Carrying = nil
		restoreWalkSpeed(player, state)
		carryState(player, false)
		return
	end

	clearCarryPresentation(player, state, carry)
	state.Carrying = nil
	restoreWalkSpeed(player, state)
	carryState(player, false)

	model:SetAttribute("CarrierUserId", 0)
	model:SetAttribute("PreviousOwnerUserId", 0)
	model:SetAttribute("OwnerUserId", player.UserId)
	model:SetAttribute("StealReadyAt", os.clock() + Config.STEAL_COOLDOWN)
	model:SetAttribute("TransferState", "Owned")
	model:SetAttribute("Contested", false)

	local prompt = model.PrimaryPart and model.PrimaryPart:FindFirstChild("ActionPrompt")
	if prompt then
		prompt.ActionText = "Snatch"
		prompt.ObjectText = (model:GetAttribute("Rarity") or "Stickman") .. " Stickman"
		prompt.HoldDuration = 0.35
		prompt.MaxActivationDistance = Config.SNATCH_INTERACTION_RANGE
	end

	table.insert(state.Sidekicks, model)
	reflowSidekicks(state)

	state.Profile.CurrentStreak.Value += 1
	state.Profile.TotalSnatches.Value += 1
	state.Profile.SessionSnatches.Value += 1
	if state.Profile.CurrentStreak.Value > state.Profile.BestStreak.Value then
		state.Profile.BestStreak.Value = state.Profile.CurrentStreak.Value
	end

	local streakBonus = math.min(Config.STREAK_BONUS_CAP, math.max(0, state.Profile.CurrentStreak.Value - 1) * Config.STREAK_BONUS_STEP)
	local bonus = math.max(5, math.floor((model:GetAttribute("Income") or 1) * Config.SECURE_BONUS_MULTIPLIER * (1 + streakBonus)))
	awardCoins(state, bonus)
	refreshState(player, state)

	if carry.Victim then
		toast(carry.Victim, player.DisplayName .. " escaped with your stickman.")
	end
	toast(player, string.format("SECURED! +$%d • %dx snatch streak", bonus, state.Profile.CurrentStreak.Value))
end

dropCarry = function(player, message)
	local state = playerState[player]
	if not state or not state.Carrying then
		return
	end

	local carry = state.Carrying
	local model = carry.Model
	clearCarryPresentation(player, state, carry)
	state.Carrying = nil
	if state.Profile then
		state.Profile.CurrentStreak.Value = 0
	end
	restoreWalkSpeed(player, state)
	carryState(player, false)
	refreshState(player, state)

	if not model or not model.Parent then
		return
	end

	model:SetAttribute("CarrierUserId", 0)
	model:SetAttribute("PreviousOwnerUserId", 0)

	local prompt = model.PrimaryPart and model.PrimaryPart:FindFirstChild("ActionPrompt")
	local victim = carry.Victim
	local victimState = victim and playerState[victim]

	if victim and victimState and victim.Parent == Players then
		model:SetAttribute("OwnerUserId", victim.UserId)
		model:SetAttribute("StealReadyAt", os.clock() + Config.STEAL_COOLDOWN)
		model:SetAttribute("TransferState", "Owned")
		if prompt then
			prompt.ActionText = "Snatch"
			prompt.ObjectText = (model:GetAttribute("Rarity") or "Stickman") .. " Stickman"
			prompt.HoldDuration = 0.35
			prompt.MaxActivationDistance = Config.SNATCH_INTERACTION_RANGE
		end
		table.insert(victimState.Sidekicks, model)
		reflowSidekicks(victimState)
		toast(victim, "Your stickman returned after the escape failed.")
	else
		model:SetAttribute("OwnerUserId", 0)
		model:SetAttribute("StealReadyAt", 0)
		model:SetAttribute("TransferState", "Market")
		model:SetAttribute("Contested", false)
		if prompt then
			prompt.ActionText = "Recruit"
			prompt.ObjectText = (model:GetAttribute("Rarity") or "Stickman") .. " Stickman"
			prompt.HoldDuration = 0.35
			prompt.MaxActivationDistance = Config.SNATCH_INTERACTION_RANGE
		end
		model:PivotTo(CFrame.new(rng:NextNumber(-12, 12), 3.2, rng:NextNumber(-30, 30)))
	end

	if message then
		toast(player, message)
	end
end

local marketSpawnCounter = 0
local epicPlusDrought = 0

local function marketStockCount()
	local count = 0
	for _, child in ipairs(world:GetChildren()) do
		if child:IsA("Model")
			and child.PrimaryPart
			and child:GetAttribute("Rarity") ~= nil
			and (child:GetAttribute("OwnerUserId") or 0) == 0
			and (child:GetAttribute("CarrierUserId") or 0) == 0
		then
			count += 1
		end
	end
	return count
end

local function spawnMarketStickman(forceCommon)
	if marketStockCount() >= Config.MARKET_MAX_STOCK then
		return
	end

	local rarity
	if forceCommon then
		rarity = Config.RARITIES[1]
	elseif epicPlusDrought >= 12 then
		rarity = Config.RARITIES[3]
	else
		rarity = weightedRarity()
	end

	if not forceCommon then
		if (rarity.Rank or 1) >= 3 then
			epicPlusDrought = 0
		else
			epicPlusDrought += 1
		end
	end

	local model, moveTo = createStickman(rarity)

	if rarity.Name == "Legendary" or rarity.Name == "Glitched" then
		broadcastToast(string.format("A %s stickman just appeared in the market!", string.upper(rarity.Name)))
	end

	local x = rng:NextNumber(-12, 12)
	local z = rng:NextNumber(-30, 30)
	moveTo(CFrame.new(x, 3.2, z) * CFrame.Angles(0, math.rad(rng:NextInteger(0, 359)), 0))

	task.delay(Config.MARKET_LIFETIME, function()
		if model.Parent
			and (model:GetAttribute("OwnerUserId") or 0) == 0
			and (model:GetAttribute("CarrierUserId") or 0) == 0
		then
			model:Destroy()
		end
	end)
end

local function assignPlot(player)
	for index, plot in ipairs(openPlots) do
		if not plot.Owner then
			plot.Owner = player
			plot.Label.Text = player.DisplayName .. "'s Base"
			return index
		end
	end
	return nil
end

local function releasePlot(player)
	local state = playerState[player]
	if not state then
		return
	end

	if state.Carrying then
		dropCarry(player)
	end

	for otherPlayer, otherState in pairs(playerState) do
		if otherPlayer ~= player and otherState.Carrying and otherState.Carrying.Victim == player then
			otherState.Carrying.Victim = nil
			otherState.Carrying.VictimState = nil
			if otherState.Carrying.Model and otherState.Carrying.Model.Parent then
				otherState.Carrying.Model:SetAttribute("OwnerUserId", 0)
			end
		end
	end

	local plot = state.PlotIndex and openPlots[state.PlotIndex]
	if plot then
		plot.Owner = nil
		plot.Label.Text = "OPEN BASE"
		plot.ShieldVisual.Transparency = 1
		plot.Model:SetAttribute("OwnerUserId", 0)
		plot.Model:SetAttribute("OwnerDisplayName", "")
		plot.Model:SetAttribute("ShieldUntilServerTime", 0)
		plot.Model:SetAttribute("ShieldReadyServerTime", 0)
		plot.Model:SetAttribute("JoinProtectionUntilServerTime", 0)
	end
	player:SetAttribute("PlotIndex", nil)

	for _, model in ipairs(state.Sidekicks) do
		if model and model.Parent then
			model:Destroy()
		end
	end
end

local function findRarity(name)
	for _, rarity in ipairs(Config.RARITIES) do
		if rarity.Name == name then
			return rarity
		end
	end
	return nil
end

local function restoreSavedCollection(player, state)
	if not state or not state.Profile then
		return
	end

	local raw = state.Profile.CollectionData.Value
	local ok, decoded = pcall(HttpService.JSONDecode, HttpService, raw)
	if not ok or type(decoded) ~= "table" then
		state.Profile.CollectionData.Value = "[]"
		return
	end

	state.Restoring = true
	local limit = getCapacity(player)
	for _, rarityName in ipairs(decoded) do
		if #state.Sidekicks >= limit then
			break
		end
		local rarity = findRarity(tostring(rarityName))
		if rarity then
			local model = createStickman(rarity)
			model:SetAttribute("OwnerUserId", player.UserId)
			model:SetAttribute("StealReadyAt", os.clock() + Config.REJOIN_STEAL_PROTECTION)
			model:SetAttribute("TransferState", "Owned")
			local prompt = model.PrimaryPart and model.PrimaryPart:FindFirstChild("ActionPrompt")
			if prompt then
				prompt.ActionText = "Snatch"
				prompt.ObjectText = rarity.Name .. " Stickman"
				prompt.MaxActivationDistance = Config.SNATCH_INTERACTION_RANGE
			end
			table.insert(state.Sidekicks, model)
		end
	end
	state.Restoring = false
	reflowSidekicks(state)
end

Players.PlayerAdded:Connect(function(player)
	player:SetAttribute("DataReady", false)
	local plotIndex = assignPlot(player)
	if not plotIndex then
		player:Kick("This prototype currently supports 6 players per server.")
		return
	end

	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats or not leaderstats:IsA("Folder") then
		if leaderstats then leaderstats:Destroy() end
		leaderstats = Instance.new("Folder")
		leaderstats.Name = "leaderstats"
		leaderstats.Parent = player
	end

	local coins = leaderstats:FindFirstChild("Coins")
	if not coins or not coins:IsA("IntValue") then
		if coins then coins:Destroy() end
		coins = Instance.new("IntValue")
		coins.Name = "Coins"
		coins.Value = Config.STARTING_COINS
		coins.Parent = leaderstats
	end

	local profile = player:FindFirstChild("Profile")
	if not profile or not profile:IsA("Folder") then
		if profile then profile:Destroy() end
		profile = Instance.new("Folder")
		profile.Name = "Profile"
		profile.Parent = player
	end

	local function intValue(name, value)
		local item = profile:FindFirstChild(name)
		if item and item:IsA("IntValue") then
			return item
		end
		if item then item:Destroy() end
		item = Instance.new("IntValue")
		item.Name = name
		item.Value = value or 0
		item.Parent = profile
		return item
	end

	local collectionData = profile:FindFirstChild("CollectionData")
	if not collectionData or not collectionData:IsA("StringValue") then
		if collectionData then collectionData:Destroy() end
		collectionData = Instance.new("StringValue")
		collectionData.Name = "CollectionData"
		collectionData.Value = "[]"
		collectionData.Parent = profile
	end

	intValue("IncomeLevel", 0)
	intValue("CapacityLevel", 0)
	intValue("ShieldLevel", 0)
	intValue("TotalSnatches", 0)
	intValue("BestStreak", 0)
	intValue("TotalRecruits", 0)
	intValue("LifetimeCoinsEarned", 0)
	intValue("MasteryXP", 0)
	intValue("MasteryLevel", 0)
	intValue("CurrentStreak", 0)
	intValue("SessionEarned", 0)
	intValue("SessionRecruits", 0)
	intValue("SessionSnatches", 0)

	local state = {
		Player = player,
		Coins = coins,
		Profile = profile,
		PlotIndex = plotIndex,
		Sidekicks = {},
		ShieldUntil = 0,
		ShieldReadyAt = 0,
		JoinProtectedUntil = os.clock() + Config.JOIN_PROTECTION_SECONDS,
		Carrying = nil,
		CarryOriginalWalkSpeed = nil,
		CarryVisuals = nil,
		Restoring = false,
	}
	playerState[player] = state
	player:SetAttribute("PlotIndex", plotIndex)
	refreshState(player, state)

	for _, valueName in ipairs({"IncomeLevel", "CapacityLevel", "ShieldLevel", "CurrentStreak"}) do
		profile[valueName].Changed:Connect(function()
			if playerState[player] == state then
				refreshState(player, state)
			end
		end)
	end

	local plot = openPlots[plotIndex]
	if plot then
		plot.ShieldVisual.Transparency = 0.84
	end
	task.delay(Config.JOIN_PROTECTION_SECONDS, function()
		if playerState[player] == state and os.clock() >= state.JoinProtectedUntil then
			local ownedPlot = openPlots[state.PlotIndex]
			if ownedPlot and state.ShieldUntil <= os.clock() then
				ownedPlot.ShieldVisual.Transparency = 1
			end
			refreshState(player, state)
		end
	end)

	player.CharacterAdded:Connect(function(character)
		task.wait(0.2)
		local root = character:FindFirstChild("HumanoidRootPart")
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		local plot = openPlots[plotIndex]
		if root and plot then
			root.CFrame = CFrame.new(plot.Position + Vector3.new(0, 5, -6))
		end
		if humanoid then
			humanoid.Died:Connect(function()
				if playerState[player] and playerState[player].Carrying then
					dropCarry(player, "Escape failed — the stickman returned.")
				end
			end)
		end
	end)

	task.spawn(function()
		while player.Parent == Players and player:GetAttribute("DataReady") ~= true do
			task.wait(0.1)
		end
		if player.Parent ~= Players or playerState[player] ~= state then
			return
		end
		restoreSavedCollection(player, state)
		refreshState(player, state)
		toast(player, "Recruit, upgrade, snatch rivals, and escape to your green SECURE pad!")
	end)
end)

Players.PlayerRemoving:Connect(function(player)
	releasePlot(player)
	playerState[player] = nil
end)

local carryUpdateAccumulator = 0
RunService.Heartbeat:Connect(function(dt)
	carryUpdateAccumulator += dt
	if carryUpdateAccumulator < Config.CARRY_SERVER_UPDATE_RATE then return end
	carryUpdateAccumulator = 0
	for player, state in pairs(playerState) do
		local carry = state.Carrying
		if carry then
			local character = player.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			local model = carry.Model
			if not root or not humanoid or humanoid.Health <= 0 or not model or not model.Parent then
				dropCarry(player, "Escape failed - the stickman returned.")
			elseif carry.ExpiresAt and os.clock() >= carry.ExpiresAt then
				dropCarry(player, "HOOK EXPIRED - the stickman returned.")
			else
				local victimCharacter = carry.Victim and carry.Victim.Character
				local victimRoot = victimCharacter and victimCharacter:FindFirstChild("HumanoidRootPart")
				local contested = victimRoot ~= nil and (victimRoot.Position - root.Position).Magnitude <= Config.CONTESTED_RANGE
				if carry.Contested ~= contested then
					carry.Contested = contested
					model:SetAttribute("Contested", contested)
					player:SetAttribute("CarryContested", contested)
					if contested then toast(player, "CONTESTED! The owner is close - break away!") end
				end
				humanoid.WalkSpeed = contested and Config.CONTESTED_CARRY_WALK_SPEED or Config.CARRY_WALK_SPEED
				model:PivotTo(root.CFrame * CFrame.new(0, 3.1, 2.5) * CFrame.Angles(0, math.rad(180), 0))
				local plot = openPlots[state.PlotIndex]
				local securePad = plot and plot.SecurePad
				if securePad and (root.Position - securePad.Position).Magnitude <= Config.SECURE_RADIUS then secureCarry(player) end
			end
		end
	end
end)

task.spawn(function()
	while true do
		task.wait(Config.PASSIVE_TICK)
		for player, state in pairs(playerState) do
			if player.Parent == Players then
				refreshState(player, state)
				local effectiveIncome = math.max(0, math.floor(tonumber(player:GetAttribute("IncomePerTick")) or 0))
				if effectiveIncome > 0 then
					awardCoins(state, effectiveIncome)
				end
			end
		end
	end
end)

task.spawn(function()
	while true do
		marketSpawnCounter += 1
		local forceCommon = marketSpawnCounter % Config.AFFORDABLE_SPAWN_EVERY == 0
		spawnMarketStickman(forceCommon)
		task.wait(Config.SPAWN_INTERVAL)
	end
end)

for i = 1, Config.INITIAL_MARKET_STOCK do
	spawnMarketStickman(i <= 3)
end