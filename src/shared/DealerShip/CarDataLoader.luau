local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PlayerDataServerService =
	require(ReplicatedStorage.Shared.PlayerDataHandler.SystemPackage.PlayerDataServerService)
local CarDataLoader = {}

function CarDataLoader:LoadPlayerCarAndStats(player)
	local money = PlayerDataServerService.get(player, "Money")

	local car = workspace:WaitForChild("CivCars"):FindFirstChild(player.Name .. "'s Car")
	if not car then
		warn("[CarDataLoader] Car not found for player: " .. player.Name)
		return nil, nil
	end

	return car, money
end

return CarDataLoader
