local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local CarHitSoundServer = require(ReplicatedStorage.Shared.Cars.SoundHanlder.CarHitSoundServer)
local ragdall = ReplicatedStorage.Remotes.Ragdall

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
	local driveseat = carModel:FindFirstChild("DriveSeat") :: VehicleSeat

	task.wait(0.1)

	local function touched(basePart)
		local character = basePart:FindFirstAncestorOfClass("Model")
		local player = Players:GetPlayerFromCharacter(character)
		if
			driveseat.AssemblyLinearVelocity.Magnitude < 10
			or not player
			or table.find(hitplayers, player)
			or character:WaitForChild("Humanoid").Sit
			or character:GetAttribute("BoxJob")
		then
			return
		end

		local function changeColisionGroup(string: string)
			for _, part: BasePart in character:GetChildren() do
				if part:IsA("BasePart") then
					part.CollisionGroup = string
				end
			end
		end

		changeColisionGroup("Hit")

		local humanoid = character:FindFirstChild("Humanoid") :: Humanoid
		local upperTorso = character:WaitForChild("UpperTorso")
		table.insert(hitplayers, player)

		ragdall:FireClient(player, true)

		CarHitSoundServer.play(player)

		humanoid:TakeDamage(driveseat.AssemblyLinearVelocity.Magnitude / 2)

		local linearVelocity = upperTorso:FindFirstChild("LinearVelocity")
		linearVelocity.VectorVelocity = driveseat.AssemblyLinearVelocity.Unit
			* driveseat.AssemblyLinearVelocity.Magnitude
		linearVelocity.Enabled = true

		task.spawn(function()
			task.wait(0.25)
			linearVelocity.Enabled = false
		end)

		task.wait(1)

		changeColisionGroup("Player")
		repeat
			task.wait()
		until player.Character.HumanoidRootPart.AssemblyLinearVelocity.magnitude < 1 or humanoid.Health < 1
		task.wait(3)
		ragdall:FireClient(player, false)

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
