local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local gui = Instance.new("ScreenGui")
gui.Name = "RunMomentumHUD"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local card = Instance.new("Frame")
card.AnchorPoint = Vector2.new(1, 0)
card.Position = UDim2.new(1, -18, 0, 78)
card.Size = UDim2.fromOffset(280, 86)
card.BackgroundColor3 = Color3.fromRGB(18, 21, 29)
card.BackgroundTransparency = 0.08
card.Parent = gui
Instance.new("UICorner", card).CornerRadius = UDim.new(0, 12)
local stroke = Instance.new("UIStroke", card)
stroke.Color = Color3.fromRGB(255, 195, 70)
stroke.Transparency = 0.35

local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.Position = UDim2.fromOffset(14, 8)
title.Size = UDim2.new(1, -28, 0, 22)
title.Font = Enum.Font.GothamBold
title.TextSize = 15
title.TextColor3 = Color3.fromRGB(255, 211, 105)
title.TextXAlignment = Enum.TextXAlignment.Left
title.Text = "RUN MOMENTUM"
title.Parent = card

local objective = title:Clone()
objective.Position = UDim2.fromOffset(14, 31)
objective.Size = UDim2.new(1, -28, 0, 28)
objective.Font = Enum.Font.Gotham
objective.TextSize = 13
objective.TextWrapped = true
objective.TextColor3 = Color3.fromRGB(230, 233, 240)
objective.Parent = card

local stats = title:Clone()
stats.Position = UDim2.fromOffset(14, 61)
stats.Size = UDim2.new(1, -28, 0, 18)
stats.Font = Enum.Font.GothamMedium
stats.TextSize = 12
stats.TextColor3 = Color3.fromRGB(165, 175, 192)
stats.Parent = card

local lastScore = -1
local function refresh()
	local score = player:GetAttribute("SessionRunScore") or 0
	local seconds = player:GetAttribute("SessionRunSeconds") or 0
	local text = player:GetAttribute("SessionRunObjective") or "Build your crew"
	objective.Text = text
	stats.Text = string.format("Score %d   •   %d:%02d", score, math.floor(seconds / 60), seconds % 60)
	if lastScore >= 0 and score > lastScore then
		local original = card.Size
		card.Size = UDim2.fromOffset(290, 91)
		TweenService:Create(card, TweenInfo.new(0.2, Enum.EasingStyle.Back), {Size = original}):Play()
	end
	lastScore = score
end

for _, name in ipairs({"SessionRunScore", "SessionRunSeconds", "SessionRunObjective"}) do
	player:GetAttributeChangedSignal(name):Connect(refresh)
end
refresh()
