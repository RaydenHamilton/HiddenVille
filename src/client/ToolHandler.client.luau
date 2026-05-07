local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ChainClient = require(ReplicatedStorage.Shared.Accessories.ChainClient)
local GunClient = require(ReplicatedStorage.Shared.GunHandler.GunClient)
local FistClient = require(ReplicatedStorage.Shared.Tools.FistClient)

ReplicatedStorage:WaitForChild("Remotes").SetupGun.OnClientEvent:Connect(function(tool: Tool, toolType: string)
	if toolType == "Gun" then
		GunClient.new(tool)
	elseif toolType == "Bag" then
		ChainClient.new(tool)
	elseif toolType == "Fist" then
		FistClient.new(tool)
	end
end)
