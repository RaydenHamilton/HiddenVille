local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Melee = {}

function Melee.init()
	ReplicatedStorage.Remotes.MeleeEvent.OnServerEvent:connect(function(Player: Player, TargetHumanoid, Damage)
		local char = Player.Character or Player.CharacterAdded:Wait()
		local tool = char:FindFirstChildOfClass("Tool")
		TargetHumanoid:TakeDamage(Damage)
		if not TargetHumanoid:FindFirstChild("creator") then
			local creator = Instance.new("ObjectValue")
			creator.Name = "creator"
			creator.Value = Player
			creator.Parent = TargetHumanoid
		else
			TargetHumanoid.creator.Value = Player
		end

		tool.Handle.Hit:Play()
		tool.Handle.Hit2:Play()
		tool.Handle.Spill:Play()

		local Animation = TargetHumanoid:LoadAnimation(tool.Hit)
		Animation:Play()
	end)
end

return Melee
