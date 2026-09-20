local Config = {}

Config.GAME_NAME = "Snatch the Stickman"
Config.STARTING_COINS = 120
Config.PASSIVE_TICK = 2

-- Crew progression
Config.CAPACITY_BY_LEVEL = {8, 10, 12}
Config.CAPACITY_UPGRADE_COSTS = {450, 1800}
Config.MAX_SIDEKICKS = Config.CAPACITY_BY_LEVEL[#Config.CAPACITY_BY_LEVEL]

Config.INCOME_MULTIPLIERS = {1, 1.20, 1.50, 1.85}
Config.INCOME_UPGRADE_COSTS = {350, 1100, 3200}

-- Defense progression
Config.SHIELD_DURATION_BY_LEVEL = {10, 13, 16, 20}
Config.SHIELD_COOLDOWN_BY_LEVEL = {35, 31, 27, 24}
Config.SHIELD_UPGRADE_COSTS = {300, 950, 2800}
Config.SHIELD_SECONDS = Config.SHIELD_DURATION_BY_LEVEL[1]
Config.SHIELD_COOLDOWN = Config.SHIELD_COOLDOWN_BY_LEVEL[1]
Config.JOIN_PROTECTION_SECONDS = 15
Config.REJOIN_STEAL_PROTECTION = 10

-- Market pacing
Config.SPAWN_INTERVAL = 3.5
Config.MARKET_LIFETIME = 45
Config.MARKET_MAX_STOCK = 18
Config.INITIAL_MARKET_STOCK = 10
Config.AFFORDABLE_SPAWN_EVERY = 5
Config.STEAL_COOLDOWN = 8

-- Escape-loop tuning
Config.CARRY_WALK_SPEED = 12
Config.CONTESTED_CARRY_WALK_SPEED = 10.5
Config.CONTESTED_RANGE = 28
Config.CARRY_SERVER_UPDATE_RATE = 1 / 30
Config.SECURE_RADIUS = 9
Config.CARRY_TIMEOUT_SECONDS = 30
Config.BREAKAWAY_SECONDS = 7
Config.VICTIM_BASE_ESCAPE_RADIUS = 38
Config.SNATCH_INTERACTION_RANGE = 11
Config.RECOVER_INTERACTION_RANGE = 10
Config.RECOVER_HOLD_DURATION = 0.65
Config.INTERCEPT_CAPTURE_SECONDS = 2.4
Config.FAST_ROUTE_INTERCEPT_SECONDS = 2.15
Config.SKY_ROUTE_INTERCEPT_SECONDS = 2.8
Config.FAST_ROUTE_CARRY_WALK_SPEED = 12.6
Config.SKY_ROUTE_CARRY_WALK_SPEED = 11.8
Config.INTERCEPT_CAPTURE_RANGE = 9.5
Config.INTERCEPT_DECAY_PER_SECOND = 1.25
Config.TETHER_WIDTH = 0.12
Config.SECURE_BONUS_MULTIPLIER = 5
Config.STREAK_BONUS_STEP = 0.12
Config.STREAK_BONUS_CAP = 0.60

-- City transit
Config.TRANSIT_COOLDOWN_SECONDS = 3.5
Config.TRANSIT_MAX_TRIGGER_DISTANCE = 14
Config.TRANSIT_EXIT_HEIGHT = 4

-- Local movement presentation. Visual only; gameplay movement remains server-authoritative.
Config.MOVEMENT_PRESENTATION = {
	Enabled = true,
	ForwardLeanDegrees = 2.0,
	SideLeanDegrees = 2.8,
	LandingDip = 0.018,
	LandingRecovery = 0.22,
	Response = 18,
	MinSpeed = 1.5,
	TouchScale = 0.58,
}

-- Session missions
Config.MISSIONS = {
	Recruit = {Goal = 3, Reward = 150, Label = "Recruit 3 stickmen"},
	Earn = {Goal = 500, Reward = 250, Label = "Earn $500"},
	Snatch = {Goal = 1, Reward = 300, Label = "Secure 1 rival stickman"},
}

Config.DISCOVERY_REWARDS = {
	Common = 25,
	Rare = 80,
	Epic = 250,
	Legendary = 750,
	Glitched = 2000,
}

Config.DISCOVERY_MILESTONES = {
	{Count = 2, Reward = 150},
	{Count = 3, Reward = 450},
	{Count = 4, Reward = 1200},
	{Count = 5, Reward = 3500},
}

Config.MASTERY_MAX_LEVEL = 30
Config.MASTERY_BASE_XP = 90
Config.MASTERY_XP_GROWTH = 45
Config.MASTERY_RECRUIT_XP = 14
Config.MASTERY_SNATCH_XP = 60
Config.MASTERY_DISCOVERY_XP = 85
Config.MASTERY_STREAK_XP = 18
Config.MASTERY_ROUTE_XP = 24
Config.MASTERY_LEVEL_REWARD_BASE = 90
Config.MASTERY_LEVEL_REWARD_STEP = 35
Config.MASTERY_INCOME_BONUS_PER_LEVEL = 0.01
Config.MASTERY_INCOME_BONUS_CAP = 0.25

Config.DIVERSITY_BONUS_PER_EXTRA_RARITY = 0.03
Config.DIVERSITY_BONUS_CAP = 0.12

Config.MARKET_EVENT_INTERVAL = 100
Config.MARKET_EVENT_DURATION = 38
Config.PAYDAY_MULTIPLIER = 1.5
Config.RARE_RUSH_EPIC_PLUS_MULTIPLIER = 2.4

Config.RARITIES = {
	{Name = "Common", Rank = 1, Weight = 60, Cost = 25, Income = 2, Color = Color3.fromRGB(225, 225, 225), Glow = false},
	{Name = "Rare", Rank = 2, Weight = 25, Cost = 80, Income = 7, Color = Color3.fromRGB(70, 170, 255), Glow = false},
	{Name = "Epic", Rank = 3, Weight = 10, Cost = 240, Income = 20, Color = Color3.fromRGB(185, 90, 255), Glow = true},
	{Name = "Legendary", Rank = 4, Weight = 4, Cost = 700, Income = 65, Color = Color3.fromRGB(255, 190, 40), Glow = true},
	{Name = "Glitched", Rank = 5, Weight = 1, Cost = 2000, Income = 200, Color = Color3.fromRGB(255, 80, 190), Glow = true},
}

return Config