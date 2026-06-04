local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")

local soundEvent = game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("HitScream")
local CanRagdoll = true

local CarRagdoll = {}

function CarRagdoll.init()
	local function recoverFromRagdoll(hit)
		local healthConnection
		healthConnection = humanoid.HealthChanged:Connect(function()
			if humanoid.Health < humanoid.MaxHealth then
				CanRagdoll = true
				healthConnection:Disconnect()
				hit.CanCollide = false
			end
		end)

		if not CanRagdoll then
			hit.CanCollide = false
			if healthConnection then
				healthConnection:Disconnect()
			end
		end
		task.wait(5)
		CanRagdoll = true
	end

	local function onTouched(hit: BasePart)
		if hit.Name == "FRONT" and CanRagdoll then
			if humanoid.Sit then
				return
			end
			if hit.Velocity.Magnitude < 10 then
				return
			end

			soundEvent:FireServer(hit.Velocity * 1.2)

			CanRagdoll = false

			recoverFromRagdoll(hit)
		end
	end

	for _, part in pairs(character:GetDescendants()) do
		if part:IsA("BasePart") and part.Name ~= "FRONT" then
			part.Touched:Connect(onTouched)
		end
	end

	player.CharacterAdded:Connect(function(newCharacter)
		character = newCharacter
		humanoid = character:WaitForChild("Humanoid")
		for _, part in pairs(character:GetDescendants()) do
			if part:IsA("BasePart") and part.Name ~= "FRONT" then
				part.Touched:Connect(onTouched)
			end
		end
	end)
end
return CarRagdoll
