local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CarHitSoundServer = require(ReplicatedStorage.Shared.Cars.SoundHanlder.CarHitSoundServer)

local carRagdall = {}

local function CharacterAdded(character)
	task.wait(0.1)
	local upperTorso = character:WaitForChild("UpperTorso")

	local attachment = Instance.new("Attachment")
	attachment.Parent = upperTorso

	local linearVelocity = Instance.new("LinearVelocity")
	linearVelocity.Parent = upperTorso

	linearVelocity.Attachment0 = attachment
	linearVelocity.RelativeTo = Enum.ActuatorRelativeTo.World
	linearVelocity.VectorVelocity = Vector3.zero
	linearVelocity.MaxForce = math.huge
	linearVelocity.Enabled = false
end

function carRagdall.new(carModel)
	local hitplayers = {}

	local front = carModel:FindFirstChild("Body"):FindFirstChild("FRONT") :: Part

	task.wait(0.1)

	local function touched(basePart)
		local character = basePart:FindFirstAncestorOfClass("Model")
		local player = Players:GetPlayerFromCharacter(character)
		if
			front.AssemblyLinearVelocity.Magnitude < 20
			or not player
			or table.find(hitplayers, player)
			or character:WaitForChild("Humanoid").Sit
		then
			return
		end

		table.insert(hitplayers, player)

		local function changeColision(owner)
			for _, part in character:GetChildren() do
				if part:IsA("BasePart") or part:IsA("MeshPart") or part:IsA("Part") then
					part.CollisionGroup = owner and "Players" or "Default"
				end
			end
		end

		changeColision(nil)

		require(ReplicatedStorage.Shared.Ragdoll.ServerRagdoll).new(player, 5)

		local upperTorso = character:WaitForChild("UpperTorso")

		local linearVelocity = upperTorso:FindFirstChild("LinearVelocity")

		linearVelocity.VectorVelocity = front.AssemblyLinearVelocity.Unit * front.AssemblyLinearVelocity.Magnitude
		linearVelocity.Enabled = true

		CarHitSoundServer.play(player)

		task.spawn(function()
			task.wait(0.25)
			linearVelocity.Enabled = false
		end)

		task.wait(1)

		changeColision(player)

		task.wait(4)

		table.remove(hitplayers, table.find(hitplayers, player))
	end

	front.touched:Connect(touched)
end

function carRagdall.init()
	for _, player: Player in Players:GetChildren() do
		player.CharacterAdded:Connect(CharacterAdded)
	end
	Players.PlayerAdded:Connect(function(player: Player)
		player.CharacterAdded:Connect(CharacterAdded)
	end)
end

return carRagdall
