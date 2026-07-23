local clientLights = {}

function clientLights.new(ui)
	local Car = ui.Car.Value
	Car:WaitForChild("DriveSeat")
	local InputService = game:GetService("UserInputService")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local client = require(ReplicatedStorage.BlinkEvents.client)

	client.lightsOn.Fire("ToggleLight")

	InputService.InputEnded:Connect(function(Input)
		if Input.KeyCode == Enum.KeyCode.F then
			client.lightsOn.Fire("ToggleHorn")
		end
	end)

	Car.DriveSeat.Changed:Connect(function(Change)
		if Change == "Throttle" then
			if Car.DriveSeat.Throttle == -1 then
				client.lightsOn.Fire("ToggleBrakes1")
			else
				client.lightsOn.Fire("ToggleBrakes2")
			end
		end
	end)

	ui.Values.Gear.Changed:connect(function()
		if ui.Values.Gear.Value == -1 then
			client.lightsOn.Fire("ToggleReverse1")
		else
			client.lightsOn.Fire("ToggleReverse2")
		end
	end)
end
return clientLights
