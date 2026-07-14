local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local carEventHandler = {}

local CarDamageRemote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("CarDamageRemote")
local Events = ReplicatedStorage:WaitForChild("CarEvents")
local CivCars = Workspace:WaitForChild("CivCars")

-- Utility: fetch a player's car safely
local function getPlayerCar(player)
	return CivCars:FindFirstChild(player.Name .. "'s Car")
end

-- Utility: safely toggle lock
local function setLock(player, state)
	local car = getPlayerCar(player)
	if not car then
		return
	end

	local lockValue = car:FindFirstChild("Locked")
	if lockValue and lockValue.Value ~= state then
		lockValue.Value = state
	end
end

-- ?? Lock / Unlock

-- Utility: returns the CivCars model the character is currently seated in (or nil)
local function getSeatedCarModel(character)
	if not character then
		return nil
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return nil
	end

	local seat = humanoid.SeatPart
	if not seat or not (seat:IsA("Seat") or seat:IsA("VehicleSeat")) then
		return nil
	end

	-- Walk up until we hit a Model directly under CivCars
	local cur = seat
	while cur and cur ~= CivCars do
		if cur:IsA("Model") and cur.Parent == CivCars then
			return cur
		end
		cur = cur.Parent
	end
	return nil
end

local function despawn(player)
	local car = getPlayerCar(player)
	if not car then
		return
	end

	local occupiedSeats = {}
	for _, seat in ipairs(car:QueryDescendants("VehicleSeat, Seat")) do
		if seat.Occupant then
			table.insert(occupiedSeats, seat)
		end
	end

	if #occupiedSeats == 0 then
		car:Destroy()
	else
		-- Force players out before despawn
		for _, seat in ipairs(occupiedSeats) do
			local humanoid = seat.Occupant
			if humanoid and humanoid:IsA("Humanoid") then
				humanoid.Sit = false
			end
		end

		-- Small delay so players actually get unseated
		task.delay(1.25, function()
			if car.Parent then
				car:Destroy()
			end
		end)
	end
end

local function damageCar(player, carOrPart, damage)
	-- Validate damage

	if typeof(damage) ~= "number" or damage ~= damage then
		return
	end -- damage~=damage catches NaN
	damage = math.clamp(damage, 0, 500) -- pick a sane max; adjust to your game's balance
	if damage <= 0 then
		return
	end

	-- Resolve the car model (client may send Model or hit Part)
	local carModel
	if typeof(carOrPart) == "Instance" then
		if carOrPart:IsA("Model") then
			carModel = carOrPart
		else
			carModel = carOrPart:FindFirstAncestorWhichIsA("Model")
		end
	end
	if not carModel or not carModel:IsA("Model") then
		return
	end

	if carModel.Parent ~= CivCars then
		return
	end

	-- Block damage to the car the shooter is currently seated in (the critical bug fix)
	local seatedCar = getSeatedCarModel(player and player.Character)
	if seatedCar and seatedCar == carModel then
		return
	end

	-- Apply damage
	local health = carModel:FindFirstChild("Health")
	if health and typeof(health.Value) == "number" then
		health.Value = math.max(0, health.Value - damage)
	end
end

local function lock(player)
	setLock(player, true)
end

local function unlock(player)
	setLock(player, false)
end

local function despawnCarTimer(car: Model)
	local lockSequence = 0
	local driveSeat = car:FindFirstChild("DriveSeat") :: Seat

	local gui = driveSeat:FindFirstChildOfClass("BillboardGui")
	if not gui then
		return
	end

	local textLabel = gui:FindFirstChildOfClass("TextLabel")
	if not textLabel then
		return
	end

	local function stopTimer()
		gui.Enabled = false
		textLabel.Text = ``
	end

	local stroke = textLabel:FindFirstChildOfClass("UIStroke")
	if not stroke then
		warn("No_UIStroke")
		return
	end

	local body = car:FindFirstChild("Body")
	if not body then
		warn("No_Body")
		return
	end

	local Weight = body:WaitForChild("#Weight", 8)
	if not Weight then
		warn("No_Weight")
		return
	end

	local lockedValue = car:FindFirstChild("Locked") :: BoolValue
	if not lockedValue then
		warn("No_lock")
		return
	end

	local attachment = Instance.new("Attachment")
	attachment.Parent = Weight
	attachment.WorldPosition = Weight.Position + Vector3.new(0, 7, 0)

	local raycast = Workspace:Raycast(attachment.WorldPosition, Vector3.yAxis * -10)
	if raycast then
		attachment.WorldPosition = raycast.Position + Vector3.new(0, 1, 0)
	end

	textLabel.Size = UDim2.fromScale(2, 0.7)
	textLabel.RichText = true

	stroke.StrokeSizingMode = Enum.StrokeSizingMode.ScaledSize
	stroke.Thickness = 0.05

	-- gui.Size = UDim2.fromOffset(300, 100)
	gui.ClipsDescendants = false
	gui.StudsOffset = Vector3.new(0, 0, 0)
	gui.Adornee = attachment

	local function startTimer()
		lockSequence += 1
		local currentLock = lockSequence
		if driveSeat.Occupant or lockedValue.Value then
			if gui.Enabled == true then
				stopTimer()
			end
			return
		end

		for i = 120, 0, -1 do
			if not driveSeat.Occupant and not lockedValue.Value and currentLock == lockSequence then
				gui.Enabled = true
				textLabel.Text = `Despawning in {i}s`
				task.wait(1)
			else
				if gui.Enabled == true then
					stopTimer()
				end
				return
			end
		end

		textLabel.Text = `Despawning now`
		task.wait(1)
		car:Destroy()
	end

	lockedValue.Changed:Connect(startTimer)
	driveSeat:GetPropertyChangedSignal("Occupant"):Connect(startTimer)
end

function carEventHandler.init()
	CarDamageRemote.OnServerEvent:Connect(damageCar)
	Events.Lock.OnServerEvent:Connect(lock)
	Events.Unlock.OnServerEvent:Connect(unlock)
	Events.Despawn.OnServerEvent:Connect(despawn)

	CivCars.ChildAdded:Connect(despawnCarTimer)
end
return carEventHandler
