-- Reactive heist-route guidance for the authored base neighborhoods.
-- Presentation only: competitive authority remains on the server.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local localPlayer = Players.LocalPlayer
local world = workspace:WaitForChild("SnatchTheStickmanWorld")
local connectedMap = world:WaitForChild("ConnectedMap")
local neighborhoods = connectedMap:WaitForChild("BaseNeighborhoods")

local COLORS = {
	Neutral = Color3.fromRGB(120, 132, 155),
	Escape = Color3.fromRGB(92, 255, 155),
	Intercept = Color3.fromRGB(255, 108, 94),
	Contested = Color3.fromRGB(255, 188, 72),
}

local tracked = {}
local activeCarry = nil
local lastRole = "Neutral"

local function playerPlotIndex(userId)
	local player = Players:GetPlayerByUserId(userId)
	return player and tonumber(player:GetAttribute("PlotIndex")) or nil
end
local function ensureHighlight(model)
	local highlight = model:FindFirstChild("HeistRouteHighlight")
	if not highlight then
		highlight = Instance.new("Highlight")
		highlight.Name = "HeistRouteHighlight"
		highlight.DepthMode = Enum.HighlightDepthMode.Occluded
		highlight.FillTransparency = 0.9
		highlight.OutlineTransparency = 0.3
		highlight.Enabled = false
		highlight.Parent = model
	end
	return highlight
end

local function registerNeighborhood(model)
	if not model:IsA("Model") then return end
	local index = tonumber(model:GetAttribute("PlotIndex"))
	if not index then return end
	tracked[index] = {
		model = model,
		highlight = ensureHighlight(model),
		ground = model:FindFirstChild("GroundLaneGuide"),
		sky = model:FindFirstChild("SkyGuide"),
		marker = model:FindFirstChild("RouteChoiceMarker"),
	}
end

for _, child in ipairs(neighborhoods:GetChildren()) do
	registerNeighborhood(child)
end
neighborhoods.ChildAdded:Connect(function(child) task.defer(registerNeighborhood, child) end)
local function findActiveCarry()
	for _, child in ipairs(world:GetChildren()) do
		if child:IsA("Model") and child:GetAttribute("TransferState") == "InTransit" then
			local carrierId = tonumber(child:GetAttribute("CarrierUserId")) or 0
			local victimId = tonumber(child:GetAttribute("PreviousOwnerUserId")) or 0
			if carrierId == localPlayer.UserId or victimId == localPlayer.UserId then
				return child, carrierId, victimId
			end
		end
	end
	return nil, 0, 0
end

local function setRouteVisual(data, enabled, role, pulse)
	if not data or not data.model.Parent then return end
	local color = COLORS[role] or COLORS.Neutral
	data.highlight.Enabled = enabled
	data.highlight.OutlineColor = color
	data.highlight.FillColor = color
	data.highlight.OutlineTransparency = enabled and (0.18 + pulse * 0.18) or 1

	for _, guide in ipairs({data.ground, data.sky}) do
		if guide and guide.Parent then
			guide.Color = enabled and color or COLORS.Neutral
			guide.Transparency = enabled and (0.05 + pulse * 0.15) or 0.45
		end
	end
end
local function setMarkerText(data, text, color)
	local marker = data and data.marker
	if not marker then return end
	local gui = marker:FindFirstChildOfClass("SurfaceGui")
	local label = gui and gui:FindFirstChildOfClass("TextLabel")
	if label then
		label.Text = text
		label.TextColor3 = color
	end
end

local function clearRoutes()
	for _, data in pairs(tracked) do
		setRouteVisual(data, false, "Neutral", 0)
		setMarkerText(data, "FAST LANE   /   SKY ROUTE", COLORS.Neutral)
	end
end

local function refresh()
	local carry, carrierId, victimId = findActiveCarry()
	if not carry then
		if activeCarry or lastRole ~= "Neutral" then clearRoutes() end
		activeCarry = nil
		lastRole = "Neutral"
		return
	end

	local role = carrierId == localPlayer.UserId and "Escape" or "Intercept"
	if carry:GetAttribute("Contested") then role = "Contested" end
	local victimPlot = playerPlotIndex(victimId)
	local carrierPlot = playerPlotIndex(carrierId)
	local pulse = (math.sin(workspace:GetServerTimeNow() * 5) + 1) * 0.5
	for index, data in pairs(tracked) do
		local isVictimRoute = index == victimPlot
		local isCarrierHome = index == carrierPlot
		local enabled = isVictimRoute or (role == "Escape" and isCarrierHome)
		setRouteVisual(data, enabled, role, pulse)

		if isVictimRoute then
			if role == "Escape" then
				setMarkerText(data, "ESCAPE: FAST / SKY", COLORS[role])
			elseif role == "Contested" then
				setMarkerText(data, "CONTESTED - CUT THEM OFF", COLORS[role])
			else
				setMarkerText(data, "DEFEND: INTERCEPT ROUTES", COLORS[role])
			end
		elseif role == "Escape" and isCarrierHome then
			setMarkerText(data, "HOME - REACH SECURE PAD", COLORS[role])
		else
			setMarkerText(data, "FAST LANE   /   SKY ROUTE", COLORS.Neutral)
		end
	end

	activeCarry = carry
	lastRole = role
end

local elapsed = 0
RunService.Heartbeat:Connect(function(dt)
	elapsed += dt
	if elapsed < 0.12 then return end
	elapsed = 0
	refresh()
end)
