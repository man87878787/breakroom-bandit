local Config = {}

Config.STARTING_COINS = 120
Config.PASSIVE_TICK = 2
Config.SHIELD_SECONDS = 10
Config.SHIELD_COOLDOWN = 35
Config.MAX_SIDEKICKS = 8
Config.SPAWN_INTERVAL = 3.5
Config.MARKET_LIFETIME = 40
Config.STEAL_COOLDOWN = 7

-- Escape-loop tuning
Config.CARRY_WALK_SPEED = 12
Config.SECURE_RADIUS = 9
Config.RECOVER_HOLD_DURATION = 0.65
Config.SECURE_BONUS_MULTIPLIER = 5

Config.RARITIES = {
	{Name = "Common", Weight = 60, Cost = 25, Income = 2, Color = Color3.fromRGB(225, 225, 225)},
	{Name = "Rare", Weight = 25, Cost = 80, Income = 7, Color = Color3.fromRGB(70, 170, 255)},
	{Name = "Epic", Weight = 10, Cost = 240, Income = 20, Color = Color3.fromRGB(185, 90, 255)},
	{Name = "Legendary", Weight = 4, Cost = 700, Income = 65, Color = Color3.fromRGB(255, 190, 40)},
	{Name = "Glitched", Weight = 1, Cost = 2000, Income = 200, Color = Color3.fromRGB(255, 80, 190)},
}

return Config
