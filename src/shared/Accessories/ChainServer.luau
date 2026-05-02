local ReplicatedStorage = game:GetService("ReplicatedStorage")

local remotefunction = ReplicatedStorage.Remotes:WaitForChild("AddAccessorie")

function remotefunction.OnServerInvoke(player: Player, command, value)
	local tool = player.Character:FindFirstChildOfClass("Tool")
	local name = tool.Name

	name = name:gsub("^Girl ", "")

	if command == "protect" then
		if value[2] then
			local currentvest = value[1]:FindFirstChild("VestArmour")
			if currentvest then
				currentvest:Destroy()
			end

			for i, v in pairs(value[1]:GetChildren()) do
				if v.ClassName == "Accessory" then
					task.wait(0.1)
					tool.Handle.Sound:Play()
					tool.Handle.Part1.Transparency = 1
					tool.Handle.Part2.Transparency = 1
					tool.Handle.Part1.Decal.Transparency = 1
				end
			end

			local vest = ReplicatedStorage.Chains[name]:Clone()
			value[1].Humanoid:AddAccessory(vest)
		end
	elseif command == "unprotect" then
		for _, v in pairs(value[1]:GetChildren()) do
			if v.ClassName == "Accessory" then
				v.Handle.Transparency = 0
				tool.Handle.Sound:Play() -- hides other hats
				tool.Handle.Part1.Transparency = 0
				tool.Handle.Part2.Transparency = 0
				tool.Handle.Part1.Decal.Transparency = 0
			end
		end
		player.Character[name]:Remove()
	end
end

return nil
