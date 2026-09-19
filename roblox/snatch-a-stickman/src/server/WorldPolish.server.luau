local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
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
Lighting.ClockTime = 18.5
Lighting.Brightness = 2
Lighting.Ambient = Color3.fromRGB(58, 64, 82)
Lighting.OutdoorAmbient = Color3.fromRGB(42, 48, 65)
Lighting.EnvironmentDiffuseScale = 0.45
Lighting.EnvironmentSpecularScale = 0.65

local atmosphere = Lighting:FindFirstChild("SnatchAtmosphere") or Instance.new("Atmosphere")
atmosphere.Name = "SnatchAtmosphere"
atmosphere.Density = 0.18
atmosphere.Offset = 0.1
atmosphere.Color = Color3.fromRGB(180, 194, 230)
atmosphere.Decay = Color3.fromRGB(64, 72, 105)
atmosphere.Glare = 0.05
atmosphere.Haze = 1.2
atmosphere.Parent = Lighting

local bloom = Lighting:FindFirstChild("SnatchBloom") or Instance.new("BloomEffect")
bloom.Name = "SnatchBloom"
bloom.Intensity = 0.35
bloom.Size = 24
bloom.Threshold = 1.6
bloom.Parent = Lighting

local color = Lighting:FindFirstChild("SnatchColor") or Instance.new("ColorCorrectionEffect")
color.Name = "SnatchColor"
color.Brightness = 0.01
color.Contrast = 0.08
color.Saturation = 0.05
color.TintColor = Color3.fromRGB(235, 240, 255)
color.Parent = Lighting

-- Perimeter rails make the playable space feel intentional and prevent accidental falls.
local railColor = Color3.fromRGB(48, 55, 72)
part("NorthRail", Vector3.new(180, 3, 1.5), CFrame.new(0, 1, -89), railColor, Enum.Material.Metal, true)
part("SouthRail", Vector3.new(180, 3, 1.5), CFrame.new(0, 1, 89), railColor, Enum.Material.Metal, true)
part("WestRail", Vector3.new(1.5, 3, 180), CFrame.new(-89, 1, 0), railColor, Enum.Material.Metal, true)
part("EastRail", Vector3.new(1.5, 3, 180), CFrame.new(89, 1, 0), railColor, Enum.Material.Metal, true)

-- Market outline improves navigation at a glance.
local marketEdge = Color3.fromRGB(74, 217, 148)
part("MarketEdgeN", Vector3.new(36, 0.25, 0.45), CFrame.new(0, 0.62, -37), marketEdge, Enum.Material.Neon, false)
part("MarketEdgeS", Vector3.new(36, 0.25, 0.45), CFrame.new(0, 0.62, 37), marketEdge, Enum.Material.Neon, false)
part("MarketEdgeW", Vector3.new(0.45, 0.25, 74), CFrame.new(-17, 0.62, 0), marketEdge, Enum.Material.Neon, false)
part("MarketEdgeE", Vector3.new(0.45, 0.25, 74), CFrame.new(17, 0.62, 0), marketEdge, Enum.Material.Neon, false)

-- A vertical title board makes the game identity visible from every base.
local titleBoard = part(
	"TitleBoard",
	Vector3.new(30, 8, 1),
	CFrame.new(0, 7, -40),
	Color3.fromRGB(17, 20, 29),
	Enum.Material.Metal,
	false
)
local titleGui = Instance.new("SurfaceGui")
titleGui.Face = Enum.NormalId.Front
titleGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
titleGui.PixelsPerStud = 30
titleGui.Parent = titleBoard

local title = Instance.new("TextLabel")
title.Size = UDim2.fromScale(1, 1)
title.BackgroundTransparency = 1
title.Text = string.upper(Config.GAME_NAME)
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextStrokeTransparency = 0.65
title.TextScaled = true
title.Font = Enum.Font.GothamBlack
title.Parent = titleGui

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
		Enum.Material.SmoothPlastic,
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
