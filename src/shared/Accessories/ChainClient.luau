local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local client = {}

function client.new(tool: Tool)
	local animations = ReplicatedStorage.UniveralAnimations.Chain

	local player = Players.LocalPlayer
	local character = player.Character or player.CharacterAdded:Wait()
	local humanoid = character:WaitForChild("Humanoid")

	local event = ReplicatedStorage.Remotes:WaitForChild("AddAccessorie")
	local protection = 50

	local ready = false

	local specialanim = humanoid:LoadAnimation(animations.wear)
	local specialanim2 = humanoid:LoadAnimation(animations.takeoff)

	tool.Activated:Connect(function()
		local hum = character:FindFirstChild("Humanoid")
		if hum and ready == false then
			ready = true
			specialanim:Play()

			task.wait(1)
			event:FireServer("protect", { character, hum, protection })
		elseif ready == true then
			ready = false
			specialanim2:Play()
			task.wait(0.3)
			event:FireServer("unprotect", { character, hum, protection})
		end
	end)
end

return client
