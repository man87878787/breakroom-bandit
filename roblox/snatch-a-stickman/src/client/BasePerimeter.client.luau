local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local localPlayer = Players.LocalPlayer
local world = workspace:WaitForChild("SnatchTheStickmanWorld")
local perimeters = {}

local COLORS = {
	Open = Color3.fromRGB(100, 110, 128),
	Protected = Color3.fromRGB(90, 190, 255),
	Shielded = Color3.fromRGB(176, 120, 255),
	Vulnerable = Color3.fromRGB(255, 105, 110),
	Ready = Color3.fromRGB(90, 245, 145),
}

local function makePart(parent, name, size, cframe)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cframe
	p.Anchored = true
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = false
	p.Material = Enum.Material.Neon
	p.Transparency = 0.35
	p.Parent = parent
	return p
end
local function makePerimeter(plot)
	if perimeters[plot] then return perimeters[plot] end
	local floor = plot:FindFirstChild("Floor")
	if not floor then return nil end

	local folder = Instance.new("Folder")
	folder.Name = "LocalDefensePerimeter"
	folder.Parent = plot
	local y = floor.Position.Y + 0.65
	local x, z = floor.Position.X, floor.Position.Z
	local rails = {
		makePart(folder, "North", Vector3.new(42, 0.22, 0.35), CFrame.new(x, y, z - 16.5)),
		makePart(folder, "South", Vector3.new(42, 0.22, 0.35), CFrame.new(x, y, z + 16.5)),
		makePart(folder, "West", Vector3.new(0.35, 0.22, 34), CFrame.new(x - 20.5, y, z)),
		makePart(folder, "East", Vector3.new(0.35, 0.22, 34), CFrame.new(x + 20.5, y, z)),
	}
	local entry = makePart(folder, "AttackWindow", Vector3.new(8, 0.12, 3), CFrame.new(x, y + 0.02, z - 18.5))
	entry.Transparency = 0.2
	perimeters[plot] = {Folder = folder, Rails = rails, Entry = entry}
	return perimeters[plot]
end

local function defenseState(plot, now)
	local ownerId = tonumber(plot:GetAttribute("OwnerUserId")) or 0
	if ownerId <= 0 then return "Open", COLORS.Open, 0 end
	local joinUntil = tonumber(plot:GetAttribute("JoinProtectionUntilServerTime")) or 0
	local shieldUntil = tonumber(plot:GetAttribute("ShieldUntilServerTime")) or 0
	local readyAt = tonumber(plot:GetAttribute("ShieldReadyServerTime")) or 0
	if joinUntil > now then return "Protected", COLORS.Protected, joinUntil - now end
	if shieldUntil > now then return "Shielded", COLORS.Shielded, shieldUntil - now end
	if readyAt > now then return "Vulnerable", COLORS.Vulnerable, readyAt - now end
	return "Ready", COLORS.Ready, 0
end

local function updatePlot(plot, now)
	local perimeter = makePerimeter(plot)
	if not perimeter then return end
	local state, color, remaining = defenseState(plot, now)
	local ownerId = tonumber(plot:GetAttribute("OwnerUserId")) or 0
	local isMine = ownerId == localPlayer.UserId

	for _, rail in ipairs(perimeter.Rails) do
		rail.Color = color
		rail.Transparency = state == "Open" and 0.75 or (state == "Vulnerable" and 0.18 or 0.38)
	end
	perimeter.Entry.Color = color
	perimeter.Entry.Transparency = state == "Vulnerable" and 0.02 or 0.38

	if state == "Vulnerable" then
		perimeter.Entry.Size = Vector3.new(8 + math.sin(now * 5) * 1.5, 0.12, 3)
	else
		perimeter.Entry.Size = Vector3.new(8, 0.12, 3)
	end

	perimeter.Folder:SetAttribute("DefenseState", state)
	perimeter.Folder:SetAttribute("SecondsRemaining", math.max(0, math.ceil(remaining)))
	perimeter.Folder:SetAttribute("LocalPlayerOwnsBase", isMine)
end
local function refresh()
	local now = workspace:GetServerTimeNow()
	for _, plot in ipairs(world:GetChildren()) do
		if plot:IsA("Model") and plot:GetAttribute("PlotIndex") then
			updatePlot(plot, now)
		end
	end
end

world.ChildRemoved:Connect(function(child)
	local perimeter = perimeters[child]
	if perimeter then
		if perimeter.Folder.Parent then perimeter.Folder:Destroy() end
		perimeters[child] = nil
	end
end)

local elapsed = 0
RunService.Heartbeat:Connect(function(dt)
	elapsed += dt
	if elapsed < 0.1 then return end
	elapsed = 0
	refresh()
end)

refresh()
