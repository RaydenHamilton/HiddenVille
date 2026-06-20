local MiscWeld = {}
function MiscWeld.new(car)
	local function MakeWeld(x, y, type, s)
		if type == nil then
			type = "Weld"
		end
		local W = Instance.new(type)
		W.Part0 = x
		W.Part1 = y
		W.C0 = x.CFrame:inverse() * x.CFrame
		W.C1 = y.CFrame:inverse() * x.CFrame
		W.Parent = x
		if type == "Motor" and s ~= nil then
			W.MaxVelocity = s
		end
		return W
	end
	local function ModelWeld(a, b)
		if a:IsA("BasePart") then
			MakeWeld(b, a, "Weld")
		elseif a:IsA("Model") then
			for _, v in pairs(a:GetChildren()) do
				ModelWeld(v, b)
			end
		end
	end

	car.DriveSeat.ChildAdded:connect(function(child)
		if
			child.Name == "SeatWeld"
			and child:IsA("Weld")
			and game.Players:GetPlayerFromCharacter(child.Part1.Parent) ~= nil
		then
			child.C0 = CFrame.new(0, -0.5, 0)
				* CFrame.fromEulerAnglesXYZ(-(math.pi / 2), 0, 0)
				* CFrame.Angles(math.rad(13), 0, 0)
		end
	end)
end
---------------------------
return MiscWeld
