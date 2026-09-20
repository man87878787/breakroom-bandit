local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local TowerService = {}
local plots = {}
local playerPlots = {}
local interactionHandlers = {}
local hazardDebounce = {}
local portalDebounce = {}

local PALETTE = {
	Color3.fromRGB(100, 92, 255),
	Color3.fromRGB(41, 196, 255),
	Color3.fromRGB(255, 92, 143),
	Color3.fromRGB(255, 178, 66),
	Color3.fromRGB(81, 222, 142),
	Color3.fromRGB(190, 98, 255),
}

local RIVAL_NAMES = {
	"VOLT",
	"CRIMSON",
	"EMBER",
	"NEON",
	"PHANTOM",
	"NOVA",
}

local function newPart(parent, name, size, cframe, color, material, canCollide)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = cframe
	part.Anchored = true
	part.CanCollide = canCollide ~= false
	part.CanTouch = true
	part.CanQuery = true
	part.Material = material or Enum.Material.SmoothPlastic
	part.Color = color
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent
	return part
end

local function plotPosition(index)
	local angle = ((index - 1) / Config.TOWERS.PlotCount) * math.pi * 2
	return Vector3.new(
		math.cos(angle) * Config.TOWERS.PlotRadius,
		0,
		math.sin(angle) * Config.TOWERS.PlotRadius
	)
end

local function connectHazard(part)
	part:SetAttribute("Hazard", true)
	part.Touched:Connect(function(hit)
		local character = hit and hit.Parent
		if not character then
			return
		end

		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if not humanoid or humanoid.Health <= 0 or hazardDebounce[humanoid] then
			return
		end

		local player = Players:GetPlayerFromCharacter(character)
		local immuneUntil = player and tonumber(player:GetAttribute("HazardImmuneUntil")) or 0
		if immuneUntil > workspace:GetServerTimeNow() then
			return
		end

		hazardDebounce[humanoid] = true
		humanoid.Health = 0
		task.delay(1, function()
			hazardDebounce[humanoid] = nil
		end)
	end)
end

local function addPrompt(parent, name, actionText, objectText, actionKey, plot, holdDuration)
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = name
	prompt.ActionText = actionText
	prompt.ObjectText = objectText
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.GamepadKeyCode = Enum.KeyCode.ButtonX
	prompt.HoldDuration = holdDuration or 0.25
	prompt.MaxActivationDistance = Config.STEAL.InteractDistance
	prompt.RequiresLineOfSight = false
	prompt.ClickablePrompt = true
	prompt.Parent = parent

	prompt.Triggered:Connect(function(player)
		local handler = interactionHandlers[actionKey]
		if handler then
			handler(player, plot)
		end
	end)

	return prompt
end

local function updatePlotIdentity(plot)
	local ownerName = tostring(plot:GetAttribute("OwnerName") or "")
	local ownerUserId = tonumber(plot:GetAttribute("OwnerUserId")) or 0
	local isNPC = plot:GetAttribute("IsNPC") == true
	local level = tonumber(plot:GetAttribute("TowerLevel")) or 1

	local label = plot:FindFirstChild("OwnerLabel", true)
	if label and label:IsA("TextLabel") then
		if isNPC then
			label.Text = string.format("RIVAL %s\nTOWER LV.%d", ownerName, level)
		elseif ownerUserId == 0 then
			label.Text = "OPEN TOWER"
		else
			label.Text = string.format("%s\nTOWER LV.%d", ownerName, level)
		end
	end

	local structure = plot:FindFirstChild("Structure")
	local core = structure and structure:FindFirstChild("StealCore")
	local stealPrompt = core and core:FindFirstChild("StealPrompt")
	if stealPrompt and stealPrompt:IsA("ProximityPrompt") then
		stealPrompt.Enabled = ownerUserId ~= 0 or isNPC
		if isNPC then
			stealPrompt.ObjectText = "Rival " .. ownerName .. " Core"
		elseif ownerUserId ~= 0 then
			stealPrompt.ObjectText = ownerName .. "'s Core"
		else
			stealPrompt.ObjectText = "Unclaimed Core"
		end
	end
end

local function createOwnerBillboard(plot)
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "OwnerBillboard"
	billboard.Size = UDim2.fromOffset(210, 64)
	billboard.StudsOffsetWorldSpace = Vector3.new(0, 7, 0)
	billboard.AlwaysOnTop = true
	billboard.MaxDistance = 180
	billboard.Parent = plot.PrimaryPart

	local label = Instance.new("TextLabel")
	label.Name = "OwnerLabel"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundColor3 = Color3.fromRGB(15, 18, 28)
	label.BackgroundTransparency = 0.15
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0.7
	label.Font = Enum.Font.GothamBlack
	label.TextScaled = true
	label.TextWrapped = true
	label.Parent = billboard

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = label
end

local function createTowerGeometry(plot, level)
	local structure = plot:FindFirstChild("Structure")
	if structure then
		structure:Destroy()
	end

	structure = Instance.new("Folder")
	structure.Name = "Structure"
	structure.Parent = plot

	local plotIndex = tonumber(plot:GetAttribute("PlotIndex")) or 1
	local accent = PALETTE[((plotIndex - 1) % #PALETTE) + 1]
	local basePos = plot.PrimaryPart.Position
	local baseTop = basePos.Y + (plot.PrimaryPart.Size.Y * 0.5)

	local floors = math.clamp(
		Config.TOWERS.BaseFloorCount + (level - 1) * Config.TOWERS.FloorsPerUpgrade,
		Config.TOWERS.BaseFloorCount,
		Config.TOWERS.MaxFloors
	)

	for floorIndex = 1, floors do
		local floorY = baseTop + floorIndex * Config.TOWERS.FloorHeight
		local platformColor = floorIndex % 2 == 0
			and Color3.fromRGB(47, 53, 70)
			or Color3.fromRGB(57, 63, 82)

		newPart(
			structure,
			("Floor_%02d"):format(floorIndex),
			Vector3.new(28, 1, 28),
			CFrame.new(basePos.X, floorY, basePos.Z),
			platformColor,
			Enum.Material.Metal
		)

		local previousY = baseTop + (floorIndex - 1) * Config.TOWERS.FloorHeight
		local sideZ = floorIndex % 2 == 0 and -11.5 or 11.5
		for stepIndex = 1, Config.TOWERS.StepsPerFloor do
			local alpha = stepIndex / (Config.TOWERS.StepsPerFloor + 1)
			local x = -9 + alpha * 18
			if floorIndex % 2 == 0 then
				x = -x
			end

			newPart(
				structure,
				("Step_%02d_%02d"):format(floorIndex, stepIndex),
				Vector3.new(6.5, 1, 5),
				CFrame.new(
					basePos.X + x,
					previousY + alpha * Config.TOWERS.FloorHeight,
					basePos.Z + sideZ
				),
				accent,
				Enum.Material.SmoothPlastic
			)
		end

		local hazard = newPart(
			structure,
			("Hazard_%02d"):format(floorIndex),
			Vector3.new(floorIndex % 2 == 0 and 18 or 2, 1.6, floorIndex % 2 == 0 and 2 or 18),
			CFrame.new(basePos.X, floorY + 1.25, basePos.Z),
			Color3.fromRGB(255, 66, 88),
			Enum.Material.Neon,
			false
		)
		hazard.Transparency = 0.08
		connectHazard(hazard)

		for cornerIndex, offset in ipairs({
			Vector3.new(-11, 0.65, -11),
			Vector3.new(11, 0.65, -11),
			Vector3.new(-11, 0.65, 11),
			Vector3.new(11, 0.65, 11),
		}) do
			local marker = newPart(
				structure,
				("Corner_%02d_%02d"):format(floorIndex, cornerIndex),
				Vector3.new(1.5, 0.25, 1.5),
				CFrame.new(basePos + Vector3.new(offset.X, floorY - basePos.Y + offset.Y, offset.Z)),
				accent,
				Enum.Material.Neon,
				false
			)
			marker.CanTouch = false
		end
	end

	local topY = baseTop + floors * Config.TOWERS.FloorHeight + 3
	local core = newPart(
		structure,
		"StealCore",
		Vector3.new(5, 5, 5),
		CFrame.new(basePos.X, topY, basePos.Z),
		Color3.fromRGB(255, 206, 72),
		Enum.Material.Neon,
		false
	)
	core.Shape = Enum.PartType.Ball
	core:SetAttribute("StealObjective", true)

	local light = Instance.new("PointLight")
	light.Name = "CoreLight"
	light.Color = core.Color
	light.Brightness = 2
	light.Range = 18
	light.Parent = core

	addPrompt(
		core,
		"StealPrompt",
		"STEAL CORE",
		"Tower Core",
		"Steal",
		plot,
		Config.STEAL.HoldDuration
	)

	plot:SetAttribute("FloorCount", floors)
	updatePlotIdentity(plot)
end

local function createBaseInteractions(plot)
	local basePos = plot.PrimaryPart.Position
	local plotIndex = tonumber(plot:GetAttribute("PlotIndex")) or 1
	local accent = PALETTE[((plotIndex - 1) % #PALETTE) + 1]
	local towardHub = Vector3.new(-basePos.X, 0, -basePos.Z).Unit
	local facing = CFrame.lookAt(basePos, basePos + towardHub)

	local baseModel = Instance.new("Model")
	baseModel.Name = "MiniBase"
	baseModel.Parent = plot

	local floor = newPart(
		baseModel,
		"InteriorFloor",
		Vector3.new(16, 1, 16),
		CFrame.new(basePos + Vector3.new(0, 1.6, 0)),
		Color3.fromRGB(25, 30, 42),
		Enum.Material.Metal
	)
	floor:SetAttribute("SafeInterior", true)

	for tier = 1, 3 do
		local y = 2.1 + (tier - 1) * 4
		local size = 18 - (tier - 1)
		local ring = newPart(
			baseModel,
			("Tier_%02d"):format(tier),
			Vector3.new(size, 0.55, size),
			CFrame.new(basePos + Vector3.new(0, y, 0)),
			tier == 3 and accent or Color3.fromRGB(42, 48, 64),
			tier == 3 and Enum.Material.Neon or Enum.Material.Metal
		)
		ring.CanTouch = false
	end

	for _, localOffset in ipairs({
		Vector3.new(-7.5, 5.8, -7.5),
		Vector3.new(7.5, 5.8, -7.5),
		Vector3.new(-7.5, 5.8, 7.5),
		Vector3.new(7.5, 5.8, 7.5),
	}) do
		local column = newPart(
			baseModel,
			"CornerColumn",
			Vector3.new(2.2, 8, 2.2),
			facing * CFrame.new(localOffset),
			accent,
			Enum.Material.Neon
		)
		column.CanTouch = false
	end

	for _, panelData in ipairs({
		{ Vector3.new(0, 5.7, -8), Vector3.new(12, 7, 1) },
		{ Vector3.new(-8, 5.7, 0), Vector3.new(1, 7, 12) },
		{ Vector3.new(8, 5.7, 0), Vector3.new(1, 7, 12) },
	}) do
		local glass = newPart(
			baseModel,
			"GlassPanel",
			panelData[2],
			facing * CFrame.new(panelData[1]),
			Color3.fromRGB(95, 110, 145),
			Enum.Material.Glass
		)
		glass.Transparency = 0.45
		glass.CanTouch = false
	end

	local roof = newPart(
		baseModel,
		"Roof",
		Vector3.new(16, 1, 16),
		CFrame.new(basePos + Vector3.new(0, 10.1, 0)),
		Color3.fromRGB(34, 39, 52),
		Enum.Material.Metal
	)
	roof.CanTouch = false

	local entrancePos = basePos + towardHub * 18 + Vector3.new(0, 1.5, 0)
	local entrance = newPart(
		plot,
		"BasePortal",
		Vector3.new(10, 0.75, 8),
		CFrame.lookAt(entrancePos, entrancePos + towardHub),
		Color3.fromRGB(78, 226, 143),
		Enum.Material.Neon
	)
	entrance:SetAttribute("BaseEntrance", true)

	local portalLight = Instance.new("PointLight")
	portalLight.Color = entrance.Color
	portalLight.Brightness = 2
	portalLight.Range = 14
	portalLight.Parent = entrance

	local portalGui = Instance.new("BillboardGui")
	portalGui.Size = UDim2.fromOffset(180, 42)
	portalGui.StudsOffsetWorldSpace = Vector3.new(0, 3.2, 0)
	portalGui.AlwaysOnTop = true
	portalGui.MaxDistance = 100
	portalGui.Parent = entrance

	local portalLabel = Instance.new("TextLabel")
	portalLabel.Size = UDim2.fromScale(1, 1)
	portalLabel.BackgroundColor3 = Color3.fromRGB(12, 20, 18)
	portalLabel.BackgroundTransparency = 0.18
	portalLabel.Text = "ENTER BASE"
	portalLabel.TextColor3 = Color3.fromRGB(130, 255, 184)
	portalLabel.Font = Enum.Font.GothamBlack
	portalLabel.TextScaled = true
	portalLabel.Parent = portalGui
	local portalCorner = Instance.new("UICorner")
	portalCorner.CornerRadius = UDim.new(0, 9)
	portalCorner.Parent = portalLabel

	local interiorSpawn = newPart(
		baseModel,
		"InteriorSpawn",
		Vector3.new(4, 0.2, 4),
		facing * CFrame.new(0, 2.3, 5),
		Color3.fromRGB(26, 31, 43),
		Enum.Material.SmoothPlastic,
		false
	)
	interiorSpawn.Transparency = 1
	interiorSpawn.CanTouch = false
	interiorSpawn.CanQuery = false

	local exitPad = newPart(
		baseModel,
		"ExitPad",
		Vector3.new(6, 0.55, 4),
		facing * CFrame.new(0, 2.25, -5.5),
		Color3.fromRGB(226, 91, 105),
		Enum.Material.Neon
	)
	exitPad:SetAttribute("BaseExit", true)
	local exitAction = ("ExitBase_%02d"):format(plotIndex)
	addPrompt(exitPad, "ExitPrompt", "EXIT BASE", "Outside", exitAction, plot, 0.1)

	local bankPad = newPart(
		baseModel,
		"BankPad",
		Vector3.new(5, 0.55, 5),
		facing * CFrame.new(-5, 2.25, 2),
		Color3.fromRGB(78, 226, 143),
		Enum.Material.Neon
	)
	bankPad:SetAttribute("BankZone", true)
	addPrompt(bankPad, "BankPrompt", "BANK CORE", "Your Vault", "Bank", plot, 0.2)

	local upgradePad = newPart(
		baseModel,
		"UpgradePad",
		Vector3.new(5, 0.55, 5),
		facing * CFrame.new(5, 2.25, 2),
		accent,
		Enum.Material.Neon
	)
	upgradePad:SetAttribute("UpgradeZone", true)
	addPrompt(upgradePad, "UpgradePrompt", "UPGRADE", "Tower Builder", "Upgrade", plot, 0.2)

	local function teleportPlayer(player, targetCFrame)
		if not player or portalDebounce[player] then
			return
		end
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if not character or not humanoid or humanoid.Health <= 0 then
			return
		end

		portalDebounce[player] = true
		player:SetAttribute("HazardImmuneUntil", workspace:GetServerTimeNow() + 1.5)
		character:PivotTo(targetCFrame * CFrame.new(0, 3.5, 0))
		task.delay(0.9, function()
			portalDebounce[player] = nil
		end)
	end

	entrance.Touched:Connect(function(hit)
		local character = hit and hit.Parent
		local player = character and Players:GetPlayerFromCharacter(character)
		if not player or tonumber(plot:GetAttribute("OwnerUserId")) ~= player.UserId then
			return
		end
		teleportPlayer(player, interiorSpawn.CFrame)
	end)

	interactionHandlers[exitAction] = function(player, sourcePlot)
		if sourcePlot ~= plot or tonumber(plot:GetAttribute("OwnerUserId")) ~= player.UserId then
			return
		end
		teleportPlayer(player, entrance.CFrame * CFrame.new(0, 0, -5))
	end
end

local function createBridge(world, index, target)
	local roads = world:FindFirstChild("Roads")
	if not roads then
		roads = Instance.new("Folder")
		roads.Name = "Roads"
		roads.Parent = world
	end

	local direction = Vector3.new(target.X, 0, target.Z).Unit
	local inner = direction * (Config.WORLD.HubSize.X * 0.48)
	local outer = target - direction * (Config.TOWERS.PlotSize.X * 0.48)
	local length = (outer - inner).Magnitude
	local center = (inner + outer) * 0.5
	local cframe = CFrame.lookAt(Vector3.new(center.X, 0, center.Z), Vector3.new(outer.X, 0, outer.Z))

	local bridge = newPart(
		roads,
		("Bridge_%02d"):format(index),
		Vector3.new(Config.WORLD.BridgeWidth, Config.WORLD.BridgeThickness, length),
		cframe,
		Color3.fromRGB(38, 43, 58),
		Enum.Material.Metal
	)
	bridge:SetAttribute("MainRoute", true)

	for _, side in ipairs({ -1, 1 }) do
		local rail = newPart(
			roads,
			("BridgeRail_%02d_%d"):format(index, side),
			Vector3.new(0.6, 2.2, length),
			cframe * CFrame.new(side * (Config.WORLD.BridgeWidth * 0.5 - 0.3), 1.7, 0),
			PALETTE[((index - 1) % #PALETTE) + 1],
			Enum.Material.Neon
		)
		rail.CanTouch = false
	end
end

function TowerService.SetInteractionHandlers(handlers)
	interactionHandlers = handlers or {}
end

function TowerService.Initialize(world)
	table.clear(plots)
	table.clear(playerPlots)

	local folder = Instance.new("Folder")
	folder.Name = "TowerPlots"
	folder.Parent = world

	local hub = newPart(
		world,
		"CentralNexus",
		Config.WORLD.HubSize,
		CFrame.new(0, 0, 0),
		Color3.fromRGB(24, 28, 40),
		Enum.Material.Slate
	)
	hub:SetAttribute("SafeHub", true)

	local hubSpawn = Instance.new("SpawnLocation")
	hubSpawn.Name = "HubSpawn"
	hubSpawn.Size = Vector3.new(10, 1, 10)
	hubSpawn.CFrame = CFrame.new(0, 2, 0)
	hubSpawn.Anchored = true
	hubSpawn.Neutral = true
	hubSpawn.Transparency = 0.45
	hubSpawn.Color = Color3.fromRGB(255, 255, 255)
	hubSpawn.Parent = world

	for axisIndex, offset in ipairs({
		Vector3.new(0, 1.1, 34),
		Vector3.new(0, 1.1, -34),
		Vector3.new(34, 1.1, 0),
		Vector3.new(-34, 1.1, 0),
	}) do
		local strip = newPart(
			world,
			("HubGuide_%02d"):format(axisIndex),
			axisIndex <= 2 and Vector3.new(6, 0.2, 14) or Vector3.new(14, 0.2, 6),
			CFrame.new(offset),
			Color3.fromRGB(115, 104, 255),
			Enum.Material.Neon,
			false
		)
		strip.CanTouch = false
	end

	local voidFloor = newPart(
		world,
		"VoidFloor",
		Config.WORLD.VoidFloorSize,
		CFrame.new(0, Config.WORLD.VoidFloorY, 0),
		Color3.fromRGB(8, 10, 16),
		Enum.Material.SmoothPlastic
	)
	voidFloor.Transparency = 0.1
	connectHazard(voidFloor)

	for index = 1, Config.TOWERS.PlotCount do
		local position = plotPosition(index)
		createBridge(world, index, position)

		local model = Instance.new("Model")
		model.Name = ("TowerPlot_%02d"):format(index)
		local rivalLevel = 1 + ((index - 1) % 3)
		model:SetAttribute("PlotIndex", index)
		model:SetAttribute("OwnerUserId", 0)
		model:SetAttribute("OwnerName", RIVAL_NAMES[index])
		model:SetAttribute("IsNPC", true)
		model:SetAttribute("TowerLevel", rivalLevel)
		model.Parent = folder

		local base = newPart(
			model,
			"Base",
			Config.TOWERS.PlotSize,
			CFrame.new(position),
			Color3.fromRGB(34, 39, 52),
			Enum.Material.Concrete
		)
		model.PrimaryPart = base

		local trim = newPart(
			model,
			"BaseTrim",
			Vector3.new(Config.TOWERS.PlotSize.X - 2, 0.25, Config.TOWERS.PlotSize.Z - 2),
			base.CFrame * CFrame.new(0, 1.15, 0),
			PALETTE[((index - 1) % #PALETTE) + 1],
			Enum.Material.Neon,
			false
		)
		trim.CanTouch = false

		local towardHub = Vector3.new(-position.X, 0, -position.Z).Unit
		local side = Vector3.new(-towardHub.Z, 0, towardHub.X)
		local spawnPosition = position
			+ towardHub * 20
			+ side * 7
			+ Vector3.new(0, Config.TOWERS.SpawnHeight, 0)
		local spawn = newPart(
			model,
			"OwnerSpawn",
			Vector3.new(4, 0.2, 4),
			CFrame.new(spawnPosition),
			Color3.fromRGB(82, 232, 150),
			Enum.Material.SmoothPlastic,
			false
		)
		spawn.Transparency = 1
		spawn.CanTouch = false
		spawn.CanQuery = false
		spawn:SetAttribute("SafeSpawn", true)

		createOwnerBillboard(model)
		createBaseInteractions(model)
		createTowerGeometry(model, rivalLevel)

		plots[index] = model
	end
end

function TowerService.Assign(player, towerLevel)
	if playerPlots[player] then
		return playerPlots[player]
	end

	for _, plot in ipairs(plots) do
		if plot:GetAttribute("OwnerUserId") == 0 then
			plot:SetAttribute("OwnerUserId", player.UserId)
			plot:SetAttribute("OwnerName", player.DisplayName)
			plot:SetAttribute("IsNPC", false)
			plot:SetAttribute("TowerLevel", towerLevel)
			playerPlots[player] = plot
			player:SetAttribute("TowerPlotIndex", plot:GetAttribute("PlotIndex"))
			createTowerGeometry(plot, towerLevel)
			updatePlotIdentity(plot)
			return plot
		end
	end

	return nil
end

function TowerService.GetForPlayer(player)
	return playerPlots[player]
end

function TowerService.GetByIndex(index)
	return plots[index]
end

function TowerService.GetPlots()
	return plots
end

function TowerService.Refresh(player, level)
	local plot = playerPlots[player]
	if not plot then
		return
	end

	plot:SetAttribute("TowerLevel", level)
	createTowerGeometry(plot, level)
	updatePlotIdentity(plot)
end

function TowerService.Release(player)
	local plot = playerPlots[player]
	if not plot then
		return
	end

	local index = tonumber(plot:GetAttribute("PlotIndex")) or 1
	local rivalLevel = 1 + ((index - 1) % 3)
	plot:SetAttribute("OwnerUserId", 0)
	plot:SetAttribute("OwnerName", RIVAL_NAMES[index])
	plot:SetAttribute("IsNPC", true)
	plot:SetAttribute("TowerLevel", rivalLevel)
	createTowerGeometry(plot, rivalLevel)
	updatePlotIdentity(plot)

	playerPlots[player] = nil
	player:SetAttribute("TowerPlotIndex", nil)
end

function TowerService.GetPlayerFromPlot(plot)
	local userId = plot and tonumber(plot:GetAttribute("OwnerUserId"))
	if not userId or userId == 0 then
		return nil
	end
	return Players:GetPlayerByUserId(userId)
end

return TowerService
