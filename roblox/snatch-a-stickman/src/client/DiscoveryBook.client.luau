local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local player = Players.LocalPlayer
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local discovery = player:WaitForChild("Profile"):WaitForChild("DiscoveryData", 20)
if not discovery then return end

local gui = Instance.new("ScreenGui")
gui.Name = "StickmanDiscoveryUI"
gui.ResetOnSpawn = false
gui.DisplayOrder = 12
gui.Parent = player:WaitForChild("PlayerGui")
local button = Instance.new("TextButton")
button.AnchorPoint = Vector2.new(1, 0)
button.Position = UDim2.new(0.985, 0, 0.19, 0)
button.Size = UDim2.fromOffset(180, 42)
button.BackgroundColor3 = Color3.fromRGB(20, 24, 34)
button.TextColor3 = Color3.fromRGB(235, 240, 255)
button.Font = Enum.Font.GothamBold
button.TextSize = 14
button.Parent = gui
Instance.new("UICorner", button).CornerRadius = UDim.new(0, 12)

local panel = Instance.new("Frame")
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.fromScale(0.5, 0.5)
panel.Size = UDim2.fromOffset(430, 390)
panel.BackgroundColor3 = Color3.fromRGB(14, 17, 25)
panel.Visible = false
panel.Parent = gui
Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 16)
local title = Instance.new("TextLabel")
title.Position = UDim2.fromOffset(18, 12)
title.Size = UDim2.new(1, -36, 0, 32)
title.BackgroundTransparency = 1
title.Text = "STICKMAN DISCOVERY"
title.TextColor3 = Color3.new(1, 1, 1)
title.Font = Enum.Font.GothamBlack
title.TextSize = 20
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = panel
local progress = title:Clone()
progress.Position = UDim2.fromOffset(18, 48)
progress.Size = UDim2.new(1, -36, 0, 24)
progress.Font = Enum.Font.GothamBold
progress.TextSize = 13
progress.TextColor3 = Color3.fromRGB(165, 178, 214)
progress.Parent = panel
local list = Instance.new("Frame")
list.Position = UDim2.fromOffset(18, 82)
list.Size = UDim2.new(1, -36, 1, -100)
list.BackgroundTransparency = 1
list.Parent = panel
local layout = Instance.new("UIListLayout", list)
layout.Padding = UDim.new(0, 8)
local labels = {}
for _, rarity in ipairs(Config.RARITIES) do
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 0, 48)
	label.BackgroundColor3 = Color3.fromRGB(27, 31, 43)
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Font = Enum.Font.GothamBold
	label.TextSize = 14
	label.Parent = list
	Instance.new("UICorner", label).CornerRadius = UDim.new(0, 10)
	labels[rarity.Name] = label
end
local function render()
	local found = {}
	local ok, data = pcall(HttpService.JSONDecode, HttpService, discovery.Value)
	if ok and type(data) == "table" then for _, name in ipairs(data) do found[tostring(name)] = true end end
	local count = 0
	for _, rarity in ipairs(Config.RARITIES) do
		local label = labels[rarity.Name]
		if found[rarity.Name] then
			count += 1
			label.Text = string.format("   ✓ %s   •   +$%d / %ds", rarity.Name, rarity.Income, Config.PASSIVE_TICK)
			label.TextColor3 = rarity.Color
		else
			label.Text = string.format("   ?  UNDISCOVERED   •   Tier %d", rarity.Rank or 1)
			label.TextColor3 = Color3.fromRGB(116, 124, 145)
		end
	end
	local pct = math.floor(count / math.max(1, #Config.RARITIES) * 100 + 0.5)
	progress.Text = string.format("%d / %d discovered  •  %d%% complete", count, #Config.RARITIES, pct)
	button.Text = string.format("COLLECTION  %d/%d", count, #Config.RARITIES)
end
button.Activated:Connect(function() panel.Visible = not panel.Visible end)
discovery.Changed:Connect(render)
render()
