local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local setupClient = ReplicatedStorage:WaitForChild("Remotes").SetupGun
local gunHandler = ReplicatedStorage.Shared.GunHandler
local VestServer = require(ReplicatedStorage.Shared.Accessories.VestServer)
local Drink = require(ReplicatedStorage.Shared.Foods.Drink)
local Food = require(ReplicatedStorage.Shared.Foods.Food)
local gunServer = require(gunHandler.GunServer)
local gunWeld = require(gunHandler.GunWeld)
local gunLaser = require(gunHandler.GunLaser)

local SetUpTable = {}


local function setup(child: Tool, character)
	--[[ Start Setup ]]
	if SetUpTable[child] then
		return
	end

	local player = Players:GetPlayerFromCharacter(character)
	SetUpTable[child] = {}

	if SetUpTable[child][player] ~= true then
		SetUpTable[child][player] = true
	end

	child.Destroying:Connect(function(...)
		table.remove(SetUpTable, table.find(SetUpTable, child))
	end)

	local function hasTag(tag)
		return table.find(child:GetTags(), tag)
	end

	--[[ End Setup ]]

	-- bag
	if hasTag("Bag") then
		setupClient:FireClient(player, child, "Bag")
	end

	-- Gun
	if child:FindFirstChild("Setting") and child:FindFirstChild("ChangeMagAndAmmo") then
		gunServer.new(child)
		gunWeld.new(child)
		gunLaser.new(child)

		setupClient:FireClient(player, child, "Gun")
	end

	-- Vest
	if hasTag("Vest") then
		VestServer.new(child)
	end

	--drink
	if hasTag("Drink") then
		Drink.new(child)
	end

	-- food
	if hasTag("Food") then
		Food.new(child)
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
