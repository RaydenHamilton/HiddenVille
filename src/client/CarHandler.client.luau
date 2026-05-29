local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local CarCameraEffect = require(ReplicatedStorage.Shared.Cars.CarCameraEffect)
local CarGunClient = require(ReplicatedStorage.Shared.Cars.CarGunClient)
local Controls = require(ReplicatedStorage.Shared.Cars.Controls)
local SoundClient = require(ReplicatedStorage.Shared.Cars.SoundHanlder.SoundClient)

Workspace.CivCars.ChildAdded:Connect(function(CarModel: Model) end)

Players.LocalPlayer.PlayerGui.ChildAdded:Connect(function(a0: Instance)
	if a0.Name == "A-Chassis Interface" then
		SoundClient.new()
		Controls.new()
	end
end)

CarCameraEffect.init()
CarGunClient.init()
