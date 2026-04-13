local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local server = require(ReplicatedStorage.BlinkEvents.server)
local PlayerDataServerService =
	require(ReplicatedStorage.Shared.PlayerDataHandler.SystemPackage.PlayerDataServerService)

server.MoveSafeItem.On(function(player, From, itemName)
	if From == "Backpack" then
		local item = player.Backpack:FindFirstChild(itemName)
		if item and item:IsA("Tool") then
			item.Parent = player.Safe
			PlayerDataServerService.get(player, "Safe")
		end
	elseif From == "Safe" then
		local item = player.Safe:FindFirstChild(itemName)
		if item and item:IsA("Tool") then
			item.Parent = player.Backpack
			PlayerDataServerService.get(player, "Safe")
		end
	end
end)

-- TODO load data and save data when player leaves and joins back
Players.PlayerAdded:Connect(function(player)
	local SafeFolder = Instance.new("Folder")
	SafeFolder.Name = "Safe"
	SafeFolder.Parent = player

	local safeData = PlayerDataServerService.get(player, "Safe")
end)
