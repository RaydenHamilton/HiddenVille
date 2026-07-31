--// Services
local Players = game:GetService("Players")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local StarterGuiService = game:GetService("StarterGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local Workspace = game:GetService("Workspace")

if RunService:IsStudio() or true then
	return {}
end

--// Player + Gui

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local Mouse = Player:GetMouse()
local Character = Player.Character or Player.CharacterAdded:Wait()
local CurrentCam = workspace.CurrentCamera

--// Gui Elements
local Gui = ReplicatedFirst:WaitForChild("MainMenu", 30)

local Main = Gui
Main.Parent = PlayerGui
local LoadingFrame = Main:WaitForChild("LoadingFrame")
local ButtonFrame = Main:WaitForChild("ButtonsFrame")
local FadeFrame = Main.Fade
local LoadingText = LoadingFrame.LoadingText
local TipText = LoadingFrame.Tip
local MenuSong = Main.Song
local EnterSound = Main.ButtonSound
local ClickSound = Main.ClickSound
local ProgressBar = LoadingFrame.LoadingBar.FillerBar

--// Menu (safe with StreamingEnabled)
local ReplicatedMenu = ReplicatedStorage:WaitForChild("Menu", 30)
local MenuFolder = ReplicatedMenu:Clone()
MenuFolder.Parent = workspace

local MenuCamera = MenuFolder:WaitForChild("MenuCamera", 30)

--// ═══════════════════════════════════════════════════════════════════
--// SMOOTHING CONFIGURATION - Tweak these for perfect feel
--// ═══════════════════════════════════════════════════════════════════
local Config = {
	-- Lerp speeds (0-1, higher = faster response)
	ProgressBarLerp = 0.08, -- How smooth the progress bar fills
	FOVLerp = 0.12, -- Camera FOV smoothness
	CameraTiltLerp = 0.06, -- Mouse-follow camera smoothness
	TextSizeLerp = 0.15, -- Text size pulse smoothness

	-- Timing
	TipCrossfadeDuration = 0.8, -- How long tip text crossfades
	TipDisplayDuration = 5, -- How long each tip shows

	-- Camera
	MaxTilt = 12, -- Maximum camera tilt degrees
	BaseFOV = 70,
	MinFOV = 62,
	MaxFOV = 85,

	-- Text pulse
	MinTextSize = 65,
	MaxTextSize = 280,

	-- Fade durations
	LoadingFadeOut = 1.4,
	MenuFadeOut = 1.8,
	BlackFadeDuration = 1.0,
}

--// ═══════════════════════════════════════════════════════════════════
--// SMOOTH STATE VARIABLES
--// ═══════════════════════════════════════════════════════════════════
local smoothState = {
	targetProgress = 0,
	displayProgress = 0,
	targetFOV = Config.BaseFOV,
	currentFOV = Config.BaseFOV,
	targetTiltX = 0,
	targetTiltY = 0,
	currentTiltX = 0,
	currentTiltY = 0,
	targetTextSize = Config.MinTextSize,
	currentTextSize = Config.MinTextSize,
}

--// Initial Setup
Gui.ButtonsFrame.Visible = false
Gui.LoadingFrame.Visible = true
PlayerGui:WaitForChild("MainScreen", 30).Enabled = false

local menuClient = {}

if not game.Loaded then
	game.Loaded:Wait()
end

MenuSong:Play()

-- Force MenuCamera immediately
CurrentCam.CameraType = Enum.CameraType.Scriptable
CurrentCam.CFrame = MenuCamera.CFrame
Workspace.CurrentCamera = CurrentCam
StarterGuiService:SetCoreGuiEnabled("Backpack", false)

--// Tips
local Tips = {
	"Like And Favorite The Game.",
	"Join The Group For Free Cash.",
	"Like And Favorite The Game.",
}

--// ═══════════════════════════════════════════════════════════════════
--// UTILITY FUNCTIONS
--// ═══════════════════════════════════════════════════════════════════

-- Attempt sub-frame lerp for extra smoothness
local function lerp(current, target, alpha)
	return current + (target - current) * alpha
end

-- Attempt smooth delta-time independent lerping
local function smoothLerp(current, target, speed, dt)
	-- This formula gives consistent smoothing regardless of framerate
	local alpha = 1 - math.pow(1 - speed, dt * 60)
	return lerp(current, target, alpha)
end

local function easeInOutQuint(t)
	return t < 0.5 and 16 * t * t * t * t * t or 1 - math.pow(-2 * t + 2, 5) / 2
end

-- Attempt smooth tween with premium defaults
local function smoothTween(obj, duration, properties, easingStyle, easingDirection)
	easingStyle = easingStyle or Enum.EasingStyle.Quint
	easingDirection = easingDirection or Enum.EasingDirection.Out

	local tweenInfo = TweenInfo.new(duration, easingStyle, easingDirection, 0, false, 0)

	local tween = TweenService:Create(obj, tweenInfo, properties)
	tween:Play()
	return tween
end

-- Collect all fadeable descendants for batch operations
local function collectFadeables(gui)
	local fadeables = {
		texts = {},
		images = {},
		frames = {},
		strokes = {},
	}

	for _, desc in ipairs(gui:GetDescendants()) do
		if desc:IsA("TextLabel") or desc:IsA("TextButton") then
			table.insert(fadeables.texts, desc)
		elseif desc:IsA("ImageLabel") or desc:IsA("ImageButton") then
			table.insert(fadeables.images, desc)
		elseif desc:IsA("Frame") then
			table.insert(fadeables.frames, desc)
		elseif desc:IsA("UIStroke") then
			table.insert(fadeables.strokes, desc)
		end
	end

	return fadeables
end

--// ═══════════════════════════════════════════════════════════════════
--// ULTRA-SMOOTH FADE SYSTEM
--// ═══════════════════════════════════════════════════════════════════
local function ultraSmoothFadeOut(gui, duration)
	duration = duration or Config.LoadingFadeOut
	local fadeables = collectFadeables(gui)

	-- Use Exponential easing for that premium fade feel
	local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)

	-- Batch all tweens for synchronized fading
	for _, text in ipairs(fadeables.texts) do
		TweenService:Create(text, tweenInfo, { TextTransparency = 1 }):Play()
	end

	for _, image in ipairs(fadeables.images) do
		TweenService:Create(image, tweenInfo, { ImageTransparency = 1 }):Play()
	end

	for _, frame in ipairs(fadeables.frames) do
		TweenService:Create(frame, tweenInfo, { BackgroundTransparency = 1 }):Play()
	end

	for _, stroke in ipairs(fadeables.strokes) do
		TweenService:Create(stroke, tweenInfo, { Transparency = 1 }):Play()
	end
end

--// ═══════════════════════════════════════════════════════════════════
--// SMOOTH TIP CROSSFADE
--// ═══════════════════════════════════════════════════════════════════
local function crossfadeTip(tipLabel, newText, duration)
	duration = duration or Config.TipCrossfadeDuration

	-- Fade out current text
	local fadeOut = smoothTween(tipLabel, duration / 2, { TextTransparency = 1 }, Enum.EasingStyle.Quad)

	fadeOut.Completed:Connect(function()
		tipLabel.Text = newText
		-- Fade in new text
		smoothTween(tipLabel, duration / 2, { TextTransparency = 0 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	end)
end

--// ═══════════════════════════════════════════════════════════════════
--// PARTICLE BURST (Enhanced)
--// ═══════════════════════════════════════════════════════════════════
local function spawnParticles(position)
	local part = Instance.new("Part")
	part.Anchored = true
	part.CanCollide = false
	part.Transparency = 1
	part.Position = position + Vector3.new(0, 5, 0)
	part.Parent = workspace

	local emitter = Instance.new("ParticleEmitter")
	emitter.Texture = "rbxassetid://241594284"
	emitter.Rate = 0
	emitter.Lifetime = NumberRange.new(2, 3.5)
	emitter.Speed = NumberRange.new(8, 18)
	emitter.SpreadAngle = Vector2.new(45, 45)
	emitter.Rotation = NumberRange.new(0, 360)
	emitter.RotSpeed = NumberRange.new(-120, 120)
	emitter.Drag = 2
	emitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.1, 1.2),
		NumberSequenceKeypoint.new(0.8, 0.8),
		NumberSequenceKeypoint.new(1, 0),
	})
	emitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.3),
		NumberSequenceKeypoint.new(0.7, 0.3),
		NumberSequenceKeypoint.new(1, 1),
	})
	emitter.Parent = part

	emitter:Emit(50)
	game:GetService("Debris"):AddItem(part, 6)
end

--// ═══════════════════════════════════════════════════════════════════
--// INITIALIZE RIG
--// ═══════════════════════════════════════════════════════════════════
local function initializeAnimRig()
	local rigClone = ReplicatedStorage:WaitForChild("MenuRig"):Clone()
	local rigHumanoid = rigClone:WaitForChild("Humanoid")
	local rigRoot = rigClone:WaitForChild("HumanoidRootPart")

	rigRoot.Anchored = true
	rigRoot.CFrame = MenuFolder.CFramePart.CFrame
	rigClone.Parent = MenuFolder

	local humanoidDescription = Players:GetHumanoidDescriptionFromUserId(Player.UserId)
	rigHumanoid:ApplyDescription(humanoidDescription)

	local desc = rigHumanoid:GetAppliedDescription()
	desc.LeftArm = 376530220
	desc.RightArm = 376531012
	desc.LeftLeg = 376531300
	desc.RightLeg = 376531703
	desc.Torso = 376532000
	desc.DepthScale = 0.9
	desc.HeadScale = 1
	desc.HeightScale = 1
	desc.ProportionScale = 0
	desc.WidthScale = 1
	rigHumanoid:ApplyDescription(desc)

	local rigAnimation = rigHumanoid:LoadAnimation(rigClone:WaitForChild("Animation"))
	rigAnimation:Play()
end

--// ═══════════════════════════════════════════════════════════════════
--// FAKE ASSET LOADING (Smooth curve simulation)
--// ═══════════════════════════════════════════════════════════════════
local totalAssets = 8970
local assetsLoaded = 0
local loadingComplete = false

local function loadAssets()
	-- Simulate realistic loading with variable speed
	-- Starts fast, slows in middle, speeds up at end
	local startTime = tick()
	local targetDuration = 3.5 -- Total loading time in seconds

	while assetsLoaded < totalAssets do
		local elapsed = tick() - startTime
		local rawProgress = math.clamp(elapsed / targetDuration, 0, 1)

		-- Apply easing curve for realistic feel
		-- Fast start, slower middle, fast finish
		local easedProgress = easeInOutQuint(rawProgress)

		assetsLoaded = math.floor(easedProgress * totalAssets)
		smoothState.targetProgress = easedProgress

		RunService.Heartbeat:Wait()
	end

	assetsLoaded = totalAssets
	smoothState.targetProgress = 1
	loadingComplete = true
end

--// ═══════════════════════════════════════════════════════════════════
--// MASTER RENDER LOOP - All smooth updates happen here
--// ═══════════════════════════════════════════════════════════════════
local masterConnection
local isMenuActive = true

local function startMasterRenderLoop()
	local lastTime = tick()

	masterConnection = RunService.RenderStepped:Connect(function()
		if not isMenuActive then
			if masterConnection then
				masterConnection:Disconnect()
				masterConnection = nil
			end
			return
		end

		local currentTime = tick()
		local dt = currentTime - lastTime
		lastTime = currentTime

		-- Clamp dt to prevent huge jumps on lag spikes
		dt = math.min(dt, 0.1)

		local loudness = MenuSong.PlaybackLoudness

		-- ═══ SMOOTH PROGRESS BAR ═══
		if LoadingFrame.Visible then
			smoothState.displayProgress =
				smoothLerp(smoothState.displayProgress, smoothState.targetProgress, Config.ProgressBarLerp, dt)

			ProgressBar.Size = UDim2.fromScale(smoothState.displayProgress, 1)
			LoadingText.Text =
				string.format("Assets Loaded %d/%d", math.floor(smoothState.displayProgress * totalAssets), totalAssets)

			-- Smooth color transition
			local r = math.floor(25 + (170 - 25) * smoothState.displayProgress)
			LoadingFrame.Ville.TextColor3 = Color3.fromRGB(r, 0, 0)
		end

		-- ═══ SMOOTH FOV ═══
		if ButtonFrame.Visible and not LoadingFrame.Visible then
			smoothState.targetFOV = math.clamp(Config.BaseFOV - loudness / 20, Config.MinFOV, Config.MaxFOV)
		else
			smoothState.targetFOV = math.clamp(Config.BaseFOV - loudness / 30, Config.MinFOV, Config.MaxFOV)
		end

		smoothState.currentFOV = smoothLerp(smoothState.currentFOV, smoothState.targetFOV, Config.FOVLerp, dt)
		CurrentCam.FieldOfView = smoothState.currentFOV

		-- ═══ SMOOTH CAMERA TILT ═══
		if ButtonFrame.Visible and not LoadingFrame.Visible then
			smoothState.targetTiltX = ((Mouse.Y - Mouse.ViewSizeY / 2) / Mouse.ViewSizeY) * -Config.MaxTilt
			smoothState.targetTiltY = ((Mouse.X - Mouse.ViewSizeX / 2) / Mouse.ViewSizeX) * -Config.MaxTilt
		else
			smoothState.targetTiltX = 0
			smoothState.targetTiltY = 0
		end

		smoothState.currentTiltX =
			smoothLerp(smoothState.currentTiltX, smoothState.targetTiltX, Config.CameraTiltLerp, dt)
		smoothState.currentTiltY =
			smoothLerp(smoothState.currentTiltY, smoothState.targetTiltY, Config.CameraTiltLerp, dt)

		-- Apply camera transform
		if ButtonFrame.Visible or LoadingFrame.Visible then
			CurrentCam.CameraType = Enum.CameraType.Scriptable
			CurrentCam.CFrame = MenuCamera.CFrame
				* CFrame.Angles(math.rad(smoothState.currentTiltX), math.rad(smoothState.currentTiltY), 0)
		end

		-- ═══ SMOOTH TEXT SIZE PULSE ═══
		if ButtonFrame.Visible then
			smoothState.targetTextSize =
				math.clamp(Config.MinTextSize + loudness / 2, Config.MinTextSize, Config.MaxTextSize)

			smoothState.currentTextSize =
				smoothLerp(smoothState.currentTextSize, smoothState.targetTextSize, Config.TextSizeLerp, dt)

			-- Apply to all pulsing labels
			local pulseLabels = {
				Gui.ButtonsFrame.Checkers:FindFirstChild("Hidden"),
				Gui.LoadingFrame:FindFirstChild("Hidden"),
				Gui.ButtonsFrame.Checkers:FindFirstChild("Ville"),
				Gui.LoadingFrame:FindFirstChild("Ville"),
			}

			for _, label in ipairs(pulseLabels) do
				if label then
					label.TextSize = smoothState.currentTextSize
				end
			end
		end
	end)
end

--// ═══════════════════════════════════════════════════════════════════
--// LOADING SCREEN FLOW
--// ═══════════════════════════════════════════════════════════════════
local function showLoadingScreen()
	-- Start loading in background
	task.spawn(loadAssets)

	-- Wait for loading to complete
	while not loadingComplete do
		task.wait(0.05)
	end

	-- Small delay to let progress bar catch up visually
	task.wait(0.3)

	-- Burst particles on complete
	spawnParticles(MenuCamera.CFrame.Position)

	-- Start tip rotation
	task.spawn(function()
		local currentTipIndex = 1
		while LoadingFrame.Visible or ButtonFrame.Visible do
			local nextIndex = (currentTipIndex % #Tips) + 1
			local tip = Tips[nextIndex]

			crossfadeTip(TipText, tip)
			if ButtonFrame.Checkers:FindFirstChild("Tip") then
				crossfadeTip(ButtonFrame.Checkers.Tip, tip)
			end

			currentTipIndex = nextIndex
			task.wait(Config.TipDisplayDuration)
		end
	end)

	-- Smooth transition from loading to buttonsLoadingFrame.Visible = false
	LoadingFrame.Visible = false
	ButtonFrame.Visible = true

	-- Fade in button frame with slight delay for overlap
	task.delay(Config.LoadingFadeOut * 0.3, function()
		ButtonFrame.Visible = true
	end)

	-- Hide loading frame after fade
	task.delay(Config.LoadingFadeOut + 0.1, function()
		LoadingFrame.Visible = false
	end)
end

--// ═══════════════════════════════════════════════════════════════════
--// PLAY BUTTON HANDLER
--// ═══════════════════════════════════════════════════════════════════
local function handlePlayButton()
	-- Dramatic camera punch zoom with smooth easing
	local punchTween = TweenService:Create(
		CurrentCam,
		TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{ CFrame = CurrentCam.CFrame * CFrame.new(0, 0, -8) }
	)
	punchTween:Play()

	-- Ultra smooth music fade
	smoothTween(MenuSong, 2.0, { Volume = 0 }, Enum.EasingStyle.Exponential).Completed:Connect(function()
		MenuSong:Stop()
		MenuSong.Volume = 1
	end)

	-- Fade out all menu elements
	ultraSmoothFadeOut(ButtonFrame, Config.MenuFadeOut)
	ultraSmoothFadeOut(LoadingFrame, Config.MenuFadeOut)

	-- Smooth fade to black
	task.delay(Config.MenuFadeOut * 0.5, function()
		local fadeToBlack =
			smoothTween(FadeFrame, Config.BlackFadeDuration, { Transparency = 0 }, Enum.EasingStyle.Exponential)

		fadeToBlack.Completed:Connect(function()
			-- Cleanup
			isMenuActive = false
			ButtonFrame.Visible = false
			LoadingFrame.Visible = false
			Main.Enabled = false

			if workspace:FindFirstChild("Menu") then
				workspace.Menu:Destroy()
			end

			-- Restore player camera
			CurrentCam.CameraType = Enum.CameraType.Custom
			CurrentCam.CameraSubject = Character:WaitForChild("Humanoid")
			CurrentCam.FieldOfView = 70

			-- Enable game UI
			PlayerGui.MainScreen.Enabled = true
			PlayerGui.MainScreen:WaitForChild("GameplayFrame").Visible = true

			-- Smooth fade back from black
			smoothTween(FadeFrame, Config.BlackFadeDuration, { Transparency = 1 }, Enum.EasingStyle.Exponential)
		end)
	end)
end

--// ═══════════════════════════════════════════════════════════════════
--// BUTTON INTERACTIONS (Enhanced)
--// ═══════════════════════════════════════════════════════════════════
local function handleButtonEntered(button)
	local originalSize = button.TextSize
	smoothTween(button, 0.25, { TextSize = originalSize + 12 }, Enum.EasingStyle.Back)

	local leaveConnection
	leaveConnection = button.MouseLeave:Connect(function()
		smoothTween(button, 0.3, { TextSize = originalSize }, Enum.EasingStyle.Quint)
		leaveConnection:Disconnect()
	end)

	EnterSound:Play()
end

local function handleButtonClick(button)
	-- Snappy rotation with overshoot
	local clickTween = smoothTween(button, 0.08, { Rotation = 10 }, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	clickTween.Completed:Connect(function()
		smoothTween(button, 0.25, { Rotation = 0 }, Enum.EasingStyle.Elastic)
	end)

	ClickSound:Play()
end

function menuClient.init()
	--// ═══════════════════════════════════════════════════════════════════
	--// CONNECT BUTTONS
	--// ═══════════════════════════════════════════════════════════════════
	for _, btnName in ipairs({ "Play", "Help", "Credits", "Gamepasses" }) do
		local button = ButtonFrame.Checkers:FindFirstChild(btnName) :: GuiButton
		if button then
			button.MouseEnter:Connect(function()
				handleButtonEntered(button)
			end)
			button.Activated:Connect(function()
				handleButtonClick(button)
				if btnName == "Play" then
					local isMobile = UserInputService.TouchEnabled
					if isMobile then
						require(ReplicatedStorage.PackagesNew.satchel)
						local touchGui = PlayerGui.TouchGui
						touchGui.Enabled = true
					else
						StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, true)
					end
					handlePlayButton()
				end
			end)
			button.TouchTap:Connect(function() end)
		end
	end

	--// ═══════════════════════════════════════════════════════════════════
	--// RUN
	--// ═══════════════════════════════════════════════════════════════════

	-- Safely attempt to disable the inventory bar until it takes effect
	-- repeat
	-- 	task.wait(0.1)
	-- 	local success = pcall(function()
	-- 		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
	-- 	end)
	-- until success

	if PlayerGui:FindFirstChild("TouchGui") then
		local touchGui = PlayerGui.TouchGui
		touchGui.Enabled = false
	end
	startMasterRenderLoop()
	showLoadingScreen()
	initializeAnimRig()
end
return menuClient
