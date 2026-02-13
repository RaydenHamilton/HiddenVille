local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local moneyTransferEvent = ReplicatedStorage:WaitForChild("SendMoneyEvent")
local uiEvent = ReplicatedStorage:WaitForChild("MoneyTransferUI")

local cooldownTime = 10
local cooldowns = {}

moneyTransferEvent.OnServerEvent:Connect(function(sender, recipientInput, amount, reason)
	if not amount or amount <= 0 then
		return
	end

	local senderStats = sender:FindFirstChild("leaderstats")
	local senderMoney = senderStats and senderStats:FindFirstChild("Money")
	if not senderMoney or senderMoney.Value < amount then
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

	local recipientStats = recipient:FindFirstChild("leaderstats")
	local recipientMoney = recipientStats and recipientStats:FindFirstChild("Money")
	if not recipientMoney then
		return
	end

	if recipientMoney.Value + amount < recipientMoney.Value or senderMoney.Value - amount > senderMoney.Value then
		return
	end
	if senderMoney.Value - amount < 0 then
		return
	end

	senderMoney.Value = senderMoney.Value - amount
	recipientMoney.Value = recipientMoney.Value + amount

	uiEvent:FireClient(recipient, "Sender: " .. sender.Name, "Amount: $" .. amount, reason, true)
	uiEvent:FireClient(sender, "Reciever: " .. recipient.Name, "Amount: $" .. amount, reason, false)

	cooldowns[sender] = os.time()
end)
