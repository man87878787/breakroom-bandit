local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local StealService = {}
local carrying = {}
local cooldownUntil = {}
local protectedUntil = {}
local targetLocks = {}

local function now()
	return workspace:GetServerTimeNow()
end

local function rootOf(player)
	local character = player.Character
	return character and character:FindFirstChild("HumanoidRootPart")
end

local function humanoidOf(player)
	local character = player.Character
	return character and character:FindFirstChildOfClass("Humanoid")
end

local function restoreMovement(player)
	local humanoid = humanoidOf(player)
	if humanoid then
		humanoid.WalkSpeed = Config.PLAYER.BaseWalkSpeed
	end
end

function StealService.CanStart(attacker, victim, victimPlot)
	if not victimPlot then
		return false, "That tower is unavailable."
	end
	if victim and attacker == victim then
		return false, "You cannot steal your own core."
	end
	if not victim and victimPlot:GetAttribute("IsNPC") ~= true then
		return false, "That tower has no active core."
	end
	if carrying[attacker] then
		return false, "Bank your current core first."
	end
	if (cooldownUntil[attacker] or 0) > now() then
		return false, "Your steal ability is cooling down."
	end
	if victim and (protectedUntil[victim] or 0) > now() then
		return false, "That tower is temporarily protected."
	end
	if targetLocks[victimPlot] then
		return false, "Someone is already escaping with that core."
	end

	local attackerRoot = rootOf(attacker)
	local structure = victimPlot:FindFirstChild("Structure")
	local core = structure and structure:FindFirstChild("StealCore")
	if not attackerRoot or not core then
		return false, "That core is unavailable."
	end
	if (attackerRoot.Position - core.Position).Magnitude > Config.STEAL.InteractDistance + 2 then
		return false, "Move closer to the tower core."
	end

	local attackerLevel = tonumber(attacker:GetAttribute("TowerLevel")) or 1
	local victimLevel = victim
		and (tonumber(victim:GetAttribute("TowerLevel")) or 1)
		or (tonumber(victimPlot:GetAttribute("TowerLevel")) or 1)

	if victimLevel - attackerLevel > Config.STEAL.MaxLevelDifference then
		return false, "That tower is too far above your current level."
	end

	return true
end

function StealService.Start(attacker, victim, victimPlot)
	local ok, reason = StealService.CanStart(attacker, victim, victimPlot)
	if not ok then
		return false, reason
	end

	local victimLevel = victim
		and (tonumber(victim:GetAttribute("TowerLevel")) or 1)
		or (tonumber(victimPlot:GetAttribute("TowerLevel")) or 1)
	local victimName = victim
		and victim.DisplayName
		or tostring(victimPlot:GetAttribute("OwnerName") or "Rival")
	local reward = Config.GetStealReward(victimLevel)

	carrying[attacker] = {
		VictimUserId = victim and victim.UserId or 0,
		VictimName = victimName,
		Reward = reward,
		StartedAt = now(),
		TargetPlot = victimPlot,
	}
	targetLocks[victimPlot] = attacker

	attacker:SetAttribute("CarryingSteal", true)
	attacker:SetAttribute("StealReward", reward)
	attacker:SetAttribute("StolenFrom", victimName)

	local humanoid = humanoidOf(attacker)
	if humanoid then
		humanoid.WalkSpeed = Config.STEAL.CarryWalkSpeed
	end

	return true, reward
end

function StealService.Bank(attacker, attackerPlot)
	local active = carrying[attacker]
	if not active or not attackerPlot then
		return false, "You are not carrying a stolen core."
	end

	local root = rootOf(attacker)
	if not root or not attackerPlot.PrimaryPart then
		return false, "Your tower is unavailable."
	end
	if (root.Position - attackerPlot.PrimaryPart.Position).Magnitude > Config.STEAL.EscapeRadius then
		return false, "Return to your own base to bank the core."
	end

	carrying[attacker] = nil
	targetLocks[active.TargetPlot] = nil
	cooldownUntil[attacker] = now() + Config.STEAL.AttackerCooldownSeconds

	attacker:SetAttribute("CarryingSteal", false)
	attacker:SetAttribute("StealReward", 0)
	attacker:SetAttribute("StolenFrom", "")
	restoreMovement(attacker)

	return true, active
end

function StealService.CancelCarry(player, applyCooldown)
	local active = carrying[player]
	if not active then
		return false
	end

	targetLocks[active.TargetPlot] = nil
	carrying[player] = nil

	player:SetAttribute("CarryingSteal", false)
	player:SetAttribute("StealReward", 0)
	player:SetAttribute("StolenFrom", "")
	restoreMovement(player)

	if applyCooldown then
		cooldownUntil[player] = now() + Config.STEAL.DeathCooldownSeconds
	end
	return true
end

function StealService.Protect(player, duration)
	local seconds = tonumber(duration) or Config.STEAL.VictimProtectionSeconds
	protectedUntil[player] = now() + math.max(0, seconds)
	player:SetAttribute("ProtectedUntil", protectedUntil[player])
end

function StealService.GetProtectionRemaining(player)
	return math.max(0, (protectedUntil[player] or 0) - now())
end

function StealService.Clear(player)
	local active = carrying[player]
	if active then
		targetLocks[active.TargetPlot] = nil
	end

	carrying[player] = nil
	cooldownUntil[player] = nil
	protectedUntil[player] = nil
end

return StealService
