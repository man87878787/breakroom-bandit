-- Dual secure-zone guidance: gives thieves a real deposit choice and prevents single-pad camping.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local world = workspace:WaitForChild("SnatchTheStickmanWorld")

local highlights = {}
local labels = {}

local function clear()
	for _, item in ipairs(highlights) do item:Destroy() end
	for _, item in ipairs(labels) do item:Destroy() end
	table.clear(highlights)
	table.clear(labels)
end

local function addPadPresentation(pad, text, color)
	local highlight = Instance.new("Highlight")
	highlight.Name = "LocalSecureRoute"
	highlight.Adornee = pad
	highlight.FillColor = color
	highlight.OutlineColor = Color3.fromRGB(235, 255, 255)
	highlight.FillTransparency = 0.58
	highlight.OutlineTransparency = 0.12
	highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	highlight.Parent = pad
	table.insert(highlights, highlight)

	local gui = Instance.new("BillboardGui")
	gui.Name = "LocalSecureChoice"
	gui.Adornee = pad
	gui.Size = UDim2.fromOffset(150, 42)
	gui.StudsOffset = Vector3.new(0, 3, 0)
	gui.AlwaysOnTop = true
	gui.MaxDistance = 110
	gui.Parent = pad
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundColor3 = Color3.fromRGB(18, 24, 33)
	label.BackgroundTransparency = 0.16
	label.Text = text
	label.TextColor3 = color
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.Parent = gui
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = label
	table.insert(labels, gui)
end

local function rebuild()
	clear()
	if not player:GetAttribute("CarryRarity") then return end
	local plotIndex = tonumber(player:GetAttribute("PlotIndex"))
	local plot = plotIndex and world:FindFirstChild("Plot" .. plotIndex)
	if not plot then return end
	local padA = plot:FindFirstChild("SecurePad")
	local padB = plot:FindFirstChild("SecurePad2")
	if padA then addPadPresentation(padA, "SECURE A", Color3.fromRGB(75, 255, 150)) end
	if padB then addPadPresentation(padB, "SECURE B", Color3.fromRGB(80, 225, 255)) end
end

player:GetAttributeChangedSignal("CarryRarity"):Connect(rebuild)
player:GetAttributeChangedSignal("PlotIndex"):Connect(rebuild)

local accumulator = 0
RunService.Heartbeat:Connect(function(dt)
	if #highlights == 0 then return end
	accumulator += dt
	if accumulator < 0.15 then return end
	accumulator = 0
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not root then return end
	for _, highlight in ipairs(highlights) do
		local pad = highlight.Adornee
		if pad and pad:IsA("BasePart") then
			local distance = (root.Position - pad.Position).Magnitude
			highlight.FillTransparency = distance < 24 and 0.3 or 0.58
		end
	end
end)

rebuild()
