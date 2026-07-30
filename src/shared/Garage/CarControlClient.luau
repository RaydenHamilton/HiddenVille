local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CarControl = {}

local carEvent = ReplicatedStorage.Remotes.CarControl :: RemoteEvent
local player = Players.LocalPlayer

local function stopCar(bool, door)
	local humanoid = player.Character:FindFirstChild("Humanoid") :: Humanoid

	local driveSeat = humanoid.SeatPart :: VehicleSeat

	local car = driveSeat.Parent :: Model

	for _, part: BasePart in car:QueryDescendants("BasePart") do
		part.AssemblyLinearVelocity = Vector3.zero
		part.AssemblyAngularVelocity = Vector3.zero
	end

	if bool then
		local moter = door.Value.Value
		car.PrimaryPart = car.Body["#Weight"]
		local newCframe: CFrame = moter.CFrame
		local cframe = newCframe * CFrame.new(0, -newCframe.Position.Y + car.PrimaryPart.Position.Y, 0)
		car:PivotTo(cframe)
		humanoid.JumpPower = 0
	else
		humanoid.JumpPower = 50
		car.PrimaryPart = driveSeat
	end

	car.DriveSeat.Anchored = bool
end

function CarControl.init()
	carEvent.OnClientEvent:Connect(stopCar)
end
return CarControl
