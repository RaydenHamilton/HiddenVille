local gunWeld = {}
local ToolWelds = {}
function gunWeld.new(Tool)
	if Tool:isA("Tool") then
		local WeldName = "RightMotor6DGrip"

		local function Tool_Equipped()
			local plr_char = Tool.Parent
			if not plr_char then
				return
			end

			local Right_Arm = plr_char:FindFirstChild("RightHand")
			if not Right_Arm then
				return
			end

			local Right_GripW = Right_Arm:WaitForChild("RightGrip", 2)
			if not Right_GripW then
				return
			end

			local oldWeld = Right_Arm:FindFirstChild(WeldName)
			if oldWeld then
				oldWeld:Destroy()
			end

			local Right_Weld = Instance.new("Motor6D")
			Right_Weld.Part0 = Right_GripW.Part0
			Right_Weld.Part1 = Right_GripW.Part1
			Right_Weld.C0 = Right_GripW.C0
			Right_Weld.C1 = Right_GripW.C1
			Right_Weld.Parent = Right_Arm
			Right_Weld.Name = WeldName
			Right_GripW:Destroy()
			ToolWelds[Tool] = Right_Weld
		end

		local function Tool_Unequip()
			if ToolWelds[Tool] and ToolWelds[Tool].Parent then
				ToolWelds[Tool]:Destroy()
			end
			ToolWelds[Tool] = nil
		end

		Tool.Equipped:Connect(Tool_Equipped)
		Tool.Unequipped:Connect(Tool_Unequip)
	end
end

return gunWeld
