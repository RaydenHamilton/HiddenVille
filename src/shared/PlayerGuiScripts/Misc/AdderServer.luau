local adderServer = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PlayerDataServerService =
	require(ReplicatedStorage.Shared.PlayerDataHandler.SystemPackage.PlayerDataServerService)

local PlayerCooldowns = {}

local notification = ReplicatedStorage.Remotes:WaitForChild("Notification")

function adderServer.init()
	local function formatMoney(amount)
		local isNegative = amount < 0
		amount = math.abs(amount)

		if amount >= 1e12 then
			return (isNegative and "-" or "") .. string.format("%.2fT", amount / 1e12)
		elseif amount >= 1e9 then
			return (isNegative and "-" or "") .. string.format("%.2fB", amount / 1e9)
		elseif amount >= 1e6 then
			return (isNegative and "-" or "") .. string.format("%.2fM", amount / 1e6)
		else
			local str, formatted, len = tostring(amount), "", #tostring(amount)
			for i = 1, len do
				formatted = str:sub(len - i + 1, len - i + 1) .. formatted
				if i % 3 == 0 and i < len then
					formatted = "," .. formatted
				end
			end
			return (isNegative and "-" or "") .. formatted
		end
	end

	local function createAdder(player, amount)
		if PlayerCooldowns[player] then
			return
		end
		PlayerCooldowns[player] = true
		if amount > 0 then
			notification:FireClient(player, `${formatMoney(amount)}`, "Money")
		else
			notification:FireClient(player, `${formatMoney(amount)}`, "Buy")
		end

		task.delay(0.35, function()
			PlayerCooldowns[player] = nil
		end)
	end

	local last = {}
	local function monitorLeaderstats(player)
		local function connectStat(stat)
			local diff = stat - last[player]
			local ignoreThreshold = math.max(1000000, last[player] * 0.75)
			last[player] = stat
			if math.abs(diff) > ignoreThreshold then
				return
			end
			createAdder(player, diff)
		end

		last[player] = PlayerDataServerService.get(player, "Money")
		PlayerDataServerService.MoneySignal:Connect(connectStat)
	end

	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function()
			task.wait(1)
			monitorLeaderstats(player)
		end)
	end)

	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(function()
			monitorLeaderstats(player)
		end)
	end
end
return adderServer
