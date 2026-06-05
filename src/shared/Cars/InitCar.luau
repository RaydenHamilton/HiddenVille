local initCar = {}

initCar.new = function(car: Model)
	local module = car:FindFirstChild("A-Chassis Tune")
	--[[Weld functions]]

	local PGS_ON = workspace:PGSIsEnabled()

	function MakeWeld(x, y, type, s)
		if type == nil then
			type = "Weld"
		end
		local W = Instance.new(type)
		W.Part0 = x
		W.Part1 = y
		W.Parent = x
		W.C0 = x.CFrame:inverse() * x.CFrame
		W.C1 = y.CFrame:inverse() * x.CFrame
		if type == "Motor" and s ~= nil then
			W.MaxVelocity = s
		end
		return W
	end

	function ModelWeld(a, b)
		if a:IsA("BasePart") then
			MakeWeld(b, a, "Weld")
		elseif a:IsA("Model") then
			for i, v in pairs(a:GetChildren()) do
				ModelWeld(v, b)
			end
		end
	end

	function UnAnchor(a)
		if a:IsA("BasePart") then
			a.Anchored = false
		end
		for i, v in pairs(a:GetChildren()) do
			UnAnchor(v)
		end
	end

	--[[Initialize]]
	module:WaitForChild("A-Chassis Interface")
	module:WaitForChild("Plugins")
	module:WaitForChild("README")

	local interface = module:WaitForChild("A-Chassis Interface", 8)
	if not interface then
		warn("A-Chassis Interface not found!")
		return
	end

	local sitting = interface:WaitForChild("Sitting", 8)
	if not sitting then
		warn("Sitting not found!")
		return
	end

	local parked = interface:FindFirstChild("Parked")
	local driveSeat = car:WaitForChild("DriveSeat", 8)
	local billboard = driveSeat:WaitForChild("Billboard", 8)
	local locked = car:WaitForChild("Locked", 8)
	local proximityPrompt = driveSeat:WaitForChild("Sit", 8)

	local countdownTime = 120
	local countdownRunning = false
	local countdownCoroutine
	local stopCountdownFlag = false

	local _Tune = require(module)

	task.wait(_Tune.LoadDelay)

	--Weight Scaling
	local weightScaling = _Tune.WeightScaling
	if not workspace:PGSIsEnabled() then
		weightScaling = _Tune.LegacyScaling
	end

	local Drive = car.Wheels:GetChildren()

	--Remove Existing Mass
	function DReduce(p)
		for i, v in pairs(p:GetChildren()) do
			if v:IsA("BasePart") then
				if v.CustomPhysicalProperties == nil then
					v.CustomPhysicalProperties = PhysicalProperties.new(v.Material)
				end
				v.CustomPhysicalProperties = PhysicalProperties.new(
					0.0001,
					v.CustomPhysicalProperties.Friction,
					v.CustomPhysicalProperties.Elasticity,
					v.CustomPhysicalProperties.FrictionWeight,
					v.CustomPhysicalProperties.ElasticityWeight
				)
			end
			DReduce(v)
		end
	end
	DReduce(car)

	local function startCountdown(time)
		if countdownRunning then
			return
		end
		countdownRunning = true
		stopCountdownFlag = false

		countdownCoroutine = coroutine.create(function()
			for i = time, 0, -1 do
				if stopCountdownFlag then
					countdownRunning = false
					billboard.TextLabel.Text = ""
					billboard.Enabled = false
					return
				end

				while sitting.Value or locked.Value or (parked and parked.Value) do
					billboard.Enabled = false
					task.wait(1)

					if stopCountdownFlag then
						countdownRunning = false
						billboard.TextLabel.Text = ""
						billboard.Enabled = false
						return
					end
				end

				if i == 0 then
					task.wait(0.5)
					billboard.TextLabel.Text = "Deleting Car..."
					if _G.hookCarRemove then
						_G.hookCarRemove(car)
					end
					countdownRunning = false
					return
				else
					billboard.TextLabel.Text = "Deleting Car in " .. i .. " Seconds"
					billboard.Enabled = true
					task.wait(1)
				end
			end
		end)

		coroutine.resume(countdownCoroutine)
	end

	local function stopCountdown()
		if countdownRunning then
			countdownRunning = false
			billboard.Enabled = false
			stopCountdownFlag = true
		end
	end

	--[[Wheel Configuration]]

	--Store Reference Orientation Function
	function getParts(model, t, a)
		for i, v in pairs(model:GetChildren()) do
			if v:IsA("BasePart") then
				table.insert(t, { v, a.CFrame:toObjectSpace(v.CFrame) })
			elseif v:IsA("Model") then
				getParts(v, t, a)
			end
		end
	end

	--PGS/Legacy
	local fDensity = _Tune.FWheelDensity
	local rDensity = _Tune.RWheelDensity
	if not PGS_ON then
		fDensity = _Tune.FWLgcyDensity
		rDensity = _Tune.RWLgcyDensity
	end

	local fDistX = _Tune.FWsBoneLen * math.cos(math.rad(_Tune.FWsBoneAngle))
	local fDistY = _Tune.FWsBoneLen * math.sin(math.rad(_Tune.FWsBoneAngle))
	local rDistX = _Tune.RWsBoneLen * math.cos(math.rad(_Tune.RWsBoneAngle))
	local rDistY = _Tune.RWsBoneLen * math.sin(math.rad(_Tune.RWsBoneAngle))

	local fSLX = _Tune.FSusLength * math.cos(math.rad(_Tune.FSusAngle))
	local fSLY = _Tune.FSusLength * math.sin(math.rad(_Tune.FSusAngle))
	local rSLX = _Tune.RSusLength * math.cos(math.rad(_Tune.RSusAngle))
	local rSLY = _Tune.RSusLength * math.sin(math.rad(_Tune.RSusAngle))

	for _, v in pairs(Drive) do
		--Apply Wheel Density
		if v.Name == "FL" or v.Name == "FR" or v.Name == "F" then
			if v:IsA("BasePart") then
				if v.CustomPhysicalProperties == nil then
					v.CustomPhysicalProperties = PhysicalProperties.new(v.Material)
				end
				v.CustomPhysicalProperties = PhysicalProperties.new(
					fDensity,
					v.CustomPhysicalProperties.Friction,
					v.CustomPhysicalProperties.Elasticity,
					v.CustomPhysicalProperties.FrictionWeight,
					v.CustomPhysicalProperties.ElasticityWeight
				)
			end
		else
			if v:IsA("BasePart") then
				if v.CustomPhysicalProperties == nil then
					v.CustomPhysicalProperties = PhysicalProperties.new(v.Material)
				end
				v.CustomPhysicalProperties = PhysicalProperties.new(
					rDensity,
					v.CustomPhysicalProperties.Friction,
					v.CustomPhysicalProperties.Elasticity,
					v.CustomPhysicalProperties.FrictionWeight,
					v.CustomPhysicalProperties.ElasticityWeight
				)
			end
		end

		--Resurface Wheels
		for _, a in pairs({ "Top", "Bottom", "Left", "Right", "Front", "Back" }) do
			v[a .. "Surface"] = Enum.SurfaceType.SmoothNoOutlines
		end

		--Store Axle-Anchored/Suspension-Anchored Part Orientation
		local WParts = {}

		local tPos = v.Position - car.DriveSeat.Position
		if v.Name == "FL" or v.Name == "RL" then
			v.CFrame = car.DriveSeat.CFrame * CFrame.Angles(math.rad(90), 0, math.rad(90))
		else
			v.CFrame = car.DriveSeat.CFrame * CFrame.Angles(math.rad(90), 0, math.rad(-90))
		end
		v.CFrame = v.CFrame + tPos

		if v:FindFirstChild("Parts") ~= nil then
			getParts(v.Parts, WParts, v)
		end
		if v:FindFirstChild("Fixed") ~= nil then
			getParts(v.Fixed, WParts, v)
		end

		--Align Wheels
		if v.Name == "FL" or v.Name == "FR" then
			v.CFrame = v.CFrame * CFrame.Angles(math.rad(_Tune.FCamber), 0, 0)
			if v.Name == "FL" then
				v.CFrame = v.CFrame * CFrame.Angles(0, 0, math.rad(_Tune.FToe))
			else
				v.CFrame = v.CFrame * CFrame.Angles(0, 0, math.rad(-_Tune.FToe))
			end
		elseif v.Name == "RL" or v.Name == "RR" then
			v.CFrame = v.CFrame * CFrame.Angles(math.rad(_Tune.RCamber), 0, 0)
			if v.Name == "RL" then
				v.CFrame = v.CFrame * CFrame.Angles(0, 0, math.rad(_Tune.RToe))
			else
				v.CFrame = v.CFrame * CFrame.Angles(0, 0, math.rad(-_Tune.RToe))
			end
		end

		--Re-orient Axle-Anchored/Suspension-Anchored Parts
		for _, a in pairs(WParts) do
			a[1].CFrame = v.CFrame:toWorldSpace(a[2])
		end

		--[[Chassis Assembly]]
		--Create Steering Axle
		local arm = Instance.new("Part", v)
		arm.Name = "Arm"
		arm.Anchored = true
		arm.CanCollide = false
		arm.FormFactor = Enum.FormFactor.Custom
		arm.Size = Vector3.new(_Tune.AxleSize, _Tune.AxleSize, _Tune.AxleSize)
		arm.CFrame = (v.CFrame * CFrame.new(0, _Tune.StAxisOffset, 0)) * CFrame.Angles(-math.pi / 2, -math.pi / 2, 0)
		arm.CustomPhysicalProperties = PhysicalProperties.new(_Tune.AxleDensity, 0, 0, 100, 100)
		arm.TopSurface = Enum.SurfaceType.Smooth
		arm.BottomSurface = Enum.SurfaceType.Smooth
		arm.Transparency = 1

		--Create Wheel Spindle
		local base = arm:Clone()
		base.Parent = v
		base.Name = "Base"
		base.CFrame = base.CFrame * CFrame.new(0, _Tune.AxleSize, 0)
		base.BottomSurface = Enum.SurfaceType.Hinge

		--Create Steering Anchor
		local axle = arm:Clone()
		axle.Parent = v
		axle.Name = "Axle"
		axle.CFrame = CFrame.new(
			v.Position
				- ((v.CFrame * CFrame.Angles(math.pi / 2, 0, 0)).lookVector * ((v.Size.x / 2) + (axle.Size.x / 2))),
			v.Position
		) * CFrame.Angles(0, math.pi, 0)
		axle.BackSurface = Enum.SurfaceType.Hinge

		if v.Name == "F" or v.Name == "R" then
			local axle2 = arm:Clone()
			axle2.Parent = v
			axle2.Name = "Axle"
			axle2.CFrame = CFrame.new(
				v.Position
					+ ((v.CFrame * CFrame.Angles(math.pi / 2, 0, 0)).lookVector * ((v.Size.x / 2) + (axle2.Size.x / 2))),
				v.Position
			) * CFrame.Angles(0, math.pi, 0)
			axle2.BackSurface = Enum.SurfaceType.Hinge
			MakeWeld(arm, axle2)
		end

		--Create Suspension
		if PGS_ON and _Tune.SusEnabled then
			local sa = arm:Clone()
			sa.Parent = v
			sa.Name = "#SA"
			if v.Name == "FL" or v.Name == "FR" or v.Name == "F" then
				local aOff = _Tune.FAnchorOffset
				sa.CFrame = v.CFrame
					* CFrame.new(_Tune.AxleSize / 2, -fDistX, -fDistY)
					* CFrame.new(aOff[3], aOff[1], -aOff[2])
					* CFrame.Angles(-math.pi / 2, -math.pi / 2, 0)
			else
				local aOff = _Tune.RAnchorOffset
				sa.CFrame = v.CFrame
					* CFrame.new(_Tune.AxleSize / 2, -rDistX, -rDistY)
					* CFrame.new(aOff[3], aOff[1], -aOff[2])
					* CFrame.Angles(-math.pi / 2, -math.pi / 2, 0)
			end

			local sb = sa:Clone()
			sb.Parent = v
			sb.Name = "#SB"
			sb.CFrame = sa.CFrame * CFrame.new(0, 0, _Tune.AxleSize)

			sb.FrontSurface = Enum.SurfaceType.Hinge

			local g = Instance.new("BodyGyro", sb)
			g.Name = "Stabilizer"
			g.MaxTorque = Vector3.new(0, 0, 1)
			g.P = 0

			local sf1 = Instance.new("Attachment", sa)
			sf1.Name = "SAtt"

			local sf2 = sf1:Clone()
			sf2.Parent = sb

			if v.Name == "FL" or v.Name == "FR" or v.Name == "F" then
				sf1.Position = Vector3.new(fDistX - fSLX, -fDistY + fSLY, _Tune.AxleSize / 2)
				sf2.Position = Vector3.new(fDistX, -fDistY, -_Tune.AxleSize / 2)
			elseif v.Name == "RL" or v.Name == "RR" or v.Name == "R" then
				sf1.Position = Vector3.new(rDistX - rSLX, -rDistY + rSLY, _Tune.AxleSize / 2)
				sf2.Position = Vector3.new(rDistX, -rDistY, -_Tune.AxleSize / 2)
			end

			sb:MakeJoints()

			local sp = Instance.new("SpringConstraint", v)
			sp.Name = "Spring"
			sp.Attachment0 = sf1
			sp.Attachment1 = sf2
			sp.LimitsEnabled = true

			sp.Visible = _Tune.SusVisible
			sp.Radius = _Tune.SusRadius
			sp.Thickness = _Tune.SusThickness
			sp.Color = BrickColor.new(_Tune.SusColor)
			sp.Coils = _Tune.SusCoilCount

			if v.Name == "FL" or v.Name == "FR" or v.Name == "F" then
				g.D = _Tune.FAntiRoll or 0
				sp.Damping = _Tune.FSusDamping
				sp.Stiffness = _Tune.FSusStiffness
				sp.FreeLength = _Tune.FSusLength or 0 + _Tune.FPreCompress or 0
				sp.MaxLength = _Tune.FSusLength or 0 + _Tune.FExtensionLim or 0
				sp.MinLength = _Tune.FSusLength or 0 - _Tune.FCompressLim or 0
			else
				-- g.D = _Tune.RAntiRoll
				sp.Damping = _Tune.RSusDamping
				sp.Stiffness = _Tune.RSusStiffness
				sp.FreeLength = _Tune.RSusLength or 0 + _Tune.RPreCompressd or 0
				sp.MaxLength = _Tune.RSusLength or 0 + _Tune.RExtensionLim or 0
				sp.MinLength = _Tune.RSusLength or 0 - _Tune.RCompressLim or 0
			end

			MakeWeld(car.DriveSeat, sa)
			MakeWeld(sb, base)
		else
			MakeWeld(car.DriveSeat, base)
		end

		--Lock Rear Steering Axle
		if v.Name == "RL" or v.Name == "RR" or v.Name == "R" then
			MakeWeld(base, axle)
		end

		--Weld Assembly
		if v.Parent.Name == "RL" or v.Parent.Name == "RR" or v.Name == "R" then
			MakeWeld(car.DriveSeat, arm)
		end

		MakeWeld(arm, axle)

		arm:MakeJoints()
		axle:MakeJoints()

		--Weld Miscelaneous Parts
		if v:FindFirstChild("SuspensionFixed") ~= nil then
			ModelWeld(v.SuspensionFixed, car.DriveSeat)
		end
		if v:FindFirstChild("WheelFixed") ~= nil then
			ModelWeld(v.WheelFixed, axle)
		end
		if v:FindFirstChild("Fixed") ~= nil then
			ModelWeld(v.Fixed, arm)
		end

		--Weld Wheel Parts
		if v:FindFirstChild("Parts") ~= nil then
			ModelWeld(v.Parts, v)
		end

		--Add Steering Gyro
		if v:FindFirstChild("Steer") then
			v:FindFirstChild("Steer"):Destroy()
		end

		if v.Name == "FL" or v.Name == "FR" or v.Name == "F" then
			local steer = Instance.new("BodyGyro", arm)
			steer.Name = "Steer"
			steer.P = _Tune.SteerP
			steer.D = _Tune.SteerD
			steer.MaxTorque = Vector3.new(0, _Tune.SteerMaxTorque, 0)
			steer.cframe = v.CFrame * CFrame.Angles(0, -math.pi / 2, 0)
		end

		--Add Stabilization Gyro
		local gyro = Instance.new("BodyGyro", v)
		gyro.Name = "Stabilizer"
		gyro.MaxTorque = Vector3.new(1, 0, 1)
		gyro.P = 0
		if v.Name == "FL" or v.Name == "FR" or v.Name == "F" then
			gyro.D = _Tune.FGyroDamp
		else
			gyro.D = _Tune.RGyroDamp
		end

		--Add Rotational BodyMover
		local AV = Instance.new("BodyAngularVelocity", v)
		AV.Name = "#AV"
		AV.angularvelocity = Vector3.new(0, 0, 0)
		AV.maxTorque = Vector3.new(_Tune.PBrakeForce, 0, _Tune.PBrakeForce)
		AV.P = 1e9
	end

	--[[Vehicle Weight]]
	--Determine Current Mass
	local mass = 0

	function getMass(p)
		for i, v in pairs(p:GetChildren()) do
			if v:IsA("BasePart") then
				mass = mass + v:GetMass()
			end
			getMass(v)
		end
	end
	getMass(car)

	--Apply Vehicle Weight
	if mass < _Tune.Weight * weightScaling then
		--Calculate Weight Distribution
		local centerF = Vector3.new()
		local centerR = Vector3.new()
		local countF = 0
		local countR = 0

		for i, v in pairs(Drive) do
			if v.Name == "FL" or v.Name == "FR" or v.Name == "F" then
				centerF = centerF + v.CFrame.p
				countF = countF + 1
			else
				centerR = centerR + v.CFrame.p
				countR = countR + 1
			end
		end
		centerF = centerF / countF
		centerR = centerR / countR
		local center = centerR:Lerp(centerF, _Tune.WeightDist / 100)

		--Create Weight Brick
		local weightB = Instance.new("Part", car.Body)
		weightB.Name = "#Weight"
		weightB.Anchored = true
		weightB.CanCollide = false
		weightB.BrickColor = BrickColor.new("Really black")
		weightB.TopSurface = Enum.SurfaceType.Smooth
		weightB.BottomSurface = Enum.SurfaceType.Smooth
		if _Tune.WBVisible then
			weightB.Transparency = 0.75
		else
			weightB.Transparency = 1
		end
		weightB.Size = Vector3.new(_Tune.WeightBSize[1], _Tune.WeightBSize[2], _Tune.WeightBSize[3])
		weightB.CustomPhysicalProperties = PhysicalProperties.new(
			((_Tune.Weight * weightScaling) - mass) / (weightB.Size.x * weightB.Size.y * weightB.Size.z),
			0,
			0,
			0,
			0
		)
		weightB.CFrame = (car.DriveSeat.CFrame - car.DriveSeat.Position + center) * CFrame.new(0, _Tune.CGHeight, 0)
	else
		--Existing Weight Is Too Massive
		warn(
			"\n\t [AC"
				.. "]: Mass too high for specified weight."
				.. "\n\t    Target Mass:\t"
				.. (math.ceil(_Tune.Weight * weightScaling * 100) / 100)
				.. "\n\t    Current Mass:\t"
				.. (math.ceil(mass * 100) / 100)
				.. "\n\t Reduce part size or axle density to achieve desired weight."
		)
	end

	local flipG = Instance.new("BodyGyro", car.DriveSeat)
	flipG.Name = "Flip"
	flipG.D = 0
	flipG.MaxTorque = Vector3.new(0, 0, 0)
	flipG.P = 0

	--[[Finalize Chassis]]
	--Misc Weld

	task.wait()
	ModelWeld(car.Body, car.DriveSeat)

	--Unanchor
	task.wait()
	UnAnchor(car)

	--[[Manage Plugins]]

	module["A-Chassis Interface"].Car.Value = car
	for i, v in pairs(module.Plugins:GetChildren()) do
		for _, a in pairs(v:GetChildren()) do
			if a:IsA("RemoteEvent") or a:IsA("RemoteFunction") then
				a.Parent = car
				for _, b in pairs(a:GetChildren()) do
					if b:IsA("Script") then
						b.Disabled = false
					end
				end
			end
		end
		v.Parent = module["A-Chassis Interface"]
	end
	module.Plugins:Destroy()

	--[[Remove Character Weight]]
	--Get Seats
	local Seats = {}
	function getSeats(p)
		for i, v in pairs(p:GetChildren()) do
			if v:IsA("VehicleSeat") or v:IsA("Seat") then
				local seat = {}
				seat.Seat = v
				seat.Parts = {}
				table.insert(Seats, seat)
			end
			getSeats(v)
		end
	end
	getSeats(car)

	--Store Physical Properties/Remove Mass Function
	function getPProperties(mod, t)
		for i, v in pairs(mod:GetChildren()) do
			if v:IsA("BasePart") then
				if v.CustomPhysicalProperties == nil then
					v.CustomPhysicalProperties = PhysicalProperties.new(v.Material)
				end
				table.insert(t, { v, v.CustomPhysicalProperties })
				v.CustomPhysicalProperties = PhysicalProperties.new(
					0.0001,
					v.CustomPhysicalProperties.Friction,
					v.CustomPhysicalProperties.Elasticity,
					v.CustomPhysicalProperties.FrictionWeight,
					v.CustomPhysicalProperties.ElasticityWeight
				)
			end
			getPProperties(v, t)
		end
	end

	--Apply Seat Handler
	for i, v in pairs(Seats) do
		--Sit Handler
		v.Seat.ChildAdded:connect(function(child)
			if
				child.Name == "SeatWeld"
				and child:IsA("Weld")
				and child.Part1 ~= nil
				and child.Part1.Parent ~= workspace
				and not child.Part1.Parent:IsDescendantOf(car)
			then
				v.Parts = {}
				getPProperties(child.Part1.Parent, v.Parts)
			end
		end)

		--Leave Handler
		v.Seat.ChildRemoved:connect(function(child)
			if child.Name == "SeatWeld" and child:IsA("Weld") then
				for i, v in pairs(v.Parts) do
					if v[1] ~= nil and v[2] ~= nil and v[1]:IsDescendantOf(workspace) then
						v[1].CustomPhysicalProperties = v[2]
					end
				end
				v.Parts = {}
			end
		end)
	end

	--[[Driver Handling]]

	--Driver Sit
	car.DriveSeat.ChildAdded:connect(function(child)
		if
			child.Name == "SeatWeld"
			and child:IsA("Weld")
			and game.Players:GetPlayerFromCharacter(child.Part1.Parent) ~= nil
		then
			local p = game.Players:GetPlayerFromCharacter(child.Part1.Parent)

			for _, part in ipairs(car.Body:GetDescendants()) do
				if part:IsA("BasePart") then
					part.Anchored = false
				end
			end

			local g = module["A-Chassis Interface"]:Clone()
			g.Parent = p.PlayerGui

			stopCountdown()

			car.DriveSeat:SetNetworkOwner(p)
		end
	end)

	driveSeat.ChildRemoved:Connect(function(child)
		if child.Name == "SeatWeld" and child:IsA("Weld") then
			local p = game.Players:GetPlayerFromCharacter(child.Part1.Parent)
			if p and p:FindFirstChild("PlayerGui") then
				local gui = p.PlayerGui
				if gui:FindFirstChild("Interface") then
					gui.Interface:Destroy()
				end
				if gui:FindFirstChild("CarGui") then
					gui.CarGui:Destroy()
				end
			end

			if driveSeat:FindFirstChild("Flip") then
				driveSeat.Flip.MaxTorque = Vector3.new()
			end

			if p and p.Character:FindFirstChild("InCar") then
				p.Character.InCar.Value = false
			end
			sitting.Value = false

			if proximityPrompt then
				proximityPrompt.Enabled = true
			end

			for _, wheel in ipairs(car.Wheels:GetChildren()) do
				local av = wheel:FindFirstChild("#AV")
				if av then
					if av:IsA("BodyAngularVelocity") then
						av.AngularVelocity = Vector3.zero
						av.MaxTorque = Vector3.zero
					else
						av.AngularVelocity = 0
						av.MotorMaxTorque = 0
					end
				end
			end

			task.spawn(function()
				task.wait(3)
				if not driveSeat.Occupant then
					for _, part in ipairs(car.Body:GetChildren()) do
						if
							(part:IsA("BasePart") or part:IsA("UnionOperation"))
							and not table.find({ "FRONT", "Drag", "DownforceR", "DownforceF" }, part.Name)
						then
							part.Anchored = false
						end
					end
				end
			end)

			if parked and not parked.Value then
				startCountdown(countdownTime)
			end
		end
	end)

	local removedTools = {}

	for _, seat in ipairs(car.Body:GetChildren()) do
		if seat:IsA("VehicleSeat") or seat:IsA("Seat") then
			local SeatClone = module:FindFirstChild("Sit"):Clone()
			SeatClone.Parent = seat

			SeatClone.Triggered:Connect(function(player)
				if seat:FindFirstChild("Locked") then
					game:GetService("ReplicatedStorage")
						:FindFirstChild("Notify")
						:FireClient(player, "Vehicle is locked.", 2)
					return
				end

				local character = player.Character or player.CharacterAdded:Wait() :: Model
				local humanoid = character:FindFirstChildWhichIsA("Humanoid")
				if character:GetAttribute("Ragdoll") or not humanoid or humanoid.Sit or seat.Occupant then
					return
				end
				character.HumanoidRootPart.CollisionGroup = "Car"

				removedTools[player.UserId] = {}
				for _, toolName in ipairs({ "Fist", "Admin Fist", "Boxing Gloves" }) do
					local backpackTool = player.Backpack:FindFirstChild(toolName)
					if backpackTool then
						table.insert(removedTools[player.UserId], backpackTool:Clone())
						backpackTool:Destroy()
					end

					local charTool = character:FindFirstChild(toolName)
					if charTool then
						table.insert(removedTools[player.UserId], charTool:Clone())
						charTool:Destroy()
					end
				end

				seat:Sit(humanoid)
			end)

			seat:GetPropertyChangedSignal("Occupant"):Connect(function()
				local occupant = seat.Occupant

				if occupant == nil then
					for _, player in ipairs(game.Players:GetPlayers()) do
						local character = player.Character
						if character and character:FindFirstChildWhichIsA("Humanoid") then
							if removedTools[player.UserId] then
								task.wait()
								local root: Model = player.Character
								root:PivotTo(seat.CFrame * CFrame.new(seat.Name == "BackL" and -5 or 5, 0, 0))
								character.HumanoidRootPart.CollisionGroup = "Player"
								for _, tool in ipairs(removedTools[player.UserId]) do
									if tool then
										tool.Parent = player.Backpack
									end
								end
								removedTools[player.UserId] = nil
							end
						end
					end
				end
			end)
		end
	end

	sitting.Changed:Connect(function()
		if sitting.Value then
			stopCountdown()
		else
			if not countdownRunning and not locked.Value and not parked.Value then
				startCountdown(countdownTime)
			end
		end
	end)

	locked.Changed:Connect(function()
		if locked.Value then
			stopCountdown()
			for _, part in ipairs(car.Body:GetDescendants()) do
				if part:IsA("BasePart") then
					part.Anchored = false
				end
			end
		else
			if not countdownRunning and not sitting.Value and not parked.Value then
				startCountdown(countdownTime)
				for _, part in ipairs(car.Body:GetDescendants()) do
					if part:IsA("BasePart") then
						part.Anchored = false
					end
				end
			end
		end
	end)

	if parked then
		parked:GetPropertyChangedSignal("Value"):Connect(function()
			if parked.Value then
				stopCountdown()
			else
				if not countdownRunning and not sitting.Value and not locked.Value then
					startCountdown(countdownTime)
				end
			end
		end)
	end

	local carDestroyed = false
	local carOnFire = false

	local function getPlayersInCar()
		local players = {}

		for _, player in ipairs(game.Players:GetPlayers()) do
			local character = player.Character
			local humanoid = character and character:FindFirstChildWhichIsA("Humanoid")

			if humanoid and humanoid.Sit and humanoid.SeatPart then
				if humanoid.SeatPart:IsDescendantOf(car) then
					table.insert(players, player)
				end
			end
		end

		return players
	end

	local function destroyCar()
		if carDestroyed then
			return
		end
		carDestroyed = true
		carOnFire = true

		if car.Body and car.Body.FRONT then
			if car.Body.FRONT:FindFirstChild("Smoke") then
				car.Body.FRONT.Smoke.Enabled = true
			end
			if car.Body.FRONT:FindFirstChild("Fire") then
				car.Body.FRONT.Fire.Enabled = true
			end
		end

		startCountdown(15)

		task.spawn(function()
			while car and car.Parent do
				if carOnFire then
					for _, player in ipairs(getPlayersInCar()) do
						local humanoid = player.Character and player.Character:FindFirstChildWhichIsA("Humanoid")
						if humanoid and humanoid.Health > 0 then
							humanoid:TakeDamage(20)
						end
					end
				end
				task.wait(0.5)
			end
		end)

		task.delay(15, function()
			if car and car.Parent then
				car:Destroy()
			end
		end)
	end

	local carHealth = car:WaitForChild("Health")
	carHealth:GetPropertyChangedSignal("Value"):Connect(function()
		if not carDestroyed and carHealth.Value <= 0 then
			destroyCar()
		end
	end)
end

return initCar
