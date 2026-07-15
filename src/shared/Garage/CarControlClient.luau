local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
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
		local newCframe: CFrame = moter.CFrame
		-- newCframe.Position.Y = car.PrimaryPart.Position.Y
		car:PivotTo(newCframe)
		humanoid.JumpPower = 0
	else
		humanoid.JumpPower = 50
		car.PrimaryPart = driveSeat
	end

	for _, wheel: BasePart in driveSeat.Parent.Wheels:GetChildren() do
		wheel.Anchored = bool
	end
end

function CarControl.init()
	carEvent.OnClientEvent:Connect(stopCar)
end
return CarControl
