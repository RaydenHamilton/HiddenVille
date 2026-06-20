local lightsModule = {}

local TweenService = game:GetService("TweenService")

local tweenInfo = TweenInfo.new(0.15)
local ON_GOAL = { Transparency = 0.02 }
local OFF_GOAL = { Transparency = 1 }

local allLights = { "Right", "Reverse", "Left", "Brakes", "Headlight", "DRL" }

function lightsModule.new(carModel: Model)
	for _, lightModel in carModel:GetDescendants() do
		if table.find(allLights, lightModel.Name) and lightModel:IsA("Model") then

			lightModel.on.Changed:Connect(function()
				local lights = lightModel.G1:GetChildren()
				local isOn = lightModel.on.Value

				for _, vehLight in ipairs(lights) do
					TweenService:Create(vehLight, tweenInfo, isOn and ON_GOAL or OFF_GOAL):Play()

					local light = vehLight:FindFirstChild("Light")
					if light then
						light.Enabled = isOn
					end
				end
			end)
		end
	end
end
return lightsModule
