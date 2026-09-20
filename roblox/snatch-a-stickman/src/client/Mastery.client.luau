local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local gui = Instance.new("ScreenGui")
gui.Name = "MasteryHUD"
gui.ResetOnSpawn = false
gui.DisplayOrder = 11
gui.Parent = player:WaitForChild("PlayerGui")

local card = Instance.new("Frame")
card.Name = "Card"
card.AnchorPoint = Vector2.new(1, 0)
card.Position = UDim2.new(1, -18, 0, 228)
card.Size = UDim2.fromOffset(280, 94)
card.BackgroundColor3 = Color3.fromRGB(18, 21, 29)
card.BackgroundTransparency = 0.06
card.Parent = gui
Instance.new("UICorner", card).CornerRadius = UDim.new(0, 13)

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(112, 170, 255)
stroke.Transparency = 0.35
stroke.Thickness = 1.5
stroke.Parent = card
local title = Instance.new("TextLabel")
title.Position = UDim2.fromOffset(14, 8)
title.Size = UDim2.new(1, -28, 0, 22)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBlack
title.TextSize = 15
title.TextColor3 = Color3.fromRGB(168, 202, 255)
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = card

local subtitle = title:Clone()
subtitle.Position = UDim2.fromOffset(14, 30)
subtitle.Size = UDim2.new(1, -28, 0, 18)
subtitle.Font = Enum.Font.GothamMedium
subtitle.TextSize = 11
subtitle.TextColor3 = Color3.fromRGB(190, 199, 218)
subtitle.Parent = card

local barBack = Instance.new("Frame")
barBack.Position = UDim2.fromOffset(14, 54)
barBack.Size = UDim2.new(1, -28, 0, 9)
barBack.BackgroundColor3 = Color3.fromRGB(47, 53, 68)
barBack.Parent = card
Instance.new("UICorner", barBack).CornerRadius = UDim.new(1, 0)

local bar = Instance.new("Frame")
bar.Size = UDim2.fromScale(0, 1)
bar.BackgroundColor3 = Color3.fromRGB(112, 170, 255)
bar.Parent = barBack
Instance.new("UICorner", bar).CornerRadius = UDim.new(1, 0)
local detail = title:Clone()
detail.Position = UDim2.fromOffset(14, 68)
detail.Size = UDim2.new(1, -28, 0, 18)
detail.Font = Enum.Font.GothamMedium
detail.TextSize = 11
detail.TextColor3 = Color3.fromRGB(158, 170, 193)
detail.Parent = card

local lastLevel = tonumber(player:GetAttribute("MasteryLevel")) or 0
local lastPulse = tonumber(player:GetAttribute("MasteryPulse")) or 0

local function refresh()
	local level = tonumber(player:GetAttribute("MasteryLevel")) or 0
	local xp = tonumber(player:GetAttribute("MasteryXP")) or 0
	local nextXP = tonumber(player:GetAttribute("MasteryXPNext")) or 0
	local progress = tonumber(player:GetAttribute("MasteryProgress")) or 0
	local titleText = tostring(player:GetAttribute("MasteryTitle") or "ROOKIE RECRUITER")
	local bonus = tonumber(player:GetAttribute("MasteryIncomeBonus")) or 0
	local maxed = player:GetAttribute("MasteryMaxed") == true

	title.Text = string.format("MASTERY %d  •  %s", level, titleText)
	if maxed then
		subtitle.Text = "MAX LEVEL • permanent income bonus fully unlocked"
		detail.Text = string.format("+%d%% passive income", math.floor(bonus * 100 + 0.5))
		progress = 1
	else
		subtitle.Text = string.format("%d / %d XP to next level", xp, nextXP)
		detail.Text = string.format("+%d%% passive income • earn XP from recruiting, snatching, streaks, and discoveries", math.floor(bonus * 100 + 0.5))
	end
	TweenService:Create(bar, TweenInfo.new(0.24, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = UDim2.fromScale(math.clamp(progress, 0, 1), 1),
	}):Play()

	local pulse = tonumber(player:GetAttribute("MasteryPulse")) or 0
	if level > lastLevel or pulse > lastPulse then
		local original = card.Size
		card.Size = UDim2.fromOffset(original.X.Offset + 16, original.Y.Offset + 6)
		TweenService:Create(card, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Size = original,
		}):Play()
	end
	lastLevel = math.max(lastLevel, level)
	lastPulse = math.max(lastPulse, pulse)
end
for _, name in ipairs({
	"MasteryLevel",
	"MasteryXP",
	"MasteryXPNext",
	"MasteryProgress",
	"MasteryIncomeBonus",
	"MasteryTitle",
	"MasteryMaxed",
	"MasteryPulse",
}) do
	player:GetAttributeChangedSignal(name):Connect(refresh)
end

local function adapt()
	local camera = workspace.CurrentCamera
	if not camera then return end
	if camera.ViewportSize.X < 760 then
		card.Position = UDim2.new(1, -12, 0, 348)
		card.Size = UDim2.fromOffset(238, 88)
		title.TextSize = 13
		subtitle.TextSize = 10
		detail.TextSize = 9
	else
		card.Position = UDim2.new(1, -18, 0, 366)
		card.Size = UDim2.fromOffset(280, 94)
		title.TextSize = 15
		subtitle.TextSize = 11
		detail.TextSize = 11
	end
end

local camera = workspace.CurrentCamera
if camera then
	camera:GetPropertyChangedSignal("ViewportSize"):Connect(adapt)
end

refresh()
adapt()
