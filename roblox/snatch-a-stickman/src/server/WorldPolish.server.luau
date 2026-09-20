local Lighting = game:GetService("Lighting")

local world = workspace:WaitForChild("SnatchTheStickmanWorld")

local old = world:FindFirstChild("LaunchPolish")
if old then
	old:Destroy()
end

local polish = Instance.new("Folder")
polish.Name = "LaunchPolish"
polish.Parent = world

local function part(name, size, cframe, color, material, canCollide)
	local item = Instance.new("Part")
	item.Name = name
	item.Size = size
	item.CFrame = cframe
	item.Anchored = true
	item.CanCollide = canCollide == true
	item.CanTouch = false
	item.CanQuery = true
	item.TopSurface = Enum.SurfaceType.Smooth
	item.BottomSurface = Enum.SurfaceType.Smooth
	item.Color = color
	item.Material = material or Enum.Material.SmoothPlastic
	item.Parent = polish
	return item
end

-- A readable, high-contrast evening palette gives rare stickmen and pads more visual punch.
Lighting.ClockTime = 17.15
Lighting.Brightness = 2.15
Lighting.Ambient = Color3.fromRGB(62, 68, 82)
Lighting.OutdoorAmbient = Color3.fromRGB(72, 79, 96)
Lighting.EnvironmentDiffuseScale = 0.62
Lighting.EnvironmentSpecularScale = 0.72

local atmosphere = Lighting:FindFirstChild("SnatchAtmosphere") or Instance.new("Atmosphere")
atmosphere.Name = "SnatchAtmosphere"
atmosphere.Density = 0.12
atmosphere.Offset = 0.08
atmosphere.Color = Color3.fromRGB(202, 218, 235)
atmosphere.Decay = Color3.fromRGB(86, 105, 132)
atmosphere.Glare = 0.02
atmosphere.Haze = 0.72
atmosphere.Parent = Lighting

local bloom = Lighting:FindFirstChild("SnatchBloom") or Instance.new("BloomEffect")
bloom.Name = "SnatchBloom"
bloom.Intensity = 0.16
bloom.Size = 18
bloom.Threshold = 1.9
bloom.Parent = Lighting

local color = Lighting:FindFirstChild("SnatchColor") or Instance.new("ColorCorrectionEffect")
color.Name = "SnatchColor"
color.Brightness = 0.01
color.Contrast = 0.045
color.Saturation = 0.035
color.TintColor = Color3.fromRGB(244, 247, 255)
color.Parent = Lighting

-- Market outline improves navigation at a glance.
local marketEdge = Color3.fromRGB(74, 217, 148)
part("MarketEdgeN", Vector3.new(36, 0.25, 0.45), CFrame.new(0, 0.62, -37), marketEdge, Enum.Material.Neon, false)
part("MarketEdgeS", Vector3.new(36, 0.25, 0.45), CFrame.new(0, 0.62, 37), marketEdge, Enum.Material.Neon, false)
part("MarketEdgeW", Vector3.new(0.45, 0.25, 74), CFrame.new(-17, 0.62, 0), marketEdge, Enum.Material.Neon, false)
part("MarketEdgeE", Vector3.new(0.45, 0.25, 74), CFrame.new(17, 0.62, 0), marketEdge, Enum.Material.Neon, false)

-- Lit paths connect every base to the market, clarifying the raid/escape routes.
for plotIndex = 1, 6 do
	local plot = world:WaitForChild("Plot" .. tostring(plotIndex))
	local floor = plot:WaitForChild("Floor")
	local start = Vector3.new(floor.Position.X, 0.12, floor.Position.Z)
	local target = Vector3.new(0, 0.12, 0)
	local delta = target - start
	local length = math.max(8, delta.Magnitude - 22)
	local direction = delta.Unit
	local midpoint = start + direction * ((delta.Magnitude - 8) * 0.5)
	local path = part(
		"Plot" .. tostring(plotIndex) .. "Path",
		Vector3.new(7, 0.16, length),
		CFrame.lookAt(midpoint, Vector3.new(0, midpoint.Y, 0)),
		Color3.fromRGB(37, 42, 55),
		Enum.Material.Asphalt,
		false
	)
	path.Transparency = 0.12

	local marker = part(
		"Plot" .. tostring(plotIndex) .. "Marker",
		Vector3.new(0.4, 0.2, length),
		path.CFrame * CFrame.new(0, 0.12, 0),
		Color3.fromRGB(90, 112, 255),
		Enum.Material.Neon,
		false
	)
	marker.Transparency = 0.15
end

-- Market lamp posts create landmarks without external assets.
local lampPositions = {
	Vector3.new(-21, 0, -31), Vector3.new(21, 0, -31),
	Vector3.new(-21, 0, -10), Vector3.new(21, 0, -10),
	Vector3.new(-21, 0, 10), Vector3.new(21, 0, 10),
	Vector3.new(-21, 0, 31), Vector3.new(21, 0, 31),
}

for index, position in ipairs(lampPositions) do
	part("LampPost" .. index, Vector3.new(0.65, 8, 0.65), CFrame.new(position + Vector3.new(0, 4, 0)), Color3.fromRGB(44, 49, 63), Enum.Material.Metal, false)
	local lamp = part("Lamp" .. index, Vector3.new(1.6, 0.45, 1.6), CFrame.new(position + Vector3.new(0, 8, 0)), Color3.fromRGB(118, 180, 255), Enum.Material.Neon, false)
	local light = Instance.new("PointLight")
	light.Brightness = 1.35
	light.Range = 16
	light.Color = lamp.Color
	light.Shadows = false
	light.Parent = lamp
end

-- Small center beacon gives players an obvious rendezvous point.
local beacon = part("MarketBeacon", Vector3.new(2.5, 0.7, 2.5), CFrame.new(0, 0.85, 0), Color3.fromRGB(255, 112, 190), Enum.Material.Neon, false)
beacon.Shape = Enum.PartType.Cylinder
beacon.CFrame = beacon.CFrame * CFrame.Angles(0, 0, math.rad(90))
