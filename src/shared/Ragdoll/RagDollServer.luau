--!strict
--[[ SERVICES ]]
local Players = game:GetService("Players")

--[[ CONFIG ]]
local ragdollStates = {
	Enum.HumanoidStateType.Ragdoll,
	-- Enum.HumanoidStateType.FallingDown,
	-- Enum.HumanoidStateType.GettingUp,
}

--[[ SERVICE ]]
local RagdollService = {}

--[[ FUNCTIONS ]]

local function toggleJoints(character: Model, boolean: boolean)
	for _, joint in character:GetDescendants() do
		if joint:IsA("AnimationConstraint") and joint.Name ~= "Root" then
			joint.Enabled = boolean
		end
	end
end

local function characterAdded(character: Model)
	local humanoid = character:WaitForChild("Humanoid") :: Humanoid

	humanoid.StateChanged:Connect(function(old: Enum.HumanoidStateType, new: Enum.HumanoidStateType)
		if new == Enum.HumanoidStateType.Dead then
			return
		end
		toggleJoints(character, not table.find(ragdollStates, new))
		character:SetAttribute("Ragdoll", (new == Enum.HumanoidStateType.GettingUp) or nil)
	end)
end

local function playerAdded(player: Player)
	player.CharacterAdded:Connect(characterAdded)
	if player.Character then
		characterAdded(player.Character)
	end
end

--[[ INIT ]]
function RagdollService.init()
	Players.PlayerAdded:Connect(playerAdded)
	for _, player in Players:GetPlayers() do
		playerAdded(player)
	end
end

--[[ RETURN ]]
return RagdollService
