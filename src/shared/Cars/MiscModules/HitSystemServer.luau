local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local HitSystem = {}

local function crashEffect(driveSeat)
	local front = driveSeat.Parent.Body:WaitForChild("FRONT")
	local cp = ReplicatedStorage.Crash:Clone()
	cp.Parent = Workspace
	cp.Position = front.Position

	local Loop = true
	task.delay(1.75, function()
		Loop = false
	end)
	task.spawn(function()
		while Loop do
			task.wait()
			cp.Position = front.Position
		end
	end)

	for _, v in ipairs(cp:QueryDescendants("ParticleEmitter")) do
		v.Enabled = true
		v:Emit(15)
		task.spawn(function()
			task.wait(1.75)
			v.Enabled = false
		end)
	end

	local sound = math.random(1, 2)

	if sound == 1 then
		if driveSeat:FindFirstChild("Sound1") then
			driveSeat:WaitForChild("Sound1"):Clone().Parent = cp
			cp.Sound1:Play()
		end
	else
		if driveSeat:FindFirstChild("Sound2") then
			driveSeat:WaitForChild("Sound2"):Clone().Parent = cp
			cp.Sound2:Play()
		end
	end

	Debris:AddItem(cp, 3)
end

local function damagePlayers(car, damage)
	for _, seat in car:QueryDescendants("Seat, VehicleSeat") do
		local humanoid = seat.Occupant
		if humanoid then
			humanoid:TakeDamage(damage)
		end
	end
end

local lastChanged = {}

local function getCrash(car)
	local driveSeat = car:FindFirstChild("DriveSeat")

	if not driveSeat then
		return
	end

	local value = driveSeat.AssemblyLinearVelocity.magnitude
	if lastChanged[driveSeat] then
		local change = value - lastChanged[driveSeat]
		if change > 8 then
			damagePlayers(car, change)
			crashEffect(driveSeat)
		end
	else
		lastChanged[driveSeat] = value
		return
	end
	lastChanged[driveSeat] = value
end

local cars = {}

local function ChildAdded(child)
	task.wait(1)
	table.insert(cars, child)
end
local function ChildRemove(child)
	table.remove(cars, table.find(cars, child))
end

HitSystem.init = function()
	Workspace.CivCars.ChildAdded:Connect(ChildAdded)
	Workspace.CivCars.ChildRemoved:Connect(ChildRemove)
	RunService.Heartbeat:Connect(function()
		for _, car in cars do
			getCrash(car)
		end
	end)
end

return HitSystem
