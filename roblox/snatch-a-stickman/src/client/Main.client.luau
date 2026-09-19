local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local remotes = ReplicatedStorage:WaitForChild("GameRemotes")
local toastRemote = remotes:WaitForChild("Toast")
local carryRemote = remotes:WaitForChild("CarryState")
local threatRemote = remotes:WaitForChild("ThreatState")

local leaderstats = player:WaitForChild("leaderstats")
local coins = leaderstats:WaitForChild("Coins")
local profile = player:WaitForChild("Profile")

local gui = Instance.new("ScreenGui")
gui.Name = "SnatchTheStickmanUI"
gui.ResetOnSpawn = false
gui.DisplayOrder = 10
gui.IgnoreGuiInset = false
gui.Parent = playerGui

local root = Instance.new("Frame")
root.Name = "Root"
root.Size = UDim2.fromScale(1, 1)
root.BackgroundTransparency = 1
root.Parent = gui

local function corner(parent, radius)
	local item = Instance.new("UICorner")
	item.CornerRadius = UDim.new(0, radius or 12)
	item.Parent = parent
	return item
end

local function stroke(parent, transparency)
	local item = Instance.new("UIStroke")
	item.Color = Color3.fromRGB(92, 105, 138)
	item.Transparency = transparency or 0.55
	item.Thickness = 1
	item.Parent = parent
	return item
end

local function makeText(parent, name, position, size, text, textColor, font, textSize)
	local item = Instance.new("TextLabel")
	item.Name = name
	item.Position = position
	item.Size = size
	item.BackgroundTransparency = 1
	item.Text = text
	item.TextColor3 = textColor or Color3.fromRGB(255, 255, 255)
	item.Font = font or Enum.Font.GothamMedium
	item.TextSize = textSize or 15
	item.TextXAlignment = Enum.TextXAlignment.Left
	item.TextYAlignment = Enum.TextYAlignment.Center
	item.Parent = parent
	return item
end

local title = Instance.new("TextLabel")
title.AnchorPoint = Vector2.new(0.5, 0)
title.Position = UDim2.fromScale(0.5, 0.018)
title.Size = UDim2.new(0.38, 0, 0, 46)
title.BackgroundColor3 = Color3.fromRGB(15, 18, 26)
title.BackgroundTransparency = 0.08
title.Text = "SNATCH THE STICKMAN"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextScaled = true
title.Font = Enum.Font.GothamBlack
title.Parent = root
corner(title, 14)
stroke(title, 0.5)

local titlePadding = Instance.new("UIPadding")
titlePadding.PaddingLeft = UDim.new(0, 16)
titlePadding.PaddingRight = UDim.new(0, 16)
titlePadding.Parent = title

local stats = Instance.new("Frame")
stats.AnchorPoint = Vector2.new(1, 0)
stats.Position = UDim2.new(0.985, 0, 0.025, 0)
stats.Size = UDim2.fromOffset(255, 142)
stats.BackgroundColor3 = Color3.fromRGB(15, 18, 26)
stats.BackgroundTransparency = 0.08
stats.Parent = root
corner(stats, 14)
stroke(stats, 0.52)

makeText(stats, "Heading", UDim2.fromOffset(14, 6), UDim2.new(1, -28, 0, 24), "YOUR BASE", Color3.fromRGB(163, 176, 215), Enum.Font.GothamBold, 12)
local coinsLabel = makeText(stats, "Coins", UDim2.fromOffset(14, 31), UDim2.new(1, -28, 0, 27), "$0", Color3.fromRGB(113, 255, 159), Enum.Font.GothamBlack, 23)
local incomeLabel = makeText(stats, "Income", UDim2.fromOffset(14, 61), UDim2.new(1, -28, 0, 22), "+$0 / tick", Color3.fromRGB(212, 221, 244), Enum.Font.GothamBold, 14)
local crewLabel = makeText(stats, "Crew", UDim2.fromOffset(14, 84), UDim2.new(1, -28, 0, 22), "Crew 0/8", Color3.fromRGB(212, 221, 244), Enum.Font.GothamBold, 14)
local streakLabel = makeText(stats, "Streak", UDim2.fromOffset(14, 107), UDim2.new(1, -28, 0, 22), "Snatch streak 0x", Color3.fromRGB(255, 194, 92), Enum.Font.GothamBold, 14)

local coinScale = Instance.new("UIScale")
coinScale.Parent = coinsLabel

local missions = Instance.new("Frame")
missions.AnchorPoint = Vector2.new(0, 1)
missions.Position = UDim2.new(0.018, 0, 0.93, 0)
missions.Size = UDim2.fromOffset(330, 146)
missions.BackgroundColor3 = Color3.fromRGB(15, 18, 26)
missions.BackgroundTransparency = 0.1
missions.Parent = root
corner(missions, 14)
stroke(missions, 0.58)

makeText(missions, "Heading", UDim2.fromOffset(14, 7), UDim2.new(1, -28, 0, 22), "SESSION MISSIONS", Color3.fromRGB(163, 176, 215), Enum.Font.GothamBold, 12)
local recruitMission = makeText(missions, "Recruit", UDim2.fromOffset(14, 34), UDim2.new(1, -28, 0, 26), "○ Recruit 3 stickmen", nil, Enum.Font.GothamBold, 14)
local earnMission = makeText(missions, "Earn", UDim2.fromOffset(14, 64), UDim2.new(1, -28, 0, 26), "○ Earn $500", nil, Enum.Font.GothamBold, 14)
local snatchMission = makeText(missions, "Snatch", UDim2.fromOffset(14, 94), UDim2.new(1, -28, 0, 26), "○ Secure 1 rival stickman", nil, Enum.Font.GothamBold, 14)
local missionFooter = makeText(missions, "Footer", UDim2.fromOffset(14, 120), UDim2.new(1, -28, 0, 18), "Complete missions for bonus coins.", Color3.fromRGB(160, 168, 190), Enum.Font.GothamMedium, 11)

local shieldStatus = Instance.new("TextLabel")
shieldStatus.AnchorPoint = Vector2.new(1, 1)
shieldStatus.Position = UDim2.new(0.982, 0, 0.94, 0)
shieldStatus.Size = UDim2.fromOffset(235, 40)
shieldStatus.BackgroundColor3 = Color3.fromRGB(22, 25, 36)
shieldStatus.BackgroundTransparency = 0.08
shieldStatus.TextColor3 = Color3.fromRGB(182, 164, 255)
shieldStatus.Font = Enum.Font.GothamBold
shieldStatus.TextSize = 14
shieldStatus.Parent = root
corner(shieldStatus, 12)
stroke(shieldStatus, 0.6)

local dataStatus = makeText(root, "DataStatus", UDim2.new(0.018, 0, 0.025, 0), UDim2.fromOffset(210, 24), "Profile: loading…", Color3.fromRGB(176, 185, 209), Enum.Font.GothamMedium, 12)

local carryBanner = Instance.new("TextLabel")
carryBanner.Name = "CarryBanner"
carryBanner.AnchorPoint = Vector2.new(0.5, 0)
carryBanner.Position = UDim2.fromScale(0.5, 0.095)
carryBanner.Size = UDim2.new(0.72, 0, 0, 56)
carryBanner.BackgroundColor3 = Color3.fromRGB(32, 166, 84)
carryBanner.BackgroundTransparency = 0.04
carryBanner.TextColor3 = Color3.fromRGB(255, 255, 255)
carryBanner.TextScaled = true
carryBanner.Font = Enum.Font.GothamBlack
carryBanner.Text = "ESCAPE TO YOUR GREEN SECURE PAD!"
carryBanner.Visible = false
carryBanner.Parent = root
corner(carryBanner, 14)
stroke(carryBanner, 0.35)
local carryPadding = Instance.new("UIPadding")
carryPadding.PaddingLeft = UDim.new(0, 16)
carryPadding.PaddingRight = UDim.new(0, 16)
carryPadding.Parent = carryBanner

local carryScale = Instance.new("UIScale")
carryScale.Parent = carryBanner

local threatBanner = Instance.new("TextLabel")
threatBanner.Name = "ThreatBanner"
threatBanner.AnchorPoint = Vector2.new(0.5, 0)
threatBanner.Position = UDim2.fromScale(0.5, 0.158)
threatBanner.Size = UDim2.new(0.64, 0, 0, 48)
threatBanner.BackgroundColor3 = Color3.fromRGB(186, 62, 68)
threatBanner.BackgroundTransparency = 0.04
threatBanner.TextColor3 = Color3.fromRGB(255, 255, 255)
threatBanner.TextScaled = true
threatBanner.Font = Enum.Font.GothamBlack
threatBanner.Text = "YOUR STICKMAN IS BEING SNATCHED!"
threatBanner.Visible = false
threatBanner.Parent = root
corner(threatBanner, 14)
stroke(threatBanner, 0.34)

local threatPadding = Instance.new("UIPadding")
threatPadding.PaddingLeft = UDim.new(0, 16)
threatPadding.PaddingRight = UDim.new(0, 16)
threatPadding.Parent = threatBanner

local threatScale = Instance.new("UIScale")
threatScale.Parent = threatBanner

local hint = Instance.new("TextLabel")
hint.AnchorPoint = Vector2.new(0.5, 1)
hint.Position = UDim2.fromScale(0.5, 0.985)
hint.Size = UDim2.new(0.72, 0, 0, 28)
hint.BackgroundTransparency = 1
hint.Text = "Recruit • Upgrade • Earn • Snatch • Escape • Defend"
hint.TextColor3 = Color3.fromRGB(218, 224, 239)
hint.TextScaled = true
hint.Font = Enum.Font.GothamMedium
hint.Parent = root

local toast = Instance.new("TextLabel")
toast.AnchorPoint = Vector2.new(0.5, 0.5)
toast.Position = UDim2.fromScale(0.5, 0.76)
toast.Size = UDim2.new(0.68, 0, 0, 56)
toast.BackgroundColor3 = Color3.fromRGB(15, 18, 26)
toast.BackgroundTransparency = 1
toast.TextTransparency = 1
toast.TextColor3 = Color3.fromRGB(255, 255, 255)
toast.TextScaled = true
toast.Font = Enum.Font.GothamBold
toast.Visible = true
toast.Parent = root
corner(toast, 14)
stroke(toast, 0.65)

local lastCoins = coins.Value
local function refreshCoins()
	coinsLabel.Text = "$" .. tostring(coins.Value)
	if coins.Value > lastCoins then
		coinScale.Scale = 1.12
		TweenService:Create(coinScale, TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
	end
	lastCoins = coins.Value
end

local function refreshStats()
	incomeLabel.Text = string.format("+$%d / %ds", player:GetAttribute("IncomePerTick") or 0, 2)
	crewLabel.Text = string.format("Crew %d/%d", player:GetAttribute("CrewCount") or 0, player:GetAttribute("Capacity") or 8)
	streakLabel.Text = string.format("Snatch streak %dx", player:GetAttribute("CurrentStreak") or 0)
end

local function missionText(kind, fallback)
	local progress = player:GetAttribute("Mission" .. kind .. "Progress")
	local goal = player:GetAttribute("Mission" .. kind .. "Goal")
	local reward = player:GetAttribute("Mission" .. kind .. "Reward")
	local claimed = player:GetAttribute("Mission" .. kind .. "Claimed")
	if progress == nil or goal == nil then
		return "○ " .. fallback, false
	end
	if claimed then
		return string.format("✓ %s  +$%d", fallback, reward or 0), true
	end
	return string.format("○ %s  %d/%d  (+$%d)", fallback, progress, goal, reward or 0), false
end

local function refreshMissions()
	local text1, done1 = missionText("Recruit", "Recruit 3 stickmen")
	local text2, done2 = missionText("Earn", "Earn $500")
	local text3, done3 = missionText("Snatch", "Secure 1 rival stickman")
	recruitMission.Text = text1
	earnMission.Text = text2
	snatchMission.Text = text3
	recruitMission.TextColor3 = done1 and Color3.fromRGB(113, 255, 159) or Color3.fromRGB(240, 243, 250)
	earnMission.TextColor3 = done2 and Color3.fromRGB(113, 255, 159) or Color3.fromRGB(240, 243, 250)
	snatchMission.TextColor3 = done3 and Color3.fromRGB(113, 255, 159) or Color3.fromRGB(240, 243, 250)
	if done1 and done2 and done3 then
		missionFooter.Text = "All session missions complete!"
		missionFooter.TextColor3 = Color3.fromRGB(113, 255, 159)
	end
end

local function refreshDataStatus()
	local status = tostring(player:GetAttribute("PersistenceStatus") or "Loading")
	if status == "Saved" then
		dataStatus.Text = "Profile: saved"
		dataStatus.TextColor3 = Color3.fromRGB(113, 255, 159)
	elseif status == "Saving" then
		dataStatus.Text = "Profile: saving…"
		dataStatus.TextColor3 = Color3.fromRGB(255, 219, 125)
	elseif status == "Unavailable" or status == "Error" then
		dataStatus.Text = "Profile: save unavailable"
		dataStatus.TextColor3 = Color3.fromRGB(255, 145, 145)
	else
		dataStatus.Text = "Profile: loading…"
		dataStatus.TextColor3 = Color3.fromRGB(176, 185, 209)
	end
end

local function refreshShield()
	local now = workspace:GetServerTimeNow()
	local activeUntil = player:GetAttribute("ShieldUntilServerTime") or 0
	local readyAt = player:GetAttribute("ShieldReadyServerTime") or 0
	local joinUntil = player:GetAttribute("JoinProtectionUntilServerTime") or 0

	if joinUntil > now then
		shieldStatus.Text = string.format("JOIN PROTECTION  %ds", math.ceil(joinUntil - now))
		shieldStatus.TextColor3 = Color3.fromRGB(126, 204, 255)
	elseif activeUntil > now then
		shieldStatus.Text = string.format("SHIELD ACTIVE  %ds", math.ceil(activeUntil - now))
		shieldStatus.TextColor3 = Color3.fromRGB(185, 166, 255)
	elseif readyAt > now then
		shieldStatus.Text = string.format("SHIELD RECHARGING  %ds", math.ceil(readyAt - now))
		shieldStatus.TextColor3 = Color3.fromRGB(255, 198, 120)
	else
		shieldStatus.Text = "SHIELD READY"
		shieldStatus.TextColor3 = Color3.fromRGB(113, 255, 159)
	end
end

local carryActive = false
local carryMessage = ""
carryRemote.OnClientEvent:Connect(function(active, message)
	carryActive = active == true
	carryMessage = tostring(message or "")
	carryBanner.Visible = carryActive
	if carryActive then
		carryScale.Scale = 0.9
		TweenService:Create(carryScale, TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
		if carryMessage ~= "" then
			carryBanner.Text = carryMessage
		end
	else
		carryScale.Scale = 1
		carryBanner.BackgroundColor3 = Color3.fromRGB(32, 166, 84)
	end
end)

local threatActive = false
local threatMessage = ""
threatRemote.OnClientEvent:Connect(function(active, message)
	threatActive = active == true
	threatMessage = tostring(message or "")
	threatBanner.Visible = threatActive
	if threatActive then
		threatBanner.Text = threatMessage ~= "" and threatMessage or "YOUR STICKMAN IS BEING SNATCHED!"
		threatScale.Scale = 0.9
		TweenService:Create(threatScale, TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
	else
		threatScale.Scale = 1
	end
end)

local toastSerial = 0
toastRemote.OnClientEvent:Connect(function(message)
	toastSerial += 1
	local serial = toastSerial
	toast.Text = tostring(message)
	toast.Position = UDim2.fromScale(0.5, 0.79)

	TweenService:Create(toast, TweenInfo.new(0.16), {
		BackgroundTransparency = 0.08,
		TextTransparency = 0,
		Position = UDim2.fromScale(0.5, 0.76),
	}):Play()

	task.wait(2.4)
	if serial ~= toastSerial then
		return
	end

	TweenService:Create(toast, TweenInfo.new(0.25), {
		BackgroundTransparency = 1,
		TextTransparency = 1,
		Position = UDim2.fromScale(0.5, 0.73),
	}):Play()
end)

local function adaptToViewport()
	local camera = workspace.CurrentCamera
	if not camera then
		return
	end
	local width = camera.ViewportSize.X
	if width < 760 then
		title.Size = UDim2.new(0.48, 0, 0, 42)
		stats.Size = UDim2.fromOffset(210, 136)
		missions.Size = UDim2.new(0.52, 0, 0, 142)
		shieldStatus.Size = UDim2.fromOffset(200, 38)
		carryBanner.Size = UDim2.new(0.88, 0, 0, 52)
		threatBanner.Size = UDim2.new(0.88, 0, 0, 46)
		hint.Size = UDim2.new(0.9, 0, 0, 24)
	else
		title.Size = UDim2.new(0.38, 0, 0, 46)
		stats.Size = UDim2.fromOffset(255, 142)
		missions.Size = UDim2.fromOffset(330, 146)
		shieldStatus.Size = UDim2.fromOffset(235, 40)
		carryBanner.Size = UDim2.new(0.72, 0, 0, 56)
		threatBanner.Size = UDim2.new(0.64, 0, 0, 48)
		hint.Size = UDim2.new(0.72, 0, 0, 28)
	end
end

refreshCoins()
refreshStats()
refreshMissions()
refreshDataStatus()
refreshShield()
adaptToViewport()

coins.Changed:Connect(refreshCoins)
for _, attribute in ipairs({"IncomePerTick", "CrewCount", "Capacity", "CurrentStreak"}) do
	player:GetAttributeChangedSignal(attribute):Connect(refreshStats)
end
for _, attribute in ipairs({
	"MissionRecruitProgress", "MissionRecruitGoal", "MissionRecruitReward", "MissionRecruitClaimed",
	"MissionEarnProgress", "MissionEarnGoal", "MissionEarnReward", "MissionEarnClaimed",
	"MissionSnatchProgress", "MissionSnatchGoal", "MissionSnatchReward", "MissionSnatchClaimed",
}) do
	player:GetAttributeChangedSignal(attribute):Connect(refreshMissions)
end
player:GetAttributeChangedSignal("PersistenceStatus"):Connect(refreshDataStatus)

local camera = workspace.CurrentCamera
if camera then
	camera:GetPropertyChangedSignal("ViewportSize"):Connect(adaptToViewport)
end

local accumulator = 0
RunService.Heartbeat:Connect(function(dt)
	accumulator += dt
	if accumulator < 0.1 then
		return
	end
	accumulator = 0
	refreshShield()

	if carryActive then
		local plotIndex = player:GetAttribute("PlotIndex")
		local world = workspace:FindFirstChild("SnatchTheStickmanWorld")
		local plot = world and plotIndex and world:FindFirstChild("Plot" .. tostring(plotIndex))
		local pad = plot and plot:FindFirstChild("SecurePad")
		local character = player.Character
		local rootPart = character and character:FindFirstChild("HumanoidRootPart")
		local now = workspace:GetServerTimeNow()
		local rarity = string.upper(tostring(player:GetAttribute("CarryRarity") or "STICKMAN"))
		local victimName = tostring(player:GetAttribute("CarryVictimName") or "")
		local expiresAt = player:GetAttribute("CarryExpiresServerTime") or 0
		local secondsLeft = math.max(0, math.ceil(expiresAt - now))
		carryBanner.BackgroundColor3 = secondsLeft <= 8 and Color3.fromRGB(202, 72, 64) or Color3.fromRGB(32, 166, 84)
		if pad and rootPart then
			local distance = math.max(0, math.floor((rootPart.Position - pad.Position).Magnitude + 0.5))
			if victimName ~= "" then
				carryBanner.Text = string.format("HOOKED %s FROM %s  •  %d STUDS  •  %ds", rarity, string.upper(victimName), distance, secondsLeft)
			else
				carryBanner.Text = string.format("HOOKED %s  •  %d STUDS  •  %ds", rarity, distance, secondsLeft)
			end
		elseif carryMessage ~= "" then
			carryBanner.Text = string.format("%s  •  %ds", carryMessage, secondsLeft)
		end
	end

	if threatActive then
		local now = workspace:GetServerTimeNow()
		local expiresAt = player:GetAttribute("ThreatExpiresServerTime") or 0
		local secondsLeft = math.max(0, math.ceil(expiresAt - now))
		local rarity = string.upper(tostring(player:GetAttribute("ThreatRarity") or "STICKMAN"))
		local carrierName = tostring(player:GetAttribute("ThreatCarrierName") or "")
		if carrierName ~= "" and expiresAt > 0 then
			threatBanner.Text = string.format("%s IS SNATCHING YOUR %s!  •  %ds TO RECOVER", string.upper(carrierName), rarity, secondsLeft)
		elseif threatMessage ~= "" then
			threatBanner.Text = threatMessage
		end
	end
end)