local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera
-- Tuned so camera sits just in front of eyes

local function IsFirstPerson(bool)
	local char = player.Character
	local head = char and char:FindFirstChild("Head")
	if not head then
		return false
	end
	return (camera.CFrame.Position - head.Position).Magnitude < (bool and 0.9 or 5)
end
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
			if
				obj.Parent:IsA("Accessory") or obj.Name == "Head"
				-- or obj.Name == "UpperTorso"
				-- or obj.Name == "LowerTorso"
			then
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

RunService:BindToRenderStep("OffsetCameraToHead", Enum.RenderPriority.Camera.Value - 1, SetCameraOffset)

RunService.RenderStepped:Connect(function()
	local char = player.Character
	local humanoid = char and char:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end

	if IsFirstPerson(true) then
		SetCharacterVisible(char, true)
		HideHeadAndFace(char, true)
	elseif not IsFirstPerson(false) then
		HideHeadAndFace(char, false)
	end
end)
