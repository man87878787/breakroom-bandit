local Config = {}

Config.GAME_VERSION = 1
Config.DATA_VERSION = 1

Config.PLAYER = {
	StartingCoins = 250,
	StartingTowerLevel = 1,
	MaxTowerLevel = 50,
	BaseWalkSpeed = 16,
	BaseJumpPower = 50,
}

Config.TOWERS = {
	PlotCount = 6,
	PlotRadius = 145,
	PlotSize = Vector3.new(42, 1, 42),
	SpawnHeight = 4,
	FloorHeight = 18,
	BaseFloorCount = 5,
	FloorsPerUpgrade = 1,
	MaxFloors = 24,
	ClaimProtectionSeconds = 20,
}

Config.STEAL = {
	InteractDistance = 12,
	HoldDuration = 1.25,
	CarryWalkSpeed = 13,
	EscapeRadius = 26,
	BaseReward = 175,
	LevelReward = 35,
	VictimProtectionSeconds = 25,
	AttackerCooldownSeconds = 12,
	MaxLevelDifference = 12,
}

Config.UPGRADES = {
	TowerBaseCost = 300,
	TowerGrowth = 1.34,
	MovementBaseCost = 225,
	MovementGrowth = 1.42,
	DefenseBaseCost = 350,
	DefenseGrowth = 1.45,
	MaxMovementLevel = 10,
	MaxDefenseLevel = 10,
}

Config.PERSISTENCE = {
	StoreName = "StealATowerOfHell_v1",
	SaveIntervalSeconds = 60,
	MaxRetries = 4,
	RetryDelaySeconds = 1.5,
}

Config.REMOTES = {
	RequestTowerUpgrade = "RequestTowerUpgrade",
	RequestSteal = "RequestSteal",
	RequestBankSteal = "RequestBankSteal",
	StateChanged = "StateChanged",
	Toast = "Toast",
}

function Config.GetTowerUpgradeCost(level)
	return math.floor(Config.UPGRADES.TowerBaseCost * (Config.UPGRADES.TowerGrowth ^ math.max(0, level - 1)))
end

function Config.GetStealReward(victimTowerLevel)
	return Config.STEAL.BaseReward + math.max(0, victimTowerLevel - 1) * Config.STEAL.LevelReward
end

return Config
