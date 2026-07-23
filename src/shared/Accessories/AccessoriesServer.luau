local ReplicatedStorage = game:GetService("ReplicatedStorage")

local remotefunction = ReplicatedStorage.Remotes:WaitForChild("AddAccessorie")

local chain = {}

function chain.init()
	local function event(player: Player, value, tool)

		local character = player.Character or player.CharacterAdded:Wait()
		local name = tool.Name

		if not character:FindFirstChild(name) then
			if value[2] then
				local currentvest = value[1]:FindFirstChild("VestArmour")
				if currentvest then
					currentvest:Destroy()
				end

				for i, v in pairs(value[1]:GetChildren()) do
					if v.ClassName == "Accessory" then
						task.wait(0.1)

						if tool.Handle:FindFirstChild("Sound") then
							tool.Handle.Sound:Play()
						end
						if tool.Handle:FindFirstChildOfClass("BasePart") then
							tool.Handle.Part1.Transparency = 1
							tool.Handle.Part2.Transparency = 1
							tool.Handle.Part1.Decal.Transparency = 1
						end
					end
				end

				local vest = ReplicatedStorage.Accessories:FindFirstChild(name)
				if not vest then
					warn(`no_{name}`)
					return
				end
				local clone = vest:Clone()
				value[1].Humanoid:AddAccessory(clone)
				print("on")
			end
		else
			for _, v in pairs(value[1]:GetChildren()) do
				if v.ClassName == "Accessory" then
					v.Handle.Transparency = 0

					if tool.Handle:FindFirstChild("Sound") then
						tool.Handle.Sound:Play()
					end
					if tool.Handle:FindFirstChildOfClass("BasePart") then
						tool.Handle.Part1.Transparency = 0
						tool.Handle.Part2.Transparency = 0
						tool.Handle.Part1.Decal.Transparency = 0
					end
				end
			end
			for _, instance in player.Character:GetChildren() do
				if instance:IsA("Tool") then
					continue
				end
				if instance.Name == name then
					instance:Remove()
				end
			end
		end
	end
	remotefunction.OnServerEvent:Connect(event)
end

return chain
