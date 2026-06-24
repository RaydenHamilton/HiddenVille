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

	local state
	RunService.RenderStepped:Connect(function()
		if humanoid:GetState() == Enum.HumanoidStateType.Seated then
			state = humanoid:GetState()
			EnterFirstPerson()
		elseif state ~= Enum.HumanoidStateType.Running then
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
