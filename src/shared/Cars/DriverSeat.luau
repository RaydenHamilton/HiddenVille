local DriverSeat = {}

DriverSeat.new = function(carModel: Model)
	local DriveSeat = carModel:FindFirstChild("DriveSeat")
	local DrivePrompt = DriveSeat:WaitForChild("Sit")
	local Car = DriveSeat.Parent
	local Owner = Car:WaitForChild("Owner")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")

	DrivePrompt.Triggered:Connect(function(Player)
		local Character = Player.Character or Player.CharacterAdded:Wait()
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
		end
	end)

	Car:WaitForChild("Locked").Changed:Connect(function()
		local locked = Car.Locked.Value
		DrivePrompt.Enabled = not locked

		for _, obj in ipairs(Car:GetDescendants()) do
			if obj:IsA("ProximityPrompt") then
				obj.Enabled = not locked
			end
		end
	end)
end

return DriverSeat
