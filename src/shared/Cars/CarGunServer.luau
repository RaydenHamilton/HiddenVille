local server = {}
function server.init()
	-- local playerParts = {}

	-- local Workspace = game:GetService("Workspace")
	-- local Players = game:GetService("Players")
	-- local ReplicatedStorage = game:GetService("ReplicatedStorage")

	-- ReplicatedStorage.Remotes.CarGun.OnServerEvent:Connect(function(player, unit)
	-- 	local character = player.character

	-- 	playerParts[player].Part.Position = character.Head.Position + unit * 5

	-- 	if not playerParts[player].IKControl.ChainRoot then
	-- 		print("start")
	-- 		playerParts[player].IKControl.ChainRoot = character.UpperTorso
	-- 		playerParts[player].IKControl.EndEffector = character.RightHand
	-- 		playerParts[player].IKControl.Enabled = true
	-- 		playerParts[player].IKControl.Target = playerParts[player].Part
	-- 	end
	-- end)

	-- Players.PlayerAdded:Connect(function(player: Player)
	-- 	local ikPart = Instance.new("Part")
	-- 	-- ikPart.Transparency = 1
	-- 	ikPart.Parent = Workspace
	-- 	ikPart.CanCollide = false
	-- 	ikPart.CanQuery = false
	-- 	ikPart.CanTouch = false
	-- 	ikPart.Anchored = true

	-- 	local ik = Instance.new("IKControl")
	-- 	ik.Parent = player.Character or player.CharacterAdded:Wait()
	-- 	ik.Type = Enum.IKControlType.Position
	-- 	ik.Weight = 0.999
	-- 	ik.SmoothTime = 0.5

	-- 	playerParts[player] = { Part = ikPart, IKControl = ik }
	-- end)
end
return server
