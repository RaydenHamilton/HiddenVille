local DriverSeat = {}

DriverSeat.new = function(carModel: Model)
	local DriveSeat = carModel:FindFirstChild("DriveSeat")
	local DrivePrompt = DriveSeat:WaitForChild("Sit")
	local Car = DriveSeat.Parent
	local Owner = Car:WaitForChild("Owner")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local CurrentOccupant

	DrivePrompt.Triggered:Connect(function(Player)
		local Character = Player.Character or Player.CharacterAdded:Wait() :: Model

		if Character:GetAttribute("Ragdoll") then
			return
		end

		local Humanoid = Character:FindFirstChildWhichIsA("Humanoid")
		local Shiftlock = Character:FindFirstChild("Shiftlock")

		local locked = DriveSeat:FindFirstChild("Locked")
		if locked and locked:IsA("BoolValue") and locked.Value == true then
			ReplicatedStorage:FindFirstChild("Notify"):FireClient(Player, "Vehicle is locked.", 2)
			return
		end

		if Shiftlock and Shiftlock.Value == true then
			ReplicatedStorage:FindFirstChild("Notify"):FireClient(Player, "Can't enter vehicle while in shiftlock.", 2)
			return
		end

		if string.lower(Owner.Value) == string.lower(Player.Name) and not Humanoid.Sit then
			DriveSeat:Sit(Humanoid)
			DrivePrompt.Enabled = false
			CurrentOccupant = Player
			CurrentOccupant.Character.HumanoidRootPart.CollisionGroup = "Car"
		end
	end)

	DriveSeat:GetPropertyChangedSignal("Occupant"):Connect(function()
		if not DriveSeat.Occupant then
			task.wait()

			local root: Model = CurrentOccupant.Character or CurrentOccupant.CharacterAdded:Wait()
			root:PivotTo(DriveSeat.CFrame * CFrame.new(-5, 0, 0))
			CurrentOccupant.Character.HumanoidRootPart.CollisionGroup = "Player"

			for _, v in carModel:QueryDescendants("ProximityPrompt") do
				v.Enabled = true
			end
		end
	end)

	Car:WaitForChild("Locked").Changed:Connect(function()
		local locked = Car.Locked.Value
		DrivePrompt.Enabled = not locked

		for _, obj in ipairs(Car:QueryDescendants("ProximityPrompt")) do
			obj.Enabled = not locked
		end
	end)
end

return DriverSeat
