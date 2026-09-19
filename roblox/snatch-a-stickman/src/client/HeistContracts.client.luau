local Players = game:GetService("Players")

local player = Players.LocalPlayer
local gui = Instance.new("ScreenGui")
gui.Name = "HeistContractHUD"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local card = Instance.new("Frame")
card.Name = "Card"
card.AnchorPoint = Vector2.new(0.5, 0)
card.Position = UDim2.new(0.5, 0, 0, 78)
card.Size = UDim2.fromOffset(330, 74)
card.BackgroundColor3 = Color3.fromRGB(18, 21, 29)
card.BackgroundTransparency = 0.08
card.Parent = gui
Instance.new("UICorner", card).CornerRadius = UDim.new(0, 12)

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(95, 220, 145)
stroke.Transparency = 0.35
stroke.Parent = card

local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.Position = UDim2.fromOffset(14, 8)
title.Size = UDim2.new(1, -28, 0, 24)
title.Font = Enum.Font.GothamBold
title.TextSize = 16
title.TextColor3 = Color3.new(1, 1, 1)
title.TextXAlignment = Enum.TextXAlignment.Left
title.Text = "HEIST CONTRACT"
title.Parent = card

local detail = title:Clone()
detail.Position = UDim2.fromOffset(14, 34)
detail.Size = UDim2.new(1, -28, 0, 20)
detail.Font = Enum.Font.Gotham
detail.TextSize = 14
detail.TextColor3 = Color3.fromRGB(205, 212, 224)
detail.Parent = card

local barBack = Instance.new("Frame")
barBack.Position = UDim2.fromOffset(14, 59)
barBack.Size = UDim2.new(1, -28, 0, 6)
barBack.BackgroundColor3 = Color3.fromRGB(52, 58, 70)
barBack.Parent = card
Instance.new("UICorner", barBack).CornerRadius = UDim.new(1, 0)

local bar = Instance.new("Frame")
bar.Size = UDim2.fromScale(0, 1)
bar.BackgroundColor3 = Color3.fromRGB(95, 220, 145)
bar.Parent = barBack
Instance.new("UICorner", bar).CornerRadius = UDim.new(1, 0)

local function refresh()
	local start = player:GetAttribute("HeistContractStart") or 0
	local target = player:GetAttribute("HeistContractTarget") or 3
	local progress = player:GetAttribute("HeistContractProgress") or 0
	local reward = player:GetAttribute("HeistContractReward") or 90
	local needed = math.max(1, target - start)
	local current = math.clamp(progress - start, 0, needed)
	detail.Text = string.format("Secure %d/%d rival stickmen  •  Reward $%d", current, needed, reward)
	bar.Size = UDim2.fromScale(current / needed, 1)
end

for _, name in ipairs({"HeistContractStart", "HeistContractTarget", "HeistContractProgress", "HeistContractReward"}) do
	player:GetAttributeChangedSignal(name):Connect(refresh)
end
refresh()
