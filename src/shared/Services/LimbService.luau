--!strict
--[[ SERVICES ]]--
local Players = game:GetService("Players")

--[[ CONFIG ]]--
type Control = { Root: string, Effector: string }

local controllers = {
	Head = { Root = "Head", Effector = "Head" },
	
	LeftHand = { Root = "LeftUpperArm", Effector = "LeftHand" },
	RightHand = { Root = "RightUpperArm", Effector = "RightHand" },
	
	LeftFoot = { Root = "LeftUpperLeg", Effector = "LeftFoot" },
	RightFoot = { Root = "RightUpperLeg", Effector = "RightFoot" },
}

controllers = controllers :: typeof(controllers)

--[[ SERVICE ]]--
local LimbService = {}

--[[ FUNCTIONS ]]--
local function injectControls(character: Model)
	local humanoid = character:WaitForChild("Humanoid") :: Humanoid
	
	for name: string, control: Control in pairs(controllers) do
		local ik = Instance.new("IKControl")
		ik.Name = name
		ik.Type = Enum.IKControlType.LookAt
		ik.ChainRoot = character:WaitForChild(control.Root)
		ik.EndEffector = character:WaitForChild(control.Effector)
		ik.Enabled = true
		ik.SmoothTime = 0.05
		ik.Parent = humanoid
	end
end

local function playerAdded(player: Player)
	player.CharacterAdded:Connect(injectControls)
	if player.Character then injectControls(player.Character) end
end

--[[ INITS ]]--
function LimbService.serverInit(): ()
	Players.PlayerAdded:Connect(playerAdded)

	for _, player in Players:GetPlayers() do
		playerAdded(player)
	end
end

function LimbService.clientInit(): ()
	--(Players.LocalPlayer :: Player).CharacterAdded:Connect(injectControls)
end

--[[ METHODS ]]--
function LimbService.setTarget(character: Model, limb: keyof<typeof(controllers)>, target: BasePart)
	local humanoid = character:WaitForChild("Humanoid") :: Humanoid
	local control = humanoid:WaitForChild(limb) :: IKControl
	control.Target = target
end

--[[ RETURN ]]--
return LimbService