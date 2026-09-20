-- Rotating district activities that turn the expanded city into active gameplay.
-- Server authoritative: clients only display attributes; movement and rewards are verified here.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local WorldConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("WorldConfig"))
local remotes = ReplicatedStorage:WaitForChild("GameRemotes")
local toastRemote = remotes:WaitForChild("Toast")

local world = workspace:WaitForChild("SnatchTheStickmanWorld")
local connectedMap = world:WaitForChild("ConnectedMap")

local old = connectedMap:FindFirstChild("DistrictActivities")
if old then old:Destroy() end

local activityRoot = Instance.new("Folder")
activityRoot.Name = "DistrictActivities"
activityRoot.Parent = connectedMap

local sessions = {}
local completedUsers = {}
local markers = {}
local activityBag = {}
local lastActivityId = nil
local rng = Random.new()
local cycleId = 0
local activeActivity = nil
local activeUntil = 0
local nextAt = workspace:GetServerTimeNow() + WorldConfig.ACTIVITY_SETTINGS.InitialDelay

local function toast(player, message)
	if player and player.Parent == Players then
		toastRemote:FireClient(player, message)
	end
end

local function broadcast(message)
	for _, player in ipairs(Players:GetPlayers()) do
		toast(player, message)
	end
end

local function getRoot(player)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if humanoid and humanoid.Health > 0 and root then return root end
	return nil
end

local function heistLocked(player)
	return player:GetAttribute("CarryRarity") ~= nil
		or player:GetAttribute("CarryVictimName") ~= nil
		or player:GetAttribute("StickmanThreatened") == true
		or player:GetAttribute("CarryContested") == true
end

local function award(player, amount)
	local leaderstats = player:FindFirstChild("leaderstats")
	local profile = player:FindFirstChild("Profile")
	local coins = leaderstats and leaderstats:FindFirstChild("Coins")
	if not coins then return false end
	coins.Value += amount
	local lifetime = profile and profile:FindFirstChild("LifetimeCoinsEarned")
	local sessionEarned = profile and profile:FindFirstChild("SessionEarned")
	if lifetime then lifetime.Value += amount end
	if sessionEarned then sessionEarned.Value += amount end
	return true
end

local function makeMarker(activity)
	local district = WorldConfig.GetDistrictById(activity.DistrictId)
	if not district then return end

	local markerPosition = activity.Position or district.Center
	local marker = Instance.new("Part")
	marker.Name = activity.Id .. "Marker"
	marker.Size = Vector3.new(math.max(5.5, activity.Radius * 1.6), 0.18, math.max(5.5, activity.Radius * 1.6))
	marker.CFrame = CFrame.new(markerPosition + Vector3.new(0, 0.12, 0))
	marker.Anchored = true
	marker.CanCollide = false
	marker.CanTouch = false
	marker.CanQuery = false
	marker.Material = Enum.Material.Neon
	marker.Color = activity.Accent
	marker.Transparency = 0.78
	marker.Parent = activityRoot

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "ActivitySign"
	billboard.Size = UDim2.fromOffset(260, 64)
	billboard.StudsOffset = Vector3.new(0, 5.5, 0)
	billboard.AlwaysOnTop = false
	billboard.MaxDistance = 85
	billboard.Enabled = false
	billboard.Parent = marker

	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundColor3 = Color3.fromRGB(14, 17, 25)
	label.BackgroundTransparency = 0.12
	label.TextColor3 = activity.Accent
	label.TextStrokeTransparency = 0.7
	label.TextScaled = true
	label.TextWrapped = true
	label.Font = Enum.Font.GothamBold
	label.Text = activity.Name
	label.Parent = billboard

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = label

	markers[activity.Id] = {Part = marker, Billboard = billboard, Label = label}
end

for _, activity in ipairs(WorldConfig.ACTIVITIES) do
	makeMarker(activity)
end

local function setPlayerState(player, activity, progress, completed)
	player:SetAttribute("DistrictActivityActive", activity ~= nil)
	player:SetAttribute("DistrictActivityId", activity and activity.Id or "")
	player:SetAttribute("DistrictActivityName", activity and activity.Name or "")
	player:SetAttribute("DistrictActivityDistrict", activity and activity.DistrictId or "")
	player:SetAttribute("DistrictActivityProgress", progress or 0)
	player:SetAttribute("DistrictActivityGoal", activity and activity.RequiredSeconds or 0)
	player:SetAttribute("DistrictActivityReward", activity and activity.Reward or 0)
	player:SetAttribute("DistrictActivityCompleted", completed == true)
end

local function publishWorld()
	world:SetAttribute("DistrictActivityId", activeActivity and activeActivity.Id or "")
	world:SetAttribute("DistrictActivityName", activeActivity and activeActivity.Name or "City quiet")
	world:SetAttribute("DistrictActivityDistrict", activeActivity and activeActivity.DistrictId or "")
	world:SetAttribute("DistrictActivityDescription", activeActivity and activeActivity.Description or "A new district activity will begin soon.")
	world:SetAttribute("DistrictActivityEndsAt", activeUntil)
	world:SetAttribute("DistrictActivityNextAt", activeActivity and 0 or nextAt)
	world:SetAttribute("DistrictActivityReward", activeActivity and activeActivity.Reward or 0)
	world:SetAttribute("DistrictActivityRequiredSeconds", activeActivity and activeActivity.RequiredSeconds or 0)
end

local function refreshMarkers()
	for id, marker in pairs(markers) do
		local enabled = activeActivity and activeActivity.Id == id
		marker.Billboard.Enabled = enabled == true
		marker.Part.Transparency = enabled and 0.28 or 0.82
		if enabled then
			marker.Label.Text = string.format("%s\nSTAY IN ZONE • +$%d", activeActivity.Name, activeActivity.Reward)
		end
	end
end

local function refillActivityBag()
	activityBag = table.clone(WorldConfig.ACTIVITIES)
	for index = #activityBag, 2, -1 do
		local swapIndex = rng:NextInteger(1, index)
		activityBag[index], activityBag[swapIndex] = activityBag[swapIndex], activityBag[index]
	end
	if #activityBag > 1 and lastActivityId and activityBag[#activityBag].Id == lastActivityId then
		activityBag[1], activityBag[#activityBag] = activityBag[#activityBag], activityBag[1]
	end
end

local function nextActivity()
	if #activityBag == 0 then refillActivityBag() end
	local activity = table.remove(activityBag)
	lastActivityId = activity.Id
	return activity
end

local function beginActivity()
	activeActivity = nextActivity()
	cycleId += 1
	completedUsers = {}
	activeUntil = workspace:GetServerTimeNow() + activeActivity.Duration
	nextAt = 0

	for _, player in ipairs(Players:GetPlayers()) do
		sessions[player] = {Cycle = cycleId, Progress = 0, Completed = false}
		setPlayerState(player, activeActivity, 0, false)
	end
	publishWorld()
	refreshMarkers()
	world:SetAttribute("DistrictActivityPulse", (world:GetAttribute("DistrictActivityPulse") or 0) + 1)
	broadcast(string.format("CITY ACTIVITY: %s — %s (+$%d)", activeActivity.Name, activeActivity.Description, activeActivity.Reward))
end

local function endActivity()
	activeActivity = nil
	activeUntil = 0
	nextAt = workspace:GetServerTimeNow() + WorldConfig.ACTIVITY_SETTINGS.Interval
	for _, player in ipairs(Players:GetPlayers()) do
		setPlayerState(player, nil, 0, false)
	end
	sessions = {}
	publishWorld()
	refreshMarkers()
end

local function stepPlayer(player, dt)
	if not activeActivity or player:GetAttribute("DataReady") ~= true then return end
	local session = sessions[player]
	if not session or session.Cycle ~= cycleId then
		local completed = completedUsers[player.UserId] == true
		session = {Cycle = cycleId, Progress = 0, Completed = completed}
		sessions[player] = session
		setPlayerState(player, activeActivity, 0, completed)
	end
	if session.Completed then return end

	local root = getRoot(player)
	local district = WorldConfig.GetDistrictById(activeActivity.DistrictId)
	if not root or not district or heistLocked(player) then return end

	local target = activeActivity.Position or district.Center
	if (root.Position - target).Magnitude > activeActivity.Radius then return end

	session.Progress = math.min(activeActivity.RequiredSeconds, session.Progress + dt)
	player:SetAttribute("DistrictActivityProgress", session.Progress)
	if session.Progress >= activeActivity.RequiredSeconds then
		if award(player, activeActivity.Reward) then
			session.Completed = true
			completedUsers[player.UserId] = true
			player:SetAttribute("DistrictActivityCompleted", true)
			player:SetAttribute("DistrictActivityPulse", (player:GetAttribute("DistrictActivityPulse") or 0) + 1)
			player:SetAttribute("DistrictActivityLastReward", activeActivity.Reward)
			toast(player, string.format("%s COMPLETE! +$%d", activeActivity.Name, activeActivity.Reward))
		end
	end
end

Players.PlayerAdded:Connect(function(player)
	if activeActivity then
		local completed = completedUsers[player.UserId] == true
		local progress = completed and activeActivity.RequiredSeconds or 0
		sessions[player] = {Cycle = cycleId, Progress = progress, Completed = completed}
		setPlayerState(player, activeActivity, progress, completed)
	else
		setPlayerState(player, nil, 0, false)
	end
end)

Players.PlayerRemoving:Connect(function(player)
	sessions[player] = nil
end)

publishWorld()
refreshMarkers()

task.spawn(function()
	local last = os.clock()
	while true do
		local nowClock = os.clock()
		local dt = math.min(0.75, nowClock - last)
		last = nowClock
		local now = workspace:GetServerTimeNow()

		if activeActivity then
			for _, player in ipairs(Players:GetPlayers()) do
				stepPlayer(player, dt)
			end
			if now >= activeUntil then endActivity() end
		elseif now >= nextAt then
			beginActivity()
		end
		task.wait(WorldConfig.ACTIVITY_SETTINGS.TickRate)
	end
end)
