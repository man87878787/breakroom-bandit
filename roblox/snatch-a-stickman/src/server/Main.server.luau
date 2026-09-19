local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

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

local world = workspace:FindFirstChild("SnatchAStickmanWorld")
if world then
	world:Destroy()
end

world = Instance.new("Folder")
world.Name = "SnatchAStickmanWorld"
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

local function makePlot(index, position)
	local model = Instance.new("Model")
	model.Name = "Plot" .. index
	model.Parent = world

	local floor = Instance.new("Part")
	floor.Name = "Floor"
	floor.Size = Vector3.new(42, 1, 28)
	floor.CFrame = CFrame.new(position)
	floor.Anchored = true
	floor.Color = Color3.fromRGB(42, 46, 58)
	floor.Material = Enum.Material.SmoothPlastic
	floor.Parent = model

	local sign = Instance.new("Part")
	sign.Name = "Sign"
	sign.Size = Vector3.new(14, 5, 1)
	sign.CFrame = CFrame.new(position + Vector3.new(0, 3, 13))
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
	shield.Size = Vector3.new(44, 10, 30)
	shield.CFrame = CFrame.new(position + Vector3.new(0, 5, 0))
	shield.Anchored = true
	shield.CanCollide = false
	shield.Transparency = 1
	shield.Material = Enum.Material.ForceField
	shield.Color = Color3.fromRGB(105, 100, 255)
	shield.Parent = model

	local button = Instance.new("Part")
	button.Name = "ShieldButton"
	button.Size = Vector3.new(4, 1, 4)
	button.CFrame = CFrame.new(position + Vector3.new(0, 1, -11))
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

	local slots = Instance.new("Folder")
	slots.Name = "Slots"
	slots.Parent = model

	for slotIndex = 1, Config.MAX_SIDEKICKS do
		local row = math.floor((slotIndex - 1) / 4)
		local column = (slotIndex - 1) % 4
		local x = -12 + (column * 8)
		local z = -3 + (row * 8)

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
		Slots = slots,
	}

	prompt.Triggered:Connect(function(player)
		local state = playerState[player]
		if not state or state.PlotIndex ~= index then
			toast(player, "That shield belongs to another base.")
			return
		end

		local now = os.clock()
		if now < state.ShieldReadyAt then
			toast(player, string.format("Shield recharging: %ds", math.ceil(state.ShieldReadyAt - now)))
			return
		end

		state.ShieldUntil = now + Config.SHIELD_SECONDS
		state.ShieldReadyAt = now + Config.SHIELD_COOLDOWN
		shield.Transparency = 0.72
		toast(player, "Base shield active!")

		task.delay(Config.SHIELD_SECONDS, function()
			if state and state.ShieldUntil <= os.clock() then
				shield.Transparency = 1
			end
		end)
	end)
end

for index, position in ipairs(plotPositions) do
	makePlot(index, position)
end

local function weightedRarity()
	local total = 0
	for _, rarity in ipairs(Config.RARITIES) do
		total += rarity.Weight
	end

	local roll = rng:NextNumber(0, total)
	local running = 0
	for _, rarity in ipairs(Config.RARITIES) do
		running += rarity.Weight
		if roll <= running then
			return rarity
		end
	end

	return Config.RARITIES[1]
end

local function createStickman(rarity)
	local model = Instance.new("Model")
	model.Name = rarity.Name .. " Stickman"
	model:SetAttribute("Rarity", rarity.Name)
	model:SetAttribute("Cost", rarity.Cost)
	model:SetAttribute("Income", rarity.Income)
	model:SetAttribute("OwnerUserId", 0)
	model:SetAttribute("StealReadyAt", 0)

	local root = Instance.new("Part")
	root.Name = "Root"
	root.Size = Vector3.new(1.2, 2.8, 0.8)
	root.Anchored = true
	root.CanCollide = false
	root.Color = rarity.Color
	root.Material = Enum.Material.SmoothPlastic
	root.Parent = model
	model.PrimaryPart = root

	local head = Instance.new("Part")
	head.Name = "Head"
	head.Shape = Enum.PartType.Ball
	head.Size = Vector3.new(1.5, 1.5, 1.5)
	head.Anchored = true
	head.CanCollide = false
	head.Color = rarity.Color
	head.Parent = model

	local limbSpecs = {
		{"LeftArm", Vector3.new(0.35, 2.2, 0.35), Vector3.new(-0.9, 0.1, 0)},
		{"RightArm", Vector3.new(0.35, 2.2, 0.35), Vector3.new(0.9, 0.1, 0)},
		{"LeftLeg", Vector3.new(0.4, 2.4, 0.4), Vector3.new(-0.4, -2.5, 0)},
		{"RightLeg", Vector3.new(0.4, 2.4, 0.4), Vector3.new(0.4, -2.5, 0)},
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
	text.Text = string.format("%s\n$%d • +$%d/tick", rarity.Name, rarity.Cost, rarity.Income)
	text.Parent = billboard

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "ActionPrompt"
	prompt.ActionText = "Recruit"
	prompt.ObjectText = rarity.Name .. " Stickman"
	prompt.HoldDuration = 0.35
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.Parent = root

	model.Parent = world

	local function arrangeParts(cframe)
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

	model:SetAttribute("ArrangeVersion", 1)

	local function moveTo(cframe)
		arrangeParts(cframe)
	end

	prompt.Triggered:Connect(function(player)
		local state = playerState[player]
		if not state then
			return
		end

		local ownerUserId = model:GetAttribute("OwnerUserId") or 0
		if ownerUserId == 0 then
			if #state.Sidekicks >= Config.MAX_SIDEKICKS then
				toast(player, "Your base is full.")
				return
			end

			if state.Coins.Value < rarity.Cost then
				toast(player, string.format("You need $%d more.", rarity.Cost - state.Coins.Value))
				return
			end

			state.Coins.Value -= rarity.Cost
			table.insert(state.Sidekicks, model)
			model:SetAttribute("OwnerUserId", player.UserId)
			model:SetAttribute("StealReadyAt", os.clock() + Config.STEAL_COOLDOWN)
			prompt.ActionText = "Snatch"

			local plot = openPlots[state.PlotIndex]
			local slot = plot.Slots:FindFirstChild(tostring(#state.Sidekicks))
			if slot then
				moveTo(slot.CFrame * CFrame.new(0, 3.2, 0))
			end

			toast(player, rarity.Name .. " stickman recruited!")
			return
		end

		if ownerUserId == player.UserId then
			toast(player, "This stickman already works for you.")
			return
		end

		local victim = Players:GetPlayerByUserId(ownerUserId)
		local victimState = victim and playerState[victim]
		if victimState and os.clock() < victimState.ShieldUntil then
			toast(player, "That base is shielded.")
			return
		end

		local stealReadyAt = model:GetAttribute("StealReadyAt") or 0
		if os.clock() < stealReadyAt then
			toast(player, "That stickman is still protected.")
			return
		end

		if #state.Sidekicks >= Config.MAX_SIDEKICKS then
			toast(player, "Your base is full.")
			return
		end

		if victimState then
			for i, owned in ipairs(victimState.Sidekicks) do
				if owned == model then
					table.remove(victimState.Sidekicks, i)
					break
				end
			end

			-- Compact the victim's display so future recruits never overlap an old slot.
			local victimPlot = openPlots[victimState.PlotIndex]
			if victimPlot then
				for slotIndex, owned in ipairs(victimState.Sidekicks) do
					local targetSlot = victimPlot.Slots:FindFirstChild(tostring(slotIndex))
					if targetSlot and owned and owned.Parent then
						owned:PivotTo(targetSlot.CFrame * CFrame.new(0, 3.2, 0))
					end
				end
			end
		end

		table.insert(state.Sidekicks, model)
		model:SetAttribute("OwnerUserId", player.UserId)
		model:SetAttribute("StealReadyAt", os.clock() + Config.STEAL_COOLDOWN)

		local plot = openPlots[state.PlotIndex]
		local slot = plot.Slots:FindFirstChild(tostring(#state.Sidekicks))
		if slot then
			moveTo(slot.CFrame * CFrame.new(0, 3.2, 0))
		end

		if victim then
			toast(victim, player.DisplayName .. " snatched one of your stickmen!")
		end
		toast(player, "Snatched! Get it behind your shield.")
	end)

	return model, moveTo
end

local function spawnMarketStickman()
	local rarity = weightedRarity()
	local model, moveTo = createStickman(rarity)

	local x = rng:NextNumber(-12, 12)
	local z = rng:NextNumber(-30, 30)
	moveTo(CFrame.new(x, 3.2, z) * CFrame.Angles(0, math.rad(rng:NextInteger(0, 359)), 0))

	task.delay(Config.MARKET_LIFETIME, function()
		if model.Parent and (model:GetAttribute("OwnerUserId") or 0) == 0 then
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

	local plot = state.PlotIndex and openPlots[state.PlotIndex]
	if plot then
		plot.Owner = nil
		plot.Label.Text = "OPEN BASE"
		plot.ShieldVisual.Transparency = 1
	end

	for _, model in ipairs(state.Sidekicks) do
		if model and model.Parent then
			model:Destroy()
		end
	end
end

Players.PlayerAdded:Connect(function(player)
	local plotIndex = assignPlot(player)
	if not plotIndex then
		player:Kick("This prototype currently supports 6 players per server.")
		return
	end

	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	local coins = Instance.new("IntValue")
	coins.Name = "Coins"
	coins.Value = Config.STARTING_COINS
	coins.Parent = leaderstats

	playerState[player] = {
		Coins = coins,
		PlotIndex = plotIndex,
		Sidekicks = {},
		ShieldUntil = 0,
		ShieldReadyAt = 0,
	}

	player.CharacterAdded:Connect(function(character)
		task.wait(0.2)
		local root = character:FindFirstChild("HumanoidRootPart")
		local plot = openPlots[plotIndex]
		if root and plot then
			root.CFrame = CFrame.new(plot.Position + Vector3.new(0, 5, -6))
		end
	end)

	task.delay(1, function()
		toast(player, "Recruit stickmen, earn coins, and snatch rivals when their shield is down!")
	end)
end)

Players.PlayerRemoving:Connect(function(player)
	releasePlot(player)
	playerState[player] = nil
end)

task.spawn(function()
	while true do
		task.wait(Config.PASSIVE_TICK)
		for player, state in pairs(playerState) do
			if player.Parent == Players then
				local income = 0
				for _, model in ipairs(state.Sidekicks) do
					if model and model.Parent then
						income += model:GetAttribute("Income") or 0
					end
				end
				if income > 0 then
					state.Coins.Value += income
				end
			end
		end
	end
end)

task.spawn(function()
	while true do
		spawnMarketStickman()
		task.wait(Config.SPAWN_INTERVAL)
	end
end)

for i = 1, 8 do
	spawnMarketStickman()
end
