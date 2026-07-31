local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local PlayerDataServerService =
	require(ReplicatedStorage.Shared.PlayerDataHandler.SystemPackage.PlayerDataServerService)

local notification = ReplicatedStorage.Remotes.Notification

local function playAnimation(plr)
	local character = plr.Character
	if character then
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			local animation = Workspace.PunchmadeSystem.setup.Animation
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
end
local pc = Workspace.PunchmadeSystem.setup.comp.ProximityPrompt

local cardsystem = {}

function cardsystem.init()
	pc.Triggered:Connect(function(player)
		playAnimation(player)
		for _, tools in pairs(pc.Tools:GetChildren()) do
			if player.Character:FindFirstChild(tools.Name) then
				pc.Parent.Parent.Reader.Base.Neon.Color = Color3.new(0, 1, 0)
				pc.Parent.Parent.red.ProximityPrompt.Enabled = true
				player.Character:FindFirstChild(tools.Name):Destroy()

				notification:FireClient(player, `PC ready for card swipe`, "Success")
				pc.Parent.Purchased:Play()
				task.wait(0.01)
				pc.Enabled = false
				return
			end
		end

		notification:FireClient(player, `No Data`, "Error")
	end)

	local reader = Workspace.PunchmadeSystem.setup.red.ProximityPrompt

	reader.Triggered:Connect(function(player)
		playAnimation(player)
		for _, tools in pairs(reader.Tools:GetChildren()) do
			if player.Character:FindFirstChild(tools.Name) then
				reader.Parent.Parent.Reader.Base.Neon.Color = Color3.new(1, 0, 0)
				reader.Parent.Parent.comp.ProximityPrompt.Enabled = true
				player.Character:FindFirstChild(tools.Name).Name = "Blank (Active)"
				notification:FireClient(player, "Blank card activated", "Success")
				reader.Parent.Purchased:Play()
				task.wait(0.01)
				reader.Enabled = false
			end
		end
	end)

	local ProximityPrompt = Workspace.PunchmadeSystem.Data.BuyPistol.ProximityPrompt
	local toolName = "Data"
	local cost = 1000

	local toolSource = game.ServerStorage:FindFirstChild("Tools")

	task.wait(1)

	local function onPromptTriggered(player)
		playAnimation(player)
		const money = PlayerDataServerService.get(player, "Money")

		if money < cost then
			local failedSound = ProximityPrompt.Parent:FindFirstChild("PurchaseFailed")
			if failedSound then
				failedSound:Play()
			end
			warn("Not enough money.")
			return
		end
		local hasTool = player.Backpack:FindFirstChild(toolName) or player.Character:FindFirstChild(toolName)

		if hasTool then
			warn("Player already has the Data tool.")
			return
		end

		if toolSource then
			local tool = toolSource:FindFirstChild(toolName)
			if tool then
				local clone = tool:Clone()
				clone.Parent = player.Backpack

				notification:FireClient(player, `Purchased {clone.Name}`, "Success")
				PlayerDataServerService.add(player, "Money", -cost)

				local purchasedSound = ProximityPrompt.Parent:FindFirstChild("Purchased")
				if purchasedSound then
					purchasedSound:Play()
				end
			else
				warn("Tool '" .. toolName .. "' not found in Tools.")
			end
		else
			warn("Tool container 'Tools' not found in ServerStorage.")
		end
	end

	ProximityPrompt.Triggered:Connect(onPromptTriggered)
end
return cardsystem
