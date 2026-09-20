local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local world = workspace:WaitForChild("SnatchTheStickmanWorld")
local tracked = {}

local COLORS = {
	Available = Color3.fromRGB(110, 255, 155),
	Protected = Color3.fromRGB(100, 185, 255),
	Stealable = Color3.fromRGB(255, 205, 75),
	Hooked = Color3.fromRGB(255, 90, 100),
	Yours = Color3.fromRGB(190, 150, 255),
}

local function isStickman(model)
	return model:IsA("Model") and model.PrimaryPart ~= nil and model:GetAttribute("Rarity") ~= nil
end

local function stateFor(model)
	local carrier = model:GetAttribute("CarrierUserId") or 0
	local owner = model:GetAttribute("OwnerUserId") or 0
	local readyAt = model:GetAttribute("StealReadyAt") or 0
	if carrier ~= 0 or model:GetAttribute("TransferState") == "InTransit" then
		if carrier == player.UserId then return "Hooked", "ESCAPE • SECURE IT" end
		return "Hooked", "HOOKED • RECOVER!"
	end
	if owner == 0 then return "Available", "AVAILABLE" end
	if owner == player.UserId then return "Yours", "YOUR CREW" end
	if os.clock() < readyAt then return "Protected", "PROTECTED" end
	return "Stealable", "STEALABLE"
end

local function attach(model)
	if tracked[model] or not isStickman(model) then return end
	local gui = Instance.new("BillboardGui")
	gui.Name = "StealStatePresentation"
	gui.Size = UDim2.fromOffset(150, 22)
	gui.StudsOffset = Vector3.new(0, 4.8, 0)
	gui.AlwaysOnTop = true
	gui.MaxDistance = 85
	gui.Adornee = model.PrimaryPart
	gui.Parent = model.PrimaryPart

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundColor3 = Color3.fromRGB(12, 14, 20)
	label.BackgroundTransparency = 0.16
	label.Font = Enum.Font.GothamBlack
	label.TextSize = 12
	label.TextStrokeTransparency = 0.55
	label.Parent = gui
	Instance.new("UICorner", label).CornerRadius = UDim.new(0, 7)

	tracked[model] = {gui = gui, label = label, lastState = ""}
end

local function update(model, data)
	if not model.Parent or not model.PrimaryPart then
		if data.gui then data.gui:Destroy() end
		tracked[model] = nil
		return
	end
	local state, text = stateFor(model)
	if data.lastState ~= state or data.label.Text ~= text then
		data.lastState = state
		data.label.Text = text
		data.label.TextColor3 = COLORS[state]
		local stroke = data.label:FindFirstChildOfClass("UIStroke")
		if not stroke then
			stroke = Instance.new("UIStroke")
			stroke.Thickness = 1
			stroke.Transparency = 0.35
			stroke.Parent = data.label
		end
		stroke.Color = COLORS[state]
	end
end

for _, child in ipairs(world:GetChildren()) do attach(child) end
world.ChildAdded:Connect(function(child) task.defer(attach, child) end)

local elapsed = 0
RunService.Heartbeat:Connect(function(dt)
	elapsed += dt
	if elapsed < 0.25 then return end
	elapsed = 0
	for model, data in pairs(tracked) do update(model, data) end
end)
