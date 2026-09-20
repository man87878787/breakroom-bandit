local Config = {}

Config.GAME_VERSION = 2
Config.DATA_VERSION = 1

Config.PLAYER = {
	StartingCoins = 250,
	StartingTowerLevel = 1,
	MaxTowerLevel = 9,
	BaseWalkSpeed = 16,
	BaseJumpPower = 50,
}

Config.WORLD = {
	HubSize = Vector3.new(82, 2, 82),
	BridgeWidth = 12,
	BridgeThickness = 2,
	VoidFloorSize = Vector3.new(360, 2, 360),
	VoidFloorY = -18,
}

Config.TOWERS = {
	PlotCount = 6,
	PlotRadius = 128,
	PlotSize = Vector3.new(44, 2, 44),
	SpawnHeight = 4,
	FloorHeight = 12,
	BaseFloorCount = 4,
	FloorsPerUpgrade = 1,
	MaxFloors = 12,
	StepsPerFloor = 5,
	ClaimProtectionSeconds = 20,
}

Config.STEAL = {
	InteractDistance = 11,
	HoldDuration = 1.1,
	CarryWalkSpeed = 13,
	EscapeRadius = 22,
	BaseReward = 175,
	LevelReward = 35,
	VictimProtectionSeconds = 25,
	AttackerCooldownSeconds = 12,
	DeathCooldownSeconds = 5,
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
	EnableStudioDataStore = false,
}

Config.REMOTES = {
	RequestTowerUpgrade = "RequestTowerUpgrade",
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
