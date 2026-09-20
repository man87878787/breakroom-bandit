local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local gui = Instance.new("ScreenGui")
gui.Name = "RarityBountyHUD"
gui.ResetOnSpawn = false
gui.DisplayOrder = 10
gui.Parent = player:WaitForChild("PlayerGui")

local card = Instance.new("Frame")
card.Name = "Card"
card.AnchorPoint = Vector2.new(0, 0)
card.Position = UDim2.new(0, 18, 0, 78)
card.Size = UDim2.fromOffset(282, 84)
card.BackgroundColor3 = Color3.fromRGB(18, 21, 29)
card.BackgroundTransparency = 0.06
card.Parent = gui
Instance.new("UICorner", card).CornerRadius = UDim.new(0, 13)

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(226, 127, 255)
stroke.Transparency = 0.35
stroke.Thickness = 1.5
stroke.Parent = card
local title = Instance.new("TextLabel")
title.Position = UDim2.fromOffset(14, 8)
title.Size = UDim2.new(1, -28, 0, 22)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBlack
title.TextSize = 14
title.TextColor3 = Color3.fromRGB(226, 127, 255)
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = card

local detail = title:Clone()
detail.Position = UDim2.fromOffset(14, 32)
detail.Size = UDim2.new(1, -28, 0, 20)
detail.Font = Enum.Font.GothamMedium
detail.TextSize = 11
detail.TextColor3 = Color3.fromRGB(215, 221, 234)
detail.Parent = card

local timer = title:Clone()
timer.Position = UDim2.fromOffset(14, 56)
timer.Size = UDim2.new(1, -28, 0, 18)
timer.Font = Enum.Font.GothamMedium
timer.TextSize = 10
timer.TextColor3 = Color3.fromRGB(150, 161, 185)
timer.Parent = card

local scale = Instance.new("UIScale")
scale.Parent = card
local lastPulse = tonumber(player:GetAttribute("RarityBountyPulse")) or 0
local function refresh()
	local now = workspace:GetServerTimeNow()
	local active = player:GetAttribute("RarityBountyActive") == true
	local target = tostring(player:GetAttribute("RarityBountyTarget") or "")
	local reward = tonumber(player:GetAttribute("RarityBountyReward")) or 0
	local expiresAt = tonumber(player:GetAttribute("RarityBountyExpiresAt")) or 0
	local nextAt = tonumber(player:GetAttribute("RarityBountyNextAt")) or 0

	if active and target ~= "" then
		title.Text = "RARITY BOUNTY • " .. string.upper(target)
		detail.Text = string.format("Acquire a NEW %s during this bounty • +$%d", target, reward)
		timer.Text = string.format("%ds remaining • recruiting or snatching both count", math.max(0, math.ceil(expiresAt - now)))
		stroke.Color = Color3.fromRGB(226, 127, 255)
	else
		title.Text = "RARITY BOUNTY • PREPARING"
		detail.Text = "A new target rarity is coming soon."
		timer.Text = nextAt > now and string.format("Next bounty in %ds", math.max(0, math.ceil(nextAt - now))) or "Selecting target…"
		stroke.Color = Color3.fromRGB(112, 126, 158)
	end

	local pulse = tonumber(player:GetAttribute("RarityBountyPulse")) or 0
	if pulse > lastPulse then
		scale.Scale = 0.88
		TweenService:Create(scale, TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
	end
	lastPulse = math.max(lastPulse, pulse)
end
for _, name in ipairs({
	"RarityBountyActive",
	"RarityBountyTarget",
	"RarityBountyReward",
	"RarityBountyExpiresAt",
	"RarityBountyNextAt",
	"RarityBountyPulse",
}) do
	player:GetAttributeChangedSignal(name):Connect(refresh)
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
		card.Position = UDim2.new(0, 12, 0, 164)
		card.Size = UDim2.fromOffset(230, 78)
		title.TextSize = 12
		detail.TextSize = 9
		timer.TextSize = 8
	else
		card.Position = UDim2.new(0, 18, 0, 78)
		card.Size = UDim2.fromOffset(282, 84)
		title.TextSize = 14
		detail.TextSize = 11
		timer.TextSize = 10
	end
end

local camera = workspace.CurrentCamera
if camera then
	camera:GetPropertyChangedSignal("ViewportSize"):Connect(adapt)
end

refresh()
adapt()
