local DriverSeat = {}

DriverSeat.new = function(carModel: Model)
	local DriveSeat = carModel:FindFirstChild("DriveSeat")
	local DrivePrompt = DriveSeat:WaitForChild("Sit")
	local Car = DriveSeat.Parent
	local Owner = Car:WaitForChild("Owner")
	local Players = game:GetService("Players")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local CurrentOccupant
	local notification = ReplicatedStorage.Remotes.Notification

	local function lockWheels(bool)
		local wheels = carModel:FindFirstChild("Wheels")
		for _, wheel: BasePart in wheels:GetChildren() do
			wheel.Anchored = bool
		end
	end

	local function enterCar(Player)
		local Character = Player.Character or Player.CharacterAdded:Wait() :: Model

		if Character:GetAttribute("Ragdoll") then
			return
		end

		local Humanoid = Character:FindFirstChildWhichIsA("Humanoid")
		local Shiftlock = Character:FindFirstChild("Shiftlock")

		local locked = DriveSeat:FindFirstChild("Locked")
		if locked and locked:IsA("BoolValue") and locked.Value == true then
			notification:FireClient(Player, "Success", "Vehicle is locked.")
			return
		end

		if Shiftlock and Shiftlock.Value == true then
			notification:FireClient(Player, "Error", "Can't enter vehicle while in shiftlock.")
			return
		end

		if string.lower(Owner.Value) == string.lower(Player.Name) or locked.Value == false and not Humanoid.Sit then
			if string.lower(Owner.Value) ~= string.lower(Player.Name) then
				notification:FireClient(Players[Owner.Value], "Error", `{Player.Name} took your car`)
			end
			DriveSeat:Sit(Humanoid)
			DrivePrompt.Enabled = false
			CurrentOccupant = Player
			CurrentOccupant.Character.HumanoidRootPart.CollisionGroup = "Wheel"
			lockWheels(false)
		end
	end

	local function exitCar()
		if not DriveSeat.Occupant then
			task.wait()
			local root: Model = CurrentOccupant.Character or CurrentOccupant.CharacterAdded:Wait()
			root:PivotTo(DriveSeat.CFrame * CFrame.new(-5, 0, 0))

			CurrentOccupant.Character.HumanoidRootPart.CollisionGroup = "Player"

			for _, v in carModel:QueryDescendants("ProximityPrompt") do
				v.Enabled = true
			end

			repeat
				task.wait()
			until (DriveSeat :: BasePart).AssemblyLinearVelocity.Magnitude < 0.01

			if not DriveSeat.Occupant then
				lockWheels(true)
			end
		end
	end

	DrivePrompt.Triggered:Connect(enterCar)

	DriveSeat:GetPropertyChangedSignal("Occupant"):Connect(exitCar)
end

return DriverSeat
