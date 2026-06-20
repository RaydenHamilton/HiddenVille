local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local clientRagdollModule = {}

function clientRagdollModule.init()
	local player = Players.LocalPlayer
	local playerModule = player:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule") :: ModuleScript
	local controls = require(playerModule):GetControls()

	local connections = {}

	local char = player.Character or player.CharacterAdded:Wait()
	local root = char:WaitForChild("HumanoidRootPart") :: BasePart
	local torso = char:WaitForChild("Head")

	local function clear()
		for _, v in connections do
			v:Disconnect()
		end
	end

	local function moveToBody()
		if root and root.Parent and torso then
			root.CFrame = CFrame.new(torso.Position + Vector3.new(0, 3, 0))
			for _, instance in char:GetChildren() do
				if instance:IsA("MeshPart") then
					instance.CanCollide = true
				end
			end
			root.Anchored = true
			root.CanCollide = false
		else
			clear()
		end
	end

	local function CharacterAdded()
		clear()
		char = player.Character or player.CharacterAdded:Wait()
		root = char:WaitForChild("HumanoidRootPart") :: BasePart
		torso = char:WaitForChild("Head")
		controls:Enable()
	end

	function clientRagdollModule.new(time)
		table.insert(connections, RunService.RenderStepped:Connect(moveToBody))
		controls:Disable()

		for _, instance in char:GetChildren() do
			if instance:IsA("MeshPart") then
				instance.CanCollide = true
			end
		end
		task.wait(time)
		clear()

		for _, instance in char:GetChildren() do
			if instance:IsA("MeshPart") then
				instance.CanCollide = false
			end
		end

		root.CanCollide = true
		root.Anchored = false
		controls:Enable()
	end

	local remote = ReplicatedStorage.Remotes.KnockoutEvent

	remote.OnClientEvent:Connect(clientRagdollModule.new)
	player.CharacterAdded:Connect(CharacterAdded)
end

return clientRagdollModule
