local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

local GunFolder = ServerStorage:WaitForChild("Tools")
local BlackMarket = Workspace:WaitForChild("BlackMarket")
local DuffelBag = BlackMarket.DuffelBag
local Prompt = DuffelBag.BuyGun
local Price = DuffelBag.Price
local Gun = BlackMarket.C4
local gunPrompt = Gun.Handle.BuyGun
local gunPrice = Gun.Price

Prompt.ObjectText = "Purchase " .. DuffelBag.Name
Prompt.ActionText = "$" .. Price.Value

local Tool = ServerStorage.Tools:FindFirstChild("DuffelBag")

Prompt.Triggered:Connect(function(Player)
	if Player.leaderstats.Money.Value >= Price.Value then
		Player.leaderstats.Money.Value -= Price.Value

		local DuffelBagClone = Tool:Clone()

		if game:GetService("MarketplaceService"):UserOwnsGamePassAsync(Player.UserId, 1030832854) then
			DuffelBagClone.gamepass.Value = true
		end

		DuffelBagClone.CFrame = Player.Character:WaitForChild("UpperTorso").CFrame
		DuffelBagClone.Orientation =
			Vector3.new(DuffelBagClone.Orientation.x, DuffelBagClone.Orientation.y - 180, DuffelBagClone.Orientation.z)
		DuffelBagClone.WeldConstraint.Part1 = Player.Character.UpperTorso
		DuffelBagClone.Parent = Player.Character
	end
end)

for _, part in pairs(DuffelBag:GetDescendants()) do
	if part:IsA("MeshPart") or part:IsA("Part") then
		part.CanTouch = false
	end
end

DuffelBag.CanTouch = false

gunPrompt.ObjectText = "Purchase " .. Gun.Name
gunPrompt.ActionText = "$" .. gunPrice.Value

local GunToClone = GunFolder:WaitForChild(Gun.Name)

gunPrompt.Triggered:Connect(function(Player)
	if Player.leaderstats.Money.Value >= gunPrice.Value then
		Player.leaderstats.Money.Value -= gunPrice.Value
		GunToClone:Clone().Parent = Player.Backpack
	end
end)

for _, part in pairs(Gun:GetDescendants()) do
	if part:IsA("MeshPart") or part:IsA("Part") then
		part.CanTouch = false
	end
end

local BlankPrompt = BlackMarket.Blank.Handle.BuyGun
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
	local leaderstats = Player:FindFirstChild("leaderstats")
	if not leaderstats then
		return
	end

	local Money = leaderstats:FindFirstChild("Money")
	if not Money then
		warn("Money Not found")
		return
	end

	if Money.Value >= Price.Value then
		Money.Value -= Price.Value

		local clone = BlankToClone:Clone()
		clone.Parent = Player.Backpack
	end
end)

-- Disable physical touching on display model
for _, part in pairs(Blank:GetDescendants()) do
	if part:IsA("MeshPart") or part:IsA("Part") then
		part.CanTouch = false
	end
end

local MarketplaceService = game:GetService("MarketplaceService")
local ProximityPromptService = game:GetService("ProximityPromptService")

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

			plr:FindFirstChild("leaderstats").Money.Value = plr:FindFirstChild("leaderstats").Money.Value + totalValue
			plr:FindFirstChild("hiddenstats").XP.Value = plr:FindFirstChild("hiddenstats").XP.Value + 28700

			plr.Character.DuffelBag:Destroy()
			plr.canrob.Value = false
		end
	end
end)
