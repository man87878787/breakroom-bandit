local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Net = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Net"))

local stateChanged = Net.Get("StateChanged")
local toastRemote = Net.Get("Toast")
local upgradeRemote = Net.Get("RequestTowerUpgrade")
local bankRemote = Net.Get("RequestBankSteal")

local gui = Instance.new("ScreenGui")
gui.Name = "MainHUD"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = player:WaitForChild("PlayerGui")

local function addCorner(parent, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius or 12)
	corner.Parent = parent
	return corner
end

local function addStroke(parent, transparency)
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(255, 255, 255)
	stroke.Transparency = transparency or 0.82
	stroke.Thickness = 1
	stroke.Parent = parent
	return stroke
end

local panel = Instance.new("Frame")
panel.Name = "Status"
panel.Position = UDim2.fromOffset(18, 18)
panel.Size = UDim2.fromOffset(278, 132)
panel.BackgroundColor3 = Color3.fromRGB(17, 20, 29)
panel.BackgroundTransparency = 0.08
panel.Parent = gui
addCorner(panel, 14)
addStroke(panel, 0.86)

local padding = Instance.new("UIPadding")
padding.PaddingLeft = UDim.new(0, 16)
padding.PaddingRight = UDim.new(0, 16)
padding.PaddingTop = UDim.new(0, 13)
padding.PaddingBottom = UDim.new(0, 13)
padding.Parent = panel

local title = Instance.new("TextLabel")
title.Name = "Title"
title.Size = UDim2.new(1, 0, 0, 24)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBlack
title.Text = "STEAL A TOWER OF HELL"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextSize = 15
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = panel

local stats = Instance.new("TextLabel")
stats.Name = "Stats"
stats.Position = UDim2.fromOffset(0, 31)
stats.Size = UDim2.new(1, 0, 1, -31)
stats.BackgroundTransparency = 1
stats.Font = Enum.Font.GothamMedium
stats.TextColor3 = Color3.fromRGB(218, 222, 235)
stats.TextSize = 15
stats.TextWrapped = true
stats.TextXAlignment = Enum.TextXAlignment.Left
stats.TextYAlignment = Enum.TextYAlignment.Top
stats.Text = "Loading your tower..."
stats.Parent = panel

local objective = Instance.new("Frame")
objective.Name = "Objective"
objective.AnchorPoint = Vector2.new(0.5, 0)
objective.Position = UDim2.new(0.5, 0, 0, 18)
objective.Size = UDim2.new(0, 430, 0, 70)
objective.BackgroundColor3 = Color3.fromRGB(21, 26, 37)
objective.BackgroundTransparency = 0.03
objective.Visible = false
objective.Parent = gui
addCorner(objective, 14)
addStroke(objective, 0.72)

local objectiveTitle = Instance.new("TextLabel")
objectiveTitle.Size = UDim2.new(1, -24, 0, 27)
objectiveTitle.Position = UDim2.fromOffset(12, 9)
objectiveTitle.BackgroundTransparency = 1
objectiveTitle.Font = Enum.Font.GothamBlack
objectiveTitle.Text = "ESCAPE WITH THE CORE"
objectiveTitle.TextColor3 = Color3.fromRGB(255, 211, 78)
objectiveTitle.TextSize = 18
objectiveTitle.TextXAlignment = Enum.TextXAlignment.Center
objectiveTitle.Parent = objective

local objectiveText = Instance.new("TextLabel")
objectiveText.Size = UDim2.new(1, -24, 0, 24)
objectiveText.Position = UDim2.fromOffset(12, 38)
objectiveText.BackgroundTransparency = 1
objectiveText.Font = Enum.Font.GothamMedium
objectiveText.TextColor3 = Color3.fromRGB(235, 237, 244)
objectiveText.TextSize = 14
objectiveText.TextXAlignment = Enum.TextXAlignment.Center
objectiveText.Parent = objective

local function makeActionButton(name, anchor, position, color)
	local button = Instance.new("TextButton")
	button.Name = name
	button.AnchorPoint = anchor
	button.Position = position
	button.Size = UDim2.fromOffset(210, 52)
	button.BackgroundColor3 = color
	button.AutoButtonColor = true
	button.Font = Enum.Font.GothamBlack
	button.TextColor3 = Color3.new(1, 1, 1)
	button.TextSize = 15
	button.TextWrapped = true
	button.Parent = gui
	addCorner(button, 13)
	addStroke(button, 0.84)
	return button
end

local upgrade = makeActionButton(
	"Upgrade",
	Vector2.new(0, 1),
	UDim2.new(0, 18, 1, -18),
	Color3.fromRGB(107, 91, 255)
)
upgrade.Text = "UPGRADE TOWER"

local bank = makeActionButton(
	"Bank",
	Vector2.new(1, 1),
	UDim2.new(1, -18, 1, -18),
	Color3.fromRGB(67, 205, 126)
)
bank.TextColor3 = Color3.fromRGB(12, 27, 20)
bank.Text = "BANK STOLEN CORE"
bank.Visible = false

local hint = Instance.new("TextLabel")
hint.Name = "Hint"
hint.AnchorPoint = Vector2.new(0.5, 1)
hint.Position = UDim2.new(0.5, 0, 1, -22)
hint.Size = UDim2.new(0.52, 0, 0, 42)
hint.BackgroundTransparency = 1
hint.Font = Enum.Font.GothamMedium
hint.TextColor3 = Color3.fromRGB(208, 211, 224)
hint.TextTransparency = 0.08
hint.TextSize = 14
hint.TextWrapped = true
hint.Text = "Climb a rival tower • Steal its core • Escape to your green vault"
hint.Parent = gui

local toast = Instance.new("TextLabel")
toast.Name = "Toast"
toast.AnchorPoint = Vector2.new(0.5, 0)
toast.Position = UDim2.new(0.5, 0, 0, 98)
toast.Size = UDim2.new(0, 470, 0, 48)
toast.BackgroundColor3 = Color3.fromRGB(15, 18, 27)
toast.BackgroundTransparency = 1
toast.TextColor3 = Color3.new(1, 1, 1)
toast.TextTransparency = 1
toast.TextSize = 15
toast.TextWrapped = true
toast.Font = Enum.Font.GothamBold
toast.Visible = false
toast.Parent = gui
addCorner(toast, 12)
addStroke(toast, 0.78)

local toastVersion = 0
local toastTween
local function showToast(text)
	toastVersion += 1
	local version = toastVersion

	if toastTween then
		toastTween:Cancel()
	end

	toast.Text = tostring(text)
	toast.Visible = true
	toast.BackgroundTransparency = 1
	toast.TextTransparency = 1

	toastTween = TweenService:Create(
		toast,
		TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ BackgroundTransparency = 0.08, TextTransparency = 0 }
	)
	toastTween:Play()

	task.delay(3, function()
		if version ~= toastVersion then
			return
		end

		local fade = TweenService:Create(
			toast,
			TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{ BackgroundTransparency = 1, TextTransparency = 1 }
		)
		fade:Play()
		fade.Completed:Wait()
		if version == toastVersion then
			toast.Visible = false
		end
	end)
end

local function formatNumber(value)
	local text = tostring(math.max(0, math.floor(tonumber(value) or 0)))
	local formatted = text:reverse():gsub("(%d%d%d)", "%1,"):reverse()
	if formatted:sub(1, 1) == "," then
		formatted = formatted:sub(2)
	end
	return formatted
end

local currentState = {
	Coins = Config.PLAYER.StartingCoins,
	TowerLevel = 1,
	FloorCount = Config.TOWERS.BaseFloorCount,
	PlotIndex = 0,
	NextUpgradeCost = Config.GetTowerUpgradeCost(1),
	Steals = 0,
	TimesRobbed = 0,
	CarryingSteal = false,
	StealReward = 0,
	StolenFrom = "",
}

local function render(state)
	for key, value in pairs(state) do
		currentState[key] = value
	end

	local carrying = currentState.CarryingSteal == true
	local towerLevel = tonumber(currentState.TowerLevel) or 1
	local maxed = towerLevel >= Config.PLAYER.MaxTowerLevel
	local plotIndex = tonumber(currentState.PlotIndex) or 0
	local floorCount = tonumber(currentState.FloorCount) or 0

	stats.Text = string.format(
		"COINS   %s\nTOWER   LV.%d   •   %d FLOORS\nPLOT   %s   •   STEALS   %d",
		formatNumber(currentState.Coins),
		towerLevel,
		floorCount,
		plotIndex > 0 and ("#" .. tostring(plotIndex)) or "WAITING",
		tonumber(currentState.Steals) or 0
	)

	if maxed then
		upgrade.Text = "TOWER MAXED"
		upgrade.BackgroundColor3 = Color3.fromRGB(70, 75, 91)
		upgrade.AutoButtonColor = false
	else
		upgrade.Text = string.format("UPGRADE TOWER  •  %s", formatNumber(currentState.NextUpgradeCost))
		upgrade.BackgroundColor3 = Color3.fromRGB(107, 91, 255)
		upgrade.AutoButtonColor = true
	end

	objective.Visible = carrying
	bank.Visible = carrying
	if carrying then
		local fromName = tostring(currentState.StolenFrom or "")
		objectiveText.Text = string.format(
			"Return to your green vault  •  +%s coins%s",
			formatNumber(currentState.StealReward),
			fromName ~= "" and ("  •  " .. fromName) or ""
		)
		hint.Text = "You are carrying a stolen core — get back to YOUR green vault!"
	else
		hint.Text = "Climb a rival tower • Steal its core • Escape to your green vault"
	end
end

stateChanged.OnClientEvent:Connect(render)
toastRemote.OnClientEvent:Connect(showToast)

upgrade.Activated:Connect(function()
	if (tonumber(currentState.TowerLevel) or 1) < Config.PLAYER.MaxTowerLevel then
		upgradeRemote:FireServer()
	end
end)

bank.Activated:Connect(function()
	if currentState.CarryingSteal == true then
		bankRemote:FireServer()
	end
end)

UserInputService.InputBegan:Connect(function(input, processed)
	if processed or UserInputService:GetFocusedTextBox() then
		return
	end

	if input.KeyCode == Enum.KeyCode.U then
		upgradeRemote:FireServer()
	elseif input.KeyCode == Enum.KeyCode.B and currentState.CarryingSteal == true then
		bankRemote:FireServer()
	end
end)

if UserInputService.TouchEnabled then
	panel.Position = UDim2.fromOffset(12, 12)
	panel.Size = UDim2.fromOffset(248, 124)
	objective.Position = UDim2.new(0.5, 0, 0, 12)
	objective.Size = UDim2.new(0.72, 0, 0, 70)
	upgrade.Position = UDim2.new(0, 12, 1, -12)
	upgrade.Size = UDim2.fromOffset(176, 52)
	bank.Position = UDim2.new(1, -12, 1, -12)
	bank.Size = UDim2.fromOffset(176, 52)
	hint.Visible = false
	toast.Size = UDim2.new(0.82, 0, 0, 48)
end

render(currentState)
