-- Keeps the default screen readable. Critical heist/threat UI stays visible; secondary panels are one click away.

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local SECONDARY_GUIS = {
	DistrictActivityHUD = true,
	HeistContractHUD = true,
	MarketEventHUD = true,
	MasteryHUD = true,
	LifetimeProgressUI = true,
	RarityBountyHUD = true,
	RunMomentumHUD = true,
}

local MAIN_SECONDARY = {
	Title = true,
	Missions = true,
	DataStatus = true,
	Hint = true,
}

local expanded = false

local gui = Instance.new("ScreenGui")
gui.Name = "HUDController"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.DisplayOrder = 100
gui.Parent = playerGui

local button = Instance.new("TextButton")
button.Name = "Toggle"
button.AnchorPoint = Vector2.new(0, 1)
button.Position = UDim2.new(0, 12, 1, -12)
button.Size = UDim2.fromOffset(76, 34)
button.BackgroundColor3 = Color3.fromRGB(18, 22, 30)
button.BackgroundTransparency = 0.08
button.TextColor3 = Color3.fromRGB(230, 236, 247)
button.TextSize = 13
button.Font = Enum.Font.GothamBold
button.AutoButtonColor = true
button.Text = "HUD +"
button.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = button

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(92, 108, 142)
stroke.Transparency = 0.45
stroke.Thickness = 1
stroke.Parent = button

local function applyMainVisibility()
	local mainGui = playerGui:FindFirstChild("SnatchTheStickmanUI")
	local root = mainGui and mainGui:FindFirstChild("Root")
	if not root then return end

	for name in pairs(MAIN_SECONDARY) do
		local item = root:FindFirstChild(name)
		if item and item:IsA("GuiObject") then
			item.Visible = expanded
		end
	end
end

local function applyGui(screenGui)
	if not screenGui:IsA("ScreenGui") then return end
	if SECONDARY_GUIS[screenGui.Name] then
		screenGui.Enabled = expanded
	elseif screenGui.Name == "SnatchTheStickmanUI" then
		task.defer(applyMainVisibility)
	end
end

local function applyAll()
	button.Text = expanded and "HUD −" or "HUD +"
	for _, child in ipairs(playerGui:GetChildren()) do
		applyGui(child)
	end
	applyMainVisibility()
end

local function toggle()
	expanded = not expanded
	applyAll()
end

button.Activated:Connect(toggle)

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	if input.KeyCode == Enum.KeyCode.H then
		toggle()
	end
end)

playerGui.ChildAdded:Connect(function(child)
	task.defer(applyGui, child)
end)

applyAll()
