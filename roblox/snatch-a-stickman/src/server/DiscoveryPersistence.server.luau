-- Isolated persistence for discovery history so existing v1 player profiles remain backward compatible.
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")

local store = DataStoreService:GetDataStore("SnatchAStickman_Discovery_v1")
local sessions = {}
local closing = false
local MAX_RETRIES = 4

local function retry(callback)
	for attempt = 1, MAX_RETRIES do
		local ok, result = pcall(callback)
		if ok then return true, result end
		warn(string.format("[DiscoveryPersistence] attempt %d failed: %s", attempt, tostring(result)))
		if attempt < MAX_RETRIES then task.wait(0.6 * (2 ^ (attempt - 1))) end
	end
	return false
end

local function sanitize(raw)
	if type(raw) ~= "string" or #raw > 1024 then return "[]" end
	local ok, data = pcall(HttpService.JSONDecode, HttpService, raw)
	if not ok or type(data) ~= "table" then return "[]" end
	local clean = {}
	for _, value in ipairs(data) do
		if type(value) == "string" and #value <= 32 then table.insert(clean, value) end
	end
	local encodedOk, encoded = pcall(HttpService.JSONEncode, HttpService, clean)
	return encodedOk and encoded or "[]"
end

local function setup(player)
	player:SetAttribute("DiscoveryReady", false)
	local profile = player:WaitForChild("Profile", 20)
	if not profile or player.Parent ~= Players then return end
	local value = profile:FindFirstChild("DiscoveryData")
	if not value then
		value = Instance.new("StringValue")
		value.Name = "DiscoveryData"
		value.Value = "[]"
		value.Parent = profile
	end
	local session = {Value = value, Loaded = false, Dirty = false}
	sessions[player] = session
	local ok, saved = retry(function() return store:GetAsync("player_" .. player.UserId) end)
	if sessions[player] ~= session or player.Parent ~= Players then return end
	if ok then
		if type(saved) == "table" then saved = saved.DiscoveryData end
		if type(saved) == "string" then value.Value = sanitize(saved) end
		session.Loaded = true
		value.Changed:Connect(function() if sessions[player] == session then session.Dirty = true end end)
	else
		warn("[DiscoveryPersistence] load unavailable; saving disabled for " .. player.Name)
	end
	player:SetAttribute("DiscoveryReady", true)
end

local function save(player, force)
	local session = sessions[player]
	if not session or not session.Loaded or (not force and not session.Dirty) then return end
	local payload = sanitize(session.Value.Value)
	local ok = retry(function()
		return store:UpdateAsync("player_" .. player.UserId, function(old)
			old = type(old) == "table" and old or {}
			old.Version = 1
			old.DiscoveryData = payload
			old.UpdatedAt = os.time()
			return old
		end)
	end)
	if ok and sessions[player] == session then session.Dirty = false end
end

Players.PlayerAdded:Connect(function(player) task.spawn(setup, player) end)
for _, player in ipairs(Players:GetPlayers()) do task.spawn(setup, player) end
Players.PlayerRemoving:Connect(function(player)
	if not closing then save(player, true) end
	sessions[player] = nil
end)
task.spawn(function()
	while not closing do
		task.wait(60)
		for player in pairs(sessions) do if player.Parent == Players then task.spawn(save, player, false) end end
	end
end)
game:BindToClose(function()
	closing = true
	for player in pairs(sessions) do task.spawn(save, player, true) end
	task.wait(3)
end)
