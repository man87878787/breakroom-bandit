-- Authored base-neighborhood traversal layer.
-- Gives every base two readable approach/escape choices without changing combat authority.

local world = workspace:WaitForChild("SnatchTheStickmanWorld")
local connectedMap = world:WaitForChild("ConnectedMap")

local old = connectedMap:FindFirstChild("BaseNeighborhoods")
if old then old:Destroy() end

local root = Instance.new("Folder")
root.Name = "BaseNeighborhoods"
root.Parent = connectedMap

local COLORS = {
	Color3.fromRGB(75, 198, 255), Color3.fromRGB(114, 238, 151),
	Color3.fromRGB(225, 120, 255), Color3.fromRGB(255, 183, 78),
	Color3.fromRGB(110, 132, 255), Color3.fromRGB(255, 105, 145),
}

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

local function label(target, text, color)
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Top
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 24
	gui.Parent = target
	local t = Instance.new("TextLabel")
	t.Size = UDim2.fromScale(1, 1)
	t.BackgroundTransparency = 1
	t.Text = text
	t.TextColor3 = color
	t.TextStrokeTransparency = 0.7
	t.TextScaled = true
	t.Font = Enum.Font.GothamBlack
	t.Parent = gui
end

local function buildNeighborhood(index, plot)
	local floor = plot:WaitForChild("Floor")
	local accent = COLORS[index]
	local model = Instance.new("Model")
	model.Name = "BaseNeighborhood" .. index
	model:SetAttribute("PlotIndex", index)
	model:SetAttribute("RouteCount", 2)
	model.Parent = root

	local origin = floor.Position
	local inward = (Vector3.new(0, origin.Y, 0) - origin).Unit
	local right = Vector3.new(-inward.Z, 0, inward.X)
	local forwardCF = CFrame.lookAt(origin, origin + inward)

	-- Ground route: broad, fast-to-read lane with waist-high cover off the hook sightline.
	local laneCenter = origin + inward * 24 - right * 11
	local lane = part(model, "GroundHeistLane", Vector3.new(7, 0.16, 25),
		CFrame.lookAt(laneCenter, laneCenter + inward), Color3.fromRGB(38, 43, 54), Enum.Material.Asphalt, false)
	local stripe = part(model, "GroundLaneGuide", Vector3.new(0.45, 0.08, 23),
		lane.CFrame * CFrame.new(0, 0.12, 0), accent, Enum.Material.Neon, false, 0.18)
	label(stripe, "FAST LANE", Color3.fromRGB(235, 245, 255))

	for offset = -8, 8, 8 do
		local coverPos = laneCenter + inward * offset - right * 4.4
		part(model, "LaneCover" .. tostring(offset), Vector3.new(3.2, 2.4, 1.2),
			CFrame.lookAt(coverPos + Vector3.new(0, 1.2, 0), coverPos + inward),
			Color3.fromRGB(55, 61, 74), Enum.Material.Metal, true)
	end

	-- Elevated route: longer but gives a lateral interception/escape option.
	local skyCenter = origin + inward * 15 + right * 14 + Vector3.new(0, 5.5, 0)
	local deck = part(model, "SkyDeck", Vector3.new(8, 0.65, 24),
		CFrame.lookAt(skyCenter, skyCenter + inward), Color3.fromRGB(49, 55, 68), Enum.Material.Metal, true)
	part(model, "SkyGuide", Vector3.new(0.5, 0.1, 22), deck.CFrame * CFrame.new(0, 0.39, 0), accent, Enum.Material.Neon, false, 0.1)

	local rampLength = 14
	for _, sign in ipairs({-1, 1}) do
		local endOffset = inward * (sign * 17)
		local rampCenter = skyCenter + endOffset - Vector3.new(0, 2.7, 0)
		local pitch = math.rad(sign * -23)
		local rampCF = CFrame.lookAt(rampCenter, rampCenter + inward) * CFrame.Angles(pitch, 0, 0)
		part(model, sign < 0 and "EntryRamp" or "ExitRamp", Vector3.new(8, 0.65, rampLength),
			rampCF, Color3.fromRGB(53, 59, 72), Enum.Material.Metal, true)
	end

	-- Non-colliding rails communicate the route edge without trapping or blocking hook rays.
	for _, side in ipairs({-1, 1}) do
		local railCF = deck.CFrame * CFrame.new(side * 3.85, 1.05, 0)
		part(model, side < 0 and "LeftRail" or "RightRail", Vector3.new(0.22, 1.8, 24),
			railCF, accent, Enum.Material.Neon, false, 0.25)
	end

	local markerPos = origin + inward * 19 + right * 2
	local marker = part(model, "RouteChoiceMarker", Vector3.new(15, 0.12, 5),
		CFrame.lookAt(markerPos + Vector3.new(0, 0.1, 0), markerPos + inward),
		Color3.fromRGB(27, 31, 41), Enum.Material.SmoothPlastic, false, 0.08)
	label(marker, "FAST LANE   /   SKY ROUTE", accent)

	model:SetAttribute("GroundRouteRole", "FastDirect")
	model:SetAttribute("SkyRouteRole", "LongIntercept")
end

for index = 1, 6 do
	buildNeighborhood(index, world:WaitForChild("Plot" .. index))
end

root:SetAttribute("NeighborhoodVersion", 1)
root:SetAttribute("TotalRoutes", 12)
