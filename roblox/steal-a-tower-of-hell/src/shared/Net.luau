local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(script.Parent:WaitForChild("Config"))

local Net = {}

function Net.GetFolder()
	return ReplicatedStorage:WaitForChild("GameRemotes")
end

function Net.Get(name)
	assert(Config.REMOTES[name] ~= nil, ("Unknown remote key: %s"):format(tostring(name)))
	return Net.GetFolder():WaitForChild(Config.REMOTES[name])
end

return Net
