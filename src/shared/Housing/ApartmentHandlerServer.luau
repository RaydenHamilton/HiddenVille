local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local PlayerDataServerService =
	require(ReplicatedStorage.Shared.PlayerDataHandler.SystemPackage.PlayerDataServerService)

local doorStates = {}
local doorsOwned = {}

local function setupDoor(door)
	local doorPart = door:WaitForChild("DoorPart")
	local doorPrompt = doorPart:WaitForChild("InteractPrompt")
	local knockSound = doorPart:WaitForChild("KnockSound")
	local lockSound = doorPart:WaitForChild("LockSound")
	local hinge = door:WaitForChild("DoorFrame").Hinge
	local basePrompt = door:WaitForChild("Base").ProximityPrompt
	local doorSound = door:WaitForChild("Base").Sound
	local displayLabel = door:WaitForChild("OwnerPart").SurfaceGui.TextLabel
	local signDecal = door:WaitForChild("PurchasePart").Decal
	local buyPrompt = door:WaitForChild("PurchasePart").Purchase

	local knockAnimation = ReplicatedStorage:WaitForChild("KnockAnimation")
	local notification = ReplicatedStorage.Remotes.Notification

	local ownerValue = door:WaitForChild("Owner")
	local doorlocked = door:WaitForChild("Locked")
	local priceValue = door:WaitForChild("Price")

	local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out)
	local goalOpen = { CFrame = hinge.CFrame * CFrame.Angles(0, math.rad(90), 0) }
	local goalClose = { CFrame = hinge.CFrame * CFrame.Angles(0, 0, 0) }
	local tweenOpen = TweenService:Create(hinge, tweenInfo, goalOpen)
	local tweenClose = TweenService:Create(hinge, tweenInfo, goalClose)

	doorsOwned[door] = nil

	buyPrompt.Triggered:Connect(function(player)
		local Money = PlayerDataServerService.get(player, "Money")
		if doorsOwned[player] then
			notification:FireClient(player, "You already own a house", "Error")
			return
		end

		if Money then
			if Money >= priceValue then
				PlayerDataServerService.add(player, "Money", -priceValue)
				ownerValue = player
				displayLabel.Text = player.Name
				signDecal.Transparency = 1
				buyPrompt.Enabled = false
				doorsOwned[player] = door
			end
		end
	end)

	doorPrompt.Triggered:Connect(function(player)
		if ownerValue == player then
			doorlocked.Value = not doorlocked.Value
			doorPrompt.ActionText = doorlocked.Value and "Unlock" or "Lock"
			lockSound:Play()
		end
	end)

	basePrompt.Triggered:Connect(function(player)
		local isOwner = ownerValue.Value == player
		local isOwned = ownerValue.Value ~= nil

		local character = player.Character
		local humanoid = character:WaitForChild("Humanoid")

		local knockTrack = humanoid:LoadAnimation(knockAnimation)

		if not isOwned then
			knockSound:Play()
			knockTrack:Play()
		elseif doorlocked.Value then
			if isOwner then
				if doorStates[door] then
					tweenClose:Play()
					doorPrompt.Enabled = true
				else
					tweenOpen:Play()
					doorPrompt.Enabled = false
				end
				doorStates[door] = not doorStates[door]
				doorSound:Play()
			else
				knockSound:Play()
				knockTrack:Play()
			end
		else
			if doorStates[door] then
				tweenClose:Play()
				doorPrompt.Enabled = true
			else
				tweenOpen:Play()
				doorPrompt.Enabled = false
			end
			doorStates[door] = not doorStates[door]
			doorSound:Play()
		end
	end)

	ownerValue:GetPropertyChangedSignal("Value"):Connect(function()
		if not ownerValue.Value then
			displayLabel.Text = ""
			signDecal.Transparency = 0
			buyPrompt.Enabled = true
			doorlocked.Value = false

			for plr, ownedDoor in pairs(doorsOwned) do
				if ownedDoor == door then
					doorsOwned[plr] = nil
				end
			end
		end
	end)
end

local apartmentHandler = {}

local function PlayerRemoving(player)
	for _, door in pairs(Workspace.OwnedDoors:GetChildren()) do
		local ownerValue = door:FindFirstChild("Owner")
		if ownerValue and ownerValue.Value == player then
			ownerValue.Value = nil
			doorStates[door] = nil
		end
	end
	doorsOwned[player] = nil
end

function apartmentHandler.init()
	for _, door in pairs(Workspace.OwnedDoors:GetChildren()) do
		task.spawn(function()
			pcall(function()
				setupDoor(door)
			end)
		end)
	end

	Players.PlayerRemoving:Connect(PlayerRemoving)
end

return apartmentHandler
