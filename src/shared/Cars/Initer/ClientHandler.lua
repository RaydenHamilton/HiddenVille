local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CameraClient = require(ReplicatedStorage.Shared.Cars.Camera.CameraClient)
local Drive = require(ReplicatedStorage.Shared.Cars.Drive)
local GaugesClient = require(ReplicatedStorage.Shared.Cars.GaugesClient)
local LightClient = require(ReplicatedStorage.Shared.Cars.Lights.LightClient)
local SoundClient = require(ReplicatedStorage.Shared.Cars.SoundHanlder.SoundClient)

local clientInit = {}

function clientInit.init()
	Players.LocalPlayer.PlayerGui.ChildAdded:Connect(function(a0: Instance)
		if a0.Name == "A-Chassis Interface" then
			GaugesClient.new()
			SoundClient.new()
			CameraClient.new()
			Drive.new()
			LightClient.new(a0)
		end
	end)
end

return clientInit
