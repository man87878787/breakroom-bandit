local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
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
gui.Parent = player:WaitForChild("PlayerGui")

local panel = Instance.new("Frame")
panel.Name = "Status"
panel.AnchorPoint = Vector2.new(0, 0)
panel.Position = UDim2.fromOffset(18, 18)
panel.Size = UDim2.fromOffset(250, 106)
panel.BackgroundColor3 = Color3.fromRGB(20, 23, 32)
panel.BackgroundTransparency = 0.08
panel.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = panel

local padding = Instance.new("UIPadding")
padding.PaddingLeft = UDim.new(0, 14)
padding.PaddingRight = UDim.new(0, 14)
padding.PaddingTop = UDim.new(0, 11)
padding.PaddingBottom = UDim.new(0, 11)
padding.Parent = panel

local label = Instance.new("TextLabel")
label.Name = "Stats"
label.Size = UDim2.fromScale(1, 1)
label.BackgroundTransparency = 1
label.Font = Enum.Font.GothamBold
label.TextColor3 = Color3.new(1, 1, 1)
label.TextSize = 17
label.TextWrapped = true
label.TextXAlignment = Enum.TextXAlignment.Left
label.TextYAlignment = Enum.TextYAlignment.Top
label.Text = "Loading tower..."
label.Parent = panel

local upgrade = Instance.new("TextButton")
upgrade.Name = "Upgrade"
upgrade.AnchorPoint = Vector2.new(0, 1)
upgrade.Position = UDim2.new(0, 18, 1, -18)
upgrade.Size = UDim2.fromOffset(190, 48)
upgrade.BackgroundColor3 = Color3.fromRGB(112, 92, 255)
upgrade.Text = "UPGRADE TOWER"
upgrade.TextColor3 = Color3.new(1, 1, 1)
upgrade.TextSize = 16
upgrade.Font = Enum.Font.GothamBlack
upgrade.AutoButtonColor = true
upgrade.Parent = gui
Instance.new("UICorner", upgrade).CornerRadius = UDim.new(0, 12)

local bank = Instance.new("TextButton")
bank.Name = "Bank"
bank.AnchorPoint = Vector2.new(1, 1)
bank.Position = UDim2.new(1, -18, 1, -18)
bank.Size = UDim2.fromOffset(190, 48)
bank.BackgroundColor3 = Color3.fromRGB(82, 232, 150)
bank.Text = "BANK STEAL"
bank.TextColor3 = Color3.fromRGB(15, 24, 20)
bank.TextSize = 16
bank.Font = Enum.Font.GothamBlack
bank.Visible = false
bank.Parent = gui
Instance.new("UICorner", bank).CornerRadius = UDim.new(0, 12)

local toast = Instance.new("TextLabel")
toast.Name = "Toast"
toast.AnchorPoint = Vector2.new(0.5, 0)
toast.Position = UDim2.new(0.5, 0, 0, 18)
toast.Size = UDim2.new(0.7, 0, 0, 44)
toast.BackgroundColor3 = Color3.fromRGB(18, 21, 29)
toast.BackgroundTransparency = 0.08
toast.TextColor3 = Color3.new(1, 1, 1)
toast.TextSize = 16
toast.Font = Enum.Font.GothamBold
toast.Visible = false
toast.Parent = gui
Instance.new("UICorner", toast).CornerRadius = UDim.new(0, 12)

local toastVersion = 0
local function showToast(text)
	toastVersion += 1
	local version = toastVersion
	toast.Text = tostring(text)
	toast.Visible = true
	task.delay(3, function()
		if version == toastVersion then
			toast.Visible = false
		end
	end)
end

local function render(state)
	local carrying = state.CarryingSteal == true
	label.Text = string.format(
		"COINS  %d\nTOWER  LV.%d\nSTEALS  %d%s",
		tonumber(state.Coins) or 0,
		tonumber(state.TowerLevel) or 1,
		tonumber(state.Steals) or 0,
		carrying and ("\nCARRYING  +" .. tostring(state.StealReward or 0)) or ""
	)
	bank.Visible = carrying
end

stateChanged.OnClientEvent:Connect(render)
toastRemote.OnClientEvent:Connect(showToast)

upgrade.Activated:Connect(function()
	upgradeRemote:FireServer()
end)

bank.Activated:Connect(function()
	bankRemote:FireServer()
end)

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	if input.KeyCode == Enum.KeyCode.U then
		upgradeRemote:FireServer()
	elseif input.KeyCode == Enum.KeyCode.B and bank.Visible then
		bankRemote:FireServer()
	end
end)

render({
	Coins = player:GetAttribute("Coins") or Config.PLAYER.StartingCoins,
	TowerLevel = player:GetAttribute("TowerLevel") or 1,
	Steals = player:GetAttribute("Steals") or 0,
	CarryingSteal = player:GetAttribute("CarryingSteal") == true,
	StealReward = player:GetAttribute("StealReward") or 0,
})
