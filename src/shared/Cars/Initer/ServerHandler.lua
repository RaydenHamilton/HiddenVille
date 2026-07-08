local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local DriverSeatServer = require(ReplicatedStorage.Shared.Cars.DriverSeatServer)
local InitCarServer = require(ReplicatedStorage.Shared.Cars.InitCarServer)
local LightEnablerServer = require(ReplicatedStorage.Shared.Cars.Lights.LightEnablerServer)
local LightsServer = require(ReplicatedStorage.Shared.Cars.Lights.LightsServer)
local CarRagdallServer = require(ReplicatedStorage.Shared.Cars.MiscModules.CarRagdallServer)
local HitSystemServer = require(ReplicatedStorage.Shared.Cars.MiscModules.HitSystemServer)
local SoundServer = require(ReplicatedStorage.Shared.Cars.SoundHanlder.SoundServer)
local WeldServer = require(ReplicatedStorage.Shared.Cars.MiscModules.WeldServer)

local serverInit = {}

local function createCar(CarModel: Model)
	InitCarServer.new(CarModel)
	HitSystemServer.new(CarModel)
	DriverSeatServer.new(CarModel)
	SoundServer.new(CarModel)

	CarRagdallServer.new(CarModel)
	WeldServer.new(CarModel)
	LightsServer.new(CarModel)
	LightEnablerServer.new(CarModel)
	task.wait(1)

	for _, obj in CarModel:GetDescendants() do
		if
			(obj:IsA("UnionOperation") or obj:IsA("BasePart") or obj:IsA("MeshPart") or obj:IsA("Part"))
			and obj.Parent.Name ~= "Wheels"
			and obj.Name ~= "#Weight"
			and obj.Name ~= "FRONT"
		then
			obj.CollisionGroup = "Car"
			obj.CanCollide = true
		end
	end
end

local function CharacterAdded(character: Model)
	for _, part in character:GetDescendants() do
		if part:IsA("UnionOperation") or part:IsA("BasePart") or part:IsA("MeshPart") or part:IsA("Part") then
			part.CollisionGroup = "Player"
		end
	end
end

local function PlayerAdded(player: Player)
	player.CharacterAdded:Connect(CharacterAdded)
end

function serverInit.init()
	Workspace.CivCars.ChildAdded:Connect(createCar)
	Players.PlayerAdded:Connect(PlayerAdded)
end

return serverInit
