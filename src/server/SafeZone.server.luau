local Workspace = game:GetService("Workspace")

local lastTouched = {}

for _, Safezone in ipairs(Workspace.Safezones:GetChildren()) do
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local Players = game:GetService("Players")
	local TeleportPart = Safezone:WaitForChild("TP")

	local notification = ReplicatedStorage.Remotes:FindFirstChild("Notification")

	local function IsInSafezone(character)
		if not character or not character.PrimaryPart then
			return false
		end
		local pos = character.PrimaryPart.Position
		local zoneSize = Safezone.Size / 2
		local zonePos = Safezone.Position
		return math.abs(pos.X - zonePos.X) <= zoneSize.X
			and math.abs(pos.Y - zonePos.Y) <= zoneSize.Y
			and math.abs(pos.Z - zonePos.Z) <= zoneSize.Z
	end

	local function EnterSafezone(player)
		player:SetAttribute("InSafezone", true)
	end

	local function ExitSafezone(player)
		player:SetAttribute("InSafezone", false)
	end

	Safezone.Touched:Connect(function(hit)
		local hitCharacter = hit.Parent

		local hitPlayer = Players:GetPlayerFromCharacter(hitCharacter)

		if not lastTouched[hitPlayer] then
			return
		end
		if not (hitPlayer and hitCharacter) then
			return
		end

		local hitHumanoid = hitCharacter:FindFirstChild("Humanoid")

		if hitHumanoid then
			if hitPlayer:FindFirstChild("CombatLogged") then
				local hrp = hitCharacter:FindFirstChild("HumanoidRootPart")
				if TeleportPart and hrp then
					hitCharacter:SetPrimaryPartCFrame(TeleportPart.CFrame * CFrame.new(0, 0, 0))
					if tick() - lastTouched[hitPlayer] > 1 then
						notification:FireClient(hitPlayer, "You cannot enter here while combat logged.", "Error")

						lastTouched[hitPlayer] = tick()
					end
				end
				return
			end

			EnterSafezone(hitPlayer)
		end
	end)

	Safezone.TouchEnded:Connect(function(hit)
		local hitPlayer = Players:GetPlayerFromCharacter(hit.Parent)
		if hitPlayer then
			ExitSafezone(hitPlayer)
		end
	end)
	local function playerAdded(player: Player)
		lastTouched[player] = tick()
		player.CharacterAdded:Connect(function(char)
			local hrp = char:WaitForChild("HumanoidRootPart", 5)
			if not hrp then
				return
			end

			task.wait(0.1)

			if IsInSafezone(char) then
				EnterSafezone(player)
			end
		end)
	end

	for _, player in Players:GetChildren() do
		playerAdded(player)
	end

	Players.PlayerAdded:Connect(playerAdded)
end
