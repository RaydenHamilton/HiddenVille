local IgnitionClient = {}

local Players = game:GetService("Players")
local player = Players.LocalPlayer

function IgnitionClient.new(model)
	local seat = model:WaitForChild("DriveSeat") :: Seat

	local function seated(name)
		if name ~= "Occupant" or seat.Occupant == nil then
			return
		end

		local gui = player.PlayerGui:WaitForChild("A-Chassis Interface")
		local car = model

		gui:WaitForChild("Start1")
		gui:WaitForChild("Start2")

		for _, v in pairs(car.DriveSeat:GetChildren()) do
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

		local function stopSound()
			if not gui or not gui.Parent or not gui:FindFirstChild("IsOn") then
				s1:Stop()
				s2:Stop()
				return true
			end
			return true
		end

		task.wait()

		if stopSound() then
			return
		end

		s1:Play()

		task.wait(7.3)

		if stopSound() then
			return
		end

		s2:Play()

		if stopSound() then
			return
		end

		gui.IsOn.Value = true

		task.wait()

		s1:Stop()
		s2:Stop()
	end

	seat.Changed:Connect(seated)
end

return IgnitionClient
