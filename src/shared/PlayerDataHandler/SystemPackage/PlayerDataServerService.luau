--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

--// Packages
local ProfileStore = require(ReplicatedStorage.Packages.Profilestore)

--// Module
local PlayerDataServer = {}

local PlayerStore

local Profiles = {}

function PlayerDataServer.init(newTemplate: { any })
	PlayerStore = ProfileStore.New("treyson", newTemplate)
	Profiles = Profiles :: { [Player]: typeof(PlayerStore:StartSessionAsync()) }

	for _, player in Players:GetPlayers() do
		task.spawn(PlayerDataServer.playerAdded(player))
	end
end

function PlayerDataServer.set(player: Player, valueName: string, NewValue: {} | number)
	if Profiles[player] then
		Profiles[player]["Data"][valueName] = NewValue
	else
		warn("failed to set player data")
	end
end

function PlayerDataServer.get(player: Player, valueName: string)
	if Profiles[player] then
		return Profiles[player]["Data"][valueName]
	end
	return nil
end

function PlayerDataServer.add(player: Player, valueName: string, NewValue: number)
	if Profiles[player] and typeof(Profiles[player]["Data"][valueName]) == "number" then
		Profiles[player]["Data"][valueName] += NewValue
		print(Profiles[player]["Data"][valueName])
	else
		warn(valueName .. " is not a number")
	end
end

function PlayerDataServer.playerAdded(player: Player)
	local profile = PlayerStore:StartSessionAsync(`{player.UserId}`, {
		Cancel = function()
			return player.Parent ~= Players
		end,
	})

	if profile ~= nil then
		profile:AddUserId(player.UserId)
		profile:Reconcile()
		profile.OnSessionEnd:Connect(function()
			Profiles[player] = nil
			player:Kick(`Profile session end - Please rejoin`)
		end)

		if player.Parent == Players then
			Profiles[player] = profile
		else
			profile:EndSession()
		end
	else
		player:Kick(`Profile load fail - Please rejoin`)
	end
end

function PlayerDataServer.playerRemoving(player: Player)
	local profile = Profiles[player]
	if profile ~= nil then
		profile:EndSession()
	end
end

return table.freeze(PlayerDataServer)
