local runService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Player = Players.LocalPlayer
local Camera = workspace:WaitForChild("Camera")
local Character = Player.Character or Player.CharacterAdded:Wait()

local ClientEvents = require(ReplicatedStorage.BlinkEvents.client)
--// Here are the settings :3
local updateRate = 1 / 5 --// How many times per second the server will update, if you want 60, do 1/60
local accumulated = 0

local HeadHorFactor = 1.5
local HeadVertFactor = 1.3

local TorsoHorFactor = 1
local TorsoVertFactor = 0.7

local ArmHorFactor = 0
local ArmVerFactor = 0

local UpdateSpeed = 0.25
--// Settings end

local Ang = CFrame.Angles
local aSin = math.asin

local Torso = Character:WaitForChild("UpperTorso")
local Head = Character:WaitForChild("Head")

local LeftArm = Character:WaitForChild("LeftUpperArm")
local RightArm = Character:WaitForChild("RightUpperArm")

local Neck = Head:WaitForChild("Neck")
local Waist = Torso:WaitForChild("Waist")
local LeftShoulder = LeftArm:WaitForChild("LeftShoulder")
local RightShoulder = RightArm:WaitForChild("RightShoulder")

local NeckOrgnC0 = Neck.C0
local WaistOrgnC0 = Waist.C0
local LeftShoulerOrgnC0 = LeftShoulder.C0
local RightShoulerOrgnC0 = RightShoulder.C0

local ToolAddEvent: RBXScriptConnection
local ToolRemovedEvent: RBXScriptConnection

local Diff

function getMath()
	if Character.Head.LocalTransparencyModifier == 1 then
		local localPos = Camera.CFrame:PointToObjectSpace(Head.Position)
		Diff = localPos.Y * 1.7
	else
		Diff = (Head.CFrame.Y - Camera.CFrame.Y) / (Head.CFrame.Position - Camera.CFrame.Position).magnitude
	end
end

function updateChar()
	local HeadPosition = Head.CFrame.Position
	local TorsoPosition = Torso.CFrame.Position
	local LeftArmPosition = LeftArm.CFrame.Position
	local RightArmPosition = RightArm.CFrame.Position
	local TorsoLookVector = Torso.CFrame.lookVector
	getMath()

	Neck.C0 = Neck.C0:lerp(
		NeckOrgnC0
			* Ang(
				(aSin(Diff) * (HeadVertFactor / 2)),
				-(((HeadPosition - Camera.CFrame.Position).Unit):Cross(TorsoLookVector)).Y * (HeadHorFactor / 2),
				0
			),
		UpdateSpeed / 2
	)
	Waist.C0 = Waist.C0:lerp(
		WaistOrgnC0
			* Ang(
				(aSin(Diff) * (TorsoVertFactor / 2)),
				-(((TorsoPosition - Camera.CFrame.Position).Unit):Cross(TorsoLookVector)).Y * (TorsoHorFactor / 2),
				0
			),
		UpdateSpeed / 2
	)
	LeftShoulder.C0 = LeftShoulder.C0:lerp(LeftShoulerOrgnC0 * Ang(
		(aSin(Diff) * (ArmVerFactor / 2)), --+ math.rad(10),
		-(((LeftArmPosition - Camera.CFrame.Position).Unit):Cross(TorsoLookVector)).Y * (ArmHorFactor / 2),
		0
	), UpdateSpeed / 2)
	RightShoulder.C0 = RightShoulder.C0:lerp(RightShoulerOrgnC0 * Ang(
		(aSin(Diff) * (ArmVerFactor / 2)), --+ math.rad(10),
		-(((RightArmPosition - Camera.CFrame.Position).Unit):Cross(TorsoLookVector)).Y * (ArmHorFactor / 2),
		0
	), UpdateSpeed / 2)
end

runService.RenderStepped:Connect(function(deltaTime)
	accumulated += deltaTime
	updateChar() --// Update the character for the client, this line can be removed or kept, up to you

	if accumulated >= updateRate then --// If how much time between frames and last update if greater than or equal to our goal
		accumulated = 0
		-- giveServerJointData:FireServer(Neck.C0, Waist.C0, LeftShoulder.C0, RightArm.C0) --// Update the character for other players (server)
	end
end)

local function CharacterHasTool()
	if Character:FindFirstChildOfClass("Tool") then
		return true
	end
	return false
end

local function NewCharacter(character)
	Camera = Workspace:WaitForChild("Camera")

	Character = character

	Torso = Character:WaitForChild("UpperTorso")
	Head = Character:WaitForChild("Head")

	LeftArm = Character:WaitForChild("LeftUpperArm")
	RightArm = Character:WaitForChild("RightUpperArm")

	Neck = Head:WaitForChild("Neck")
	Waist = Torso:WaitForChild("Waist")
	LeftShoulder = LeftArm:WaitForChild("LeftShoulder")
	RightShoulder = RightArm:WaitForChild("RightShoulder")

	NeckOrgnC0 = Neck.C0
	WaistOrgnC0 = Waist.C0
	LeftShoulerOrgnC0 = LeftShoulder.C0
	RightShoulerOrgnC0 = RightShoulder.C0

	if ToolAddEvent then
		ToolAddEvent:Disconnect()
		ToolAddEvent = nil
	end

	if ToolRemovedEvent then
		ToolRemovedEvent:Disconnect()
		ToolRemovedEvent = nil
	end

	ToolAddEvent = character.ChildAdded:Connect(function()
		if CharacterHasTool() then
			ArmVerFactor = HeadVertFactor
		end
	end)

	ToolRemovedEvent = character.ChildRemoved:Connect(function()
		if not CharacterHasTool() then
			ArmVerFactor = 0
		end
	end)

	ClientEvents.SendHeadAndBodyMovementToServer.Fire(Neck.C0, Waist.C0, LeftShoulder.C0, RightShoulder.C0)
end

NewCharacter(Character)

Player.CharacterAdded:Connect(NewCharacter)

ClientEvents.SendHeadAndBodyMovementToClients.On(function(playerName, neckC0, waistC0, leftShoulderC0, rightShoulderC0)
	local player = Players[playerName]

	local otherCharacter = player.Character

	local otherTorso = otherCharacter:WaitForChild("UpperTorso")

	local otherHead = otherCharacter:WaitForChild("Head")

	local otherLeftArm = otherCharacter:WaitForChild("LeftUpperArm")
	local otherRightArm = otherCharacter:WaitForChild("RightUpperArm")

	local otherNeck = otherHead:WaitForChild("Neck")
	local otherWaist = otherTorso:WaitForChild("Waist")
	local otherLeftShoulder = otherLeftArm:WaitForChild("LeftShoulder")
	local otherRightShoulder = otherRightArm:WaitForChild("RightShoulder")

	otherNeck.C0 = neckC0
	otherWaist.C0 = waistC0
	otherLeftShoulder.C0 = leftShoulderC0
	otherRightShoulder.C0 = rightShoulderC0
end)
