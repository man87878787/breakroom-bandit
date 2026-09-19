local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local toastRemote = ReplicatedStorage:WaitForChild("GameRemotes"):WaitForChild("Toast")

local gui = Instance.new("ScreenGui")
gui.Name = "SnatchAStickmanUI"
gui.ResetOnSpawn = false
gui.Parent = playerGui

local title = Instance.new("TextLabel")
title.AnchorPoint = Vector2.new(0.5, 0)
title.Position = UDim2.fromScale(0.5, 0.025)
title.Size = UDim2.fromOffset(360, 48)
title.BackgroundColor3 = Color3.fromRGB(18, 20, 28)
title.BackgroundTransparency = 0.12
title.Text = "SNATCH A STICKMAN"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextScaled = true
title.Font = Enum.Font.GothamBlack
title.Parent = gui

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 14)
titleCorner.Parent = title

local coinsLabel = Instance.new("TextLabel")
coinsLabel.AnchorPoint = Vector2.new(1, 0)
coinsLabel.Position = UDim2.fromScale(0.98, 0.03)
coinsLabel.Size = UDim2.fromOffset(190, 42)
coinsLabel.BackgroundColor3 = Color3.fromRGB(18, 20, 28)
coinsLabel.BackgroundTransparency = 0.12
coinsLabel.TextColor3 = Color3.fromRGB(113, 255, 159)
coinsLabel.TextScaled = true
coinsLabel.Font = Enum.Font.GothamBold
coinsLabel.Parent = gui

local coinCorner = Instance.new("UICorner")
coinCorner.CornerRadius = UDim.new(0, 12)
coinCorner.Parent = coinsLabel

local hint = Instance.new("TextLabel")
hint.AnchorPoint = Vector2.new(0.5, 1)
hint.Position = UDim2.fromScale(0.5, 0.97)
hint.Size = UDim2.fromOffset(560, 38)
hint.BackgroundTransparency = 1
hint.Text = "Recruit from the market • Earn passive coins • Snatch rivals • Shield your base"
hint.TextColor3 = Color3.fromRGB(230, 232, 240)
hint.TextScaled = true
hint.Font = Enum.Font.GothamMedium
hint.Parent = gui

local toast = Instance.new("TextLabel")
toast.AnchorPoint = Vector2.new(0.5, 0.5)
toast.Position = UDim2.fromScale(0.5, 0.76)
toast.Size = UDim2.fromOffset(460, 54)
toast.BackgroundColor3 = Color3.fromRGB(18, 20, 28)
toast.BackgroundTransparency = 1
toast.TextTransparency = 1
toast.TextColor3 = Color3.fromRGB(255, 255, 255)
toast.TextScaled = true
toast.Font = Enum.Font.GothamBold
toast.Visible = true
toast.Parent = gui

local toastCorner = Instance.new("UICorner")
toastCorner.CornerRadius = UDim.new(0, 14)
toastCorner.Parent = toast

local leaderstats = player:WaitForChild("leaderstats")
local coins = leaderstats:WaitForChild("Coins")

local function refreshCoins()
	coinsLabel.Text = "$" .. tostring(coins.Value)
end

refreshCoins()
coins:GetPropertyChangedSignal("Value"):Connect(refreshCoins)

local toastSerial = 0
toastRemote.OnClientEvent:Connect(function(message)
	toastSerial += 1
	local serial = toastSerial
	toast.Text = tostring(message)

	TweenService:Create(toast, TweenInfo.new(0.16), {
		BackgroundTransparency = 0.12,
		TextTransparency = 0,
	}):Play()

	task.wait(2.3)
	if serial ~= toastSerial then
		return
	end

	TweenService:Create(toast, TweenInfo.new(0.25), {
		BackgroundTransparency = 1,
		TextTransparency = 1,
	}):Play()
end)
