local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local CameraClient = require(ReplicatedStorage.Shared.Cars.CameraClient)
local DriveClient = require(ReplicatedStorage.Shared.Cars.DriveClient)
local GaugesClient = require(ReplicatedStorage.Shared.Cars.GaugesClient)
local ClientLight = require(ReplicatedStorage.Shared.Cars.Lights.ClientLight)
local IgnitionClient = require(ReplicatedStorage.Shared.Cars.SoundHanlder.IgnitionClient)
local SoundClient = require(ReplicatedStorage.Shared.Cars.SoundHanlder.SoundClient)

Workspace.CivCars.ChildAdded:Connect(function(CarModel: Model)
	IgnitionClient.new(CarModel)
end)

Players.LocalPlayer.PlayerGui.ChildAdded:Connect(function(a0: Instance)
	if a0.Name == "A-Chassis Interface" then
		GaugesClient.new()
		SoundClient.new()
		CameraClient.new()
		DriveClient.new()
		ClientLight.new(a0)
	end
end)
