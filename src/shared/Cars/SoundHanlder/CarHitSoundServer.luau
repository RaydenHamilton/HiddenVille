local Sound = game:GetService("ServerStorage"):WaitForChild("Ouch")
local Event = game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("HitScream")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local hitSound = {}

function hitSound.init()
	Event.OnServerEvent:Connect(function(player, hit)
		task.spawn(function()
			require(ReplicatedStorage.Shared.Ragdoll.ServerRagdoll).new(player, 5)
		end)
		local character = player.Character
		for _, part in character:GetDescendants() do
			if part:IsA("BasePart") or part:IsA("MeshPart") or part:IsA("Part") then
				part.CollisionGroup = "Default"
			end
		end

		local upperTorso = character:WaitForChild("UpperTorso")

		local attachment = Instance.new("Attachment")
		attachment.Parent = upperTorso

		local linearVelocity = Instance.new("LinearVelocity")
		linearVelocity.Attachment0 = attachment
		linearVelocity.RelativeTo = Enum.ActuatorRelativeTo.World
		linearVelocity.VectorVelocity = hit
		linearVelocity.MaxForce = math.huge
		linearVelocity.Parent = upperTorso
		print(linearVelocity)
		game:GetService("Debris"):AddItem(linearVelocity, 0.25)
		game:GetService("Debris"):AddItem(attachment, 0.25)
		if Sound then
			local SoundClone = Sound:Clone()
			SoundClone.Parent = player.Character:WaitForChild("Head")
			SoundClone:Play()
			game:GetService("Debris"):AddItem(SoundClone, SoundClone.TimeLength)
		end
		task.wait(1)
		for _, part in character:GetDescendants() do
			if part:IsA("BasePart") or part:IsA("MeshPart") or part:IsA("Part") then
				part.CollisionGroup = "Player"
			end
		end
	end)
end
return hitSound
