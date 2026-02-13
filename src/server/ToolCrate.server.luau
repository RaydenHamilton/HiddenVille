local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local crateData = {}

local function setupcrate(crate)
	if crate.Name == "ToolCrate" and crate:FindFirstChild("BillboardGui") then
		local ToolFolder = ServerStorage:WaitForChild("Tools")
		local NotificationEvent = ReplicatedStorage:WaitForChild("NotificationEvent")

		local Main = crate
		local ProximityPrompt = crate:FindFirstChild("Handler", true)

		local Gui = Main:FindFirstChild("BillboardGui")
		local Cooldown = Main:FindFirstChild("Cooldown")
		local RestockTime = Main:WaitForChild("RestockTime")
		local MaxUses = Main:WaitForChild("MaxUses")
		local Tool = Main:WaitForChild("Tool")
		local Uses = Main:WaitForChild("Uses")
		local GroupID = Main.Parent:WaitForChild("GroupID")
		local GroupRank = Main:WaitForChild("GroupRank")

		Uses.Value = 0

		local playerCooldowns = {}
		local isRestocking = false
		crateData[Main] = {
			Cooldown = Cooldown.Value,
			RestockTime = RestockTime.Value,
			MaxUses = MaxUses.Value,
			ToolName = Tool.Value,
			GroupID = GroupID.Value,
			GroupRank = GroupRank.Value,
			Uses = Uses.Value,
			isRestocking = isRestocking,
			playerCooldowns = playerCooldowns,
		}
		local function updateGui()
			if
				not crateData[Main].isRestocking
				and Gui
				and Gui:FindFirstChild("Uses")
				and Gui:FindFirstChild("TextLabel")
			then
				local usesLeft = math.max(0, MaxUses.Value - Uses.Value)
				Gui.Uses.Text = usesLeft .. "/" .. MaxUses.Value
				Gui.TextLabel.Text = Tool.Value
				ProximityPrompt.ObjectText = Tool.Value
			end
		end

		ProximityPrompt.Triggered:Connect(function(player)
			local character = player.Character
			local humanoid = character and character:FindFirstChild("Humanoid")
			if not character or not humanoid or humanoid.Health == 0 then
				return
			end

			if not player:IsInGroup(GroupID.Value) then
				return
			end

			if player:GetRankInGroup(GroupID.Value) < GroupRank.Value then
				NotificationEvent:FireClient(player, "Your rank is insufficient for this crates access.")
				return
			end

			if Uses.Value >= MaxUses.Value then
				NotificationEvent:FireClient(player, "This crate is at its max use. Try again later.")
				return
			end

			if player.Backpack:FindFirstChild(Tool.Value) or player.Character:FindFirstChild(Tool.Value) then
				NotificationEvent:FireClient(player, "You already have this tool.")
				return
			end

			local cooldownInfo = crateData[Main].playerCooldowns[player]
			if cooldownInfo then
				local remaining = cooldownInfo.untilTime - tick()
				if remaining > 0 then
					NotificationEvent:FireClient(
						player,
						"You must wait " .. math.ceil(remaining) .. " seconds before using this crate again."
					)
					return
				end
			end

			local CrateTool = ToolFolder:FindFirstChild(Tool.Value)
			if CrateTool then
				local clonedTool = CrateTool:Clone()
				clonedTool.Parent = player.Backpack

				Uses.Value += 1
				updateGui()

				crateData[Main].playerCooldowns[player] = {
					untilTime = tick() + Cooldown.Value,
				}

				task.delay(Cooldown.Value, function()
					crateData[Main].splayerCooldowns[player] = nil
				end)
			end
		end)

		task.spawn(function()
			while true do
				if Uses.Value >= MaxUses.Value then
					crateData[Main].isRestocking = true
					local startTime = tick()
					while Uses.Value >= MaxUses.Value do
						if Gui and Gui:FindFirstChild("TextLabel") then
							local remaining = math.max(0, math.floor(RestockTime.Value - (tick() - startTime)))
							Gui.TextLabel.Text = "Restocking in " .. remaining .. "s"
						end
						task.wait(1)
					end
					crateData[Main].isRestocking = false
					updateGui()
				else
					updateGui()
				end
				task.wait(1)
			end
		end)

		task.spawn(function()
			while true do
				if Uses.Value >= MaxUses.Value then
					task.wait(RestockTime.Value)
					Uses.Value = 0
					updateGui()
				else
					task.wait(1)
				end
			end
		end)
	end
end
for _, crate in Workspace.TurfSystem["551 - Warehouse"]:GetChildren() do
	setupcrate(crate)
end
for _, crate in Workspace.TurfSystem["ENVY - Warehouse"]:GetChildren() do
	setupcrate(crate)
end
for _, crate in Workspace.TurfSystem["FFE - Warehouse"]:GetChildren() do
	setupcrate(crate)
end
for _, crate in Workspace.TurfSystem["FFMC - Custom Mansion"]:GetChildren() do
	setupcrate(crate)
end
for _, crate in Workspace.TurfSystem["FFS - Ware House"]:GetChildren() do
	setupcrate(crate)
end
for _, crate in Workspace.TurfSystem["MURDALAND - Ware House"]:GetChildren() do
	setupcrate(crate)
end
for _, crate in Workspace.TurfSystem["TB - Warehouse"]:GetChildren() do
	setupcrate(crate)
end
