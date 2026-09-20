local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

while player.Parent and player:GetAttribute("DataReady") ~= true do
	task.wait(0.1)
end

local profile = player:WaitForChild("Profile")
local totalRecruits = profile:WaitForChild("TotalRecruits")
local collectionData = profile:WaitForChild("CollectionData")

-- Returning players should not be forced through first-session guidance every join.
if totalRecruits.Value > 0 or collectionData.Value ~= "[]" then
	return
end

local world = workspace:WaitForChild("SnatchTheStickmanWorld")
local leaderstats = player:WaitForChild("leaderstats")
local coins = leaderstats:WaitForChild("Coins")

-- First-session onboarding is intentionally inferred from replicated game state.
-- That keeps the tutorial server-authoritative: it never awards currency or mutates gameplay.
local gui = Instance.new("ScreenGui")
gui.Name = "FirstSessionGuide"
gui.ResetOnSpawn = false
gui.DisplayOrder = 20
gui.Parent = playerGui

local card = Instance.new("Frame")
card.AnchorPoint = Vector2.new(0, 0.5)
card.Position = UDim2.new(0, 18, 0.5, 0)
card.Size = UDim2.fromOffset(290, 150)
card.BackgroundColor3 = Color3.fromRGB(17, 19, 27)
card.BackgroundTransparency = 0.08
card.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 16)
corner.Parent = card

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(82, 230, 139)
stroke.Transparency = 0.35
stroke.Thickness = 2
stroke.Parent = card

local padding = Instance.new("UIPadding")
padding.PaddingTop = UDim.new(0, 14)
padding.PaddingBottom = UDim.new(0, 14)
padding.PaddingLeft = UDim.new(0, 16)
padding.PaddingRight = UDim.new(0, 16)
padding.Parent = card

local heading = Instance.new("TextLabel")
heading.Size = UDim2.new(1, 0, 0, 24)
heading.BackgroundTransparency = 1
heading.Text = "GET STARTED  •  1 / 4"
heading.TextColor3 = Color3.fromRGB(113, 255, 159)
heading.TextXAlignment = Enum.TextXAlignment.Left
heading.Font = Enum.Font.GothamBold
heading.TextSize = 15
heading.Parent = card

local objective = Instance.new("TextLabel")
objective.Position = UDim2.fromOffset(0, 31)
objective.Size = UDim2.new(1, 0, 0, 48)
objective.BackgroundTransparency = 1
objective.Text = "Recruit your first stickman"
objective.TextColor3 = Color3.fromRGB(255, 255, 255)
objective.TextWrapped = true
objective.TextXAlignment = Enum.TextXAlignment.Left
objective.TextYAlignment = Enum.TextYAlignment.Top
objective.Font = Enum.Font.GothamBlack
objective.TextSize = 19
objective.Parent = card

local detail = Instance.new("TextLabel")
detail.Position = UDim2.fromOffset(0, 84)
detail.Size = UDim2.new(1, 0, 0, 34)
detail.BackgroundTransparency = 1
detail.Text = "Find an affordable stickman in the center market and use its Recruit prompt."
detail.TextColor3 = Color3.fromRGB(196, 201, 215)
detail.TextWrapped = true
detail.TextXAlignment = Enum.TextXAlignment.Left
detail.TextYAlignment = Enum.TextYAlignment.Top
detail.Font = Enum.Font.GothamMedium
detail.TextSize = 12
detail.Parent = card

local barBack = Instance.new("Frame")
barBack.AnchorPoint = Vector2.new(0, 1)
barBack.Position = UDim2.new(0, 0, 1, 0)
barBack.Size = UDim2.new(1, 0, 0, 7)
barBack.BackgroundColor3 = Color3.fromRGB(43, 47, 60)
barBack.Parent = card

local barCorner = Instance.new("UICorner")
barCorner.CornerRadius = UDim.new(1, 0)
barCorner.Parent = barBack

local bar = Instance.new("Frame")
bar.Size = UDim2.fromScale(0.25, 1)
bar.BackgroundColor3 = Color3.fromRGB(82, 230, 139)
bar.Parent = barBack

local barFillCorner = Instance.new("UICorner")
barFillCorner.CornerRadius = UDim.new(1, 0)
barFillCorner.Parent = bar

local steps = {
	{
		Title = "Recruit your first stickman",
		Detail = "Find an affordable stickman in the center market and use its Recruit prompt.",
	},
	{
		Title = "Collect your first payday",
		Detail = "Owned stickmen pay automatically. Watch your coin total rise before spending again.",
	},
	{
		Title = "Try your base shield",
		Detail = "Return to your base and activate the purple shield button. Timing it protects your crew.",
	},
	{
		Title = "Learn the escape route",
		Detail = "Your green SECURE pad finishes a steal. Remember its location before raiding another base.",
	},
}

local step = 1
local startingCoins = coins.Value
local coinsAfterRecruit = nil
local recruited = false
local paydaySeen = false
local shieldSeen = false
local secureVisited = false
local lastRootPosition = nil

local function ownsAnyStickman()
	for _, descendant in ipairs(world:GetChildren()) do
		if descendant:IsA("Model") and descendant:GetAttribute("OwnerUserId") == player.UserId then
			return true
		end
	end
	return false
end

local function getOwnedPlot()
	for _, candidate in ipairs(world:GetChildren()) do
		if candidate:IsA("Model") and candidate.Name:match("^Plot%d+$") then
			local sign = candidate:FindFirstChild("Sign")
			local surface = sign and sign:FindFirstChildOfClass("SurfaceGui")
			local label = surface and surface:FindFirstChild("OwnerLabel")
			if label and label.Text == player.DisplayName .. "'s Base" then
				return candidate
			end
		end
	end
	return nil
end

local function showStep(index)
	step = index
	if step > #steps then
		heading.Text = "READY TO SNATCH"
		objective.Text = "You know the loop."
		detail.Text = "Build income, protect your crew, snatch rivals, and press B to complete your permanent Stickman Index."
		TweenService:Create(bar, TweenInfo.new(0.25), {Size = UDim2.fromScale(1, 1)}):Play()
		task.delay(4, function()
			if card.Parent then
				TweenService:Create(card, TweenInfo.new(0.35), {Position = UDim2.new(0, -320, 0.5, 0)}):Play()
				task.wait(0.4)
				gui:Destroy()
			end
		end)
		return
	end

	heading.Text = string.format("GET STARTED  •  %d / %d", step, #steps)
	objective.Text = steps[step].Title
	detail.Text = steps[step].Detail
	TweenService:Create(bar, TweenInfo.new(0.22), {Size = UDim2.fromScale(step / #steps, 1)}):Play()

	card.Size = UDim2.fromOffset(300, 154)
	TweenService:Create(card, TweenInfo.new(0.16, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.fromOffset(290, 150),
	}):Play()
end

coins:GetPropertyChangedSignal("Value"):Connect(function()
	if recruited and coinsAfterRecruit and coins.Value > coinsAfterRecruit then
		paydaySeen = true
	end
end)

local scanAccumulator = 0
local connection
connection = RunService.Heartbeat:Connect(function(dt)
	scanAccumulator += dt
	if scanAccumulator < 0.25 or not gui.Parent then
		return
	end
	scanAccumulator = 0

	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if root then
		lastRootPosition = root.Position
	end

	if step == 1 and ownsAnyStickman() then
		recruited = true
		coinsAfterRecruit = coins.Value
		showStep(2)
	elseif step == 2 and paydaySeen then
		showStep(3)
	elseif step == 3 then
		local plot = getOwnedPlot()
		local shield = plot and plot:FindFirstChild("ShieldVisual")
		if shield and shield.Transparency < 0.9 then
			shieldSeen = true
			showStep(4)
		end
	elseif step == 4 then
		local plot = getOwnedPlot()
		local pad = plot and plot:FindFirstChild("SecurePad")
		if pad and lastRootPosition and (lastRootPosition - pad.Position).Magnitude <= 10 then
			secureVisited = true
			showStep(5)
			if connection then
				connection:Disconnect()
			end
		end
	end
end)

-- If a Studio hot reload catches a player already progressing, skip stale early steps.
task.delay(1, function()
	if gui.Parent and ownsAnyStickman() and step == 1 then
		recruited = true
		coinsAfterRecruit = coins.Value
		showStep(2)
	end
end)