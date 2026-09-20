-- Connects the authored map to each player's live progression state.
-- These changes are client-local presentation; server gameplay remains authoritative.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local world = workspace:WaitForChild("SnatchTheStickmanWorld")
local connectedMap = world:WaitForChild("ConnectedMap")
local landmarks = connectedMap:WaitForChild("Landmarks")
local models = connectedMap:WaitForChild("Models")

local function surfaceLabel(part)
	if not part then return nil end
	local gui = part:FindFirstChildOfClass("SurfaceGui")
	if not gui then return nil end
	return gui:FindFirstChild("Label") or gui:FindFirstChild("Text")
end

local bountyStation = landmarks:FindFirstChild("BountyStation")
local bountyLabel = bountyStation and surfaceLabel(bountyStation:FindFirstChild("Board"))

local eventTower = landmarks:FindFirstChild("MarketEventTower")
local eventLabel = eventTower and surfaceLabel(eventTower:FindFirstChild("Board"))

local rarityGallery = landmarks:FindFirstChild("RarityGallery")
local rarityColors = {
	Common = Color3.fromRGB(225, 225, 225),
	Rare = Color3.fromRGB(70, 170, 255),
	Epic = Color3.fromRGB(185, 90, 255),
	Legendary = Color3.fromRGB(255, 190, 40),
	Glitched = Color3.fromRGB(255, 80, 190),
}

local function refreshBounty()
	if not bountyLabel then return end
	local now = workspace:GetServerTimeNow()
	local active = player:GetAttribute("RarityBountyActive") == true
	local target = tostring(player:GetAttribute("RarityBountyTarget") or "")
	local reward = tonumber(player:GetAttribute("RarityBountyReward")) or 0
	local expiresAt = tonumber(player:GetAttribute("RarityBountyExpiresAt")) or 0
	local nextAt = tonumber(player:GetAttribute("RarityBountyNextAt")) or 0

	if active and target ~= "" then
		local left = math.max(0, math.ceil(expiresAt - now))
		bountyLabel.Text = string.format("YOUR BOUNTY\n%s • +$%d\n%ds LEFT", string.upper(target), reward, left)
		bountyLabel.TextColor3 = rarityColors[target] or Color3.fromRGB(220, 150, 255)
	else
		local left = math.max(0, math.ceil(nextAt - now))
		bountyLabel.Text = string.format("RARITY BOUNTIES\nNEXT TARGET IN %ds", left)
		bountyLabel.TextColor3 = Color3.fromRGB(190, 145, 255)
	end
end
local function refreshEvent()
	if not eventLabel then return end
	local now = workspace:GetServerTimeNow()
	local name = tostring(world:GetAttribute("MarketEvent") or "Calm")
	local description = tostring(world:GetAttribute("MarketEventDescription") or "Market stable")
	local endsAt = tonumber(world:GetAttribute("MarketEventEndsAt")) or 0
	local nextAt = tonumber(world:GetAttribute("MarketEventNextAt")) or 0

	if name ~= "Calm" and endsAt > now then
		eventLabel.Text = string.format("MARKET EVENT\n%s\n%s • %ds", string.upper(name), description, math.max(0, math.ceil(endsAt - now)))
	elseif nextAt > now then
		eventLabel.Text = string.format("MARKET EVENT\nCALM\nNEXT IN %ds", math.max(0, math.ceil(nextAt - now)))
	else
		eventLabel.Text = "MARKET EVENT\nCALM\nNEXT EVENT SOON"
	end
end

local function refreshGallery()
	if not rarityGallery then return end
	for rarityName, color in pairs(rarityColors) do
		local discovered = player:GetAttribute("Discovery_" .. rarityName) == true
		local orb = rarityGallery:FindFirstChild(rarityName .. "Orb")
		local tag = rarityGallery:FindFirstChild(rarityName .. "Tag")
		local label = surfaceLabel(tag)

		if orb and orb:IsA("BasePart") then
			orb.Transparency = discovered and 0.05 or 0.72
			orb.Color = discovered and color or Color3.fromRGB(72, 76, 88)
		end
		if label then
			label.Text = discovered and rarityName or "???"
			label.TextColor3 = discovered and color or Color3.fromRGB(125, 132, 148)
		end
	end
end

local function refreshBaseGate()
	local index = tonumber(player:GetAttribute("PlotIndex"))
	for gateIndex = 1, 6 do
		local gate = models:FindFirstChild("BaseGate" .. gateIndex)
		local header = gate and gate:FindFirstChild("Header")
		if header and header:IsA("BasePart") then
			if gateIndex == index then
				header.Transparency = 0
				header.Material = Enum.Material.Neon
			else
				header.Transparency = 0.08
			end
		end
	end
end

for rarityName in pairs(rarityColors) do
	player:GetAttributeChangedSignal("Discovery_" .. rarityName):Connect(refreshGallery)
end

for _, attribute in ipairs({
	"RarityBountyActive",
	"RarityBountyTarget",
	"RarityBountyReward",
	"RarityBountyExpiresAt",
	"RarityBountyNextAt",
}) do
	player:GetAttributeChangedSignal(attribute):Connect(refreshBounty)
end
for _, attribute in ipairs({
	"MarketEvent",
	"MarketEventDescription",
	"MarketEventEndsAt",
	"MarketEventNextAt",
}) do
	world:GetAttributeChangedSignal(attribute):Connect(refreshEvent)
end

player:GetAttributeChangedSignal("PlotIndex"):Connect(refreshBaseGate)

local accumulator = 0
RunService.Heartbeat:Connect(function(dt)
	accumulator += dt
	if accumulator >= 0.25 then
		accumulator = 0
		refreshBounty()
		refreshEvent()
	end
end)

refreshBounty()
refreshEvent()
refreshGallery()
refreshBaseGate()