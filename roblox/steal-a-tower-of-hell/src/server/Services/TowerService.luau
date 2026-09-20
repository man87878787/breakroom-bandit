local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local TowerService = {}
local plots = {}
local playerPlots = {}

local function newPart(parent, name, size, cframe, color, material)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = cframe
	part.Anchored = true
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

local function createTowerGeometry(plot, level)
	local structure = plot:FindFirstChild("Structure")
	if structure then
		structure:Destroy()
	end

	structure = Instance.new("Folder")
	structure.Name = "Structure"
	structure.Parent = plot

	local floors = math.clamp(
		Config.TOWERS.BaseFloorCount + (level - 1) * Config.TOWERS.FloorsPerUpgrade,
		Config.TOWERS.BaseFloorCount,
		Config.TOWERS.MaxFloors
	)

	for floorIndex = 1, floors do
		local y = 1 + (floorIndex - 1) * Config.TOWERS.FloorHeight
		local rotation = math.rad((floorIndex - 1) * 90)
		local platform = newPart(
			structure,
			("Floor_%02d"):format(floorIndex),
			Vector3.new(28, 1, 28),
			CFrame.new(plot.PrimaryPart.Position + Vector3.new(0, y, 0)) * CFrame.Angles(0, rotation, 0),
			floorIndex % 2 == 0 and Color3.fromRGB(48, 54, 72) or Color3.fromRGB(62, 68, 88),
			Enum.Material.Metal
		)

		local offset = floorIndex % 2 == 0 and 9 or -9
		newPart(
			structure,
			("Step_%02d"):format(floorIndex),
			Vector3.new(8, 1, 8),
			platform.CFrame * CFrame.new(offset, Config.TOWERS.FloorHeight * 0.48, 0),
			Color3.fromRGB(112, 92, 255),
			Enum.Material.Neon
		)
	end

	local topY = 1 + (floors - 1) * Config.TOWERS.FloorHeight + 3
	local core = newPart(
		structure,
		"StealCore",
		Vector3.new(5, 5, 5),
		CFrame.new(plot.PrimaryPart.Position + Vector3.new(0, topY, 0)),
		Color3.fromRGB(255, 196, 72),
		Enum.Material.Neon
	)
	core.Shape = Enum.PartType.Ball
	core:SetAttribute("StealObjective", true)
	plot:SetAttribute("FloorCount", floors)
end

function TowerService.Initialize(world)
	local folder = Instance.new("Folder")
	folder.Name = "TowerPlots"
	folder.Parent = world

	local center = newPart(
		world,
		"CentralNexus",
		Vector3.new(80, 2, 80),
		CFrame.new(0, 0, 0),
		Color3.fromRGB(24, 28, 40),
		Enum.Material.Slate
	)
	center:SetAttribute("SafeHub", true)

	for index = 1, Config.TOWERS.PlotCount do
		local model = Instance.new("Model")
		model.Name = ("TowerPlot_%02d"):format(index)
		model:SetAttribute("PlotIndex", index)
		model:SetAttribute("OwnerUserId", 0)
		model:SetAttribute("TowerLevel", 1)
		model.Parent = folder

		local base = newPart(
			model,
			"Base",
			Config.TOWERS.PlotSize,
			CFrame.new(plotPosition(index)),
			Color3.fromRGB(36, 41, 55),
			Enum.Material.Concrete
		)
		model.PrimaryPart = base

		local spawn = Instance.new("SpawnLocation")
		spawn.Name = "OwnerSpawn"
		spawn.Size = Vector3.new(7, 1, 7)
		spawn.CFrame = base.CFrame * CFrame.new(0, Config.TOWERS.SpawnHeight, 0)
		spawn.Anchored = true
		spawn.Neutral = true
		spawn.Transparency = 0.35
		spawn.Color = Color3.fromRGB(82, 232, 150)
		spawn.Parent = model

		createTowerGeometry(model, 1)
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
			plot:SetAttribute("TowerLevel", towerLevel)
			createTowerGeometry(plot, towerLevel)
			playerPlots[player] = plot
			player:SetAttribute("TowerPlotIndex", plot:GetAttribute("PlotIndex"))
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

function TowerService.Refresh(player, level)
	local plot = playerPlots[player]
	if not plot then
		return
	end
	plot:SetAttribute("TowerLevel", level)
	createTowerGeometry(plot, level)
end

function TowerService.Release(player)
	local plot = playerPlots[player]
	if not plot then
		return
	end
	plot:SetAttribute("OwnerUserId", 0)
	plot:SetAttribute("OwnerName", "")
	plot:SetAttribute("TowerLevel", 1)
	createTowerGeometry(plot, 1)
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
