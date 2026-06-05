local Sound = game:GetService("ServerStorage"):WaitForChild("Ouch")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local hitSound = {}
local hitplayers = {}

function hitSound.new(carModel)
	local front = carModel:FindFirstChild("Body"):FindFirstChild("FRONT") :: Part

	task.wait(0.1)
	front.CanCollide = false

	local function touched(basePart)
		local character = basePart:FindFirstAncestorOfClass("Model")
		local player = Players:GetPlayerFromCharacter(character)
		if front.AssemblyLinearVelocity.Magnitude < 10 then
			return
		end
		if not player then
			return
		end
		if table.find(hitplayers, player) then
			return
		end

		table.insert(hitplayers, player)

		require(ReplicatedStorage.Shared.Ragdoll.ServerRagdoll).new(player, 5)

		for _, part in character:GetChildren() do
			if part:IsA("BasePart") or part:IsA("MeshPart") or part:IsA("Part") then
				part.CollisionGroup = "Default"
				if not part.Anchored then
					part:SetNetworkOwner(nil)
				end
			end
		end

		local upperTorso = character:WaitForChild("UpperTorso")

		local linearVelocity = upperTorso:FindFirstChild("LinearVelocity")

		linearVelocity.VectorVelocity = front.AssemblyLinearVelocity.Unit * front.AssemblyLinearVelocity.Magnitude
		linearVelocity.Enabled = true

		task.spawn(function()
			task.wait(0.25)
			linearVelocity.Enabled = false
		end)

		if Sound then
			local SoundClone = Sound:Clone()
			SoundClone.Parent = player.Character:WaitForChild("Head")
			SoundClone:Play()
			game:GetService("Debris"):AddItem(SoundClone, SoundClone.TimeLength)
		end

		task.wait(1)

		for _, part in character:GetChildren() do
			if part:IsA("BasePart") or part:IsA("MeshPart") or part:IsA("Part") then
				part.CollisionGroup = "Player"

				if not part.Anchored then
					part:SetNetworkOwner(player)
				end
			end
		end
		task.wait(4)
		table.remove(hitplayers, table.find(hitplayers, player))
	end

	front.touched:Connect(touched)
end

function hitSound.init()
	local function CharacterAdded(character)
		task.wait(0.1)
		local upperTorso = character:WaitForChild("UpperTorso")

		local attachment = Instance.new("Attachment")
		attachment.Parent = upperTorso

		local linearVelocity = Instance.new("LinearVelocity")
		linearVelocity.Parent = upperTorso
		print(linearVelocity.Parent)

		linearVelocity.Attachment0 = attachment
		linearVelocity.RelativeTo = Enum.ActuatorRelativeTo.World
		linearVelocity.VectorVelocity = Vector3.zero
		linearVelocity.MaxForce = math.huge
		linearVelocity.Enabled = false
	end

	Players.PlayerAdded:Connect(function(player: Player)
		player.CharacterAdded:Connect(CharacterAdded)
	end)
end

return hitSound
