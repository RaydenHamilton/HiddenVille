local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local hiddenNametag = ReplicatedStorage.HiddenNametag

const maskShop = {}

const function isMask(child)
	if not child:IsA("Accessory") then
		return
	end

	if not CollectionService:HasTag(child, "Mask") then
		return
	end
	return true
end

const function isHat(child: Accessory)
	if
		child.AccessoryType == Enum.AccessoryType.Hair
		or child.AccessoryType == Enum.AccessoryType.Hat
		or child.AccessoryType == Enum.AccessoryType.Face
	then
		return true
	end
	return false
end

const function isFace(child: Accessory)
	if child.AccessoryType == Enum.AccessoryType.Face then
		return true
	end
	return false
end

const function changeNametag(character, tagName)
	local torso = character:FindFirstChild("UpperTorso")
	local hiddenTag = torso:FindFirstChild("HiddenNametag")
	hiddenTag.Enabled = hiddenTag.Name == tagName
	local Nametag = torso:FindFirstChild("Nametag")
	Nametag.Enabled = Nametag.Name == tagName
end

const function childAdded(child)
	if not isMask(child) then
		return
	end

	local func = isFace(child) and isFace or isHat

	if func(child) then
		for _, instance in child.Parent:GetChildren() do
			if instance:IsA("Accessory") and instance ~= child then
				if isMask(instance) then
					instance:Destroy()
				elseif func(instance) then
					local handle = instance:FindFirstChild("Handle")
					if handle then
						handle.Transparency = 1
					end
				end
			end
		end
		changeNametag(child.Parent, "HiddenNametag")
	end
end

const function childRemoved(child: Instance, character: Model)
	if not isMask(child) then
		return
	end
	changeNametag(character, "Nametag")
end

const function characterAdded(character: Model)
	task.wait(1)
	character.ChildAdded:Connect(childAdded)
	character.ChildRemoved:Connect(function(child: Instance)
		childRemoved(child, character)
	end)
	local tag = hiddenNametag:Clone()
	tag.Parent = character:WaitForChild("UpperTorso")
	tag.Adornee = character:WaitForChild("Head")
	tag.Enabled = false
	tag.StudsOffset = Vector3.new(0, 2.1, 0)
	tag:WaitForChild("Frame"):WaitForChild("Level").Text = Players:GetPlayerFromCharacter(character).UserId
end

const function playerAdded(player: Player)
	player.CharacterAdded:Connect(characterAdded)
	if player.Character then
		characterAdded(player.Character)
	end
end

function maskShop.init()
	Players.PlayerAdded:Connect(playerAdded)
	for _, player: Player in Players:GetChildren() do
		playerAdded(player)
	end
end

return maskShop
