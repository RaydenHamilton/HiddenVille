local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local setupClient = ReplicatedStorage.SetupGun
local gunServer = require(ReplicatedStorage.Shared.GunHandler.GunServer)

SetUpTable = {}

local function setup(child, character)
	if not child:FindFirstChild("Setting") or not child:FindFirstChild("ChangeMagAndAmmo") then
		return
	end
	local player = Players:GetPlayerFromCharacter(character)
	-- if SetUpTable[child] == nil then
	-- 	SetUpTable[child] = {}
	-- end
	if SetUpTable[child] ~= true then
		SetUpTable[child] = true
		gunServer.new(child)
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
