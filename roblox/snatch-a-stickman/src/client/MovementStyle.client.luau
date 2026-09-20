-- Subtle local movement polish that lets Roblox's default character animation stay dominant.
-- Visual only: no WalkSpeed, velocity, jump, or server movement changes.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local player = Players.LocalPlayer
local style = Config.MOVEMENT_PRESENTATION

if not style or style.Enabled == false then
	return
end

local updateConnection
local stateConnection
local serial = 0

local function damp(current, target, response, dt)
	local alpha = 1 - math.exp(-response * math.min(dt, 0.05))
	return current + (target - current) * alpha
end

local function rootMotor(character, rootPart)
	for _, motor in ipairs(rootPart:GetChildren()) do
		if motor:IsA("Motor6D") and motor.Part0 == rootPart then
			return motor
		end
	end
	for _, descendant in ipairs(character:GetDescendants()) do
		if descendant:IsA("Motor6D") and descendant.Part0 == rootPart then
			return descendant
		end
	end
	return nil
end

local function disconnect()
	if updateConnection then
		updateConnection:Disconnect()
		updateConnection = nil
	end
	if stateConnection then
		stateConnection:Disconnect()
		stateConnection = nil
	end
end

local function bind(character)
	serial += 1
	local bindSerial = serial
	disconnect()

	local humanoid = character:WaitForChild("Humanoid", 10)
	local rootPart = character:WaitForChild("HumanoidRootPart", 10)
	if bindSerial ~= serial or not humanoid or not rootPart then return end

	local motor = rootMotor(character, rootPart)
	if not motor then return end

	local touchOnly = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
	local deviceScale = touchOnly and (style.TouchScale or 0.58) or 1
	local pitch = 0
	local roll = 0
	local landing = 0

	stateConnection = humanoid.StateChanged:Connect(function(_, newState)
		if newState == Enum.HumanoidStateType.Landed then
			landing = style.LandingDip or 0.018
		end
	end)

	updateConnection = RunService.PreSimulation:Connect(function(dt)
		if bindSerial ~= serial or humanoid.Health <= 0 or not character.Parent or not motor.Parent then
			return
		end

		local move = humanoid.MoveDirection
		local velocity = rootPart.AssemblyLinearVelocity
		local horizontalSpeed = Vector3.new(velocity.X, 0, velocity.Z).Magnitude
		local grounded = humanoid.FloorMaterial ~= Enum.Material.Air
		local moving = grounded and move.Magnitude > 0.05 and horizontalSpeed > (style.MinSpeed or 1.5)

		local localMove = rootPart.CFrame:VectorToObjectSpace(move)
		local speedScale = math.clamp(horizontalSpeed / math.max(humanoid.WalkSpeed, 1), 0, 1)

		local targetPitch = 0
		local targetRoll = 0
		if moving then
			targetPitch = localMove.Z * math.rad(style.ForwardLeanDegrees or 2) * speedScale * deviceScale
			targetRoll = -localMove.X * math.rad(style.SideLeanDegrees or 2.8) * speedScale * deviceScale
		end

		local response = style.Response or 18
		pitch = damp(pitch, targetPitch, response, dt)
		roll = damp(roll, targetRoll, response, dt)

		landing = math.max(0, landing - dt * (style.LandingRecovery or 0.22))
		local overlay = CFrame.new(0, -landing * deviceScale, 0) * CFrame.Angles(pitch, 0, roll)
		motor.Transform = motor.Transform * overlay
	end)
end

player.CharacterAdded:Connect(function(character)
	task.defer(bind, character)
end)

player.CharacterRemoving:Connect(function()
	serial += 1
	disconnect()
end)

if player.Character then
	task.defer(bind, player.Character)
end
