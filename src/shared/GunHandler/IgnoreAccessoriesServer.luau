local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ignoreServer = {}

local function CharacterAdded(character: Model)
	task.wait(1.2)
	for _, instance in character:QueryDescendants("BasePart") do
		if instance.Parent ~= character then
			print(instance.Name)
			CollectionService:AddTag(instance, "NoShoot")
		end
	end
end

local function PlayerAdded(player: Player)
	if player.Character then
		CharacterAdded(player.Character)
	end
	player.CharacterAdded:Connect(CharacterAdded)
end

function ignoreServer.init()
	for _, player: Player in Players:GetChildren() do
		PlayerAdded(player)
	end
	Players.PlayerAdded:Connect(PlayerAdded)
end

return ignoreServer
