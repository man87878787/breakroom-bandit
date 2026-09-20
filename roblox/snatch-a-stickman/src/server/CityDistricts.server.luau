-- Authored outer-city expansion for Snatch the Stickman.
-- Fills the enlarged playfield with named places, playable landmarks, traversal, and environmental storytelling.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local WorldConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("WorldConfig"))
local world = workspace:WaitForChild("SnatchTheStickmanWorld")
local connectedMap = world:WaitForChild("ConnectedMap")

local previous = connectedMap:FindFirstChild("CityDistricts")
if previous then
	previous:Destroy()
end

local root = Instance.new("Folder")
root.Name = "CityDistricts"
root.Parent = connectedMap

local geometry = Instance.new("Folder")
geometry.Name = "Geometry"
geometry.Parent = root

local landmarks = Instance.new("Folder")
landmarks.Name = "Landmarks"
landmarks.Parent = root

local props = Instance.new("Folder")
props.Name = "Props"
props.Parent = root

local reactiveNeon = {}
local districtCount = 0
local propCount = 0
local buildingCount = 0
local routeCount = 0

local COLORS = {
	Dark = Color3.fromRGB(21, 25, 34),
	Concrete = Color3.fromRGB(55, 61, 73),
	Metal = Color3.fromRGB(48, 55, 69),
	Asphalt = Color3.fromRGB(28, 32, 42),
	Window = Color3.fromRGB(116, 178, 255),
	White = Color3.fromRGB(232, 239, 250),
}

local function part(parent, name, size, cframe, color, material, collide, transparency)
	local item = Instance.new("Part")
	item.Name = name
	item.Size = size
	item.CFrame = cframe
	item.Anchored = true
	item.CanCollide = collide == true
	item.CanTouch = false
	item.CanQuery = collide == true
	item.TopSurface = Enum.SurfaceType.Smooth
	item.BottomSurface = Enum.SurfaceType.Smooth
	item.Color = color
	item.Material = material or Enum.Material.SmoothPlastic
	item.Transparency = transparency or 0
	item.Parent = parent
	return item
end

local function model(parent, name, role)
	local item = Instance.new("Model")
	item.Name = name
	item:SetAttribute("WorldRole", role or name)
	item.Parent = parent
	return item
end

local function label(target, text, color, face)
	local gui = Instance.new("SurfaceGui")
	gui.Name = "WorldLabel"
	gui.Face = face or Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 26
	gui.Parent = target

	local textLabel = Instance.new("TextLabel")
	textLabel.Name = "Text"
	textLabel.Size = UDim2.fromScale(1, 1)
	textLabel.BackgroundTransparency = 1
	textLabel.Text = text
	textLabel.TextColor3 = color
	textLabel.TextStrokeTransparency = 0.68
	textLabel.TextScaled = true
	textLabel.TextWrapped = true
	textLabel.Font = Enum.Font.GothamBlack
	textLabel.Parent = gui
	return textLabel
end

local function neon(parent, name, size, cframe, accent, transparency)
	local item = part(parent, name, size, cframe, accent, Enum.Material.Neon, false, transparency or 0.12)
	item.CanQuery = false
	table.insert(reactiveNeon, {Part = item, BaseColor = accent})
	return item
end

local function districtPad(district, size)
	districtCount += 1
	local folder = model(geometry, district.Id, "District")
	folder:SetAttribute("DistrictId", district.Id)
	folder:SetAttribute("DisplayName", district.Name)

	local pad = part(folder, "DistrictFloor", size, CFrame.new(district.Center + Vector3.new(0, -0.34, 0)), COLORS.Asphalt, Enum.Material.Asphalt, true)
	local trimN = neon(folder, "TrimNorth", Vector3.new(size.X - 2, 0.12, 0.35), pad.CFrame * CFrame.new(0, 0.58, -size.Z / 2 + 0.8), district.Accent, 0.2)
	local trimS = neon(folder, "TrimSouth", Vector3.new(size.X - 2, 0.12, 0.35), pad.CFrame * CFrame.new(0, 0.58, size.Z / 2 - 0.8), district.Accent, 0.2)
	trimN.CanQuery = false
	trimS.CanQuery = false

	local sign = part(folder, "DistrictSign", Vector3.new(15, 4.8, 0.45), CFrame.new(district.Center + Vector3.new(0, 6.2, -size.Z / 2 + 2)), COLORS.Dark, Enum.Material.Metal, false)
	label(sign, string.upper(district.Name) .. "\n" .. district.Subtitle, district.Accent, Enum.NormalId.Front)
	return folder, pad
end

local function street(name, a, b, width, accent)
	routeCount += 1
	local delta = b - a
	local midpoint = a + delta * 0.5
	local road = part(geometry, name, Vector3.new(width, 0.2, delta.Magnitude), CFrame.lookAt(midpoint, b), COLORS.Asphalt, Enum.Material.Asphalt, true)
	neon(geometry, name .. "Guide", Vector3.new(0.24, 0.06, math.max(1, delta.Magnitude - 2)), road.CFrame * CFrame.new(0, 0.14, 0), accent, 0.32)
	return road
end

local function shellBuilding(name, center, size, accent, signText, openSide)
	buildingCount += 1
	local m = model(geometry, name, "PlayableBuilding")
	local width, height, depth = size.X, size.Y, size.Z
	local baseCF = CFrame.new(center)
	part(m, "Floor", Vector3.new(width, 0.6, depth), baseCF * CFrame.new(0, 0.3, 0), COLORS.Concrete, Enum.Material.Concrete, true)
	part(m, "Roof", Vector3.new(width, 0.7, depth), baseCF * CFrame.new(0, height, 0), COLORS.Metal, Enum.Material.Metal, true)

	local wallT = 0.7
	part(m, "BackWall", Vector3.new(width, height, wallT), baseCF * CFrame.new(0, height / 2, depth / 2), COLORS.Concrete, Enum.Material.Concrete, true)
	part(m, "LeftWall", Vector3.new(wallT, height, depth), baseCF * CFrame.new(-width / 2, height / 2, 0), COLORS.Concrete, Enum.Material.Concrete, true)
	part(m, "RightWall", Vector3.new(wallT, height, depth), baseCF * CFrame.new(width / 2, height / 2, 0), COLORS.Concrete, Enum.Material.Concrete, true)
	if not openSide then
		part(m, "FrontLipL", Vector3.new(width * 0.25, height, wallT), baseCF * CFrame.new(-width * 0.375, height / 2, -depth / 2), COLORS.Concrete, Enum.Material.Concrete, true)
		part(m, "FrontLipR", Vector3.new(width * 0.25, height, wallT), baseCF * CFrame.new(width * 0.375, height / 2, -depth / 2), COLORS.Concrete, Enum.Material.Concrete, true)
	end

	local sign = part(m, "Sign", Vector3.new(math.min(width - 2, 15), 2.4, 0.25), baseCF * CFrame.new(0, math.min(height - 1.8, 6.5), -depth / 2 - 0.4), COLORS.Dark, Enum.Material.Metal, false)
	label(sign, signText, accent, Enum.NormalId.Front)

	for x = -width / 2 + 2.5, width / 2 - 2.5, 5 do
		neon(m, "Window", Vector3.new(2.8, 1.4, 0.12), baseCF * CFrame.new(x, height - 2.2, depth / 2 + 0.4), accent, 0.3)
	end
	return m
end

local function crateStack(parent, name, position, accent)
	propCount += 1
	local m = model(parent, name, "Cargo")
	for i = 1, 5 do
		local row = i <= 3 and 0 or 1
		local column = row == 0 and (i - 2) or (i - 4.5)
		local crate = part(m, "Crate" .. i, Vector3.new(2.6, 2.6, 2.6), CFrame.new(position + Vector3.new(column * 2.8, 1.3 + row * 2.7, 0)), Color3.fromRGB(91, 68, 49), Enum.Material.WoodPlanks, true)
		if i == 1 then
			neon(m, "CargoStripe", Vector3.new(2.1, 0.18, 2.72), crate.CFrame * CFrame.new(0, 0.3, 0), accent, 0.25)
		end
	end
	return m
end

local function lamp(parent, name, position, accent)
	propCount += 1
	local m = model(parent, name, "StreetLight")
	part(m, "Pole", Vector3.new(0.45, 8, 0.45), CFrame.new(position + Vector3.new(0, 4, 0)), COLORS.Metal, Enum.Material.Metal, true)
	local head = neon(m, "Lamp", Vector3.new(1.6, 0.35, 1.6), CFrame.new(position + Vector3.new(0, 8.1, 0)), accent, 0.04)
	local light = Instance.new("PointLight")
	light.Brightness = 1.1
	light.Range = 14
	light.Shadows = false
	light.Color = accent
	light.Parent = head
end

-- Connect the original heist ring to the expanded city.
street("WestFreightConnector", Vector3.new(-84, 0.05, 0), Vector3.new(-116, 0.05, 0), 10, Color3.fromRGB(255, 183, 78))
street("EastJunctionConnector", Vector3.new(84, 0.05, 0), Vector3.new(116, 0.05, 0), 10, Color3.fromRGB(75, 198, 255))
street("NorthHighlineConnector", Vector3.new(0, 0.05, -84), Vector3.new(0, 0.05, -116), 10, Color3.fromRGB(204, 105, 255))
street("SouthCommonsConnector", Vector3.new(0, 0.05, 84), Vector3.new(0, 0.05, 116), 10, Color3.fromRGB(255, 105, 145))

local freight = WorldConfig.GetDistrictById("FreightYard")
districtPad(freight, Vector3.new(39, 0.5, 58))
shellBuilding("FreightWarehouseA", Vector3.new(-105, 0, -17), Vector3.new(20, 10, 17), freight.Accent, "CARGO 01", true)
shellBuilding("FreightWarehouseB", Vector3.new(-105, 0, 18), Vector3.new(20, 10, 17), freight.Accent, "CARGO 02", true)
for z = -22, 22, 11 do
	crateStack(props, "FreightCrates" .. tostring(z), Vector3.new(-88, 0, z), freight.Accent)
end

-- Simple gantry crane gives the west skyline a recognizable silhouette.
local crane = model(landmarks, "FreightGantryCrane", "Landmark")
for x = -1, 1, 2 do
	part(crane, x < 0 and "WestLeg" or "EastLeg", Vector3.new(1.2, 17, 1.2), CFrame.new(-98 + x * 9, 8.5, -27), COLORS.Metal, Enum.Material.Metal, true)
end
local craneBeam = part(crane, "Beam", Vector3.new(22, 1.3, 1.3), CFrame.new(-98, 16.5, -27), COLORS.Metal, Enum.Material.Metal, true)
neon(crane, "SafetyLight", Vector3.new(20, 0.25, 0.3), craneBeam.CFrame * CFrame.new(0, 0.75, 0), freight.Accent, 0.12)

local junction = WorldConfig.GetDistrictById("NeonJunction")
districtPad(junction, Vector3.new(39, 0.5, 58))
shellBuilding("JunctionArcade", Vector3.new(105, 0, -18), Vector3.new(20, 9, 15), junction.Accent, "NEON ARCADE", true)
shellBuilding("CourierOffice", Vector3.new(105, 0, 19), Vector3.new(20, 9, 15), junction.Accent, "COURIER DESK", true)
for z = -23, 23, 11.5 do
	lamp(props, "JunctionLamp" .. tostring(z), Vector3.new(87, 0, z), junction.Accent)
end

local junctionArch = model(landmarks, "JunctionGateway", "Landmark")
part(junctionArch, "Left", Vector3.new(1.2, 11, 1.2), CFrame.new(88, 5.5, -27), COLORS.Metal, Enum.Material.Metal, true)
part(junctionArch, "Right", Vector3.new(1.2, 11, 1.2), CFrame.new(108, 5.5, -27), COLORS.Metal, Enum.Material.Metal, true)
neon(junctionArch, "Header", Vector3.new(21, 1, 1), CFrame.new(98, 10.5, -27), junction.Accent, 0.04)
local junctionSign = part(junctionArch, "Sign", Vector3.new(15, 3, 0.3), CFrame.new(98, 8.2, -27.6), COLORS.Dark, Enum.Material.Metal, false)
label(junctionSign, "NEON JUNCTION\nCITY TRANSIT", junction.Accent, Enum.NormalId.Front)

local highline = WorldConfig.GetDistrictById("Highline")
districtPad(highline, Vector3.new(60, 0.5, 37))
shellBuilding("HighlineClubhouse", Vector3.new(20, 0, -108), Vector3.new(18, 8, 15), highline.Accent, "LOOKOUT", true)
local highDeck = part(landmarks, "HighlineDeck", Vector3.new(35, 0.8, 10), CFrame.new(-24, 8, -104), COLORS.Metal, Enum.Material.Metal, true)
routeCount += 1
for side = -1, 1, 2 do
	neon(landmarks, side < 0 and "HighlineRailL" or "HighlineRailR", Vector3.new(35, 0.3, 0.25), highDeck.CFrame * CFrame.new(0, 1.1, side * 4.8), highline.Accent, 0.18)
end
for i = 0, 8 do
	local step = part(landmarks, "HighlineStep" .. i, Vector3.new(8, 0.6, 2.2), CFrame.new(-41, 0.45 + i * 0.9, -104 + i * 0.7), COLORS.Metal, Enum.Material.Metal, true)
	step.CFrame = step.CFrame * CFrame.Angles(math.rad(-19), 0, 0)
end

local commons = WorldConfig.GetDistrictById("FoundryCommons")
districtPad(commons, Vector3.new(60, 0.5, 37))
shellBuilding("FoundryCafe", Vector3.new(-20, 0, 108), Vector3.new(18, 8, 15), commons.Accent, "FOUNDRY CAFE", true)

local fountain = model(landmarks, "CommonsFountain", "Landmark")
local fountainBase = part(fountain, "Base", Vector3.new(12, 1, 12), CFrame.new(-18, 0.5, 106), Color3.fromRGB(45, 51, 63), Enum.Material.Marble, true)
fountainBase.Shape = Enum.PartType.Cylinder
fountainBase.CFrame = fountainBase.CFrame * CFrame.Angles(0, 0, math.rad(90))
local water = part(fountain, "Water", Vector3.new(9.5, 0.35, 9.5), CFrame.new(-18, 1.1, 106), Color3.fromRGB(77, 174, 255), Enum.Material.Glass, false, 0.25)
water.Shape = Enum.PartType.Cylinder
water.CFrame = water.CFrame * CFrame.Angles(0, 0, math.rad(90))
neon(fountain, "Core", Vector3.new(1.4, 6, 1.4), CFrame.new(-18, 4, 106), commons.Accent, 0.08)

-- Street furniture and readable edges in every outer district.
for _, district in ipairs({freight, junction, highline, commons}) do
	for i, offset in ipairs({
		Vector3.new(-12, 0, -12),
		Vector3.new(12, 0, -12),
		Vector3.new(-12, 0, 12),
		Vector3.new(12, 0, 12),
	}) do
		lamp(props, district.Id .. "Lamp" .. i, district.Center + offset, district.Accent)
	end
end

-- Small cover objects are intentionally offset from connector centerlines.
for i, info in ipairs({
	{Vector3.new(-73, 0, -92), highline.Accent},
	{Vector3.new(73, 0, -92), highline.Accent},
	{Vector3.new(-73, 0, 92), commons.Accent},
	{Vector3.new(73, 0, 92), commons.Accent},
}) do
	local m = model(props, "UtilityCluster" .. i, "StreetProp")
	part(m, "Cabinet", Vector3.new(3.2, 4, 2), CFrame.new(info[1] + Vector3.new(0, 2, 0)), COLORS.Metal, Enum.Material.Metal, true)
	neon(m, "Indicator", Vector3.new(1.8, 0.35, 0.15), CFrame.new(info[1] + Vector3.new(0, 2.5, -1.1)), info[2], 0.06)
	propCount += 1
end

-- Perimeter facades fill the expanded corners and give every skyline direction a distinct silhouette.
local perimeterBuildings = {
	{Vector3.new(-98, 0, -98), Vector3.new(18, 22, 16), freight.Accent, "SCRAPWORKS"},
	{Vector3.new(-75, 0, -108), Vector3.new(14, 16, 14), highline.Accent, "NORTH LOFTS"},
	{Vector3.new(98, 0, -98), Vector3.new(18, 25, 16), junction.Accent, "SIGNAL TOWER"},
	{Vector3.new(75, 0, -108), Vector3.new(14, 18, 14), highline.Accent, "ROOFTOP ROW"},
	{Vector3.new(-98, 0, 98), Vector3.new(18, 19, 16), freight.Accent, "OLD FOUNDRY"},
	{Vector3.new(-75, 0, 108), Vector3.new(14, 17, 14), commons.Accent, "COMMONS LOFT"},
	{Vector3.new(98, 0, 98), Vector3.new(18, 23, 16), junction.Accent, "COURIER STACK"},
	{Vector3.new(75, 0, 108), Vector3.new(14, 16, 14), commons.Accent, "SOUTH LOFTS"},
}

for index, info in ipairs(perimeterBuildings) do
	buildingCount += 1
	local center = info[1]
	local size = info[2]
	local accent = info[3]
	local m = model(geometry, "PerimeterFacade" .. index, "SkylineBuilding")
	local body = part(m, "Body", size, CFrame.new(center + Vector3.new(0, size.Y / 2, 0)), Color3.fromRGB(31 + index % 3 * 5, 35 + index % 2 * 5, 48 + index % 4 * 3), Enum.Material.Concrete, true)
	for level = 1, math.max(2, math.floor(size.Y / 5)) do
		neon(
			m,
			"WindowBand" .. level,
			Vector3.new(size.X - 2.5, 0.22, 0.12),
			body.CFrame * CFrame.new(0, -size.Y / 2 + level * 4.3, -size.Z / 2 - 0.08),
			accent,
			0.35
		)
	end
	local roofSign = part(m, "RoofSign", Vector3.new(math.min(size.X - 2, 12), 1.7, 0.22), body.CFrame * CFrame.new(0, size.Y / 2 - 2.2, -size.Z / 2 - 0.18), COLORS.Dark, Enum.Material.Metal, false)
	label(roofSign, info[4], accent, Enum.NormalId.Front)
end

local function eventColor()
	local eventName = tostring(world:GetAttribute("MarketEvent") or "Calm")
	if eventName == "Rare Rush" then
		return Color3.fromRGB(204, 105, 255)
	elseif eventName == "Payday" then
		return Color3.fromRGB(82, 232, 150)
	end
	return nil
end

local function refreshEventState()
	local override = eventColor()
	for _, entry in ipairs(reactiveNeon) do
		if entry.Part.Parent then
			entry.Part.Color = override or entry.BaseColor
		end
	end
	root:SetAttribute("LiveMarketEvent", tostring(world:GetAttribute("MarketEvent") or "Calm"))
end

world:GetAttributeChangedSignal("MarketEvent"):Connect(refreshEventState)
refreshEventState()

root:SetAttribute("CityExpansionVersion", 1)
root:SetAttribute("DistrictCount", districtCount)
root:SetAttribute("BuildingCount", buildingCount)
root:SetAttribute("PropClusters", propCount)
root:SetAttribute("AddedRoutes", routeCount)
root:SetAttribute("HasPlayableOuterDistricts", true)
root:SetAttribute("HasReactiveDistrictLighting", true)
