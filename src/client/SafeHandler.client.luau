local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local client = require(ReplicatedStorage.BlinkEvents.client)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local safeGui = playerGui:WaitForChild("Safe")
local backpackFrame = safeGui.Frame.BackpackSF
local safeFrame = safeGui.Frame.SafeSF
local template = safeGui.Frame.PlaceHolderButton

local EventsList = {}

safeGui.Frame.CloseButton.Activated:Connect(function()
	safeGui.Enabled = false

	for index in pairs(EventsList) do
		EventsList[index]:Disconnect()
		EventsList[index] = nil
	end

	for _, item in backpackFrame:GetChildren() do
		if item:IsA("TextButton") then
			item:Destroy()
		end
	end

	for _, item in safeGui.Frame.SafeSF:GetChildren() do
		if item:IsA("TextButton") then
			item:Destroy()
		end
	end
end)

safeGui.AttributeChanged:Connect(function()
	if safeGui.enabled == false then
		return
	end

	for _, item in player.Backpack:GetChildren() do
		if item:IsA("Tool") then
			local newItem = template:Clone()
			newItem.Parent = backpackFrame
			newItem.Name = item.Name
			newItem.Text = item.Name
			newItem.visible = true
			EventsList[#EventsList + 1] = template.Activated:Connect(function()
				client.MoveSafeItem.Fire("Backpack", item.Name)
				newItem.Parent = safeFrame
			end)
		end
	end

	for _, item in player.Safe:GetChildren() do
		if item:IsA("Tool") then
			local newItem = template:Clone()
			newItem.Parent = safeFrame
			newItem.Name = item.Name
			newItem.Text = item.Name
			newItem.visible = true
			EventsList[#EventsList + 1] = template.Activated:Connect(function()
				client.MoveSafeItem.Fire("Safe", item.Name)
				newItem.Parent = backpackFrame
			end)
		end
	end
end)
