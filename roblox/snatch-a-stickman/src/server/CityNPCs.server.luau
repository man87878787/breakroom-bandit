-- Authored city NPC population.
-- NPCs are lightweight, server-created stickman characters with safe informational interactions.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local WorldConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("WorldConfig"))
local world = workspace:WaitForChild("SnatchTheStickmanWorld")
local connectedMap = world:WaitForChild("ConnectedMap")

local old = connectedMap:FindFirstChild("CityNPCs")
if old then
	old:Destroy()
end

local root = Instance.new("Folder")
root.Name = "CityNPCs"
root.Parent = connectedMap

local function part(parent, name, size, cframe, color, material, shape)
	local item = Instance.new("Part")
	item.Name = name
	item.Size = size
	item.CFrame = cframe
	item.Anchored = true
	item.CanCollide = false
	item.CanTouch = false
	item.CanQuery = false
	item.TopSurface = Enum.SurfaceType.Smooth
	item.BottomSurface = Enum.SurfaceType.Smooth
	item.Color = color
	item.Material = material or Enum.Material.SmoothPlastic
	if shape then
		item.Shape = shape
	end
	item.Parent = parent
	return item
end

local function toast(player, message)
	local remotes = ReplicatedStorage:FindFirstChild("GameRemotes")
	local remote = remotes and remotes:FindFirstChild("Toast")
	if remote and remote:IsA("RemoteEvent") then
		remote:FireClient(player, message)
	end
end

local function characterRoot(player)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local humanoidRootPart = character and character:FindFirstChild("HumanoidRootPart")
	if humanoid and humanoid.Health > 0 and humanoidRootPart then
		return humanoidRootPart
	end
	return nil
end

local function displayTag(head, npc)
	local gui = Instance.new("BillboardGui")
	gui.Name = "NPCNameplate"
	gui.Size = UDim2.fromOffset(210, 54)
	gui.StudsOffset = Vector3.new(0, 2.2, 0)
	gui.AlwaysOnTop = false
	gui.MaxDistance = 65
	gui.Parent = head

	local name = Instance.new("TextLabel")
	name.Size = UDim2.new(1, 0, 0.54, 0)
	name.BackgroundTransparency = 1
	name.Text = npc.Name
	name.TextColor3 = npc.Accent
	name.TextStrokeTransparency = 0.65
	name.TextScaled = true
	name.Font = Enum.Font.GothamBold
	name.Parent = gui

	local role = Instance.new("TextLabel")
	role.Position = UDim2.new(0, 0, 0.54, 0)
	role.Size = UDim2.new(1, 0, 0.38, 0)
	role.BackgroundTransparency = 1
	role.Text = npc.Role
	role.TextColor3 = Color3.fromRGB(223, 229, 242)
	role.TextStrokeTransparency = 0.72
	role.TextScaled = true
	role.Font = Enum.Font.Gotham
	role.Parent = gui
end

local function contextualDialogue(npc)
	local eventName = tostring(world:GetAttribute("MarketEvent") or "Calm")
	local activeDistrict = tostring(world:GetAttribute("DistrictActivityDistrict") or "")
	local activityName = tostring(world:GetAttribute("DistrictActivityName") or "city activity")
	local roleDistrict = {
		["Freight Mechanic"] = "FreightYard",
		["Transit Dispatcher"] = "NeonJunction",
		["Highline Lookout"] = "Highline",
		["Commons Caretaker"] = "FoundryCommons",
	}
	if roleDistrict[npc.Role] and roleDistrict[npc.Role] == activeDistrict then
		return activityName .. " is live here. Stay inside the marked zone until the scan completes; active heists pause activity progress."
	end
	if npc.Role == "Market Broker" then
		if eventName == "Rare Rush" then
			return "Rare Rush is live. The market can spike quickly, so watch your coins and protect anything valuable you land."
		elseif eventName == "Payday" then
			return "Payday is live. Income is stronger right now, so a well-built crew matters more than chasing every shiny spawn."
		end
	elseif npc.Role == "Transit Dispatcher" then
		return "Pick any destination kiosk. Transit stays disabled while you are carrying a stolen stickman or defending an active theft."
	elseif npc.Role == "Route Scout" then
		return "Your route choice becomes real during a heist: Fast is quicker but easier to intercept; Sky is slower but harder to recover."
	end
	return npc.Dialogue
end

local function buildNPC(npc, index)
	local m = Instance.new("Model")
	m.Name = npc.Name
	m:SetAttribute("NPCName", npc.Name)
	m:SetAttribute("NPCRole", npc.Role)
	m:SetAttribute("NPCIndex", index)
	m.Parent = root

	local base = CFrame.lookAt(npc.Position, Vector3.new(0, npc.Position.Y, 0))
	local torso = part(m, "Torso", Vector3.new(1.2, 3.8, 0.8), base * CFrame.new(0, 3.9, 0), Color3.fromRGB(42, 47, 61), Enum.Material.SmoothPlastic)
	local head = part(m, "Head", Vector3.new(1.9, 1.9, 1.9), base * CFrame.new(0, 6.7, 0), npc.Accent, Enum.Material.SmoothPlastic, Enum.PartType.Ball)
	part(m, "ArmL", Vector3.new(0.45, 3.4, 0.45), base * CFrame.new(-1.05, 4.1, 0) * CFrame.Angles(0, 0, math.rad(-10)), npc.Accent, Enum.Material.SmoothPlastic)
	part(m, "ArmR", Vector3.new(0.45, 3.4, 0.45), base * CFrame.new(1.05, 4.1, 0) * CFrame.Angles(0, 0, math.rad(10)), npc.Accent, Enum.Material.SmoothPlastic)
	part(m, "LegL", Vector3.new(0.55, 3.4, 0.55), base * CFrame.new(-0.42, 1.7, 0), Color3.fromRGB(55, 61, 76), Enum.Material.SmoothPlastic)
	part(m, "LegR", Vector3.new(0.55, 3.4, 0.55), base * CFrame.new(0.42, 1.7, 0), Color3.fromRGB(55, 61, 76), Enum.Material.SmoothPlastic)

	local marker = part(m, "GroundMarker", Vector3.new(4.2, 0.1, 4.2), CFrame.new(npc.Position + Vector3.new(0, 0.08, 0)), npc.Accent, Enum.Material.Neon)
	marker.Transparency = 0.72

	displayTag(head, npc)

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "TalkPrompt"
	prompt.ActionText = "Talk"
	prompt.ObjectText = npc.Name .. " • " .. npc.Role
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.GamepadKeyCode = Enum.KeyCode.ButtonX
	prompt.HoldDuration = 0.15
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = true
	prompt.Parent = torso

	prompt.Triggered:Connect(function(player)
		if player.Parent ~= Players then
			return
		end
		local playerRoot = characterRoot(player)
		if not playerRoot or (playerRoot.Position - torso.Position).Magnitude > 13 then
			return
		end
		toast(player, npc.Name .. ": " .. contextualDialogue(npc))
		player:SetAttribute("LastNPCSpokenTo", npc.Name)
	end)

	m.PrimaryPart = torso
	return m
end

for index, npc in ipairs(WorldConfig.NPCS) do
	buildNPC(npc, index)
end

root:SetAttribute("PopulationVersion", 1)
root:SetAttribute("NPCCount", #WorldConfig.NPCS)
root:SetAttribute("NPCInteractionsAreInformational", true)
