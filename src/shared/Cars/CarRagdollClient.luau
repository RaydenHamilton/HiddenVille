local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")

local soundEvent = game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("HitScream")
local CanRagdoll = true

local CarRagdoll = {}

function CarRagdoll.init()
	local function onTouched(hit: BasePart)
		if hit.Name ~= "FRONT" and not CanRagdoll then
			return
		end

		if humanoid.Sit or hit.AssemblyLinearVelocity.Magnitude < 10 then
			return
		end

		CanRagdoll = false

		task.wait(5)

		CanRagdoll = true
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
