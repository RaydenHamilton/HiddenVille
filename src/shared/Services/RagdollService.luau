--!strict
--[[ SERVICES ]]--
local Players = game:GetService("Players")

--[[ CONFIG ]]--
local ragdollStates = {
	Enum.HumanoidStateType.Ragdoll,
	Enum.HumanoidStateType.FallingDown,
	Enum.HumanoidStateType.GettingUp,
	Enum.HumanoidStateType.Dead,
}

--[[ SERVICE ]]--
local RagdollService = {}

--[[ FUNCTIONS ]]--
local function clearAnimations(humanoid: Humanoid): ()
	local animator = humanoid:FindFirstChildOfClass("Animator")
	if animator then
		for _, track: AnimationTrack in ipairs(animator:GetPlayingAnimationTracks()) do
			track:Stop()
		end
	end
end

local function toggleJoints(character: Model, boolean: boolean): ()
	if not boolean then clearAnimations(character:WaitForChild("Humanoid") :: Humanoid) end
	for _, joint in character:GetDescendants() do
		if joint:IsA("AnimationConstraint") and joint.Name ~= "Root" then
			joint.Enabled = boolean
		end
	end
end

local function characterAdded(character: Model): ()
	local humanoid = character:WaitForChild("Humanoid") :: Humanoid
	local humanoidRootPart = character:WaitForChild("HumanoidRootPart") :: BasePart

	humanoid.BreakJointsOnDeath = false
	humanoidRootPart.CanCollide = false

	humanoid.StateChanged:Connect(function(old: Enum.HumanoidStateType, new: Enum.HumanoidStateType): ()
		toggleJoints(character, not table.find(ragdollStates, new))
		humanoidRootPart.CanCollide = (new == Enum.HumanoidStateType.GettingUp)
	end)
end

--[[ INIT ]]--
function RagdollService.clientInit(): ()
	local player = Players.LocalPlayer
	player.CharacterAdded:Connect(characterAdded)
	if player.Character then characterAdded(player.Character) end
end

--[[ RETURN ]]--
return RagdollService