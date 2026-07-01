local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HitSystem = {}

HitSystem.new = function(car: Model)
	local crashdb = false
	local driveSeat = car:FindFirstChild("DriveSeat")

	local Hit = car:WaitForChild("Body"):WaitForChild("FRONT")
	Hit.Touched:Connect(function(h)
		local hum
		local value = driveSeat.Velocity.magnitude / 1
		if value >= 50 then
			if h.Parent:FindFirstChild("Humanoid") or h.Parent.Parent:FindFirstChild("Humanoid") then
				if h.Parent:FindFirstChild("Humanoid") then
					hum = h.Parent
				else
					hum = h.Parent.Parent
				end
			else
				if crashdb == false then
					if h.Parent then
						if h.Parent:FindFirstChild("FL") then
							return
						end
					end
					if h.Parent and h.Parent:FindFirstChild("Humanoid") then
						return
					end
					if h.Parent and h.Parent.Parent and h.Parent.Parent:FindFirstChild("Humanoid") then
						return
					end
					if h:IsA("Seat") then
						return
					end
					if h.Parent and h.Parent.Parent and h.Parent.Parent.Parent then
						if h.Parent.Parent.Parent:FindFirstChild("FL") then
							return
						end
					end
					if h.Transparency <= 0.9 then
						if driveSeat.Occupant and driveSeat.Occupant:IsA("Humanoid") then
							local Humanoid = driveSeat.Occupant
							Humanoid.Health -= math.random(15, 20)
						else
							pcall(function()
								hum.Health -= math.random(15, 20)
							end)
						end
						crashdb = true
						local cp = ReplicatedStorage.Crash:Clone()
						cp.Parent = workspace.Map
						cp.Position = Hit.Position

						local Loop = true
						task.delay(1.75, function()
							Loop = false
						end)
						task.spawn(function()
							while Loop do
								task.wait()
								cp.Position = Hit.Position
							end
						end)

						for _, v in ipairs(cp:GetDescendants()) do
							if v:IsA("ParticleEmitter") then
								v.Enabled = true
								v:Emit(15)
								task.spawn(function()
									task.wait(1.75)
									v.Enabled = false
								end)
							end
						end

						local sound = math.random(1, 2)
						
						if sound == 1 then
							print(driveSeat:FindFirstChild("Sound1"))
							if driveSeat:FindFirstChild("Sound1") then
								driveSeat:WaitForChild("Sound1"):Clone().Parent = cp
								cp.Sound1:Play()
							end
						else
							print(driveSeat:FindFirstChild("Sound2"))
							if driveSeat:FindFirstChild("Sound2") then
								driveSeat:WaitForChild("Sound2"):Clone().Parent = cp
								cp.Sound2:Play()
							end
						end
						game.Debris:AddItem(cp, 3)
						task.wait(0.4)
						crashdb = false
					end
				end
			end
		end
	end)
end

return HitSystem
