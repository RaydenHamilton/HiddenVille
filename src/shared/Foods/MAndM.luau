local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local Box = {}

function Box.new(box)
	local acti = false
	local uses = box.USES
	local idle

	box.Activated:Connect(function()
		local plr = Players:GetPlayerFromCharacter(box.Parent)
		if acti == false then
			acti = true
			local sound = box.Handle.Sound
			sound:Play()
			task.wait(0.1)
			local animation = plr.Character.Humanoid:LoadAnimation(box.Take)
			animation:Play()

			uses.Value = uses.Value - 1
			box.ToolTip = uses.Value .. " Uses"
			task.wait(2)

			local a = ServerStorage.Tools["m&ms"]:Clone()
			a.Parent = plr.Backpack

			if uses.Value == 0 then
				if idle then
					idle:Stop()
				end

				box:Destroy()
			end

			task.wait(0.2)

			acti = false
		end
	end)

	box.Equipped:Connect(function()
		local plr = Players:GetPlayerFromCharacter(box.Parent)
		idle = plr.Character.Humanoid:LoadAnimation(box.Idle)
		idle:Play()
	end)

	box.Unequipped:Connect(function()
		if idle then
			idle:Stop()
		end
	end)
end

function Box.Create(m)
	local active = false
	local uses = 3

	m.Activated:Connect(function()
		local plr = Players:GetPlayerFromCharacter(m.Parent)

		if active == false then
			active = true

			local animation = plr.Character.Humanoid:LoadAnimation(m.Bite)
			animation:Play()

			local sound = m.Handle.Eat
			task.wait(0.5)
			sound:Play()

			if m.Handle.Transparency == 0 then
				m.Handle.Transparency = 1
			elseif m["m&m1"].Transparency == 0 then
				m["m&m1"].Transparency = 1
			else
				m["m&m2"].Transparency = 1
			end

			task.wait(2)

			uses = uses - 1

			if plr.Character.Humanoid.MaxHealth < 110 then
				plr.Character.Humanoid.MaxHealth = plr.Character.Humanoid.MaxHealth + 2
			end

			task.spawn(function()
				task.wait(30)
				plr.Character.Humanoid.MaxHealth = 100
			end)

			plr.Character.Humanoid.Health = plr.Character.Humanoid.Health + 10

			if uses == 0 then
				m:Destroy()
			end
			task.wait(0.2)
			active = false
		end
	end)
end

return Box
