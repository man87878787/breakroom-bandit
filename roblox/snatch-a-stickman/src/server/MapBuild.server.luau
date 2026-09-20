-- Connected city-scale map layer for Snatch the Stickman.
-- Gameplay systems remain authoritative elsewhere; this script provides spatial language and models.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local world = workspace:WaitForChild("SnatchTheStickmanWorld")

local old = world:FindFirstChild("ConnectedMap")
if old then old:Destroy() end

local map = Instance.new("Folder")
map.Name = "ConnectedMap"
map.Parent = world

local roads = Instance.new("Folder")
roads.Name = "Roads"
roads.Parent = map

local models = Instance.new("Folder")
models.Name = "Models"
models.Parent = map

local landmarks = Instance.new("Folder")
landmarks.Name = "Landmarks"
landmarks.Parent = map
local function newPart(parent, name, size, cframe, color, material, collide, transparency)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cframe
	p.Anchored = true
	p.CanCollide = collide == true
	p.CanTouch = false
	p.CanQuery = collide == true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.Transparency = transparency or 0
	p.Parent = parent
	return p
end

local function newModel(parent, name, role)
	local m = Instance.new("Model")
	m.Name = name
	m:SetAttribute("MapRole", role or name)
	m.Parent = parent
	return m
end

local function addText(part, text, color, face)
	local gui = Instance.new("SurfaceGui")
	gui.Face = face or Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 28
	gui.Parent = part
	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = color or Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0.65
	label.TextScaled = true
	label.TextWrapped = true
	label.Font = Enum.Font.GothamBlack
	label.Parent = gui
	return label
end

local asphalt = Color3.fromRGB(28, 32, 42)
local roadEdge = Color3.fromRGB(71, 82, 108)
local cyan = Color3.fromRGB(80, 205, 255)
local green = Color3.fromRGB(82, 232, 150)
local purple = Color3.fromRGB(190, 102, 255)
local gold = Color3.fromRGB(255, 194, 69)

local function road(name, size, position)
	local base = newPart(roads, name, size, CFrame.new(position), asphalt, Enum.Material.Asphalt, false, 0.02)
	newPart(roads, name .. "Edge", Vector3.new(size.X, 0.05, math.min(size.Z, 0.24)), base.CFrame * CFrame.new(0, 0.07, -size.Z / 2), roadEdge, Enum.Material.Neon, false, 0.22)
	return base
end
-- Main city circulation: a market ring plus outer heist routes.
road("NorthMarketBoulevard", Vector3.new(66, 0.12, 8), Vector3.new(0, 0.08, -43))
road("SouthMarketBoulevard", Vector3.new(66, 0.12, 8), Vector3.new(0, 0.08, 43))
road("WestMarketBoulevard", Vector3.new(8, 0.12, 78), Vector3.new(-24, 0.08, 0))
road("EastMarketBoulevard", Vector3.new(8, 0.12, 78), Vector3.new(24, 0.08, 0))

road("NorthHeistRoute", Vector3.new(146, 0.08, 7), Vector3.new(0, 0.05, -76))
road("SouthHeistRoute", Vector3.new(146, 0.08, 7), Vector3.new(0, 0.05, 76))
road("WestHeistRoute", Vector3.new(7, 0.08, 146), Vector3.new(-76, 0.05, 0))
road("EastHeistRoute", Vector3.new(7, 0.08, 146), Vector3.new(76, 0.05, 0))

for z = -30, 30, 12 do
	newPart(roads, "MarketLane_" .. tostring(z), Vector3.new(1.1, 0.07, 5), CFrame.new(0, 0.64, z), green, Enum.Material.Neon, false, 0.2)
end

for x = -60, 60, 20 do
	newPart(roads, "NorthRouteMarker_" .. tostring(x), Vector3.new(8, 0.06, 0.35), CFrame.new(x, 0.12, -76), cyan, Enum.Material.Neon, false, 0.35)
	newPart(roads, "SouthRouteMarker_" .. tostring(x), Vector3.new(8, 0.06, 0.35), CFrame.new(x, 0.12, 76), cyan, Enum.Material.Neon, false, 0.35)
end
local function lampModel(name, position, lightColor)
	local m = newModel(models, name, "StreetLight")
	local pole = newPart(m, "Pole", Vector3.new(0.45, 7, 0.45), CFrame.new(position + Vector3.new(0, 3.5, 0)), Color3.fromRGB(48, 54, 69), Enum.Material.Metal, false)
	local head = newPart(m, "Light", Vector3.new(1.4, 0.35, 1.4), CFrame.new(position + Vector3.new(0, 7, 0)), lightColor, Enum.Material.Neon, false)
	local light = Instance.new("PointLight")
	light.Brightness = 1.15
	light.Range = 14
	light.Color = lightColor
	light.Shadows = false
	light.Parent = head
	m.PrimaryPart = pole
	return m
end

local lampPoints = {
	Vector3.new(-31, 0, -43), Vector3.new(31, 0, -43),
	Vector3.new(-31, 0, 43), Vector3.new(31, 0, 43),
	Vector3.new(-24, 0, -32), Vector3.new(24, 0, -32),
	Vector3.new(-24, 0, 32), Vector3.new(24, 0, 32),
}
for i, pos in ipairs(lampPoints) do
	lampModel("CityLamp" .. i, pos, i % 2 == 0 and cyan or purple)
end
local function marketStall(index, position, color)
	local m = newModel(models, "MarketStall" .. index, "RecruitmentStall")
	local baseCF = CFrame.new(position)
	local counter = newPart(m, "Counter", Vector3.new(5.5, 2, 2), baseCF * CFrame.new(0, 1, 0), Color3.fromRGB(42, 47, 61), Enum.Material.Metal, false)
	newPart(m, "Canopy", Vector3.new(6.5, 0.35, 4), baseCF * CFrame.new(0, 4.4, 0), color, Enum.Material.Neon, false, 0.1)
	newPart(m, "PostL", Vector3.new(0.3, 4, 0.3), baseCF * CFrame.new(-2.7, 2.2, 0), Color3.fromRGB(58, 64, 82), Enum.Material.Metal, false)
	newPart(m, "PostR", Vector3.new(0.3, 4, 0.3), baseCF * CFrame.new(2.7, 2.2, 0), Color3.fromRGB(58, 64, 82), Enum.Material.Metal, false)
	local sign = newPart(m, "Sign", Vector3.new(4.6, 1.25, 0.2), baseCF * CFrame.new(0, 3.2, 1.05), Color3.fromRGB(18, 21, 29), Enum.Material.SmoothPlastic, false)
	addText(sign, "LIVE MARKET", color, Enum.NormalId.Front)
	m.PrimaryPart = counter
	return m
end

local stallColors = {green, cyan, purple, gold}
local stallPositions = {
	Vector3.new(-13.5, 0, -26), Vector3.new(13.5, 0, -26),
	Vector3.new(-13.5, 0, -9), Vector3.new(13.5, 0, -9),
	Vector3.new(-13.5, 0, 9), Vector3.new(13.5, 0, 9),
	Vector3.new(-13.5, 0, 26), Vector3.new(13.5, 0, 26),
}
for i, pos in ipairs(stallPositions) do
	marketStall(i, pos, stallColors[((i - 1) % #stallColors) + 1])
end
local districtColors = {
	Color3.fromRGB(75, 198, 255),
	Color3.fromRGB(114, 238, 151),
	Color3.fromRGB(225, 120, 255),
	Color3.fromRGB(255, 183, 78),
	Color3.fromRGB(110, 132, 255),
	Color3.fromRGB(255, 105, 145),
}

local function baseGate(plotIndex, floor)
	local color = districtColors[plotIndex]
	local towardCenter = (Vector3.new(0, floor.Position.Y, 0) - floor.Position).Unit
	local gatePos = floor.Position + towardCenter * 18 + Vector3.new(0, 0.2, 0)
	local gateCF = CFrame.lookAt(gatePos, Vector3.new(0, gatePos.Y, 0))
	local m = newModel(models, "BaseGate" .. plotIndex, "BaseEntrance")

	newPart(m, "LeftPillar", Vector3.new(1.2, 7, 1.2), gateCF * CFrame.new(-5.2, 3.5, 0), Color3.fromRGB(40, 46, 60), Enum.Material.Metal, false)
	newPart(m, "RightPillar", Vector3.new(1.2, 7, 1.2), gateCF * CFrame.new(5.2, 3.5, 0), Color3.fromRGB(40, 46, 60), Enum.Material.Metal, false)
	local beam = newPart(m, "Header", Vector3.new(11.5, 1.2, 1.2), gateCF * CFrame.new(0, 6.5, 0), color, Enum.Material.Neon, false, 0.08)
	local sign = newPart(m, "DistrictSign", Vector3.new(8.5, 2, 0.25), gateCF * CFrame.new(0, 4.8, -0.68), Color3.fromRGB(16, 19, 27), Enum.Material.SmoothPlastic, false)
	addText(sign, "BASE " .. plotIndex .. "\nHEIST LANE", color, Enum.NormalId.Front)
	m.PrimaryPart = beam
	return m
end

for index = 1, 6 do
	local plot = world:WaitForChild("Plot" .. index)
	baseGate(index, plot:WaitForChild("Floor"))
end
local function crateStack(name, position, color)
	local m = newModel(models, name, "StreetProp")
	for i = 1, 3 do
		local offset = Vector3.new((i - 2) * 1.5, 0.75, (i % 2) * 0.55)
		newPart(m, "Crate" .. i, Vector3.new(1.4, 1.4, 1.4), CFrame.new(position + offset), color, Enum.Material.WoodPlanks, false)
	end
	return m
end

local cratePositions = {
	Vector3.new(-32, 0, -35), Vector3.new(32, 0, -35),
	Vector3.new(-32, 0, 35), Vector3.new(32, 0, 35),
	Vector3.new(-68, 0, -16), Vector3.new(68, 0, 16),
	Vector3.new(-68, 0, 16), Vector3.new(68, 0, -16),
}
for i, pos in ipairs(cratePositions) do
	crateStack("CrateStack" .. i, pos, i % 2 == 0 and Color3.fromRGB(92, 67, 49) or Color3.fromRGB(67, 75, 91))
end

local function planter(name, position)
	local m = newModel(models, name, "Planter")
	local pot = newPart(m, "Planter", Vector3.new(4, 1.3, 4), CFrame.new(position + Vector3.new(0, 0.65, 0)), Color3.fromRGB(49, 54, 63), Enum.Material.Concrete, false)
	newPart(m, "Trunk", Vector3.new(0.6, 4, 0.6), CFrame.new(position + Vector3.new(0, 3, 0)), Color3.fromRGB(89, 69, 52), Enum.Material.Wood, false)
	local crown = newPart(m, "Crown", Vector3.new(3.8, 3.8, 3.8), CFrame.new(position + Vector3.new(0, 5.4, 0)), Color3.fromRGB(52, 126, 87), Enum.Material.Grass, false)
	crown.Shape = Enum.PartType.Ball
	m.PrimaryPart = pot
	return m
end
for i, pos in ipairs({
	Vector3.new(-45, 0, -78), Vector3.new(-15, 0, -78), Vector3.new(15, 0, -78), Vector3.new(45, 0, -78),
	Vector3.new(-45, 0, 78), Vector3.new(-15, 0, 78), Vector3.new(15, 0, 78), Vector3.new(45, 0, 78),
}) do
	planter("Planter" .. i, pos)
end

local function stickmanStatue()
	local m = newModel(landmarks, "CentralStickmanMonument", "GameIdentity")
	local base = newPart(m, "Base", Vector3.new(8, 1.2, 8), CFrame.new(0, 1, 0), Color3.fromRGB(35, 40, 54), Enum.Material.Marble, false)
	local body = newPart(m, "Body", Vector3.new(1, 5, 1), CFrame.new(0, 7, 0), gold, Enum.Material.Neon, false)
	local head = newPart(m, "Head", Vector3.new(2.4, 2.4, 2.4), CFrame.new(0, 10.6, 0), gold, Enum.Material.Neon, false)
	head.Shape = Enum.PartType.Ball
	newPart(m, "ArmL", Vector3.new(0.55, 4.4, 0.55), CFrame.new(-1.5, 7, 0) * CFrame.Angles(0, 0, math.rad(-28)), gold, Enum.Material.Neon, false)
	newPart(m, "ArmR", Vector3.new(0.55, 4.4, 0.55), CFrame.new(1.5, 7, 0) * CFrame.Angles(0, 0, math.rad(28)), gold, Enum.Material.Neon, false)
	newPart(m, "LegL", Vector3.new(0.65, 4.6, 0.65), CFrame.new(-0.7, 3.7, 0), gold, Enum.Material.Neon, false)
	newPart(m, "LegR", Vector3.new(0.65, 4.6, 0.65), CFrame.new(0.7, 3.7, 0), gold, Enum.Material.Neon, false)
	m.PrimaryPart = base
	return m
end
stickmanStatue()
local function boardModel(name, position, facing, titleText, bodyText, accent)
	local m = newModel(landmarks, name, "SystemLandmark")
	local cf = CFrame.lookAt(position, facing)
	local base = newPart(m, "Base", Vector3.new(8, 0.7, 4), cf * CFrame.new(0, 0.35, 0), Color3.fromRGB(34, 39, 51), Enum.Material.Concrete, false)
	newPart(m, "PostL", Vector3.new(0.5, 6, 0.5), cf * CFrame.new(-3.3, 3.3, 0), Color3.fromRGB(48, 54, 70), Enum.Material.Metal, false)
	newPart(m, "PostR", Vector3.new(0.5, 6, 0.5), cf * CFrame.new(3.3, 3.3, 0), Color3.fromRGB(48, 54, 70), Enum.Material.Metal, false)
	local board = newPart(m, "Board", Vector3.new(7.2, 4.4, 0.35), cf * CFrame.new(0, 4.4, 0), Color3.fromRGB(15, 18, 26), Enum.Material.SmoothPlastic, false)
	local label = addText(board, titleText .. "\n" .. bodyText, accent, Enum.NormalId.Front)
	m.PrimaryPart = base
	return m, label, board
end

local eventModel, eventLabel, eventBoard = boardModel(
	"MarketEventTower",
	Vector3.new(31, 0, 0),
	Vector3.new(0, 0, 0),
	"MARKET EVENT",
	"CALM",
	cyan
)

local bountyModel = boardModel(
	"BountyStation",
	Vector3.new(-31, 0, 0),
	Vector3.new(0, 0, 0),
	"RARITY BOUNTIES",
	"RECRUIT OR SNATCH\nYOUR HUD TARGET",
	purple
)
local function updateEventBoard()
	local eventName = tostring(world:GetAttribute("MarketEvent") or "Calm")
	local description = tostring(world:GetAttribute("MarketEventDescription") or "Market stable")
	eventLabel.Text = "MARKET EVENT\n" .. string.upper(eventName) .. "\n" .. description

	if eventName == "Rare Rush" then
		eventLabel.TextColor3 = purple
		eventBoard.Color = Color3.fromRGB(44, 28, 58)
	elseif eventName == "Payday" then
		eventLabel.TextColor3 = green
		eventBoard.Color = Color3.fromRGB(24, 52, 40)
	else
		eventLabel.TextColor3 = cyan
		eventBoard.Color = Color3.fromRGB(15, 18, 26)
	end
end

world:GetAttributeChangedSignal("MarketEvent"):Connect(updateEventBoard)
world:GetAttributeChangedSignal("MarketEventDescription"):Connect(updateEventBoard)
updateEventBoard()

local rarityHub = newModel(landmarks, "RarityGallery", "CollectionLandmark")
local hubBase = newPart(rarityHub, "GalleryBase", Vector3.new(22, 0.5, 5), CFrame.new(0, 0.45, 49), Color3.fromRGB(31, 35, 46), Enum.Material.Marble, false)
for i, rarity in ipairs(Config.RARITIES) do
	local x = (i - 3) * 4
	local pedestal = newPart(rarityHub, rarity.Name .. "Pedestal", Vector3.new(3, 1, 3), CFrame.new(x, 1.1, 49), Color3.fromRGB(48, 53, 68), Enum.Material.Metal, false)
	local orb = newPart(rarityHub, rarity.Name .. "Orb", Vector3.new(1.6, 1.6, 1.6), CFrame.new(x, 2.7, 49), rarity.Color, Enum.Material.Neon, false)
	orb.Shape = Enum.PartType.Ball
	local tag = newPart(rarityHub, rarity.Name .. "Tag", Vector3.new(3.4, 1.1, 0.18), CFrame.new(x, 1.6, 47.45), Color3.fromRGB(16, 19, 27), Enum.Material.SmoothPlastic, false)
	addText(tag, rarity.Name, rarity.Color, Enum.NormalId.Front)
end
rarityHub.PrimaryPart = hubBase
-- Skyline silhouettes make the arena read as a complete city without affecting line-of-sight gameplay.
local skyline = Instance.new("Folder")
skyline.Name = "Skyline"
skyline.Parent = map

local buildingData = {
	{-84,-66,18}, {-84,-42,28}, {-84,-18,14}, {-84,18,24}, {-84,42,16}, {-84,66,30},
	{84,-66,26}, {84,-42,15}, {84,-18,31}, {84,18,18}, {84,42,27}, {84,66,16},
	{-62,-84,22}, {-34,-84,15}, {34,-84,25}, {62,-84,18},
	{-62,84,16}, {-34,84,29}, {34,84,18}, {62,84,26},
}
for i, data in ipairs(buildingData) do
	local x, z, height = data[1], data[2], data[3]
	local width = 8 + (i % 3) * 2
	local depth = 7 + (i % 2) * 2
	local b = newPart(skyline, "Building" .. i, Vector3.new(width, height, depth), CFrame.new(x, height / 2 - 0.4, z), Color3.fromRGB(30 + (i % 3) * 5, 34 + (i % 2) * 5, 48 + (i % 4) * 4), Enum.Material.Concrete, false)
	b.CanQuery = false
	for level = 1, math.floor(height / 5) do
		local window = newPart(skyline, "Window_" .. i .. "_" .. level, Vector3.new(math.max(2, width - 2), 0.22, 0.08), b.CFrame * CFrame.new(0, -height / 2 + level * 4.5, -depth / 2 - 0.05), i % 2 == 0 and cyan or gold, Enum.Material.Neon, false, 0.28)
		window.CanQuery = false
	end
end

map:SetAttribute("MapVersion", 2)
map:SetAttribute("DistrictCount", 6)
map:SetAttribute("MarketStallCount", #stallPositions)
map:SetAttribute("HasHeistRing", true)
map:SetAttribute("HasSystemLandmarks", true)
