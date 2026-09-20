local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local world = workspace:WaitForChild("SnatchTheStickmanWorld")
local remotes = ReplicatedStorage:WaitForChild("GameRemotes")
local toastRemote = remotes:WaitForChild("Toast")

local EVENTS = {
	{
		Name = "Rare Rush",
		Description = "Epic+ stickmen are much more likely to appear!",
		IncomeMultiplier = 1,
	},
	{
		Name = "Payday",
		Description = string.format("All passive crew income is x%.1f!", Config.PAYDAY_MULTIPLIER),
		IncomeMultiplier = Config.PAYDAY_MULTIPLIER,
	},
}

local eventIndex = 0
local activeUntil = 0
local nextAt = workspace:GetServerTimeNow() + 25

local function broadcast(message)
	for _, player in ipairs(Players:GetPlayers()) do
		toastRemote:FireClient(player, message)
	end
end
local function publishCalm()
	world:SetAttribute("MarketEvent", "Calm")
	world:SetAttribute("MarketEventDescription", "Market stable • watch for the next event")
	world:SetAttribute("MarketIncomeMultiplier", 1)
	world:SetAttribute("MarketEventEndsAt", 0)
	world:SetAttribute("MarketEventNextAt", nextAt)
end

local function startEvent()
	eventIndex = (eventIndex % #EVENTS) + 1
	local event = EVENTS[eventIndex]
	activeUntil = workspace:GetServerTimeNow() + Config.MARKET_EVENT_DURATION

	world:SetAttribute("MarketEvent", event.Name)
	world:SetAttribute("MarketEventDescription", event.Description)
	world:SetAttribute("MarketIncomeMultiplier", event.IncomeMultiplier)
	world:SetAttribute("MarketEventEndsAt", activeUntil)
	world:SetAttribute("MarketEventNextAt", 0)
	world:SetAttribute("MarketEventPulse", (world:GetAttribute("MarketEventPulse") or 0) + 1)

	broadcast(string.format("MARKET EVENT: %s — %s", string.upper(event.Name), event.Description))
end

local function endEvent()
	local old = tostring(world:GetAttribute("MarketEvent") or "Market")
	nextAt = workspace:GetServerTimeNow() + Config.MARKET_EVENT_INTERVAL
	activeUntil = 0
	publishCalm()
	broadcast(old .. " ended. The market is calm again.")
end
publishCalm()

task.spawn(function()
	while true do
		local now = workspace:GetServerTimeNow()
		if activeUntil > 0 then
			if now >= activeUntil then
				endEvent()
			end
		elseif now >= nextAt then
			startEvent()
		end
		task.wait(0.5)
	end
end)
