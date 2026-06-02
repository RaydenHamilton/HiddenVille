local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local DriverSeat = require(ReplicatedStorage.Shared.Cars.DriverSeat)
local HitSystem = require(ReplicatedStorage.Shared.Cars.HitSystem)
local InitCar = require(ReplicatedStorage.Shared.Cars.InitCar)
local SoundServer = require(ReplicatedStorage.Shared.Cars.SoundHanlder.SoundServer)

Workspace.CivCars.ChildAdded:Connect(function(CarModel: Model)
	InitCar.new(CarModel)
	HitSystem.new(CarModel)
	DriverSeat.new(CarModel)
	SoundServer.new(CarModel)
	task.wait(5)
	for _, obj in CarModel:GetDescendants() do
		if obj:IsA("BasePart") and obj.Parent.Name ~= "Wheels" and obj.Parent.Parent.Name == "Body" then
			obj.CollisionGroup = "Car"
			obj.CanCollide = true
		end
	end
end)

Players.PlayerAdded:Connect(function(player: Player)
	player.CharacterAdded:Connect(function(character: Model)
		for _, part in character:GetDescendants() do
			if part:IsA("BasePart") and part:IsA("MeshPart") and part:IsA("Part") then
				part.CollisionGroup = "Player"
			end
		end
	end)
end)
