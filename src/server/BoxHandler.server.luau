local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local Workspace = game:GetService("Workspace")
local Main = Workspace:WaitForChild("BoxJob 1")

local GrabBoxPrompt = Main:FindFirstChild("GrabBox").ProximityPrompt
local PlaceBoxPrompt = Main:FindFirstChild("PlaceBox").ProximityPrompt

local Box = ServerStorage:WaitForChild("Tools").Box
local BoxAnimation = ReplicatedStorage:FindFirstChild("BoxAnimation")

local ToggleBackpackUI = ReplicatedStorage:WaitForChild("ToggleBackpackUI")
local NotificationEvent = ReplicatedStorage:FindFirstChild("NotificationEvent")

local ProximityDistance = 150
local GamepassID = 1331110346

local PlayerConnections = {}
local PlayerAnimations = {}

local function Randomize(min, max)
	return math.random(min, max)
end

local function IsInRange(player)
	local character = player.Character or player.CharacterAdded:Wait()
	local rootPart = character and character:FindFirstChild("HumanoidRootPart")
	if not rootPart then
		return false
	end

	local grabDistance = (rootPart.Position - Main:FindFirstChild("GrabBox").Position).Magnitude
	local placeDistance = (rootPart.Position - Main:FindFirstChild("PlaceBox").Position).Magnitude

	return grabDistance <= ProximityDistance or placeDistance <= ProximityDistance
end

local function AttachBoxToHand(player)
	local character = player.Character
	if not character or character:FindFirstChild("Box") then
		return
	end

	local humanoid = character:FindFirstChild("Humanoid")
	if not humanoid then
		return
	end

	local rightHand = character:FindFirstChild("RightHand") or character:FindFirstChild("Right Arm")
	if not rightHand then
		return
	end

	local backpack = player:FindFirstChildOfClass("Backpack")
	if backpack then
		local existingTool = backpack:FindFirstChild("Box")
		if not existingTool then
			local toolClone = Box:Clone()
			toolClone.Parent = backpack

			if BoxAnimation then
				if not PlayerAnimations[player.Name] then
					local animTrack = humanoid:LoadAnimation(BoxAnimation)
					animTrack.Priority = Enum.AnimationPriority.Action
					PlayerAnimations[player.Name] = animTrack
				end

				local animTrack = PlayerAnimations[player.Name]
				animTrack:Play()

				humanoid:EquipTool(toolClone)
			end
		end
	end

	ToggleBackpackUI:FireClient(player, false)
end

local function RemoveBoxFromHand(player)
	local character = player.Character
	if not character then
		return
	end

	local box = character:FindFirstChild("Box")
	if box then
		local animTrack = PlayerAnimations[player.Name]
		if animTrack then
			local animator = character:FindFirstChild("Humanoid"):FindFirstChild("Animator")
			if animator then
				for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
					if track.Animation and track.Animation.AnimationId == BoxAnimation.AnimationId then
						track:Stop()
					end
				end
			end

			animTrack:Stop()
			PlayerAnimations[player.Name] = nil
		end

		box:Destroy()
	end

	ToggleBackpackUI:FireClient(player, true)
end

GrabBoxPrompt.Triggered:Connect(function(player)
	if player:FindFirstChild("CombatLogged") then
		if NotificationEvent then
			NotificationEvent:FireClient(player, "You cannot start the box job while in combat.")
		end
		return
	end

	if PlayerConnections[player.Name] then
		return
	end
	local box = player.Character:FindFirstChild("Box")
	if box then
		return
	end

	AttachBoxToHand(player)

	GrabBoxPrompt.GrabSound:Play()

	PlayerConnections[player.Name] = RunService.Heartbeat:Connect(function()
		if not IsInRange(player) then
			RemoveBoxFromHand(player)
			PlayerConnections[player.Name]:Disconnect()
			PlayerConnections[player.Name] = nil
		end
	end)
end)

PlaceBoxPrompt.Triggered:Connect(function(player)
	local character = player.Character
	if not character then
		return
	end

	local box = character:FindFirstChild("Box")
	if not box then
		return
	end

	if PlayerConnections[player.Name] then
		PlayerConnections[player.Name]:Disconnect()
		PlayerConnections[player.Name] = nil
	end

	local leaderstats = player:FindFirstChild("leaderstats")
	local hiddenstats = player:FindFirstChild("hiddenstats")

	local reward = Randomize(100, 250)

	local ownsMoneyGamepass = false
	local success1, result1 = pcall(function()
		return MarketplaceService:UserOwnsGamePassAsync(player.UserId, GamepassID)
	end)
	if success1 and result1 then
		ownsMoneyGamepass = true
	end

	if ownsMoneyGamepass then
		reward *= 2
	end

	if leaderstats and leaderstats:FindFirstChild("Money") then
		leaderstats.Money.Value += reward
	end

	if hiddenstats and hiddenstats:FindFirstChild("XP") then
		hiddenstats.XP.Value += 1250
	end

	PlaceBoxPrompt.PlaceSound:Play()
	RemoveBoxFromHand(player)
end)

Players.PlayerRemoving:Connect(function(player)
	if PlayerConnections[player.Name] then
		PlayerConnections[player.Name]:Disconnect()
		PlayerConnections[player.Name] = nil
	end
end)
