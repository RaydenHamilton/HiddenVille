local cashServer = {}
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PlayerDataServerService =
	require(ReplicatedStorage.Shared.PlayerDataHandler.SystemPackage.PlayerDataServerService)

-- Function to process purchase receipts

function cashServer.init()
	function processReceipt(receiptInfo)
		local player = game:GetService("Players"):GetPlayerByUserId(receiptInfo.PlayerId)

		-- Check if the player exists
		if not player then
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end

		-- Handle each product purchase
		if receiptInfo.ProductId == 1884586825 then
			PlayerDataServerService.add(player, "Money", 1000)
		elseif receiptInfo.ProductId == 1884587384 then
			PlayerDataServerService.add(player, "Money", 2000)
		elseif receiptInfo.ProductId == 1884587697 then
			PlayerDataServerService.add(player, "Money", 5000)
		elseif receiptInfo.ProductId == 1884587699 then
			PlayerDataServerService.add(player, "Money", 10000)
		elseif receiptInfo.ProductId == 1911230204 then
			local item = game.ServerStorage.InstaSpawn:FindFirstChild("Mac11")
			if item then
				item:Clone().Parent = player.Backpack
			end
		elseif receiptInfo.ProductId == 1911230903 then
			local item = game.ServerStorage.InstaSpawn:FindFirstChild("Draco")
			if item then
				item:Clone().Parent = player.Backpack
			end
		elseif receiptInfo.ProductId == 1911232975 then
			local item = game.ServerStorage.InstaSpawn:FindFirstChild("G22DSwitch")
			if item then
				item:Clone().Parent = player.Backpack
			end
		elseif receiptInfo.ProductId == 1911230616 then
			local item = game.ServerStorage.InstaSpawn:FindFirstChild("G17D")
			if item then
				item:Clone().Parent = player.Backpack
			end
		elseif receiptInfo.ProductId == 1911231148 then
			local item = game.ServerStorage.InstaSpawn:FindFirstChild("Level2 Vest")
			if item then
				item:Clone().Parent = player.Backpack
			end
		elseif receiptInfo.ProductId == 1911231672 then
			local item = game.ServerStorage.InstaSpawn:FindFirstChild("M4Carbines")
			if item then
				item:Clone().Parent = player.Backpack
			end
		end

		-- Return the decision to grant the purchase
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end

	-- Set the ProcessReceipt callback
	MarketplaceService.ProcessReceipt = processReceipt
end

return cashServer
