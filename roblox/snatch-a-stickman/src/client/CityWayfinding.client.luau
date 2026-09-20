-- Lightweight client wayfinding for the expanded city.
-- Shows a short district arrival banner and transit-arrival feedback without adding a permanent HUD panel.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local WorldConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("WorldConfig"))
local player = Players.LocalPlayer

local gui = Instance.new("ScreenGui")
gui.Name = "CityWayfinding"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.DisplayOrder = 4
gui.Parent = player:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Name = "DistrictBanner"
frame.AnchorPoint = Vector2.new(0.5, 0)
frame.Position = UDim2.new(0.5, 0, 0.09, 0)
frame.Size = UDim2.fromOffset(430, 74)
frame.BackgroundColor3 = Color3.fromRGB(15, 18, 26)
frame.BackgroundTransparency = 1
frame.BorderSizePixel = 0
frame.Visible = false
frame.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = frame

local stroke = Instance.new("UIStroke")
stroke.Thickness = 1.5
stroke.Transparency = 1
stroke.Parent = frame

local title = Instance.new("TextLabel")
title.Name = "Title"
title.Position = UDim2.new(0, 16, 0, 8)
title.Size = UDim2.new(1, -32, 0, 30)
title.BackgroundTransparency = 1
title.Text = ""
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextTransparency = 1
title.TextScaled = true
title.Font = Enum.Font.GothamBlack
title.Parent = frame

local subtitle = Instance.new("TextLabel")
subtitle.Name = "Subtitle"
subtitle.Position = UDim2.new(0, 16, 0, 41)
subtitle.Size = UDim2.new(1, -32, 0, 20)
subtitle.BackgroundTransparency = 1
subtitle.Text = ""
subtitle.TextColor3 = Color3.fromRGB(210, 218, 234)
subtitle.TextTransparency = 1
subtitle.TextScaled = true
subtitle.Font = Enum.Font.Gotham
subtitle.Parent = frame

local sizeConstraint = Instance.new("UISizeConstraint")
sizeConstraint.MinSize = Vector2.new(270, 62)
sizeConstraint.MaxSize = Vector2.new(430, 74)
sizeConstraint.Parent = frame

local currentDistrict = nil
local bannerSerial = 0

local function showBanner(name, detail, accent)
	bannerSerial += 1
	local serial = bannerSerial
	frame.Visible = true
	title.Text = string.upper(name)
	subtitle.Text = detail or ""
	stroke.Color = accent or Color3.fromRGB(90, 112, 255)
	title.TextColor3 = accent or Color3.fromRGB(255, 255, 255)

	TweenService:Create(frame, TweenInfo.new(0.18), {BackgroundTransparency = 0.12}):Play()
	TweenService:Create(stroke, TweenInfo.new(0.18), {Transparency = 0.2}):Play()
	TweenService:Create(title, TweenInfo.new(0.18), {TextTransparency = 0}):Play()
	TweenService:Create(subtitle, TweenInfo.new(0.18), {TextTransparency = 0.08}):Play()

	task.delay(2.7, function()
		if serial ~= bannerSerial then
			return
		end
		TweenService:Create(frame, TweenInfo.new(0.28), {BackgroundTransparency = 1}):Play()
		TweenService:Create(stroke, TweenInfo.new(0.28), {Transparency = 1}):Play()
		TweenService:Create(title, TweenInfo.new(0.28), {TextTransparency = 1}):Play()
		local tween = TweenService:Create(subtitle, TweenInfo.new(0.28), {TextTransparency = 1})
		tween:Play()
		tween.Completed:Once(function()
			if serial == bannerSerial then
				frame.Visible = false
			end
		end)
	end)
end

local function rootPosition()
	local character = player.Character
	local rootPart = character and character:FindFirstChild("HumanoidRootPart")
	return rootPart and rootPart.Position or nil
end

local function nearestDistrict(position)
	local best = nil
	local bestDistance = math.huge
	for _, regions in ipairs({WorldConfig.DISTRICTS, WorldConfig.PROGRESSION_ISLANDS}) do
		for _, district in ipairs(regions) do
			local delta = Vector2.new(position.X - district.Center.X, position.Z - district.Center.Z)
			local distance = delta.Magnitude
			if distance <= district.Radius and distance < bestDistance then
				best = district
				bestDistance = distance
			end
		end
	end
	return best
end

task.spawn(function()
	while gui.Parent do
		local position = rootPosition()
		if position then
			local district = nearestDistrict(position)
			local id = district and district.Id or nil
			if id ~= currentDistrict then
				currentDistrict = id
				if district then
					showBanner(district.Name, district.Subtitle, district.Accent)
				end
			end
		end
		task.wait(0.35)
	end
end)

local lastArrival = player:GetAttribute("TransitArrival")
player:GetAttributeChangedSignal("TransitArrival"):Connect(function()
	local arrival = player:GetAttribute("TransitArrival")
	if arrival and arrival ~= lastArrival then
		lastArrival = arrival
		for _, stop in ipairs(WorldConfig.TRANSIT_STOPS) do
			if stop.Name == arrival then
				showBanner(stop.Name, "CITY TRANSIT • ARRIVED", stop.Accent)
				return
			end
		end
	end
end)

local lastIslandArrival = player:GetAttribute("IslandTravelArrival")
player:GetAttributeChangedSignal("IslandTravelArrival"):Connect(function()
	local arrival = player:GetAttribute("IslandTravelArrival")
	if not arrival or arrival == "" or arrival == lastIslandArrival then return end
	lastIslandArrival = arrival
	for _, island in ipairs(WorldConfig.PROGRESSION_ISLANDS) do
		if island.Name == arrival then
			showBanner(island.Name, island.Subtitle, island.Accent)
			return
		end
	end
	if arrival == "Snatchport" then
		showBanner("Snatchport", "Returned to the home island", Color3.fromRGB(114, 205, 255))
	end
end)

-- Scale down gently on phones while preserving the same visual language.
local camera = workspace.CurrentCamera
local function resize()
	local viewport = camera and camera.ViewportSize or Vector2.new(1920, 1080)
	if viewport.X < 700 then
		frame.Size = UDim2.fromOffset(math.max(270, viewport.X - 40), 64)
	else
		frame.Size = UDim2.fromOffset(430, 74)
	end
end

if camera then
	camera:GetPropertyChangedSignal("ViewportSize"):Connect(resize)
end
resize()
