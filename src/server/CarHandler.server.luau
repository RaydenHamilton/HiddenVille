local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local PhysicsService = game:GetService("PhysicsService")
local DriverSeat = require(ReplicatedStorage.Shared.Cars.DriverSeat)
local HitSystem = require(ReplicatedStorage.Shared.Cars.HitSystem)
local InitCar = require(ReplicatedStorage.Shared.Cars.InitCar)
local SoundServer = require(ReplicatedStorage.Shared.Cars.SoundHanlder.SoundServer)

PhysicsService:CreateCollisionGroup("Car")
PhysicsService:CreateCollisionGroup("Player")

PhysicsService:CollisionGroupSetCollidable("Player", "Car", true)
PhysicsService:CollisionGroupSetCollidable("Car", "Car", false)
PhysicsService:CollisionGroupSetCollidable("Car", "Default", false)

Workspace.CivCars.ChildAdded:Connect(function(CarModel: Model)
	InitCar.new(CarModel)
	HitSystem.new(CarModel)
	DriverSeat.new(CarModel)
	SoundServer.new(CarModel)
	CarModel.PrimaryPart:SetNetworkOwner(nil)

	for _, obj in CarModel:GetDescendants() do
		if obj:IsA("MeshPart") then
			obj.CollisionGroup = "Car"
			obj.CanCollide = true
		elseif obj:IsA("BasePart") and obj.Parent == "Wheels" then
			obj.CustomPhysicalProperties = PhysicalProperties.new(100, 2, 0) -- Density, Friction, Elasticity
		end
	end
end)

Players.PlayerAdded:Connect(function(player: Player)
	player.CharacterAdded:Connect(function(character: Model)
		character:WaitForChild("HumanoidRootPart").CollisionGroup = "Player"
	end)
end)
