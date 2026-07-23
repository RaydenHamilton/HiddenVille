local lightsModule = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local server = require(ReplicatedStorage.BlinkEvents.server)

local tweenInfo = TweenInfo.new(0.15)
local ON_GOAL = { Transparency = 0.02 }
local OFF_GOAL = { Transparency = 1 }
local HeadLights = { Transparency = 0.6 }

local allLights = { "Right", "Reverse", "Left", "Brakes", "Headlight", "DRL" }

function lightsModule.new(car: Model)


	local body = car:WaitForChild("Body")

	for _, lightModel in car:QueryDescendants("Model") do
		if table.find(allLights, lightModel.Name) and lightModel:FindFirstChild("on") then
			local lights = lightModel:WaitForChild("G1", 8)
			if not lights then
				continue
			end
			lights = lights:GetChildren()
			lightModel.on.Changed:Connect(function()
				local isOn = lightModel.on.Value

				for _, vehLight in ipairs(lights) do
					TweenService:Create(
						vehLight,
						tweenInfo,
						lightModel.Name == "Headlight" and HeadLights or isOn and ON_GOAL or OFF_GOAL
					):Play()

					local light = vehLight:FindFirstChild("Light")
					if light then
						light.Enabled = isOn
					end
				end
			end)
		end
	end

	local function ToggleLight(NewValue, bool)
		NewValue.on.Value = bool or not NewValue.on.Value
	end

	local function changeValue(Name, NewValue)
		local model = body:FindFirstChild(Name)

		if not model then
			return
		end

		local value = model:FindFirstChild("on")

		if not value then
			return
		end
		value.Value = NewValue
	end

	local function ToggleHazards()
		body.Hazards.on.Value = not body.Hazards.on.Value
		if body.Left.on.Value == true then
			body.Left.on.Value = false
		end
		if body.Right.on.Value == true then
			body.Right.on.Value = false
		end
	end

	local function SetBrakes(NewValue)
		changeValue("Brakes", NewValue)
	end

	local function SetReverse(NewValue)
		changeValue("Reverse", NewValue)
	end

	server.lightsOn.On(function(_, Data)
		if Data == "ToggleLight" then
			ToggleLight(body.Headlight, true)
		elseif Data == "ToggleBrakes1" then
			SetBrakes(true)
		elseif Data == "ToggleBrakes2" then
			SetBrakes(false)
		elseif Data == "ToggleHazards" then
			ToggleHazards()
		elseif Data == "ToggleReverse1" then
			SetReverse(true)
		elseif Data == "ToggleReverse2" then
			SetReverse(false)
		end
	end)
end
return lightsModule
