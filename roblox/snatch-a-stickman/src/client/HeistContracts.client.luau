local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local gui = Instance.new("ScreenGui")
gui.Name = "HeistContractHUD"
gui.ResetOnSpawn = false
gui.DisplayOrder = 10
gui.Parent = player:WaitForChild("PlayerGui")

local card = Instance.new("Frame")
card.Name = "Card"
card.AnchorPoint = Vector2.new(0.5, 0)
card.Position = UDim2.new(0.5, 0, 0, 78)
card.Size = UDim2.fromOffset(350, 104)
card.BackgroundColor3 = Color3.fromRGB(18, 21, 29)
card.BackgroundTransparency = 0.06
card.Parent = gui
Instance.new("UICorner", card).CornerRadius = UDim.new(0, 13)

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(95, 220, 145)
stroke.Transparency = 0.35
stroke.Thickness = 1.5
stroke.Parent = card
local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.Position = UDim2.fromOffset(14, 7)
title.Size = UDim2.new(1, -28, 0, 22)
title.Font = Enum.Font.GothamBlack
title.TextSize = 15
title.TextColor3 = Color3.fromRGB(115, 235, 162)
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = card

local detail = title:Clone()
detail.Position = UDim2.fromOffset(14, 31)
detail.Size = UDim2.new(1, -28, 0, 20)
detail.Font = Enum.Font.GothamMedium
detail.TextSize = 12
detail.TextColor3 = Color3.fromRGB(215, 221, 234)
detail.Parent = card

local bonus = title:Clone()
bonus.Position = UDim2.fromOffset(14, 53)
bonus.Size = UDim2.new(1, -28, 0, 18)
bonus.Font = Enum.Font.GothamMedium
bonus.TextSize = 11
bonus.Parent = card

local barBack = Instance.new("Frame")
barBack.Position = UDim2.fromOffset(14, 77)
barBack.Size = UDim2.new(1, -28, 0, 8)
barBack.BackgroundColor3 = Color3.fromRGB(52, 58, 70)
barBack.Parent = card
Instance.new("UICorner", barBack).CornerRadius = UDim.new(1, 0)
local bar = Instance.new("Frame")
bar.Size = UDim2.fromScale(0, 1)
bar.BackgroundColor3 = Color3.fromRGB(95, 220, 145)
bar.Parent = barBack
Instance.new("UICorner", bar).CornerRadius = UDim.new(1, 0)

local footer = title:Clone()
footer.Position = UDim2.fromOffset(14, 88)
footer.Size = UDim2.new(1, -28, 0, 13)
footer.Font = Enum.Font.GothamMedium
footer.TextSize = 9
footer.TextColor3 = Color3.fromRGB(140, 151, 174)
footer.Parent = card

local lastPulse = tonumber(player:GetAttribute("HeistContractPulse")) or 0

local function refresh()
	local tier = tonumber(player:GetAttribute("HeistContractTier")) or 1
	local name = tostring(player:GetAttribute("HeistContractName") or "QUICK LIFT")
	local start = tonumber(player:GetAttribute("HeistContractStart")) or 0
	local target = tonumber(player:GetAttribute("HeistContractTarget")) or 3
	local progress = tonumber(player:GetAttribute("HeistContractProgress")) or 0
	local reward = tonumber(player:GetAttribute("HeistContractReward")) or 100
	local streakGoal = tonumber(player:GetAttribute("HeistContractStreakGoal")) or 2
	local streak = tonumber(player:GetAttribute("HeistContractStreak")) or 0
	local bonusReward = tonumber(player:GetAttribute("HeistContractBonusReward")) or 80
	local needed = math.max(1, target - start)
	local current = math.clamp(progress - start, 0, needed)
	title.Text = string.format("HEIST CONTRACT TIER %d • %s", tier, name)
	detail.Text = string.format("Secure %d/%d rivals • Base reward $%d", current, needed, reward)

	if streak >= streakGoal then
		bonus.Text = string.format("✓ STREAK BONUS READY • %dx streak • +$%d", streakGoal, bonusReward)
		bonus.TextColor3 = Color3.fromRGB(255, 211, 105)
	else
		bonus.Text = string.format("Bonus: reach %dx streak before completion • +$%d", streakGoal, bonusReward)
		bonus.TextColor3 = Color3.fromRGB(174, 182, 201)
	end

	footer.Text = "Contracts scale forever • successful snatches advance the next tier"
	TweenService:Create(bar, TweenInfo.new(0.2), {Size = UDim2.fromScale(current / needed, 1)}):Play()

	local pulse = tonumber(player:GetAttribute("HeistContractPulse")) or 0
	if pulse > lastPulse then
		local original = card.Size
		card.Size = UDim2.fromOffset(original.X.Offset + 20, original.Y.Offset + 7)
		TweenService:Create(card, TweenInfo.new(0.27, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Size = original,
		}):Play()
	end
	lastPulse = math.max(lastPulse, pulse)
end
for _, name in ipairs({
	"HeistContractTier",
	"HeistContractName",
	"HeistContractStart",
	"HeistContractTarget",
	"HeistContractProgress",
	"HeistContractReward",
	"HeistContractStreakGoal",
	"HeistContractStreak",
	"HeistContractBonusReward",
	"HeistContractPulse",
}) do
	player:GetAttributeChangedSignal(name):Connect(refresh)
end

local function adapt()
	local camera = workspace.CurrentCamera
	if not camera then return end
	if camera.ViewportSize.X < 760 then
		card.Position = UDim2.new(0.5, 0, 0, 56)
		card.Size = UDim2.new(0.86, 0, 0, 96)
		title.TextSize = 12
		detail.TextSize = 10
		bonus.TextSize = 9
	else
		card.Position = UDim2.new(0.5, 0, 0, 78)
		card.Size = UDim2.fromOffset(350, 104)
		title.TextSize = 15
		detail.TextSize = 12
		bonus.TextSize = 11
	end
end

local camera = workspace.CurrentCamera
if camera then
	camera:GetPropertyChangedSignal("ViewportSize"):Connect(adapt)
end

refresh()
adapt()
