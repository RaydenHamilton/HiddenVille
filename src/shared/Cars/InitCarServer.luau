local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local initCar = {}

local function getParts(model, t, a)
	for _, v in pairs(model:GetChildren()) do
		if v:IsA("BasePart") then
			table.insert(t, { v, a.CFrame:toObjectSpace(v.CFrame) })
		elseif v:IsA("Model") then
			getParts(v, t, a)
		end
	end
end

local function DReduce(p)
	for _, v in pairs(p:GetChildren()) do
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

local function MakeWeld(x, y, type, s)
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

local function ModelWeld(a, b)
	if a:IsA("BasePart") then
		MakeWeld(b, a, "Weld")
	elseif a:IsA("Model") then
		for _, v in pairs(a:GetChildren()) do
			ModelWeld(v, b)
		end
	end
end

local function UnAnchor(a)
	if a:IsA("BasePart") then
		a.Anchored = false
	end
	for _, v in pairs(a:GetChildren()) do
		UnAnchor(v)
	end
end

initCar.new = function(car: Model)
	local connections = {}
	--[[Weld functions]]
	local PGS_ON = Workspace:PGSIsEnabled()

	--[[Initialize]]
	local module = car:WaitForChild("A-Chassis Tune")

	local _Tune = require(module)
	local wheels = car:WaitForChild("Wheels")
	local body = car:WaitForChild("Body")
	local driveSeat = car:WaitForChild("DriveSeat")

	task.wait(_Tune.LoadDelay)

	--Weight Scaling
	local weightScaling = _Tune.WeightScaling
	if not Workspace:PGSIsEnabled() then
		weightScaling = _Tune.LegacyScaling
	end

	local Drive = wheels:GetChildren()

	--Remove Existing Mass
	DReduce(car)

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
		if v:IsA("BasePart") then
			if v.CustomPhysicalProperties == nil then
				v.CustomPhysicalProperties = PhysicalProperties.new(v.Material)
			end
			v.CustomPhysicalProperties = PhysicalProperties.new(
				(v.Name == "FL" or v.Name == "FR") and fDensity or rDensity,
				v.CustomPhysicalProperties.Friction,
				v.CustomPhysicalProperties.Elasticity,
				v.CustomPhysicalProperties.FrictionWeight,
				v.CustomPhysicalProperties.ElasticityWeight
			)
		end

		--Resurface Wheels
		for _, a in pairs({ "Top", "Bottom", "Left", "Right", "Front", "Back" }) do
			v[a .. "Surface"] = Enum.SurfaceType.SmoothNoOutlines
		end

		--Store Axle-Anchored/Suspension-Anchored Part Orientation
		local WParts = {}

		local tPos = v.Position - driveSeat.Position
		if v.Name == "FL" or v.Name == "RL" then
			v.CFrame = driveSeat.CFrame * CFrame.Angles(math.rad(90), 0, math.rad(90))
		else
			v.CFrame = driveSeat.CFrame * CFrame.Angles(math.rad(90), 0, math.rad(-90))
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
		local arm = Instance.new("Part")
		arm.Parent = v
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

			local g = Instance.new("BodyGyro")
			g.Parent = sb
			g.Name = "Stabilizer"
			g.MaxTorque = Vector3.new(0, 0, 1)
			g.P = 0

			local sf1 = Instance.new("Attachment")
			sf1.Parent = sa
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

			local sp = Instance.new("SpringConstraint")
			sp.Parent = v
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
				-- g.D = _Tune.FAntiRoll
				sp.Damping = _Tune.FSusDamping
				sp.Stiffness = _Tune.FSusStiffness
				sp.FreeLength = _Tune.FSusLength + _Tune.FPreCompress
				sp.MaxLength = _Tune.FSusLength + _Tune.FExtensionLim
				sp.MinLength = _Tune.FSusLength - _Tune.FCompressLim
			else
				-- .D = _Tune.RAntiRoll
				sp.Damping = _Tune.RSusDamping
				sp.Stiffness = _Tune.RSusStiffness
				sp.FreeLength = _Tune.RSusLength + _Tune.RPreCompress
				sp.MaxLength = _Tune.RSusLength + _Tune.RExtensionLim
				sp.MinLength = _Tune.RSusLength - _Tune.RCompressLim
			end

			MakeWeld(driveSeat, sa)
			MakeWeld(sb, base)
		else
			MakeWeld(driveSeat, base)
		end

		--Lock Rear Steering Axle
		if v.Name == "RL" or v.Name == "RR" or v.Name == "R" then
			MakeWeld(base, axle)
		end

		--Weld Assembly
		if v.Parent.Name == "RL" or v.Parent.Name == "RR" or v.Name == "R" then
			MakeWeld(driveSeat, arm)
		end

		MakeWeld(arm, axle)

		arm:MakeJoints()
		axle:MakeJoints()

		--Weld Miscelaneous Parts
		if v:FindFirstChild("SuspensionFixed") ~= nil then
			ModelWeld(v.SuspensionFixed, driveSeat)
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
			local steer = Instance.new("BodyGyro")
			steer.Parent = arm
			steer.Name = "Steer"
			steer.P = _Tune.SteerP
			steer.D = _Tune.SteerD
			steer.MaxTorque = Vector3.new(0, _Tune.SteerMaxTorque, 0)
			steer.cframe = v.CFrame * CFrame.Angles(0, -math.pi / 2, 0)
		end

		--Add Stabilization Gyro
		local gyro = Instance.new("BodyGyro")
		gyro.Parent = v
		gyro.Name = "Stabilizer"
		gyro.MaxTorque = Vector3.new(1, 0, 1)
		gyro.P = 0
		if v.Name == "FL" or v.Name == "FR" or v.Name == "F" then
			gyro.D = _Tune.FGyroDamp
		else
			gyro.D = _Tune.RGyroDamp
		end

		--Add Rotational BodyMover
		local AV = Instance.new("BodyAngularVelocity")
		AV.Parent = v
		AV.Name = "#AV"
		AV.angularvelocity = Vector3.new(0, 0, 0)
		AV.maxTorque = Vector3.new(_Tune.PBrakeForce, 0, _Tune.PBrakeForce)
		AV.P = 1e9
	end

	--[[Vehicle Weight]]
	--Determine Current Mass
	local mass = 0

	local function getMass(p)
		for _, v in pairs(p:GetChildren()) do
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

		for _, v in pairs(Drive) do
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
		local weightB = Instance.new("Part")
		weightB.Parent = body
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
		weightB.CFrame = (driveSeat.CFrame - driveSeat.Position + center) * CFrame.new(0, _Tune.CGHeight, 0)
	end

	local flipG = Instance.new("BodyGyro")
	flipG.Parent = driveSeat
	flipG.Name = "Flip"
	flipG.D = 0
	flipG.MaxTorque = Vector3.new(0, 0, 0)
	flipG.P = 0

	--[[Finalize Chassis]]

	--Weld Body
	task.wait()
	ModelWeld(body, driveSeat)

	--Unanchor
	task.wait()
	UnAnchor(car)

	--[[Manage Plugins]]

	local removedTools = {}
	for _, seat in ipairs(body:GetChildren()) do
		if seat:IsA("VehicleSeat") or seat:IsA("Seat") then
			local SeatClone = module:FindFirstChild("Sit"):Clone()
			SeatClone.Parent = seat

			connections[#connections + 1] = SeatClone.Triggered:Connect(function(player)
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

			connections[#connections + 1] = seat:GetPropertyChangedSignal("Occupant"):Connect(function()
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

	local interface = ReplicatedStorage.CarAssets:FindFirstChild("A-Chassis Interface")

	--[[Remove Character Weight]]
	--Get Seats
	local Seats = {}
	local function getSeats(p)
		for _, v in pairs(p:GetChildren()) do
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
	local function getPProperties(mod, t)
		for _, v in pairs(mod:GetChildren()) do
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
	for _, v in pairs(Seats) do
		--Sit Handler
		connections[#connections + 1] = v.Seat.ChildAdded:connect(function(child)
			if
				child.Name == "SeatWeld"
				and child:IsA("Weld")
				and child.Part1 ~= nil
				and child.Part1.Parent ~= Workspace
				and not child.Part1.Parent:IsDescendantOf(car)
			then
				v.Parts = {}
				getPProperties(child.Part1.Parent, v.Parts)
			end
		end)

		--Leave Handler
		connections[#connections + 1] = v.Seat.ChildRemoved:connect(function(child)
			if child.Name == "SeatWeld" and child:IsA("Weld") then
				for _, part in pairs(v.Parts) do
					if part[1] ~= nil and part[2] ~= nil and part[1]:IsDescendantOf(Workspace) then
						part[1].CustomPhysicalProperties = part[2]
					end
				end
				v.Parts = {}
			end
		end)
	end

	--[[Driver Handling]]

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

	--Driver Sit
	local function ChildAdded(child)
		if
			child.Name == "SeatWeld"
			and child:IsA("Weld")
			and Players:GetPlayerFromCharacter(child.Part1.Parent) ~= nil
		then
			print("car")
			--Distribute Client Interface
			local p = Players:GetPlayerFromCharacter(child.Part1.Parent)
			driveSeat:SetNetworkOwner(p)
			local g = interface:Clone()
			g.Car.Value = car
			g.Parent = p.PlayerGui
		end
	end

	local function ChildRemoved(child)
		if child.Name == "SeatWeld" and child:IsA("Weld") then
			--Remove Flip Force
			if driveSeat:FindFirstChild("Flip") ~= nil then
				driveSeat.Flip.MaxTorque = Vector3.new()
			end

			--Remove Wheel Force
			for _, v: BasePart in pairs(wheels:GetChildren()) do
				if v:FindFirstChild("#AV") ~= nil then
					if v["#AV"]:IsA("BodyAngularVelocity") then
						if v["#AV"].AngularVelocity.Magnitude > 0 then
							v["#AV"].AngularVelocity = Vector3.new()
							v["#AV"].MaxTorque = Vector3.new()
						end
					else
						if v["#AV"].AngularVelocity > 0 then
							v["#AV"].AngularVelocity = 0
							v["#AV"].MotorMaxTorque = 0
						end
					end
				end
			end

			local p = Players:GetPlayerFromCharacter(child.Part1.Parent)

			if child.Name == "SeatWeld" and child:IsA("Weld") then
				for _, playerui in p.PlayerGui:GetChildren() do
					if playerui.Name == "A-Chassis Interface" then
						playerui:Destroy()
					end
				end
			end
		end
	end

	connections[#connections + 1] = driveSeat.ChildAdded:connect(ChildAdded)
	connections[#connections + 1] = driveSeat.ChildRemoved:connect(ChildRemoved)

	--[END]]

	local carDestroyed = false
	local carOnFire = false

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

		task.wait(15)

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

initCar.init = function()
	local plugins = ReplicatedStorage.CarAssets:FindFirstChild("Plugins")

	for _, v in pairs(plugins:GetChildren()) do
		v.Parent = ReplicatedStorage.CarAssets:FindFirstChild("A-Chassis Interface")
	end
	plugins:Destroy()
end

return initCar
