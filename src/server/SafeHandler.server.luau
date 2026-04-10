local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local server = require(ReplicatedStorage.BlinkEvents.server)

server.MoveSafeItem.On(function(player, From, itemName)
	if From == "Backpack" then
		local item = player.Backpack:FindFirstChild(itemName)
		if item and item:IsA("Tool") then
			item.Parent = player.Safe
		end
	elseif From == "Safe" then
		local item = player.Safe:FindFirstChild(itemName)
		if item and item:IsA("Tool") then
			item.Parent = player.Backpack
		end
	end
end)

Players.PlayerAdded:Connect(function(player)
	SafeFolder = Instance.new("Folder")
	SafeFolder.Name = "Safe"
	SafeFolder.Parent = player
end)
