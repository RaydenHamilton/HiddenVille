local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PlayerDataServerService =
	require(ReplicatedStorage.Shared.PlayerDataHandler.SystemPackage.PlayerDataServerService)

local GunFolder = ServerStorage:WaitForChild("Tools")
local BlackMarket = Workspace:WaitForChild("BlackMarket")
local DuffelBag = BlackMarket.DuffelBag
local Prompt = DuffelBag.Buy
local Price = DuffelBag.Price
local Gun = BlackMarket.C4
local gunPrompt = Gun.Handle.Buy
local gunPrice = Gun.Price

Prompt.ObjectText = "Purchase " .. DuffelBag.Name
Prompt.ActionText = "$" .. Price.Value

local Tool = ServerStorage.Tools:FindFirstChild("DuffelBag")

local notification = ReplicatedStorage.Remotes.Notification

local blackmarket = {}

function blackmarket.init()
	Prompt.Triggered:Connect(function(Player)
		if Player.Character:FindFirstChild(Tool.Name) then
			notification:FireClient(Player, `You aleary have a duffle bag`, "Error")
			return
		end
		const money = PlayerDataServerService.get(Player, "Money")
		if money >= Price.Value then
			PlayerDataServerService.add(Player, "Money", -Price.Value)

			if not Player:FindFirstChild("canrob") then
				local val = Instance.new("BoolValue")
				val.Parent = Player
				val.Name = "canrob"
			end
			Player:FindFirstChild("canrob").Value = true
			local DuffelBagClone = Tool:Clone()
			notification:FireClient(Player, `You purchased {Tool.Name}`, "Success")

			if game:GetService("MarketplaceService"):UserOwnsGamePassAsync(Player.UserId, 1030832854) then
				DuffelBagClone.gamepass.Value = true
			end

			DuffelBagClone.CFrame = Player.Character:WaitForChild("UpperTorso").CFrame
			DuffelBagClone.Orientation = Vector3.new(
				DuffelBagClone.Orientation.x,
				DuffelBagClone.Orientation.y - 180,
				DuffelBagClone.Orientation.z
			)
			DuffelBagClone.WeldConstraint.Part1 = Player.Character.UpperTorso
			DuffelBagClone.Parent = Player.Character

			local goldValue = DuffelBagClone:WaitForChild("goldvalue")
			local gamepass = DuffelBagClone:WaitForChild("gamepass")
			local gui = DuffelBagClone:WaitForChild("guipart"):WaitForChild("SurfaceGui")
			local frame = gui:WaitForChild("Frame")
			local label = frame:WaitForChild("TextLabel")
			local bar = frame:WaitForChild("greenbar")

			local function updateDisplay()
				local gold = goldValue.Value
				local hasGamepass = gamepass.Value
				local maxGold = hasGamepass and 10 or 5

				label.Text = tostring(gold) .. "/" .. tostring(maxGold)
				bar.Size = UDim2.fromScale(gold / maxGold, 1)
			end

			updateDisplay()
			goldValue.Changed:Connect(updateDisplay)
			gamepass.Changed:Connect(updateDisplay)
		else
			notification:FireClient(Player, `You do not have enough money`, "Error")
		end
	end)

	gunPrompt.ObjectText = "Purchase " .. Gun.Name
	gunPrompt.ActionText = "$" .. gunPrice.Value

	local GunToClone = GunFolder:WaitForChild(Gun.Name)

	gunPrompt.Triggered:Connect(function(Player)
		local money = PlayerDataServerService.get(Player, "Money")
		if money >= gunPrice.Value then
			PlayerDataServerService.add(Player, "Money", -gunPrice.Value)
			GunToClone:Clone().Parent = Player.Backpack
			notification:FireClient(Player, `You purchased {GunToClone.Name}`, "Success")
		else
			notification:FireClient(Player, `You do not have enough money`, "Error")
		end
	end)

	local BlankPrompt = BlackMarket.Blank.Handle.Buy
	local Blank = BlankPrompt.Parent.Parent
	local BlankPrice = Blank:WaitForChild("Price")

	-- Set prompt text
	BlankPrompt.ObjectText = "Purchase " .. Blank.Name
	BlankPrompt.ActionText = "$" .. BlankPrice.Value
	-- Safely get the gun to clone
	local BlankToClone = GunFolder:FindFirstChild("Blank (Inactive)")
	if not BlankToClone then
		warn("Gun purchase FAILED: 'Blank (Inactive)' not found in ServerStorage.Tools")
		return
	end

	BlankPrompt.Triggered:Connect(function(Player)
		local Money = PlayerDataServerService.get(Player, "Money")

		if Money >= Price.Value then
			PlayerDataServerService.add(Player, "Money", -Price.Value)
			local clone = BlankToClone:Clone()

			notification:FireClient(Player, `You have Purchased {BlankToClone.Name}`, "Success")
			clone.Parent = Player.Backpack
		else
			notification:FireClient(Player, `You do not have enough money`, "Error")
		end
	end)

	local MoneyGamepassID = 1030750804

	local function duffelValue(DuffelValue, DuffelType, OwnsGamepass)
		if DuffelType == "Warehouse" then
			if OwnsGamepass then
				return DuffelValue * 2000
			else
				return DuffelValue * 1500
			end
		elseif DuffelType == "Jewelry" then
			if OwnsGamepass then
				return DuffelValue * 3000
			else
				return DuffelValue * 2000
			end
		elseif DuffelType == "Bank" then
			if OwnsGamepass then
				return DuffelValue * 10000
			else
				return DuffelValue * 10000
			end
		else
			return 0
		end
	end
	Workspace.Map:FindFirstChild("sellpart", true).ProximityPrompt.Triggered:Connect(function(plr)
		if plr.Character:FindFirstChild("DuffelBag") then
			if plr.Character.DuffelBag.goldvalue.Value > 0 then
				local ownsMoneyGamepass = false
				local totalValue = 0

				local success1, result1 = pcall(function()
					return MarketplaceService:UserOwnsGamePassAsync(plr.UserId, MoneyGamepassID)
				end)
				if success1 and result1 then
					ownsMoneyGamepass = true
				end

				totalValue = duffelValue(
					plr.Character.DuffelBag.goldvalue.Value,
					plr.Character.DuffelBag.Type.Value,
					ownsMoneyGamepass
				)

				PlayerDataServerService.add(plr, "Money", totalValue)
				PlayerDataServerService.add(plr, "XP", 28700)

				plr.Character.DuffelBag:Destroy()
				plr.canrob.Value = false
			end
		end
	end)
end
return blackmarket
