return
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local runService = game:GetService("RunService")
local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local Camera = workspace:WaitForChild("Camera")
local Character = Player.Character or Player.CharacterAdded:Wait()
local giveServerJointData = ReplicatedStorage.Remotes.GiveServerJointData :: RemoteEvent


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

local Dist
local Diff

function getMath()
	Dist = (Head.CFrame.Position - Camera.CFrame.Position).magnitude
	Diff = Head.CFrame.Y - Camera.CFrame.Y
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
				(aSin(Diff / Dist) * (HeadVertFactor / 2)),
				-(((HeadPosition - Camera.CFrame.Position).Unit):Cross(TorsoLookVector)).Y * (HeadHorFactor / 2),
				0
			),
		UpdateSpeed / 2
	)
	Waist.C0 = Waist.C0:lerp(
		WaistOrgnC0
			* Ang(
				(aSin(Diff / Dist) * (TorsoVertFactor / 2)),
				-(((TorsoPosition - Camera.CFrame.Position).Unit):Cross(TorsoLookVector)).Y * (TorsoHorFactor / 2),
				0
			),
		UpdateSpeed / 2
	)
	LeftShoulder.C0 = LeftShoulder.C0:lerp(
		LeftShoulerOrgnC0
			* Ang(
				(aSin(Diff / Dist) * (ArmVerFactor / 2)),
				-(((LeftArmPosition - Camera.CFrame.Position).Unit):Cross(TorsoLookVector)).Y * (ArmHorFactor / 2),
				0
			),
		UpdateSpeed / 2
	)
	RightShoulder.C0 = RightShoulder.C0:lerp(
		RightShoulerOrgnC0
			* Ang(
				(aSin(Diff / Dist) * (ArmVerFactor / 2)),
				-(((RightArmPosition - Camera.CFrame.Position).Unit):Cross(TorsoLookVector)).Y * (ArmHorFactor / 2),
				0
			),
		UpdateSpeed / 2
	)
end

runService.RenderStepped:Connect(function(deltaTime)
	accumulated += deltaTime
	updateChar() --// Update the character for the client, this line can be removed or kept, up to you

	if accumulated >= updateRate then --// If how much time between frames and last update if greater than or equal to our goal
		accumulated = 0
		-- giveServerJointData:FireServer(Neck.C0, Waist.C0, LeftShoulder.C0, RightArm.C0) --// Update the character for other players (server)
	end
end)

local ToolAddEvent: RBXScriptConnection
local ToolRemovedEvent: RBXScriptConnection

local function CharacterHasTool()
	if Character:FindFirstChildOfClass("Tool") then
		return true
	end
	return false
end

local function NewCharacter(character)
	Character = character
	if ToolAddEvent then
		ToolAddEvent:Disconnect()
	end
	if ToolRemovedEvent then
		ToolRemovedEvent:Disconnect()
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
end

NewCharacter(Character)

Player.CharacterAdded:Connect(NewCharacter)
