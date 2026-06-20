local ragdollModule = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ragdollEvent = ReplicatedStorage.Remotes.KnockoutEvent

local ragdallPlayers = {}

function ragdollModule.new(target: Player, timeDown)
	if table.find(ragdallPlayers, target) then
		return
	end

	table.insert(ragdallPlayers, target)

	local char = target.Character or target.CharacterAdded:Wait()
	char:SetAttribute("Ragdoll", true)

	for _, instance in char:GetChildren() do
		local constraint = instance:FindFirstChildOfClass("AnimationConstraint")
		if constraint then
			constraint.Enabled = false
		end
	end

	local humanoid = char:WaitForChild("Humanoid")
	local animation = ReplicatedStorage.UniveralAnimations.Ragdoll.GettingUp
	local track = humanoid:LoadAnimation(animation)

	local root = char:WaitForChild("HumanoidRootPart") :: Part

	ragdollEvent:FireClient(target, timeDown)
	humanoid:UnequipTools()
	humanoid.Sit = false
	root.CanCollide = false

	local function standup()
		track:Play()
		for _, instance in char:GetChildren() do
			local constraint = instance:FindFirstChildOfClass("AnimationConstraint")
			if constraint then
				constraint.Enabled = true
			end
		end
		root.CanCollide = true

		char:SetAttribute("Ragdoll", nil)
		table.remove(ragdallPlayers, table.find(ragdallPlayers, target))
	end

	task.delay(timeDown, standup)
end

local function CharacterAdded(character: Model)
	local humanoid = character:WaitForChild("Humanoid") :: Humanoid
	local player = Players:GetPlayerFromCharacter(character)
	humanoid.HealthChanged:Connect(function()
		if humanoid.Health <= 0 then
			ragdollModule.new(player, 99)
		end
	end)
end

function ragdollModule.init()
	Players.PlayerAdded:Connect(function(player: Player)
		player.CharacterAdded:Connect(CharacterAdded)
	end)
end

return ragdollModule
