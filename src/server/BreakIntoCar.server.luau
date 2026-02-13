local Workspace = game:GetService("Workspace")

local MoneyTaken = {}

for _, Model in Workspace.CarRobberySystem:GetChildren() do
	local Car = Model.Fusion
	local Glass = Model.Glass
	local pad = Glass.InteractPat
	local proximity = pad.Prox1
	local proximity2 = pad.Prox2
	local Elbow = proximity.Elbow
	local GrabCash = proximity2.GrabCash
	local CashPocket = proximity2.CashPocket
	local GlassBreak = pad.GlassBreak
	local CarAlarm = pad.CarAlarm

	proximity.Triggered:Connect(function(player)
		local character = player.Character
		local humanoid = character and character:FindFirstChild("Humanoid")
		local humanoidRootPart = character and character:FindFirstChild("HumanoidRootPart")
		if humanoid and humanoidRootPart and Glass.Transparency < 1 then
			local ElbowAnim = humanoid:LoadAnimation(Elbow)

			local Highlight = Instance.new("Highlight")
			Highlight.DepthMode = "Occluded"
			Highlight.Parent = Car

			task.delay(5, function()
				if Highlight and Highlight.Parent then
					Highlight:Destroy()
				end
			end)

			ElbowAnim:Play(0.3)
			proximity.Enabled = false
			ElbowAnim.Stopped:Wait()
			proximity2.Enabled = true
			humanoidRootPart.Anchored = false

			Glass.Transparency = 1
			if Highlight and Highlight.Parent then
				Highlight:Destroy()
			end
			GlassBreak:Play()
			CarAlarm:Play()
		end
	end)

	proximity2.Triggered:Connect(function(player)
		local character = player.Character
		local humanoid = character and character:FindFirstChild("Humanoid")
		local humanoidRootPart = character and character:FindFirstChild("HumanoidRootPart")
		local leaderstats = player:FindFirstChild("leaderstats")
		local hiddenstats = player:FindFirstChild("hiddenstats")

		if humanoid and humanoidRootPart then
			local CashGrab = humanoid:LoadAnimation(GrabCash)

			CashGrab:Play(0.3)
			proximity2.Enabled = false

			CashPocket:Play()

			CashGrab.Stopped:Wait()
			CashPocket:Stop()
			CarAlarm:Stop()
			humanoidRootPart.Anchored = false

			if MoneyTaken[player.UserId] then
				MoneyTaken[player.UserId] = MoneyTaken[player.UserId] - 0.1
			end
			if MoneyTaken[player.UserId] == nil then
				MoneyTaken[player.UserId] = 1
			elseif MoneyTaken[player.UserId] <= 0 then
				task.wait(25)

				proximity.Enabled = true
				proximity2.Enabled = false
				Glass.Transparency = 0.5
				return
			end

			if leaderstats and leaderstats:FindFirstChild("Money") then
				leaderstats.Money.Value = leaderstats.Money.Value + math.random(1000, 1850) * MoneyTaken[player.UserId]
			end

			if hiddenstats and hiddenstats:FindFirstChild("XP") then
				hiddenstats.XP.Value = hiddenstats.XP.Value + 450
			end

			task.wait(25)

			proximity.Enabled = true
			proximity2.Enabled = false
			Glass.Transparency = 0.5
		end
	end)
end
