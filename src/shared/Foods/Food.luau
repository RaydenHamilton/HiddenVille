local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Food = {}

function Food.new(food)
	local CD = false
	local anim = Instance.new("Animation")
	anim.AnimationId = "http://www.roblox.com/Asset?ID=112792415449747"
	local track3
	food.Equipped:Connect(function()
		task.wait(0.01)
		track3 = food.Parent.Humanoid:LoadAnimation(anim)
		track3.Priority = Enum.AnimationPriority.Action
		track3.Looped = true
		track3:Play()
	end)
	food.Unequipped:Connect(function()
		if track3 then
			track3:Stop()
		end
	end)

	food.Activated:Connect(function()
		if food:WaitForChild("Infos").Sips.Value >= 1 then
			if CD == false then
				CD = true
				local track = food.Parent.Humanoid:LoadAnimation(ReplicatedStorage.UniveralAnimations.Drink.Sip)

				track:Play()
				track.Stopped:wait()
				food:WaitForChild("Infos").Sips.Value = food:WaitForChild("Infos").Sips.Value - 1

				if food:WaitForChild("Infos").Sips.Value == 0 then
					track3:Stop()
					food:Destroy()
				end
				CD = false
			end
		end
	end)
end

return Food
