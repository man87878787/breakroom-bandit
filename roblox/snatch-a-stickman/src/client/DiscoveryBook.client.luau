-- Persistent Stickman Index / collection book UI.
-- All discovery authority and rewards live on the server.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local remotes = ReplicatedStorage:WaitForChild("GameRemotes")
local discoveryEvent = remotes:WaitForChild("DiscoveryEvent")

local gui = Instance.new("ScreenGui")
gui.Name = "StickmanIndexUI"
gui.ResetOnSpawn = false
gui.DisplayOrder = 20
gui.IgnoreGuiInset = false
gui.Parent = playerGui

local function addCorner(parent, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = parent
	return corner
end
local function addStroke(parent, color, transparency, thickness)
	local stroke = Instance.new("UIStroke")
	stroke.Color = color
	stroke.Transparency = transparency or 0
	stroke.Thickness = thickness or 1
	stroke.Parent = parent
	return stroke
end

local openButton = Instance.new("TextButton")
openButton.Name = "CollectionButton"
openButton.AnchorPoint = Vector2.new(1, 0)
openButton.Position = UDim2.new(1, -18, 0, 176)
openButton.Size = UDim2.fromOffset(190, 44)
openButton.BackgroundColor3 = Color3.fromRGB(22, 27, 38)
openButton.TextColor3 = Color3.fromRGB(242, 245, 255)
openButton.Font = Enum.Font.GothamBold
openButton.TextSize = 14
openButton.Text = "STICKMAN INDEX  0/5"
openButton.AutoButtonColor = true
openButton.Parent = gui
addCorner(openButton, 12)
local openStroke = addStroke(openButton, Color3.fromRGB(100, 174, 255), 0.35, 1.5)
local buttonBaseSize = openButton.Size

local shade = Instance.new("TextButton")
shade.Name = "Shade"
shade.Size = UDim2.fromScale(1, 1)
shade.BackgroundColor3 = Color3.fromRGB(4, 6, 10)
shade.BackgroundTransparency = 0.3
shade.Text = ""
shade.AutoButtonColor = false
shade.Visible = false
shade.Parent = gui

local panel = Instance.new("Frame")
panel.Name = "CollectionPanel"
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.fromScale(0.5, 0.5)
panel.Size = UDim2.fromOffset(560, 438)
panel.BackgroundColor3 = Color3.fromRGB(14, 17, 24)
panel.BackgroundTransparency = 0.03
panel.Visible = false
panel.Parent = gui
addCorner(panel, 18)
addStroke(panel, Color3.fromRGB(89, 106, 150), 0.35, 1.5)

local panelScale = Instance.new("UIScale")
panelScale.Parent = panel

local title = Instance.new("TextLabel")
title.Position = UDim2.fromOffset(22, 14)
title.Size = UDim2.new(1, -80, 0, 28)
title.BackgroundTransparency = 1
title.Text = "STICKMAN INDEX"
title.TextColor3 = Color3.fromRGB(242, 245, 255)
title.Font = Enum.Font.GothamBlack
title.TextSize = 21
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = panel
local subtitle = Instance.new("TextLabel")
subtitle.Position = UDim2.fromOffset(22, 43)
subtitle.Size = UDim2.new(1, -44, 0, 20)
subtitle.BackgroundTransparency = 1
subtitle.Text = "Discover every rarity • permanent progress"
subtitle.TextColor3 = Color3.fromRGB(150, 161, 190)
subtitle.Font = Enum.Font.GothamMedium
subtitle.TextSize = 12
subtitle.TextXAlignment = Enum.TextXAlignment.Left
subtitle.Parent = panel

local closeButton = Instance.new("TextButton")
closeButton.AnchorPoint = Vector2.new(1, 0)
closeButton.Position = UDim2.new(1, -14, 0, 14)
closeButton.Size = UDim2.fromOffset(34, 34)
closeButton.BackgroundColor3 = Color3.fromRGB(34, 39, 52)
closeButton.Text = "×"
closeButton.TextColor3 = Color3.fromRGB(225, 231, 246)
closeButton.Font = Enum.Font.GothamBold
closeButton.TextSize = 22
closeButton.Parent = panel
addCorner(closeButton, 10)

local progressLabel = Instance.new("TextLabel")
progressLabel.Position = UDim2.fromOffset(22, 73)
progressLabel.Size = UDim2.new(1, -44, 0, 19)
progressLabel.BackgroundTransparency = 1
progressLabel.TextColor3 = Color3.fromRGB(225, 232, 248)
progressLabel.Font = Enum.Font.GothamBold
progressLabel.TextSize = 13
progressLabel.TextXAlignment = Enum.TextXAlignment.Left
progressLabel.Parent = panel
local progressTrack = Instance.new("Frame")
progressTrack.Position = UDim2.fromOffset(22, 97)
progressTrack.Size = UDim2.new(1, -44, 0, 10)
progressTrack.BackgroundColor3 = Color3.fromRGB(37, 43, 58)
progressTrack.Parent = panel
addCorner(progressTrack, 999)

local progressFill = Instance.new("Frame")
progressFill.Size = UDim2.fromScale(0, 1)
progressFill.BackgroundColor3 = Color3.fromRGB(103, 232, 153)
progressFill.Parent = progressTrack
addCorner(progressFill, 999)

local nextReward = Instance.new("TextLabel")
nextReward.Position = UDim2.fromOffset(22, 114)
nextReward.Size = UDim2.new(1, -44, 0, 20)
nextReward.BackgroundTransparency = 1
nextReward.TextColor3 = Color3.fromRGB(255, 208, 92)
nextReward.Font = Enum.Font.GothamMedium
nextReward.TextSize = 12
nextReward.TextXAlignment = Enum.TextXAlignment.Left
nextReward.Parent = panel

local list = Instance.new("ScrollingFrame")
list.Name = "Entries"
list.Position = UDim2.fromOffset(18, 143)
list.Size = UDim2.new(1, -36, 1, -176)
list.BackgroundTransparency = 1
list.BorderSizePixel = 0
list.ScrollBarThickness = 4
list.ScrollBarImageColor3 = Color3.fromRGB(103, 120, 158)
list.CanvasSize = UDim2.fromOffset(0, 0)
list.AutomaticCanvasSize = Enum.AutomaticSize.Y
list.Parent = panel
local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 8)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = list

local listPadding = Instance.new("UIPadding")
listPadding.PaddingRight = UDim.new(0, 5)
listPadding.Parent = list

local cards = {}
for index, rarity in ipairs(Config.RARITIES) do
	local card = Instance.new("Frame")
	card.Name = rarity.Name .. "Entry"
	card.LayoutOrder = index
	card.Size = UDim2.new(1, -5, 0, 58)
	card.BackgroundColor3 = Color3.fromRGB(25, 29, 40)
	card.Parent = list
	addCorner(card, 12)
	local border = addStroke(card, rarity.Color, 0.72, 1)

	local accent = Instance.new("Frame")
	accent.Size = UDim2.fromOffset(7, 36)
	accent.Position = UDim2.fromOffset(9, 11)
	accent.BackgroundColor3 = rarity.Color
	accent.Parent = card
	addCorner(accent, 999)

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Position = UDim2.fromOffset(28, 7)
	nameLabel.Size = UDim2.new(0.42, 0, 0, 22)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextSize = 14
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Parent = card

	local detail = Instance.new("TextLabel")
	detail.Position = UDim2.fromOffset(28, 29)
	detail.Size = UDim2.new(0.7, -28, 0, 20)
	detail.BackgroundTransparency = 1
	detail.Font = Enum.Font.GothamMedium
	detail.TextSize = 11
	detail.TextXAlignment = Enum.TextXAlignment.Left
	detail.Parent = card

	local badge = Instance.new("TextLabel")
	badge.AnchorPoint = Vector2.new(1, 0.5)
	badge.Position = UDim2.new(1, -12, 0.5, 0)
	badge.Size = UDim2.fromOffset(108, 30)
	badge.BackgroundColor3 = rarity.Color
	badge.BackgroundTransparency = 0.12
	badge.TextColor3 = Color3.fromRGB(15, 18, 25)
	badge.Font = Enum.Font.GothamBlack
	badge.TextSize = 11
	badge.Parent = card
	addCorner(badge, 9)

	cards[rarity.Name] = {
		Frame = card,
		Name = nameLabel,
		Detail = detail,
		Badge = badge,
		Border = border,
		Rarity = rarity,
	}
end
local footer = Instance.new("TextLabel")
footer.AnchorPoint = Vector2.new(0, 1)
footer.Position = UDim2.new(0, 22, 1, -9)
footer.Size = UDim2.new(1, -44, 0, 18)
footer.BackgroundTransparency = 1
footer.Text = "B to open • discoveries persist between sessions"
footer.TextColor3 = Color3.fromRGB(126, 137, 164)
footer.Font = Enum.Font.GothamMedium
footer.TextSize = 10
footer.TextXAlignment = Enum.TextXAlignment.Left
footer.Parent = panel

local reveal = Instance.new("TextLabel")
reveal.Name = "DiscoveryReveal"
reveal.AnchorPoint = Vector2.new(0.5, 0)
reveal.Position = UDim2.new(0.5, 0, 0, 72)
reveal.Size = UDim2.fromOffset(500, 68)
reveal.BackgroundColor3 = Color3.fromRGB(20, 24, 34)
reveal.BackgroundTransparency = 0.04
reveal.TextColor3 = Color3.new(1, 1, 1)
reveal.Font = Enum.Font.GothamBlack
reveal.TextSize = 18
reveal.TextWrapped = true
reveal.Visible = false
reveal.Parent = gui
addCorner(reveal, 16)
local revealStroke = addStroke(reveal, Color3.fromRGB(255, 255, 255), 0.25, 2)
local revealScale = Instance.new("UIScale")
revealScale.Parent = reveal
local isOpen = false
local function setOpen(open)
	isOpen = open
	shade.Visible = open
	panel.Visible = open
	if open then
		panelScale.Scale = 0.92
		TweenService:Create(panelScale, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Scale = 1,
		}):Play()
	end
end

local function comma(value)
	local text = tostring(math.max(0, math.floor(tonumber(value) or 0)))
	local changed
	repeat
		text, changed = text:gsub("^(-?%d+)(%d%d%d)", "%1,%2")
	until changed == 0
	return text
end

local function refresh()
	local count = tonumber(player:GetAttribute("DiscoveryCount")) or 0
	local total = tonumber(player:GetAttribute("DiscoveryTotal")) or #Config.RARITIES
	local percent = tonumber(player:GetAttribute("DiscoveryPercent")) or 0
	local complete = player:GetAttribute("DiscoveryComplete") == true

	openButton.Text = string.format("STICKMAN INDEX  %d/%d", count, total)
	progressLabel.Text = string.format("%d/%d DISCOVERED  •  %d%% COMPLETE", count, total, percent)

	local ratio = total > 0 and math.clamp(count / total, 0, 1) or 0
	TweenService:Create(progressFill, TweenInfo.new(0.25), {Size = UDim2.fromScale(ratio, 1)}):Play()
	local nextGoal = tonumber(player:GetAttribute("DiscoveryNextGoal")) or 0
	local reward = tonumber(player:GetAttribute("DiscoveryNextReward")) or 0
	if complete then
		nextReward.Text = "INDEX COMPLETE  •  every rarity discovered"
		nextReward.TextColor3 = Color3.fromRGB(103, 232, 153)
	else
		nextReward.Text = string.format("Next index reward: %d discoveries  •  +$%s", nextGoal, comma(reward))
		nextReward.TextColor3 = Color3.fromRGB(255, 208, 92)
	end

	for _, rarity in ipairs(Config.RARITIES) do
		local card = cards[rarity.Name]
		local seen = player:GetAttribute("Discovery_" .. rarity.Name) == true
		if seen then
			card.Name.Text = rarity.Name:upper()
			card.Name.TextColor3 = rarity.Color
			card.Detail.Text = string.format("$%s recruit  •  +$%s/tick", comma(rarity.Cost), comma(rarity.Income))
			card.Detail.TextColor3 = Color3.fromRGB(189, 198, 218)
			card.Badge.Text = "DISCOVERED"
			card.Badge.BackgroundColor3 = rarity.Color
			card.Badge.TextColor3 = Color3.fromRGB(15, 18, 25)
			card.Frame.BackgroundTransparency = 0.02
			card.Border.Transparency = 0.35
		else
			card.Name.Text = "???"
			card.Name.TextColor3 = Color3.fromRGB(130, 138, 158)
			card.Detail.Text = "Undiscovered • obtain this rarity to reveal it"
			card.Detail.TextColor3 = Color3.fromRGB(111, 120, 143)
			card.Badge.Text = "LOCKED"
			card.Badge.BackgroundColor3 = Color3.fromRGB(62, 68, 84)
			card.Badge.TextColor3 = Color3.fromRGB(180, 187, 204)
			card.Frame.BackgroundTransparency = 0.22
			card.Border.Transparency = 0.82
		end
	end
end
local revealSerial = 0
discoveryEvent.OnClientEvent:Connect(function(rarityName, baseReward, milestoneReward, count, total, complete)
	revealSerial += 1
	local serial = revealSerial
	local rarity
	for _, candidate in ipairs(Config.RARITIES) do
		if candidate.Name == rarityName then
			rarity = candidate
			break
		end
	end
	local color = rarity and rarity.Color or Color3.fromRGB(255, 220, 110)
	local totalReward = (tonumber(baseReward) or 0) + (tonumber(milestoneReward) or 0)

	if complete then
		reveal.Text = string.format("INDEX COMPLETE: %s!  +$%s", string.upper(tostring(rarityName)), comma(totalReward))
	elseif (tonumber(milestoneReward) or 0) > 0 then
		reveal.Text = string.format("NEW %s!  INDEX %d/%d  •  +$%s", string.upper(tostring(rarityName)), count, total, comma(totalReward))
	else
		reveal.Text = string.format("NEW DISCOVERY: %s!  +$%s", string.upper(tostring(rarityName)), comma(totalReward))
	end
	reveal.BackgroundColor3 = Color3.fromRGB(20, 24, 34)
	reveal.TextColor3 = color
	revealStroke.Color = color
	reveal.Visible = true
	revealScale.Scale = 0.78
	TweenService:Create(revealScale, TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Scale = 1,
	}):Play()

	openStroke.Color = color
	local pulseSize = UDim2.new(buttonBaseSize.X.Scale, buttonBaseSize.X.Offset + 14, buttonBaseSize.Y.Scale, buttonBaseSize.Y.Offset + 4)
	TweenService:Create(openButton, TweenInfo.new(0.16), {Size = pulseSize}):Play()
	task.delay(0.18, function()
		TweenService:Create(openButton, TweenInfo.new(0.18), {Size = buttonBaseSize}):Play()
	end)

	refresh()
	task.delay(3.2, function()
		if revealSerial == serial then
			reveal.Visible = false
			openStroke.Color = Color3.fromRGB(100, 174, 255)
		end
	end)
end)
openButton.Activated:Connect(function()
	setOpen(not isOpen)
end)

closeButton.Activated:Connect(function()
	setOpen(false)
end)

shade.Activated:Connect(function()
	setOpen(false)
end)

UserInputService.InputBegan:Connect(function(input, processed)
	if input.KeyCode == Enum.KeyCode.B then
		setOpen(not isOpen)
		return
	end
	if input.KeyCode == Enum.KeyCode.Escape and isOpen then
		setOpen(false)
		return
	end
	if processed then return end
end)

for _, rarity in ipairs(Config.RARITIES) do
	player:GetAttributeChangedSignal("Discovery_" .. rarity.Name):Connect(refresh)
end
for _, name in ipairs({
	"DiscoveryCount",
	"DiscoveryTotal",
	"DiscoveryPercent",
	"DiscoveryNextGoal",
	"DiscoveryNextReward",
	"DiscoveryComplete",
}) do
	player:GetAttributeChangedSignal(name):Connect(refresh)
end
local function adapt()
	local camera = workspace.CurrentCamera
	if not camera then return end
	local width = camera.ViewportSize.X
	if width < 760 then
		openButton.Position = UDim2.new(1, -12, 0, 154)
		buttonBaseSize = UDim2.fromOffset(158, 40)
		openButton.Size = buttonBaseSize
		openButton.TextSize = 12
		panel.Size = UDim2.new(0.94, 0, 0.72, 0)
		reveal.Size = UDim2.new(0.9, 0, 0, 64)
		reveal.TextSize = 15
	else
		openButton.Position = UDim2.new(1, -18, 0, 176)
		buttonBaseSize = UDim2.fromOffset(190, 44)
		openButton.Size = buttonBaseSize
		openButton.TextSize = 14
		panel.Size = UDim2.fromOffset(560, 438)
		reveal.Size = UDim2.fromOffset(500, 68)
		reveal.TextSize = 18
	end
end

local camera = workspace.CurrentCamera
if camera then
	camera:GetPropertyChangedSignal("ViewportSize"):Connect(adapt)
end

refresh()
adapt()