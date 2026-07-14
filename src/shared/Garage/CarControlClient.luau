local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local CarControl = {}

local carEvent = ReplicatedStorage.Remotes.CarControl :: RemoteEvent
local player = Players.LocalPlayer

local function stopCar(bool, door)
	local humanoid = player.Character:FindFirstChild("Humanoid") :: Humanoid

	local driveSeat = humanoid.SeatPart :: VehicleSeat

	local car = driveSeat.Parent :: Model

	if bool then
		local moter = door.Value.Value
		car.PrimaryPart = car.Body["#Weight"]
		car:PivotTo(moter.CFrame)
	else
		car.PrimaryPart = driveSeat
	end

	task.wait(0.1)

	for _, wheel: BasePart in driveSeat.Parent.Wheels:GetChildren() do
		wheel.Anchored = bool
	end
end

function CarControl.init()
	carEvent.OnClientEvent:Connect(stopCar)
end
return CarControl
