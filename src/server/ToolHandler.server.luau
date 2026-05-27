local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local setupClient = ReplicatedStorage:WaitForChild("Remotes").SetupGun
local gunHandler = ReplicatedStorage.Shared.GunHandler
local VestServer = require(ReplicatedStorage.Shared.Accessories.VestServer)
local Drink = require(ReplicatedStorage.Shared.Foods.Drink)
local Food = require(ReplicatedStorage.Shared.Foods.Food)
local MAndM = require(ReplicatedStorage.Shared.Foods.MAndM)
local Fist = require(ReplicatedStorage.Shared.Tools.Fist)
local MeleeServer = require(ReplicatedStorage.Shared.Tools.MeleeServer)
local gunServer = require(gunHandler.GunServer)
local gunWeld = require(gunHandler.GunWeld)
local gunLaser = require(gunHandler.GunLaser)
local SetUpTable = {}

MeleeServer.init()

local function setup(child: Tool, character)
	print("Setting up tool:", child.Name, "for character:", character.Name)
	--[[ Start Setup ]]
	local player = Players:GetPlayerFromCharacter(character)

	if SetUpTable[child] and SetUpTable[child][character] then
		return
	end

	local function hasTag(tag)
		return table.find(child:GetTags(), tag)
	end

	--[[ End Setup ]]

	-- bag

	if child:FindFirstChild("Setting") and child:FindFirstChild("ChangeMagAndAmmo") then
		setupClient:FireClient(player, child, "Gun")
	end

	if hasTag("Bag") then
		setupClient:FireClient(player, child, "Bag")
	end

	if not SetUpTable[child] and hasTag("M&Ms") then
		MAndM.Create(child)
	end

	if not SetUpTable[child] and hasTag("M&Ms Box") then
		MAndM.new(child)
	end

	-- Gun
	if not SetUpTable[child] and child:FindFirstChild("Setting") and child:FindFirstChild("ChangeMagAndAmmo") then
		gunServer.new(child)
		gunWeld.new(child)
		gunLaser.new(child)
	end

	-- Vest
	if not SetUpTable[child] and hasTag("Vest") then
		print("fire")
		VestServer.new(child)
	end

	-- drink
	if not SetUpTable[child] and hasTag("Drink") then
		Drink.new(child)
	end

	if hasTag("Drink") or hasTag("Food") then
		setupClient:FireClient(player, child, "UseClient")
	end

	-- food
	if not SetUpTable[child] and hasTag("Food") then
		Food.new(child)
	end

	-- fist
	if not SetUpTable[child] and hasTag("Fist") then
		Fist.new(child)
		setupClient:FireClient(player, child, "Fist")
	end

	------------END---------------
	SetUpTable[child] = {}

	if SetUpTable[child][character] ~= true then
		SetUpTable[child][character] = true
	end

	child.Destroying:Connect(function(...)
		table.remove(SetUpTable, table.find(SetUpTable, child))
	end)
end

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		local backpack = Players:GetPlayerFromCharacter(character).Backpack
		backpack.ChildAdded:Connect(function(child)
			setup(child, character)
		end)
		for _, child in backpack:GetChildren() do
			setup(child, character)
		end
	end)
end)
