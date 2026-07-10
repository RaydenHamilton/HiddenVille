local Players = game:GetService("Players")
local seatprompt = {}

local humanoid: Humanoid

local disabledSeats = {}

local function disabledPrompt(car)
	for _, seat in car:QueryDescendants("Seat,VehicleSeat") do
		if seat:FindFirstChild("Sit") then
			seat:FindFirstChild("Sit").Enabled = false
			table.insert(disabledSeats, seat)
		end
	end
end

local function enablePrompt()
	task.wait(0.5)
	for _, seat: Seat in disabledSeats do
		if seat.Occupant == nil then
			local prox = seat:FindFirstChild("Sit")
			prox.Enabled = true
		end
	end
	disabledSeats = {}
end

local function characterAdded(character)
	humanoid = character:WaitForChild("Humanoid")

	humanoid.Seated:Connect(function(seated: boolean, seat: Seat)
		if not seated then
			enablePrompt()
			return
		end

		local playerSeat = seat:FindFirstAncestor("CivCars")

		if not playerSeat then
			return
		end

		local model = seat.Parent
		if model.Name == "Body" then
			disabledPrompt(model.Parent)
		else
			disabledPrompt(model)
		end
	end)
end

local function playerAdded(player)
	if player.Character then
		characterAdded(player.Character)
	end
	player.CharacterAdded:Connect(characterAdded)
end

function seatprompt.init()
	playerAdded(Players.LocalPlayer)
end

return seatprompt
