local killDector = {}
local replicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PlayerDataServerService =
	require(ReplicatedStorage.Shared.PlayerDataHandler.SystemPackage.PlayerDataServerService)
local killEvent = replicatedStorage.Remotes:WaitForChild("KillNotification")

function newCharacter(character)
	local creator = character.Humanoid:FindFirstChild("creator")
	local humanoid = character:WaitForChild("Humanoid")
	if humanoid.Health > 0 then
		return
	end
	if creator and creator.Value and creator.Value:IsA("Player") then
		local killer = creator.Value
		local killedPlayer = Players:GetPlayerFromCharacter(character)

		if not killedPlayer then
			return
		end

		local serverKills = killer:FindFirstChild("ServerKills")

		PlayerDataServerService.add(creator, "Kills", 1)

		if serverKills then
			serverKills.Value += 1
		end

		killEvent:FireClient(killer, killedPlayer.Name)
	end
end

function killDector.init()
	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function(character)
			local death
			death = character:WaitForChild("Humanoid").Died:Connect(function()
				death:Disconnect()
				newCharacter(character)
			end)
		end)
	end)
end
return killDector
