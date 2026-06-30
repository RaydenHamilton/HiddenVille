local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local CameraClient = require(ReplicatedStorage.Shared.Cars.Camera.CameraClient)
local DriveClient = require(ReplicatedStorage.Shared.Cars.DriveClient)
local GaugesClient = require(ReplicatedStorage.Shared.Cars.GaugesClient)
local LightClient = require(ReplicatedStorage.Shared.Cars.Lights.LightClient)
local SoundClient = require(ReplicatedStorage.Shared.Cars.SoundHanlder.SoundClient)

local clientInit = {}

function clientInit.init()
	Workspace.CivCars.ChildAdded:Connect(function(CarModel: Model)
		local seat = CarModel:WaitForChild("DriveSeat") :: Part
		seat.Anchored = true
	end)

	Players.LocalPlayer.PlayerGui.ChildAdded:Connect(function(a0: Instance)
		if a0.Name == "A-Chassis Interface" then
			print("ui")
			GaugesClient.new()
			SoundClient.new()
			CameraClient.new()
			DriveClient.new()
			LightClient.new(a0)
		end
	end)
end

return clientInit
