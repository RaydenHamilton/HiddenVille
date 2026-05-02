local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local DriverSeat = require(ReplicatedStorage.Shared.Cars.DriverSeat)
local HitSystem = require(ReplicatedStorage.Shared.Cars.HitSystem)
local InitCar = require(ReplicatedStorage.Shared.Cars.InitCar)
local SoundServer = require(ReplicatedStorage.Shared.Cars.SoundHanlder.SoundServer)

Workspace.CivCars.ChildAdded:Connect(function(CarModel: Model)
	InitCar.new(CarModel)
	HitSystem.new(CarModel)

	DriverSeat.new(CarModel)
	SoundServer.new(CarModel)
end)
