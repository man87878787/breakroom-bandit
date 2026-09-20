local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local StealService = {}
local carrying = {}
local cooldownUntil = {}
local protectedUntil = {}

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

function StealService.CanStart(attacker, victim, victimPlot)
	if attacker == victim or not victim or not victimPlot then
		return false, "Invalid target."
	end
	if carrying[attacker] then
		return false, "Bank your current steal first."
	end
	if (cooldownUntil[attacker] or 0) > now() then
		return false, "Your steal ability is cooling down."
	end
	if (protectedUntil[victim] or 0) > now() then
		return false, "That tower is temporarily protected."
	end

	local attackerRoot = rootOf(attacker)
	local core = victimPlot:FindFirstChild("Structure") and victimPlot.Structure:FindFirstChild("StealCore")
	if not attackerRoot or not core then
		return false, "Target is unavailable."
	end
	if (attackerRoot.Position - core.Position).Magnitude > Config.STEAL.InteractDistance then
		return false, "Move closer to the tower core."
	end

	local attackerLevel = tonumber(attacker:GetAttribute("TowerLevel")) or 1
	local victimLevel = tonumber(victim:GetAttribute("TowerLevel")) or 1
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

	local victimLevel = tonumber(victim:GetAttribute("TowerLevel")) or 1
	local reward = Config.GetStealReward(victimLevel)
	carrying[attacker] = {
		VictimUserId = victim.UserId,
		Reward = reward,
		StartedAt = now(),
	}

	attacker:SetAttribute("CarryingSteal", true)
	attacker:SetAttribute("StealReward", reward)
	local humanoid = humanoidOf(attacker)
	if humanoid then
		humanoid.WalkSpeed = Config.STEAL.CarryWalkSpeed
	end

	return true, reward
end

function StealService.Bank(attacker, attackerPlot)
	local active = carrying[attacker]
	if not active or not attackerPlot then
		return false, "Nothing to bank."
	end

	local root = rootOf(attacker)
	if not root or not attackerPlot.PrimaryPart then
		return false, "Your tower is unavailable."
	end

	if (root.Position - attackerPlot.PrimaryPart.Position).Magnitude > Config.STEAL.EscapeRadius then
		return false, "Return to your tower to bank the steal."
	end

	carrying[attacker] = nil
	cooldownUntil[attacker] = now() + Config.STEAL.AttackerCooldownSeconds
	attacker:SetAttribute("CarryingSteal", false)
	attacker:SetAttribute("StealReward", 0)

	local humanoid = humanoidOf(attacker)
	if humanoid then
		humanoid.WalkSpeed = Config.PLAYER.BaseWalkSpeed
	end

	return true, active
end

function StealService.Protect(player)
	protectedUntil[player] = now() + Config.STEAL.VictimProtectionSeconds
	player:SetAttribute("ProtectedUntil", protectedUntil[player])
end

function StealService.Clear(player)
	carrying[player] = nil
	cooldownUntil[player] = nil
	protectedUntil[player] = nil
end

return StealService
