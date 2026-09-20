local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local world = workspace:WaitForChild("SnatchTheStickmanWorld")
local displays = {}

local COLORS = {
	Open = Color3.fromRGB(155, 164, 180),
	Ready = Color3.fromRGB(92, 240, 150),
	Protected = Color3.fromRGB(115, 190, 255),
	Shielded = Color3.fromRGB(185, 150, 255),
	Cooldown = Color3.fromRGB(255, 184, 105),
}

local function makeDisplay(plot)
	local sign = plot:FindFirstChild("Sign") or plot:FindFirstChild("Floor")
	if not sign or displays[plot] then return end
	local gui = Instance.new("BillboardGui")
	gui.Name = "DefenseStatus"
	gui.Adornee = sign
	gui.Size = UDim2.fromOffset(230, 52)
	gui.StudsOffsetWorldSpace = Vector3.new(0, 5.2, 0)
	gui.AlwaysOnTop = true
	gui.MaxDistance = 95
	gui.Parent = plot
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundColor3 = Color3.fromRGB(17, 20, 29)
	label.BackgroundTransparency = 0.12
	label.TextColor3 = COLORS.Open
	label.TextSize = 14
	label.TextWrapped = true
	label.Font = Enum.Font.GothamBold
	label.Parent = gui
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = label
	local stroke = Instance.new("UIStroke")
	stroke.Transparency = 0.45
	stroke.Thickness = 1.5
	stroke.Parent = label
	displays[plot] = { Gui = gui, Label = label, Stroke = stroke }
end

local function stateFor(plot, now)
	local ownerId = tonumber(plot:GetAttribute("OwnerUserId")) or 0
	if ownerId <= 0 then return "OPEN BASE", COLORS.Open end
	local owner = tostring(plot:GetAttribute("OwnerDisplayName") or "PLAYER")
	local joinUntil = tonumber(plot:GetAttribute("JoinProtectionUntilServerTime")) or 0
	local shieldUntil = tonumber(plot:GetAttribute("ShieldUntilServerTime")) or 0
	local readyAt = tonumber(plot:GetAttribute("ShieldReadyServerTime")) or 0
	if joinUntil > now then
		return string.format("%s • JOIN PROTECTED  %ds", owner, math.ceil(joinUntil - now)), COLORS.Protected
	end
	if shieldUntil > now then
		return string.format("%s • SHIELDED  %ds", owner, math.ceil(shieldUntil - now)), COLORS.Shielded
	end
	if readyAt > now then
		return string.format("%s • VULNERABLE  • shield %ds", owner, math.ceil(readyAt - now)), COLORS.Cooldown
	end
	return string.format("%s • VULNERABLE  • shield ready", owner), COLORS.Ready
end

local function refresh()
	local now = workspace:GetServerTimeNow()
	for _, plot in ipairs(world:GetChildren()) do
		if plot:IsA("Model") and plot:GetAttribute("PlotIndex") then
			makeDisplay(plot)
			local display = displays[plot]
			if display then
				local text, color = stateFor(plot, now)
				display.Label.Text = text
				display.Label.TextColor3 = color
				display.Stroke.Color = color
			end
		end
	end
end
world.ChildRemoved:Connect(function(child)
	local display = displays[child]
	if display then
		display.Gui:Destroy()
		displays[child] = nil
	end
end)

local elapsed = 0
RunService.Heartbeat:Connect(function(dt)
	elapsed += dt
	if elapsed < 0.2 then return end
	elapsed = 0
	refresh()
end)

refresh()
