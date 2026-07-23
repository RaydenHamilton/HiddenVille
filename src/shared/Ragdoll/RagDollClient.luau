--!strict
--[[ SERVICES ]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

--[[ CONFIG ]]
local ragdollStates = {
	Enum.HumanoidStateType.Ragdoll,
	Enum.HumanoidStateType.FallingDown,
	Enum.HumanoidStateType.GettingUp,
}

--[[ Variable ]]

--[[ SERVICE ]]
local RagdollService = {}

--[[ FUNCTIONS ]]
local function clearAnimations(humanoid: Humanoid): ()
	local animator = humanoid:FindFirstChildOfClass("Animator")
	if animator then
		for _, track: AnimationTrack in ipairs(animator:GetPlayingAnimationTracks()) do
			track:Stop()
		end
	end
end

local function clear(character: Model, boolean: boolean): ()
	if character:GetAttribute("BoxJob") then
		return
	end
	local humanoid = character:FindFirstChild("Humanoid") :: Humanoid
	if not boolean then
		clearAnimations(character:WaitForChild("Humanoid") :: Humanoid)

		humanoid:UnequipTools()
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
	else
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, true)
	end
end

local function characterAdded(character: Model): ()
	local humanoid = character:WaitForChild("Humanoid") :: Humanoid
	local humanoidRootPart = character:WaitForChild("HumanoidRootPart") :: BasePart

	humanoid.BreakJointsOnDeath = false
	humanoidRootPart.CanCollide = false

	humanoid.StateChanged:Connect(function(old: Enum.HumanoidStateType, new: Enum.HumanoidStateType): ()
		if character:GetAttribute("BoxJob") then
			return
		end
		clear(character, not table.find(ragdollStates, new))
		humanoidRootPart.CanCollide = (new == Enum.HumanoidStateType.GettingUp or new == Enum.HumanoidStateType.Dead)
	end)
end

local function setState(boolean: boolean)
	local player = Players.LocalPlayer
	local character = player.Character
	if not character then
		return
	end

	local humanoid = character:FindFirstChild("Humanoid") :: Humanoid
	if not humanoid then
		return
	end
	humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp, not boolean)
	if boolean then
		humanoid:ChangeState(Enum.HumanoidStateType.Ragdoll)
	end
end

--[[ INIT ]]
function RagdollService.init(): ()
	local player = Players.LocalPlayer

	ReplicatedStorage.Remotes.Ragdall.OnClientEvent:Connect(setState)
	player.CharacterAdded:Connect(characterAdded)
	if player.Character then
		characterAdded(player.Character)
	end
end

--[[ RETURN ]]
return RagdollService
