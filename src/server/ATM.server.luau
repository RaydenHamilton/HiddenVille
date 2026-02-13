local MarketplaceService = game:GetService("MarketplaceService")
local Workspace = game:GetService("Workspace")
local gamePassId = 1331110346

for _, ATM in ipairs(Workspace.ATM:GetChildren()) do
	local prox = ATM:FindFirstChild("ProximityPrompt", true)
	prox.Triggered:Connect(function(player)
		for _, tool in ipairs(prox.Tools:GetChildren()) do
			if player.Character and player.Character:FindFirstChild(tool.Name) then
				local parent = ATM.Proxxxx
				local uiFrame = ATM
				local amount = math.random(3500, 10000)

				local success, hasGamePass = pcall(function()
					return MarketplaceService:UserOwnsGamePassAsync(player.UserId, gamePassId)
				end)

				if success and hasGamePass then
					amount *= 2
				end

				local stats = player:FindFirstChild("leaderstats")
				local hidden = player:FindFirstChild("hiddenstats")
				local money = stats and stats:FindFirstChild("Money")
				local xp = hidden and hidden:FindFirstChild("XP")
				if money then
					money.Value += amount
				else
					warn("Player's leaderstats or 'Money' stat not found.")
				end
				if xp then
					xp.Value += 18500
				else
					warn("Player's hiddenstats or 'XP' stat not found.")
				end

				local charTool = player.Character:FindFirstChild(tool.Name)
				if charTool then
					charTool:Destroy()
				end

				prox.MaxActivationDistance = 0
				uiFrame.Dark.Transparency = 0
				uiFrame.Screen.Transparency = 1
				parent.Purchased:Play()

				task.wait(math.random(30, 90))

				uiFrame.Dark.Transparency = 1
				uiFrame.Screen.Transparency = 0
				prox.MaxActivationDistance = 10
			end
		end
	end)
	prox.Triggered:Connect(function(plr)
		local character = plr.Character
		if character then
			local humanoid = character:FindFirstChildOfClass("Humanoid")
			if humanoid then
				local animation = Workspace.Animation
				if animation then
					local anim = humanoid:LoadAnimation(animation)
					anim.Priority = Enum.AnimationPriority.Action
					anim:Play()
				else
					warn("Animation not found.")
				end
			else
				warn("Humanoid not found in player's character.")
			end
		else
			warn("Player's character not found.")
		end
	end)
end
