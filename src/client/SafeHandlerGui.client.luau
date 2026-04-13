local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local client = require(ReplicatedStorage.BlinkEvents.client)
local SafeWhiteBlackList = require(ReplicatedStorage.Shared.Settings.SafeBlackList)

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

safeGui.Changed:Connect(function(theChange)
	if safeGui.enabled == false or theChange ~= "Enabled" then
		return
	end

	for _, item in player.Backpack:GetChildren() do
		if item:IsA("Tool") and not table.find(SafeWhiteBlackList, item.Name) then
			local newItem = template:Clone()
			newItem.Parent = backpackFrame
			newItem.Name = item.Name
			newItem.Text = item.Name
			newItem.Visible = true
			EventsList[#EventsList + 1] = newItem.Activated:Connect(function()
				local Position = item.Parent == player.Backpack and "Backpack" or "Safe"
				client.MoveSafeItem.Fire(Position, item.Name)
				if Position == "Backpack" then
					newItem.Parent = safeFrame
				else
					newItem.Parent = backpackFrame
				end
			end)
		end
	end

	for _, item in player.Safe:GetChildren() do
		if item:IsA("Tool") then
			local newItem = template:Clone()
			newItem.Parent = safeFrame
			newItem.Name = item.Name
			newItem.Text = item.Name
			newItem.Visible = true
			EventsList[#EventsList + 1] = newItem.Activated:Connect(function()
				local Position = item.Parent == player.Backpack and "Backpack" or "Safe"

				client.MoveSafeItem.Fire(Position, item.Name)
				if Position == "Backpack" then
					newItem.Parent = safeFrame
				else
					newItem.Parent = backpackFrame
				end
			end)
		end
	end
end)

for _, door in pairs(Workspace.OwnedDoors:GetChildren()) do
	local safePrompt = door:WaitForChild("Safe").Door.ProximityPrompt
	safePrompt.Triggered:Connect(function()
		local ownerValue = door:WaitForChild("Owner")

		local isOwner = ownerValue.Value == player
		local isOwned = ownerValue.Value ~= nil

		if isOwned and isOwner then
			player.PlayerGui:WaitForChild("Safe").Enabled = true
		end
	end)
end

