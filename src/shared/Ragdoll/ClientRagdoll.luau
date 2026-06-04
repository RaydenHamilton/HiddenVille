local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local clientRagdollModule = {}

function clientRagdollModule.init()
	local player = Players.LocalPlayer
	local playerModule = player:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule")
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
		task.wait(time)
		clear()
		controls:Enable()
	end

	local remote = ReplicatedStorage.Remotes.KnockoutEvent

	remote.OnClientEvent:Connect(clientRagdollModule.new)
	player.CharacterAdded:Connect(CharacterAdded)
end

return clientRagdollModule
