--TODO make cusome first person script

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local states = nil
local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera
-- Tuned so camera sits just in front of eyes
local character = player.Character or player.CharacterAdded:Wait()

-- local id = character:WaitForChild("Head").MeshId
local headClone = ReplicatedStorage:WaitForChild("Miscs").GibsR15.rig.Head:Clone()
headClone.CanCollide = false
headClone.CanQuery = false

local function SetCharacterVisible(char, visible)
	for _, obj in ipairs(char:GetDescendants()) do
		if obj:IsA("BasePart") then
			obj.LocalTransparencyModifier = visible and 0 or 1
		end
	end
end

local function HideHeadAndFace(char, hide)
	for _, obj in ipairs(char:GetDescendants()) do
		if obj:IsA("BasePart") then
			if obj.Parent:IsA("Accessory") or obj.Name == "Head" then
				obj.LocalTransparencyModifier = hide and 1 or 0
			end
		end
	end
end

local function SetCameraOffset()
	local char = player.Character
	local humanoid = char and char:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end
	local objectSpace = (char.HumanoidRootPart.CFrame + Vector3.new(0, 1.5, 0)):ToObjectSpace(char.Head.CFrame)
	humanoid.CameraOffset = objectSpace.Position + Vector3.new(0, 0, -0.5)
end

local function moveHeadBehindCamera(bool)
	if bool then
		if headClone.Parent ~= Workspace then
			headClone.Parent = Workspace
			RunService:BindToRenderStep("OffsetCameraToHead", Enum.RenderPriority.Camera.Value - 1, SetCameraOffset)
		end
		headClone.CFrame = CFrame.new(camera.CFrame.X, character.Head.CFrame.Y + 0.05, camera.CFrame.Z)
	else
		if headClone.Parent == Workspace then
			headClone.Parent = ReplicatedStorage
			RunService:UnbindFromRenderStep("OffsetCameraToHead")
		end
	end
end

function hideNameTag(char, hide)
	if not (char:FindFirstChild("Head") and char.Head:FindFirstChild("Nametag")) then
		return
	end
	char.Head.Nametag.MaxDistance = hide and 0 or 10000
end

RunService.RenderStepped:Connect(function()
	local char = player.Character
	local humanoid = char and char:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end
	if character.Head.LocalTransparencyModifier > 0.5 and states ~= "First Person" then
		SetCharacterVisible(char, true)
		HideHeadAndFace(char, true)
		moveHeadBehindCamera(true)
		hideNameTag(char, true)
		states = "First Person"
	elseif states ~= "Third Person" then
		humanoid.CameraOffset = Vector3.zero
		moveHeadBehindCamera(false)
		hideNameTag(char, false)
		states = "Third Person"
	end
end)
