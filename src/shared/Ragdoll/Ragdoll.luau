local ragdollModule = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ragdollEvent = ReplicatedStorage.Remotes.KnockoutEvent

function ragdollModule.new(target: Player, timeDown)
	local char = target.Character or target.CharacterAdded:Wait()
	local humanoid = char:WaitForChild("Humanoid")

	local root = char:WaitForChild("HumanoidRootPart") :: BasePart

	humanoid.Sit = false

	ragdollEvent:FireClient(target, timeDown)

	local animation = ReplicatedStorage.UniveralAnimations.Ragdoll.GettingUp
	local track = humanoid:LoadAnimation(animation)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp, false)
	humanoid:ChangeState(Enum.HumanoidStateType.Physics)
	humanoid:UnequipTools()

	for _, instance in char:GetDescendants() do
		if instance:IsA("AnimationConstraint") then
			instance.Enabled = false
		elseif instance:IsA("BasePart") then
			instance.CanCollide = true
		end
	end
	root.CanCollide = false

	root.Anchored = true

	local function standup()
		-- re-enable constraints
		for _, instance in char:GetDescendants() do
			if instance:IsA("AnimationConstraint") then
				instance.Enabled = true
			elseif instance:IsA("BasePart") then
				instance.CanCollide = false
			end
		end
		root.Anchored = false
		track:Play()

		root.CanCollide = true
		humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
	end

	task.delay(timeDown, standup)
end

local function CharacterAdded(character: Model)
	local humanoid = character:WaitForChild("Humanoid") :: Humanoid
	local player = Players:GetPlayerFromCharacter(character)
	humanoid.Died:Connect(function()
		ragdollModule.new(player, 10)
	end)
end

function ragdollModule.init()
	Players.PlayerAdded:Connect(function(player: Player)
		player.CharacterAdded:Connect(CharacterAdded)
	end)
end

return ragdollModule
