local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local world = workspace:WaitForChild("SnatchTheStickmanWorld")

local gui = Instance.new("ScreenGui")
gui.Name = "MarketEventHUD"
gui.ResetOnSpawn = false
gui.DisplayOrder = 10
gui.Parent = player:WaitForChild("PlayerGui")

local card = Instance.new("Frame")
card.Name = "Card"
card.AnchorPoint = Vector2.new(0.5, 1)
card.Position = UDim2.new(0.5, 0, 1, -22)
card.Size = UDim2.fromOffset(460, 62)
card.BackgroundColor3 = Color3.fromRGB(18, 21, 29)
card.BackgroundTransparency = 0.06
card.Parent = gui
Instance.new("UICorner", card).CornerRadius = UDim.new(0, 14)

local stroke = Instance.new("UIStroke")
stroke.Transparency = 0.34
stroke.Thickness = 1.5
stroke.Parent = card
local title = Instance.new("TextLabel")
title.Position = UDim2.fromOffset(14, 7)
title.Size = UDim2.new(1, -28, 0, 21)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBlack
title.TextSize = 14
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = card

local detail = title:Clone()
detail.Position = UDim2.fromOffset(14, 30)
detail.Size = UDim2.new(1, -28, 0, 22)
detail.Font = Enum.Font.GothamMedium
detail.TextSize = 11
detail.TextColor3 = Color3.fromRGB(204, 211, 226)
detail.Parent = card

local scale = Instance.new("UIScale")
scale.Parent = card
local lastPulse = tonumber(world:GetAttribute("MarketEventPulse")) or 0

local function eventColor(name)
	if name == "Rare Rush" then return Color3.fromRGB(207, 118, 255) end
	if name == "Payday" then return Color3.fromRGB(105, 235, 151) end
	return Color3.fromRGB(118, 151, 205)
end
local function refresh()
	local now = workspace:GetServerTimeNow()
	local name = tostring(world:GetAttribute("MarketEvent") or "Calm")
	local description = tostring(world:GetAttribute("MarketEventDescription") or "Market stable")
	local endsAt = tonumber(world:GetAttribute("MarketEventEndsAt")) or 0
	local nextAt = tonumber(world:GetAttribute("MarketEventNextAt")) or 0
	local color = eventColor(name)

	title.TextColor3 = color
	stroke.Color = color

	if name ~= "Calm" and endsAt > now then
		title.Text = "MARKET EVENT • " .. string.upper(name)
		detail.Text = string.format("%s  •  %ds left", description, math.max(0, math.ceil(endsAt - now)))
	else
		title.Text = "MARKET • CALM"
		if nextAt > now then
			detail.Text = string.format("Next market event in %ds", math.max(0, math.ceil(nextAt - now)))
		else
			detail.Text = "Next market event starting soon…"
		end
	end

	local pulse = tonumber(world:GetAttribute("MarketEventPulse")) or 0
	if pulse > lastPulse then
		scale.Scale = 0.9
		TweenService:Create(scale, TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Scale = 1,
		}):Play()
	end
	lastPulse = math.max(lastPulse, pulse)
end
for _, name in ipairs({
	"MarketEvent",
	"MarketEventDescription",
	"MarketEventEndsAt",
	"MarketEventNextAt",
	"MarketEventPulse",
}) do
	world:GetAttributeChangedSignal(name):Connect(refresh)
end

task.spawn(function()
	while gui.Parent do
		refresh()
		task.wait(0.25)
	end
end)

local function adapt()
	local camera = workspace.CurrentCamera
	if not camera then return end
	if camera.ViewportSize.X < 760 then
		card.Size = UDim2.new(0.9, 0, 0, 58)
		card.Position = UDim2.new(0.5, 0, 1, -12)
		title.TextSize = 12
		detail.TextSize = 9
	else
		card.Size = UDim2.fromOffset(460, 62)
		card.Position = UDim2.new(0.5, 0, 1, -22)
		title.TextSize = 14
		detail.TextSize = 11
	end
end

local camera = workspace.CurrentCamera
if camera then
	camera:GetPropertyChangedSignal("ViewportSize"):Connect(adapt)
end

refresh()
adapt()
