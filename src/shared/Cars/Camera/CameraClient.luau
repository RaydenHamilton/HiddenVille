local Players = game:GetService("Players")
local RS = game:GetService("RunService")

local CameraModule = {}

function CameraModule.new()
	local gui = Players.LocalPlayer.PlayerGui:WaitForChild("A-Chassis Interface")
	local car = gui.Car.Value
	local cam = workspace.CurrentCamera

	car.DriveSeat.ChildRemoved:connect(function(child)
		if child.Name == "SeatWeld" then
			RS:UnbindFromRenderStep("MCam")
			car.DriveSeat.Anchored = true
			cam.CameraType = Enum.CameraType.Custom
		end
	end)
	car.DriveSeat.ChildAdded:connect(function(child)
		if child.Name == "SeatWeld" then
			car.DriveSeat.Anchored = false
		end
	end)

	gui.Values.MouseSteerOn.Changed:connect(function(property)
		if gui.Values.MouseSteerOn.Value then
			RS:BindToRenderStep("MCam", Enum.RenderPriority.Camera.Value, function()
				cam.CameraType = Enum.CameraType.Scriptable
				local pspeed = math.min(1, car.DriveSeat.Velocity.Magnitude / 500)
				local cc = car.DriveSeat.Position
					+ Vector3.new(0, 8 + (pspeed * 2), 0)
					- (car.DriveSeat.CFrame.lookVector * 17)
					+ (car.DriveSeat.Velocity.Unit * -7 * pspeed)
				cam.CoordinateFrame = CFrame.new(cc, car.DriveSeat.Position)
			end)
		else
			RS:UnbindFromRenderStep("MCam")
			cam.CameraType = Enum.CameraType.Custom
		end
	end)
end

return CameraModule
