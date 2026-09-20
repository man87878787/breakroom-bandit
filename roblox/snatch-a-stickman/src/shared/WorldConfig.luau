-- Shared authored-world metadata for Snatch the Stickman.
-- Server map, NPC, transit, and client wayfinding systems all consume this file.

local WorldConfig = {}

WorldConfig.MAP_HALF_SIZE = 120

WorldConfig.DISTRICTS = {
	{
		Id = "CentralMarket",
		Name = "Stickman Market",
		Subtitle = "Recruit • trade • watch the market",
		Center = Vector3.new(0, 0, 0),
		Radius = 48,
		Accent = Color3.fromRGB(82, 232, 150),
	},
	{
		Id = "FreightYard",
		Name = "Scrapline Freight",
		Subtitle = "Warehouses • cargo lanes • west transit",
		Center = Vector3.new(-98, 0, 0),
		Radius = 29,
		Accent = Color3.fromRGB(255, 183, 78),
	},
	{
		Id = "NeonJunction",
		Name = "Neon Junction",
		Subtitle = "Transit exchange • signs • east concourse",
		Center = Vector3.new(98, 0, 0),
		Radius = 29,
		Accent = Color3.fromRGB(75, 198, 255),
	},
	{
		Id = "Highline",
		Name = "The Highline",
		Subtitle = "Rooftops • lookout • elevated crossings",
		Center = Vector3.new(0, 0, -100),
		Radius = 27,
		Accent = Color3.fromRGB(204, 105, 255),
	},
	{
		Id = "FoundryCommons",
		Name = "Foundry Commons",
		Subtitle = "Plaza • vendors • south transit",
		Center = Vector3.new(0, 0, 100),
		Radius = 27,
		Accent = Color3.fromRGB(255, 105, 145),
	},
}

WorldConfig.TRANSIT_STOPS = {
	{
		Id = "Market",
		Name = "Market Central",
		Position = Vector3.new(34, 0, 34),
		Accent = Color3.fromRGB(82, 232, 150),
	},
	{
		Id = "Freight",
		Name = "Scrapline Freight",
		Position = Vector3.new(-100, 0, 0),
		Accent = Color3.fromRGB(255, 183, 78),
	},
	{
		Id = "Junction",
		Name = "Neon Junction",
		Position = Vector3.new(100, 0, 0),
		Accent = Color3.fromRGB(75, 198, 255),
	},
	{
		Id = "Highline",
		Name = "Highline Station",
		Position = Vector3.new(0, 0, -101),
		Accent = Color3.fromRGB(204, 105, 255),
	},
	{
		Id = "Commons",
		Name = "Foundry Commons",
		Position = Vector3.new(0, 0, 101),
		Accent = Color3.fromRGB(255, 105, 145),
	},
}

WorldConfig.NPCS = {
	{
		Name = "Mara",
		Role = "Market Broker",
		Position = Vector3.new(-12, 0, 32),
		Accent = Color3.fromRGB(82, 232, 150),
		Dialogue = "Watch rarity, income, and protection before you spend. A flashy stickman is only valuable if you can keep it.",
	},
	{
		Name = "Dex",
		Role = "Route Scout",
		Position = Vector3.new(12, 0, -32),
		Accent = Color3.fromRGB(204, 105, 255),
		Dialogue = "Fast Lane gets you moving. Sky Route buys space. Commit to the route that matches the defender, not your habit.",
	},
	{
		Name = "Bolt",
		Role = "Freight Mechanic",
		Position = Vector3.new(-101, 0, 12),
		Accent = Color3.fromRGB(255, 183, 78),
		Dialogue = "These freight lanes were built for movement. Use the containers as landmarks, but do not corner yourself.",
	},
	{
		Name = "Iris",
		Role = "Transit Dispatcher",
		Position = Vector3.new(101, 0, 12),
		Accent = Color3.fromRGB(75, 198, 255),
		Dialogue = "Transit is for repositioning between districts. Active heists lock the network so nobody can teleport out of a chase.",
	},
	{
		Name = "Vee",
		Role = "Highline Lookout",
		Position = Vector3.new(-30, 0, -98),
		Accent = Color3.fromRGB(204, 105, 255),
		Dialogue = "The Highline gives you a clean read on the city. Learn the silhouettes and you will stop getting lost during a chase.",
	},
	{
		Name = "Sol",
		Role = "Commons Caretaker",
		Position = Vector3.new(18, 0, 108),
		Accent = Color3.fromRGB(255, 105, 145),
		Dialogue = "Foundry Commons is a breather between raids. Check your contracts and mastery before you head back toward a base.",
	},
	{
		Name = "Kite",
		Role = "Bounty Runner",
		Position = Vector3.new(-34, 0, 8),
		Accent = Color3.fromRGB(255, 96, 118),
		Dialogue = "Bounties are a reason to change your target. Do not tunnel on one rarity if the board is paying for another.",
	},
	{
		Name = "Archive-7",
		Role = "Index Curator",
		Position = Vector3.new(8, 0, 52),
		Accent = Color3.fromRGB(110, 132, 255),
		Dialogue = "Your Index is permanent. A discovery stays meaningful even after the stickman changes hands.",
	},
}

function WorldConfig.GetDistrictById(id)
	for _, district in ipairs(WorldConfig.DISTRICTS) do
		if district.Id == id then
			return district
		end
	end
	return nil
end

function WorldConfig.GetTransitStop(id)
	for _, stop in ipairs(WorldConfig.TRANSIT_STOPS) do
		if stop.Id == id then
			return stop
		end
	end
	return nil
end

return WorldConfig
