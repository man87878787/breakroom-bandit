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

local function toast(player, text)
	if player.Parent == Players then
		remoteObjects.Toast:FireClient(player, tostring(text))
	end
end

local function applyPlayerState(player, data)
	player:SetAttribute("Coins", data.Coins)
	player:SetAttribute("TowerLevel", data.TowerLevel)
	player:SetAttribute("MovementLevel", data.MovementLevel)
	player:SetAttribute("DefenseLevel", data.DefenseLevel)
	player:SetAttribute("Steals", data.Steals)
	player:SetAttribute("TimesRobbed", data.TimesRobbed)
	player:SetAttribute("CarryingSteal", false)
	player:SetAttribute("StealReward", 0)
	player:SetAttribute("StolenFrom", "")
	player:SetAttribute("TowerPlotIndex", 0)

	local oldLeaderstats = player:FindFirstChild("leaderstats")
	if oldLeaderstats then
		oldLeaderstats:Destroy()
	end

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
	if not data or player.Parent ~= Players then
		return
	end

	player:SetAttribute("Coins", data.Coins)
	player:SetAttribute("TowerLevel", data.TowerLevel)
	player:SetAttribute("MovementLevel", data.MovementLevel)
	player:SetAttribute("DefenseLevel", data.DefenseLevel)
	player:SetAttribute("Steals", data.Steals)
	player:SetAttribute("TimesRobbed", data.TimesRobbed)

	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local coins = leaderstats:FindFirstChild("Coins")
		local steals = leaderstats:FindFirstChild("Steals")
		if coins then coins.Value = data.Coins end
		if steals then steals.Value = data.Steals end
	end

	local plot = TowerService.GetForPlayer(player)
	local towerLevel = data.TowerLevel
	local maxLevel = towerLevel >= Config.PLAYER.MaxTowerLevel
	local nextUpgradeCost = maxLevel and 0 or Config.GetTowerUpgradeCost(towerLevel)

	remoteObjects.StateChanged:FireClient(player, {
		Coins = data.Coins,
		TowerLevel = towerLevel,
		MaxTowerLevel = Config.PLAYER.MaxTowerLevel,
		FloorCount = plot and plot:GetAttribute("FloorCount") or 0,
		PlotIndex = plot and plot:GetAttribute("PlotIndex") or 0,
		NextUpgradeCost = nextUpgradeCost,
		Steals = data.Steals,
		TimesRobbed = data.TimesRobbed,
		CarryingSteal = player:GetAttribute("CarryingSteal") == true,
		StealReward = player:GetAttribute("StealReward") or 0,
		StolenFrom = player:GetAttribute("StolenFrom") or "",
	})
end

local function assignPlot(player)
	local data = PlayerData.Get(player)
	if not data then
		return nil
	end

	local plot = TowerService.Assign(player, data.TowerLevel)
	if not plot then
		player.RespawnLocation = world:FindFirstChild("HubSpawn")
		return nil
	end

	local spawn = plot:FindFirstChild("OwnerSpawn")
	if spawn and player.Character then
		player.Character:PivotTo(spawn.CFrame * CFrame.new(0, 3, 0))
	end

	StealService.Protect(player, Config.TOWERS.ClaimProtectionSeconds)
	sync(player)
	return plot
end

local function setupCharacter(player, character)
	local humanoid = character:WaitForChild("Humanoid", 10)
	if not humanoid then
		return
	end

	humanoid.WalkSpeed = Config.PLAYER.BaseWalkSpeed
	humanoid.JumpPower = Config.PLAYER.BaseJumpPower

	local plot = TowerService.GetForPlayer(player)
	local spawn = plot and plot:FindFirstChild("OwnerSpawn")
	if spawn then
		character:PivotTo(spawn.CFrame * CFrame.new(0, 3, 0))
	end

	humanoid.Died:Connect(function()
		if StealService.CancelCarry(player, true) then
			toast(player, "You dropped the stolen core.")
			sync(player)
		end
	end)
end

local function requestUpgrade(player, sourcePlot)
	local data = PlayerData.Get(player)
	if not data then
		return
	end

	local ownPlot = TowerService.GetForPlayer(player)
	if not ownPlot then
		toast(player, "You do not have a tower yet.")
		return
	end
	if sourcePlot and sourcePlot ~= ownPlot then
		toast(player, "You can only upgrade your own tower.")
		return
	end
	if data.TowerLevel >= Config.PLAYER.MaxTowerLevel then
		toast(player, "Your tower is already max level.")
		return
	end

	local cost = Config.GetTowerUpgradeCost(data.TowerLevel)
	if data.Coins < cost then
		toast(player, ("You need %d coins to upgrade."):format(cost))
		return
	end

	data.Coins -= cost
	data.TowerLevel += 1
	TowerService.Refresh(player, data.TowerLevel)
	sync(player)
	toast(player, ("Tower upgraded to level %d!"):format(data.TowerLevel))
end

local function requestSteal(player, targetPlot)
	if not targetPlot then
		return
	end

	local victim = TowerService.GetPlayerFromPlot(targetPlot)
	local ok, result = StealService.Start(player, victim, targetPlot)
	if not ok then
		toast(player, result)
		return
	end

	sync(player)
	toast(player, ("CORE STOLEN! Escape to your green vault for %d coins."):format(result))

	if victim then
		toast(victim, ("%s stole your core!"):format(player.DisplayName))
	end
end

local function requestBank(player, sourcePlot)
	local ownPlot = TowerService.GetForPlayer(player)
	if not ownPlot then
		toast(player, "You do not have a tower to bank at.")
		return
	end
	if sourcePlot and sourcePlot ~= ownPlot then
		toast(player, "That is not your vault.")
		return
	end

	local ok, result = StealService.Bank(player, ownPlot)
	if not ok then
		toast(player, result)
		return
	end

	local victim = result.VictimUserId > 0
		and Players:GetPlayerByUserId(result.VictimUserId)
		or nil

	PlayerData.Update(player, function(data)
		data.Coins += result.Reward
		data.Steals += 1
	end)

	if victim then
		PlayerData.Update(victim, function(data)
			data.TimesRobbed += 1
		end)
		StealService.Protect(victim, Config.STEAL.VictimProtectionSeconds)
		sync(victim)
		toast(victim, "Your core returned. Temporary protection is active.")
	end

	sync(player)
	toast(player, ("BANKED! +%d coins"):format(result.Reward))
end

TowerService.SetInteractionHandlers({
	Steal = requestSteal,
	Bank = requestBank,
	Upgrade = requestUpgrade,
})

remoteObjects.RequestTowerUpgrade.OnServerEvent:Connect(function(player)
	requestUpgrade(player, nil)
end)

remoteObjects.RequestBankSteal.OnServerEvent:Connect(function(player)
	requestBank(player, nil)
end)

local function onPlayerAdded(player)
	local data = PlayerData.Load(player)
	applyPlayerState(player, data)

	player.CharacterAdded:Connect(function(character)
		setupCharacter(player, character)
	end)
	if player.Character then
		task.spawn(setupCharacter, player, player.Character)
	end

	local plot = assignPlot(player)
	if not plot then
		toast(player, "All tower plots are occupied. You will spawn in the hub until one opens.")
		sync(player)
	end
end

local function assignWaitingPlayer(excludedPlayer)
	for _, candidate in ipairs(Players:GetPlayers()) do
		if candidate ~= excludedPlayer and not TowerService.GetForPlayer(candidate) and PlayerData.Get(candidate) then
			local plot = assignPlot(candidate)
			if plot then
				toast(candidate, "A tower plot just opened — it is yours!")
				return
			end
		end
	end
end

local function onPlayerRemoving(player)
	StealService.Clear(player)
	TowerService.Release(player)
	PlayerData.Release(player)
	task.defer(assignWaitingPlayer, player)
end

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
