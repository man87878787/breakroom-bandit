-- Terrain-first world foundation: one large home island, two progression islands, and a horizon-scale ocean.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Terrain = workspace.Terrain

local WorldConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("WorldConfig"))

Terrain:Clear()
Terrain.WaterColor = WorldConfig.OCEAN.WaterColor
Terrain.WaterTransparency = WorldConfig.OCEAN.WaterTransparency
Terrain.WaterReflectance = WorldConfig.OCEAN.WaterReflectance
Terrain.WaterWaveSize = WorldConfig.OCEAN.WaterWaveSize
Terrain.WaterWaveSpeed = WorldConfig.OCEAN.WaterWaveSpeed

Terrain:FillBlock(
	CFrame.new(WorldConfig.OCEAN.Center),
	WorldConfig.OCEAN.Size,
	Enum.Material.Water
)

local function fillLobe(center, radius, topMaterial)
	local topY = -0.35
	local rockHeight = 30
	local sandHeight = 10
	local grassHeight = 5

	Terrain:FillCylinder(
		CFrame.new(center + Vector3.new(0, topY - rockHeight / 2, 0)),
		rockHeight,
		radius + 8,
		Enum.Material.Rock
	)
	Terrain:FillCylinder(
		CFrame.new(center + Vector3.new(0, topY - sandHeight / 2, 0)),
		sandHeight,
		radius + 3,
		Enum.Material.Sand
	)
	Terrain:FillCylinder(
		CFrame.new(center + Vector3.new(0, topY - grassHeight / 2, 0)),
		grassHeight,
		math.max(12, radius - 9),
		topMaterial
	)
end

local function addRockOutcrop(center, radius, height)
	Terrain:FillBall(center + Vector3.new(0, -height * 0.38, 0), radius, Enum.Material.Rock)
end

local function buildHomeIsland()
	local c = WorldConfig.HOME_ISLAND.Center
	fillLobe(c + Vector3.new(0, 0, 5), 142, Enum.Material.Grass)
	fillLobe(c + Vector3.new(-72, 0, 8), 102, Enum.Material.Grass)
	fillLobe(c + Vector3.new(72, 0, 8), 98, Enum.Material.Grass)
	fillLobe(c + Vector3.new(0, 0, 82), 94, Enum.Material.Grass)
	fillLobe(c + Vector3.new(-8, 0, -78), 88, Enum.Material.Grass)

	addRockOutcrop(c + Vector3.new(-155, -4, -25), 32, 22)
	addRockOutcrop(c + Vector3.new(158, -5, 25), 28, 20)
	addRockOutcrop(c + Vector3.new(-118, -5, 132), 24, 18)
	addRockOutcrop(c + Vector3.new(122, -5, 128), 26, 18)
end

local function buildIronwake()
	local island = WorldConfig.PROGRESSION_ISLANDS[1]
	local c = island.Center
	fillLobe(c, 116, Enum.Material.Ground)
	fillLobe(c + Vector3.new(-58, 0, 14), 82, Enum.Material.Ground)
	fillLobe(c + Vector3.new(62, 0, 10), 76, Enum.Material.Ground)
	fillLobe(c + Vector3.new(10, 0, 78), 70, Enum.Material.Ground)
	fillLobe(c + Vector3.new(-12, 0, -70), 66, Enum.Material.Ground)

	addRockOutcrop(c + Vector3.new(-136, -5, -22), 30, 22)
	addRockOutcrop(c + Vector3.new(135, -5, 24), 26, 20)
	addRockOutcrop(c + Vector3.new(28, -6, 145), 24, 17)
end

local function buildCrownreach()
	local island = WorldConfig.PROGRESSION_ISLANDS[2]
	local c = island.Center
	fillLobe(c, 124, Enum.Material.Grass)
	fillLobe(c + Vector3.new(-65, 0, 8), 86, Enum.Material.Grass)
	fillLobe(c + Vector3.new(66, 0, 18), 82, Enum.Material.Grass)
	fillLobe(c + Vector3.new(4, 0, 84), 75, Enum.Material.Grass)
	fillLobe(c + Vector3.new(-10, 0, -76), 72, Enum.Material.Grass)

	addRockOutcrop(c + Vector3.new(-148, -5, 5), 30, 22)
	addRockOutcrop(c + Vector3.new(148, -5, -10), 30, 22)
	addRockOutcrop(c + Vector3.new(50, -7, 150), 28, 20)
end

buildHomeIsland()
buildIronwake()
buildCrownreach()

workspace:SetAttribute("WorldTerrainVersion", 1)
workspace:SetAttribute("WorldIslandCount", 3)
