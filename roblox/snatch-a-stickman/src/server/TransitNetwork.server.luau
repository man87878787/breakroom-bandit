-- Server-authoritative city transit.
-- Fast travel is intentionally disabled during active heists so teleports cannot bypass chase counterplay.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local WorldConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("WorldConfig"))

local world = workspace:WaitForChild("SnatchTheStickmanWorld")
local connectedMap = world:WaitForChild("ConnectedMap")

local old = connectedMap:FindFirstChild("CityTransit")
if old then
	old:Destroy()
end

local root = Instance.new("Folder")
root.Name = "CityTransit"
root.Parent = connectedMap

local stations = {}
local cooldownUntil = {}

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

local function text(target, value, color)
	local gui = Instance.new("SurfaceGui")
	gui.Name = "TransitLabel"
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 28
	gui.Parent = target
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = value
	label.TextColor3 = color
	label.TextStrokeTransparency = 0.65
	label.TextScaled = true
	label.TextWrapped = true
	label.Font = Enum.Font.GothamBold
	label.Parent = gui
end

local function characterRoot(player)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local humanoidRootPart = character and character:FindFirstChild("HumanoidRootPart")
	if not humanoid or humanoid.Health <= 0 or not humanoidRootPart then
		return nil
	end
	return humanoidRootPart
end

local function toast(player, message)
	local remotes = ReplicatedStorage:FindFirstChild("GameRemotes")
	local remote = remotes and remotes:FindFirstChild("Toast")
	if remote and remote:IsA("RemoteEvent") then
		remote:FireClient(player, message)
	end
end

local function heistLocked(player)
	return player:GetAttribute("CarryRarity") ~= nil
		or player:GetAttribute("CarryVictimName") ~= nil
		or player:GetAttribute("StickmanThreatened") == true
		or player:GetAttribute("CarryContested") == true
end

local function canTravel(player, sourcePart)
	if not player or player.Parent ~= Players then
		return false, "Transit unavailable."
	end
	local rootPart = characterRoot(player)
	if not rootPart then
		return false, "Respawn before using transit."
	end
	if (rootPart.Position - sourcePart.Position).Magnitude > Config.TRANSIT_MAX_TRIGGER_DISTANCE then
		return false, "Move closer to the transit kiosk."
	end
	if heistLocked(player) then
		return false, "Transit is locked during an active heist."
	end
	local now = os.clock()
	if (cooldownUntil[player] or 0) > now then
		return false, "Transit is recharging."
	end
	return true, nil
end

local function teleport(player, sourcePart, destination)
	local allowed, reason = canTravel(player, sourcePart)
	if not allowed then
		toast(player, reason)
		return
	end

	local rootPart = characterRoot(player)
	if not rootPart then
		return
	end

	cooldownUntil[player] = os.clock() + Config.TRANSIT_COOLDOWN_SECONDS
	local target = destination.Position + Vector3.new(0, Config.TRANSIT_EXIT_HEIGHT, 0)
	local look = Vector3.new(0, target.Y, 0) - target
	if look.Magnitude < 1 then
		look = Vector3.new(0, 0, -1)
	else
		look = look.Unit
	end
	player.Character:PivotTo(CFrame.lookAt(target, target + look))
	player:SetAttribute("TransitArrival", destination.Name)
	player:SetAttribute("TransitLastStop", destination.Id)
	toast(player, "Arrived at " .. destination.Name .. ".")
end

local function stationModel(stop)
	local model = Instance.new("Model")
	model.Name = stop.Id .. "Station"
	model:SetAttribute("TransitStopId", stop.Id)
	model:SetAttribute("TransitStopName", stop.Name)
	model.Parent = root

	local base = part(model, "Platform", Vector3.new(19, 0.7, 13), CFrame.new(stop.Position + Vector3.new(0, 0.35, 0)), Color3.fromRGB(38, 43, 55), Enum.Material.Metal, false)
	local canopy = part(model, "Canopy", Vector3.new(19, 0.5, 13), CFrame.new(stop.Position + Vector3.new(0, 7.6, 0)), Color3.fromRGB(48, 55, 69), Enum.Material.Metal, false)
	local beacon = part(model, "Beacon", Vector3.new(1.2, 6.2, 1.2), CFrame.new(stop.Position + Vector3.new(0, 3.4, 4.6)), stop.Accent, Enum.Material.Neon, false)
	local light = Instance.new("PointLight")
	light.Color = stop.Accent
	light.Range = 16
	light.Brightness = 1.2
	light.Shadows = false
	light.Parent = beacon

	for x = -1, 1, 2 do
		part(model, x < 0 and "CanopyPostL" or "CanopyPostR", Vector3.new(0.55, 7.2, 0.55), CFrame.new(stop.Position + Vector3.new(x * 8, 3.6, 5.2)), Color3.fromRGB(53, 59, 72), Enum.Material.Metal, false)
	end

	local sign = part(model, "StationSign", Vector3.new(15.5, 2.4, 0.3), CFrame.new(stop.Position + Vector3.new(0, 6.1, 5.9)), Color3.fromRGB(17, 20, 29), Enum.Material.Metal, false)
	text(sign, string.upper(stop.Name) .. "\nCITY TRANSIT", stop.Accent)

	model.PrimaryPart = base
	stations[stop.Id] = model
	return model
end

for _, stop in ipairs(WorldConfig.TRANSIT_STOPS) do
	stationModel(stop)
end

-- Each station gets a destination kiosk for every other stop.
for _, source in ipairs(WorldConfig.TRANSIT_STOPS) do
	local station = stations[source.Id]
	local destinations = {}
	for _, destination in ipairs(WorldConfig.TRANSIT_STOPS) do
		if destination.Id ~= source.Id then
			table.insert(destinations, destination)
		end
	end

	for index, destination in ipairs(destinations) do
		local angle = (index - 1) * (math.pi * 2 / #destinations)
		local offset = Vector3.new(math.cos(angle) * 6.1, 0, math.sin(angle) * 3.5)
		local kiosk = part(
			station,
			"To" .. destination.Id,
			Vector3.new(2.6, 3.6, 1.4),
			CFrame.new(source.Position + offset + Vector3.new(0, 1.8, 0)),
			Color3.fromRGB(24, 28, 38),
			Enum.Material.Metal,
			false
		)
		local screen = part(station, "Screen" .. destination.Id, Vector3.new(2.1, 1.3, 0.12), kiosk.CFrame * CFrame.new(0, 0.45, -0.76), destination.Accent, Enum.Material.Neon, false, 0.08)
		text(screen, destination.Name, Color3.fromRGB(255, 255, 255))

		local prompt = Instance.new("ProximityPrompt")
		prompt.Name = "TravelPrompt"
		prompt.ActionText = "Travel"
		prompt.ObjectText = destination.Name
		prompt.KeyboardKeyCode = Enum.KeyCode.E
		prompt.GamepadKeyCode = Enum.KeyCode.ButtonX
		prompt.HoldDuration = 0.35
		prompt.MaxActivationDistance = Config.TRANSIT_MAX_TRIGGER_DISTANCE - 2
		prompt.RequiresLineOfSight = true
		prompt.Parent = kiosk

		prompt.Triggered:Connect(function(player)
			teleport(player, kiosk, destination)
		end)
	end
end

Players.PlayerRemoving:Connect(function(player)
	cooldownUntil[player] = nil
end)

root:SetAttribute("TransitVersion", 1)
root:SetAttribute("StopCount", #WorldConfig.TRANSIT_STOPS)
root:SetAttribute("HeistSafe", true)
root:SetAttribute("MobilePromptCompatible", true)
