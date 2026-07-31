-- DailyRollServer (Script) - FIXED VERSION
const dailySpin = {}

--// Services
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local PlayerDataServerService =
	require(ReplicatedStorage.Shared.PlayerDataHandler.SystemPackage.PlayerDataServerService)

--// DataStore
local dailyRewardDS = DataStoreService:GetDataStore("HiddenvilleRewardsRelease")

--// RemoteEvent
local NotificationEvent = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Notification")

--// Reward configuration
local rewardsForStreak = {
	[1] = 100,
	[2] = 250,
	[3] = 500,
	[4] = 1000,
	[5] = 1750,
	[6] = 3000,
	[7] = 7500,
}

local allowedTools = {
	"G20",
	"G22DSwitch",
	"Mac11",
	"Draco",
	"Mac10",
}

local carNames = {
	"2018 Chrysler 300 SRT",
	"2021 Dodge Challanger Hellcat",
	"2022 Dodge Charger Hellcat",
}

local whitelist = {
	[""] = true,
	["legalGlokk"] = true,
	["LegalKeem"] = true,
}

--// Track active cooldown connections (for cleanup)
local ActiveCooldowns = {}

function dailySpin.init()
	--// Helper functions
	local function formatTime(seconds)
		local days = math.floor(seconds / 86400)
		local hours = math.floor((seconds % 86400) / 3600)
		local minutes = math.floor((seconds % 3600) / 60)
		local secs = seconds % 60

		if days > 0 then
			return string.format("%dD %dH %dM %dS", days, hours, minutes, secs)
		elseif hours > 0 then
			return string.format("%dH %dM %dS", hours, minutes, secs)
		elseif minutes > 0 then
			return string.format("%dM %dS", minutes, secs)
		else
			return string.format("%dS", secs)
		end
	end

	-- Safe catalog price lookup (Option 1)
	local function getCatalogCarPrice(carName: string): number
		local CarsCatalog = ReplicatedStorage:FindFirstChild("Cars")
		if not CarsCatalog then
			return 1000
		end

		local carData = CarsCatalog:FindFirstChild(carName)
		if not carData then
			return 1000
		end

		local priceObj = carData:FindFirstChild("Price", true)
		if priceObj and (priceObj:IsA("IntValue") or priceObj:IsA("NumberValue")) then
			return priceObj.Value
		end

		return 1000
	end

	-- Dynamic cooldown updater (FIXED - checks if player/GUI still exists)
	local function startCooldown(plr, cooldownText, cooldownTwo, claimBtn, lastClaimTime)
		-- Disconnect any existing cooldown for this player
		if ActiveCooldowns[plr.UserId] then
			ActiveCooldowns[plr.UserId]:Disconnect()
			ActiveCooldowns[plr.UserId] = nil
		end

		local function update()
			-- CHECK: Is player still in game?
			if not plr or not plr.Parent then
				return true -- Return true to disconnect
			end

			-- CHECK: Do GUI elements still exist?
			if not cooldownText or not cooldownText.Parent then
				return true
			end
			if not cooldownTwo or not cooldownTwo.Parent then
				return true
			end
			if not claimBtn or not claimBtn.Parent then
				return true
			end

			local remainingTime = 24 * 60 * 60 - (os.time() - lastClaimTime)
			if remainingTime > 0 then
				-- Wrap in pcall for extra safety
				pcall(function()
					cooldownText.Visible = true
					cooldownTwo.Visible = true
					cooldownText.Text = "Cooldown: " .. formatTime(remainingTime)
					cooldownTwo.Text = "Cooldown: " .. formatTime(remainingTime)
					local spinLabel = claimBtn:FindFirstChild("SpinLabel")
					if spinLabel then
						spinLabel.Text = "Cooldown"
					end
					claimBtn.TextColor3 = Color3.fromRGB(255, 0, 0)
				end)
				return false
			else
				pcall(function()
					cooldownText.Visible = false
					cooldownTwo.Visible = false
					local spinLabel = claimBtn:FindFirstChild("SpinLabel")
					if spinLabel then
						spinLabel.Text = "SPIN!"
					end
					claimBtn.TextColor3 = Color3.fromRGB(0, 255, 0)
				end)
				return true
			end
		end

		local connection
		connection = RunService.Heartbeat:Connect(function()
			if update() then
				connection:Disconnect()
				if ActiveCooldowns[plr.UserId] == connection then
					ActiveCooldowns[plr.UserId] = nil
				end
			end
		end)

		-- Store connection for cleanup
		ActiveCooldowns[plr.UserId] = connection
	end

	-- Rolling effect & reward handling
	local function rollReward(plr, rewardLabel, claimBtn, rollSound)
		-- Safety check
		if not plr or not plr.Parent then
			return "Cancelled"
		end

		pcall(function()
			rollSound:Play()
		end)

		-- Show random rolling animation
		local rewardTypes = { "Money", "Tool", "Level", "Car" }
		local rollDuration = 9
		local startTime = tick()
		while tick() - startTime < rollDuration do
			-- Check if player left during roll
			if not plr or not plr.Parent then
				return "Cancelled"
			end
			if not rewardLabel or not rewardLabel.Parent then
				return "Cancelled"
			end

			pcall(function()
				rewardLabel.Text = rewardTypes[math.random(1, #rewardTypes)]
			end)
			task.wait(0.1)
		end

		-- Check again before rewards
		if not plr or not plr.Parent then
			return "Cancelled"
		end

		-- Determine final reward
		local rewardChances = { Money = 48, Level = 32, Tool = 16, Car = 4 }
		local function chance(min, max)
			return math.random() * (max - min) + min
		end

		local function rewardRng()
			local total = 0
			for _, w in pairs(rewardChances) do
				total += w
			end
			local roll = chance(1, total)
			local cum = 0
			for r, w in pairs(rewardChances) do
				cum += w
				if roll <= cum then
					return r
				end
			end
		end

		local chosenReward = rewardRng()
		local finalReward = ""

		local toolsFolder = ServerStorage:FindFirstChild("Tools")
		local carsFolder = ServerStorage:FindFirstChild("Cars")

		if chosenReward == "Money" then
			local base = math.random(500, 10000)
			finalReward = "+$" .. base
			PlayerDataServerService.add(plr, "Money", base)
		elseif chosenReward == "Tool" then
			if toolsFolder then
				local toolList = {}
				for _, tName in ipairs(allowedTools) do
					local tool = toolsFolder:FindFirstChild(tName)
					if tool then
						table.insert(toolList, tool)
					end
				end
				if #toolList > 0 and plr:FindFirstChild("Backpack") then
					local chosenTool = toolList[math.random(1, #toolList)]:Clone()
					chosenTool.Parent = plr.Backpack
					finalReward = chosenTool.Name
				else
					finalReward = "No tools available"
				end
			else
				finalReward = "No tools available"
			end
		elseif chosenReward == "Level" then
			local increase = math.random(3, 20)
			PlayerDataServerService.add(plr, "Money", increase)

			finalReward = "+" .. increase .. " Level"
		elseif chosenReward == "Car" then
			if carsFolder then
				local carList = {}
				for _, cName in ipairs(carNames) do
					if carsFolder:FindFirstChild(cName) then
						table.insert(carList, cName)
					end
				end

				if #carList > 0 then
					local chosenCar = carList[math.random(1, #carList)]
					local owns = _G.checkCarOwnership and _G.checkCarOwnership(plr, chosenCar) or false

					local price = getCatalogCarPrice(chosenCar)

					if not owns then
						if _G.hookCarGive then
							_G.hookCarGive(plr, chosenCar)
							finalReward = "Car: " .. chosenCar
						else
							warn("hookCarGive is missing; cannot grant car:", chosenCar)
							finalReward = "Car grant failed"
						end
					else
						pcall(function()
							NotificationEvent:FireClient(
								plr,
								"You already own " .. chosenCar .. ", received half money.",
								"Error"
							)
						end)
						PlayerDataServerService.add(plr, "Money", price / 2)
						finalReward = chosenCar .. ": $" .. (price / 2)
					end
				else
					finalReward = "No cars available"
				end
			else
				finalReward = "No cars available"
			end
		end

		-- Update GUI (with safety checks)
		pcall(function()
			if rewardLabel and rewardLabel.Parent then
				rewardLabel.Text = finalReward
			end
			if claimBtn and claimBtn.Parent then
				local spinLabel = claimBtn:FindFirstChild("SpinLabel")
				if spinLabel then
					spinLabel.Text = "Claim"
				end
				claimBtn.TextColor3 = Color3.fromRGB(0, 255, 0)
			end
		end)

		return finalReward
	end

	--// Player added
	Players.PlayerAdded:Connect(function(plr)
		local _, dailyRewardInfo = pcall(function()
			return dailyRewardDS:GetAsync(plr.UserId .. "-DailyRewards")
		end)

		if type(dailyRewardInfo) ~= "table" then
			dailyRewardInfo = { 0, nil, 1 }
		end

		local lastOnline = dailyRewardInfo[2]
		local streak = dailyRewardInfo[3] or 1
		local streakBonus = rewardsForStreak[streak] or 100
		local canClaim = false
		local isSpinning = false

		-- Wait for GUI with timeout
		local mainScreen = plr:WaitForChild("PlayerGui", 10)
		if not mainScreen then
			return
		end
		mainScreen = mainScreen:WaitForChild("MainScreen", 10)
		if not mainScreen then
			return
		end

		local dailyRewardGui = mainScreen:FindFirstChild("DailySpin")
		if not dailyRewardGui then
			return
		end

		local mainGui = dailyRewardGui:FindFirstChild("Holder")
		if not mainGui then
			return
		end

		local claimBtn = mainGui:FindFirstChild("Spin")
		if not claimBtn then
			return
		end

		local spinLabel = claimBtn:FindFirstChild("SpinLabel")
		local rewardLabel = mainGui:FindFirstChild("Reward")
		local cooldownText = dailyRewardGui:FindFirstChild("Cooldown")

		-- Find cooldownTwo safely
		local gameplayFrame = mainScreen:FindFirstChild("GameplayFrame")
		local cooldownTwo = gameplayFrame and gameplayFrame:FindFirstChild("SideButtons")
		cooldownTwo = cooldownTwo and cooldownTwo:FindFirstChild("DailySpin")
		cooldownTwo = cooldownTwo and cooldownTwo:FindFirstChild("Cooldown2")

		local rollSound = mainGui:FindFirstChild("RollSound")

		-- streakBonus currently unused, keeping your variable to avoid behavior change
		_ = streakBonus

		if not lastOnline or os.time() - lastOnline >= 24 * 60 * 60 or whitelist[plr.Name] then
			canClaim = true
		end

		if lastOnline and not canClaim then
			if cooldownText and cooldownTwo and claimBtn then
				startCooldown(plr, cooldownText, cooldownTwo, claimBtn, lastOnline)
			end
		end

		--// Claim button
		if claimBtn then
			claimBtn.Activated:Connect(function()
				if isSpinning then
					return
				end
				if not plr or not plr.Parent then
					return
				end
				isSpinning = true

				local levelVal = plr:FindFirstChild("hiddenstats") and plr.hiddenstats:FindFirstChild("Level")
				if levelVal and levelVal.Value < 10 then
					pcall(function()
						NotificationEvent:FireClient(plr, "You must be level 10+ to spin.", "Error")
					end)
					isSpinning = false
					return
				end

				if canClaim then
					pcall(function()
						if spinLabel then
							spinLabel.Text = "Rolling..."
						end
						claimBtn.TextColor3 = Color3.fromRGB(255, 255, 0)
					end)

					rollReward(plr, rewardLabel, claimBtn, rollSound)

					-- Check if player still exists
					if not plr or not plr.Parent then
						isSpinning = false
						return
					end

					-- Update streak
					streak = streak + 1
					if streak > 7 then
						streak = 1
					end

					if not whitelist[plr.Name] then
						local ok, err = pcall(function()
							dailyRewardDS:SetAsync(
								plr.UserId .. "-DailyRewards",
								{ levelVal and levelVal.Value or 0, os.time(), streak }
							)
						end)
						if not ok then
							warn("Failed saving: " .. tostring(err))
						end

						canClaim = false
						if cooldownText and cooldownTwo and claimBtn then
							startCooldown(plr, cooldownText, cooldownTwo, claimBtn, os.time())
						end
					else
						pcall(function()
							if spinLabel then
								spinLabel.Text = "SPIN!"
							end
							claimBtn.TextColor3 = Color3.fromRGB(0, 255, 0)
						end)
					end
				else
					print("Cooldown in progress")
				end

				isSpinning = false
			end)
		end
	end)

	--// Cleanup when player leaves
	Players.PlayerRemoving:Connect(function(plr)
		-- Disconnect their cooldown loop
		if ActiveCooldowns[plr.UserId] then
			ActiveCooldowns[plr.UserId]:Disconnect()
			ActiveCooldowns[plr.UserId] = nil
		end
	end)
end
return dailySpin
