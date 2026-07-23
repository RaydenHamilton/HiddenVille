local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local trove = require(ReplicatedStorage.Packages._Index["sleitnick_trove@1.8.0"].trove)
local DriverSeatServer = require(ReplicatedStorage.Shared.Cars.DriverSeatServer)
local Initialize = require(ReplicatedStorage.Shared.Cars.Initialize)
local LightsServer = require(ReplicatedStorage.Shared.Cars.Lights.LightsServer)
local CarRagdallServer = require(ReplicatedStorage.Shared.Cars.MiscModules.CarRagdollServer)
local MiscWeld = require(ReplicatedStorage.Shared.Cars.MiscModules.MiscWeld)
local SoundServer = require(ReplicatedStorage.Shared.Cars.SoundHanlder.SoundServer)

local serverInit = {}

local function createCar(CarModel: Model)
	MiscWeld.new(CarModel)
	DriverSeatServer.new(CarModel)
	Initialize.new(CarModel)
	-- SoundServer.new(CarModel)

	-- CarRagdallServer.new(CarModel)
	-- LightsServer.new(CarModel)
	task.wait(1)
	if true then
		return
	end

	for _, obj in CarModel:QueryDescendants("BasePart") do
		if obj.Name == "#Weight" then
			obj:AddTag("NoShoot")
			warn("noshoot added ")
			continue
		end
		if not obj:FindFirstAncestor("Wheels") and obj.Name ~= "FRONT" then
			obj.CollisionGroup = "Car"
			obj.CanCollide = true
			if obj.Parent.Name == "Windows" then
				obj.CanCollide = false
				(obj :: BasePart).CanQuery = false
			end
		elseif obj:FindFirstAncestor("Wheels") then
			obj.CollisionGroup = "Wheel"
			-- if obj.Parent.Name == "Wheels" then
			-- obj.Anchored = true
			-- end
		end
	end
end

local function CharacterAdded(character: Model)
	for _, part in character:QueryDescendants("BasePart") do
		part.CollisionGroup = "Player"
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
