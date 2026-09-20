-- Studio-grade authored-world expansion for Snatch the Stickman.
-- Adds navigation, landmarks, models, props, vertical routes, and dynamic district identity.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local world = workspace:WaitForChild("SnatchTheStickmanWorld")
local connectedMap = world:WaitForChild("ConnectedMap")

local old = connectedMap:FindFirstChild("StudioExpansion")
if old then old:Destroy() end

local expansion = Instance.new("Folder")
expansion.Name = "StudioExpansion"
expansion.Parent = connectedMap

local architecture = Instance.new("Folder")
architecture.Name = "Architecture"
architecture.Parent = expansion

local props = Instance.new("Folder")
props.Name = "Props"
props.Parent = expansion

local navigation = Instance.new("Folder")
navigation.Name = "Navigation"
navigation.Parent = expansion
local function part(parent, name, size, cframe, color, material, collide, transparency)
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

local function model(parent, name, role)
	local m = Instance.new("Model")
	m.Name = name
	m:SetAttribute("WorldRole", role or name)
	m.Parent = parent
	return m
end

local function textSurface(target, text, color, face)
	local gui = Instance.new("SurfaceGui")
	gui.Name = "Display"
	gui.Face = face or Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 28
	gui.Parent = target
	local label = Instance.new("TextLabel")
	label.Name = "Text"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = color or Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0.72
	label.TextScaled = true
	label.TextWrapped = true
	label.Font = Enum.Font.GothamBlack
	label.Parent = gui
	return label
end

local asphalt = Color3.fromRGB(30, 34, 44)
local concrete = Color3.fromRGB(57, 62, 73)
local dark = Color3.fromRGB(20, 24, 33)
local metal = Color3.fromRGB(50, 56, 70)
local cyan = Color3.fromRGB(78, 204, 255)
local green = Color3.fromRGB(82, 232, 150)
local purple = Color3.fromRGB(204, 105, 255)
local gold = Color3.fromRGB(255, 194, 72)
local red = Color3.fromRGB(255, 96, 118)

local propCount = 0
local routeCount = 0
local landmarkCount = 0
local function sidewalk(name, size, position)
	routeCount += 1
	return part(
		navigation,
		name,
		size,
		CFrame.new(position),
		Color3.fromRGB(67, 71, 81),
		Enum.Material.Concrete,
		true,
		0.02
	)
end

-- Walkable sidewalks ring the market and create readable pedestrian lanes.
sidewalk("NorthMarketWalk", Vector3.new(68, 0.45, 5), Vector3.new(0, 0.23, -48))
sidewalk("SouthMarketWalk", Vector3.new(68, 0.45, 5), Vector3.new(0, 0.23, 48))
sidewalk("WestMarketWalk", Vector3.new(5, 0.45, 86), Vector3.new(-29, 0.23, 0))
sidewalk("EastMarketWalk", Vector3.new(5, 0.45, 86), Vector3.new(29, 0.23, 0))

local crosswalks = {
	{Vector3.new(0, 0.52, -43), Vector3.new(1.2, 0.08, 6)},
	{Vector3.new(0, 0.52, 43), Vector3.new(1.2, 0.08, 6)},
	{Vector3.new(-24, 0.52, 0), Vector3.new(6, 0.08, 1.2)},
	{Vector3.new(24, 0.52, 0), Vector3.new(6, 0.08, 1.2)},
}

for i, info in ipairs(crosswalks) do
	for stripe = -2, 2 do
		local pos = info[1]
		local size = info[2]
		local offset
		if size.X < size.Z then
			offset = Vector3.new(stripe * 2.1, 0, 0)
		else
			offset = Vector3.new(0, 0, stripe * 2.1)
		end
		part(
			navigation,
			"Crosswalk_" .. i .. "_" .. stripe,
			size,
			CFrame.new(pos + offset),
			Color3.fromRGB(218, 223, 232),
			Enum.Material.SmoothPlastic,
			false,
			0.12
		)
	end
end

local function bench(name, position, yaw)
	propCount += 1
	local m = model(props, name, "Bench")
	local cf = CFrame.new(position) * CFrame.Angles(0, math.rad(yaw or 0), 0)
	local seat = part(m, "Seat", Vector3.new(5, 0.45, 1.6), cf * CFrame.new(0, 1.5, 0), Color3.fromRGB(88, 65, 48), Enum.Material.WoodPlanks, true)
	part(m, "Back", Vector3.new(5, 2, 0.35), cf * CFrame.new(0, 2.4, 0.65), Color3.fromRGB(88, 65, 48), Enum.Material.WoodPlanks, true)
	part(m, "LegL", Vector3.new(0.35, 1.4, 1.2), cf * CFrame.new(-1.8, 0.7, 0), metal, Enum.Material.Metal, true)
	part(m, "LegR", Vector3.new(0.35, 1.4, 1.2), cf * CFrame.new(1.8, 0.7, 0), metal, Enum.Material.Metal, true)
	m.PrimaryPart = seat
	return m
end
local function vendingMachine(name, position, accent, yaw)
	propCount += 1
	local m = model(props, name, "VendingMachine")
	local cf = CFrame.new(position) * CFrame.Angles(0, math.rad(yaw or 0), 0)
	local body = part(m, "Body", Vector3.new(2.8, 5, 2), cf * CFrame.new(0, 2.5, 0), dark, Enum.Material.Metal, true)
	local panel = part(m, "Panel", Vector3.new(2.2, 3.2, 0.16), cf * CFrame.new(0, 2.9, -1.08), accent, Enum.Material.Neon, false, 0.08)
	textSurface(panel, [[SNATCH
SUPPLY]], Color3.fromRGB(15, 19, 26), Enum.NormalId.Front)
	local slot = part(m, "Slot", Vector3.new(1.6, 0.45, 0.18), cf * CFrame.new(0, 0.75, -1.1), metal, Enum.Material.Metal, false)
	m.PrimaryPart = body
	return m
end

local function dumpster(name, position, yaw)
	propCount += 1
	local m = model(props, name, "Dumpster")
	local cf = CFrame.new(position) * CFrame.Angles(0, math.rad(yaw or 0), 0)
	local body = part(m, "Body", Vector3.new(4.5, 2.5, 2.5), cf * CFrame.new(0, 1.25, 0), Color3.fromRGB(51, 84, 68), Enum.Material.Metal, true)
	part(m, "Lid", Vector3.new(4.8, 0.25, 2.8), cf * CFrame.new(0, 2.65, 0), Color3.fromRGB(43, 66, 57), Enum.Material.Metal, true)
	m.PrimaryPart = body
	return m
end

local function utilityBox(name, position, accent)
	propCount += 1
	local m = model(props, name, "UtilityBox")
	local body = part(m, "Cabinet", Vector3.new(2.2, 3.2, 1.6), CFrame.new(position + Vector3.new(0, 1.6, 0)), metal, Enum.Material.Metal, true)
	local strip = part(m, "Status", Vector3.new(1.6, 0.18, 0.08), body.CFrame * CFrame.new(0, 0.8, -0.84), accent, Enum.Material.Neon, false)
	m.PrimaryPart = body
	return m
end
local function barrier(name, position, yaw, accent)
	propCount += 1
	local m = model(props, name, "StreetBarrier")
	local cf = CFrame.new(position) * CFrame.Angles(0, math.rad(yaw or 0), 0)
	local rail = part(m, "Rail", Vector3.new(5.5, 0.55, 0.55), cf * CFrame.new(0, 1.35, 0), accent or red, Enum.Material.Metal, true)
	part(m, "FootL", Vector3.new(0.55, 1.5, 1.5), cf * CFrame.new(-2.2, 0.75, 0), metal, Enum.Material.Metal, true)
	part(m, "FootR", Vector3.new(0.55, 1.5, 1.5), cf * CFrame.new(2.2, 0.75, 0), metal, Enum.Material.Metal, true)
	m.PrimaryPart = rail
	return m
end

local propLayout = {
	{"BenchN1", "bench", Vector3.new(-18, 0, -51), 0},
	{"BenchN2", "bench", Vector3.new(18, 0, -51), 180},
	{"BenchS1", "bench", Vector3.new(-18, 0, 51), 180},
	{"BenchS2", "bench", Vector3.new(18, 0, 51), 0},
	{"VendingW", "vending", Vector3.new(-32, 0, -18), 90},
	{"VendingE", "vending", Vector3.new(32, 0, 18), -90},
	{"DumpsterW", "dumpster", Vector3.new(-33, 0, 22), 0},
	{"DumpsterE", "dumpster", Vector3.new(33, 0, -22), 180},
}

for _, item in ipairs(propLayout) do
	if item[2] == "bench" then
		bench(item[1], item[3], item[4])
	elseif item[2] == "vending" then
		vendingMachine(item[1], item[3], item[1] == "VendingW" and cyan or purple, item[4])
	else
		dumpster(item[1], item[3], item[4])
	end
end
for i, position in ipairs({
	Vector3.new(-34, 0, -34),
	Vector3.new(34, 0, -34),
	Vector3.new(-34, 0, 34),
	Vector3.new(34, 0, 34),
}) do
	utilityBox("Utility" .. i, position, i % 2 == 0 and purple or cyan)
end

for i, data in ipairs({
	{Vector3.new(-38, 0, -47), 0},
	{Vector3.new(38, 0, -47), 0},
	{Vector3.new(-38, 0, 47), 0},
	{Vector3.new(38, 0, 47), 0},
}) do
	barrier("MarketBarrier" .. i, data[1], data[2], i % 2 == 0 and purple or red)
end

local function warehouse(name, origin, accent, mirrored)
	landmarkCount += 1
	local m = model(architecture, name, "HeistWarehouse")
	local signDir = mirrored and 1 or -1
	local center = CFrame.new(origin)

	local floor = part(m, "Floor", Vector3.new(20, 0.6, 18), center * CFrame.new(0, 0.3, 0), Color3.fromRGB(48, 52, 62), Enum.Material.Metal, true)
	part(m, "Roof", Vector3.new(21, 0.8, 19), center * CFrame.new(0, 11.2, 0), Color3.fromRGB(30, 34, 42), Enum.Material.Metal, true)
	part(m, "BackWall", Vector3.new(20, 11, 0.8), center * CFrame.new(0, 5.5, -signDir * 8.6), Color3.fromRGB(42, 46, 56), Enum.Material.Metal, true)
	part(m, "LeftWall", Vector3.new(0.8, 11, 18), center * CFrame.new(-9.6, 5.5, 0), Color3.fromRGB(42, 46, 56), Enum.Material.Metal, true)
	part(m, "RightWall", Vector3.new(0.8, 11, 18), center * CFrame.new(9.6, 5.5, 0), Color3.fromRGB(42, 46, 56), Enum.Material.Metal, true)

	part(m, "FrontPierL", Vector3.new(5.4, 11, 0.8), center * CFrame.new(-7.3, 5.5, signDir * 8.6), Color3.fromRGB(42, 46, 56), Enum.Material.Metal, true)
	part(m, "FrontPierR", Vector3.new(5.4, 11, 0.8), center * CFrame.new(7.3, 5.5, signDir * 8.6), Color3.fromRGB(42, 46, 56), Enum.Material.Metal, true)
	part(m, "FrontHeader", Vector3.new(9.2, 3, 0.8), center * CFrame.new(0, 9.5, signDir * 8.6), accent, Enum.Material.Metal, true, 0.08)

	local sign = part(m, "Sign", Vector3.new(8.5, 2, 0.25), center * CFrame.new(0, 8.3, signDir * 9.05), dark, Enum.Material.Metal, false)
	textSurface(sign, "HEIST DEPOT", accent, mirrored and Enum.NormalId.Back or Enum.NormalId.Front)

	for i = -1, 1 do
		local crate = part(m, "InteriorCrate" .. i, Vector3.new(2.4, 2.4, 2.4), center * CFrame.new(i * 4.2, 1.5, -signDir * 2), Color3.fromRGB(83, 64, 48), Enum.Material.WoodPlanks, true)
		crate:SetAttribute("ChaseCover", true)
	end

	local guide = part(m, "ExitGuide", Vector3.new(5, 0.12, 1), center * CFrame.new(0, 0.65, signDir * 5.5), accent, Enum.Material.Neon, false, 0.12)
	guide:SetAttribute("NavigationAccent", true)
	m.PrimaryPart = floor
	return m
end
warehouse("WestHeistDepot", Vector3.new(-54, 0, 0), red, false)
warehouse("EastHeistDepot", Vector3.new(54, 0, 0), cyan, true)

local function transitStop()
	landmarkCount += 1
	local m = model(architecture, "TransitStop", "TransitLandmark")
	local origin = Vector3.new(0, 0, 70)
	local deck = part(m, "Platform", Vector3.new(30, 0.7, 8), CFrame.new(origin + Vector3.new(0, 0.35, 0)), concrete, Enum.Material.Concrete, true)
	for _, x in ipairs({-12, 12}) do
		part(m, "Post" .. x, Vector3.new(0.45, 6, 0.45), CFrame.new(origin + Vector3.new(x, 3.2, 0)), metal, Enum.Material.Metal, true)
	end
	local roof = part(m, "Canopy", Vector3.new(29, 0.55, 7), CFrame.new(origin + Vector3.new(0, 6.1, 0)), cyan, Enum.Material.Metal, true, 0.08)
	local sign = part(m, "StationSign", Vector3.new(11, 2.2, 0.2), CFrame.new(origin + Vector3.new(0, 4.2, -3.6)), dark, Enum.Material.Metal, false)
	textSurface(sign, [[SNATCH CITY
TRANSIT]], cyan, Enum.NormalId.Front)
	bench("TransitBenchA", origin + Vector3.new(-6, 0.4, 0), 180)
	bench("TransitBenchB", origin + Vector3.new(6, 0.4, 0), 180)
	m.PrimaryPart = deck
	return m
end
transitStop()

local function elevatedRoute(name, centerX, accent)
	routeCount += 1
	local m = model(navigation, name, "ElevatedEscapeRoute")
	local platform = part(m, "Catwalk", Vector3.new(9, 0.65, 28), CFrame.new(centerX, 8, 0), Color3.fromRGB(50, 55, 67), Enum.Material.Metal, true)
	local glow = part(m, "GuideStrip", Vector3.new(0.5, 0.12, 27), platform.CFrame * CFrame.new(0, 0.39, 0), accent, Enum.Material.Neon, false, 0.08)

	local northRamp = part(m, "NorthRamp", Vector3.new(9, 0.65, 18), CFrame.new(centerX, 4.1, -21) * CFrame.Angles(math.rad(-24), 0, 0), Color3.fromRGB(55, 60, 72), Enum.Material.Metal, true)
	local southRamp = part(m, "SouthRamp", Vector3.new(9, 0.65, 18), CFrame.new(centerX, 4.1, 21) * CFrame.Angles(math.rad(24), 0, 0), Color3.fromRGB(55, 60, 72), Enum.Material.Metal, true)
	for _, z in ipairs({-13.5, 13.5}) do
		part(m, "RailL" .. z, Vector3.new(0.3, 2, 1.2), CFrame.new(centerX - 4.35, 9, z), metal, Enum.Material.Metal, true)
		part(m, "RailR" .. z, Vector3.new(0.3, 2, 1.2), CFrame.new(centerX + 4.35, 9, z), metal, Enum.Material.Metal, true)
	end

	local marker = part(m, "RouteSign", Vector3.new(7, 1.4, 0.2), CFrame.new(centerX, 10.2, 0), dark, Enum.Material.Metal, false)
	textSurface(marker, [[ESCAPE
ROUTE]], accent, Enum.NormalId.Front)
	m.PrimaryPart = platform
	return m
end

elevatedRoute("WestSkyRoute", -39, purple)
elevatedRoute("EastSkyRoute", 39, cyan)

local function alleyArch(name, position, yaw, accent, labelText)
	landmarkCount += 1
	local m = model(architecture, name, "ShortcutGate")
	local cf = CFrame.new(position) * CFrame.Angles(0, math.rad(yaw), 0)
	part(m, "Left", Vector3.new(1, 7, 1), cf * CFrame.new(-4.5, 3.5, 0), metal, Enum.Material.Metal, true)
	part(m, "Right", Vector3.new(1, 7, 1), cf * CFrame.new(4.5, 3.5, 0), metal, Enum.Material.Metal, true)
	local header = part(m, "Header", Vector3.new(10, 1, 1), cf * CFrame.new(0, 6.5, 0), accent, Enum.Material.Neon, true, 0.04)
	local sign = part(m, "Label", Vector3.new(7, 1.5, 0.2), cf * CFrame.new(0, 5, -0.6), dark, Enum.Material.Metal, false)
	textSurface(sign, labelText, accent, Enum.NormalId.Front)
	m.PrimaryPart = header
	return m
end
alleyArch("NorthShortcut", Vector3.new(0, 0, -54), 0, purple, [[NORTH
SHORTCUT]])
alleyArch("SouthShortcut", Vector3.new(0, 0, 54), 180, green, [[SOUTH
SHORTCUT]])

local function billboard(name, position, yaw, headline, subline, accent)
	landmarkCount += 1
	local m = model(architecture, name, "Billboard")
	local cf = CFrame.new(position) * CFrame.Angles(0, math.rad(yaw), 0)
	local post = part(m, "Post", Vector3.new(1, 8, 1), cf * CFrame.new(0, 4, 0), metal, Enum.Material.Metal, true)
	local board = part(m, "Board", Vector3.new(15, 6, 0.45), cf * CFrame.new(0, 9, 0), dark, Enum.Material.Metal, false)
	textSurface(board, headline .. "\n" .. subline, accent, Enum.NormalId.Front)
	m.PrimaryPart = post
	return m
end

billboard("NorthBillboard", Vector3.new(-55, 0, -78), 0, "SNATCH SMART", "STEAL • ESCAPE • SECURE", gold)
billboard("SouthBillboard", Vector3.new(55, 0, 78), 180, "BUILD THE CREW", "DISCOVER • MASTER • DOMINATE", green)

-- District signs reflect live plot ownership instead of remaining decorative.
local function gateLabel(index)
	local baseGate = connectedMap:FindFirstChild("Models") and connectedMap.Models:FindFirstChild("BaseGate" .. index)
	if not baseGate then return nil end
	local sign = baseGate:FindFirstChild("DistrictSign")
	local gui = sign and sign:FindFirstChildOfClass("SurfaceGui")
	return gui and gui:FindFirstChild("Label")
end

local function refreshDistrictSigns()
	local owners = {}
	for _, player in ipairs(Players:GetPlayers()) do
		local index = tonumber(player:GetAttribute("PlotIndex"))
		if index then owners[index] = player end
	end
	for index = 1, 6 do
		local label = gateLabel(index)
		if label then
			local owner = owners[index]
			if owner then
				label.Text = string.format("%s'S BASE\nHEIST LANE", string.upper(owner.DisplayName))
			else
				label.Text = string.format("BASE %d\nOPEN DISTRICT", index)
			end
		end
	end
end

local playerConnections = {}
local function watchPlayer(player)
	if playerConnections[player] then playerConnections[player]:Disconnect() end
	playerConnections[player] = player:GetAttributeChangedSignal("PlotIndex"):Connect(refreshDistrictSigns)
	task.defer(refreshDistrictSigns)
end

Players.PlayerAdded:Connect(watchPlayer)
Players.PlayerRemoving:Connect(function(player)
	local connection = playerConnections[player]
	if connection then connection:Disconnect() end
	playerConnections[player] = nil
	task.defer(refreshDistrictSigns)
end)

for _, player in ipairs(Players:GetPlayers()) do watchPlayer(player) end
refreshDistrictSigns()

-- Global market events recolor authored-world accents so systems visibly affect the map.
local reactive = {}
for _, descendant in ipairs(expansion:GetDescendants()) do
	if descendant:IsA("BasePart") and descendant.Material == Enum.Material.Neon then
		table.insert(reactive, descendant)
	end
end
local function eventAccent()
	local eventName = tostring(world:GetAttribute("MarketEvent") or "Calm")
	if eventName == "Rare Rush" then return purple end
	if eventName == "Payday" then return green end
	return cyan
end

local function refreshEventLighting()
	local accent = eventAccent()
	for index, neon in ipairs(reactive) do
		if neon.Parent and (index % 3 == 0) then
			neon.Color = accent
		end
	end
end

world:GetAttributeChangedSignal("MarketEvent"):Connect(refreshEventLighting)
refreshEventLighting()

expansion:SetAttribute("ExpansionVersion", 1)
expansion:SetAttribute("PropModels", propCount)
expansion:SetAttribute("Landmarks", landmarkCount)
expansion:SetAttribute("NavigationRoutes", routeCount)
expansion:SetAttribute("HasElevatedEscapeRoutes", true)
expansion:SetAttribute("HasDynamicDistrictSigns", true)
expansion:SetAttribute("HasReactiveMarketLighting", true)