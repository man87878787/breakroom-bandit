-- Lifetime progression HUD for Snatch the Stickman.
-- Reads only server-published milestone attributes; rewards remain server-authoritative.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local TRACKS = {
	{Field = "TotalRecruits", Label = "RECRUITER", Unit = "recruits"},
	{Field = "TotalSnatches", Label = "SNATCHER", Unit = "snatches"},
	{Field = "LifetimeCoinsEarned", Label = "MOGUL", Unit = "coins"},
	{Field = "BestStreak", Label = "ESCAPE ARTIST", Unit = "streak"},
}

local gui = Instance.new("ScreenGui")
gui.Name = "LifetimeProgressUI"
gui.ResetOnSpawn = false
gui.DisplayOrder = 9
gui.IgnoreGuiInset = false
gui.Parent = playerGui

local card = Instance.new("Frame")
card.Name = "Card"
card.AnchorPoint = Vector2.new(0, 0.5)
card.Position = UDim2.new(0.018, 0, 0.48, 0)
card.Size = UDim2.fromOffset(300, 238)
card.BackgroundColor3 = Color3.fromRGB(15, 18, 26)
card.BackgroundTransparency = 0.08
card.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 14)
corner.Parent = card

local outline = Instance.new("UIStroke")
outline.Color = Color3.fromRGB(92, 105, 138)
outline.Transparency = 0.55
outline.Parent = card

local title = Instance.new("TextLabel")
title.Position = UDim2.fromOffset(14, 8)
title.Size = UDim2.new(1, -58, 0, 24)
title.BackgroundTransparency = 1
title.Text = "LIFETIME GOALS"
title.TextColor3 = Color3.fromRGB(163, 176, 215)
title.Font = Enum.Font.GothamBold
title.TextSize = 12
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = card

local collapse = Instance.new("TextButton")
collapse.AnchorPoint = Vector2.new(1, 0)
collapse.Position = UDim2.new(1, -10, 0, 7)
collapse.Size = UDim2.fromOffset(32, 26)
collapse.BackgroundColor3 = Color3.fromRGB(28, 33, 47)
collapse.Text = "–"
collapse.TextColor3 = Color3.fromRGB(220, 226, 242)
collapse.Font = Enum.Font.GothamBold
collapse.TextSize = 18
collapse.AutoButtonColor = true
collapse.Parent = card
local collapseCorner = Instance.new("UICorner")
collapseCorner.CornerRadius = UDim.new(0, 8)
collapseCorner.Parent = collapse

local rows = {}
for index, track in ipairs(TRACKS) do
	local y = 38 + (index - 1) * 47
	local label = Instance.new("TextLabel")
	label.Position = UDim2.fromOffset(14, y)
	label.Size = UDim2.new(1, -28, 0, 19)
	label.BackgroundTransparency = 1
	label.TextColor3 = Color3.fromRGB(238, 241, 249)
	label.Font = Enum.Font.GothamBold
	label.TextSize = 12
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = card

	local bar = Instance.new("Frame")
	bar.Position = UDim2.fromOffset(14, y + 23)
	bar.Size = UDim2.new(1, -28, 0, 9)
	bar.BackgroundColor3 = Color3.fromRGB(38, 43, 58)
	bar.Parent = card
	local barCorner = Instance.new("UICorner")
	barCorner.CornerRadius = UDim.new(1, 0)
	barCorner.Parent = bar

	local fill = Instance.new("Frame")
	fill.Size = UDim2.fromScale(0, 1)
	fill.BackgroundColor3 = Color3.fromRGB(113, 255, 159)
	fill.Parent = bar
	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(1, 0)
	fillCorner.Parent = fill

	rows[track.Field] = {Label = label, Fill = fill, Track = track}
end

local footer = Instance.new("TextLabel")
footer.AnchorPoint = Vector2.new(0, 1)
footer.Position = UDim2.new(0, 14, 1, -7)
footer.Size = UDim2.new(1, -28, 0, 16)
footer.BackgroundTransparency = 1
footer.Text = "Permanent goals • rewards pay automatically"
footer.TextColor3 = Color3.fromRGB(145, 154, 180)
footer.Font = Enum.Font.GothamMedium
footer.TextSize = 10
footer.TextXAlignment = Enum.TextXAlignment.Left
footer.Parent = card

local function comma(value)
	local text = tostring(math.max(0, math.floor(tonumber(value) or 0)))
	local changed
	repeat
		text, changed = text:gsub("^(-?%d+)(%d%d%d)", "%1,%2")
	until changed == 0
	return text
end

local function refresh(field)
	local row = rows[field]
	if not row then return end
	local prefix = "Milestone_" .. field .. "_"
	local value = tonumber(player:GetAttribute(prefix .. "Value")) or 0
	local goal = tonumber(player:GetAttribute(prefix .. "NextGoal")) or 0
	local reward = tonumber(player:GetAttribute(prefix .. "NextReward")) or 0
	local complete = player:GetAttribute(prefix .. "Complete") == true

	if complete then
		row.Label.Text = string.format("✓ %s  %s %s • COMPLETE", row.Track.Label, comma(value), row.Track.Unit)
		row.Label.TextColor3 = Color3.fromRGB(113, 255, 159)
		TweenService:Create(row.Fill, TweenInfo.new(0.25), {Size = UDim2.fromScale(1, 1)}):Play()
		return
	end

	if goal <= 0 then
		row.Label.Text = row.Track.Label .. "  loading…"
		row.Label.TextColor3 = Color3.fromRGB(180, 188, 208)
		return
	end

	row.Label.Text = string.format("%s  %s/%s %s  (+$%s)", row.Track.Label, comma(value), comma(goal), row.Track.Unit, comma(reward))
	row.Label.TextColor3 = Color3.fromRGB(238, 241, 249)
	local progress = math.clamp(value / goal, 0, 1)
	TweenService:Create(row.Fill, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.fromScale(progress, 1)}):Play()
end

local expanded = true
collapse.Activated:Connect(function()
	expanded = not expanded
	collapse.Text = expanded and "–" or "+"
	local target = expanded and UDim2.fromOffset(300, 238) or UDim2.fromOffset(300, 40)
	TweenService:Create(card, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = target}):Play()
	for _, row in pairs(rows) do
		row.Label.Visible = expanded
		row.Fill.Parent.Visible = expanded
	end
	footer.Visible = expanded
end)

for _, track in ipairs(TRACKS) do
	local prefix = "Milestone_" .. track.Field .. "_"
	for _, suffix in ipairs({"Value", "NextGoal", "NextReward", "Complete"}) do
		player:GetAttributeChangedSignal(prefix .. suffix):Connect(function()
			refresh(track.Field)
		end)
	end
	refresh(track.Field)
end

local function adaptToViewport()
	local camera = workspace.CurrentCamera
	if not camera then return end
	if camera.ViewportSize.X < 760 then
		card.Position = UDim2.new(0.018, 0, 0.42, 0)
		card.Size = expanded and UDim2.fromOffset(265, 238) or UDim2.fromOffset(265, 40)
	else
		card.Position = UDim2.new(0.018, 0, 0.48, 0)
		card.Size = expanded and UDim2.fromOffset(300, 238) or UDim2.fromOffset(300, 40)
	end
end

local camera = workspace.CurrentCamera
if camera then
	camera:GetPropertyChangedSignal("ViewportSize"):Connect(adaptToViewport)
end
adaptToViewport()
