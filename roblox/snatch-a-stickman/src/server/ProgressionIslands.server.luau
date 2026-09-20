-- Server-authoritative travel and authored landmarks for the two destination islands.
-- Two destination islands plus Snatchport create a spacious three-island progression world.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local WorldConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("WorldConfig"))
local remotes = ReplicatedStorage:WaitForChild("GameRemotes")
local toastRemote = remotes:WaitForChild("Toast")

local world = workspace:WaitForChild("SnatchTheStickmanWorld")
local connectedMap = world:WaitForChild("ConnectedMap")

local old = connectedMap:FindFirstChild("ProgressionIslands")
if old then old:Destroy() end

local root = Instance.new("Folder")
root.Name = "ProgressionIslands"
root.Parent = connectedMap

local islandFolder = Instance.new("Folder")
islandFolder.Name = "Islands"
islandFolder.Parent = root

local travelFolder = Instance.new("Folder")
travelFolder.Name = "Travel"
travelFolder.Parent = root

local cooldownUntil = {}
local decorCount = 0

local COLORS = {
	Dark = Color3.fromRGB(27, 31, 42),
	Metal = Color3.fromRGB(53, 59, 72),
	Rock = Color3.fromRGB(61, 65, 72),
	Grass = Color3.fromRGB(69, 118, 77),
	Sand = Color3.fromRGB(181, 158, 108),
	Water = Color3.fromRGB(37, 104, 154),
	White = Color3.fromRGB(232, 238, 247),
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

local function model(parent, name)
	local item = Instance.new("Model")
	item.Name = name
	item.Parent = parent
	return item
end

local function neon(parent, name, size, cframe, color, transparency)
	local item = part(parent, name, size, cframe, color, Enum.Material.Neon, false, transparency or 0.08)
	item.CanQuery = false
	return item
end

local function surfaceLabel(target, text, color)
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 26
	gui.Parent = target

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = color
	label.TextStrokeTransparency = 0.68
	label.TextScaled = true
	label.TextWrapped = true
	label.Font = Enum.Font.GothamBold
	label.Parent = gui
end

local function billboard(target, titleText, subtitleText, color)
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(230, 62)
	gui.StudsOffset = Vector3.new(0, 3.4, 0)
	gui.MaxDistance = 70
	gui.AlwaysOnTop = false
	gui.Parent = target

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0.55, 0)
	title.BackgroundTransparency = 1
	title.Text = titleText
	title.TextColor3 = color
	title.TextStrokeTransparency = 0.65
	title.TextScaled = true
	title.Font = Enum.Font.GothamBold
	title.Parent = gui

	local subtitle = Instance.new("TextLabel")
	subtitle.Position = UDim2.new(0, 0, 0.56, 0)
	subtitle.Size = UDim2.new(1, 0, 0.35, 0)
	subtitle.BackgroundTransparency = 1
	subtitle.Text = subtitleText
	subtitle.TextColor3 = COLORS.White
	subtitle.TextStrokeTransparency = 0.72
	subtitle.TextScaled = true
	subtitle.Font = Enum.Font.Gotham
	subtitle.Parent = gui
end

local function makeLamp(parent, name, position, accent)
	decorCount += 1
	local m = model(parent, name)
	part(m, "Pole", Vector3.new(0.38, 6.5, 0.38), CFrame.new(position + Vector3.new(0, 3.25, 0)), COLORS.Metal, Enum.Material.Metal, false)
	local head = neon(m, "Light", Vector3.new(1.25, 0.25, 1.25), CFrame.new(position + Vector3.new(0, 6.6, 0)), accent, 0.05)
	local light = Instance.new("PointLight")
	light.Color = accent
	light.Brightness = 0.8
	light.Range = 11
	light.Shadows = false
	light.Parent = head
	return m
end

local function makeBench(parent, name, position, facing)
	decorCount += 1
	local m = model(parent, name)
	local cf = CFrame.new(position) * CFrame.Angles(0, facing, 0)
	part(m, "Seat", Vector3.new(4.8, 0.35, 1.3), cf * CFrame.new(0, 1.25, 0), Color3.fromRGB(94, 75, 56), Enum.Material.WoodPlanks, true)
	part(m, "Back", Vector3.new(4.8, 1.6, 0.3), cf * CFrame.new(0, 2.0, 0.55), Color3.fromRGB(94, 75, 56), Enum.Material.WoodPlanks, false)
	for x = -1.8, 1.8, 3.6 do
		part(m, "Leg", Vector3.new(0.28, 1.2, 0.28), cf * CFrame.new(x, 0.6, 0), COLORS.Metal, Enum.Material.Metal, true)
	end
	return m
end

local function makeCrates(parent, name, position, accent)
	decorCount += 1
	local m = model(parent, name)
	for index, offset in ipairs({
		Vector3.new(-1.3, 1.1, 0),
		Vector3.new(1.3, 1.1, 0),
		Vector3.new(0, 3.25, 0),
	}) do
		local crate = part(m, "Crate" .. index, Vector3.new(2.35, 2.1, 2.35), CFrame.new(position + offset), Color3.fromRGB(102, 72, 48), Enum.Material.WoodPlanks, true)
		if index == 3 then
			neon(m, "CargoTag", Vector3.new(1.35, 0.18, 2.38), crate.CFrame * CFrame.new(0, 0.28, 0), accent, 0.15)
		end
	end
	return m
end

local function makePlanter(parent, name, position, accent)
	decorCount += 1
	local m = model(parent, name)
	part(m, "Box", Vector3.new(3.6, 1.2, 3.6), CFrame.new(position + Vector3.new(0, 0.6, 0)), COLORS.Dark, Enum.Material.Concrete, true)
	part(m, "Plant", Vector3.new(2.5, 1.6, 2.5), CFrame.new(position + Vector3.new(0, 1.8, 0)), Color3.fromRGB(67, 139, 79), Enum.Material.Grass, false)
	neon(m, "Trim", Vector3.new(3.75, 0.12, 0.18), CFrame.new(position + Vector3.new(0, 1.1, -1.86)), accent, 0.25)
	return m
end

local function makeTerminal(parent, name, position, accent, titleText)
	decorCount += 1
	local m = model(parent, name)
	local body = part(m, "Body", Vector3.new(3.6, 4.2, 1.2), CFrame.new(position + Vector3.new(0, 2.1, 0)), COLORS.Dark, Enum.Material.Metal, true)
	neon(m, "Screen", Vector3.new(2.8, 1.5, 0.12), body.CFrame * CFrame.new(0, 0.5, -0.66), accent, 0.08)
	local sign = part(m, "Sign", Vector3.new(3.1, 0.8, 0.12), body.CFrame * CFrame.new(0, -1.1, -0.67), COLORS.Metal, Enum.Material.Metal, false)
	surfaceLabel(sign, titleText, accent)
	return m
end

local function makeBeacon(parent, name, position, accent)
	decorCount += 1
	local m = model(parent, name)
	part(m, "Base", Vector3.new(2.6, 0.7, 2.6), CFrame.new(position + Vector3.new(0, 0.35, 0)), COLORS.Metal, Enum.Material.Metal, true)
	part(m, "Stem", Vector3.new(0.5, 5.5, 0.5), CFrame.new(position + Vector3.new(0, 3.1, 0)), COLORS.Metal, Enum.Material.Metal, false)
	local lamp = neon(m, "Beacon", Vector3.new(1.1, 1.1, 1.1), CFrame.new(position + Vector3.new(0, 6.0, 0)), accent, 0.03)
	lamp.Shape = Enum.PartType.Ball
	local light = Instance.new("PointLight")
	light.Color = accent
	light.Brightness = 1
	light.Range = 15
	light.Shadows = false
	light.Parent = lamp
	return m
end

local function makeLandmark(parent, name, position, accent, tier)
	decorCount += 1
	local m = model(parent, name)
	local height = 8 + tier * 2
	part(m, "Core", Vector3.new(2.2, height, 2.2), CFrame.new(position + Vector3.new(0, height / 2, 0)), COLORS.Metal, Enum.Material.Metal, true)
	neon(m, "Spine", Vector3.new(0.38, height - 1.4, 2.35), CFrame.new(position + Vector3.new(0, height / 2, -1.15)), accent, 0.07)
	for level = 1, tier + 2 do
		local y = 1.2 + level * 2.1
		part(m, "Wing" .. level, Vector3.new(5.5 + level * 0.7, 0.35, 1.2), CFrame.new(position + Vector3.new(0, y, 0)), COLORS.Dark, Enum.Material.Metal, false)
	end
	return m
end

local function buildDecor(parent, island, tier)
	local c = island.Center
	local r = island.Radius
	makeLamp(parent, "LampA", c + Vector3.new(-r * 0.52, 0, -r * 0.12), island.Accent)
	makeLamp(parent, "LampB", c + Vector3.new(r * 0.50, 0, r * 0.08), island.Accent)
	makeBench(parent, "BenchA", c + Vector3.new(-r * 0.36, 0, r * 0.36), math.rad(28))
	makeBench(parent, "BenchB", c + Vector3.new(r * 0.32, 0, -r * 0.38), math.rad(-32))
	makeCrates(parent, "CargoStack", c + Vector3.new(-r * 0.45, 0, -r * 0.43), island.Accent)
	makePlanter(parent, "Planter", c + Vector3.new(r * 0.43, 0, r * 0.38), island.Accent)
	makeTerminal(parent, "UpgradeTerminal", c + Vector3.new(0, 0, r * 0.48), island.Accent, "REQUIRES SCORE " .. tostring(island.RequiredUpgradeScore))
	makeBeacon(parent, "DockBeacon", c + Vector3.new(0, 0, -r * 0.58), island.Accent)
	makeLandmark(parent, "IslandLandmark", c + Vector3.new(0, 0, 3), island.Accent, tier)
	makePlanter(parent, "CenterPlanter", c + Vector3.new(r * 0.30, 0, 2), island.Accent)
end

local function makeBuilding(parent, name, center, size, accent, titleText, material)
	decorCount += 1
	local m = model(parent, name)
	local width, height, depth = size.X, size.Y, size.Z
	local base = CFrame.new(center)
	part(m, "Floor", Vector3.new(width, 0.6, depth), base * CFrame.new(0, 0.3, 0), Color3.fromRGB(63, 66, 72), Enum.Material.Concrete, true)
	part(m, "Roof", Vector3.new(width, 0.7, depth), base * CFrame.new(0, height, 0), COLORS.Metal, Enum.Material.Metal, true)
	part(m, "Back", Vector3.new(width, height, 0.7), base * CFrame.new(0, height / 2, depth / 2), COLORS.Dark, material or Enum.Material.Concrete, true)
	part(m, "Left", Vector3.new(0.7, height, depth), base * CFrame.new(-width / 2, height / 2, 0), COLORS.Dark, material or Enum.Material.Concrete, true)
	part(m, "Right", Vector3.new(0.7, height, depth), base * CFrame.new(width / 2, height / 2, 0), COLORS.Dark, material or Enum.Material.Concrete, true)
	part(m, "FrontL", Vector3.new(width * 0.32, height, 0.7), base * CFrame.new(-width * 0.34, height / 2, -depth / 2), COLORS.Dark, material or Enum.Material.Concrete, true)
	part(m, "FrontR", Vector3.new(width * 0.32, height, 0.7), base * CFrame.new(width * 0.34, height / 2, -depth / 2), COLORS.Dark, material or Enum.Material.Concrete, true)
	local sign = part(m, "Sign", Vector3.new(width * 0.52, 2, 0.18), base * CFrame.new(0, height * 0.72, -depth / 2 - 0.4), Color3.fromRGB(18, 21, 29), Enum.Material.Metal, false)
	surfaceLabel(sign, titleText, accent)
	neon(m, "Trim", Vector3.new(width * 0.72, 0.16, 0.16), base * CFrame.new(0, height - 0.4, -depth / 2 - 0.42), accent, 0.18)
	return m
end

local function makeCrane(parent, center, accent)
	decorCount += 1
	local m = model(parent, "FreightCrane")
	part(m, "Tower", Vector3.new(2.4, 24, 2.4), CFrame.new(center + Vector3.new(0, 12, 0)), COLORS.Metal, Enum.Material.Metal, true)
	part(m, "Boom", Vector3.new(32, 1.4, 1.4), CFrame.new(center + Vector3.new(10, 23, 0)), COLORS.Metal, Enum.Material.Metal, false)
	part(m, "Counterweight", Vector3.new(5, 3.2, 3.2), CFrame.new(center + Vector3.new(-7, 21.8, 0)), Color3.fromRGB(80, 84, 90), Enum.Material.Metal, false)
	part(m, "Cable", Vector3.new(0.22, 11, 0.22), CFrame.new(center + Vector3.new(22, 16.8, 0)), Color3.fromRGB(24, 26, 30), Enum.Material.Metal, false)
	local hook = neon(m, "Hook", Vector3.new(1.2, 1.2, 1.2), CFrame.new(center + Vector3.new(22, 11, 0)), accent, 0.12)
	hook.Shape = Enum.PartType.Ball
	return m
end

local function makeLookout(parent, center, accent)
	decorCount += 1
	local m = model(parent, "CrownLookout")
	part(m, "Tower", Vector3.new(8, 22, 8), CFrame.new(center + Vector3.new(0, 11, 0)), Color3.fromRGB(58, 61, 72), Enum.Material.Concrete, true)
	part(m, "Deck", Vector3.new(20, 0.8, 20), CFrame.new(center + Vector3.new(0, 20.5, 0)), COLORS.Metal, Enum.Material.Metal, true)
	for _, offset in ipairs({
		Vector3.new(-8.8, 22, -8.8), Vector3.new(8.8, 22, -8.8),
		Vector3.new(-8.8, 22, 8.8), Vector3.new(8.8, 22, 8.8),
	}) do
		part(m, "RailPost", Vector3.new(0.45, 3.4, 0.45), CFrame.new(center + offset), COLORS.Metal, Enum.Material.Metal, false)
	end
	local crown = neon(m, "CrownLight", Vector3.new(4.5, 0.55, 4.5), CFrame.new(center + Vector3.new(0, 24.2, 0)), accent, 0.05)
	local light = Instance.new("PointLight")
	light.Color = accent
	light.Brightness = 1.1
	light.Range = 22
	light.Shadows = false
	light.Parent = crown
	return m
end

local function makeFerry(parent, center, accent)
	decorCount += 1
	local m = model(parent, "HarborFerry")
	part(m, "Hull", Vector3.new(28, 3.2, 10), CFrame.new(center + Vector3.new(0, 0.6, 0)), Color3.fromRGB(43, 50, 61), Enum.Material.Metal, false)
	part(m, "Deck", Vector3.new(24, 0.7, 8), CFrame.new(center + Vector3.new(0, 2.4, 0)), Color3.fromRGB(104, 86, 66), Enum.Material.WoodPlanks, false)
	part(m, "Cabin", Vector3.new(8, 5, 7), CFrame.new(center + Vector3.new(-5, 5.1, 0)), Color3.fromRGB(220, 224, 229), Enum.Material.Metal, false)
	local glass = part(m, "Windshield", Vector3.new(0.2, 2.4, 5.4), CFrame.new(center + Vector3.new(-0.9, 5.5, 0)), Color3.fromRGB(93, 164, 196), Enum.Material.Glass, false, 0.25)
	glass.CanQuery = false
	neon(m, "Stripe", Vector3.new(24.4, 0.22, 0.22), CFrame.new(center + Vector3.new(0, 1.1, -5.1)), accent, 0.08)
	return m
end

local function makeAirTaxi(parent, center, accent)
	decorCount += 1
	local m = model(parent, "HarborAirTaxi")
	part(m, "Body", Vector3.new(15, 3.8, 5.5), CFrame.new(center + Vector3.new(0, 4, 0)), Color3.fromRGB(60, 65, 78), Enum.Material.Metal, false)
	part(m, "Wing", Vector3.new(7.5, 0.55, 20), CFrame.new(center + Vector3.new(0, 4.2, 0)), Color3.fromRGB(48, 52, 63), Enum.Material.Metal, false)
	part(m, "Tail", Vector3.new(4, 4.5, 0.7), CFrame.new(center + Vector3.new(-6.2, 6.2, 0)), Color3.fromRGB(48, 52, 63), Enum.Material.Metal, false)
	local cockpit = part(m, "Cockpit", Vector3.new(4.8, 2.4, 5.1), CFrame.new(center + Vector3.new(3.7, 5.1, 0)), Color3.fromRGB(105, 177, 214), Enum.Material.Glass, false, 0.22)
	cockpit.CanQuery = false
	neon(m, "RunningLightL", Vector3.new(0.4, 0.4, 0.4), CFrame.new(center + Vector3.new(0, 4.5, -10)), accent, 0.03)
	neon(m, "RunningLightR", Vector3.new(0.4, 0.4, 0.4), CFrame.new(center + Vector3.new(0, 4.5, 10)), accent, 0.03)
	return m
end

local function buildIslandArchitecture(parent, island, tier)
	local c = island.Center
	if island.Id == "Ironwake" then
		makeBuilding(parent, "IronwakeFoundry", c + Vector3.new(-42, 0, 24), Vector3.new(34, 13, 24), island.Accent, "IRONWAKE FOUNDRY", Enum.Material.Brick)
		makeBuilding(parent, "FreightHouse", c + Vector3.new(48, 0, 18), Vector3.new(28, 11, 22), island.Accent, "FREIGHT HOUSE", Enum.Material.Metal)
		makeCrane(parent, c + Vector3.new(12, 0, 68), island.Accent)
		part(parent, "FreightRoad", Vector3.new(112, 0.28, 10), CFrame.new(c + Vector3.new(0, 0.08, 12)), Color3.fromRGB(45, 48, 55), Enum.Material.Asphalt, true)
	else
		makeBuilding(parent, "CrownHall", c + Vector3.new(-38, 0, 22), Vector3.new(32, 13, 24), island.Accent, "CROWN HALL", Enum.Material.Marble)
		makeBuilding(parent, "ArchiveHouse", c + Vector3.new(44, 0, 28), Vector3.new(26, 10, 20), island.Accent, "RARE ARCHIVE", Enum.Material.Concrete)
		makeLookout(parent, c + Vector3.new(8, 0, 72), island.Accent)
		part(parent, "CrownWalk", Vector3.new(116, 0.28, 9), CFrame.new(c + Vector3.new(0, 0.08, 14)), Color3.fromRGB(63, 65, 76), Enum.Material.Pavement, true)
	end
end

local function buildIsland(island, tier)
	local m = model(islandFolder, island.Id)
	m:SetAttribute("IslandId", island.Id)
	m:SetAttribute("DisplayName", island.Name)
	m:SetAttribute("RequiredUpgradeScore", island.RequiredUpgradeScore)
	m:SetAttribute("TravelCost", island.TravelCost)

	-- Terrain owns the coastline. Keep only a small authored arrival plaza here.
	part(
		m,
		"ArrivalPlaza",
		Vector3.new(28, 0.45, 22),
		CFrame.new(island.Center + Vector3.new(0, 0.18, -island.Radius * 0.22)),
		Color3.fromRGB(56, 61, 72),
		Enum.Material.Concrete,
		true
	)

	local sign = part(m, "IslandSign", Vector3.new(17, 4.8, 0.5), CFrame.new(island.Center + Vector3.new(0, 6.2, -island.Radius * 0.58)), COLORS.Dark, Enum.Material.Metal, false)
	surfaceLabel(
		sign,
		string.format("%s\n%s  •  UPGRADE SCORE %d", string.upper(island.Name), string.upper(island.TravelMode), island.RequiredUpgradeScore),
		island.Accent
	)

	local decor = Instance.new("Folder")
	decor.Name = "Decor"
	decor.Parent = m
	buildDecor(decor, island, tier)
	buildIslandArchitecture(decor, island, tier)
	return m
end

for index, island in ipairs(WorldConfig.PROGRESSION_ISLANDS) do
	buildIsland(island, index)
end

local function toast(player, message)
	if player and player.Parent == Players then
		toastRemote:FireClient(player, message)
	end
end

local function characterRoot(player)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local rootPart = character and character:FindFirstChild("HumanoidRootPart")
	if humanoid and humanoid.Health > 0 and rootPart then
		return rootPart
	end
	return nil
end

local function upgradeScore(player)
	local profile = player:FindFirstChild("Profile")
	if not profile then return 0 end
	local total = 0
	for _, name in ipairs({"IncomeLevel", "CapacityLevel", "ShieldLevel"}) do
		local value = profile:FindFirstChild(name)
		if value and value:IsA("IntValue") then total += value.Value end
	end
	return total
end

local function heistLocked(player)
	return player:GetAttribute("CarryRarity") ~= nil
		or player:GetAttribute("CarryVictimName") ~= nil
		or player:GetAttribute("StickmanThreatened") == true
		or player:GetAttribute("CarryContested") == true
end

local function canTravel(player, source, island, free)
	if player.Parent ~= Players or player:GetAttribute("DataReady") ~= true then
		return false, "Your profile is still loading."
	end
	local rootPart = characterRoot(player)
	if not rootPart then return false, "Respawn before traveling." end
	if (rootPart.Position - source.Position).Magnitude > WorldConfig.ISLAND_TRAVEL.MaxPromptDistance + 3 then
		return false, "Move closer to the travel NPC."
	end
	if heistLocked(player) then
		return false, "Finish the active heist before leaving the island."
	end
	if (cooldownUntil[player] or 0) > os.clock() then
		return false, "Travel is recharging."
	end
	if not free and island then
		local score = upgradeScore(player)
		if score < island.RequiredUpgradeScore then
			return false, string.format("Upgrade score %d required. You have %d.", island.RequiredUpgradeScore, score)
		end
		local stats = player:FindFirstChild("leaderstats")
		local coins = stats and stats:FindFirstChild("Coins")
		if not coins or coins.Value < island.TravelCost then
			return false, string.format("You need $%d for that ride.", island.TravelCost)
		end
	end
	return true, nil
end

local function travel(player, source, island, destination, free)
	local allowed, reason = canTravel(player, source, island, free)
	if not allowed then
		toast(player, reason)
		return
	end

	if not free and island then
		local stats = player:FindFirstChild("leaderstats")
		local coins = stats and stats:FindFirstChild("Coins")
		if not coins or coins.Value < island.TravelCost then return end
		coins.Value -= island.TravelCost
	end

	cooldownUntil[player] = os.clock() + WorldConfig.ISLAND_TRAVEL.CooldownSeconds
	local character = player.Character
	if not character then return end
	character:PivotTo(CFrame.new(destination + Vector3.new(0, 4, 0)))
	player:SetAttribute("IslandTravelArrival", island and island.Name or "Snatchport")
	player:SetAttribute("IslandTravelPulse", (player:GetAttribute("IslandTravelPulse") or 0) + 1)
	toast(player, island and ("Arrived at " .. island.Name .. ".") or "Returned to Snatchport.")
end

local function travelNPC(parent, name, role, position, accent, action, objectText, callback)
	local m = model(parent, name)
	local torso = part(m, "Torso", Vector3.new(1.15, 3.5, 0.75), CFrame.new(position + Vector3.new(0, 3.6, 0)), COLORS.Dark, Enum.Material.SmoothPlastic, false)
	local head = part(m, "Head", Vector3.new(1.75, 1.75, 1.75), CFrame.new(position + Vector3.new(0, 6.2, 0)), accent, Enum.Material.SmoothPlastic, false)
	head.Shape = Enum.PartType.Ball
	for _, info in ipairs({
		{"ArmL", Vector3.new(-0.95, 3.7, 0), Vector3.new(0.38, 3.0, 0.38)},
		{"ArmR", Vector3.new(0.95, 3.7, 0), Vector3.new(0.38, 3.0, 0.38)},
		{"LegL", Vector3.new(-0.38, 1.5, 0), Vector3.new(0.5, 3.0, 0.5)},
		{"LegR", Vector3.new(0.38, 1.5, 0), Vector3.new(0.5, 3.0, 0.5)},
	}) do
		part(m, info[1], info[3], CFrame.new(position + info[2]), info[1]:find("Arm") and accent or COLORS.Metal, Enum.Material.SmoothPlastic, false)
	end
	billboard(head, name, role, accent)

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = action
	prompt.ObjectText = objectText
	prompt.HoldDuration = 0.25
	prompt.MaxActivationDistance = WorldConfig.ISLAND_TRAVEL.MaxPromptDistance
	prompt.RequiresLineOfSight = true
	prompt.Parent = torso
	prompt.Triggered:Connect(function(player)
		callback(player, torso)
	end)
	return m
end

local hub = model(travelFolder, "CityHarbor")
local hubPosition = WorldConfig.ISLAND_TRAVEL.HubPosition
part(hub, "Dock", Vector3.new(58, 0.8, 18), CFrame.new(hubPosition + Vector3.new(0, 0.4, 0)), Color3.fromRGB(73, 62, 50), Enum.Material.WoodPlanks, true)
part(hub, "FerryPier", Vector3.new(12, 0.8, 72), CFrame.new(hubPosition + Vector3.new(-20, 0.35, 34)), Color3.fromRGB(73, 62, 50), Enum.Material.WoodPlanks, true)
part(hub, "AirPad", Vector3.new(25, 0.5, 25), CFrame.new(hubPosition + Vector3.new(22, 0.2, 12)), Color3.fromRGB(53, 57, 67), Enum.Material.Concrete, true)
local hubSign = part(hub, "Sign", Vector3.new(16, 3.5, 0.4), CFrame.new(hubPosition + Vector3.new(0, 5.3, -6.4)), COLORS.Dark, Enum.Material.Metal, false)
surfaceLabel(hubSign, "SNATCHPORT HARBOR\nFERRY • AIR TAXI", Color3.fromRGB(114, 205, 255))
makeFerry(hub, hubPosition + Vector3.new(-20, -5, 72), WorldConfig.PROGRESSION_ISLANDS[1].Accent)
makeAirTaxi(hub, hubPosition + Vector3.new(22, 0, 12), WorldConfig.PROGRESSION_ISLANDS[2].Accent)

local vendors = {
	{Name = "Marlow", Role = "Ironwake Ferry Captain", Offset = Vector3.new(-10, 0, 0)},
	{Name = "Astra", Role = "Crownreach Air Taxi Pilot", Offset = Vector3.new(10, 0, 0)},
}

for index, island in ipairs(WorldConfig.PROGRESSION_ISLANDS) do
	local vendor = vendors[index]
	travelNPC(
		hub,
		vendor.Name,
		vendor.Role,
		hubPosition + vendor.Offset,
		island.Accent,
		"Travel $" .. tostring(island.TravelCost),
		island.Name .. " • score " .. tostring(island.RequiredUpgradeScore),
		function(player, source)
			travel(player, source, island, island.Center, false)
		end
	)

	local returnPosition = island.Center + Vector3.new(0, 0, -island.Radius * 0.60)
	travelNPC(
		travelFolder,
		island.Id .. " Guide",
		"Return Guide",
		returnPosition,
		island.Accent,
		"Return Free",
		"Snatchport",
		function(player, source)
			travel(player, source, nil, WorldConfig.ISLAND_TRAVEL.ReturnPosition, true)
		end
	)
end

Players.PlayerAdded:Connect(function(player)
	player:SetAttribute("IslandTravelArrival", "")
	player:SetAttribute("IslandTravelPulse", 0)
end)

Players.PlayerRemoving:Connect(function(player)
	cooldownUntil[player] = nil
end)

root:SetAttribute("IslandCount", 1 + #WorldConfig.PROGRESSION_ISLANDS)
root:SetAttribute("DecorModelCount", decorCount)
root:SetAttribute("TravelIsServerAuthoritative", true)
root:SetAttribute("UsesPhysicsVehicles", false)
