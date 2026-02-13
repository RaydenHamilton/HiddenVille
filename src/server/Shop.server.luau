local Workspace = game:GetService("Workspace")
local ServerStorage = game:GetService("ServerStorage")

for _, item in Workspace.BuyableItems.Normal:GetChildren() do
	local Prompt = item:FindFirstChild("BuyGun", true)
	local Gui = Prompt.Parent:FindFirstChild("Gui")
	local GunModule = nil
	local Gun = Prompt.Parent.Parent
	local RequiredLevel = Gun:FindFirstChild("RequiredLevel")
	local Price = Gun:FindFirstChild("Price")
	Prompt.ObjectText = "Purchase " .. Gun.Name
	Prompt.ActionText = "$" .. Price.Value
	Prompt.Triggered:Connect(function(Player)
		local GunFolder = ServerStorage:WaitForChild("Tools")

		-- Safe module load
		local SettingFolder = Gun:FindFirstChild("Setting")
		if SettingFolder and SettingFolder:FindFirstChild("1") then
			GunModule = require(SettingFolder["1"])
		end

		-- Validate Price & Required Level
		if not Price or not RequiredLevel then
			warn(Gun.Name .. " missing Price or RequiredLevel")
			return
		end

		-- Find tool to clone
		local GunToClone = GunFolder:FindFirstChild(Gun.Name)

		if not GunToClone then
			warn("Tool '" .. Gun.Name .. "' not found in ServerStorage > Tools")
			return
		end

		local debounce = {}
		if debounce[Player] then
			return
		end
		debounce[Player] = true

		local stats = Player:FindFirstChild("hiddenstats")
		local leaderstats = Player:FindFirstChild("leaderstats")

		if not stats or not leaderstats then
			debounce[Player] = nil
			return
		end

		local Level = stats:FindFirstChild("Level")
		local Money = leaderstats:FindFirstChild("Money")

		if not Level or not Money then
			debounce[Player] = nil
			return
		end

		if Level.Value < RequiredLevel.Value then
			debounce[Player] = nil
			return
		end

		if Money.Value >= Price.Value then
			Money.Value -= Price.Value

			local newGun = GunToClone:Clone()
			newGun.Parent = Player.Backpack
		end

		task.wait(0.5)
		debounce[Player] = nil
	end)

	-- Disable touch triggers so preview gun doesn't cause lag
	for _, part in ipairs(Gun:GetDescendants()) do
		if part:IsA("Part") or part:IsA("MeshPart") then
			part.CanTouch = false
		end
	end

	-- Safe GUI update
	if Gui and Gui:FindFirstChild("Frame") then
		local Frame = Gui.Frame

		if Frame:FindFirstChild("Level") then
			Frame.Level.Text = "Required Level: " .. RequiredLevel.Value
		end

		if GunModule then
			if Frame:FindFirstChild("Accuracy") then
				Frame.Accuracy.Text = Frame.Accuracy.Text .. GunModule.Spread
			end
			if Frame:FindFirstChild("Damage") then
				Frame.Damage.Text = Frame.Damage.Text .. GunModule.BaseDamage
			end
			if Frame:FindFirstChild("Ammo") then
				Frame.Ammo.Text = Frame.Ammo.Text .. GunModule.AmmoPerMag
			end
		end
	end
end

for _, item in Workspace.BuyableItems.GamePass:GetChildren() do
	local MarketplaceService = game:GetService("MarketplaceService")

	local Prompt = item:FindFirstChild("BuyGun", true)
	local Gun = item
	local Price = Gun:FindFirstChild("Price")
	local Gui = Prompt.Parent:FindFirstChild("Gui")

	-- Safe Require
	local GunModule = nil
	local SettingFolder = Gun:FindFirstChild("Setting")
	if SettingFolder and SettingFolder:FindFirstChild("1") then
		GunModule = require(SettingFolder["1"])
	end

	local gamepassId = Prompt.GamePass.Value

	-- Safety checks
	if not Price then
		warn("Gun missing Price value:", Gun.Name)
		return
	end

	Prompt.ObjectText = "Purchase " .. Gun.Name .. " Spawner"
	Prompt.ActionText = "$R" .. Price.Value

	local debounce = {}

	Prompt.Triggered:Connect(function(Player)
		if debounce[Player] then
			return
		end
		debounce[Player] = true

		MarketplaceService:PromptGamePassPurchase(Player, gamepassId)

		task.wait(0.5)
		debounce[Player] = nil
	end)

	-- Prevent touch on display parts
	for _, part in ipairs(Gun:GetDescendants()) do
		if part:IsA("Part") or part:IsA("MeshPart") then
			part.CanTouch = false
		end
	end

	-- GUI safe update
	if Gui and Gui:FindFirstChild("Frame") then
		local Frame = Gui.Frame

		if Frame:FindFirstChild("Price") then
			Frame.Price.Text = "$R" .. Price.Value
		end

		if GunModule then
			if Frame:FindFirstChild("Accuracy") then
				Frame.Accuracy.Text = Frame.Accuracy.Text .. GunModule.Spread
			end

			if Frame:FindFirstChild("Damage") then
				Frame.Damage.Text = Frame.Damage.Text .. GunModule.BaseDamage
			end

			if Frame:FindFirstChild("Ammo") then
				Frame.Ammo.Text = Frame.Ammo.Text .. GunModule.AmmoPerMag
			end
		end
	end
end

for _, item in Workspace.ChipsSystem:GetChildren() do
	if item:FindFirstChild("ProximityPrompt", true) then
		local trigger = item:FindFirstChild("ProximityPrompt", true)
		local text = trigger.Parent.Parent.Stock.RoleplayName.Frame.RoleplayName

		local stock = math.huge
		local price = 200
		local restocking = false

		local function updateText()
			text.Text = "Stock: " .. stock
		end

		local function startRestocking()
			if restocking then
				return
			end
			restocking = true

			while stock < 30 do
				task.wait(180)
				stock += 1
				updateText()
			end

			restocking = false
		end

		trigger.Triggered:Connect(function(player)
			local stick = ServerStorage:WaitForChild("Tools"):WaitForChild(item.Name)
			local leaderstats = player:FindFirstChild("leaderstats")

			if stock <= 0 then
				startRestocking()
				return
			end

			if leaderstats and leaderstats:FindFirstChild("Money") then
				local money = leaderstats.Money
				if money.Value >= price then
					money.Value -= price
					local giveObject = stick:Clone()
					giveObject.Parent = player.Backpack
					stock -= 1
					updateText()

					if stock <= 0 then
						startRestocking()
					end
				end
			end
		end)

		updateText()
	end
end
