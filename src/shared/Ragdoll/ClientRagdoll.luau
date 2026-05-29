local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local clientRagdollModule = {}
function clientRagdollModule.init()
	local player = Players.LocalPlayer
	local playerModule = player:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule")
	local controls = require(playerModule):GetControls()

	local char = player.Character or player.CharacterAdded:Wait()
	local connections = {}

	local function clear()
		for i, v in connections do
			v:Disconnect()
		end
	end

	local root = char:WaitForChild("HumanoidRootPart") :: BasePart
	local torso = char:FindFirstChild("Head")

	local function moveToBody()
		root.CFrame = CFrame.new(torso.Position, torso.Position + Vector3.new(0, 3, 0))
		root.CFrame = CFrame.new(root.Position) * CFrame.Angles(0, root.Orientation.Y, 0)
	end
	local function CharacterAdded()
		char = player.Character or player.CharacterAdded:Wait()
		root = char:WaitForChild("HumanoidRootPart") :: BasePart
		torso = char:FindFirstChild("Head")

		clear()
		controls:Enable()
	end

	function clientRagdollModule.new(time)
		table.insert(connections, RunService.RenderStepped:Connect(moveToBody))
		controls:Disable()
		task.wait(time)
		controls:Enable()
		clear()
	end

	local remote = ReplicatedStorage.Remotes.KnockoutEvent

	remote.OnClientEvent:Connect(clientRagdollModule.new)
	player.CharacterAdded:Connect(CharacterAdded)
end

return clientRagdollModule
