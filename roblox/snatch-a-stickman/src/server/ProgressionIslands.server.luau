-- Three lightweight progression islands with server-authoritative travel.
-- The islands add space and progression without turning the center city into visual clutter.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Terrain = workspace.Terrain

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

local function disc(parent, name, center, diameter, height, color, material, y)
	local item = part(
		parent,
		name,
		Vector3.new(height, diameter, diameter),
		CFrame.new(center + Vector3.new(0, y, 0)) * CFrame.Angles(0, 0, math.rad(90)),
		color,
		material,
		true
	)
	item.Shape = Enum.PartType.Cylinder
	return item
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
	makeTerminal(parent, "UpgradeTerminal", c + Vector3.new(0, 0, r * 0.48), island.Accent, "UPGRADE TIER " .. tostring(tier))
	makeBeacon(parent, "DockBeacon", c + Vector3.new(0, 0, -r * 0.58), island.Accent)
	makeLandmark(parent, "IslandLandmark", c + Vector3.new(0, 0, 3), island.Accent, tier)
	makePlanter(parent, "CenterPlanter", c + Vector3.new(r * 0.30, 0, 2), island.Accent)
end

local function buildIsland(island, tier)
	local m = model(islandFolder, island.Id)
	m:SetAttribute("IslandId", island.Id)
	m:SetAttribute("DisplayName", island.Name)
	m:SetAttribute("RequiredUpgradeScore", island.RequiredUpgradeScore)
	m:SetAttribute("TravelCost", island.TravelCost)

	disc(m, "RockBase", island.Center, island.Radius * 2.15, 7, COLORS.Rock, Enum.Material.Slate, -3.4)
	disc(m, "Ground", island.Center, island.Radius * 1.95, 2.1, tier == 2 and COLORS.Metal or COLORS.Grass, tier == 2 and Enum.Material.Metal or Enum.Material.Grass, -0.95)
	disc(m, "WalkRing", island.Center, island.Radius * 1.15, 0.45, Color3.fromRGB(65, 70, 82), Enum.Material.Concrete, 0.04)

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
	return m
end

-- A shallow water field visually separates the central city from the progression islands.
Terrain:FillBlock(CFrame.new(0, -6, 115), Vector3.new(600, 10, 470), Enum.Material.Water)

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
	player:SetAttribute("IslandTravelArrival", island and island.Name or "Stickman City")
	player:SetAttribute("IslandTravelPulse", (player:GetAttribute("IslandTravelPulse") or 0) + 1)
	toast(player, island and ("Arrived at " .. island.Name .. ".") or "Returned to Stickman City.")
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
part(hub, "Dock", Vector3.new(32, 0.8, 15), CFrame.new(hubPosition + Vector3.new(0, 0.4, 0)), Color3.fromRGB(73, 62, 50), Enum.Material.WoodPlanks, true)
local hubSign = part(hub, "Sign", Vector3.new(16, 3.5, 0.4), CFrame.new(hubPosition + Vector3.new(0, 5.3, -6.4)), COLORS.Dark, Enum.Material.Metal, false)
surfaceLabel(hubSign, "ISLAND HARBOR\nRIDES SCALE WITH YOUR UPGRADES", Color3.fromRGB(114, 205, 255))

local vendors = {
	{Name = "Bo", Role = "Ferry Captain", Offset = Vector3.new(-9, 0, 0)},
	{Name = "Rook", Role = "Cargo Shuttle Operator", Offset = Vector3.new(0, 0, 0)},
	{Name = "Nova", Role = "Air Taxi Pilot", Offset = Vector3.new(9, 0, 0)},
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
		"Stickman City",
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

root:SetAttribute("IslandCount", #WorldConfig.PROGRESSION_ISLANDS)
root:SetAttribute("DecorModelCount", decorCount)
root:SetAttribute("TravelIsServerAuthoritative", true)
root:SetAttribute("UsesPhysicsVehicles", false)
