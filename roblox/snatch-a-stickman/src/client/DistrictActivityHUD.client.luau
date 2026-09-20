-- Compact HUD for rotating district activities.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local world = workspace:WaitForChild("SnatchTheStickmanWorld")

local gui = Instance.new("ScreenGui")
gui.Name = "DistrictActivityHUD"
gui.ResetOnSpawn = false
gui.DisplayOrder = 5
gui.Parent = player:WaitForChild("PlayerGui")

local card = Instance.new("Frame")
card.Name = "ActivityCard"
card.AnchorPoint = Vector2.new(0, 0.5)
card.Position = UDim2.new(0, 18, 0.53, 0)
card.Size = UDim2.fromOffset(310, 112)
card.BackgroundColor3 = Color3.fromRGB(13, 16, 24)
card.BackgroundTransparency = 0.08
card.BorderSizePixel = 0
card.Visible = false
card.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = card

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(92, 123, 255)
stroke.Transparency = 0.28
stroke.Thickness = 1.5
stroke.Parent = card

local title = Instance.new("TextLabel")
title.Position = UDim2.new(0, 14, 0, 10)
title.Size = UDim2.new(1, -28, 0, 25)
title.BackgroundTransparency = 1
title.TextColor3 = Color3.fromRGB(245, 248, 255)
title.TextXAlignment = Enum.TextXAlignment.Left
title.TextScaled = true
title.Font = Enum.Font.GothamBold
title.Parent = card

local detail = Instance.new("TextLabel")
detail.Position = UDim2.new(0, 14, 0, 39)
detail.Size = UDim2.new(1, -28, 0, 33)
detail.BackgroundTransparency = 1
detail.TextColor3 = Color3.fromRGB(188, 198, 220)
detail.TextXAlignment = Enum.TextXAlignment.Left
detail.TextYAlignment = Enum.TextYAlignment.Top
detail.TextWrapped = true
detail.TextScaled = true
detail.Font = Enum.Font.Gotham
detail.Parent = card

local barBack = Instance.new("Frame")
barBack.Position = UDim2.new(0, 14, 1, -26)
barBack.Size = UDim2.new(1, -90, 0, 10)
barBack.BackgroundColor3 = Color3.fromRGB(40, 45, 60)
barBack.BorderSizePixel = 0
barBack.Parent = card

local barCorner = Instance.new("UICorner")
barCorner.CornerRadius = UDim.new(1, 0)
barCorner.Parent = barBack

local bar = Instance.new("Frame")
bar.Name = "Progress"
bar.Size = UDim2.fromScale(0, 1)
bar.BackgroundColor3 = Color3.fromRGB(91, 215, 146)
bar.BorderSizePixel = 0
bar.Parent = barBack

local barFillCorner = Instance.new("UICorner")
barFillCorner.CornerRadius = UDim.new(1, 0)
barFillCorner.Parent = bar

local status = Instance.new("TextLabel")
status.AnchorPoint = Vector2.new(1, 0.5)
status.Position = UDim2.new(1, -12, 1, -21)
status.Size = UDim2.fromOffset(65, 22)
status.BackgroundTransparency = 1
status.TextColor3 = Color3.fromRGB(119, 230, 171)
status.TextScaled = true
status.Font = Enum.Font.GothamBold
status.Parent = card

local function districtDisplay(id)
	if id == "FreightYard" then return "SCRAPLINE FREIGHT" end
	if id == "NeonJunction" then return "NEON JUNCTION" end
	if id == "Highline" then return "THE HIGHLINE" end
	if id == "FoundryCommons" then return "FOUNDRY COMMONS" end
	return string.upper(id or "CITY")
end

local function resize()
	local camera = workspace.CurrentCamera
	local viewport = camera and camera.ViewportSize or Vector2.new(1920, 1080)
	if viewport.X < 700 then
		card.Position = UDim2.new(0, 10, 0.57, 0)
		card.Size = UDim2.fromOffset(math.max(255, math.min(300, viewport.X - 20)), 104)
	else
		card.Position = UDim2.new(0, 18, 0.53, 0)
		card.Size = UDim2.fromOffset(310, 112)
	end
end

local accumulator = 0
RunService.Heartbeat:Connect(function(dt)
	accumulator += dt
	if accumulator < 0.12 then return end
	accumulator = 0

	local active = world:GetAttribute("DistrictActivityId")
	if not active or active == "" then
		card.Visible = false
		return
	end

	card.Visible = true
	local name = tostring(world:GetAttribute("DistrictActivityName") or "City Activity")
	local district = tostring(world:GetAttribute("DistrictActivityDistrict") or "")
	local endsAt = tonumber(world:GetAttribute("DistrictActivityEndsAt")) or 0
	local reward = tonumber(world:GetAttribute("DistrictActivityReward")) or 0
	local goal = tonumber(player:GetAttribute("DistrictActivityGoal")) or 0
	local progress = tonumber(player:GetAttribute("DistrictActivityProgress")) or 0
	local completed = player:GetAttribute("DistrictActivityCompleted") == true
	local remaining = math.max(0, math.ceil(endsAt - workspace:GetServerTimeNow()))

	title.Text = name
	if completed then
		detail.Text = string.format("%s • COMPLETE • +$%d", districtDisplay(district), reward)
		status.Text = "DONE"
	else
		detail.Text = string.format("%s • stay in the activity zone • %ds left", districtDisplay(district), remaining)
		status.Text = string.format("%ds", math.ceil(math.max(0, goal - progress)))
	end
	bar.Size = UDim2.fromScale(goal > 0 and math.clamp(progress / goal, 0, 1) or 0, 1)
end)

local camera = workspace.CurrentCamera
if camera then camera:GetPropertyChangedSignal("ViewportSize"):Connect(resize) end
resize()
