-- Responsive objective HUD and world guidance for progression-island jobs.
-- Reads server-authored player attributes; rewards and route authority stay server-side.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local WorldConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("WorldConfig"))
local world = workspace:WaitForChild("SnatchTheStickmanWorld")
local connectedMap = world:WaitForChild("ConnectedMap")
local islandsFolder = connectedMap:WaitForChild("ProgressionIslands")

local gui = Instance.new("ScreenGui")
gui.Name = "IslandJobHUD"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.DisplayOrder = 6
gui.Parent = player:WaitForChild("PlayerGui")

local card = Instance.new("Frame")
card.Name = "ObjectiveCard"
card.AnchorPoint = Vector2.new(0.5, 0)
card.Position = UDim2.new(0.5, 0, 0, 76)
card.Size = UDim2.fromOffset(420, 104)
card.BackgroundColor3 = Color3.fromRGB(12, 15, 23)
card.BackgroundTransparency = 0.06
card.BorderSizePixel = 0
card.Visible = false
card.Parent = gui
Instance.new("UICorner", card).CornerRadius = UDim.new(0, 14)

local stroke = Instance.new("UIStroke")
stroke.Thickness = 1.5
stroke.Transparency = 0.18
stroke.Parent = card

local padding = Instance.new("UIPadding")
padding.PaddingLeft = UDim.new(0, 16)
padding.PaddingRight = UDim.new(0, 16)
padding.PaddingTop = UDim.new(0, 11)
padding.PaddingBottom = UDim.new(0, 10)
padding.Parent = card

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -84, 0, 24)
title.BackgroundTransparency = 1
title.TextXAlignment = Enum.TextXAlignment.Left
title.Font = Enum.Font.GothamBold
title.TextSize = 18
title.TextColor3 = Color3.fromRGB(245, 248, 255)
title.Parent = card

local stepLabel = Instance.new("TextLabel")
stepLabel.Position = UDim2.new(0, 0, 0, 29)
stepLabel.Size = UDim2.new(1, 0, 0, 24)
stepLabel.BackgroundTransparency = 1
stepLabel.TextXAlignment = Enum.TextXAlignment.Left
stepLabel.Font = Enum.Font.GothamMedium
stepLabel.TextSize = 15
stepLabel.TextColor3 = Color3.fromRGB(205, 214, 232)
stepLabel.Parent = card

local detail = Instance.new("TextLabel")
detail.Position = UDim2.new(0, 0, 0, 57)
detail.Size = UDim2.new(1, 0, 0, 20)
detail.BackgroundTransparency = 1
detail.TextXAlignment = Enum.TextXAlignment.Left
detail.Font = Enum.Font.Gotham
detail.TextSize = 13
detail.TextColor3 = Color3.fromRGB(155, 168, 193)
detail.Parent = card

local counter = Instance.new("TextLabel")
counter.AnchorPoint = Vector2.new(1, 0)
counter.Position = UDim2.new(1, 0, 0, 1)
counter.Size = UDim2.fromOffset(76, 23)
counter.BackgroundTransparency = 1
counter.TextXAlignment = Enum.TextXAlignment.Right
counter.Font = Enum.Font.GothamBold
counter.TextSize = 15
counter.Parent = card

local marker = Instance.new("BillboardGui")
marker.Name = "IslandJobObjectiveMarker"
marker.AlwaysOnTop = true
marker.Size = UDim2.fromOffset(164, 54)
marker.StudsOffsetWorldSpace = Vector3.new(0, 6, 0)
marker.MaxDistance = 500
marker.Enabled = false
marker.Parent = gui

local markerFrame = Instance.new("Frame")
markerFrame.Size = UDim2.fromScale(1, 1)
markerFrame.BackgroundColor3 = Color3.fromRGB(10, 13, 20)
markerFrame.BackgroundTransparency = 0.14
markerFrame.BorderSizePixel = 0
markerFrame.Parent = marker
Instance.new("UICorner", markerFrame).CornerRadius = UDim.new(0, 10)

local markerStroke = Instance.new("UIStroke")
markerStroke.Thickness = 1.5
markerStroke.Parent = markerFrame

local markerText = Instance.new("TextLabel")
markerText.Size = UDim2.new(1, -10, 1, -8)
markerText.Position = UDim2.fromOffset(5, 4)
markerText.BackgroundTransparency = 1
markerText.TextWrapped = true
markerText.Font = Enum.Font.GothamBold
markerText.TextSize = 13
markerText.TextColor3 = Color3.fromRGB(245, 248, 255)
markerText.Parent = markerFrame

local function islandById(id)
	for _, island in ipairs(WorldConfig.PROGRESSION_ISLANDS) do
		if island.Id == id then return island end
	end
	return nil
end

local function objectivePart(islandId, step)
	local islandModel = islandsFolder:FindFirstChild(islandId)
	if not islandModel then return nil end
	local checkpoint = islandModel:FindFirstChild(islandId .. "JobStep" .. tostring(step), true)
	return checkpoint and checkpoint:FindFirstChild("Body") or nil
end

local function resize()
	local camera = workspace.CurrentCamera
	local viewport = camera and camera.ViewportSize or Vector2.new(1920, 1080)
	local width = math.clamp(viewport.X - 24, 270, 420)
	card.Size = UDim2.fromOffset(width, viewport.X < 620 and 112 or 104)
	card.Position = UDim2.new(0.5, 0, 0, viewport.X < 620 and 58 or 76)
	title.TextSize = viewport.X < 620 and 16 or 18
	stepLabel.TextSize = viewport.X < 620 and 14 or 15
end

local function refresh()
	local islandId = player:GetAttribute("ActiveIslandJob")
	local step = tonumber(player:GetAttribute("IslandJobStep")) or 0
	local count = tonumber(player:GetAttribute("IslandJobStepCount")) or 0
	local island = islandId and islandById(islandId) or nil
	local job = islandId and WorldConfig.ISLAND_JOBS[islandId] or nil
	local stepData = job and job.Steps[step] or nil
	if not island or not job or not stepData or step <= 0 then
		card.Visible = false
		marker.Enabled = false
		marker.Adornee = nil
		return
	end

	card.Visible = true
	stroke.Color = island.Accent
	counter.TextColor3 = island.Accent
	markerStroke.Color = island.Accent
	title.Text = job.Name
	stepLabel.Text = stepData.Name
	counter.Text = string.format("%d / %d", step, count)
	detail.Text = string.format("%s  -  reward $%d", island.Name, job.Reward)

	local target = objectivePart(islandId, step)
	marker.Adornee = target
	marker.Enabled = target ~= nil
	markerText.Text = string.format("NEXT\n%s", string.upper(stepData.Name))
end

for _, attribute in ipairs({"ActiveIslandJob", "IslandJobStep", "IslandJobStepCount"}) do
	player:GetAttributeChangedSignal(attribute):Connect(refresh)
end

local lastDistance = -1
RunService.RenderStepped:Connect(function()
	if not marker.Enabled or not marker.Adornee then return end
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not root then return end
	local distance = math.floor((root.Position - marker.Adornee.Position).Magnitude + 0.5)
	if distance ~= lastDistance then
		lastDistance = distance
		local islandId = player:GetAttribute("ActiveIslandJob")
		local step = tonumber(player:GetAttribute("IslandJobStep")) or 0
		local job = islandId and WorldConfig.ISLAND_JOBS[islandId] or nil
		local stepData = job and job.Steps[step] or nil
		if stepData then markerText.Text = string.format("NEXT  %dm\n%s", distance, string.upper(stepData.Name)) end
	end
end)

local camera = workspace.CurrentCamera
if camera then camera:GetPropertyChangedSignal("ViewportSize"):Connect(resize) end
resize()
refresh()
