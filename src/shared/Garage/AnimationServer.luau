local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")
local GarageAnimation = {}

local INVALID_CAR_TYPES = {
	["PDCar"] = true,
	["Scooter"] = true,
	["PDCar2"] = true,
}

local doorEntered = {}

local function openGarage(player, driveSeat, enterPart)
	local moter = enterPart.Value.Value
	local character = player.Character
	if not character then
		warn("no character")
		return
	end

	local humanoid = character:FindFirstChild("Humanoid")
	if not humanoid then
		warn("no humanoid")
		return
	end

	local playerGui = player:FindFirstChild("PlayerGui")
	if not playerGui then
		warn("no player gui")
		return
	end

	local civCars = Workspace:FindFirstChild("CivCars")
	if not civCars then
		warn("no civ car")
		return
	end

	local playerCar = civCars:FindFirstChild(player.Name .. "'s Car")
	if not playerCar then
		warn("no player car")
		return
	end

	local seat = playerCar:FindFirstChildOfClass("VehicleSeat")
	if not seat or seat.Occupant ~= humanoid then
		warn("no Seat")
		return
	end

	local carType = playerCar:FindFirstChild("CarType")
	if not carType or INVALID_CAR_TYPES[carType.Value] then
		warn("wrong type")
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
		objValue.Value = moter
	end

	local function closeGarage()
		if newGarageUI and newGarageUI.Parent then
			newGarageUI.Enabled = false
			newGarageUI:Destroy()
		end

		ReplicatedStorage.Remotes.CarControl:FireClient(player, false)

		task.wait(5)
		doorEntered[driveSeat.Parent] = nil
	end

	-- hook common close button names (X / Close / Exit / CloseButton)
	local closeNames = { "CloseButton", "X", "Close", "Exit" }
	for _, name in ipairs(closeNames) do
		local btn = newGarageUI:FindFirstChild(name, true)
		if btn and (btn:IsA("TextButton") or btn:IsA("ImageButton") or btn.MouseButton1Click) then
			btn.MouseButton1Click:Connect(closeGarage)
		end
	end
end

local function getCar(part: BasePart): Model?
	local model = part:FindFirstAncestorOfClass("Model")
	if not model then
		return
	end

	local car = model:FindFirstAncestorOfClass("Model")

	if not car or car.Parent ~= Workspace.CivCars then
		return
	end

	return car
end

local function enterAnimation(car: Model, door: Part)
	local driveseat = car:FindFirstChild("DriveSeat") :: VehicleSeat

	local humanoid = driveseat.Occupant

	if not humanoid then
		return
	end

	local player = Players:GetPlayerFromCharacter(humanoid.Parent)
	ReplicatedStorage.Remotes.CarControl:FireClient(player, true, door)
	openGarage(player, driveseat, door)
end

local function enter(part: BasePart, door: Part)
	local car = getCar(part)

	if not car then
		return
	end

	if doorEntered[car] then
		return
	end

	doorEntered[car] = door

	enterAnimation(car, door)
end

function GarageAnimation.init()
	for _, door: Part in Workspace.Garage:GetChildren() do
		door.Touched:Connect(function(part: BasePart)
			enter(part, door)
		end)
	end
end

return GarageAnimation
