local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local PlayerData = require(script.Parent.Services:WaitForChild("PlayerData"))
local TowerService = require(script.Parent.Services:WaitForChild("TowerService"))
local StealService = require(script.Parent.Services:WaitForChild("StealService"))

local oldWorld = workspace:FindFirstChild("StealATowerOfHellWorld")
if oldWorld then
	oldWorld:Destroy()
end

local world = Instance.new("Folder")
world.Name = "StealATowerOfHellWorld"
world:SetAttribute("GameVersion", Config.GAME_VERSION)
world.Parent = workspace

local remotes = ReplicatedStorage:FindFirstChild("GameRemotes")
if remotes then
	remotes:Destroy()
end
remotes = Instance.new("Folder")
remotes.Name = "GameRemotes"
remotes.Parent = ReplicatedStorage

local remoteObjects = {}
for key, remoteName in pairs(Config.REMOTES) do
	local remote = Instance.new("RemoteEvent")
	remote.Name = remoteName
	remote.Parent = remotes
	remoteObjects[key] = remote
end

TowerService.Initialize(world)

local function applyPlayerState(player, data)
	player:SetAttribute("Coins", data.Coins)
	player:SetAttribute("TowerLevel", data.TowerLevel)
	player:SetAttribute("MovementLevel", data.MovementLevel)
	player:SetAttribute("DefenseLevel", data.DefenseLevel)
	player:SetAttribute("Steals", data.Steals)
	player:SetAttribute("TimesRobbed", data.TimesRobbed)
	player:SetAttribute("CarryingSteal", false)
	player:SetAttribute("StealReward", 0)

	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	local coins = Instance.new("IntValue")
	coins.Name = "Coins"
	coins.Value = data.Coins
	coins.Parent = leaderstats

	local steals = Instance.new("IntValue")
	steals.Name = "Steals"
	steals.Value = data.Steals
	steals.Parent = leaderstats
end

local function sync(player)
	local data = PlayerData.Get(player)
	if not data then
		return
	end

	player:SetAttribute("Coins", data.Coins)
	player:SetAttribute("TowerLevel", data.TowerLevel)
	player:SetAttribute("Steals", data.Steals)
	player:SetAttribute("TimesRobbed", data.TimesRobbed)

	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local coins = leaderstats:FindFirstChild("Coins")
		local steals = leaderstats:FindFirstChild("Steals")
		if coins then coins.Value = data.Coins end
		if steals then steals.Value = data.Steals end
	end

	remoteObjects.StateChanged:FireClient(player, {
		Coins = data.Coins,
		TowerLevel = data.TowerLevel,
		Steals = data.Steals,
		CarryingSteal = player:GetAttribute("CarryingSteal") == true,
		StealReward = player:GetAttribute("StealReward") or 0,
	})
end

local function toast(player, text)
	remoteObjects.Toast:FireClient(player, tostring(text))
end

local function onPlayerAdded(player)
	local data = PlayerData.Load(player)
	applyPlayerState(player, data)

	local plot = TowerService.Assign(player, data.TowerLevel)
	if not plot then
		toast(player, "All tower plots are occupied. You are queued for a plot.")
	else
		player.RespawnLocation = plot:FindFirstChild("OwnerSpawn")
	end

	sync(player)
end

local function onPlayerRemoving(player)
	TowerService.Release(player)
	StealService.Clear(player)
	PlayerData.Release(player)
end

remoteObjects.RequestTowerUpgrade.OnServerEvent:Connect(function(player)
	local data = PlayerData.Get(player)
	if not data then return end
	if data.TowerLevel >= Config.PLAYER.MaxTowerLevel then
		toast(player, "Your tower is already max level.")
		return
	end

	local cost = Config.GetTowerUpgradeCost(data.TowerLevel)
	if data.Coins < cost then
		toast(player, ("You need %d coins."):format(cost))
		return
	end

	data.Coins -= cost
	data.TowerLevel += 1
	TowerService.Refresh(player, data.TowerLevel)
	sync(player)
	toast(player, ("Tower upgraded to level %d!"):format(data.TowerLevel))
end)

remoteObjects.RequestSteal.OnServerEvent:Connect(function(player, targetPlotIndex)
	if type(targetPlotIndex) ~= "number" then return end
	targetPlotIndex = math.floor(targetPlotIndex)

	local plot = TowerService.GetByIndex(targetPlotIndex)
	local victim = TowerService.GetPlayerFromPlot(plot)
	local ok, result = StealService.Start(player, victim, plot)
	if not ok then
		toast(player, result)
		return
	end

	toast(player, ("Core stolen! Escape home for %d coins."):format(result))
	sync(player)
end)

remoteObjects.RequestBankSteal.OnServerEvent:Connect(function(player)
	local plot = TowerService.GetForPlayer(player)
	local ok, result = StealService.Bank(player, plot)
	if not ok then
		toast(player, result)
		return
	end

	local victim = Players:GetPlayerByUserId(result.VictimUserId)
	PlayerData.Update(player, function(data)
		data.Coins += result.Reward
		data.Steals += 1
	end)

	if victim then
		PlayerData.Update(victim, function(data)
			data.TimesRobbed += 1
		end)
		StealService.Protect(victim)
		sync(victim)
		toast(victim, "Your tower was robbed. Temporary protection is active.")
	end

	sync(player)
	toast(player, ("Banked %d coins!"):format(result.Reward))
end)

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(onPlayerAdded, player)
end

task.spawn(function()
	while true do
		task.wait(Config.PERSISTENCE.SaveIntervalSeconds)
		for _, player in ipairs(Players:GetPlayers()) do
			PlayerData.Save(player)
		end
	end
end)

game:BindToClose(function()
	for _, player in ipairs(Players:GetPlayers()) do
		PlayerData.Save(player)
	end
end)
