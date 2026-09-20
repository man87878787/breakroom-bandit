local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local ranks = Config.RUN_MOMENTUM.Ranks

local player = Players.LocalPlayer
local gui = Instance.new("ScreenGui")
gui.Name = "RunMomentumHUD"
gui.ResetOnSpawn = false
gui.DisplayOrder = 10
gui.Parent = player:WaitForChild("PlayerGui")

local card = Instance.new("Frame")
card.Name = "Card"
card.AnchorPoint = Vector2.new(1, 0)
card.Position = UDim2.new(1, -18, 0, 78)
card.Size = UDim2.fromOffset(292, 116)
card.BackgroundColor3 = Color3.fromRGB(18, 21, 29)
card.BackgroundTransparency = 0.06
card.Parent = gui
Instance.new("UICorner", card).CornerRadius = UDim.new(0, 13)

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(255, 195, 70)
stroke.Transparency = 0.35
stroke.Thickness = 1.5
stroke.Parent = card
local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.Position = UDim2.fromOffset(14, 7)
title.Size = UDim2.new(1, -28, 0, 22)
title.Font = Enum.Font.GothamBlack
title.TextSize = 15
title.TextColor3 = Color3.fromRGB(255, 211, 105)
title.TextXAlignment = Enum.TextXAlignment.Left
title.Text = "RUN MOMENTUM"
title.Parent = card

local rankLabel = title:Clone()
rankLabel.Position = UDim2.fromOffset(14, 29)
rankLabel.Size = UDim2.new(1, -28, 0, 18)
rankLabel.Font = Enum.Font.GothamBold
rankLabel.TextSize = 12
rankLabel.Parent = card

local objective = title:Clone()
objective.Position = UDim2.fromOffset(14, 49)
objective.Size = UDim2.new(1, -28, 0, 28)
objective.Font = Enum.Font.Gotham
objective.TextSize = 12
objective.TextWrapped = true
objective.TextColor3 = Color3.fromRGB(230, 233, 240)
objective.Parent = card

local barBack = Instance.new("Frame")
barBack.Position = UDim2.fromOffset(14, 79)
barBack.Size = UDim2.new(1, -28, 0, 7)
barBack.BackgroundColor3 = Color3.fromRGB(52, 58, 70)
barBack.Parent = card
Instance.new("UICorner", barBack).CornerRadius = UDim.new(1, 0)
local bar = Instance.new("Frame")
bar.Size = UDim2.fromScale(0, 1)
bar.BackgroundColor3 = Color3.fromRGB(255, 195, 70)
bar.Parent = barBack
Instance.new("UICorner", bar).CornerRadius = UDim.new(1, 0)

local stats = title:Clone()
stats.Position = UDim2.fromOffset(14, 91)
stats.Size = UDim2.new(1, -28, 0, 18)
stats.Font = Enum.Font.GothamMedium
stats.TextSize = 11
stats.TextColor3 = Color3.fromRGB(165, 175, 192)
stats.Parent = card

local function rankColor(rank)
	if rank == "LEGEND" then return Color3.fromRGB(255, 110, 210) end
	if rank == "DIAMOND" then return Color3.fromRGB(130, 220, 255) end
	if rank == "GOLD" then return Color3.fromRGB(255, 205, 80) end
	if rank == "SILVER" then return Color3.fromRGB(205, 214, 230) end
	if rank == "BRONZE" then return Color3.fromRGB(215, 145, 85) end
	return Color3.fromRGB(170, 178, 194)
end

local lastScore = -1
local lastPulse = tonumber(player:GetAttribute("SessionRunRankPulse")) or 0
local function refresh()
	local score = tonumber(player:GetAttribute("SessionRunScore")) or 0
	local seconds = tonumber(player:GetAttribute("SessionRunSeconds")) or 0
	local objectiveText = tostring(player:GetAttribute("SessionRunObjective") or "Build your crew")
	local rank = tostring(player:GetAttribute("SessionRunRank") or "ROOKIE")
	local nextRank = tostring(player:GetAttribute("SessionRunNextRank") or "BRONZE")
	local nextScore = tonumber(player:GetAttribute("SessionRunNextRankScore")) or (ranks[2] and ranks[2].Score or 250)
	local progress = tonumber(player:GetAttribute("SessionRunRankProgress")) or 0
	local color = rankColor(rank)

	rankLabel.Text = nextRank == "MAX"
		and string.format("%s • MAX RUN RANK", rank)
		or string.format("%s → %s at %d", rank, nextRank, nextScore)
	rankLabel.TextColor3 = color
	stroke.Color = color
	bar.BackgroundColor3 = color
	objective.Text = objectiveText
	stats.Text = string.format("Score %d   •   %d:%02d", score, math.floor(seconds / 60), seconds % 60)

	TweenService:Create(bar, TweenInfo.new(0.22), {
		Size = UDim2.fromScale(math.clamp(progress, 0, 1), 1),
	}):Play()

	local pulse = tonumber(player:GetAttribute("SessionRunRankPulse")) or 0
	if pulse > lastPulse then
		local original = card.Size
		card.Size = UDim2.fromOffset(original.X.Offset + 18, original.Y.Offset + 6)
		TweenService:Create(card, TweenInfo.new(0.26, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Size = original,
		}):Play()
	end

	if lastScore >= 0 and score > lastScore and pulse == lastPulse then
		local original = card.Size
		card.Size = UDim2.fromOffset(original.X.Offset + 8, original.Y.Offset + 3)
		TweenService:Create(card, TweenInfo.new(0.18, Enum.EasingStyle.Back), {Size = original}):Play()
	end
	lastScore = score
	lastPulse = math.max(lastPulse, pulse)
end
for _, name in ipairs({
	"SessionRunScore",
	"SessionRunSeconds",
	"SessionRunObjective",
	"SessionRunRank",
	"SessionRunNextRank",
	"SessionRunNextRankScore",
	"SessionRunRankProgress",
	"SessionRunRankPulse",
}) do
	player:GetAttributeChangedSignal(name):Connect(refresh)
end

local function adapt()
	local camera = workspace.CurrentCamera
	if not camera then return end
	if camera.ViewportSize.X < 760 then
		card.Position = UDim2.new(1, -12, 0, 232)
		card.Size = UDim2.fromOffset(245, 108)
		title.TextSize = 13
		rankLabel.TextSize = 10
		objective.TextSize = 10
		stats.TextSize = 9
	else
		card.Position = UDim2.new(1, -18, 0, 242)
		card.Size = UDim2.fromOffset(292, 116)
		title.TextSize = 15
		rankLabel.TextSize = 12
		objective.TextSize = 12
		stats.TextSize = 11
	end
end

local camera = workspace.CurrentCamera
if camera then
	camera:GetPropertyChangedSignal("ViewportSize"):Connect(adapt)
end

refresh()
adapt()
