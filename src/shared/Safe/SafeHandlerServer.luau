local safeServer = {}

function safeServer.init()
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
				local safeData = PlayerDataServerService.get(player, "Safe")
				table.insert(safeData, itemName)
				PlayerDataServerService.set(player, "Safe", safeData)
			end
		elseif From == "Safe" then
			local item = player.Safe:FindFirstChild(itemName)
			if item and item:IsA("Tool") then
				item.Parent = player.Backpack
				local safeData = PlayerDataServerService.get(player, "Safe")
				table.remove(safeData, table.find(safeData, itemName))
				PlayerDataServerService.set(player, "Safe", safeData)
			end
		end
	end)

	-- TODO load data and save data when player leaves and joins back
	Players.PlayerAdded:Connect(function(player)
		local SafeFolder = Instance.new("Folder")
		SafeFolder.Name = "Safe"
		SafeFolder.Parent = player

		local safeData = PlayerDataServerService.get(player, "Safe")
		if safeData then
			for _, itemName in ipairs(safeData) do
				local item = ServerStorage["Safe Tools"]:FindFirstChild(itemName)
				if item and item:IsA("Tool") then
					local clone = item:Clone()
					clone.Parent = SafeFolder
				end
			end
		end
	end)
end
return safeServer
