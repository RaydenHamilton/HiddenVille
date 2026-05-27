local ReplicatedStorage = game:GetService("ReplicatedStorage")
local NotificationModule = require(ReplicatedStorage.Modules.NotificationModule)

local remote = ReplicatedStorage.Remotes.Notication

local function notifcation(message, level)
	NotificationModule[level](message, 3)
end

remote.OnClientEvent:Connect(notifcation)
