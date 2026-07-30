local characterLoaderServer = {}

function characterLoaderServer.inti()
	if game:IsLoaded() then
		game.Loaded:Wait()
	end

	local Players = game:GetService("Players")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local ServerStorage = game:GetService("ServerStorage")
	local CharacterSettings = require(ReplicatedStorage.Settings.CharacterSettings)

	local righttats = script:FindFirstChild("righttats")
	local lefttats = script:FindFirstChild("lefttats")

	local groupid = 45546465546
	local nametag = ReplicatedStorage:WaitForChild("Nametag")

	local function playerAdded(player)
		local function LoadCharacter(character)
			local humanoid = character:WaitForChild("Humanoid")
			local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

			if player.CharacterAppearanceLoaded then
				player.CharacterAppearanceLoaded:Wait()
			end

			humanoidRootPart.Anchored = true

			local leaderstats = player:FindFirstChild("leaderstats")
			if not leaderstats or not leaderstats:FindFirstChild("Gender") then
				warn("Missing leaderstats or Gender value for player")
				humanoidRootPart.Anchored = false
			end

			local genderFolder = ReplicatedStorage:FindFirstChild("Rigs")
			if not genderFolder then
				warn("Rigs folder missing in ServerStorage")
				humanoidRootPart.Anchored = false
				return
			end
			local maleFolder = genderFolder:FindFirstChild("Male")
			local femaleFolder = genderFolder:FindFirstChild("Female")
			if not maleFolder or not femaleFolder then
				warn("Male or Female folder missing in Rigs")
				humanoidRootPart.Anchored = false
				return
			end

			local genderValue = leaderstats and leaderstats.Gender.Value or "Male"
			if not genderValue then
				warn(player.Name .. " does not have a Gender value. Defaulting to Male.")
				return
			end

			if genderValue == "Female" then
				for _, part in ipairs(femaleFolder:GetChildren()) do
					local existingBody = character:FindFirstChild(part.Name)
					if existingBody and part.Name ~= "HumanoidRootPart" then
						if existingBody:IsA("MeshPart") then
							existingBody:Remove()
							local clonedPart = part:Clone()
							clonedPart.Parent = character
						end
					end
				end
			else
				for _, part in ipairs(maleFolder:GetChildren()) do
					local existingBody = character:FindFirstChild(part.Name)
					if existingBody and part.Name ~= "HumanoidRootPart" then
						if existingBody:IsA("MeshPart") then
							existingBody:Remove()
							local clonedPart = part:Clone()
							clonedPart.Parent = character
						end
					end
				end
			end

			humanoid:BuildRigFromAttachments()

			local scales = {
				--BodyDepthScale = 0.92,
				BodyHeightScale = 1.2,
				BodyWidthScale = 1,
				HeadScale = 1,
				BodyProportionScale = 0,
				BodyTypeScale = 0,
			}

			for scale, value in pairs(scales) do
				local scaleObj = humanoid:FindFirstChild(scale)
				if scaleObj then
					scaleObj.Value = value
				end
			end

			if not nametag then
				warn("Nametag UI not found in ReplicatedStorage")
				humanoidRootPart.Anchored = false
				return
			end

			local function getLevelColor(level)
				if level >= 1 and level <= 9 then
					return Color3.fromRGB(17, 255, 0)
				elseif level >= 10 and level <= 19 then
					return Color3.fromRGB(17, 255, 0)
				elseif level >= 20 and level <= 29 then
					return Color3.fromRGB(255, 170, 0)
				elseif level >= 30 and level <= 39 then
					return Color3.fromRGB(255, 170, 0)
				elseif level >= 40 and level <= 49 then
					return Color3.fromRGB(255, 170, 0)
				elseif level >= 50 and level <= 59 then
					return Color3.fromRGB(255, 170, 0)
				elseif level >= 100 then
					return Color3.fromRGB(255, 170, 0)
				else
					return Color3.fromRGB(255, 170, 0)
				end
			end
			character:WaitForChild("Humanoid").DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None

			local CustomLevel = Instance.new("BoolValue")
			CustomLevel.Parent = player
			CustomLevel.Value = false

			task.wait(0.1)

			local NametagClone = nametag:Clone()

			NametagClone.Parent = character:WaitForChild("UpperTorso")

			NametagClone.Adornee = character:WaitForChild("Head")
			NametagClone.StudsOffset = Vector3.new(0, 2.1, 0)
			local rankid = player:GetRankInGroup(groupid)
			local emoji = CharacterSettings.RankTable[tostring(rankid)]
			local UserEmoji = CharacterSettings.EmojiTable[tostring(player.UserId)]

			local hiddenstats = player:FindFirstChild("hiddenstats")
			local customLevel = CharacterSettings.CustomsTable[tostring(player.UserId)]
			local levelValue = customLevel and customLevel.level
				or (hiddenstats and hiddenstats:FindFirstChild("Level") and hiddenstats.Level.Value or 1)
			local levelColor = customLevel and customLevel.color or getLevelColor(levelValue)

			local customName = CharacterSettings.CustomNames[tostring(player.UserId)]
			local displayText = customName or player.DisplayName
			if emoji and UserEmoji then
				displayText = "[" .. emoji .. "][" .. UserEmoji .. "] " .. (customName or player.DisplayName)
			elseif emoji then
				displayText = "[" .. emoji .. "] " .. (customName or player.DisplayName)
			elseif UserEmoji then
				displayText = "[" .. UserEmoji .. "] " .. (customName or player.DisplayName)
			elseif CharacterSettings.StarsTable[player.Name] then
				displayText = "[⭐] " .. (customName or player.DisplayName)
			else
				displayText = customName or player.DisplayName
			end

			local NametagFrame = NametagClone:WaitForChild("Frame")

			NametagFrame.Username.Text = displayText
			NametagFrame.Level.Text = "Level " .. levelValue
			NametagFrame.Level.TextColor3 = levelColor
			NametagFrame.Level.RichText = false
			NametagFrame.Username.RichText = false
			task.wait()
			NametagFrame.Level.RichText = true
			NametagFrame.Username.RichText = true

			if not customLevel then
				player:WaitForChild("hiddenstats", 10).Level:GetPropertyChangedSignal("Value"):Connect(function()
					local updatedLevelValue = player:WaitForChild("hiddenstats", 10).Level.Value
					NametagFrame.Level.Text = "Level " .. updatedLevelValue
					NametagFrame.Level.TextColor3 = getLevelColor(updatedLevelValue)
					CustomLevel.Value = false
				end)
			else
				CustomLevel.Value = true
			end

			local function applyServerTattoos()
				if not lefttats and not righttats then
					warn("tats")
					return
				end

				local rightHand = character:WaitForChild("RightHand")
				local leftHand = character:WaitForChild("LeftHand")

				if not rightHand then
					rightHand = character:WaitForChild("RightHand")
				end
				if not leftHand then
					leftHand = character:WaitForChild("LeftHand")
				end

				if rightHand then
					for _, child in ipairs(rightHand:GetChildren()) do
						if child.GetAttribute and child:GetAttribute("IsTattoo") then
							child:Destroy()
						end
					end
				end
				if leftHand then
					for _, child in ipairs(leftHand:GetChildren()) do
						if child.GetAttribute and child:GetAttribute("IsTattoo") then
							child:Destroy()
						end
					end
				end

				if lefttats and rightHand then
					for _, obj in ipairs(lefttats:GetChildren()) do
						local clone = obj:Clone()
						clone.Parent = leftHand
						if clone.SetAttribute then
							clone:SetAttribute("IsTattoo", true)
						end
					end
				end

				if righttats and leftHand then
					for _, obj in ipairs(righttats:GetChildren()) do
						local clone = obj:Clone()
						clone.Parent = rightHand
						if clone.SetAttribute then
							clone:SetAttribute("IsTattoo", true)
						end
					end
				end
			end

			local success, err = pcall(applyServerTattoos)
			if not success then
				warn("applyServerTattoos failed: ", err)
			end

			humanoidRootPart.Anchored = false

			if not player.Backpack:FindFirstChild("Fist") then
				local Fist = ServerStorage.Tools:WaitForChild("Fist")
				local FistClone = Fist:Clone()
				FistClone.Parent = player.Backpack
			end

			if not player.Backpack:FindFirstChild("Phone") then
				local Phone = ServerStorage.Tools:WaitForChild("Phone")
				local PhoneClone = Phone:Clone()
				PhoneClone.Parent = player.Backpack
			end
		end

		player.CharacterAdded:Connect(LoadCharacter)
		if player.Character then
			LoadCharacter(player.Character)
		end
	end

	Players.PlayerAdded:Connect(playerAdded)
	for i, player in Players:GetChildren() do
		playerAdded(player)
	end
end

return characterLoaderServer
