local IgnitionClient = {}

local Players = game:GetService("Players")
local player = Players.LocalPlayer

local connect: RBXScriptConnection
local character: Model
local humanoid: Humanoid

local function seated()
	local seat = humanoid.SeatPart

	repeat
		seat = humanoid.SeatPart
		task.wait()
	until seat

	-- Loop through the array to find the match

	if seat.Occupant == nil then
		return
	end

	local gui = player.PlayerGui:WaitForChild("A-Chassis Interface", 9)
	local car = seat.Parent

	gui:WaitForChild("Start1")
	gui:WaitForChild("Start2")

	for _, v in pairs(car.DriveSeat:GetChildren()) do
		for _, a in pairs(gui:GetChildren()) do
			if v.Name == a.Name then
				v:Stop()
				task.wait()
				v:Destroy()
				print(v.Name)
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

function IgnitionClient.init()
	local function CharacterAdded(char)
		if connect then
			connect:Disconnect()
		end
		character = char
		humanoid = character:WaitForChild("Humanoid") :: Humanoid
		connect = humanoid:GetPropertyChangedSignal("Sit"):Connect(seated)
	end

	player.CharacterAdded:Connect(CharacterAdded)

	if player.Character then
		CharacterAdded(player.Character)
	end
end

return IgnitionClient
