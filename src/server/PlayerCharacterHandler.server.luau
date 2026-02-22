local ReplicatedStorage = game:GetService("ReplicatedStorage")

local playerJointData: RemoteEvent = ReplicatedStorage.Remotes.GiveServerJointData

local function SetPlayerJoints(player: Player, neckCO, waistCO)
	local character = player.Character
	local head = character:FindFirstChild("Head")
	local torso = character:FindFirstChild("UpperTorso")
	local neck = head:WaitForChild("Neck")
	local waist = torso:WaitForChild("Waist")
	neck.C0 = neckCO
	waist.C0 = waistCO
end

playerJointData.OnServerEvent:Connect(SetPlayerJoints)
