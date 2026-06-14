local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local DriverSeat = require(ReplicatedStorage.Shared.Cars.DriverSeat)
local HitSystem = require(ReplicatedStorage.Shared.Cars.HitSystem)
local InitCar = require(ReplicatedStorage.Shared.Cars.InitCar)
local ServerLights = require(ReplicatedStorage.Shared.Cars.Lights.ServerLights)
local LightsServer = require(ReplicatedStorage.Shared.Cars.Lights.LightsServer)
local CarHitSoundServer = require(ReplicatedStorage.Shared.Cars.SoundHanlder.CarHitSoundServer)
local SoundServer = require(ReplicatedStorage.Shared.Cars.SoundHanlder.SoundServer)
local Weld = require(ReplicatedStorage.Shared.Cars.Weld)

Workspace.CivCars.ChildAdded:Connect(function(CarModel: Model)
	InitCar.new(CarModel)
	HitSystem.new(CarModel)
	DriverSeat.new(CarModel)
	SoundServer.new(CarModel)
	CarHitSoundServer.new(CarModel)
	LightsServer.new(CarModel)
	Weld.new(CarModel)
	ServerLights.new(CarModel)
	task.wait(5)

	for _, obj in CarModel:GetDescendants() do
		if
			(obj:IsA("UnionOperation") or obj:IsA("BasePart") or obj:IsA("MeshPart") or obj:IsA("Part"))
			and obj.Parent.Name ~= "Wheels"
			and obj.Name ~= "Floor"
		then
			obj.CollisionGroup = "Car"
			obj.CanCollide = true
		end
	end
end)

Players.PlayerAdded:Connect(function(player: Player)
	player.CharacterAdded:Connect(function(character: Model)
		for _, part in character:GetDescendants() do
			if part:IsA("UnionOperation") or part:IsA("BasePart") or part:IsA("MeshPart") or part:IsA("Part") then
				part.CollisionGroup = "Player"
			end
		end
	end)
end)
