local Workspace = game:GetService("Workspace")
for _, model in Workspace["Group Reward Circles"]:GetChildren() do
	local Amount = 10000
	local ServerStorage = game:GetService("ServerStorage")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")

	-- notification system event
	local NotificationEvent = ReplicatedStorage:WaitForChild("NotificationEvent")

	model.Part.ProximityPrompt.Triggered:Connect(function(Player)
		if
			Player.Character
			and Player.Character:FindFirstChild("Humanoid")
			and Player.Character.Humanoid.Health > 0
		then
			-- make sure player has leaderstats
			local leaderstats = Player:FindFirstChild("leaderstats")
			if leaderstats then
				local Money = leaderstats:FindFirstChild("Money")
				if Money then
					-- tracker for claimed reward
					local claimedGroup = Player:FindFirstChild("ClaimedGroup")
					if not claimedGroup then
						claimedGroup = Instance.new("BoolValue")
						claimedGroup.Name = "ClaimedGroup"
						claimedGroup.Value = false
						claimedGroup.Parent = Player
					end

					-- check group membership
					if Player:IsInGroup(540064642) then
						if not claimedGroup.Value then
							claimedGroup.Value = true

							-- add money
							Money.Value += Amount

							-- give Glock17 Compact tool
							local toolFolder = ServerStorage:FindFirstChild("Tools")
							if toolFolder then
								local gun = toolFolder:FindFirstChild("Glock17 Compact")
								if gun then
									gun:Clone().Parent = Player.Backpack
								end
							end

							-- popup adder effect (if you want to keep it)
							task.spawn(function()
								if Player.PlayerGui:FindFirstChild("Adder") then
									Player.PlayerGui:FindFirstChild("Adder"):Destroy()
								end
								local adder = ReplicatedStorage.Misc.Adder:Clone()
								adder.Parent = Player.PlayerGui
								adder.Amount.Text = "+$" .. tostring(Amount)
								task.wait(2)
								for _ = 1, 100 do
									if adder then
										adder.Amount.TextTransparency += 0.01
										adder.Amount.UIStroke.Transparency += 0.01
										task.wait(0.01)
									end
								end
								adder:Destroy()
							end)
						else
							NotificationEvent:FireClient(
								Player,
								"You already claimed this.",
								Color3.fromRGB(255, 200, 0)
							)
						end
					else
						NotificationEvent:FireClient(Player, "You are not in the group", Color3.fromRGB(255, 0, 0))
					end
				end
			end
		end
	end)
end
