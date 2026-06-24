-- Hiddenville Movement System v12 (with your original mobile buttons)
-- Smooth sway, stamina, FOV, crouch/run animations + clones Sprint/Crouch from PlayerGui.MobileGui into TouchGui.TouchControlFrame
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ContextActionService = game:GetService("ContextActionService")
local TweenService = game:GetService("TweenService")
local Player = Players.LocalPlayer

local movement = {}
local connects = {}

function movement.new()
	ContextActionService:UnbindAction("CrouchBind")
	ContextActionService:UnbindAction("RunBind")
	for _, v in connects do
		v:Disconnect()
	end

	local PlayerGui = Player:WaitForChild("PlayerGui")
	local Character = Player.Character or Player.CharacterAdded:Wait()
	local Humanoid = Character:WaitForChild("Humanoid")
	local Animator = Humanoid:FindFirstChildOfClass("Animator") or Humanoid:WaitForChild("Animator")
	local Root = Character:WaitForChild("HumanoidRootPart")
	local camera = workspace.CurrentCamera

	-- ?? Animations (expects a child folder named "Animations" with Run & Crouch)
	local AnimationFolder = ReplicatedStorage.UniveralAnimations.Running
	local Animations = {
		Run = Animator:LoadAnimation(AnimationFolder:WaitForChild("Run")),
		Crouch = Animator:LoadAnimation(AnimationFolder:WaitForChild("Crouch")),
	}

	-- ?? Stamina
	local staminaValue = Character:FindFirstChild("Stamina") or Instance.new("NumberValue")
	staminaValue.Name = "Stamina"
	staminaValue.Value = 100
	staminaValue.Parent = Character

	local MaxStamina = 100
	local StaminaDepletionRate = 4.5
	local StaminaRegenRate = 6.5
	local canRegenStamina = true

	local Running = false
	local CanRun = true
	local Crouching = false
	local targetOffset = 0
	local currentOffset = 0

	-- ?? Running sound
	local runSound = Character:FindFirstChild("RunSound")
	if not runSound then
		runSound = Instance.new("Sound")
		runSound.Name = "RunSound"
		runSound.SoundId = "rbxassetid://142665235"
		runSound.Volume = 0.6
		runSound.Looped = true
		runSound.Parent = Root
	end

	-- ?? UI Bars (assumes these paths exist in your UI)
	local StaminaGui = PlayerGui.MainScreen.GameplayFrame.BarHolder.StaminaBar
	local StaminaBar = StaminaGui:WaitForChild("Frame")
	local HealthGui = PlayerGui.MainScreen.GameplayFrame.BarHolder.HealthBar
	local HealthBar = HealthGui:WaitForChild("Frame")

	Humanoid.WalkSpeed = 9.5

	-- Update bars
	local function UpdateBars()
		StaminaBar.Size = UDim2.new(staminaValue.Value / MaxStamina, 0, 1, 0)
		HealthBar.Size = UDim2.new(Humanoid.Health / Humanoid.MaxHealth, 0, 1, 0)
		HealthBar.Position = UDim2.new(Humanoid.Health / Humanoid.MaxHealth / 2, 0, 0.5, 0)
		StaminaBar.Position = UDim2.new(staminaValue.Value / MaxStamina / 2, 0, 0.5, 0)
		StaminaGui.Percent.Text = tostring(math.floor(staminaValue.Value)) .. "%"
		HealthGui.Percent.Text = tostring(math.floor(Humanoid.Health)) .. "%"
	end

	-- Crouch toggle
	local function ToggleCrouch()
		if not Crouching then
			Crouching = true
			Humanoid.WalkSpeed = 7.5
			targetOffset = -0.4
			if not Animations.Crouch.IsPlaying then
				Animations.Crouch:Play()
			end
			Animations.Crouch:AdjustSpeed(Humanoid.MoveDirection.Magnitude > 0 and 1 or 0)
		else
			Crouching = false
			Humanoid.WalkSpeed = 9.5
			targetOffset = 0
			if Animations.Crouch.IsPlaying then
				Animations.Crouch:Stop()
			end
		end
	end

	local function running(speed)
		if speed > 10 and Running then
			if not Animations.Run.IsPlaying then
				Animations.Run:Play()
			end
			if not runSound.IsPlaying then
				runSound:Play()
			end
		else
			if Animations.Run.IsPlaying then
				Animations.Run:Stop()
			end
			if runSound.IsPlaying then
				runSound:Stop()
			end
		end
	end

	-- Run anim + sound

	-- Camera sway + FOV
	local swayTimer = 0
	local FOV_IDLE, FOV_RUN, FOV_DEFAULT = 70, 85, 70

	local function setFOV(target)
		if game.Players.LocalPlayer:GetAttribute("InIntro") == true then
			return
		end
		TweenService
			:Create(
				camera,
				TweenInfo.new(0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
				{ FieldOfView = target }
			)
			:Play()
	end

	local firstPerson = 0

	local function rendersteped(dt)
		local speed = Root.Velocity.Magnitude
		local isRunning = Running and speed > 0
		local isWalking = speed > 2 and speed <= 12
		local head = Character:FindFirstChild("Head")
		if head and head.LocalTransparencyModifier > 0.4 then
			firstPerson = 1
		else
			firstPerson = 4
		end
		currentOffset += (targetOffset * firstPerson - currentOffset) * dt * 6
		local baseOffset = Vector3.new(0, currentOffset, 0)

		swayTimer += dt * (isWalking and 3 or 1.2)
		local swayY = math.sin(swayTimer * (isWalking and 6 or 1.2)) * (isWalking and 0.02 or 0.05)
		baseOffset += Vector3.new(0, swayY * (isWalking and 1 or 0.15), 0)

		camera.CFrame = camera.CFrame * CFrame.new(baseOffset)

		if isRunning then
			setFOV(FOV_RUN)
		elseif isWalking then
			setFOV(FOV_DEFAULT)
		else
			setFOV(FOV_IDLE)
		end
	end

	-- Keyboard / Controller binds
	local function userinput(input, processed)
		if processed then
			return
		end
		if input.KeyCode == Enum.KeyCode.C then
			ToggleCrouch()
		end
	end

	ContextActionService:BindAction("RunBind", function(_, state)
		if state == Enum.UserInputState.Begin and CanRun then
			Running = true
			if Humanoid.MoveDirection.Magnitude > 0 then
				Humanoid.WalkSpeed = 20
			end
		elseif state == Enum.UserInputState.End then
			Running = false
			Humanoid.WalkSpeed = 9.5
			if Animations.Run.IsPlaying then
				Animations.Run:Stop()
			end
			if runSound.IsPlaying then
				runSound:Stop()
			end
		end
	end, false, Enum.KeyCode.LeftShift, Enum.KeyCode.ButtonL2)

	ContextActionService:BindAction("CrouchBind", function(_, state)
		if state == Enum.UserInputState.Begin then
			ToggleCrouch()
		end
	end, false, Enum.KeyCode.C, Enum.KeyCode.ButtonB)

	local function Heartbeat(dt)
		local isMoving = Humanoid.MoveDirection.Magnitude > 0.1

		if Running and CanRun and isMoving then
			staminaValue.Value -= (StaminaDepletionRate * dt)
			if staminaValue.Value <= 0 then
				staminaValue.Value = 0
				CanRun = false
				Running = false
				Humanoid.WalkSpeed = 9.5
				if Animations.Run.IsPlaying then
					Animations.Run:Stop()
				end
				if runSound.IsPlaying then
					runSound:Stop()
				end
			end
		elseif canRegenStamina and not Running then
			staminaValue.Value = math.min(staminaValue.Value + (StaminaRegenRate * dt), MaxStamina)
			if staminaValue.Value > 20 then
				CanRun = true
			end
		end

		UpdateBars()
	end
	-- Stamina loop

	-- ?? YOUR ORIGINAL MOBILE BUTTONS (clone from PlayerGui.MobileGui into TouchGui.TouchControlFrame)
	local mobileButtonsHooked = false
	local function SetupMobileButtons()
		if mobileButtonsHooked then
			return
		end
		if not UserInputService.TouchEnabled then
			return
		end

		-- TouchGui/TouchControlFrame lives under PlayerGui on many setups
		local TouchGui = PlayerGui:FindFirstChild("TouchGui") or PlayerGui:WaitForChild("TouchGui", 5)
		if not TouchGui then
			warn("[Movement] TouchGui not found in PlayerGui (mobile buttons not attached).")
			return
		end
		local ButtonFrame = TouchGui:FindFirstChild("TouchControlFrame")
			or TouchGui:WaitForChild("TouchControlFrame", 5)
		if not ButtonFrame then
			warn("[Movement] TouchControlFrame not found in TouchGui (mobile buttons not attached).")
			return
		end

		local MobileGui = PlayerGui:FindFirstChild("MobileGui")
		if not MobileGui then
			warn("[Movement] PlayerGui.MobileGui missing (no SprintButton/CrouchButton to clone).")
			return
		end

		-- Clone your original buttons right into Touch controls
		local RunButton = ButtonFrame:WaitForChild("SprintButton") or ButtonFrame:WaitForChild("SprintButton", 5)

		local CrouchButton = ButtonFrame:WaitForChild("CrouchButton") or ButtonFrame:WaitForChild("CrouchButton", 5)

		-- Hook behavior (exact same feel)
		connects[#connects + 1] = RunButton.Activated:Connect(function()
			if Running then
				Running = false
				Humanoid.WalkSpeed = 9.5
				if Animations.Run.IsPlaying then
					Animations.Run:Stop()
				end
				if runSound.IsPlaying then
					runSound:Stop()
				end
			else
				if CanRun then
					Running = true
					Humanoid.WalkSpeed = 20
					if not runSound.IsPlaying then
						runSound:Play()
					end
				end
			end
		end)

		connects[#connects + 1] = CrouchButton.Activated:Connect(function()
			ToggleCrouch()
		end)

		mobileButtonsHooked = true
	end

	SetupMobileButtons()

	local function ChildAdded(child)
		if child.Name == "TouchGui" or child.Name == "MobileGui" then
			task.wait(0.1)
			SetupMobileButtons()
		end
	end
	local function characterAdded()
		mobileButtonsHooked = false
		task.wait(1)
		SetupMobileButtons()
	end

	local function remote()
		Running = false
		Humanoid.WalkSpeed = 9.5
		if Animations.Run.IsPlaying then
			Animations.Run:Stop()
		end
		if runSound.IsPlaying then
			runSound:Stop()
		end
	end

	connects[#connects + 1] = UserInputService.InputBegan:Connect(userinput)
	connects[#connects + 1] = RunService.RenderStepped:Connect(rendersteped)
	connects[#connects + 1] = RunService.Heartbeat:Connect(Heartbeat)
	connects[#connects + 1] = Players.LocalPlayer.CharacterAdded:Connect(characterAdded)
	connects[#connects + 1] = PlayerGui.ChildAdded:Connect(ChildAdded)
	connects[#connects + 1] = ReplicatedStorage.Remotes.KnockoutEvent.OnClientEvent:Connect(remote)
	connects[#connects + 1] = Humanoid.Running:Connect(running)
end

function movement.init() end

return movement
