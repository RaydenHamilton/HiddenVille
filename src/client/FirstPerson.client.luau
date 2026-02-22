local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera
-- Tuned so camera sits just in front of eyes

local function IsFirstPerson()
	local char = player.Character
	local head = char and char:FindFirstChild("Head")
	if not head then
		return false
	end
	return (camera.CFrame.Position - head.Position).Magnitude < 1.5
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
RunService.RenderStepped:Connect(function()
	local char = player.Character
	local humanoid = char and char:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end

	if IsFirstPerson() then
		local objectSpace = (char.HumanoidRootPart.CFrame + Vector3.new(0, 1.5, 0)):ToObjectSpace(char.Head.CFrame)
		humanoid.CameraOffset = objectSpace.Position --+ Vector3.new(0, 0, -0.2)
		SetCharacterVisible(char, true)
		HideHeadAndFace(char, true)
	else
		HideHeadAndFace(char, false)
	end
end)
