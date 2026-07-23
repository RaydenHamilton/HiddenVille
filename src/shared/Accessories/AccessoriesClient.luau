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

	local specialanim = humanoid:LoadAnimation(animations.wear)

	tool.Activated:Connect(function()
		local hum = character:FindFirstChild("Humanoid") :: Humanoid

		local sound = Instance.new("Sound")
		sound.SoundId = "rbxassetid://113495211930866"
		sound.Parent = character
		sound.Volume = 2
		hum:UnequipTools()
		if hum then
			specialanim:Play()

			task.wait(0.3)

			sound:Play()
			event:FireServer({ character, hum, protection }, tool)
		end

		task.delay(1, function()
			sound:Destroy()
		end)
	end)
end

return client
