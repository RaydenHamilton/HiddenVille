local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

local Main = Workspace.Map.VendingMachines
local ToolsFolder = ServerStorage:FindFirstChild("Tools")

for _, prompt in ipairs(Main:GetDescendants()) do
	if prompt:IsA("ProximityPrompt") and prompt.Name == "VendingMachine" then
		prompt.Triggered:Connect(function(player)
			local drink = ToolsFolder:FindFirstChild("Sprite")
			if not drink then
				warn("Sprite not found in ServerStorage.")
				return
			end

			local leaderstats = player:FindFirstChild("leaderstats")
			local money = leaderstats and leaderstats:FindFirstChild("Money")
			local sound = prompt:FindFirstChild("PurchaseSound")

			if not money then
				warn("Player is missing Money stat.")
				return
			end

			if money.Value >= 5 then
				money.Value = money.Value - 5

				if sound then
					sound:Play()
				else
					warn("PurchaseSound not found in VendingMachine.")
				end

				task.wait(sound.TimeLength)

				local drinkClone = drink:Clone()
				drinkClone.Parent = player:FindFirstChild("Backpack")

				prompt.Enabled = false
				task.delay(3, function()
					if prompt then
						prompt.Enabled = true
					end
				end)
			end
		end)
	end
end