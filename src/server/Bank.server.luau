local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local ResetTime = 600

local pp = Workspace.BankHeist.bankdoor.partc4.ProximityPrompt
local partC4 = pp.Parent
local mainDoor = partC4.Parent.main
local c4Part = mainDoor:WaitForChild("placec4")

local goldFolder = game.Workspace.BankHeist:WaitForChild("GoldFolder")
local replicatedGold = ReplicatedStorage:WaitForChild("AllGold")

local function onGoldCollected(promptObject, player)
	print("ProximityPrompt triggered by", player)

	if not player:FindFirstChild("canrob") or not player.canrob.Value then return end

	local character = player.Character
	if not character then return end

	local duffel = character:FindFirstChild("DuffelBag")
	if not duffel then return end

	local maxCapacity = duffel:FindFirstChild("gamepass") and duffel.gamepass.Value and 10 or 5
	local currentGold = duffel:FindFirstChild("goldvalue")

	if not (duffel:FindFirstChild("goldvalue") and duffel:FindFirstChild("gamepass")) then
		warn("DuffelBag missing required children!")
		return
	end

	if currentGold and currentGold.Value < maxCapacity then
		currentGold.Value += 1

		local duffelType = duffel:FindFirstChild("Type")
		if duffelType then
			duffel.Type.Value = "Bank"
		end

		local part = promptObject.Parent
		local model = part and part.Parent
		if model and model:IsA("Model") then
			model:Destroy()
		end
	end
end

local function connectGoldPrompts()
	for _, gold in ipairs(goldFolder:GetDescendants()) do
		if gold:IsA("ProximityPrompt") then
			gold.Triggered:Connect(function(player)
				onGoldCollected(gold, player)
			end)
		end
	end
end

local function resetGold()
	for _, g in ipairs(goldFolder:GetChildren()) do
		g:Destroy()
	end

	for _, g in ipairs(replicatedGold:GetChildren()) do
		local clone = g:Clone()
		clone.Parent = goldFolder
	end

	connectGoldPrompts()
end

pp.Triggered:Connect(function(plr)

	-- ❌ REMOVED MASK REQUIREMENT
	-- No more balaclava check

	local c4 = plr.Backpack:FindFirstChild("C4") or plr.Character:FindFirstChild("C4")
	if not c4 then return end

	pp.Enabled = false
	c4:Destroy()
	partC4.Transparency = 0

	c4Part.beep:Play()
	task.wait(4)
	c4Part.beep:Stop()
	c4Part.explosion:Play()

	local explosion = Instance.new("Explosion")
	explosion.BlastRadius = 0.05
	explosion.Position = partC4.Position
	explosion.Parent = workspace

	partC4.Transparency = 1
	mainDoor.Parent = game.ReplicatedStorage

	ReplicatedStorage.NotificationEvent:FireAllClients("The bank has been robbed.")

	for _, player in ipairs(game.Players:GetPlayers()) do
		if player == plr then continue end

		local canrob = player:FindFirstChild("canrob")
		local playerGui = player:FindFirstChild("PlayerGui")
		if canrob and playerGui then
			canrob.Value = true
			local bankAlarm = playerGui:FindFirstChild("MainScreen") and playerGui.MainScreen:FindFirstChild("BankAlarm")
			if bankAlarm then
				bankAlarm:Play()
			end
		end
	end

	task.wait(ResetTime)

	mainDoor.Parent = partC4.Parent
	pp.Enabled = true

	resetGold()

	local removePlayersZone = mainDoor.Parent:FindFirstChild("RemovePlayers")
	if removePlayersZone then
		for _, part in ipairs(removePlayersZone:GetTouchingParts()) do
			local char = part.Parent
			local player = game.Players:GetPlayerFromCharacter(char)
			if player and char and char:FindFirstChild("HumanoidRootPart") then
				char.HumanoidRootPart.CFrame = mainDoor.PlayerTeleport.CFrame
			end
		end
	end

	ReplicatedStorage.NotificationEvent:FireAllClients("The bank has been reset.")
end)

resetGold()
