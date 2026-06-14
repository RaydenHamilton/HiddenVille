local ReplicatedStorage = game:GetService("ReplicatedStorage")
local server = require(ReplicatedStorage.BlinkEvents.server)
local serverLights = {}

function serverLights.new(Car)
	local function ToggleLight(NewValue)
		NewValue.on.Value = not NewValue.on.Value
	end

	local function ToggleHazards()
		Car.Body.Hazards.on.Value = not Car.Body.Hazards.on.Value
		if Car.Body.Left.on.Value == true then
			Car.Body.Left.on.Value = false
		end
		if Car.Body.Right.on.Value == true then
			Car.Body.Right.on.Value = false
		end
	end

	local function SetBrakes(NewValue)
		Car.Body.Brakes.on.Value = NewValue
	end

	local function ToggleBlinker(NewValue)
		NewValue.on.Value = not NewValue.on.Value
	end

	local function SetReverse(NewValue)
		Car.Body.Reverse.on.Value = NewValue
	end

	local function SetHorn()
		Car.DriveSeat.Horn.Playing = not Car.DriveSeat.Horn.Playing
	end

	server.lightsOn.On(function(Player, Data)
		if Data == "ToggleLight" then
			ToggleLight(Car.Body.Headlight)
			ToggleLight(Car.Body.Highlight)
		elseif Data == "ToggleBrakes1" then
			SetBrakes(true)
		elseif Data == "ToggleBrakes2" then
			SetBrakes(false)
		elseif Data == "ToggleLeftBlink" then
			ToggleBlinker(Car.Body.Left)
		elseif Data == "ToggleHazards" then
			ToggleHazards()
		elseif Data == "ToggleRightBlink" then
			ToggleBlinker(Car.Body.Right)
		elseif Data == "ToggleReverse1" then
			SetReverse(true)
		elseif Data == "ToggleReverse2" then
			SetReverse(false)
		elseif Data == "ToggleHorn" then
			SetHorn()
		end
	end)
end

return serverLights
