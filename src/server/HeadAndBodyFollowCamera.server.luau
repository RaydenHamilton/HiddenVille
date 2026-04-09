local ReplicatedStorage = game:GetService("ReplicatedStorage")

local serverEvents = require(ReplicatedStorage.BlinkEvents.server)

serverEvents.SendHeadAndBodyMovementToServer.On(function(player, neckC0, waistC0, leftShoulderC0, rightShoulderC0)
	serverEvents.SendHeadAndBodyMovementToClients.FireExcept(
		player,
		player.Name,
		neckC0,
		waistC0,
		leftShoulderC0,
		rightShoulderC0
	) --// Update the character for other players (client)
end)
