local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

local Gui = ServerStorage:WaitForChild("CarDealerGui")

Workspace.NPCs:WaitForChild("Dealership NPC").HumanoidRootPart.CarDealer.Triggered:Connect(function(player)
	local GuiClone = Gui:Clone()
	GuiClone.Parent = player.PlayerGui
	--GuiClone.DealershipClient.Enabled = true
end)
