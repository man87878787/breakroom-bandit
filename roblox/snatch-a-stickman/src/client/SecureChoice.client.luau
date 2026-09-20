-- Dual secure-zone guidance tied directly to the authored Fast Lane / Sky Route network.
-- Presentation only: the server remains authoritative for carry state and securing.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local world = workspace:WaitForChild("SnatchTheStickmanWorld")
local connectedMap = world:WaitForChild("ConnectedMap")
local neighborhoods = connectedMap:WaitForChild("BaseNeighborhoods")

local PAD_COLORS = {
	A = Color3.fromRGB(75, 255, 150),
	B = Color3.fromRGB(80, 225, 255),
}

local presentations = {}
local routeAssignments = {}
local accumulator = 0

local function clear()
	for _, item in ipairs(presentations) do
		if item.highlight then item.highlight:Destroy() end
		if item.gui then item.gui:Destroy() end
		if item.routeGui then item.routeGui:Destroy() end
	end
	table.clear(presentations)
	table.clear(routeAssignments)
end

local function routePart(model, name)
	local item = model and model:FindFirstChild(name)
	return item and item:IsA("BasePart") and item or nil
end

local function chooseAssignments(neighborhood, padA, padB)
	local ground = routePart(neighborhood, "GroundLaneGuide")
	local sky = routePart(neighborhood, "SkyGuide")
	if not ground or not sky or not padA or not padB then return nil end

	-- Pick the pairing that creates the shortest combined route-to-deposit travel.
	-- This keeps the authored route system correct for every plot orientation without hard-coded sides.
	local direct = (ground.Position - padA.Position).Magnitude + (sky.Position - padB.Position).Magnitude
	local crossed = (ground.Position - padB.Position).Magnitude + (sky.Position - padA.Position).Magnitude
	if direct <= crossed then
		return {
			{routeName = "FAST", route = ground, padName = "A", pad = padA},
			{routeName = "SKY", route = sky, padName = "B", pad = padB},
		}
	end
	return {
		{routeName = "FAST", route = ground, padName = "B", pad = padB},
		{routeName = "SKY", route = sky, padName = "A", pad = padA},
	}
end

local function makeBillboard(adornee, name, text, color, offset, width)
	local gui = Instance.new("BillboardGui")
	gui.Name = name
	gui.Adornee = adornee
	gui.Size = UDim2.fromOffset(width or 190, 44)
	gui.StudsOffset = offset or Vector3.new(0, 3, 0)
	gui.AlwaysOnTop = true
	gui.MaxDistance = 120
	gui.Parent = adornee

	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundColor3 = Color3.fromRGB(18, 24, 33)
	label.BackgroundTransparency = 0.14
	label.Text = text
	label.TextColor3 = color
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.Parent = gui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = label
	return gui, label
end

local function addPresentation(assignment)
	local color = PAD_COLORS[assignment.padName]
	local highlight = Instance.new("Highlight")
	highlight.Name = "LocalSecureRoute"
	highlight.Adornee = assignment.pad
	highlight.FillColor = color
	highlight.OutlineColor = Color3.fromRGB(235, 255, 255)
	highlight.FillTransparency = 0.58
	highlight.OutlineTransparency = 0.12
	highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	highlight.Parent = assignment.pad

	local gui, label = makeBillboard(
		assignment.pad,
		"LocalSecureChoice",
		string.format("SECURE %s • %s ROUTE", assignment.padName, assignment.routeName),
		color,
		Vector3.new(0, 3, 0),
		205
	)
	local routeGui, routeLabel = makeBillboard(
		assignment.route,
		"LocalRouteDestination",
		string.format("%s → SECURE %s", assignment.routeName, assignment.padName),
		color,
		Vector3.new(0, 2.2, 0),
		185
	)

	table.insert(presentations, {
		highlight = highlight,
		gui = gui,
		label = label,
		routeGui = routeGui,
		routeLabel = routeLabel,
		assignment = assignment,
	})
end

local function rebuild()
	clear()
	if not player:GetAttribute("CarryRarity") then return end

	local plotIndex = tonumber(player:GetAttribute("PlotIndex"))
	local plot = plotIndex and world:FindFirstChild("Plot" .. plotIndex)
	local neighborhood = plotIndex and neighborhoods:FindFirstChild("BaseNeighborhood" .. plotIndex)
	if not plot or not neighborhood then return end

	local padA = plot:FindFirstChild("SecurePad")
	local padB = plot:FindFirstChild("SecurePad2")
	if not (padA and padA:IsA("BasePart") and padB and padB:IsA("BasePart")) then return end

	local assignments = chooseAssignments(neighborhood, padA, padB)
	if not assignments then return end
	routeAssignments = assignments
	for _, assignment in ipairs(assignments) do
		addPresentation(assignment)
	end
end

player:GetAttributeChangedSignal("CarryRarity"):Connect(rebuild)
player:GetAttributeChangedSignal("PlotIndex"):Connect(rebuild)
neighborhoods.ChildAdded:Connect(function()
	if player:GetAttribute("CarryRarity") then task.defer(rebuild) end
end)

RunService.Heartbeat:Connect(function(dt)
	if #presentations == 0 then return end
	accumulator += dt
	if accumulator < 0.15 then return end
	accumulator = 0

	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not root then return end

	local bestPresentation = nil
	local bestScore = math.huge
	for _, presentation in ipairs(presentations) do
		local assignment = presentation.assignment
		local pad = assignment.pad
		local route = assignment.route
		if pad.Parent and route.Parent then
			-- Recommend a route using the player's current approach cost plus the route-to-pad leg.
			-- It is advisory only and never changes secure authority or rewards.
			local score = (root.Position - route.Position).Magnitude + (route.Position - pad.Position).Magnitude
			if score < bestScore then
				bestScore = score
				bestPresentation = presentation
			end
		end
	end

	for _, presentation in ipairs(presentations) do
		local assignment = presentation.assignment
		local distance = (root.Position - assignment.pad.Position).Magnitude
		local recommended = presentation == bestPresentation
		presentation.highlight.FillTransparency = distance < 24 and 0.24 or (recommended and 0.42 or 0.62)
		presentation.highlight.OutlineTransparency = recommended and 0.02 or 0.2
		presentation.label.Text = string.format(
			"%sSECURE %s • %s ROUTE",
			recommended and "★ " or "",
			assignment.padName,
			assignment.routeName
		)
		presentation.routeLabel.Text = string.format(
			"%s%s → SECURE %s",
			recommended and "★ " or "",
			assignment.routeName,
			assignment.padName
		)
	end
end)

rebuild()
