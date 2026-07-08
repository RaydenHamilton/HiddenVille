local Players = game:GetService("Players")
--[[
		___      _______                _     
	   / _ |____/ ___/ /  ___ ____ ___ (_)__ 
	  / __ /___/ /__/ _ \/ _ `(_-<(_-</ (_-<
	 /_/ |_|   \___/_//_/\_,_/___/___/_/___/
 						SecondLogic @ Inspare
]]

local GaugesModule = {}

function GaugesModule.new()
	local gui = Players.LocalPlayer.PlayerGui:WaitForChild("A-Chassis Interface")
	local frame = gui.AC6_Stock_Gauges

	local autoscaling = false --Estimates top speed

	local UNITS = { --Click on speed to change units
		--First unit is default
		{
			units = "MPH",
			scaling = (10 / 12) * (60 / 88), -- 1 stud : 10 inches | ft/s to MPH
			maxSpeed = 140,
			spInc = 20, -- Increment between labelled notches
		},

		{
			units = "KM/H",
			scaling = (10 / 12) * 1.09728, -- 1 stud : 10 inches | ft/s to KP/H
			maxSpeed = 220,
			spInc = 40, -- Increment between labelled notches
		},

		{
			units = "SPS",
			scaling = 1, -- Roblox standard
			maxSpeed = 280,
			spInc = 40, -- Increment between labelled notches
		},
	}

	-----------------------------------------------------------------------------------------------

	frame:WaitForChild("Speedo")
	frame:WaitForChild("Tach")
	frame:WaitForChild("ln")
	frame:WaitForChild("Gear")
	frame:WaitForChild("Speed")

	local car = gui.Car.Value
	car.DriveSeat.HeadsUpDisplay = false

	local _Tune = require(car["A-Chassis Tune"])

	local _pRPM = _Tune.PeakRPM
	local _lRPM = _Tune.Redline

	local currentUnits = 1
	local revEnd = math.ceil(_lRPM / 1000)

	--Automatic Gauge Scaling
	if autoscaling then
		local Drive = {}
		if _Tune.Config == "FWD" or _Tune.Config == "AWD" then
			if car.Wheels:FindFirstChild("FL") ~= nil then
				table.insert(Drive, car.Wheels.FL)
			end
			if car.Wheels:FindFirstChild("FR") ~= nil then
				table.insert(Drive, car.Wheels.FR)
			end
			if car.Wheels:FindFirstChild("F") ~= nil then
				table.insert(Drive, car.Wheels.F)
			end
		end
		if _Tune.Config == "RWD" or _Tune.Config == "AWD" then
			if car.Wheels:FindFirstChild("RL") ~= nil then
				table.insert(Drive, car.Wheels.RL)
			end
			if car.Wheels:FindFirstChild("RR") ~= nil then
				table.insert(Drive, car.Wheels.RR)
			end
			if car.Wheels:FindFirstChild("R") ~= nil then
				table.insert(Drive, car.Wheels.R)
			end
		end

		local wDia = 0
		for i, v in pairs(Drive) do
			if v.Size.x > wDia then
				wDia = v.Size.x
			end
		end
		Drive = nil
		for i, v in pairs(UNITS) do
			v.maxSpeed =
				math.ceil(v.scaling * wDia * math.pi * _lRPM / 60 / _Tune.Ratios[#_Tune.Ratios] / _Tune.FinalDrive)
			v.spInc = math.max(math.ceil(v.maxSpeed / 200) * 20, 20)
		end
	end

	for i = 0, revEnd * 2 do
		local ln = frame.ln:clone()
		ln.Parent = frame.Tach
		ln.Rotation = 45 + i * 225 / (revEnd * 2)
		ln.Num.Text = i / 2
		ln.Num.Rotation = -ln.Rotation
		if i * 500 >= math.floor(_pRPM / 500) * 500 then
			ln.Frame.BackgroundColor3 = Color3.new(1, 0, 0)
			if i < revEnd * 2 then
				ln2 = ln:clone()
				ln2.Parent = frame.Tach
				ln2.Rotation = 45 + (i + 0.5) * 225 / (revEnd * 2)
				ln2.Num:Destroy()
				ln2.Visible = true
			end
		end
		if i % 2 == 0 then
			ln.Frame.Size = UDim2.new(0, 3, 0, 10)
			ln.Frame.Position = UDim2.new(0, -1, 0, 100)
			ln.Num.Visible = true
		else
			ln.Num:Destroy()
		end
		ln.Visible = true
	end

	local lns = Instance.new("Frame", frame.Speedo)
	lns.Name = "lns"
	lns.BackgroundTransparency = 1
	lns.BorderSizePixel = 0
	lns.Size = UDim2.new(0, 0, 0, 0)
	for i = 1, 90 do
		local ln = frame.ln:clone()
		ln.Parent = lns
		ln.Rotation = 45 + 225 * (i / 90)
		if i % 2 == 0 then
			ln.Frame.Size = UDim2.new(0, 2, 0, 10)
			ln.Frame.Position = UDim2.new(0, -1, 0, 100)
		else
			ln.Frame.Size = UDim2.new(0, 3, 0, 5)
		end
		ln.Num:Destroy()
		ln.Visible = true
	end

	for i, v in pairs(UNITS) do
		local lnn = Instance.new("Frame", frame.Speedo)
		lnn.BackgroundTransparency = 1
		lnn.BorderSizePixel = 0
		lnn.Size = UDim2.new(0, 0, 0, 0)
		lnn.Name = v.units
		if i ~= 1 then
			lnn.Visible = false
		end

		for i = 0, v.maxSpeed, v.spInc do
			local ln = frame.ln:clone()
			ln.Parent = lnn
			ln.Rotation = 45 + 225 * (i / v.maxSpeed)
			ln.Num.Text = i
			ln.Num.TextSize = 14
			ln.Num.Rotation = -ln.Rotation
			ln.Frame:Destroy()
			ln.Num.Visible = true
			ln.Visible = true
		end
	end

	local function changeNeedle()
		frame.Tach.Needle.Rotation = 45 + 225 * math.min(1, gui.Values.RPM.Value / (revEnd * 1000))
	end

	local function changeGear()
		local gearText = gui.Values.Gear.Value
		if gearText > 0 then
			gearText = "Gear: D"
		elseif gearText == 0 then
			gearText = "Gear: N"
		elseif gearText == -1 then
			gearText = "Gear: R"
		end
		print(gearText)
		frame.Gear.Text = gearText
	end

	local function changeTCS()
		if _Tune.TCSEnabled then
			if gui.Values.TCS.Value then
				frame.TCS.TextColor3 = Color3.new(1, 170 / 255, 0)
				frame.TCS.TextStrokeColor3 = Color3.new(1, 170 / 255, 0)
				if gui.Values.TCSActive.Value then
					task.wait()
					frame.TCS.Visible = not frame.TCS.Visible
				else
					task.wait()
					frame.TCS.Visible = false
				end
			else
				frame.TCS.Visible = true
				frame.TCS.TextColor3 = Color3.new(1, 0, 0)
				frame.TCS.TextStrokeColor3 = Color3.new(1, 0, 0)
			end
		else
			frame.TCS.Visible = false
		end
	end

	local function TCSActive()
		if _Tune.TCSEnabled then
			if gui.Values.TCSActive.Value and gui.Values.TCS.Value then
				task.wait()
				frame.TCS.Visible = not frame.TCS.Visible
			elseif not gui.Values.TCS.Value then
				task.wait()
				frame.TCS.Visible = true
			else
				task.wait()
				frame.TCS.Visible = false
			end
		else
			frame.TCS.Visible = false
		end
	end

	local function TCS()
		if _Tune.TCSEnabled then
			if gui.Values.TCSActive.Value and gui.Values.TCS.Value then
				task.wait()
				frame.TCS.Visible = not frame.TCS.Visible
			elseif not gui.Values.TCS.Value then
				task.wait()
				frame.TCS.Visible = true
			end
		else
			if frame.TCS.Visible then
				frame.TCS.Visible = false
			end
		end
	end

	local function ABS()
		if _Tune.ABSEnabled then
			if gui.Values.ABS.Value then
				frame.ABS.TextColor3 = Color3.new(1, 170 / 255, 0)
				frame.ABS.TextStrokeColor3 = Color3.new(1, 170 / 255, 0)
				if gui.Values.ABSActive.Value then
					task.wait()
					frame.ABS.Visible = not frame.ABS.Visible
				else
					task.wait()
					frame.ABS.Visible = false
				end
			else
				frame.ABS.Visible = true
				frame.ABS.TextColor3 = Color3.new(1, 0, 0)
				frame.ABS.TextStrokeColor3 = Color3.new(1, 0, 0)
			end
		else
			frame.ABS.Visible = false
		end
	end

	local function ABSActive()
		if _Tune.ABSEnabled then
			if gui.Values.ABSActive.Value and gui.Values.ABS.Value then
				task.wait()
				frame.ABS.Visible = not frame.ABS.Visible
			elseif not gui.Values.ABS.Value then
				task.wait()
				frame.ABS.Visible = true
			else
				task.wait()
				frame.ABS.Visible = false
			end
		else
			frame.ABS.Visible = false
		end
	end

	local function ABSGUI()
		if _Tune.ABSEnabled then
			if gui.Values.ABSActive.Value and gui.Values.ABS.Value then
				task.wait()
				frame.ABS.Visible = not frame.ABS.Visible
			elseif not gui.Values.ABS.Value then
				task.wait()
				frame.ABS.Visible = true
			end
		else
			if frame.ABS.Visible then
				frame.ABS.Visible = false
			end
		end
	end

	local function PBrake()

		frame.PBrake.Visible = gui.Values.PBrake.Value
	end

	local function Gear()
		if gui.Values.TransmissionMode.Value == "Auto" then
			frame.TMode.Text = "A/T"
			frame.TMode.BackgroundColor3 = Color3.new(1, 170 / 255, 0)
		elseif gui.Values.TransmissionMode.Value == "Semi" then
			frame.TMode.Text = "S/T"
			frame.TMode.BackgroundColor3 = Color3.new(0, 170 / 255, 127 / 255)
		else
			frame.TMode.Text = "M/T"
			frame.TMode.BackgroundColor3 = Color3.new(1, 85 / 255, 0.5)
		end
	end

	local function speedoNeedle()
		frame.Speedo.Needle.Rotation = 45
			+ 225
				* math.min(
					1,
					UNITS[currentUnits].scaling * gui.Values.Velocity.Value.Magnitude / UNITS[currentUnits].maxSpeed
				)
		frame.Speed.Text = math.floor(UNITS[currentUnits].scaling * gui.Values.Velocity.Value.Magnitude)
			.. " "
			.. UNITS[currentUnits].units
	end

	local function SpeedActive()
		if currentUnits == #UNITS then
			currentUnits = 1
		else
			currentUnits = currentUnits + 1
		end
		for i, v in pairs(frame.Speedo:GetChildren()) do
			v.Visible = v.Name == UNITS[currentUnits].units or v.Name == "Needle" or v.Name == "lns"
		end
		frame.Speed.Text = math.floor(UNITS[currentUnits].scaling * gui.Values.Velocity.Value.Magnitude)
			.. " "
			.. UNITS[currentUnits].units
	end

	local connections = {}

	connections[#connections + 1] = gui.Values.RPM.Changed:connect(changeNeedle)

	connections[#connections + 1] = gui.Values.Gear.Changed:connect(changeGear)

	connections[#connections + 1] = gui.Values.TCS.Changed:connect(changeTCS)

	connections[#connections + 1] = gui.Values.TCSActive.Changed:connect(TCSActive)

	connections[#connections + 1] = frame.TCS.Changed:connect(TCS)

	connections[#connections + 1] = gui.Values.ABS.Changed:connect(ABS)

	connections[#connections + 1] = gui.Values.ABSActive.Changed:connect(ABSActive)

	connections[#connections + 1] = frame.ABS.Changed:connect(ABSGUI)

	connections[#connections + 1] = gui.Values.PBrake.Changed:connect(PBrake)

	connections[#connections + 1] = gui.Values.TransmissionMode.Changed:connect(Gear)

	connections[#connections + 1] = gui.Values.Velocity.Changed:connect(speedoNeedle)

	connections[#connections + 1] = frame.Speed.Activated:connect(SpeedActive)

	local function removeConnections()
		for _, connection: RBXScriptConnection in connections do
			connection:Disconnect()
		end
	end

	connections[#connections + 1] = gui.Destroying:Connect(removeConnections)

	task.wait(0.1)
	Gear()
	PBrake()
	print("start")
end

return GaugesModule
