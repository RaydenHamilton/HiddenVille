local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerDataServerService =
	require(ReplicatedStorage.Shared.PlayerDataHandler.SystemPackage.PlayerDataServerService)

local playerDataServerSetup = {}
playerDataServerSetup.__index = playerDataServerSetup

local profileTemplate = {
	Safe = {},
	PlayerData = {
		Money = 5000,
		Bank = 0,
		Gender = "Male",
		Level = 1,
		XP = 0,
		Kills = 0,
		ClaimedGroup = false,
	},
}

function playerDataServerSetup.init()
	PlayerDataServerService.create(profileTemplate)

	Players.PlayerAdded:Connect(PlayerDataServerService.playerAdded)
	Players.PlayerRemoving:Connect(PlayerDataServerService.playerRemoving)
end

return playerDataServerSetup
