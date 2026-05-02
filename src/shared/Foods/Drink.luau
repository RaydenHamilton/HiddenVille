local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local Drink = {}
function Drink.new(drink)
	local CD = false
	local anim = Instance.new("Animation")
	anim.AnimationId = "http://www.roblox.com/Asset?ID=110063013584450"
	local track3

	drink.Equipped:Connect(function()
		task.wait(0.01)
		track3 = drink.Parent.Humanoid:LoadAnimation(anim)
		track3.Priority = Enum.AnimationPriority.Action
		track3.Looped = true
		track3:Play()
	end)
	drink.Unequipped:Connect(function()
		if track3 then
			track3:Stop()
		end
	end)

	drink.Activated:Connect(function()
		if drink:WaitForChild("Infos").Sips.Value >= 1 then
			if CD == false then
				CD = true
				local track = drink.Parent.Humanoid:LoadAnimation(ReplicatedStorage.UniveralAnimations.Drink.Sip)

				track:Play()
				task.wait(0.3)
				drink.Handle.Att.ParticleEmitter.Enabled = true
				task.wait(0.4)
				drink.Handle.Att.ParticleEmitter.Enabled = false
				task.wait(0.8)
				drink:WaitForChild("Infos").Sips.Value = drink:WaitForChild("Infos").Sips.Value - 1

				if drink:WaitForChild("Infos").Sips.Value == 0 then
					local track2 = drink.Parent.Humanoid:LoadAnimation(ReplicatedStorage.UniveralAnimations.Drink.Done)

					track2:Play()
					task.wait(0.25)

					local can = drink.Handle:Clone()
					can.Parent = game.Workspace
					can.CFrame = drink.Handle.CFrame
					can.Velocity = drink.Handle.CFrame.rightVector * 7.5
						+ Vector3.new(0, math.random(8, 23), math.random(-5, 5))
					can.RotVelocity = Vector3.new(0, math.random(50, 300), 0)
					drink.Handle.Transparency = 1
					can.CanCollide = true
					Debris:AddItem(can, 30)
					track3:Stop()
					drink:Destroy()
				end
				CD = false
			end
		end
	end)
end
return Drink
