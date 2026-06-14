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
	local humanoid = char:WaitForChild("Humanoid")
	local root = char:WaitForChild("HumanoidRootPart") :: BasePart
	local animation = ReplicatedStorage.UniveralAnimations.Ragdoll.GettingUp
	local track = humanoid:LoadAnimation(animation)

	ragdollEvent:FireClient(target, timeDown)

	humanoid:UnequipTools()

	humanoid.Sit = false
	char:SetAttribute("Ragdoll", true)

	for _, instance in char:GetChildren() do
		local constraint = instance:FindFirstChildOfClass("AnimationConstraint")
		if constraint then
			constraint.Enabled = false
		end
		if instance:IsA("MeshPart") then
			instance.CanCollide = true
		end
	end

	root.CanCollide = false
	root.Anchored = true

	local function standup()
		-- re-enable constraints

		track:Play()
		for _, instance in char:GetChildren() do
			local constraint = instance:FindFirstChildOfClass("AnimationConstraint")
			if constraint then
				constraint.Enabled = true
			end
			if instance:IsA("BasePart") then
				instance.CanCollide = false
			end
		end
		root.Anchored = false
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
			ragdollModule.new(player, 10)
		end
	end)
end

function ragdollModule.init()
	Players.PlayerAdded:Connect(function(player: Player)
		player.CharacterAdded:Connect(CharacterAdded)
	end)
end

return ragdollModule
