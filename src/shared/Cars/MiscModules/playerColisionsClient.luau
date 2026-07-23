local Players = game:GetService("Players")
local playerColisions = {}

local player = Players.LocalPlayer

local function seated(boolean)
	for _, plr: Player in Players:GetChildren() do
		if plr.Character then
			for _, part: Instance in plr.Character:GetChildren() do
				if part:IsA("BasePart") then
					part.CanCollide = not boolean
				end
			end
		end
	end
end

local function characterAdded(character)
	local humanoid = character:WaitForChild("Humanoid") :: Humanoid
	humanoid.Seated:Connect(seated)
end

function playerColisions.init()
	player.CharacterAdded:Connect(characterAdded)
end

return playerColisions
