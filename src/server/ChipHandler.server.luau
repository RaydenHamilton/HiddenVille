local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local Workspace = game:GetService("Workspace")
local Prompt = Workspace.NPCs.Vender.UpperTorso.Main.SellPrompt

local gamepassID = 1331110346

local function checkForChips(player)
	return player.Character:FindFirstChild("Small Chips")
		or player.Backpack:FindFirstChild("Small Chips")
		or player.Character:FindFirstChild("Medium Chips")
		or player.Backpack:FindFirstChild("Medium Chips")
		or player.Character:FindFirstChild("Large Chips")
		or player.Backpack:FindFirstChild("Large Chips")
end

local function sellChips(player, takiType)
	local moneyEarned = 0
	local xpEarned = 0
	if takiType == "Small Chips" then
		moneyEarned = math.random(350, 750)
		xpEarned = 3875
	elseif takiType == "Medium Chips" then
		moneyEarned = math.random(850, 1250)
		xpEarned = 3875
	elseif takiType == "Large Chips" then
		moneyEarned = math.random(1500, 2250)
		xpEarned = 4875
	end

	local ownsMoneyGamepass = false
	local success1, result1 = pcall(function()
		return MarketplaceService:UserOwnsGamePassAsync(player.UserId, gamepassID)
	end)
	if success1 and result1 then
		ownsMoneyGamepass = true
	end

	if ownsMoneyGamepass then
		moneyEarned *= 2
	end

	local leaderstats = player:FindFirstChild("leaderstats")
	local hiddenstats = player:FindFirstChild("hiddenstats")
	if leaderstats and hiddenstats then
		local money = leaderstats:FindFirstChild("Money")
		local xp = hiddenstats:FindFirstChild("XP")
		if money and xp then
			money.Value = money.Value + moneyEarned
			xp.Value = xp.Value + xpEarned
		end
	end

	return moneyEarned
end

Prompt.Triggered:Connect(function(player)
	local character = player.Character
	local leaderstats = player:FindFirstChild("leaderstats")

	if leaderstats and checkForChips(player) then
		local moneyEarned = 0
		local takiToSell = nil

		if character:FindFirstChild("Small Chips") then
			moneyEarned = sellChips(player, "Small Chips")
			takiToSell = character:FindFirstChild("Small Chips")
		elseif character:FindFirstChild("Medium Chips") then
			moneyEarned = sellChips(player, "Medium Chips")
			takiToSell = character:FindFirstChild("Medium Chips")
		elseif character:FindFirstChild("Large Chips") then
			moneyEarned = sellChips(player, "Large Chips")
			takiToSell = character:FindFirstChild("Large Chips")
		end

		if takiToSell then
			takiToSell:Destroy()
			Prompt.Parent["money sound effect"]:Play()
			ReplicatedStorage.Events.SOLDChips:FireClient(player, moneyEarned)
		end
	else
		ReplicatedStorage.Events.Availability:FireClient(player, "Equip Chips")
	end
end)

local ServerStorage = game:GetService("ServerStorage")

local main = Workspace.ChipsSystem
local toolsFolder = ServerStorage:WaitForChild("Tools")

local COOK_TIME = 12
local RESTORE_DELAY = 3

-- Cache allowed tools once instead of rebuilding every cook
local AllowedChips = {}
do
	for _, item in ipairs(toolsFolder:GetChildren()) do
		if
			item:IsA("Tool")
			and (item.Name == "Small Chips" or item.Name == "Medium Chips" or item.Name == "Large Chips")
		then
			table.insert(AllowedChips, item)
		end
	end
end

-- Extract pot parts only once
local function getPotComponents(trigger)
	local potModel = trigger:FindFirstAncestorWhichIsA("Model")
	local potMain = potModel:WaitForChild("w")

	return {
		model = potModel,
		trigger = trigger,
		stickText = potMain.Stick.Stick.Frame.RoleplayName,
		powderText = potMain.Powder.Powder.Frame.RoleplayName,
		usedUI = potMain.Used.Used.Frame.RoleplayName,
		inUseText = potMain.Main.Used.Frame.RoleplayName,
		cookingUI = potMain.Main.Cooking,
		cookingSound = potMain.Main.CookingSound,
		endSound = potMain.Main.Dome,
	}
end

local potStates = {}

local function cook(pot, plr)
	local states = potStates[pot.model]
	if not states then
		return
	end

	states.isCooking = true

	local ui = pot.usedUI
	ui.Visible = true
	pot.stickText.Visible = false
	pot.powderText.Visible = false

	pot.trigger.Enabled = false
	pot.cookingUI.Enabled = true
	pot.cookingSound:Play()

	-- Small loop effect
	for i = 1, 3 do
		ui.Text = "Cooking" .. string.rep(".", i)
		task.wait(1)
	end

	task.wait(COOK_TIME)

	pot.cookingSound:Stop()
	pot.endSound:Play()
	pot.cookingUI.Enabled = false
	pot.trigger.Enabled = true

	-- Reward handling
	if #AllowedChips > 0 then
		local reward = AllowedChips[math.random(1, #AllowedChips)]:Clone()
		reward.Parent = plr.Backpack
	else
		warn("No valid Chips found in Tools folder.")
	end

	-- Reset UI + states
	ui.Visible = false
	pot.stickText.Text = "0/1 Stick"
	pot.powderText.Text = "0/1 Red Powder"
	pot.stickText.Visible = true
	pot.powderText.Visible = true
	states.inUse = nil
	states.stick = false
	states.powder = false
	states.isCooking = false
	pot.inUseText.Visible = false
end

local function onTriggered(trigger, plr)
	local pot = getPotComponents(trigger)
	local states = potStates[pot.model]

	if not states then
		states = { inUse = nil, stick = false, powder = false, isCooking = false }
		potStates[pot.model] = states
	end

	if states.inUse and states.inUse ~= plr.Name then
		ReplicatedStorage.NotificationEvent:FireClient(plr, "This pot is not useable.")
		return
	end

	-- Quick ingredient lookup (one scan each)
	local char, backpack = plr.Character, plr.Backpack
	local hasStick = (char and char:FindFirstChild("Stick")) or (backpack and backpack:FindFirstChild("Stick"))
	local hasPowder = (char and char:FindFirstChild("Powder")) or (backpack and backpack:FindFirstChild("Powder"))

	if not hasStick or not hasPowder then
		ReplicatedStorage.NotificationEvent:FireClient(plr, "You do not have the required ingredients.")
		return
	end

	states.inUse = plr.Name
	pot.inUseText.Text = "Used by: " .. plr.Name
	pot.inUseText.Visible = true

	-- Ingredient remove helper
	local function hasAndRemove(name)
		local obj = (char and char:FindFirstChild(name)) or (backpack and backpack:FindFirstChild(name))
		if obj then
			obj:Destroy()
			return true
		end
		return false
	end

	local addedIngredient = false
	if not states.powder and hasAndRemove("Powder") then
		states.powder = true
		pot.powderText.Text = "1/1 Red Powder"
		addedIngredient = true
	end
	if not states.stick and hasAndRemove("Stick") then
		states.stick = true
		pot.stickText.Text = "1/1 Stick"
		addedIngredient = true
	end

	if not addedIngredient then
		ReplicatedStorage.Events.Availability:FireClient(plr)
	end

	-- Start cooking if ready
	if not states.isCooking then
		if states.stick and states.powder then
			states.isCooking = true
			task.delay(RESTORE_DELAY, function()
				cook(pot, plr)
			end)
		end
	else
		ReplicatedStorage.NotificationEvent:FireClient(plr, "This pot is not useable.")
	end
end

-- Connect all cook prompts once
for _, trigger in ipairs(main:GetDescendants()) do
	if trigger:IsA("ProximityPrompt") and trigger.Name == "CookPrompt" then
		trigger.Triggered:Connect(function(plr)
			onTriggered(trigger, plr)
		end)
	end
end
