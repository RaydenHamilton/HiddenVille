local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local setupClient = ReplicatedStorage:WaitForChild("Remotes").SetupGun
local gunHandler = ReplicatedStorage.Shared.GunHandler
local gunServer = require(gunHandler.GunServer)
local gunWeld = require(gunHandler.GunWeld)
local gunLaser = require(gunHandler.GunLaser)
local SetUpTable = {}

local function setup(child, character)
	if not child:FindFirstChild("Setting") or not child:FindFirstChild("ChangeMagAndAmmo") then
		return
	end
	local player = Players:GetPlayerFromCharacter(character)
	-- if SetUpTable[child] == nil then
	-- 	SetUpTable[child] = {}
	-- end
	if SetUpTable[child] == nil then
		SetUpTable[child] = {}
		gunServer.new(child)
		gunWeld.new(child)
		gunLaser.new(child)
	end
	-- when gun setup still
	if SetUpTable[child][player] ~= true then
		SetUpTable[child][player] = true
		setupClient:FireClient(player, child)
	end
end

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		local backpack = Players:GetPlayerFromCharacter(character).Backpack
		for _, child in backpack:GetChildren() do
			setup(child, character)
		end
		backpack.ChildAdded:Connect(function(child)
			setup(child, character)
		end)
	end)
end)
