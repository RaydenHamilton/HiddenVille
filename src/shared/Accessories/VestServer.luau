local Debris = game:GetService("Debris")

local vestServer = {}

function vestServer.new(tool)
	print("inited")
	tool.Equipped:Connect(function()
		print("start")
		local Player = tool.Parent
		local Humanoid = Player:FindFirstChild("Humanoid")
		if not Humanoid then
			print("no humanoid")
			return
		end

		for _, accessory in ipairs(Player:GetChildren()) do
			if accessory:IsA("Accessory") and accessory.Name == "_Vest" then
				print("alread")
				return
			end
		end

		local Safe = Instance.new("ForceField")
		Safe.Visible = false
		Safe.Parent = Player

		local vest = game.ServerStorage:FindFirstChild("_Vest")
		if vest then
			
			vest = vest:Clone()
			vest.Parent = workspace
			Humanoid:AddAccessory(vest)
		end

		local Number = tool.VestHealth:Clone()
		Number.Parent = Player

		tool.Handle.Open:Play()
		task.wait(0.7)
		tool.Plate.Transparency = 1
		tool.Handle.Close:Play()
		Debris:AddItem(Safe, 0.4)
		task.wait(0.4)

		Humanoid:UnequipTools()
	end)
end

return vestServer
