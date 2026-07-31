local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local PlayerDataServerService =
	require(ReplicatedStorage.Shared.PlayerDataHandler.SystemPackage.PlayerDataServerService)

local RewardData = DataStoreService:GetDataStore("HiddenvilleDailyRewardsRelease1")

local CanClaim = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("CanClaimDailyReward")
local GetAllDailyClaims = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("GetAllClaims")
local giveMoney = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("GiveMoney")
local chooseTool = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("ChooseTool")

local Playertimes = {}

local validHandguns = {
	["G20D"] = true,
	["G20"] = true,
	["G20Switch"] = true,
}

local validLongguns = {
	["Mac11"] = true,
	["Mini-Uzi"] = true,
	["Mac10"] = true,
}

local dailyRewards = {}

function dailyRewards.init()
	local function canClaimReward(player, rewardIndex)
		local success, data = pcall(function()
			return RewardData:GetAsync(player.UserId)
		end)

		local today = os.date("%Y%m%d")
		if not success or not data then
			return true
		end

		if data.day ~= today then
			return true
		end

		if data.claimed and data.claimed[rewardIndex] then
			local now = os.time()
			local tomorrow = os.time({
				year = os.date("*t").year,
				month = os.date("*t").month,
				day = os.date("*t").day + 1,
				hour = 0,
			})
			local remaining = tomorrow - now
			return false, remaining
		end

		return true
	end

	local function setRewardClaimed(player, rewardIndex)
		local success, data = pcall(function()
			return RewardData:GetAsync(player.UserId)
		end)

		local today = os.date("%Y%m%d")
		data = data or {}

		if data.day ~= today then
			data = { day = today, claimed = {} }
		end

		data.claimed[rewardIndex] = true

		pcall(function()
			RewardData:SetAsync(player.UserId, data)
		end)
	end

	local rewards = {
		[500] = { time = 120 },
		[2000] = { time = 300 },
		[2500] = { time = 600 },
		[3500] = { time = 1200 },
		[5000] = { time = 1500 },
		[10000] = { time = 2100 },
	}

	giveMoney.OnServerEvent:Connect(function(player, amount, rewardIndex)
		if typeof(amount) ~= "number" or amount <= 0 then
			return
		end

		if Playertimes[player.UserId].time >= rewards[amount].time and not Playertimes[player.UserId][amount] then
			Playertimes[player.UserId][amount] = true
		else
			print(player.Name .. " Stop Cheating")
			return
		end

		PlayerDataServerService.add(player, "Money", amount)
		setRewardClaimed(player, rewardIndex)
	end)

	chooseTool.OnServerEvent:Connect(function(player, toolName, rewardIndex)
		if typeof(toolName) ~= "string" then
			return
		end

		if not validHandguns[toolName] and not validLongguns[toolName] then
			warn(player.Name .. " attempted to get an invalid tool:", toolName)
			return
		end

		local tool = ServerStorage:FindFirstChild("Tools") and ServerStorage.Tools:FindFirstChild(toolName)
		if not tool or not tool:IsA("Tool") then
			warn("Tool '" .. toolName .. "' does not exist or is not a Tool.")
			return
		end

		setRewardClaimed(player, rewardIndex)

		local backpack = player:FindFirstChild("Backpack")
		if backpack and not backpack:FindFirstChild(toolName) then
			local toolClone = tool:Clone()
			toolClone.Parent = backpack
		end
	end)

	GetAllDailyClaims.OnServerInvoke = function(player)
		local success, data = pcall(function()
			return RewardData:GetAsync(player.UserId)
		end)

		local today = os.date("%Y%m%d")
		local claims = {}

		for i = 1, 8 do
			claims[i] = true
		end

		if not success or not data then
			return claims
		end

		if data.day ~= today then
			return claims
		end

		for index, claimed in pairs(data.claimed or {}) do
			if claimed then
				claims[tonumber(index)] = false
			end
		end

		return claims
	end

	CanClaim.OnServerInvoke = function(player, rewardIndex)
		return canClaimReward(player, rewardIndex)
	end

	Players.PlayerAdded:Connect(function(player)
		Playertimes[player.UserId] = {}
		Playertimes[player.UserId].time = 1

		while task.wait(1) and Playertimes[player.UserId] do
			Playertimes[player.UserId].time += 1
		end
	end)

	Players.PlayerRemoving:Connect(function(player)
		Playertimes[player.UserId] = nil
	end)
end
return dailyRewards
