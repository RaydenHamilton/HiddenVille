local client = {}

function client.init()
    
	-- local Players = game:GetService("Players")
	-- local ReplicatedStorage = game:GetService("ReplicatedStorage")

	-- local remote: RemoteEvent = ReplicatedStorage.Remotes.CarGun

	-- local player = Players.LocalPlayer
	-- local mouse = player:GetMouse()
	-- local character = player.Character or player.CharacterAdded:Wait()

	-- local lastVector = Vector3.zero

	-- mouse.Move:Connect(function(...)
	-- 	if not character and lastVector:Dot((mouse.Hit.Position - character.Head.Position).Unit) > 0.8 then
	-- 		return
	-- 	end
	-- 	lastVector = (mouse.Hit.Position - character.Head.Position).Unit
	-- 	print("new")

	-- 	remote:FireServer(lastVector)
	-- end)

	-- player.CharacterAdded:Connect(function(Character: Model)
	-- 	character = Character
	-- end)
end

return client
