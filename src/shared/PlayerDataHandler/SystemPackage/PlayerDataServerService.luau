--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

--// Packages
local ProfileStore = require(ReplicatedStorage.PackagesNew.Profilestore)
local GoodSignal =
	require(ReplicatedStorage.PackagesNew._Index["1foreverhd_topbarplus@3.4.0"].topbarplus.Packages.GoodSignal)

--// Module
local PlayerDataServer = {}

local PlayerStore

local Profiles = {}

PlayerDataServer.MoneySignal = GoodSignal.new()

local function updateClient(player, valueName, NewValue)
	if valueName == "Money" then
		ReplicatedStorage.Remotes.UpdataPlayerMoney:FireClient(player, NewValue)
		PlayerDataServer.MoneySignal:Fire(NewValue)
	end
end

function PlayerDataServer.create(newTemplate: { any })
	PlayerStore = ProfileStore.New("game", newTemplate)
	Profiles = Profiles :: { [Player]: typeof(PlayerStore:StartSessionAsync()) }

	for _, player in Players:GetPlayers() do
		task.spawn(PlayerDataServer.playerAdded(player))
	end

	ReplicatedStorage.Remotes.RequestPlayerData.OnServerInvoke = PlayerDataServer.get
end

function PlayerDataServer.set(player: Player, valueName: string, NewValue: {} | number)
	if Profiles[player] then
		updateClient(player, valueName, NewValue)
		Profiles[player]["Data"][valueName] = NewValue
	else
		warn("failed to set player data")
	end
end

function PlayerDataServer.get(player: Player, valueName: string)
	repeat
		task.wait()
	until Profiles[player] and Profiles[player]["Data"][valueName] ~= nil

	if Profiles[player] then
		return Profiles[player]["Data"][valueName]
	end

	warn("Data_not_Found: " .. valueName)
	return nil
end

function PlayerDataServer.add(player: Player, valueName: string, NewValue: number)
	if Profiles[player] and typeof(Profiles[player]["Data"][valueName]) == "number" then
		local value = PlayerDataServer.get(player, valueName)
		PlayerDataServer.set(player, valueName, value + NewValue)
		Profiles[player]["Data"][valueName] += NewValue
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
