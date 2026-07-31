local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PlayerDataServerService =
	require(ReplicatedStorage.Shared.PlayerDataHandler.SystemPackage.PlayerDataServerService)

local phoneServer = {}

function phoneServer.init()
	local moneyTransferEvent = ReplicatedStorage.Remotes:WaitForChild("SendMoneyEvent")
	local uiEvent = ReplicatedStorage.Remotes:WaitForChild("MoneyTransferUI")

	local cooldownTime = 10
	local cooldowns = {}

	local function isValidMoney(amount)
		return typeof(amount) == "number"
			and amount == amount -- not NaN
			and amount > 0
			and amount < 1e6 -- optional cap
	end

	moneyTransferEvent.OnServerEvent:Connect(function(sender, recipientInput, amount, reason)
		if not amount or amount <= 0 then
			return
		end
		local senderMoney = PlayerDataServerService.get(sender, "Money")
		if senderMoney < amount then
			return
		end

		if not isValidMoney(amount) then
			return
		end

		if cooldowns[sender] and os.time() - cooldowns[sender] < cooldownTime then
			return
		end

		local input = string.lower(recipientInput)
		local recipient = nil

		for _, player in pairs(Players:GetPlayers()) do
			local name = string.lower(player.Name)
			local display = string.lower(player.DisplayName)

			if name == input or display == input then
				recipient = player
				break
			end
		end

		if not recipient or recipient == sender then
			return
		end

		const recipientMoney = PlayerDataServerService.get(recipient, "Money")
		if recipientMoney + amount < recipientMoney or senderMoney - amount > senderMoney then
			return
		end

		if senderMoney - amount < 0 then
			return
		end

		PlayerDataServerService.add(sender, "Money", -amount)
		PlayerDataServerService.add(recipient, "Money", amount)

		uiEvent:FireClient(recipient, "Sender: " .. sender.Name, "Amount: $" .. amount, reason, true)
		uiEvent:FireClient(sender, "Reciever: " .. recipient.Name, "Amount: $" .. amount, reason, false)

		cooldowns[sender] = os.time()
	end)
end
return phoneServer
