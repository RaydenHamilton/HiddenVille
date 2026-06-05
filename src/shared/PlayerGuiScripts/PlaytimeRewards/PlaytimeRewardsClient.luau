local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local playtimeClientModule = {}

function playtimeClientModule.init()
	local NotificationModule = require(ReplicatedStorage.Modules.NotificationModule)

	local Player = Players.LocalPlayer

	local PlayerGui = Player:WaitForChild("PlayerGui")
	local Main = PlayerGui:WaitForChild("MainScreen"):WaitForChild("PlaytimeRewards"):WaitForChild("Main")
	local RewardsFrame = Main:WaitForChild("RewardsFrame")
	local MainMenu = PlayerGui:WaitForChild("MainMenu")

	local GetAllClaims = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("GetAllClaims")
	local ClaimTool = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("ChooseTool")
	local ClaimMoney = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("GiveMoney")

	local rewards = {
		[1] = { reward = "Money", value = 500, time = 120 }, -- 120
		[2] = { reward = "Money", value = 2000, time = 300 }, -- 300
		[3] = { reward = "Money", value = 2500, time = 600 }, -- 600
		[4] = { reward = "Gun", value = "Handgun", time = 900 }, -- 900
		[5] = { reward = "Money", value = 3500, time = 1200 },
		[6] = { reward = "Money", value = 5000, time = 1500 },
		[7] = { reward = "Money", value = 10000, time = 2100 },
		[8] = { reward = "Gun", value = "Longgun", time = 3600 },
	}

	local Handguns = {
		"G20D",
		"G20",
		"G20Switch",
	}

	local Longguns = {
		"Mac11",
		"Mini-Uzi",
		"Mac10",
	}

	local popup = false
	local playtime = 0
	local claimedRewards = {}
	local connectedButtons = {}
	local connectedHover = {}

	local function tweenColor(guiObject, targetColor, duration)
		local tweenInfo = TweenInfo.new(duration or 0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		local tween = TweenService:Create(guiObject, tweenInfo, { BackgroundColor3 = targetColor })
		tween:Play()
	end

	local function createTween(element, properties, duration)
		local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		return TweenService:Create(element, tweenInfo, properties)
	end

	local function getOriginalTransparencies(frame)
		local transparencyMap = {}

		if frame:IsA("GuiObject") then
			transparencyMap[frame] = { BackgroundTransparency = frame.BackgroundTransparency }
		end

		for _, descendant in ipairs(frame:GetDescendants()) do
			local props = {}

			if descendant:IsA("GuiObject") then
				props.BackgroundTransparency = descendant.BackgroundTransparency
			end
			if descendant:IsA("TextLabel") or descendant:IsA("TextButton") then
				props.TextTransparency = descendant.TextTransparency
			end
			if descendant:IsA("ImageLabel") or descendant:IsA("ImageButton") then
				props.ImageTransparency = descendant.ImageTransparency
			end
			if descendant:IsA("UIStroke") then
				props.Transparency = descendant.Transparency
			end

			if next(props) then
				transparencyMap[descendant] = props
			end
		end

		return transparencyMap
	end

	local function tweenToTransparency(transparencyMap, duration)
		for descendant, props in pairs(transparencyMap) do
			local tweenProps = {}
			for propName, targetValue in pairs(props) do
				tweenProps[propName] = targetValue
			end

			if next(tweenProps) then
				local tween = createTween(descendant, tweenProps, duration)
				tween:Play()
			end
		end
	end

	local function makeDescendantsInvisible(transparencyMap)
		for descendant, props in pairs(transparencyMap) do
			if descendant:IsA("GuiObject") and props.BackgroundTransparency ~= nil then
				descendant.BackgroundTransparency = 1
			end
			if (descendant:IsA("TextLabel") or descendant:IsA("TextButton")) and props.TextTransparency ~= nil then
				descendant.TextTransparency = 1
			end
			if (descendant:IsA("ImageLabel") or descendant:IsA("ImageButton")) and props.ImageTransparency ~= nil then
				descendant.ImageTransparency = 1
			end
			if descendant:IsA("UIStroke") and props.Transparency ~= nil then
				descendant.Transparency = 1
			end
		end
	end

	local function formatTime(seconds)
		local minutes = math.floor(seconds / 60)
		local secs = seconds % 60
		return string.format("%02d:%02d", minutes, secs)
	end

	local function updateRewards()
		local claims
		local success, result = pcall(function()
			return GetAllClaims:InvokeServer()
		end)

		if success then
			claims = result
		else
			warn("Failed to get claim data")
			return
		end

		local updated = false
		for index, data in pairs(rewards) do
			task.spawn(function()
				local frame = RewardsFrame:FindFirstChild(tostring(index))
				if not frame then
					return
				end
				local claimButton = frame:FindFirstChild("Claim")
				if not claimButton then
					return
				end

				local isClaimed = claims[index] == false
				local timeRequired = data.time

				if isClaimed then
					if claimButton.Text ~= "Claimed" then
						claimButton.Text = "Claimed"

						tweenColor(claimButton, Color3.fromRGB(100, 100, 100))
						claimButton.Visible = true
						claimedRewards[index] = true
					end
				elseif playtime >= timeRequired then
					if claimButton.Text ~= "Claim" then
						claimButton.Text = "Claim"
						NotificationModule.Success("You gift is ready to be claimed!", 3)
						tweenColor(claimButton, Color3.fromRGB(0, 170, 0))
						claimButton.Visible = true
					end
				else
					local remaining = timeRequired - playtime
					claimButton.Text = formatTime(remaining)
					tweenColor(claimButton, Color3.fromRGB(170, 0, 0))
					claimButton.Visible = true
					if not updated then
						updated = true
						if remaining > 0 then
							PlayerGui.MainScreen.GameplayFrame.SideButtons["Playtime Rewards"].Inside.Text =
								formatTime(remaining)
						else
							PlayerGui.MainScreen.GameplayFrame.SideButtons["Playtime Rewards"].Inside.Text = "Completed"
						end
					end
				end

				if not connectedButtons[index] and not claimedRewards[index] then
					connectedButtons[index] = true
					claimButton.Activated:Connect(function()
						if not claimedRewards[index] and playtime >= data.time then
							if data.reward == "Gun" then
								local toolName
								if data.value == "Handgun" then
									toolName = Handguns[math.random(1, #Handguns)]
								else
									toolName = Longguns[math.random(1, #Longguns)]
								end
								ClaimTool:FireServer(toolName, index)
							else
								ClaimMoney:FireServer(data.value, index)
							end

							if data.reward == "Money" then
								local message = PlayerGui.GiftNotification:WaitForChild(`${data.value}`)
								message.Text = `CLAIMED {message.Text}`
							else
								NotificationModule.Success(`CLAIMED GUN!`, 3)
							end

							claimedRewards[index] = true
							claimButton.Text = "Claimed"
							claimButton.AutoButtonColor = false
							claimButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
						end
					end)
				end

				if not connectedHover[index] then
					connectedHover[index] = true

					local originalSize = claimButton.Size
					local originalPosition = claimButton.Position

					claimButton.MouseEnter:Connect(function()
						local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

						local sizeIncrease = UDim2.new(0, 5, 0, 5)
						local hoverSize = originalSize + sizeIncrease
						local hoverPosition = originalPosition
							- UDim2.new(0, sizeIncrease.X.Offset / 2, 0, sizeIncrease.Y.Offset / 2)

						local tweenSize = TweenService:Create(claimButton, tweenInfo, { Size = hoverSize })
						local tweenPos = TweenService:Create(claimButton, tweenInfo, { Position = hoverPosition })

						tweenSize:Play()
						tweenPos:Play()
					end)

					claimButton.MouseLeave:Connect(function()
						local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

						local tweenSize = TweenService:Create(claimButton, tweenInfo, { Size = originalSize })
						local tweenPos = TweenService:Create(claimButton, tweenInfo, { Position = originalPosition })

						tweenSize:Play()
						tweenPos:Play()
					end)
				end
			end)
		end
	end

	task.spawn(function()
		while true do
			task.wait(1)
			playtime += 1
			updateRewards()
			if playtime > 3600 then
				break
			end
		end
	end)

	MainMenu:GetPropertyChangedSignal("Enabled"):Connect(function()
		if not MainMenu.Enabled and not popup then
			local transparencyMap = getOriginalTransparencies(Main)
			makeDescendantsInvisible(transparencyMap)

			Main.Parent.Visible = true

			tweenToTransparency(transparencyMap, 0.5)
		end
	end)
end
return playtimeClientModule
