local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Drive = require(ReplicatedStorage.Shared.Cars.Drive)
local GaugesClient = require(ReplicatedStorage.Shared.Cars.GaugesClient)
local LightClient = require(ReplicatedStorage.Shared.Cars.Lights.LightClient)
local SoundClient = require(ReplicatedStorage.Shared.Cars.SoundHanlder.SoundClient)

local clientInit = {}

function clientInit.init()
	Players.LocalPlayer.PlayerGui.ChildAdded:Connect(function(a0: Instance)
		if a0.Name == "A-Chassis Interface" then
			Drive.new()
			GaugesClient.new()
			SoundClient.new()
			LightClient.new(a0)
		end
	end)
end

return clientInit
