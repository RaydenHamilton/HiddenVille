local FistClient = {}

function FistClient.new(Tool)
	local UserInputService = game:GetService("UserInputService")
	local Players = game:GetService("Players")
	local RunService = game:GetService("RunService")
	local Workspace = game:GetService("Workspace")

	local CurrentCamera = Workspace.CurrentCamera
	local Player = Players.LocalPlayer
	local Character = Player.Character or Player.CharacterAdded:Wait()
	local Humanoid = Character:WaitForChild("Humanoid")
	local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")

	local AnimationsFolder = Tool:WaitForChild("Animations")

	local Animations = {}

	local function loadAnimations()
		local animator = Humanoid:FindFirstChildOfClass("Animator")
		if not animator then
			animator = Instance.new("Animator")
			animator.Parent = Humanoid
		end

		local function safeLoad(anim)
			if anim and anim:IsA("Animation") then
				local loadedAnim = animator:LoadAnimation(anim)
				if loadedAnim then
					return loadedAnim
				else
					warn("Failed to load animation:", anim.Name, anim.AnimationId)
				end
			else
				warn("Invalid animation object:", anim and anim.Name or "nil")
			end
		end

		Animations.idle = safeLoad(AnimationsFolder:FindFirstChild("Idle"))
		Animations.kick = safeLoad(AnimationsFolder:FindFirstChild("Kick"))
		Animations.push = safeLoad(AnimationsFolder:FindFirstChild("Push"))
		Animations.stomp = safeLoad(AnimationsFolder:FindFirstChild("Stomp"))

		Animations.punches = {
			safeLoad(AnimationsFolder:FindFirstChild("Punch1")),
			safeLoad(AnimationsFolder:FindFirstChild("Punch2")),
			safeLoad(AnimationsFolder:FindFirstChild("Punch3")),
			safeLoad(AnimationsFolder:FindFirstChild("Punch4")),
		}

		Animations.dodges = {
			right = safeLoad(AnimationsFolder:FindFirstChild("WRight")),
			left = safeLoad(AnimationsFolder:FindFirstChild("WLeft")),
			front = safeLoad(AnimationsFolder:FindFirstChild("WFront")),
			back = safeLoad(AnimationsFolder:FindFirstChild("WBack")),
		}
	end

	local PunchedRemote = Tool:WaitForChild("FistHandler")
	local Cooldowns = {
		Punch = 0.4,
		Stomp = 0.5,
		Push = 4,
		Dodge = 0.4,
	}

	local isKeyDown = {
		W = false,
		A = false,
		S = false,
		D = false,
	}

	local debounce = false
	local canPush = true
	local punchIndex = 0
	local activeGui = nil
	local equipped = false
	local UFD

	local isDodging = false

	local function IsAlive(character)
		return character and character:FindFirstChild("Humanoid") and character.Humanoid.Health > 0
	end

	local function Punch()
		if debounce or not IsAlive(Character) then
			return
		end
		if not equipped then
			return
		end
		debounce = true

		punchIndex = (punchIndex % #Animations.punches) + 1
		local punchAnim = Animations.punches[punchIndex]
		punchAnim:Play()

		local hitbox = Instance.new("Part")
		hitbox.Size = Vector3.new(4, 2, 4)
		hitbox.Transparency = 1
		hitbox.Color = Color3.fromRGB(170, 0, 0)
		hitbox.CanCollide = false
		hitbox.Anchored = true
		hitbox.CFrame = Character.RightHand.CFrame
		hitbox.Parent = Workspace

		for _, obj in ipairs(Workspace:GetPartsInPart(hitbox)) do
			local targetHumanoid = obj.Parent:FindFirstChild("Humanoid")
			if targetHumanoid and targetHumanoid ~= Humanoid then
				PunchedRemote:FireServer(targetHumanoid, 10, "Punch")
				if hitbox then
					hitbox:Destroy()
				end
			end
		end

		task.wait(0.1)
		if hitbox then
			hitbox:Destroy()
		end

		task.wait(Cooldowns.Punch)
		debounce = false
	end

	local function Stomp()
		if debounce or not IsAlive(Character) then
			return
		end
		if not equipped then
			return
		end
		debounce = true

		local chance = math.random(1, 2)

		if chance == 1 then
			Animations.stomp:Play()
		elseif chance == 2 then
			Animations.kick:Play()
		end

		local hitbox = Instance.new("Part")
		hitbox.Size = Vector3.new(4, 2, 4)
		hitbox.Transparency = 1
		hitbox.Color = Color3.fromRGB(170, 0, 0)
		hitbox.CanCollide = false
		hitbox.Anchored = true
		hitbox.CFrame = Character.RightFoot.CFrame
		hitbox.Parent = Workspace

		for _, obj in ipairs(Workspace:GetPartsInPart(hitbox)) do
			local targetHumanoid = obj.Parent:FindFirstChild("Humanoid")
			if targetHumanoid and targetHumanoid ~= Humanoid then
				PunchedRemote:FireServer(targetHumanoid, 8, "Stomp")
				if hitbox then
					hitbox:Destroy()
				end
			end
		end

		task.wait(0.1)
		if hitbox then
			hitbox:Destroy()
		end

		task.wait(Cooldowns.Stomp)
		debounce = false
	end

	local function Push()
		if not canPush or debounce or not IsAlive(Character) then
			return
		end
		if not equipped then
			return
		end
		debounce = true
		canPush = false

		Animations.push:Play()

		local hitbox = Instance.new("Part")
		hitbox.Size = Vector3.new(4, 5, 4)
		hitbox.Transparency = 1
		hitbox.Color = Color3.fromRGB(170, 0, 0)
		hitbox.CanCollide = false
		hitbox.Anchored = true

		local rootPart = Character:FindFirstChild("HumanoidRootPart")
		if not rootPart then
			return
		end
		hitbox.CFrame = rootPart.CFrame * CFrame.new(0, 0, -3)
		hitbox.Orientation = rootPart.Orientation
		hitbox.Parent = Workspace

		for _, obj in ipairs(Workspace:GetPartsInPart(hitbox)) do
			local targetHumanoid = obj.Parent:FindFirstChild("Humanoid")
			if targetHumanoid and targetHumanoid ~= Humanoid then
				PunchedRemote:FireServer(targetHumanoid, 0, "Push")
			end
		end

		task.wait(0.1)
		if hitbox then
			hitbox:Destroy()
			debounce = false
		end

		task.wait(Cooldowns.Push)
		canPush = true
	end

	local function Dodge()
		if isDodging or debounce then
			return
		end

		local staminaValue = Character:FindFirstChild("Stamina")
		if not staminaValue or staminaValue.Value < 8 then
			return
		end

		staminaValue.Value -= 8

		debounce = true
		isDodging = true

		local cameraCFrame = CurrentCamera.CFrame
		local forwardVector = Vector3.new(cameraCFrame.LookVector.X, 0, cameraCFrame.LookVector.Z).Unit
		local rightVector = Vector3.new(cameraCFrame.RightVector.X, 0, cameraCFrame.RightVector.Z).Unit

		local dodgeDirection = Vector3.zero
		if isKeyDown.W then
			dodgeDirection += forwardVector
		end
		if isKeyDown.S then
			dodgeDirection -= forwardVector
		end
		if isKeyDown.A then
			dodgeDirection -= rightVector
		end
		if isKeyDown.D then
			dodgeDirection += rightVector
		end

		if dodgeDirection.Magnitude > 0 then
			dodgeDirection = dodgeDirection.Unit
		else
			dodgeDirection = forwardVector
		end

		if dodgeDirection:Dot(forwardVector) > 0.5 then
			Animations.dodges.front:Play()
		elseif dodgeDirection:Dot(forwardVector) < -0.5 then
			Animations.dodges.back:Play()
		elseif dodgeDirection:Dot(rightVector) > 0.5 then
			Animations.dodges.right:Play()
		elseif dodgeDirection:Dot(rightVector) < -0.5 then
			Animations.dodges.left:Play()
		end

		local bodyVelocity = Instance.new("BodyVelocity")
		bodyVelocity.MaxForce = Vector3.new(40000, 0, 40000)
		bodyVelocity.Velocity = dodgeDirection * 12
		bodyVelocity.Parent = HumanoidRootPart

		task.wait(Cooldowns.Dodge)
		bodyVelocity:Destroy()

		for _, anim in pairs(Animations.dodges) do
			anim:Stop()
		end

		isDodging = false
		debounce = false

		task.wait(Cooldowns.Dodge)
	end

	local function updateDirection(humanoidRootPart)
		local cameraLookVector = CurrentCamera.CFrame.LookVector
		local flatLookVector = Vector3.new(cameraLookVector.X, 0, cameraLookVector.Z).Unit

		humanoidRootPart.CFrame = CFrame.new(humanoidRootPart.Position, humanoidRootPart.Position + flatLookVector)
	end

	local function CreateGuiButtons()
		local touchGui = Player.PlayerGui:FindFirstChild("TouchGui") or Player.PlayerGui:WaitForChild("TouchGui", 5)

		if not touchGui then
			warn(" TouchGui not found in PlayerGui (mobile buttons not attached).")
			return
		end

		local buttonFrame = touchGui:FindFirstChild("TouchControlFrame")
			or touchGui:WaitForChild("TouchControlFrame", 5)

		if not buttonFrame then
			warn(" TouchControlFrame not found in TouchGui (mobile buttons not attached).")
			return
		end

		local FistGui = buttonFrame:FindFirstChild("FistGui") or touchGui:WaitForChild("FistGui", 5)

		if not FistGui then
			warn(" Fist not found in TouchGui (mobile buttons not attached).")
			return
		end

		if FistGui then
			FistGui.Stomp.Visible = true
			FistGui.Push.Visible = true
		else
			warn("MobileButtons not found in MobilePunchGui")
		end

		if FistGui then
			FistGui.Stomp.Activated:Connect(Stomp)
			FistGui.Push.Activated:Connect(Push)
		else
			warn("MobileButtons not found in MobilePunchGui")
		end
	end

	local function DestroyGuiButtons()
		if not Player or not Player:FindFirstChild("PlayerGui") then
			warn("Player or PlayerGui not found")
			return
		end

		local touchGui = Player.PlayerGui:FindFirstChild("TouchGui") or Player.PlayerGui:WaitForChild("TouchGui", 5)

		if not touchGui then
			warn(" TouchGui not found in PlayerGui (mobile buttons not attached).")
			return
		end

		local buttonFrame = touchGui:FindFirstChild("TouchControlFrame")
			or touchGui:WaitForChild("TouchControlFrame", 5)

		if not buttonFrame then
			warn(" TouchControlFrame not found in TouchGui (mobile buttons not attached).")
			return
		end

		local FistGui = buttonFrame:FindFirstChild("FistGui") or touchGui:WaitForChild("FistGui", 5)

		if not FistGui then
			warn(" Fist not found in TouchGui (mobile buttons not attached).")
			return
		end

		if FistGui then
			FistGui.Stomp.Visible = false
			FistGui.Push.Visible = false
		else
			warn("MobileButtons not found in MobilePunchGui")
		end
	end

	Tool.Equipped:Connect(function()
		Animations.idle:Play()
		equipped = true

		UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter

		Humanoid.CameraOffset = Vector3.new(1, 0, 0)
		Humanoid.AutoRotate = false
		Humanoid.JumpPower = 0

		UFD = RunService.RenderStepped:Connect(function()
			updateDirection(HumanoidRootPart)
		end)

		if UserInputService.TouchEnabled then
			CreateGuiButtons()
		else
			local keyboardGui = Tool:WaitForChild("KeyboardButtons"):Clone()
			keyboardGui.Parent = Player:WaitForChild("PlayerGui")
			activeGui = keyboardGui
		end

		Tool.Activated:Connect(function()
			if isDodging and Humanoid:GetState() ~= Enum.HumanoidStateType.Physics then
				return
			end
			Punch()
		end)
		UserInputService.InputBegan:Connect(function(input, gameProcessed)
			if not equipped or gameProcessed then
				return
			end
			if not Tool.CanAttack and Humanoid:GetState() ~= Enum.HumanoidStateType.Physics then
				return
			end

			if input.KeyCode == Enum.KeyCode.F or input.KeyCode == Enum.KeyCode.ButtonB then
				Stomp()
			elseif input.KeyCode == Enum.KeyCode.W then
				isKeyDown.W = true
			elseif input.KeyCode == Enum.KeyCode.A then
				isKeyDown.A = true
			elseif input.KeyCode == Enum.KeyCode.S then
				isKeyDown.S = true
			elseif input.KeyCode == Enum.KeyCode.D then
				isKeyDown.D = true
			elseif input.KeyCode == Enum.KeyCode.G or input.KeyCode == Enum.KeyCode.ButtonX then
				Push()
			elseif input.KeyCode == Enum.KeyCode.ButtonR2 then
				if isDodging then
					return
				end
				Punch()
			end
		end)
		UserInputService.InputEnded:Connect(function(input, gameProcessed)
			if not equipped then
				return
			end

			if input.KeyCode == Enum.KeyCode.W then
				isKeyDown.W = false
			elseif input.KeyCode == Enum.KeyCode.A then
				isKeyDown.A = false
			elseif input.KeyCode == Enum.KeyCode.S then
				isKeyDown.S = false
			elseif input.KeyCode == Enum.KeyCode.D then
				isKeyDown.D = false
			end
		end)
	end)

	Tool.Unequipped:Connect(function()
		Animations.idle:Stop()
		equipped = false

		UserInputService.MouseBehavior = Enum.MouseBehavior.Default

		Humanoid.CameraOffset = Vector3.new(0, 0, 0)
		Humanoid.AutoRotate = true
		Humanoid.JumpPower = 40

		if UFD then
			UFD:Disconnect()
			UFD = nil
		end

		if activeGui then
			activeGui:Destroy()
			activeGui = nil
		end

		if Player.PlayerGui:FindFirstChild("KeyboardButtons") then
			Player.PlayerGui:FindFirstChild("KeyboardButtons"):Destroy()
		end

		DestroyGuiButtons()
	end)

	Player.CharacterAdded:Connect(function(character)
		task.wait(1)
		loadAnimations()
	end)

	if Player.Character then
		task.wait(1)
		loadAnimations()
	end
end

return FistClient
