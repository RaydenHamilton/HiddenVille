local CarCamera = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer

local TweenService = game:GetService("TweenService")
local Camera = workspace.CurrentCamera

local char = player.Character or player.CharacterAdded:Wait()
local humanoid = char:WaitForChild("Humanoid") :: Humanoid

local DefaultFOV = 70
local FirstPersonFOV = 100

local currentTween

function CarCamera.init()
	-- Tween into first person FOV
	local function EnterFirstPerson()
		if currentTween then
			currentTween:Cancel()
		end

		currentTween = TweenService:Create(
			Camera,
			TweenInfo.new(
				3, -- Time
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

		currentTween =
			TweenService:Create(Camera, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				FieldOfView = DefaultFOV,
			})

		currentTween:Play()
	end
	local function SetCameraOffset(cframe)
		if not humanoid then
			return
		end
		local objectSpace = (char.HumanoidRootPart.CFrame + Vector3.new(0, 1.5, 0)):ToObjectSpace(cframe)
		humanoid.CameraOffset = objectSpace.Position + Vector3.new(0, 0, -0.5)
	end

	local state
	RunService.RenderStepped:Connect(function(a0: number)
		if humanoid:GetState() == Enum.HumanoidStateType.Seated then
			EnterFirstPerson()
			state = humanoid:GetState()
		elseif state ~= Enum.HumanoidStateType.Running then
			SetCameraOffset(char.Head.CFrame)
			state = humanoid:GetState()
			ExitFirstPerson()
		end
	end)

	player.CharacterAdded:Connect(function(character: Model)
		humanoid = char:WaitForChild("Humanoid") :: Humanoid
		char = character
	end)
end
return CarCamera
