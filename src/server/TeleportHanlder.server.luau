local Workspace = game:GetService("Workspace")
for _, Folder in Workspace.TurfSystem:getChildren() do
	if not Folder:IsA("Folder") then
		continue
	end
	local Debris = game:GetService("Debris")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local TweenService = game:GetService("TweenService")
	local RunService = game:GetService("RunService")

	local NotificationEvent = ReplicatedStorage:WaitForChild("NotificationEvent")

	local Main = Folder
	local ProximityPromptIn = Main:FindFirstChild("Inside", true).ProximityPrompt
	local SoundIn = ProximityPromptIn:FindFirstChild("Sound")
	local TeleportOut = Main:FindFirstChild("Outside")
	local TurfName = Main:FindFirstChild("TurfName") and Main.TurfName.Value or "Turf"

	ProximityPromptIn.ObjectText = TurfName .. " Turf"

	local function ensureFadeGuiIn(player)
		local playerGui = player:FindFirstChildOfClass("PlayerGui") or player:FindFirstChild("PlayerGui")
		if not playerGui then
			return nil
		end

		local screenGui = playerGui:FindFirstChild("TeleportFadeGui")
		if not screenGui then
			screenGui = Instance.new("ScreenGui")
			screenGui.Name = "TeleportFadeGui"
			screenGui.IgnoreGuiInset = true
			screenGui.ResetOnSpawn = false
			screenGui.Parent = playerGui

			local frame = Instance.new("Frame")
			frame.Name = "FadeFrame"
			frame.Size = UDim2.fromScale(1, 1)
			frame.BackgroundColor3 = Color3.new(0, 0, 0)
			frame.BackgroundTransparency = 1
			frame.ZIndex = 10
			frame.Visible = false
			frame.Parent = screenGui
		end

		return screenGui:FindFirstChild("FadeFrame")
	end

	local function safeTeleportIn(player, character, targetCFrame)
		local hrp = character:FindFirstChild("HumanoidRootPart")
		if not hrp then
			return
		end

		local pad = Instance.new("Part")
		pad.Name = "TP_SafetyPad"
		pad.Anchored = true
		pad.CanCollide = true
		pad.Transparency = 1
		pad.Size = Vector3.new(22, 1, 22)
		pad.CFrame = targetCFrame * CFrame.new(0, -3, 0)
		pad.Parent = workspace
		Debris:AddItem(pad, 4)

		hrp.Anchored = true
		hrp.AssemblyLinearVelocity = Vector3.zero
		hrp.AssemblyAngularVelocity = Vector3.zero

		if character.PrimaryPart then
			character:PivotTo(targetCFrame)
		end

		if player then
			pcall(function()
				player:RequestStreamAroundAsync(targetCFrame.Position)
			end)
		end

		RunService.Heartbeat:Wait()
		if hrp then
			hrp.Anchored = false
		end
	end

	local function playFadeIn(player, callback)
		local fadeFrame = ensureFadeGuiIn(player)
		if not fadeFrame then
			if callback then
				callback()
			end
			return
		end

		fadeFrame.BackgroundTransparency = 1
		fadeFrame.Visible = true

		local tweenIn = TweenService:Create(
			fadeFrame,
			TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ BackgroundTransparency = 0 }
		)

		local tweenOut = TweenService:Create(
			fadeFrame,
			TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{ BackgroundTransparency = 1 }
		)

		task.spawn(function()
			tweenIn:Play()
			tweenIn.Completed:Wait()

			local oldFocus = player.ReplicationFocus
			if TeleportOut then
				player.ReplicationFocus = TeleportOut
			end

			if callback then
				callback()
			end

			player.ReplicationFocus = oldFocus

			tweenOut:Play()
			tweenOut.Completed:Wait()

			fadeFrame.BackgroundTransparency = 1
			fadeFrame.Visible = false
		end)
	end

	ProximityPromptIn.Triggered:Connect(function(player)
		if not player then
			return
		end
		local character = player.Character
		if not character then
			return
		end

		local humanoid = character:FindFirstChild("Humanoid")
		if not humanoid or humanoid.Health <= 0 then
			return
		end

		if not TeleportOut then
			NotificationEvent:FireClient(player, TurfName .. ": Teleport point missing.")
			return
		end

		playFadeIn(player, function()
			safeTeleportIn(player, character, TeleportOut.CFrame)

			if SoundIn then
				local soundClone = SoundIn:Clone()
				soundClone.Parent = player:FindFirstChildOfClass("PlayerGui") or player
				soundClone:Play()
				Debris:AddItem(soundClone, math.max(2, soundClone.TimeLength))
			end
		end)
	end)

	local ProximityPromptOut = Main:FindFirstChild("Outside", true).ProximityPrompt
	local SoundOut = ProximityPromptOut:FindFirstChild("Sound")
	local TeleportIn = Main:FindFirstChild("Inside")

	local GroupID = Main:FindFirstChild("GroupID")
	local RequiredRank = Main:FindFirstChild("RequiredRank")

	ProximityPromptOut.ObjectText = TurfName .. " Turf"

	local function ensureFadeGuiOut(player)
		local playerGui = player:FindFirstChildOfClass("PlayerGui") or player:FindFirstChild("PlayerGui")
		if not playerGui then
			return nil
		end

		local screenGui = playerGui:FindFirstChild("TeleportFadeGui")
		if not screenGui then
			screenGui = Instance.new("ScreenGui")
			screenGui.Name = "TeleportFadeGui"
			screenGui.IgnoreGuiInset = true
			screenGui.ResetOnSpawn = false
			screenGui.Parent = playerGui

			local frame = Instance.new("Frame")
			frame.Name = "FadeFrame"
			frame.Size = UDim2.fromScale(1, 1)
			frame.BackgroundColor3 = Color3.new(0, 0, 0)
			frame.BackgroundTransparency = 1
			frame.ZIndex = 10
			frame.Visible = false
			frame.Parent = screenGui
		end

		return screenGui:FindFirstChild("FadeFrame")
	end

	local function safeTeleportOut(player, character, targetCFrame)
		local hrp = character:FindFirstChild("HumanoidRootPart")
		if not hrp then
			return
		end

		local pad = Instance.new("Part")
		pad.Name = "TP_SafetyPad"
		pad.Anchored = true
		pad.CanCollide = true
		pad.Transparency = 1
		pad.Size = Vector3.new(22, 1, 22)
		pad.CFrame = targetCFrame * CFrame.new(0, -3, 0)
		pad.Parent = workspace
		Debris:AddItem(pad, 4)

		hrp.Anchored = true
		hrp.AssemblyLinearVelocity = Vector3.zero
		hrp.AssemblyAngularVelocity = Vector3.zero

		if character.PrimaryPart then
			character:PivotTo(targetCFrame)
		end

		if player then
			pcall(function()
				player:RequestStreamAroundAsync(targetCFrame.Position)
			end)
		end

		RunService.Heartbeat:Wait()
		if hrp then
			hrp.Anchored = false
		end
	end

	local function playFadeOut(player, callback)
		local fadeFrame = ensureFadeGuiOut(player)
		if not fadeFrame then
			if callback then
				callback()
			end
			return
		end

		fadeFrame.BackgroundTransparency = 1
		fadeFrame.Visible = true

		local tweenIn = TweenService:Create(
			fadeFrame,
			TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ BackgroundTransparency = 0 }
		)

		local tweenOut = TweenService:Create(
			fadeFrame,
			TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{ BackgroundTransparency = 1 }
		)

		task.spawn(function()
			tweenIn:Play()
			tweenIn.Completed:Wait()

			local oldFocus = player.ReplicationFocus
			if TeleportIn then
				player.ReplicationFocus = TeleportIn
			end

			if callback then
				callback()
			end

			player.ReplicationFocus = oldFocus

			tweenOut:Play()
			tweenOut.Completed:Wait()

			fadeFrame.BackgroundTransparency = 1
			fadeFrame.Visible = false
		end)
	end

	ProximityPromptOut.Triggered:Connect(function(player)
		if not player then
			return
		end
		local character = player.Character
		if not character then
			return
		end

		local humanoid = character:FindFirstChild("Humanoid")
		if not humanoid or humanoid.Health <= 0 then
			return
		end

		if not TeleportIn then
			NotificationEvent:FireClient(player, TurfName .. ": Teleport point missing.")
			return
		end

		if not GroupID or not GroupID.Value then
			NotificationEvent:FireClient(player, TurfName .. ": GroupID missing.")
			return
		end

		if not player:IsInGroup(GroupID.Value) then
			NotificationEvent:FireClient(player, TurfName .. ": You must be in the group to enter the turf.")
			return
		end

		if RequiredRank and player:GetRankInGroup(GroupID.Value) < RequiredRank.Value then
			NotificationEvent:FireClient(player, TurfName .. ": You are not high enough rank to enter the turf.")
			return
		end

		playFadeOut(player, function()
			safeTeleportOut(player, character, TeleportIn.CFrame)

			if SoundOut then
				local soundClone = SoundOut:Clone()
				soundClone.Parent = player:FindFirstChildOfClass("PlayerGui") or player
				soundClone:Play()
				Debris:AddItem(soundClone, math.max(2, soundClone.TimeLength))
			end
		end)
	end)
end
