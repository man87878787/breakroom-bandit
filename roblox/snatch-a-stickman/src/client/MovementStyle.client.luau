-- Local movement polish layered on top of Roblox's normal character animations.
-- Presentation only: this never changes WalkSpeed, velocity, jump power, or server gameplay.

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

local simulationConnection = nil
local stateConnection = nil
local characterSerial = 0

local function smooth(current, target, response, dt)
	local alpha = 1 - math.exp(-response * math.min(dt, 0.05))
	return current + (target - current) * alpha
end

local function findRootMotor(character, rootPart)
	for _, child in ipairs(rootPart:GetChildren()) do
		if child:IsA("Motor6D") and child.Part0 == rootPart then
			return child
		end
	end
	for _, descendant in ipairs(character:GetDescendants()) do
		if descendant:IsA("Motor6D") and descendant.Part0 == rootPart then
			return descendant
		end
	end
	return nil
end

local function disconnectCharacter()
	if simulationConnection then
		simulationConnection:Disconnect()
		simulationConnection = nil
	end
	if stateConnection then
		stateConnection:Disconnect()
		stateConnection = nil
	end
end

local function bindCharacter(character)
	characterSerial += 1
	local serial = characterSerial
	disconnectCharacter()

	local humanoid = character:WaitForChild("Humanoid", 10)
	local rootPart = character:WaitForChild("HumanoidRootPart", 10)
	if serial ~= characterSerial or not humanoid or not rootPart then
		return
	end

	local rootMotor = findRootMotor(character, rootPart)
	if not rootMotor then
		return
	end

	local touchOnly = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
	local deviceScale = touchOnly and (style.TouchScale or 0.72) or 1
	local phase = 0
	local pitch = 0
	local roll = 0
	local bob = 0
	local landingDip = 0

	stateConnection = humanoid.StateChanged:Connect(function(_, newState)
		if newState == Enum.HumanoidStateType.Landed then
			landingDip = style.LandingDip or 0.045
		end
	end)

	simulationConnection = RunService.PreSimulation:Connect(function(dt)
		if serial ~= characterSerial or not character.Parent or humanoid.Health <= 0 or not rootMotor.Parent then
			return
		end

		local moveDirection = humanoid.MoveDirection
		local localMove = rootPart.CFrame:VectorToObjectSpace(moveDirection)
		local velocity = rootPart.AssemblyLinearVelocity
		local horizontalSpeed = Vector3.new(velocity.X, 0, velocity.Z).Magnitude
		local speedRatio = math.clamp(horizontalSpeed / math.max(humanoid.WalkSpeed, 1), 0, 1.2)
		local grounded = humanoid.FloorMaterial ~= Enum.Material.Air
		local moving = grounded and moveDirection.Magnitude > 0.05 and horizontalSpeed > (style.MinSpeed or 1)

		local forwardLean = math.rad(style.ForwardLeanDegrees or 5)
		local sideLean = math.rad(style.SideLeanDegrees or 4)
		local targetPitch = moving and localMove.Z * forwardLean * speedRatio * deviceScale or 0
		local targetRoll = moving and -localMove.X * sideLean * speedRatio * deviceScale or 0

		if not grounded then
			local airTilt = math.rad(style.AirTiltDegrees or 2.5)
			targetPitch += math.clamp(-velocity.Y / 55, -1, 1) * airTilt * deviceScale
		end

		if moving then
			phase += dt * (style.BobFrequency or 9.5) * (0.72 + speedRatio * 0.38)
		end
		local targetBob = moving and math.sin(phase * 2) * (style.BobHeight or 0.04) * speedRatio * deviceScale or 0

		landingDip = math.max(0, landingDip - dt * (style.LandingRecovery or 0.42))
		local response = style.Response or 14
		pitch = smooth(pitch, targetPitch, response, dt)
		roll = smooth(roll, targetRoll, response, dt)
		bob = smooth(bob, targetBob - landingDip * deviceScale, response, dt)

		local overlay = CFrame.new(0, bob, 0) * CFrame.Angles(pitch, 0, roll)
		rootMotor.Transform = rootMotor.Transform * overlay
	end)
end

player.CharacterAdded:Connect(function(character)
	task.defer(bindCharacter, character)
end)

player.CharacterRemoving:Connect(function()
	characterSerial += 1
	disconnectCharacter()
end)

if player.Character then
	task.defer(bindCharacter, player.Character)
end
