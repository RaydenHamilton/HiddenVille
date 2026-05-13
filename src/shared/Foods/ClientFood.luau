local Players = game:GetService("Players")
local client = {}

local player = Players.LocalPlayer

function client.new(drink)
	drink:WaitForChild("Infos").Sips.Changed:Connect(function()
		local character = player.Character and player.CharacterAdded:Wait()
		if character.Stamina.Value <= 30 and character then
			character.Stamina.Value = character.Stamina.Value + 7
		end
	end)
end

return client
