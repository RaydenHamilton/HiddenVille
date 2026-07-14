local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ChainClient = require(ReplicatedStorage.Shared.Accessories.ChainClient)
local ClientFood = require(ReplicatedStorage.Shared.Foods.ClientFood)
local GunClient = require(ReplicatedStorage.Shared.GunHandler.GunClient)
local FistClient = require(ReplicatedStorage.Shared.Tools.FistClient)

ReplicatedStorage:WaitForChild("Remotes").SetupGun.OnClientEvent:Connect(function(tool: Tool, toolType: string)
	if toolType == "Gun" then
		GunClient.new(tool)
	elseif toolType == "Accessorie" then
		ChainClient.new(tool)
	elseif toolType == "Fist" then
		FistClient.new(tool)
	elseif toolType == "UseCleint" then
		ClientFood.new(tool)
	end
end)
