local IgnitionClient = {}

local Players = game:GetService("Players")
local player = Players.LocalPlayer

function IgnitionClient.new(model)
	local gui = player.PlayerGui:WaitForChild("A-Chassis Interface")
	local car = model

	gui:WaitForChild("Start1")
	gui:WaitForChild("Start2")

	for i, v in pairs(car.DriveSeat:GetChildren()) do
		for _, a in pairs(gui:GetChildren()) do
			if v.Name == a.Name then
				v:Stop()
				task.wait()
				v:Destroy()
			end
		end
	end

	local s1 = gui.Start1
	local s2 = gui.Start2

	s1.Parent = car.DriveSeat
	s2.Parent = car.DriveSeat
	task.wait()
	s1:Play()
	task.wait(7.3)
	s2:Play()
	gui.IsOn.Value = true
	task.wait()
	s1:Stop()
	s2:Stop()
end

return IgnitionClient
