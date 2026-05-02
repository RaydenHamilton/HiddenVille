local Players = game:GetService("Players")
local goldValue
local gamepass
local gui
local frame
local label
local bar

local function updateDisplay()
	local gold = goldValue.Value
	local hasGamepass = gamepass.Value
	local maxGold = hasGamepass and 10 or 5

	label.Text = tostring(gold) .. "/" .. tostring(maxGold)
	bar.Size = UDim2.fromScale(gold / maxGold, 1)
end

Players.PlayerAdded:Connect(function(player: Player)
	player.CharacterAdded:Connect(function(character: Model)
		character.ChildAdded:Connect(function(bag: Instance)
			if bag.Name == "DuffelBag" then
				goldValue = bag:WaitForChild("goldvalue")
				gamepass = bag:WaitForChild("gamepass")
				gui = bag:WaitForChild("guipart"):WaitForChild("SurfaceGui")
				frame = gui:WaitForChild("Frame")
				label = frame:WaitForChild("TextLabel")
				bar = frame:WaitForChild("greenbar")
				updateDisplay()
				goldValue.Changed:Connect(updateDisplay)
				gamepass.Changed:Connect(updateDisplay)
			end
		end)
	end)
end)
