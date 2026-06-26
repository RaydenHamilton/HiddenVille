local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer

local TweenService = game:GetService("TweenService")
local Camera = workspace.CurrentCamera

local DefaultFOV = 70
local FirstPersonFOV = 200

local currentTween

-- Tween into first person FOV
local function EnterFirstPerson()
	if currentTween then
		currentTween:Cancel()
	end

	currentTween = TweenService:Create(
		Camera,
		TweenInfo.new(
			0.5, -- Time
			Enum.EasingStyle.Quad,
			Enum.EasingDirection.Out
		),
		{
			FieldOfView = FirstPersonFOV,
		}
	)

	currentTween:Play()
end

-- Tween back to normal FOV
local function ExitFirstPerson()
	if currentTween then
		currentTween:Cancel()
	end

	currentTween = TweenService:Create(Camera, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		FieldOfView = DefaultFOV,
	})

	currentTween:Play()
end

local function SetCharacterVisible(char, visible)
	for _, obj in ipairs(char:GetChildren()) do
		if obj:IsA("BasePart") and (string.find(obj.Name, "Hand") or string.find(obj.Name, "Arm")) then
			obj.LocalTransparencyModifier = visible and 0 or 1
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

local state

RunService.RenderStepped:Connect(function()
	local char = player.Character or player.CharacterAdded:Wait()
	local humanoid = char:WaitForChild("Humanoid") :: Humanoid
	if humanoid:GetState() == Enum.HumanoidStateType.Seated or humanoid.Sit then
		return
	end
	if char:FindFirstChild("Head") then
		if char:WaitForChild("Head").LocalTransparencyModifier > 0.4 then
			SetCameraOffset()
			EnterFirstPerson()
			SetCharacterVisible(char, true)
			state = "First"
		elseif state ~= "Third" then
			state = "Third"
			ExitFirstPerson()
		end
	end
end)
