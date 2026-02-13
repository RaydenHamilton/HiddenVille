local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

for _, door in pairs(Workspace.Map:GetDescendants()) do
	if
		door.Name == "Door"
		and door:FindFirstChild("Doorframe")
		and door:FindFirstChild("Base"):FindFirstChild("ProximityPrompt")
	then
		local hinge = door:FindFirstChild("Doorframe"):WaitForChild("Hinge")
		local prompt = door:FindFirstChild("Base"):FindFirstChild("ProximityPrompt")

		local goalOpen = {}
		goalOpen.CFrame = hinge.CFrame * CFrame.Angles(0, math.rad(90), 0)

		local goalClose = {}
		goalClose.CFrame = hinge.CFrame * CFrame.Angles(0, 0, 0)

		local tweenInfo = TweenInfo.new(0.5)
		local tweenOpen = TweenService:Create(hinge, tweenInfo, goalOpen)
		local tweenClose = TweenService:Create(hinge, tweenInfo, goalClose)

		prompt.Triggered:Connect(function()
			if prompt.ActionText == "Close" then
				tweenClose:Play()
				prompt.ActionText = "Open"
			else
				tweenOpen:Play()
				prompt.ActionText = "Close"
			end
		end)
	end
end
function DoorOpen(door, state)
	if state.Open == false and not state.StopAndReopen then
		state.Open = true
		state.StopAndReopen = true
		for _ = state.DoorPos, 25 do
			if door.Stop.Value == true then
				repeat
					task.wait()
				until door.Stop.Value == false
			end
			state.DoorPos = state.DoorPos + 1
			for L = 1, #state.DL do
				state.DL[L].CFrame = state.DL[L].CFrame * CFrame.new(0.15, 0, 0)
			end
			for R = 1, #state.DR do
				state.DR[R].CFrame = state.DR[R].CFrame * CFrame.new(-0.15, 0, 0)
			end
			task.wait()
		end
		if door.Mode.Value == 1 then
			repeat
				task.wait()
			until door.Mode.Value ~= 1
		end
		task.wait(state.Timer)
		state.StopAndReopen = false
		state.Open = false
		for _ = 0, 25 do
			if door.Stop.Value == true then
				repeat
					task.wait()
				until door.Stop.Value == false
			end
			if state.StopAndReopen then
				door.OpenInside.Value = true
				return
			end
			state.DoorPos = state.DoorPos - 1
			for L = 1, #state.DL do
				state.DL[L].CFrame = state.DL[L].CFrame * CFrame.new(-0.15, 0, 0)
			end
			for R = 1, #state.DR do
				state.DR[R].CFrame = state.DR[R].CFrame * CFrame.new(0.15, 0, 0)
			end
			task.wait()
		end
	end
end
for _, slidingDoor in pairs(Workspace.Map:GetDescendants()) do
	if
		slidingDoor.Name == "Door"
		and slidingDoor:FindFirstChild("DoorLeft")
		and slidingDoor:FindFirstChild("DoorRight")
		and slidingDoor:FindFirstChild("Mode")
		and slidingDoor:FindFirstChild("Open")
		and slidingDoor:FindFirstChild("OpenInside")
		and slidingDoor:FindFirstChild("OpenOutside")
		and slidingDoor:FindFirstChild("Stop")
	then
		task.spawn(function()
			local state = {
				Timer = 1,
				Open = false,
				StopAndReopen = false,
				DoorPos = 0,
				DL = slidingDoor.DoorLeft:GetChildren(),
				DR = slidingDoor.DoorRight:GetChildren(),
			}

			slidingDoor.Mode.Changed:connect(function()
				if slidingDoor.Mode.Value == 1 then
					DoorOpen(slidingDoor, state)
				end
			end)

			slidingDoor.Open.Changed:connect(function()
				if slidingDoor.Open.Value == true then
					slidingDoor.Open.Value = false
					DoorOpen(slidingDoor, state)
				end
			end)

			slidingDoor.OpenOutside.Changed:connect(function()
				if slidingDoor.OpenOutside.Value == true then
					slidingDoor.OpenOutside.Value = false
					if slidingDoor.Mode.Value == 0 then
						DoorOpen(slidingDoor, state)
					end
				end
			end)

			slidingDoor.OpenInside.Changed:connect(function()
				if slidingDoor.OpenInside.Value == true then
					slidingDoor.OpenInside.Value = false
					if slidingDoor.Mode.Value == 0 or slidingDoor.Mode.Value == 3 then
						DoorOpen(slidingDoor, state)
					end
				end
			end)
		end)
	end
end

for _, sound in Workspace.Map:GetDescendants() do
	if sound:IsA("Sound") and sound.Parent.Name == "Base" then
		sound.Parent.ProximityPrompt.Triggered:Connect(function()
			sound:Play()
		end)
	end
end

for _, autoDoor in pairs(Workspace.Map:GetChildren()) do
	if autoDoor.Name == "Auto Door" then
		local Work = false
		function Activated(whoWasThat)
			if Work == false then
				if whoWasThat.Parent:FindFirstChild("Humanoid") then
					Work = true
					autoDoor.Door.OpenInside.Value = true
					autoDoor.Door.OpenOutside.Value = true
					task.wait(1)
					Work = false
				end
			end
		end
		autoDoor.Door:WaitForChild("InsideSensor").Sensor.Touched:connect(Activated)
		autoDoor.Door:WaitForChild("OutsideSensor").Sensor.Touched:connect(Activated)
	end
end

local ServerStorage = game:GetService("ServerStorage")

local INVALID_CAR_TYPES = {
	["PDCar"] = true,
	["Scooter"] = true,
	["PDCar2"] = true,
}
for _, garageDoor in Workspace.Map.Interactions:GetChildren() do
	local door = garageDoor:FindFirstChild("Garage")
	if garageDoor.Name == "Motor" and door then
		door.Triggered:Connect(function(player)
			local character = player.Character
			if not character then
				return
			end

			local humanoid = character:FindFirstChild("Humanoid")
			if not humanoid then
				return
			end

			local playerGui = player:FindFirstChild("PlayerGui")
			if not playerGui then
				return
			end

			local civCars = workspace:FindFirstChild("CivCars")
			if not civCars then
				return
			end

			local playerCar = civCars:FindFirstChild(player.Name .. "'s Car")
			if not playerCar then
				return
			end

			local seat = playerCar:FindFirstChildOfClass("VehicleSeat")
			if not seat or seat.Occupant ~= humanoid then
				return
			end

			local carType = playerCar:FindFirstChild("CarType")
			if not carType or INVALID_CAR_TYPES[carType.Value] then
				return
			end

			local existingGarageUI = playerGui:FindFirstChild("GarageUI")
			if existingGarageUI then
				existingGarageUI:Destroy()
			end

			local garageTemplate = ServerStorage:FindFirstChild("GarageUI")
			if not garageTemplate then
				warn("GarageUI template not found in ServerStorage.")
				return
			end

			local newGarageUI = garageTemplate:Clone()
			newGarageUI.Parent = playerGui
			newGarageUI.Enabled = true
			if newGarageUI:FindFirstChild("CarCustomization") then
				newGarageUI.CarCustomization.Enabled = true
			end

			local objValue = newGarageUI:FindFirstChild("Object")
			if objValue then
				objValue.Value = door
			end

			local function closeGarage()
				if newGarageUI and newGarageUI.Parent then
					newGarageUI.Enabled = false
					newGarageUI:Destroy()
				end
			end

			-- hook common close button names (X / Close / Exit / CloseButton)
			local closeNames = { "CloseButton", "X", "Close", "Exit" }
			for _, name in ipairs(closeNames) do
				local btn = newGarageUI:FindFirstChild(name, true)
				if btn and btn:IsA("TextButton") or btn:IsA("ImageButton") then
					btn.MouseButton1Click:Connect(closeGarage)
				elseif btn and btn.MouseButton1Click then
					btn.MouseButton1Click:Connect(closeGarage)
				end
			end

			-- also close if they leave the seat
			seat:GetPropertyChangedSignal("Occupant"):Connect(function()
				if seat.Occupant ~= humanoid then
					closeGarage()
				end
			end)
		end)
	end
end
