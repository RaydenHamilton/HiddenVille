local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local dive = {}

function dive.init()
	-- RemoteEvent for breaking shield
	local BreakSpawnShield = ReplicatedStorage:WaitForChild("BreakSpawnShield")

	local Player = Players.LocalPlayer
	local Character = Player.Character or Player.CharacterAdded:Wait()
	local Humanoid = Character:WaitForChild("Humanoid")
	local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
	local Stamina = Character:WaitForChild("Stamina")

	-- Roll animation
	local Animator = Humanoid:WaitForChild("Animator")
	local RollAnimation = Instance.new("Animation")
	RollAnimation.AnimationId = "rbxassetid://104519680758175"

	local canRoll = true
	local rollCooldown = 1.2
	local rollForce = 80
	local rollDuration = 0.8
	local justJumped = false -- ADDED: Track recent jump

	local function isGrounded()
		local ray = workspace:Raycast(HumanoidRootPart.Position, Vector3.new(0, -3.5, 0))
		return ray ~= nil
	end

	local function dive()
		if Stamina.Value < 10 then
			return
		end

		canRoll = false
		Stamina.Value -= 10

		BreakSpawnShield:FireServer()

		-- ADDED: Check if we're jumping into this roll
		local startedAirborne = not isGrounded()
		if startedAirborne then
			justJumped = true
			task.delay(1, function()
				justJumped = false
			end)
		end

		-- Prevent ragdoll/floppy states
		Humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
		Humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
		Humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp, false)

		-- Play roll animation
		local animTrack = Animator:LoadAnimation(RollAnimation)
		animTrack.Priority = Enum.AnimationPriority.Action4
		animTrack:Play()

		-- Apply roll force
		local bv = Instance.new("BodyVelocity")
		bv.MaxForce = Vector3.new(1, 0, 1) * 6000
		bv.Velocity = HumanoidRootPart.CFrame.LookVector * rollForce
		bv.Parent = HumanoidRootPart

		-- CHANGED: Anti-clip only when grounded and not jumping
		local antiClip
		antiClip = RunService.Heartbeat:Connect(function()
			-- SKIP anti-clip entirely if player jumped
			if justJumped then
				return
			end

			if HumanoidRootPart then
				local velY = HumanoidRootPart.AssemblyLinearVelocity.Y

				-- Only correct if moving downward fast (falling through floor)
				if velY < -50 and isGrounded() == false then
					local ray =
						workspace:Raycast(HumanoidRootPart.Position + Vector3.new(0, 10, 0), Vector3.new(0, -20, 0))
					if ray and (HumanoidRootPart.Position.Y - ray.Position.Y) < 0 then
						-- Push up with velocity instead of teleporting (no camera jitter)
						HumanoidRootPart.AssemblyLinearVelocity = Vector3.new(
							HumanoidRootPart.AssemblyLinearVelocity.X,
							20, -- Gentle upward push
							HumanoidRootPart.AssemblyLinearVelocity.Z
						)
					end
				end
			end
		end)

		-- Smoothly stop
		local tween =
			TweenService:Create(bv, TweenInfo.new(rollDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Velocity = Vector3.new(0, 0, 0),
			})
		tween:Play()
		tween.Completed:Connect(function()
			bv:Destroy()
			animTrack:Stop(0.2)

			if antiClip then
				antiClip:Disconnect()
			end

			if isGrounded() then
				Humanoid:ChangeState(Enum.HumanoidStateType.Running)
			end

			task.delay(0.1, function()
				Humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
				Humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, true)
				Humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp, true)
			end)
		end)

		task.delay(rollCooldown, function()
			canRoll = true
		end)
	end
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then
			return
		end

		if not canRoll then
			return
		end
		if input.KeyCode == Enum.KeyCode.V or input.KeyCode == Enum.KeyCode.DPadRight then
			dive()
		end
	end)

	local function characterAdded()
		-- RemoteEvent for breaking shield
		BreakSpawnShield = ReplicatedStorage:WaitForChild("BreakSpawnShield")

		Player = Players.LocalPlayer
		Character = Player.Character or Player.CharacterAdded:Wait()
		Humanoid = Character:WaitForChild("Humanoid")
		HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
		Stamina = Character:WaitForChild("Stamina")

		-- Roll animation
		Animator = Humanoid:WaitForChild("Animator")
		RollAnimation = Instance.new("Animation")
		RollAnimation.AnimationId = "rbxassetid://104519680758175"

		canRoll = true
		rollCooldown = 1.2
		rollForce = 80
		rollDuration = 0.8
		justJumped = false

		local mobileButtons = Player:WaitForChild("PlayerGui"):WaitForChild("TouchGui", 5)
		if mobileButtons then
			local frame = mobileButtons:WaitForChild("TouchControlFrame")
			local button = frame:WaitForChild("DiveButton")

			button.Activated:Connect(function()
				if not canRoll then
					return
				end
				dive()
			end)
		end
	end

	Player.CharacterAdded:Connect(characterAdded)
	if Player.Character then
		characterAdded()
	end
end
return dive
