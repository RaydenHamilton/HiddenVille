--!strict
local GunHandlerClient = {}
--TODO load every var on equip
GunHandlerClient.__index = GunHandlerClient

--// Services
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

function GunHandlerClient.new(tool: Tool)
	local self = setmetatable({}, GunHandlerClient)
	--// References
	local Miscs = ReplicatedStorage:WaitForChild("Miscs")
	local Modules = ReplicatedStorage:WaitForChild("Modules")
	local Remotes = ReplicatedStorage:WaitForChild("Remotes")

	local GunVisualEffects = Miscs.GunVisualEffects

	self.Setting = tool:WaitForChild("Setting")

	--// Modules
	self.ProjectileHandler = require(Modules.ProjectileHandler)
	self.AudioHandler = require(Modules.AudioHandler)
	self.SmokeTrail = require(Modules.SmokeTrail)
	self.DamageModule = require(Modules.DamageModule)
	self.Utilities = require(Modules.Utilities)
	self.Module = require(self.Setting)

	--// self.Utilities
	self.Spring = self.Utilities.Spring
	self.Thread = self.Utilities.Thread
	self.ProjectileMotion = self.Utilities.ProjectileMotion
	self.Math = self.Utilities.Math

	--// Variables
	self.Tool = tool
	self.AnimationFolder = self.Tool:WaitForChild("AnimationFolder")
	self.ValueFolder = self.Tool:WaitForChild("ValueFolder")
	self.Player = Players.LocalPlayer
	self.Mouse = self.Player:GetMouse()
	self.Camera = Workspace.CurrentCamera
	self.Hud = ReplicatedStorage:WaitForChild("GunGUI")
	self.Character = Workspace:WaitForChild(self.Player.Name)
	self.Humanoid = self.Character:WaitForChild("Humanoid")
	self.HumanoidRootPart = self.Character:WaitForChild("HumanoidRootPart")
	self.Torso = self.Character:FindFirstChild("Torso") or self.Character:FindFirstChild("UpperTorso")
	self.PlayerGui = self.Player:WaitForChild("PlayerGui")
	self.GunGUI = nil
	self.Empty = self.Humanoid:LoadAnimation(self.Tool:FindFirstChild("Empty"))
	self.Handle = self.Tool:WaitForChild(self.Module.PrimaryHandle)

	--// connections
	self.MarkerEvent = self.Tool:WaitForChild("MarkerEvent")
	self.ChangeMagAndAmmo = self.Tool:WaitForChild("ChangeMagAndAmmo")
	self.FlingDeadBody = self.Tool:WaitForChild("FlingDeadBody")
	self.InflictTarget = Remotes.InflictTarget
	self.ShatterGlass = Remotes.ShatterGlass

	--// Assets
	self.BindToStepName = "UpdateGun_" .. HttpService:GenerateGUID()
	self.VisualEffects = self.Module.UseCommonVisualEffects and GunVisualEffects.Common
		or GunVisualEffects[self.Tool.Name]

	--Viewmodel
	self.FakeCamera = nil
	self.VMHandleToFire = self.Tool:FindFirstChild("Handle")
	self.CFAngles = nil

	self.VMKeyframes = {}
	self.VMKeyframeConnections = {}
	--
	self.Handle2 = nil
	self.HandleToFire = self.Handle
	self.Animations = {}
	self.SettingModules = {}
	self.Variables = {}
	self.KeyframeConnections = {}
	self.connections = {}
	self.Humanoids = {}
	self:LoadAnims()
	if self.Module.DualWeldEnabled then
		self.Handle2 = self.Tool:WaitForChild(self.Module.SecondaryHandle)
		if not self.Handle2 and self.Module.DualWeldEnabled then
			error('"Dual" setting is enabled but "Handle2" is missing!')
		end
	end

	self.CommonVariables = {
		Equipped = false,
		ActuallyEquipped = false,
		Enabled = true,
		Down = false,
		HoldDown = false,
		Reloading = false,
		AimDown = false,
		Scoping = false,
		Inspecting = false,
		Charging = false,
		Charged = false,
		Overheated = false,
		CanBeCooledDown = true,
		Switching = false,
		Alting = false,
		CurrentRate = 0,
		LastRate = 0,
		ElapsedTime = 0,
		InitialSensitivity = UserInputService.MouseDeltaSensitivity,
	}
	self.Tool.Equipped:Connect(function()
		self:OnEquipt()
	end)
end

function GunHandlerClient:ToolParentChange()
	if
		not self.Tool:IsDescendantOf(game)
		or self.Tool:IsDescendantOf(Workspace) and (not self.Tool:FindFirstAncestorOfClass("Model") or not Players:GetPlayerFromCharacter(
			self.Tool:FindFirstAncestorOfClass("Model")
		))
		or not self.Tool:IsDescendantOf(Workspace)
	then
		self:OnUnequipping()
	end
end

function GunHandlerClient:OnChangeMagAndAmmoEvent(Values)
	for _, v in ipairs(Values) do
		self.Variables[v.Id].Mag = v.Mag
		self.Variables[v.Id].Ammo = v.Ammo
		self.Variables[v.Id].Heat = v.Heat
	end
	self:UpdateGUI()
end

function GunHandlerClient:InputEnded(Input, GameProcessed)
	if GameProcessed then
		return
	end
	if not UserInputService.TouchEnabled then
		if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.KeyCode == self.Module.Controller.Fire then
			self:OnStoppingFiring()
		elseif Input.UserInputType == Enum.UserInputType.MouseButton2 then
			if self.CommonVariables.AimDown then
				TweenService:Create(
					self.Camera,
					TweenInfo.new(
						self.CurrentModule.TweenLengthNAD,
						self.CurrentModule.EasingStyleNAD,
						self.CurrentModule.EasingDirectionNAD
					),
					{ FieldOfView = 70 }
				):Play()
				if
					self.CurrentModule.AimAnimationsEnabled
					and self.CurrentAnimTable.AimIdleAnim
					and self.CurrentAnimTable.AimIdleAnim.IsPlaying
				then
					self.CurrentAnimTable.AimIdleAnim:Stop()
					if self.CurrentAnimTable.IdleAnim then
						self.CurrentAnimTable.IdleAnim:Play(nil, nil, self.CurrentModule.IdleAnimationSpeed)
					end
				end

				self.CommonVariables.Scoping = false
				self.Player.CameraMode = Enum.CameraMode.Classic
				UserInputService.MouseDeltaSensitivity = self.CommonVariables.InitialSensitivity
				self.CommonVariables.AimDown = false
			end
		end
	end
end

function GunHandlerClient:InputBegin(Input, GameProcessed)
	if GameProcessed then
		return
	end
	if not UserInputService.TouchEnabled then
		if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.KeyCode == self.Module.Controller.Fire then
			self:OnFiring()
		elseif Input.KeyCode == self.Module.Keyboard.Reload or Input.KeyCode == self.Module.Controller.Reload then
			self:Reload()
		elseif Input.KeyCode == self.Module.Keyboard.HoldDown or Input.KeyCode == self.Module.Controller.HoldDown then
			self:OnHoldingDown()
		elseif Input.KeyCode == self.Module.Keyboard.Inspect or Input.KeyCode == self.Module.Controller.Inspect then
			self:OnInspecting()
		elseif Input.KeyCode == self.Module.Keyboard.Switch or Input.KeyCode == self.Module.Controller.Switch then
			self:OnSwitching()
		elseif Input.KeyCode == self.Module.Keyboard.ToogleAim or Input.KeyCode == self.Module.Controller.ToogleAim then
			self:OnTooglingAiming()
		elseif Input.KeyCode == self.Module.Keyboard.Melee or Input.KeyCode == self.Module.Controller.Melee then
			self:OnMeleeAttacking()
		elseif Input.KeyCode == self.Module.Keyboard.AltFire or Input.KeyCode == self.Module.Controller.AltFire then
			self:OnAlting()
		elseif Input.UserInputType == Enum.UserInputType.MouseButton2 then
			if
				not self.CommonVariables.Reloading
				and not self.CommonVariables.Overheated
				and not self.CommonVariables.HoldDown
				and not self.CommonVariables.Alting
				and not self.CommonVariables.AimDown
				and self.CommonVariables.ActuallyEquipped
				and self.CurrentModule.IronsightEnabled
				and (self.Camera.Focus.p - self.Camera.CoordinateFrame.p).Magnitude <= 1
			then
				if not self.CurrentModule.KeepAimingOnReloading then
					if self.CommonVariables.Reloading or self.CommonVariables.Overheated then
						return
					end
				end
				TweenService:Create(
					self.Camera,
					TweenInfo.new(
						self.CurrentModule.TweenLength,
						self.CurrentModule.EasingStyle,
						self.CurrentModule.EasingDirection
					),
					{ FieldOfView = self.CurrentModule.FieldOfViewIS }
				):Play()
				if self.CurrentAnimTable.InspectAnim and self.CurrentAnimTable.InspectAnim.IsPlaying then
					self.CurrentAnimTable.InspectAnim:Stop()
				end
				if
					self.CurrentModule.AimAnimationsEnabled
					and self.CurrentAnimTable.IdleAnim
					and self.CurrentAnimTable.IdleAnim.IsPlaying
				then
					self.CurrentAnimTable.IdleAnim:Stop()
					if self.CurrentAnimTable.AimIdleAnim then
						self.CurrentAnimTable.AimIdleAnim:Play(nil, nil, self.CurrentModule.AimIdleAnimationSpeed)
					end
				end

				self.Player.CameraMode = Enum.CameraMode.LockFirstPerson
				UserInputService.MouseDeltaSensitivity = self.CommonVariables.InitialSensitivity
					* self.CurrentModule.MouseSensitiveIS
				self.CommonVariables.AimDown = true
			elseif
				not self.CommonVariables.Reloading
				and not self.CommonVariables.Overheated
				and not self.CommonVariables.HoldDown
				and not self.CommonVariables.Alting
				and not self.CommonVariables.AimDown
				and self.CommonVariables.ActuallyEquipped
				and self.CurrentModule.SniperEnabled
				and (self.Camera.Focus.p - self.Camera.CoordinateFrame.p).Magnitude <= 1
			then
				if not self.CurrentModule.KeepAimingOnReloading then
					if self.CommonVariables.Reloading or self.CommonVariables.Overheated then
						return
					end
				end
				TweenService:Create(
					self.Camera,
					TweenInfo.new(
						self.CurrentModule.TweenLength,
						self.CurrentModule.EasingStyle,
						self.CurrentModule.EasingDirection
					),
					{ FieldOfView = self.CurrentModule.FieldOfViewS }
				):Play()
				if self.CurrentAnimTable.InspectAnim and self.CurrentAnimTable.InspectAnim.IsPlaying then
					self.CurrentAnimTable.InspectAnim:Stop()
				end
				if
					self.CurrentModule.AimAnimationsEnabled
					and self.CurrentAnimTable.IdleAnim
					and self.CurrentAnimTable.IdleAnim.IsPlaying
				then
					self.CurrentAnimTable.IdleAnim:Stop()
					if self.CurrentAnimTable.AimIdleAnim then
						self.CurrentAnimTable.AimIdleAnim:Play(nil, nil, self.CurrentModule.AimIdleAnimationSpeed)
					end
				end

				self.CommonVariables.AimDown = true
				local StartTime = os.clock()
				repeat
					self.Thread:Wait()
					if not (self.CommonVariables.ActuallyEquipped or self.CommonVariables.AimDown) then
						break
					end
				until (os.clock() - StartTime) >= self.CurrentModule.ScopeDelay
				if self.CommonVariables.ActuallyEquipped and self.CommonVariables.AimDown then
					local ZoomSound = self.GunGUI.Scope.ZoomSound:Clone()
					ZoomSound.Parent = self.PlayerGui
					ZoomSound:Play()
					ZoomSound.Ended:Connect(function()
						ZoomSound:Destroy()
					end)
					self.Player.CameraMode = Enum.CameraMode.LockFirstPerson
					UserInputService.MouseDeltaSensitivity = self.CommonVariables.InitialSensitivity
						* self.CurrentModule.MouseSensitiveS
					self.CommonVariables.Scoping = true
				end
			end
		end
	end
end

function GunHandlerClient:LoadAnims()
	for i, v in ipairs(self.Setting:GetChildren()) do
		table.insert(self.SettingModules, require(v))
		local Folder = self.ValueFolder:FindFirstChild(tostring(i)) :: Folder
		table.insert(self.Variables, {
			Mag = (Folder:FindFirstChild("Mag") :: IntValue).Value,
			Ammo = (Folder:FindFirstChild("Ammo") :: IntValue).Value,
			Heat = (Folder:FindFirstChild("Heat") :: IntValue).Value,
			MaxAmmo = self.SettingModules[i].MaxAmmo,
			ElapsedCooldownTime = 0,
			ChargeLevel = 0,
			FireModes = self.SettingModules[i].FireModes,
			FireMode = 1,
			ShotsForDepletion = 0,
			ShotID = 0,
		})
	end
	self.CurrentFireMode = 1
	self.CurrentModule = self.SettingModules[self.CurrentFireMode]
	self.CurrentVariables = self.Variables[self.CurrentFireMode]
	--for the scope wiggle
	self.Scope = self.Spring.spring.new(Vector3.new(0, 200, 0))
	self.Scope.s = self.CurrentModule.ScopeSwaySpeed
	self.Scope.d = self.CurrentModule.ScopeSwayDamper
	--for the knockback wiggle
	self.Knockback = self.Spring.spring.new(Vector3.new())
	self.Knockback.s = self.CurrentModule.ScopeKnockbackSpeed
	self.Knockback.d = self.CurrentModule.ScopeKnockbackDamper

	-- Dead body fling cooldown to prevent packet spam
	self.LastFlingTime = 0
	self.FLING_COOLDOWN = 0.1 -- Only send fling request every 0.1 seconds max

	-- Screen effect for hitting dead bodies (Da Bronx style)
	self.DeadBodyHitEffect = nil
	--camera

	self.CameraSpring = self.Spring.spring.new(Vector3.new())
	self.CameraSpring.s = self.CurrentModule.RecoilSpeed
	self.CameraSpring.d = self.CurrentModule.RecoilDamper

	self.CrossHairColors = {
		Idle = Color3.fromRGB(255, 255, 255), -- White when idle
		Aiming = Color3.fromRGB(150, 150, 150), -- Gray when aiming at someone
		Hit = Color3.fromRGB(199, 2, 2), -- Red when shot someone
	}
	self.CurrentCrosshairState = "Idle"
	self.CrosshairHitResetTime = 0.15 -- Time in seconds for red color to show after hitting
	-- Crosshair hit animation function
	-- Store original values and active tweens to prevent rapid fire bugs
	self.CrosshairOriginalValues = {
		CenterSize = UDim2.fromOffset(7, 7),
		CenterRotation = 0,
		HR_Position = nil,
		HL_Position = nil,
		VD_Position = nil,
		VU_Position = nil,
	}
	self.ActiveCrosshairTweens = {}
	for i, v in ipairs(self.AnimationFolder:GetChildren()) do
		local AnimTable = {}
		if self.SettingModules[i].EquippedAnimationID ~= nil then
			AnimTable.EquippedAnim = v.ThirdPerson:WaitForChild("EquippedAnim")
			AnimTable.EquippedAnim = self.Humanoid:LoadAnimation(AnimTable.EquippedAnim)
		end
		if self.SettingModules[i].IdleAnimationID ~= nil then
			AnimTable.IdleAnim = v.ThirdPerson:WaitForChild("IdleAnim")
			AnimTable.IdleAnim = self.Humanoid:LoadAnimation(AnimTable.IdleAnim)
		end

		if self.SettingModules[i].FireAnimationID ~= nil then
			AnimTable.FireAnim = v.ThirdPerson:WaitForChild("FireAnim")
			AnimTable.FireAnim = self.Humanoid:LoadAnimation(AnimTable.FireAnim)
		end
		if self.SettingModules[i].ShotgunPumpinAnimationID ~= nil then
			AnimTable.ShotgunPumpinAnim = v.ThirdPerson:WaitForChild("ShotgunPumpinAnim")
			AnimTable.ShotgunPumpinAnim = self.Humanoid:LoadAnimation(AnimTable.ShotgunPumpinAnim)
		end
		if self.SettingModules[i].ShotgunClipinAnimationID ~= nil then
			AnimTable.ShotgunClipinAnim = v.ThirdPerson:WaitForChild("ShotgunClipinAnim")
			AnimTable.ShotgunClipinAnim = self.Humanoid:LoadAnimation(AnimTable.ShotgunClipinAnim)
		end
		if self.SettingModules[i].ReloadAnimationID ~= nil then
			AnimTable.ReloadAnim = v.ThirdPerson:WaitForChild("ReloadAnim")
			AnimTable.ReloadAnim = self.Humanoid:LoadAnimation(AnimTable.ReloadAnim)
		end
		if self.SettingModules[i].HoldDownAnimationID ~= nil then
			AnimTable.HoldDownAnim = v.ThirdPerson:WaitForChild("HoldDownAnim")
			AnimTable.HoldDownAnim = self.Humanoid:LoadAnimation(AnimTable.HoldDownAnim)
		end
		if
			self.SettingModules[i].SecondaryFireAnimationEnabled
			and self.SettingModules[i].SecondaryFireAnimationID ~= nil
		then
			AnimTable.SecondaryFireAnim = v.ThirdPerson:WaitForChild("SecondaryFireAnim")
			AnimTable.SecondaryFireAnim = self.Humanoid:LoadAnimation(AnimTable.SecondaryFireAnim)
		end
		if
			self.SettingModules[i].SecondaryShotgunPump
			and self.SettingModules[i].SecondaryShotgunPumpinAnimationID ~= nil
		then
			AnimTable.SecondaryShotgunPumpinAnim = v.ThirdPerson:WaitForChild("SecondaryShotgunPumpinAnim")
			AnimTable.SecondaryShotgunPumpinAnim = self.Humanoid:LoadAnimation(AnimTable.SecondaryShotgunPumpinAnim)
		end
		if self.SettingModules[i].AimAnimationsEnabled and self.SettingModules[i].AimIdleAnimationID ~= nil then
			AnimTable.AimIdleAnim = v.ThirdPerson:WaitForChild("AimIdleAnim")
			AnimTable.AimIdleAnim = self.Humanoid:LoadAnimation(AnimTable.AimIdleAnim)
		end
		if self.SettingModules[i].AimAnimationsEnabled and self.SettingModules[i].AimFireAnimationID ~= nil then
			AnimTable.AimFireAnim = v.ThirdPerson:WaitForChild("AimFireAnim")
			AnimTable.AimFireAnim = self.Humanoid:LoadAnimation(AnimTable.AimFireAnim)
		end
		if
			self.SettingModules[i].AimAnimationsEnabled
			and self.SettingModules[i].AimSecondaryFireAnimationID ~= nil
		then
			AnimTable.AimSecondaryFireAnim = v.ThirdPerson:WaitForChild("AimSecondaryFireAnim")
			AnimTable.AimSecondaryFireAnim = self.Humanoid:LoadAnimation(AnimTable.AimSecondaryFireAnim)
		end
		if self.SettingModules[i].AimAnimationsEnabled and self.SettingModules[i].AimChargingAnimationID ~= nil then
			AnimTable.AimChargingAnim = v.ThirdPerson:WaitForChild("AimChargingAnim")
			AnimTable.AimChargingAnim = self.Humanoid:LoadAnimation(AnimTable.AimChargingAnim)
		end
		if
			self.SettingModules[i].TacticalReloadAnimationEnabled
			and self.SettingModules[i].TacticalReloadAnimationID ~= nil
		then
			AnimTable.TacticalReloadAnim = v.ThirdPerson:WaitForChild("TacticalReloadAnim")
			AnimTable.TacticalReloadAnim = self.Humanoid:LoadAnimation(AnimTable.TacticalReloadAnim)
		end
		if self.SettingModules[i].InspectAnimationEnabled and self.SettingModules[i].InspectAnimationID ~= nil then
			AnimTable.InspectAnim = v.ThirdPerson:WaitForChild("InspectAnim")
			AnimTable.InspectAnim = self.Humanoid:LoadAnimation(AnimTable.InspectAnim)
		end
		if
			self.SettingModules[i].ShotgunReload
			and self.SettingModules[i].PreShotgunReload
			and self.SettingModules[i].PreShotgunReloadAnimationID ~= nil
		then
			AnimTable.PreShotgunReloadAnim = v.ThirdPerson:WaitForChild("PreShotgunReloadAnim")
			AnimTable.PreShotgunReloadAnim = self.Humanoid:LoadAnimation(AnimTable.PreShotgunReloadAnim)
		end
		if self.SettingModules[i].MinigunRevUpAnimationID ~= nil then
			AnimTable.MinigunRevUpAnim = v.ThirdPerson:WaitForChild("MinigunRevUpAnim")
			AnimTable.MinigunRevUpAnim = self.Humanoid:LoadAnimation(AnimTable.MinigunRevUpAnim)
		end
		if self.SettingModules[i].MinigunRevDownAnimationID ~= nil then
			AnimTable.MinigunRevDownAnim = v.ThirdPerson:WaitForChild("MinigunRevDownAnim")
			AnimTable.MinigunRevDownAnim = self.Humanoid:LoadAnimation(AnimTable.MinigunRevDownAnim)
		end
		if self.SettingModules[i].ChargingAnimationEnabled and self.SettingModules[i].ChargingAnimationID ~= nil then
			AnimTable.ChargingAnim = v.ThirdPerson:WaitForChild("ChargingAnim")
			AnimTable.ChargingAnim = self.Humanoid:LoadAnimation(AnimTable.ChargingAnim)
		end
		if self.SettingModules[i].SelectiveFireEnabled and self.SettingModules[i].SwitchAnimationID ~= nil then
			AnimTable.SwitchAnim = v.ThirdPerson:WaitForChild("SwitchAnim")
			AnimTable.SwitchAnim = self.Humanoid:LoadAnimation(AnimTable.SwitchAnim)
		end
		if self.SettingModules[i].BatteryEnabled and self.SettingModules[i].OverheatAnimationID ~= nil then
			AnimTable.OverheatAnim = v.ThirdPerson:WaitForChild("OverheatAnim")
			AnimTable.OverheatAnim = self.Humanoid:LoadAnimation(AnimTable.OverheatAnim)
		end
		if self.SettingModules[i].MeleeAttackEnabled and self.SettingModules[i].MeleeAttackAnimationID ~= nil then
			AnimTable.MeleeAttackAnim = v.ThirdPerson:WaitForChild("MeleeAttackAnim")
			AnimTable.MeleeAttackAnim = self.Humanoid:LoadAnimation(AnimTable.MeleeAttackAnim)
		end
		if self.Module.AltFire and self.SettingModules[i].AltAnimationID ~= nil then
			AnimTable.AltAnim = v.ThirdPerson:WaitForChild("AltAnim")
			AnimTable.AltAnim = self.Humanoid:LoadAnimation(AnimTable.AltAnim)
		end
		table.insert(self.Animations, AnimTable)
	end
	self.CurrentAnimTable = self.Animations[self.CurrentFireMode]

	if self.CurrentModule.AimAnimationsEnabled then
		self.CurrentAimFireAnim = self.CurrentAnimTable.AimFireAnim
		self.CurrentAimFireAnimationSpeed = self.CurrentModule.AimFireAnimationSpeed
	end
	self.CurrentFireAnim = self.CurrentAnimTable.FireAnim
	self.CurrentFireAnimationSpeed = self.CurrentModule.FireAnimationSpeed
	self.CurrentShotgunPumpinAnim = self.CurrentAnimTable.ShotgunPumpinAnim
	self.CurrentShotgunPumpinAnimationSpeed = self.CurrentModule.ShotgunPumpinSpeed
end

function GunHandlerClient:SetCrosshairColor(color)
	if self.GunGUI and self.GunGUI:FindFirstChild("Crosshair") then
		local CrossFrame = self.GunGUI.Crosshair:FindFirstChild("Main")
		if CrossFrame then
			local Center = CrossFrame:FindFirstChild("Center")
			if Center then
				Center.ImageColor3 = color
			end
		end
	end
end

function GunHandlerClient:IsAimingAtPlayer()
	if not self.GunGUI or not self.GunGUI:FindFirstChild("Crosshair") then
		return false
	end

	local crosshairPos = self.GunGUI.Crosshair.AbsolutePosition
	local InputRay = self.Camera:ScreenPointToRay(crosshairPos.X, crosshairPos.Y)
	local raycastParams = RaycastParams.new()
	raycastParams.FilterDescendantsInstances = { self.Camera, self.Tool, self.Character }
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude

	local raycastResult = Workspace:Raycast(InputRay.Origin, InputRay.Direction * 1000, raycastParams)
	if raycastResult and raycastResult.Instance then
		local hitPart = raycastResult.Instance
		local model = hitPart:FindFirstAncestorOfClass("Model")
		if model then
			local humanoid = model:FindFirstChildOfClass("Humanoid")
			if humanoid and humanoid.Health > 0 then
				-- Make sure it's a damageable target
				if self.DamageModule.CanDamage(model, self.Character, self.CurrentModule.FriendlyFire) then
					return true
				end
			end
		end
	end
	return false
end

function GunHandlerClient:PlayDeadBodyHitEffect()
	if not self.GunGUI then
		return
	end

	-- Create flash effect if it doesn't exist
	if not self.DeadBodyHitEffect or not self.DeadBodyHitEffect.Parent then
		self.DeadBodyHitEffect = Instance.new("Frame")
		self.DeadBodyHitEffect.Name = "DeadBodyHitEffect"
		self.DeadBodyHitEffect.Size = UDim2.fromScale(1, 1)
		self.DeadBodyHitEffect.Position = UDim2.new(0, 0, 0, 0)
		self.DeadBodyHitEffect.BackgroundTransparency = 1
		self.DeadBodyHitEffect.BorderSizePixel = 0
		self.DeadBodyHitEffect.ZIndex = 100
		self.DeadBodyHitEffect.Parent = self.GunGUI

		-- Create white flash overlay
		local flashOverlay = Instance.new("Frame")
		flashOverlay.Name = "FlashOverlay"
		flashOverlay.Size = UDim2.fromScale(1, 1)
		flashOverlay.Position = UDim2.new(0, 0, 0, 0)
		flashOverlay.BackgroundColor3 = Color3.fromRGB(255, 255, 255) -- Bright white
		flashOverlay.BackgroundTransparency = 1
		flashOverlay.BorderSizePixel = 0
		flashOverlay.ZIndex = 100
		flashOverlay.Parent = self.DeadBodyHitEffect
	end

	local flashOverlay = self.DeadBodyHitEffect:FindFirstChild("FlashOverlay")

	-- Instant flash, then fade out
	if flashOverlay then
		-- Instantly set to visible (bright white flash)
		flashOverlay.BackgroundTransparency = 0.7

		-- Fade out
		local fadeInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		local fadeTween = TweenService:Create(flashOverlay, fadeInfo, { BackgroundTransparency = 1 })
		fadeTween:Play()
	end
end

function GunHandlerClient:CheckAndFlingDeadBody(fireDirection)
	-- Check cooldown first to prevent spam
	local currentTime = tick()
	if currentTime - self.LastFlingTime < self.FLING_COOLDOWN then
		return
	end

	if not self.GunGUI or not self.GunGUI:FindFirstChild("Crosshair") then
		return
	end

	local crosshairPos = self.GunGUI.Crosshair.AbsolutePosition
	local InputRay = self.Camera:ScreenPointToRay(crosshairPos.X, crosshairPos.Y)
	local raycastParams = RaycastParams.new()
	raycastParams.FilterDescendantsInstances = { self.Camera, self.Tool, self.Character }
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude

	local raycastResult = Workspace:Raycast(InputRay.Origin, InputRay.Direction * 1000, raycastParams)
	if raycastResult and raycastResult.Instance then
		local hitPart = raycastResult.Instance
		local model = hitPart:FindFirstAncestorOfClass("Model")
		if model then
			local humanoid = model:FindFirstChildOfClass("Humanoid")
			-- Check if this is a dead body (humanoid dead or doesn't exist - ragdoll)
			if humanoid and humanoid.Health <= 0 then
				-- Update cooldown and send request
				self.LastFlingTime = currentTime
				local direction = fireDirection or InputRay.Direction
				local dir = direction.Unit
				-- Send the part reference directly (Roblox serializes this efficiently)
				self.FlingDeadBody:FireServer(hitPart, dir)

				-- Show red crosshair when hitting dead body
				self:SetCrosshairColor(self.CrossHairColors.Hit)
				self.CurrentCrosshairState = "Hit"
				task.delay(self.CrosshairHitResetTime, function()
					if self.CurrentCrosshairState == "Hit" then
						self.CurrentCrosshairState = "Idle"
					end
				end)

				-- Play screen effect
				self:PlayDeadBodyHitEffect()

				-- Play random shot sound effect on the dead body
				local shotSound = math.random(1, 2) == 1 and self.Tool:FindFirstChild("Shot1")
					or self.Tool:FindFirstChild("Shot2")
				if shotSound then
					local soundClone = shotSound:Clone()
					soundClone.Parent = hitPart
					soundClone:Play()
					game:GetService("Debris"):AddItem(soundClone, soundClone.TimeLength + 0.5)
				end
			end
		end
	end
end

function GunHandlerClient:AddressTableValue(v1, v2)
	if v1 ~= nil and self.CurrentModule.ChargedShotAdvanceEnabled then
		return (
			(self.CurrentVariables.ChargeLevel == 1 and v1.Level1)
			or (self.CurrentVariables.ChargeLevel == 2 and v1.Level2)
			or (self.CurrentVariables.ChargeLevel == 3 and v1.Level3)
			or v2
		)
	else
		return v2
	end
end

function GunHandlerClient:PopulateHumanoids(mdl)
	if mdl.ClassName == "Humanoid" then
		if self.DamageModule.CanDamage(mdl.Parent, self.Character, self.CurrentModule.FriendlyFire) then
			table.insert(self.Humanoids, mdl)
		end
	end
	for _, mdl2 in ipairs(mdl:GetChildren()) do
		self:PopulateHumanoids(mdl2)
	end
end

function GunHandlerClient:CastRay(StartPos, Direction, Length)
	local Hit, EndPos = Workspace:FindPartOnRayWithIgnoreList(
		Ray.new(StartPos, Direction * Length),
		{ self.Camera, self.Tool, self.Character }
	)
	if Hit then
		local FirePointObject = self.HandleToFire:FindFirstChild("GunFirePoint" .. self.CurrentFireMode)
		if FirePointObject ~= nil then
			local TipCFrame = FirePointObject.WorldCFrame
			local TipPos = TipCFrame.Position
			local TipDir = TipCFrame.LookVector
			local AmountToCheatBack = math.abs((self.HumanoidRootPart.Position - TipPos):Dot(TipDir)) + 1
			local GunRay = Ray.new(TipPos - TipDir.Unit * AmountToCheatBack, TipDir.Unit * AmountToCheatBack)
			local HitPart, HitPoint =
				Workspace:FindPartOnRayWithIgnoreList(GunRay, { self.Camera, self.Tool, self.Character }, false, true)
			if HitPart and math.abs((TipPos - HitPoint).Magnitude) > 0 then
				return self:CastRay(EndPos + (Direction * 0.01), Direction, Length - (StartPos - EndPos).Magnitude)
			end
		end
	end
	return EndPos
end

function GunHandlerClient:Get3DPosition(CurrentPosOnScreen)
	local InputRay = self.Camera:ScreenPointToRay(CurrentPosOnScreen.X, CurrentPosOnScreen.Y)
	local EndPos = InputRay.Origin + InputRay.Direction
	return self:CastRay(self.Camera.CFrame.p, (EndPos - self.Camera.CFrame.p).Unit, 5000)
end

function GunHandlerClient:WorldToScreen(Viewpoint)
	local ToObjectSpace = self.Camera.CFrame:pointToObjectSpace(Viewpoint)
	local FieldOfView = math.tan(math.rad(self.Camera.FieldOfView) / 2)
	return Vector2.new(
		self.Camera.ViewportSize.X
			* (
				0.5
				+ 0.5
					* (ToObjectSpace.X / ToObjectSpace.Z / -(self.Camera.ViewportSize.X / self.Camera.ViewportSize.Y * FieldOfView))
			),
		self.Camera.ViewportSize.Y * (0.5 + 0.5 * (ToObjectSpace.Y / ToObjectSpace.Z / FieldOfView))
	)
end

function GunHandlerClient:FindNearestEntity()
	self.Humanoids = {}
	self:PopulateHumanoids(Workspace)
	local MinOffset = nil
	local TargetModel = nil
	local TargetHumanoid = nil
	local TargetTorso = nil
	for _, v in ipairs(self.Humanoids) do
		local torso = v.Parent:FindFirstChild("HumanoidRootPart")
			or v.Parent:FindFirstChild("Torso")
			or v.Parent:FindFirstChild("UpperTorso")
		if v and torso then
			local Dist = (self.Character.Head.Position - torso.Position).Magnitude
			local MousePos = self:Get3DPosition(self.GunGUI.Crosshair.AbsolutePosition)
			local MouseDirection = (MousePos - self.Character.Head.Position).Unit
			local Offset = (((MouseDirection * Dist) + self.Character.Head.Position) - torso.Position).Magnitude
			if Offset < self.CurrentModule.LockOnRadius and (not MinOffset or Offset < MinOffset) and v.Health > 0 then
				if self.DamageModule.CanDamage(v.Parent, self.Character, self.CurrentModule.FriendlyFire) then
					TargetModel = v.Parent
					TargetHumanoid = v
					TargetTorso = torso
				end
			end
		end
	end
	return TargetModel, TargetHumanoid, TargetTorso
end

function GunHandlerClient:UpdateGUI()
	self.GunGUI.Frame.Mag.Fill:TweenSize(
		UDim2.fromScale(self.CurrentVariables.Mag / self.CurrentModule.AmmoPerMag, 1),
		Enum.EasingDirection.Out,
		Enum.EasingStyle.Quint,
		0.25,
		true
	)
	self.GunGUI.Frame.Ammo.Fill:TweenSize(
		UDim2.fromScale(self.CurrentVariables.Ammo / self.CurrentModule.MaxAmmo, 1),
		Enum.EasingDirection.Out,
		Enum.EasingStyle.Quint,
		0.25,
		true
	)
	self.GunGUI.Frame.Heat.Fill:TweenSize(
		UDim2.fromScale(self.CurrentVariables.Heat / self.CurrentModule.MaxHeat, 1),
		Enum.EasingDirection.Out,
		Enum.EasingStyle.Quint,
		0.25,
		true
	)
	self.GunGUI.Frame.Mag.Current.Text = self.CurrentVariables.Mag
	self.GunGUI.AmmoWidgetContainer.ContentLayer.CurrentAmmoTxt.Text = self.CurrentVariables.Mag
	self.GunGUI.Frame.Mag.Max.Text = self.CurrentModule.AmmoPerMag
	self.GunGUI.Frame.Mag.FireMode.Text = self.Tool.Name
	self.GunGUI.Frame.Ammo.Current.Text = self.CurrentVariables.Ammo
	self.GunGUI.Frame.Ammo.Max.Text = self.CurrentModule.MaxAmmo
	self.GunGUI.Frame.Heat.Current.Text = self.CurrentVariables.Heat
	self.GunGUI.Frame.Heat.Max.Text = self.CurrentModule.MaxHeat
	self.GunGUI.Frame.Heat.FireMode.Text = self.CurrentModule.FireModeTexts[self.CurrentVariables.FireMode]

	self.GunGUI.Frame.Mag.Current.Visible = not self.CommonVariables.Reloading
	self.GunGUI.Frame.Mag.Max.Visible = not self.CommonVariables.Reloading
	self.GunGUI.Frame.Mag.Frame.Visible = not self.CommonVariables.Reloading
	self.GunGUI.Frame.Mag.Reloading.Visible = self.CommonVariables.Reloading
	self.GunGUI.Frame.Mag.FireMode.Visible = self.CurrentModule.SelectiveFireEnabled

	self.GunGUI.Frame.Ammo.Current.Visible = not (self.CurrentVariables.Ammo <= 0)
	self.GunGUI.Frame.Ammo.Max.Visible = not (self.CurrentVariables.Ammo <= 0)
	self.GunGUI.Frame.Ammo.Frame.Visible = not (self.CurrentVariables.Ammo <= 0)
	self.GunGUI.Frame.Ammo.NoMoreAmmo.Visible = (self.CurrentVariables.Ammo <= 0)

	self.GunGUI.Frame.Heat.Visible = self.CurrentModule.BatteryEnabled
	self.GunGUI.Frame.Heat.Current.Visible = not self.CommonVariables.Overheated
	self.GunGUI.Frame.Heat.Max.Visible = not self.CommonVariables.Overheated
	self.GunGUI.Frame.Heat.Frame.Visible = not self.CommonVariables.Overheated
	self.GunGUI.Frame.Heat.Overheated.Visible = self.CommonVariables.Overheated
	self.GunGUI.Frame.Heat.FireMode.Visible = self.CurrentModule.SelectiveFireEnabled

	self.GunGUI.ChargeBar.Visible = (
		self.CurrentModule.ChargedShotAdvanceEnabled or self.CurrentModule.HoldAndReleaseEnabled
	)
	self.GunGUI.ChargeBar.Level1.Visible = not self.CurrentModule.HoldAndReleaseEnabled
	self.GunGUI.ChargeBar.Level2.Visible = not self.CurrentModule.HoldAndReleaseEnabled
	self.GunGUI.ChargeBar.Level1.Position =
		UDim2.fromScale(self.CurrentModule.Level1ChargingTime / self.CurrentModule.AdvancedChargingTime, 0.5)
	self.GunGUI.ChargeBar.Level2.Position =
		UDim2.fromScale(self.CurrentModule.Level2ChargingTime / self.CurrentModule.AdvancedChargingTime, 0.5)

	self.GunGUI.Frame.Mag.Visible = not self.CurrentModule.BatteryEnabled
	self.GunGUI.Frame.Ammo.Visible = self.CurrentModule.LimitedAmmoEnabled
	self.GunGUI.Frame.Heat.Visible = self.CurrentModule.BatteryEnabled

	self.GunGUI.MobileButtons.Visible = UserInputService.TouchEnabled --For mobile version
	local AimButton = self.GunGUI.MobileButtons.AimButton
	local HoldDownButton = self.GunGUI.MobileButtons.HoldDownButton
	local InspectButton = self.GunGUI.MobileButtons.InspectButton
	local ReloadButton = self.GunGUI.MobileButtons.ReloadButton
	local SwitchButton = self.GunGUI.MobileButtons.SwitchButton
	local MeleeButton = self.GunGUI.MobileButtons.MeleeButton
	local AltButton = self.GunGUI.MobileButtons.AltButton

	AimButton.Visible = self.CurrentModule.SniperEnabled or self.CurrentModule.IronsightEnabled
	HoldDownButton.Visible = self.CurrentModule.HoldDownEnabled
	InspectButton.Visible = self.CurrentModule.InspectAnimationEnabled
	SwitchButton.Visible = self.CurrentModule.SelectiveFireEnabled
	ReloadButton.Visible = not self.CurrentModule.BatteryEnabled
	MeleeButton.Visible = self.CurrentModule.MeleeAttackEnabled
	AltButton.Visible = self.Module.AltFire
end

function GunHandlerClient:RenderScope()
	self.Knockback.t = self.Knockback.t:Lerp(Vector3.new(), 0.2)
end

function GunHandlerClient:RenderMouse()
	local Delta = UserInputService:GetMouseDelta() / self.CurrentModule.ScopeSensitive
	local Offset = self.GunGUI.Scope.AbsoluteSize.X * 0.5

	if self.CommonVariables.Scoping and UserInputService.MouseEnabled and UserInputService.KeyboardEnabled then --For pc version
		self.GunGUI.Scope.Position =
			UDim2.fromOffset(self.Scope.p.X + (self.Knockback.p.Y * 1000), self.Scope.p.Y + (self.Knockback.p.X * 200))
		self.Scope.t = Vector3.new(self.Mouse.X - Offset - Delta.X, self.Mouse.Y - Offset - Delta.Y, 0)
	elseif
		self.CommonVariables.Scoping
		and UserInputService.TouchEnabled
		and not UserInputService.MouseEnabled
		and not UserInputService.KeyboardEnabled
	then --For mobile version, but in first-person view
		self.GunGUI.Scope.Position =
			UDim2.fromOffset(self.Scope.p.X + (self.Knockback.p.Y * 1000), self.Scope.p.Y + (self.Knockback.p.X * 200))
		self.Scope.t = Vector3.new(
			self.GunGUI.Crosshair.AbsolutePosition.X - Offset - Delta.X,
			self.GunGUI.Crosshair.AbsolutePosition.Y - Offset - Delta.Y,
			0
		)
	end

	self.GunGUI.Scope.Visible = self.CommonVariables.Scoping
	if not self.CommonVariables.Scoping then
		self.GunGUI.Crosshair.Main.Visible = true
		self.Scope.t = Vector3.new(600, 200, 0)
	else
		self.GunGUI.Crosshair.Main.Visible = false
	end

	if UserInputService.MouseEnabled and UserInputService.KeyboardEnabled then --For pc version
		if self.FakeCamera then
			self.CFAngles = CFrame.fromEulerAnglesXYZ(self.FakeCamera.Transform:ToEulerAnglesXYZ()) or CFrame.new()
			if (self.Camera.Focus.p - self.Camera.CoordinateFrame.p).Magnitude <= 1 then
				if self.CFAngles then
					local v = self:WorldToScreen(
						(self.Camera.CFrame * self.CFAngles:Inverse() * CFrame.new(0, 0, -4)).Position
					)
					local v2 = self.Camera.ViewportSize / 2
					self.GunGUI.Crosshair.Position = (v - v2).Magnitude > 0.08 and UDim2.fromOffset(v.X, v.Y)
						or UDim2.fromOffset(v2.X, v2.Y)
				else
					self.GunGUI.Crosshair.Position = UDim2.fromOffset(self.Mouse.X, self.Mouse.Y)
				end
			else
				self.GunGUI.Crosshair.Position = UDim2.fromOffset(self.Mouse.X, self.Mouse.Y)
			end
		else
			self.GunGUI.Crosshair.Position = UDim2.fromOffset(self.Mouse.X, self.Mouse.Y)
		end
	elseif
		UserInputService.TouchEnabled
		and not UserInputService.MouseEnabled
		and not UserInputService.KeyboardEnabled
		and (self.Character.Head.Position - self.Camera.CoordinateFrame.p).Magnitude > 2
	then --For mobile version, but in third-person view
		self.GunGUI.Crosshair.Position = UDim2.fromScale(0.5, 0.2)
	elseif
		UserInputService.TouchEnabled
		and not UserInputService.MouseEnabled
		and not UserInputService.KeyboardEnabled
		and (self.Character.Head.Position - self.Camera.CoordinateFrame.p).Magnitude <= 2
	then --For mobile version, but in first-person view
		if self.FakeCamera then
			self.CFAngles = CFrame.fromEulerAnglesXYZ(self.FakeCamera.Transform:ToEulerAnglesXYZ()) or CFrame.new()
			if (self.Camera.Focus.p - self.Camera.CoordinateFrame.p).Magnitude <= 1 then
				if self.CFAngles then
					local v = self:WorldToScreen(
						(self.Camera.CFrame * self.CFAngles:Inverse() * CFrame.new(0, 0, -4)).Position
					)
					local v2 = self.Camera.ViewportSize / 2
					self.GunGUI.Crosshair.Position = (v - v2).Magnitude > 0.08 and UDim2.fromOffset(v.X, v.Y)
						or UDim2.fromOffset(v2.X, v2.Y)
				else
					self.GunGUI.Crosshair.Position = UDim2.fromScale(0.5, 0.2)
				end
			else
				self.GunGUI.Crosshair.Position = UDim2.fromScale(0.5, 0.2)
			end
		else
			self.GunGUI.Crosshair.Position = UDim2.fromScale(0.5, 0.2)
		end
	end

	if
		self:AddressTableValue(self.CurrentModule.ChargeAlterTable.Homing, self.CurrentModule.Homing)
		and self.CurrentModule.LockOnOnHovering
		and not self.CurrentModule.HitscanMode
	then
		local TargetEntity, TargetHumanoid, TargetTorso = self:FindNearestEntity()
		if TargetEntity and TargetHumanoid and TargetTorso then
			self.LockedEntity = TargetEntity
		else
			self.LockedEntity = nil
		end
	end

	-- Update crosshair color based on state (only if not in hit state)
	if self.CurrentCrosshairState ~= "Hit" then
		if self:IsAimingAtPlayer() then
			self:SetCrosshairColor(self.CrossHairColors.Aiming)
			self.CurrentCrosshairState = "Aiming"
		else
			self:SetCrosshairColor(self.CrossHairColors.Idle)
			self.CurrentCrosshairState = "Idle"
		end
	end
end

function GunHandlerClient:RenderCam()
	self.Camera.CoordinateFrame = self.Camera.CoordinateFrame
		* CFrame.Angles(self.CameraSpring.p.X, self.CameraSpring.p.Y, self.CameraSpring.p.Z)
end

function GunHandlerClient:RenderRate(dt)
	self.CommonVariables.ElapsedTime = self.CommonVariables.ElapsedTime + dt
	if self.CommonVariables.ElapsedTime >= 1 then
		self.CommonVariables.ElapsedTime = 0
		self.CommonVariables.CurrentRate = self.CommonVariables.CurrentRate - self.CommonVariables.LastRate
		self.CommonVariables.LastRate = self.CommonVariables.CurrentRate
	end
end

function GunHandlerClient:RenderMotion()
	if self.Beam and self.Attach0 and self.Attach1 then
		local Position = self:Get3DPosition(self.GunGUI.Crosshair.AbsolutePosition)
		local cframe =
			CFrame.new(self.HandleToFire:FindFirstChild("GunFirePoint" .. self.CurrentFireMode).WorldPosition, Position)
		local direction = cframe.LookVector

		if direction then
			self.ProjectileMotion.UpdateProjectilePath(
				self.Beam,
				self.Attach0,
				self.Attach1,
				self.HandleToFire:FindFirstChild("GunFirePoint" .. self.CurrentFireMode).WorldPosition,
				direction
					* self:AddressTableValue(
						self.CurrentModule.ChargeAlterTable.BulletSpeed,
						self.CurrentModule.BulletSpeed
					),
				3,
				self:AddressTableValue(
					self.CurrentModule.ChargeAlterTable.BulletAcceleration,
					self.CurrentModule.BulletAcceleration
				)
			)
		end
	end
end

function GunHandlerClient:RenderCooldown(dt)
	self.CurrentVariables.ElapsedCooldownTime = self.CurrentVariables.ElapsedCooldownTime + dt
	if self.CurrentVariables.ElapsedCooldownTime >= self.CurrentModule.CooldownTime then
		self.CurrentVariables.ElapsedCooldownTime = 0
		if not self.CommonVariables.Down then
			if not self.CommonVariables.Overheated then
				if self.CommonVariables.CanBeCooledDown then
					if self.CurrentVariables.Heat > 0 then
						self.CurrentVariables.Heat = math.clamp(
							self.CurrentVariables.Heat - self.CurrentModule.CooldownRate,
							0,
							self.CurrentModule.MaxHeat
						)
						self:UpdateGUI()
					end
				end
			end
		end
	end
end

function GunHandlerClient:CancelCrosshairTweens()
	for _, tween in pairs(self.ActiveCrosshairTweens) do
		if tween then
			tween:Cancel()
		end
	end
	self.ActiveCrosshairTweens = {}
end

function GunHandlerClient:PlayCrosshairHitAnimation(IsHeadshot)
	if not self.GunGUI or not self.GunGUI:FindFirstChild("Crosshair") then
		return
	end

	local CrosshairMain = self.GunGUI.Crosshair:FindFirstChild("Main")
	if not CrosshairMain then
		return
	end

	local Center = CrosshairMain:FindFirstChild("Center")
	local CrossParts = {
		HR = CrosshairMain:FindFirstChild("HR"),
		HL = CrosshairMain:FindFirstChild("HL"),
		VD = CrosshairMain:FindFirstChild("VD"),
		VU = CrosshairMain:FindFirstChild("VU"),
	}

	-- Cancel any ongoing tweens first
	self:CancelCrosshairTweens()

	-- Cache original positions on first run
	if self.CrosshairOriginalValues.HR_Position == nil then
		if CrossParts.HR then
			self.CrosshairOriginalValues.HR_Position = CrossParts.HR.Position
		end
		if CrossParts.HL then
			self.CrosshairOriginalValues.HL_Position = CrossParts.HL.Position
		end
		if CrossParts.VD then
			self.CrosshairOriginalValues.VD_Position = CrossParts.VD.Position
		end
		if CrossParts.VU then
			self.CrosshairOriginalValues.VU_Position = CrossParts.VU.Position
		end
	end

	-- Animation settings
	local punchScale = IsHeadshot and 1.5 or 1.3
	local punchDuration = 0.06
	local returnDuration = 0.1
	local rotationAmount = IsHeadshot and 45 or 25

	-- Animate Center (punch scale + rotation)
	if Center then
		local originalSize = self.CrosshairOriginalValues.CenterSize
		local originalRotation = self.CrosshairOriginalValues.CenterRotation

		-- Reset to base first, then animate
		Center.Size = originalSize
		Center.Rotation = originalRotation

		-- Punch out animation
		local punchTween =
			TweenService:Create(Center, TweenInfo.new(punchDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Size = UDim2.fromOffset(5 * punchScale, 5 * punchScale),
				Rotation = originalRotation + rotationAmount,
			})
		table.insert(self.ActiveCrosshairTweens, punchTween)
		punchTween:Play()

		-- Return animation
		local returnTween = TweenService:Create(
			Center,
			TweenInfo.new(returnDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{
				Size = originalSize,
				Rotation = originalRotation,
			}
		)
		table.insert(self.ActiveCrosshairTweens, returnTween)

		punchTween.Completed:Connect(function()
			returnTween:Play()
		end)
	end

	-- Animate crosshair arms (spread out then return)
	local spreadAmount = IsHeadshot and 6 or 4
	local spreadOffsets = {
		HR = UDim2.fromOffset(spreadAmount, 0),
		HL = UDim2.fromOffset(-spreadAmount, 0),
		VD = UDim2.fromOffset(0, spreadAmount),
		VU = UDim2.fromOffset(0, -spreadAmount),
	}

	for name, part in pairs(CrossParts) do
		if part and self.CrosshairOriginalValues[name .. "_Position"] then
			local originalPos = self.CrosshairOriginalValues[name .. "_Position"]
			local spreadOffset = spreadOffsets[name]

			-- Reset to base position first
			part.Position = originalPos

			local targetPos = UDim2.new(
				originalPos.X.Scale + spreadOffset.X.Scale,
				originalPos.X.Offset + spreadOffset.X.Offset,
				originalPos.Y.Scale + spreadOffset.Y.Scale,
				originalPos.Y.Offset + spreadOffset.Y.Offset
			)

			-- Spread out
			local spreadTween = TweenService:Create(
				part,
				TweenInfo.new(punchDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{
					Position = targetPos,
				}
			)
			table.insert(self.ActiveCrosshairTweens, spreadTween)
			spreadTween:Play()

			-- Return
			local returnTween = TweenService:Create(
				part,
				TweenInfo.new(returnDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{
					Position = originalPos,
				}
			)
			table.insert(self.ActiveCrosshairTweens, returnTween)

			spreadTween.Completed:Connect(function()
				returnTween:Play()
			end)
		end
	end
end

function GunHandlerClient:MarkHit(ClientModule, IsHeadshot)
	if ClientModule.HitmarkerEnabled then
		if IsHeadshot then
			self.GunGUI.Crosshair.Hitmarker.ImageColor3 = ClientModule.HitmarkerColorHS
			self.GunGUI.Crosshair.Hitmarker.ImageTransparency = 0
			TweenService:Create(
				self.GunGUI.Crosshair.Hitmarker,
				TweenInfo.new(ClientModule.HitmarkerFadeTimeHS, Enum.EasingStyle.Linear, Enum.EasingDirection.Out),
				{ ImageTransparency = 1 }
			):Play()
			local MarkerSound = self.GunGUI.Crosshair.MarkerSound:Clone()
			MarkerSound.SoundId = "rbxassetid://"
				.. ClientModule.HitmarkerSoundID[math.random(1, #ClientModule.HitmarkerSoundID)]
			MarkerSound.PlaybackSpeed = ClientModule.HitmarkerSoundPitchHS
			MarkerSound.Parent = self.PlayerGui
			MarkerSound:Play()
			MarkerSound.Ended:Connect(function()
				MarkerSound:Destroy()
			end)
		else
			self.GunGUI.Crosshair.Hitmarker.ImageColor3 = ClientModule.HitmarkerColor
			self.GunGUI.Crosshair.Hitmarker.ImageTransparency = 0
			TweenService:Create(
				self.GunGUI.Crosshair.Hitmarker,
				TweenInfo.new(ClientModule.HitmarkerFadeTime, Enum.EasingStyle.Linear, Enum.EasingDirection.Out),
				{ ImageTransparency = 1 }
			):Play()
			local MarkerSound = self.GunGUI.Crosshair.MarkerSound:Clone()
			MarkerSound.SoundId = "rbxassetid://"
				.. ClientModule.HitmarkerSoundID[math.random(1, #ClientModule.HitmarkerSoundID)]
			MarkerSound.PlaybackSpeed = ClientModule.HitmarkerSoundPitch
			MarkerSound.Parent = self.PlayerGui
			MarkerSound:Play()
			MarkerSound.Ended:Connect(function()
				MarkerSound:Destroy()
			end)
		end
	end

	-- Play cool crosshair hit animation
	self:PlayCrosshairHitAnimation(IsHeadshot)

	-- Set crosshair to red temporarily when hitting someone
	self.CurrentCrosshairState = "Hit"
	self:SetCrosshairColor(self.CrossHairColors.Hit)
	task.delay(self.CrosshairHitResetTime, function()
		if self.CurrentCrosshairState == "Hit" then
			self.CurrentCrosshairState = "Idle" -- Will be updated to correct state in next RenderMouse call
		end
	end)
	--end)
end

function GunHandlerClient:EjectShell(ShootingHandle)
	ShootingHandle = self.VMHandleToFire
	if self.CurrentModule.BulletShellEnabled then
		if self.CurrentModule.BulletShellParticles then
			function GunHandlerClient:Spawner()
				for i, v in pairs(self.VisualEffects.ShellEjectEffect:GetChildren()) do
					if v.ClassName == "ParticleEmitter" then
						local Count = 1
						local Particle = v:Clone()
						Particle.Parent = ShootingHandle["ShellEjectParticlePoint" .. self.CurrentFireMode]
						if Particle:FindFirstChild("EmitCount") then
							Count = Particle.EmitCount.Value
						end
						self.Thread:Delay(0.01, function()
							Particle:Emit(Count)
							Debris:AddItem(Particle, Particle.Lifetime.Max)
						end)
					end
				end
			end
			self.Thread:Spawn(function()
				self:Spawner()
			end)
		end
		local Shell = Instance.new("Part")
		Shell.CFrame = ShootingHandle["ShellEjectPoint" .. self.CurrentFireMode].WorldCFrame
		Shell.Material = Enum.Material.Metal

		Shell.Size = self.CurrentModule.ShellSize
		Shell.CanCollide = false -- Disable collision to prevent flinging the player
		Shell.CanQuery = false -- Don't interfere with raycasts
		Shell.CanTouch = false -- Don't trigger touch events
		Shell.Name = "Shell"
		Shell.Velocity = ShootingHandle["ShellEjectPoint" .. self.CurrentFireMode].WorldCFrame.LookVector
			* self.CurrentModule.BulletShellVelocity
		Shell.RotVelocity = ShootingHandle["ShellEjectPoint" .. self.CurrentFireMode].WorldCFrame.LookVector
			* self.CurrentModule.BulletShellRotVelocity
		Shell.Parent = self.Camera
		local Shellmesh = Instance.new("SpecialMesh")
		Shellmesh.Scale = self.CurrentModule.ShellScale
		Shellmesh.MeshId = "rbxassetid://" .. self.CurrentModule.ShellMeshID
		Shellmesh.TextureId = "rbxassetid://" .. self.CurrentModule.ShellTextureID
		Shellmesh.MeshType = "FileMesh"
		Shellmesh.Parent = Shell
		Debris:AddItem(Shell, self.CurrentModule.DisappearTime)
	end
end

function GunHandlerClient:RecoilCamera()
	if self.CurrentModule.CameraRecoilingEnabled then
		local Recoil = self:AddressTableValue(self.CurrentModule.ChargeAlterTable.Recoil, self.CurrentModule.Recoil)
		local CurrentRecoil = Recoil * (self.CommonVariables.AimDown and 1 - self.CurrentModule.RecoilRedution or 1)
		local RecoilX = math.rad(
			CurrentRecoil
				* self.Math.Randomize2(
					self.CurrentModule.AngleX_Min,
					self.CurrentModule.AngleX_Max,
					self.CurrentModule.Accuracy
				)
		)
		local RecoilY = math.rad(
			CurrentRecoil
				* self.Math.Randomize2(
					self.CurrentModule.AngleY_Min,
					self.CurrentModule.AngleY_Max,
					self.CurrentModule.Accuracy
				)
		)
		local RecoilZ = math.rad(
			CurrentRecoil
				* self.Math.Randomize2(
					self.CurrentModule.AngleZ_Min,
					self.CurrentModule.AngleZ_Max,
					self.CurrentModule.Accuracy
				)
		)
		self.Knockback:Accelerate(
			Vector3.new(
				-RecoilX * self.CurrentModule.ScopeKnockbackMultiplier,
				-RecoilY * self.CurrentModule.ScopeKnockbackMultiplier,
				0
			)
		)
		self.CameraSpring:Accelerate(Vector3.new(RecoilX, RecoilY, RecoilZ))
		self.Thread:Wait(0.03)
		self.CameraSpring:Accelerate(Vector3.new(-RecoilX, -RecoilY, 0))
	end
end

function GunHandlerClient:SelfKnockback(p1, p2)
	local SelfKnockbackPower = self:AddressTableValue(
		self.CurrentModule.ChargeAlterTable.SelfKnockbackPower,
		self.CurrentModule.SelfKnockbackPower
	)
	local SelfKnockbackMultiplier = self:AddressTableValue(
		self.CurrentModule.ChargeAlterTable.SelfKnockbackMultiplier,
		self.CurrentModule.SelfKnockbackMultiplier
	)
	local SelfKnockbackRedution = self:AddressTableValue(
		self.CurrentModule.ChargeAlterTable.SelfKnockbackRedution,
		self.CurrentModule.SelfKnockbackRedution
	)
	local Power = self.Humanoid:GetState() ~= Enum.HumanoidStateType.Freefall
			and SelfKnockbackPower * SelfKnockbackMultiplier * (1 - SelfKnockbackRedution)
		or SelfKnockbackPower * SelfKnockbackMultiplier
	local VelocityMod = (p1 - p2).Unit
	local AirVelocity = self.Torso.Velocity
		- Vector3.new(0, self.Torso.Velocity.Y, 0)
		+ Vector3.new(VelocityMod.X, 0, VelocityMod.Z) * -Power
	local TorsoFly = Instance.new("BodyVelocity")
	TorsoFly.MaxForce = Vector3.new(math.huge, 0, math.huge)
	TorsoFly.Velocity = AirVelocity
	TorsoFly.Parent = self.Torso
	self.Torso.Velocity = self.Torso.Velocity + Vector3.new(0, VelocityMod.Y * 2, 0) * -Power
	Debris:AddItem(TorsoFly, 0.25)
end
function GunHandlerClient:Fire(ShootingHandle, ShootingVMHandle, FireClientDirections, FireServerDirections)
	if self.CurrentModule.AimAnimationsEnabled and self.CommonVariables.AimDown == true then
		if self.CurrentAimFireAnim then
			self.CurrentAimFireAnim:Play(nil, nil, self.CurrentAimFireAnimationSpeed)
		end
	else
		if self.CurrentFireAnim then
			self.CurrentFireAnim:Play(nil, nil, self.CurrentFireAnimationSpeed)
		end
	end

	if self.CurrentAnimTable.MinigunRevUpAnim and self.CurrentAnimTable.MinigunRevUpAnim.IsPlaying then
		self.CurrentAnimTable.MinigunRevUpAnim:Stop()
	end

	local FireSounds = ShootingHandle[self.CurrentFireMode].FireSounds
	local VisualEffects2 = self.VisualEffects
	if self.VisualEffects:FindFirstChild(self.CurrentModule.ModuleName) then
		VisualEffects2 = self.VisualEffects[self.CurrentModule]
	end
	local MuzzleFolder = VisualEffects2.MuzzleEffect
	local HitEffectFolder = VisualEffects2.HitEffect
	local BloodEffectFolder = VisualEffects2.BloodEffect
	local ExplosionEffectFolder = VisualEffects2.ExplosionEffect
	local GoreEffectFolder = VisualEffects2.GoreEffect
	if self.CurrentModule.ChargedShotAdvanceEnabled then
		if self.CurrentVariables.ChargeLevel == 1 then
			if ShootingHandle[self.CurrentFireMode]:FindFirstChild("FireSoundsLvl1") then
				FireSounds = ShootingHandle[self.CurrentFireMode].FireSoundsLvl1
			end
			if VisualEffects2:FindFirstChild("MuzzleEffectLvl1") then
				MuzzleFolder = VisualEffects2.MuzzleEffectLvl1
			end
			if VisualEffects2:FindFirstChild("HitEffectLvl1") then
				HitEffectFolder = VisualEffects2.HitEffectLvl1
			end
			if VisualEffects2:FindFirstChild("BloodEffectLvl1") then
				BloodEffectFolder = VisualEffects2.BloodEffectLvl1
			end
			if VisualEffects2:FindFirstChild("ExplosionEffectLvl1") then
				ExplosionEffectFolder = VisualEffects2.ExplosionEffectLvl1
			end
			if VisualEffects2:FindFirstChild("GoreEffectLvl1") then
				GoreEffectFolder = VisualEffects2.GoreEffectLvl1
			end
		elseif self.CurrentVariables.ChargeLevel == 2 then
			if ShootingHandle[self.CurrentFireMode]:FindFirstChild("FireSoundsLvl2") then
				FireSounds = ShootingHandle[self.CurrentFireMode].FireSoundsLvl2
			end
			if VisualEffects2:FindFirstChild("MuzzleEffectLvl2") then
				MuzzleFolder = VisualEffects2.MuzzleEffectLvl2
			end
			if VisualEffects2:FindFirstChild("HitEffectLvl2") then
				HitEffectFolder = VisualEffects2.HitEffectLvl2
			end
			if VisualEffects2:FindFirstChild("BloodEffectLvl2") then
				BloodEffectFolder = VisualEffects2.BloodEffectLvl2
			end
			if VisualEffects2:FindFirstChild("ExplosionEffectLvl2") then
				ExplosionEffectFolder = VisualEffects2.ExplosionEffectLvl2
			end
			if VisualEffects2:FindFirstChild("GoreEffectLvl2") then
				GoreEffectFolder = VisualEffects2.GoreEffectLvl2
			end
		elseif self.CurrentVariables.ChargeLevel == 3 then
			if ShootingHandle[self.CurrentFireMode]:FindFirstChild("FireSoundsLvl3") then
				FireSounds = ShootingHandle[self.CurrentFireMode].FireSoundsLvl3
			end
			if VisualEffects2:FindFirstChild("MuzzleEffectLvl3") then
				MuzzleFolder = VisualEffects2.MuzzleEffectLvl3
			end
			if VisualEffects2:FindFirstChild("HitEffectLvl3") then
				HitEffectFolder = VisualEffects2.HitEffectLvl3
			end
			if VisualEffects2:FindFirstChild("BloodEffectLvl3") then
				BloodEffectFolder = VisualEffects2.BloodEffectLvl3
			end
			if VisualEffects2:FindFirstChild("ExplosionEffectLvl3") then
				ExplosionEffectFolder = VisualEffects2.ExplosionEffectLvl3
			end
			if VisualEffects2:FindFirstChild("GoreEffectLvl3") then
				GoreEffectFolder = VisualEffects2.GoreEffectLvl3
			end
		end
	end
	local Tracks = FireSounds:GetChildren()
	local Chosen = math.random(1, #Tracks)
	local Track = Tracks[Chosen]
	if Track ~= nil then
		self.AudioHandler:PlayAudio({
			SoundId = Track.SoundId,
			EmitterSize = Track.EmitterSize,
			MaxDistance = Track.MaxDistance,
			Volume = Track.Volume,
			Pitch = Track.PlaybackSpeed,
			Origin = ShootingHandle:FindFirstChild("GunMuzzlePoint" .. self.CurrentFireMode),
			Echo = self.CurrentModule.EchoEffect,
			Silenced = self.CurrentModule.SilenceEffect,
		}, {
			Enabled = self.CurrentModule.LowAmmo,
			CurrentAmmo = self.CurrentVariables.Mag,
			AmmoPerMag = self.CurrentModule.AmmoPerMag,
			SoundId = ShootingHandle[self.CurrentFireMode].LowAmmoSound.SoundId,
			EmitterSize = ShootingHandle[self.CurrentFireMode].LowAmmoSound.EmitterSize,
			MaxDistance = ShootingHandle[self.CurrentFireMode].LowAmmoSound.MaxDistance,
			Volume = ShootingHandle[self.CurrentFireMode].LowAmmoSound.Volume,
			Pitch = self.CurrentModule.RaisePitch and (math.max(math.abs(self.CurrentVariables.Mag / 10 - 1), 0.4))
				or ShootingHandle[self.CurrentFireMode].LowAmmoSound.PlaybackSpeed,
			Origin = ShootingHandle:FindFirstChild("GunMuzzlePoint" .. self.CurrentFireMode),
		}, true)
	end
	if self:IsAimingAtPlayer() then
		self:MarkHit(self.CurrentModule, false)
	end
	self.ProjectileHandler:SimulateProjectile(
		self.Tool,
		ShootingHandle,
		(self.Camera.Focus.p - self.Camera.CoordinateFrame.p).Magnitude <= 1 and ShootingVMHandle or nil,
		self.CurrentModule,
		FireClientDirections,
		FireServerDirections,
		ShootingHandle:FindFirstChild("GunFirePoint" .. self.CurrentFireMode),
		ShootingHandle:FindFirstChild("GunMuzzlePoint" .. self.CurrentFireMode),
		{
			MuzzleFolder = MuzzleFolder,
			HitEffectFolder = HitEffectFolder,
			BloodEffectFolder = BloodEffectFolder,
			ExplosionEffectFolder = ExplosionEffectFolder,
			GoreEffect = GoreEffectFolder,
			ChargeLevel = self.CurrentVariables.ChargeLevel,
			LockedEntity = self.LockedEntity,
		},
		true
	)

	-- Check if we hit a dead body and fling it
	if FireClientDirections and #FireClientDirections > 0 then
		self:CheckAndFlingDeadBody(FireClientDirections[1])
	else
		self:CheckAndFlingDeadBody(nil)
	end

	self.Thread:Spawn(function(...)
		self:RecoilCamera(...)
	end)
end

function GunHandlerClient:Overheat()
	if
		self.CommonVariables.ActuallyEquipped
		and self.CommonVariables.Enabled
		and not self.CommonVariables.Overheated
		and (self.CurrentVariables.Ammo > 0 or not self.CurrentModule.LimitedAmmoEnabled)
		and self.CurrentVariables.Heat >= self.CurrentModule.MaxHeat
	then
		self.CommonVariables.Overheated = true
		if self.CurrentAnimTable.InspectAnim and self.CurrentAnimTable.InspectAnim.IsPlaying then
			self.CurrentAnimTable.InspectAnim:Stop()
		end

		if self.CommonVariables.AimDown then
			TweenService:Create(
				self.Camera,
				TweenInfo.new(
					self.CurrentModule.TweenLengthNAD,
					self.CurrentModule.EasingStyleNAD,
					self.CurrentModule.EasingDirectionNAD
				),
				{ FieldOfView = 70 }
			):Play()
			--SetCrossScale(1)
			if
				self.CurrentModule.AimAnimationsEnabled
				and self.CurrentAnimTable.AimIdleAnim
				and self.CurrentAnimTable.AimIdleAnim.IsPlaying
			then
				self.CurrentAnimTable.AimIdleAnim:Stop()

				if self.CurrentAnimTable.IdleAnim then
					self.CurrentAnimTable.IdleAnim:Play(nil, nil, self.CurrentModule.IdleAnimationSpeed)
				end
			end

			self.CommonVariables.Scoping = false
			self.Player.CameraMode = Enum.CameraMode.Classic
			UserInputService.MouseDeltaSensitivity = self.CommonVariables.InitialSensitivity
			self.CommonVariables.AimDown = false
		end
		self:UpdateGUI()
		if self.CommonVariables.ActuallyEquipped then
			if self.CurrentAnimTable.OverheatAnim then
				self.CurrentAnimTable.OverheatAnim:Play(nil, nil, self.CurrentModule.OverheatAnimationSpeed)
			end

			self.Handle[self.CurrentFireMode].OverheatSound:Play()
		end
		--self.Thread:Wait(self.CurrentModule.OverheatTime)
		for _ = 1, self.CurrentModule.MaxHeat do
			self.Thread:Wait(self.CurrentModule.OverheatTime / self.CurrentModule.MaxHeat)
			self.CurrentVariables.Heat = self.CurrentVariables.Heat - 1
			self:UpdateGUI()
			if self.CurrentVariables.Heat == 0 then
				self.CommonVariables.Overheated = false
				break
			end
		end
		self.CommonVariables.Overheated = false
		self:UpdateGUI()
	end
end

function GunHandlerClient:updateServerChangeMagAndAmmo()
	self.ChangeMagAndAmmo:FireServer(
		self.CurrentFireMode,
		self.CurrentVariables.Mag,
		self.CurrentVariables.Ammo,
		self.CurrentVariables.Heat
	)
end

function GunHandlerClient:Reload()
	if
		self.CommonVariables.ActuallyEquipped
		and self.CommonVariables.Enabled
		and not self.CommonVariables.Reloading
		and (self.CurrentVariables.Ammo > 0 or not self.CurrentModule.LimitedAmmoEnabled)
		and self.CurrentVariables.Mag < self.CurrentModule.AmmoPerMag
	then
		self.CommonVariables.Reloading = true

		if self.CurrentModule.MagDrop == true then
			self.Tool.Magdrop:FireServer()
		end
		if self.CurrentAnimTable.InspectAnim and self.CurrentAnimTable.InspectAnim.IsPlaying then
			self.CurrentAnimTable.InspectAnim:Stop()
		end

		if not self.CurrentModule.KeepAimingOnReloading then
			if self.CommonVariables.AimDown then
				TweenService:Create(
					self.Camera,
					TweenInfo.new(
						self.CurrentModule.TweenLengthNAD,
						self.CurrentModule.EasingStyleNAD,
						self.CurrentModule.EasingDirectionNAD
					),
					{ FieldOfView = 70 }
				):Play()
				if
					self.CurrentModule.AimAnimationsEnabled
					and self.CurrentAnimTable.AimIdleAnim
					and self.CurrentAnimTable.AimIdleAnim.IsPlaying
				then
					self.CurrentAnimTable.AimIdleAnim:Stop()
					if self.CurrentAnimTable.IdleAnim then
						self.CurrentAnimTable.IdleAnim:Play(nil, nil, self.CurrentModule.IdleAnimationSpeed)
					end
				end

				self.CommonVariables.Scoping = false
				self.Player.CameraMode = Enum.CameraMode.Classic
				UserInputService.MouseDeltaSensitivity = self.CommonVariables.InitialSensitivity
				self.CommonVariables.AimDown = false
			end
		end
		self:UpdateGUI()
		if self.CurrentModule.ShotgunReload then
			if self.CurrentModule.PreShotgunReload then
				if self.CommonVariables.ActuallyEquipped then
					if self.CurrentAnimTable.PreShotgunReloadAnim then
						self.CurrentAnimTable.PreShotgunReloadAnim:Play(
							nil,
							nil,
							self.CurrentModule.PreShotgunReloadAnimationSpeed
						)
					end

					self.Handle[self.CurrentFireMode].PreReloadSound:Play()
				end
				local StartTime = os.clock()
				repeat
					self.Thread:Wait()
					if not self.CommonVariables.ActuallyEquipped then
						break
					end
				until (os.clock() - StartTime) >= self.CurrentModule.PreShotgunReloadSpeed
			end
			for _ = 1, (self.CurrentModule.AmmoPerMag - self.CurrentVariables.Mag) do
				if self.CommonVariables.ActuallyEquipped then
					if self.CurrentAnimTable.ShotgunClipinAnim then
						self.CurrentAnimTable.ShotgunClipinAnim:Play(
							nil,
							nil,
							self.CurrentModule.ShotgunClipinAnimationSpeed
						)
					end

					self.Handle[self.CurrentFireMode].ShotgunClipin:Play()
				end
				local StartTime = os.clock()
				repeat
					self.Thread:Wait()
					if not self.CommonVariables.ActuallyEquipped then
						break
					end
				until (os.clock() - StartTime) >= self.CurrentModule.ShellClipinSpeed
				if self.CurrentVariables.Mag < self.CurrentModule.AmmoPerMag then
					if self.CommonVariables.ActuallyEquipped then
						if self.CurrentModule.LimitedAmmoEnabled then
							if self.CurrentVariables.Ammo > 0 then
								self.CurrentVariables.Mag = self.CurrentVariables.Mag + 1
								self.CurrentVariables.Ammo = self.CurrentVariables.Ammo - 1
								self:updateServerChangeMagAndAmmo()
								-- if self.Module.MagCartridge and not self.CurrentModule.BatteryEnabled then
								-- 	for i = 1, self.CurrentVariables.Mag do
								-- 		self.GunGUI.MagCartridge[i].Visible = true
								-- 	end
								-- end
								self:UpdateGUI()
							end
						else
							self.CurrentVariables.Mag = self.CurrentVariables.Mag + 1
							self.CurrentVariables.Ammo = self.CurrentVariables.Ammo - 1
							self:updateServerChangeMagAndAmmo()
							-- if self.Module.MagCartridge and not self.CurrentModule.BatteryEnabled then
							-- 	for i = 1, self.CurrentVariables.Mag do
							-- 		self.GunGUI.MagCartridge[i].Visible = true
							-- 	end
							-- end
							self:UpdateGUI()
						end
					end
				else
					break
				end
				if self.CurrentModule.LimitedAmmoEnabled then
					if (not self.CommonVariables.ActuallyEquipped) or (self.CurrentVariables.Ammo <= 0) then
						break
					end
				else
					if not self.CommonVariables.ActuallyEquipped then
						break
					end
				end
			end
		end
		if self.CommonVariables.ActuallyEquipped then
			if self.CurrentModule.TacticalReloadAnimationEnabled then
				if self.CurrentVariables.Mag > 0 then
					if self.CurrentAnimTable.TacticalReloadAnim then
						self.CurrentAnimTable.TacticalReloadAnim:Play(
							nil,
							nil,
							self.CurrentModule.TacticalReloadAnimationSpeed
						)
					end

					self.Handle[self.CurrentFireMode].TacticalReloadSound:Play()
				else
					if self.CurrentAnimTable.ReloadAnim then
						self.CurrentAnimTable.ReloadAnim:Play(nil, nil, self.CurrentModule.ReloadAnimationSpeed)
					end

					self.Handle[self.CurrentFireMode].ReloadSound:Play()
				end
			else
				if self.CurrentAnimTable.ReloadAnim then
					self.CurrentAnimTable.ReloadAnim:Play(nil, nil, self.CurrentModule.ReloadAnimationSpeed)
				end

				self.Handle[self.CurrentFireMode].ReloadSound:Play()
			end
		end
		local ReloadTime = (self.CurrentVariables.Mag > 0 and self.CurrentModule.TacticalReloadAnimationEnabled)
				and self.CurrentModule.TacticalReloadTime
			or self.CurrentModule.ReloadTime
		local StartTime = os.clock()
		repeat
			self.Thread:Wait()
			if not self.CommonVariables.ActuallyEquipped then
				break
			end
		until (os.clock() - StartTime) >= ReloadTime
		if self.CommonVariables.ActuallyEquipped then
			if not self.CurrentModule.ShotgunReload then
				if self.CurrentModule.LimitedAmmoEnabled then
					local ammoToUse =
						math.min(self.CurrentModule.AmmoPerMag - self.CurrentVariables.Mag, self.CurrentVariables.Ammo)
					self.CurrentVariables.Mag = self.CurrentVariables.Mag + ammoToUse
					self.CurrentVariables.Ammo = self.CurrentVariables.Ammo - ammoToUse
				else
					self.CurrentVariables.Mag = self.CurrentModule.AmmoPerMag
				end
				self:updateServerChangeMagAndAmmo()
			end
		end
		self.CommonVariables.Reloading = false
		self.Empty:Stop()
		self:UpdateGUI()
	end
end

function GunHandlerClient:OnTooglingAiming()
	if
		not self.CommonVariables.Reloading
		and not self.CommonVariables.Overheated
		and not self.CommonVariables.HoldDown
		and not self.CommonVariables.Alting
		and not self.CommonVariables.AimDown
		and self.CommonVariables.ActuallyEquipped
		and self.CurrentModule.IronsightEnabled
		and (self.Camera.Focus.p - self.Camera.CoordinateFrame.p).Magnitude <= 1
	then
		if not self.CurrentModule.KeepAimingOnReloading then
			if self.CommonVariables.Reloading or self.CommonVariables.Overheated then
				return
			end
		end
		TweenService:Create(
			self.Camera,
			TweenInfo.new(
				self.CurrentModule.TweenLength,
				self.CurrentModule.EasingStyle,
				self.CurrentModule.EasingDirection
			),
			{ FieldOfView = self.CurrentModule.FieldOfViewIS }
		):Play()
		--SetCrossScale(self.CurrentModule.CrossScaleIS)
		if self.CurrentAnimTable.InspectAnim and self.CurrentAnimTable.InspectAnim.IsPlaying then
			self.CurrentAnimTable.InspectAnim:Stop()
		end

		if
			self.CurrentModule.AimAnimationsEnabled
			and self.CurrentAnimTable.IdleAnim
			and self.CurrentAnimTable.IdleAnim.IsPlaying
		then
			self.CurrentAnimTable.IdleAnim:Stop()
			if self.CurrentAnimTable.AimIdleAnim then
				self.CurrentAnimTable.AimIdleAnim:Play(nil, nil, self.CurrentModule.AimIdleAnimationSpeed)
			end
		end

		self.Player.CameraMode = Enum.CameraMode.LockFirstPerson
		UserInputService.MouseDeltaSensitivity = self.CommonVariables.InitialSensitivity
			* self.CurrentModule.MouseSensitiveIS
		self.CommonVariables.AimDown = true
	elseif
		not self.CommonVariables.Reloading
		and not self.CommonVariables.Overheated
		and not self.CommonVariables.HoldDown
		and not self.CommonVariables.Alting
		and self.CommonVariables.AimDown
		and self.CommonVariables.ActuallyEquipped
		and self.CurrentModule.SniperEnabled
		and (self.Camera.Focus.p - self.Camera.CoordinateFrame.p).Magnitude <= 1
	then
		if not self.CurrentModule.KeepAimingOnReloading then
			if self.CommonVariables.Reloading or self.CommonVariables.Overheated then
				return
			end
		end
		TweenService:Create(
			self.Camera,
			TweenInfo.new(
				self.CurrentModule.TweenLength,
				self.CurrentModule.EasingStyle,
				self.CurrentModule.EasingDirection
			),
			{ FieldOfView = self.CurrentModule.FieldOfViewS }
		):Play()
		if self.CurrentAnimTable.InspectAnim and self.CurrentAnimTable.InspectAnim.IsPlaying then
			self.CurrentAnimTable.InspectAnim:Stop()
		end

		if
			self.CurrentModule.AimAnimationsEnabled
			and self.CurrentAnimTable.IdleAnim
			and self.CurrentAnimTable.IdleAnim.IsPlaying
		then
			self.CurrentAnimTable.IdleAnim:Stop()
			if self.CurrentAnimTable.AimIdleAnim then
				self.CurrentAnimTable.AimIdleAnim:Play(nil, nil, self.CurrentModule.AimIdleAnimationSpeed)
			end
		end

		self.CommonVariables.AimDown = true
		local StartTime = os.clock()
		repeat
			self.Thread:Wait()
			if not (self.CommonVariables.ActuallyEquipped or self.CommonVariables.AimDown) then
				break
			end
		until (os.clock() - StartTime) >= self.CurrentModule.ScopeDelay
		if self.CommonVariables.ActuallyEquipped and self.CommonVariables.AimDown then
			local ZoomSound = self.GunGUI.Scope.ZoomSound:Clone()
			ZoomSound.Parent = self.PlayerGui
			ZoomSound:Play()
			ZoomSound.Ended:Connect(function()
				ZoomSound:Destroy()
			end)
			self.Player.CameraMode = Enum.CameraMode.LockFirstPerson
			UserInputService.MouseDeltaSensitivity = self.CommonVariables.InitialSensitivity
				* self.CurrentModule.MouseSensitiveS
			self.CommonVariables.Scoping = true
		end
	else
		TweenService:Create(
			self.Camera,
			TweenInfo.new(
				self.CurrentModule.TweenLengthNAD,
				self.CurrentModule.EasingStyleNAD,
				self.CurrentModule.EasingDirectionNAD
			),
			{ FieldOfView = 70 }
		):Play()
		if
			self.CurrentModule.AimAnimationsEnabled
			and self.CurrentAnimTable.AimIdleAnim
			and self.CurrentAnimTable.AimIdleAnim.IsPlaying
		then
			self.CurrentAnimTable.AimIdleAnim:Stop()
			if self.CurrentAnimTable.IdleAnim then
				self.CurrentAnimTable.IdleAnim:Play(nil, nil, self.CurrentModule.IdleAnimationSpeed)
			end
		end

		self.CommonVariables.Scoping = false
		self.Player.CameraMode = Enum.CameraMode.Classic
		UserInputService.MouseDeltaSensitivity = self.CommonVariables.InitialSensitivity
		self.CommonVariables.AimDown = false
	end
end

function GunHandlerClient:OnHoldingDown()
	if self.CurrentModule.HoldDownEnabled then
		if
			not self.CommonVariables.Reloading
			and not self.CommonVariables.Overheated
			and self.CommonVariables.ActuallyEquipped
			and self.CommonVariables.Enabled
		then
			if not self.CommonVariables.HoldDown then
				self.CommonVariables.HoldDown = true
				if self.CurrentAnimTable.AimIdleAnim and self.CurrentAnimTable.AimIdleAnim.IsPlaying then
					self.CurrentAnimTable.AimIdleAnim:Stop()
				end
				if self.CurrentAnimTable.IdleAnim and self.CurrentAnimTable.IdleAnim.IsPlaying then
					self.CurrentAnimTable.IdleAnim:Stop()
				end

				if self.CurrentAnimTable.HoldDownAnim then
					self.CurrentAnimTable.HoldDownAnim:Play(nil, nil, self.CurrentModule.HoldDownAnimationSpeed)
				end

				if self.CommonVariables.AimDown then
					TweenService:Create(
						self.Camera,
						TweenInfo.new(
							self.CurrentModule.TweenLengthNAD,
							self.CurrentModule.EasingStyleNAD,
							self.CurrentModule.EasingDirectionNAD
						),
						{ FieldOfView = 70 }
					):Play()
					--SetCrossScale(1)

					self.CommonVariables.Scoping = false
					self.Player.CameraMode = Enum.CameraMode.Classic
					UserInputService.MouseDeltaSensitivity = self.CommonVariables.InitialSensitivity
					self.CommonVariables.AimDown = false
				end
			else
				self.CommonVariables.HoldDown = false
				if self.CurrentAnimTable.IdleAnim then
					self.CurrentAnimTable.IdleAnim:Play(nil, nil, self.CurrentModule.IdleAnimationSpeed)
				end

				if self.CurrentAnimTable.HoldDownAnim and self.CurrentAnimTable.HoldDownAnim.IsPlaying then
					self.CurrentAnimTable.HoldDownAnim:Stop()
				end
			end
		end
	end
end

function GunHandlerClient:OnInspecting()
	if
		not self.CommonVariables.Reloading
		and not self.CommonVariables.Overheated
		and self.CommonVariables.ActuallyEquipped
		and self.CommonVariables.Enabled
		and not self.CommonVariables.AimDown
		and not self.CommonVariables.Inspecting
		and not self.CommonVariables.Switching
		and not self.CommonVariables.Alting
		and self.CurrentModule.InspectAnimationEnabled
	then
		self.CommonVariables.Inspecting = true
		if self.CurrentAnimTable.InspectAnim then
			self.CurrentAnimTable.InspectAnim:Play(nil, nil, self.CurrentModule.InspectAnimationSpeed)
		end

		local StartTime = os.clock()
		repeat
			self.Thread:Wait()
			if
				not self.CommonVariables.ActuallyEquipped
				or self.CommonVariables.Reloading
				or self.CommonVariables.Overheated
				or not self.CommonVariables.Enabled
				or self.CommonVariables.AimDown
				or self.CommonVariables.Switching
			then
				break
			end
		until (os.clock() - StartTime)
			>= self.CurrentAnimTable.InspectAnim.Length / self.CurrentAnimTable.InspectAnim.Speed
		self.CommonVariables.Inspecting = false
	end
end

function GunHandlerClient:OnSwitching()
	if
		not self.CommonVariables.Reloading
		and not self.CommonVariables.Overheated
		and self.CommonVariables.ActuallyEquipped
		and self.CommonVariables.Enabled
		and not self.CommonVariables.Inspecting
		and not self.CommonVariables.Switching
		and not self.CommonVariables.Alting
		and self.CurrentModule.SelectiveFireEnabled
	then
		self.CommonVariables.Switching = true
		if self.CurrentAnimTable.SwitchAnim then
			self.CurrentAnimTable.SwitchAnim:Play(nil, nil, self.CurrentModule.SwitchAnimationSpeed)
		end

		local StartTime = os.clock()
		repeat
			self.Thread:Wait()
			if
				not self.CommonVariables.ActuallyEquipped
				or self.CommonVariables.Reloading
				or self.CommonVariables.Overheated
				or not self.CommonVariables.Enabled
				or self.CommonVariables.Inspecting
			then
				break
			end
		until (os.clock() - StartTime) >= self.CurrentModule.SwitchTime
		self.CommonVariables.Switching = false
		if
			self.CommonVariables.ActuallyEquipped
			and not self.CommonVariables.Reloading
			and not self.CommonVariables.Overheated
			and self.CommonVariables.Enabled
			and not self.CommonVariables.Inspecting
		then
			self.Handle[self.CurrentFireMode].SwitchSound:Play()
			self.CurrentVariables.FireMode = self.CurrentVariables.FireMode % #self.CurrentVariables.FireModes + 1
			self:UpdateGUI()
		end
	end
end

function GunHandlerClient:OnAlting()
	if self.Module.AltFire and #self.Setting:GetChildren() > 1 then
		if
			not self.CommonVariables.Reloading
			and not self.CommonVariables.Overheated
			and self.CommonVariables.ActuallyEquipped
			and self.CommonVariables.Enabled
			and not self.CommonVariables.Inspecting
			and not self.CommonVariables.Alting
			and not self.CommonVariables.Switching
		then
			self.CommonVariables.Alting = true
			if self.CurrentAnimTable.InspectAnim and self.CurrentAnimTable.InspectAnim.IsPlaying then
				self.CurrentAnimTable.InspectAnim:Stop()
			end

			if self.CommonVariables.AimDown then
				TweenService:Create(
					self.Camera,
					TweenInfo.new(
						self.CurrentModule.TweenLengthNAD,
						self.CurrentModule.EasingStyleNAD,
						self.CurrentModule.EasingDirectionNAD
					),
					{ FieldOfView = 70 }
				):Play()
				--SetCrossScale(1)
				if
					self.CurrentModule.AimAnimationsEnabled
					and self.CurrentAnimTable.AimIdleAnim
					and self.CurrentAnimTable.AimIdleAnim.IsPlaying
				then
					self.CurrentAnimTable.AimIdleAnim:Stop()
					if self.CurrentAnimTable.IdleAnim then
						self.CurrentAnimTable.IdleAnim:Play(nil, nil, self.CurrentModule.IdleAnimationSpeed)
					end
				end

				self.CommonVariables.Scoping = false
				self.Player.CameraMode = Enum.CameraMode.Classic
				UserInputService.MouseDeltaSensitivity = self.CommonVariables.InitialSensitivity
				self.CommonVariables.AimDown = false
			end
			if self.CurrentAnimTable.AltAnim then
				self.CurrentAnimTable.AltAnim:Play(nil, nil, self.CurrentModule.SwitchAnimationSpeed)
			end
			self.Handle[self.CurrentFireMode].AltSound:Play()
			local StartTime = os.clock()
			repeat
				self.Thread:Wait()
				if
					not self.CommonVariables.ActuallyEquipped
					or self.CommonVariables.Reloading
					or self.CommonVariables.Overheated
					or not self.CommonVariables.Enabled
					or self.CommonVariables.Inspecting
				then
					break
				end
			until (os.clock() - StartTime) >= self.CurrentModule.SwitchTime
			self.CommonVariables.Alting = false
			if
				self.CommonVariables.ActuallyEquipped
				and not self.CommonVariables.Reloading
				and not self.CommonVariables.Overheated
				and self.CommonVariables.Enabled
				and not self.CommonVariables.Inspecting
			then
				self.LockedEntity = nil
				if self.Beam then
					self.Beam:Destroy()
					self.Beam = nil
				end
				if self.Attach0 then
					self.Attach0:Destroy()
					self.Attach0 = nil
				end
				if self.Attach1 then
					self.Attach1:Destroy()
					self.Attach1 = nil
				end
				for _, a in pairs(self.CurrentAnimTable) do
					if
						a --[[and not a.Animation.Name == "AltAnim"]]
					then
						if a.IsPlaying then
							a:Stop()
						end
					end
				end

				self.HandleToFire = self.Handle

				self.CommonVariables.CurrentRate = 0
				self.CommonVariables.LastRate = 0
				self.CommonVariables.ElapsedTime = 0

				self.CurrentFireMode = self.CurrentFireMode % #self.Setting:GetChildren() + 1
				self.CurrentModule = self.SettingModules[self.CurrentFireMode]
				self.CurrentVariables = self.Variables[self.CurrentFireMode]
				self.CurrentAnimTable = self.Animations[self.CurrentFireMode]

				if self.CurrentModule.AimAnimationsEnabled then
					self.CurrentAimFireAnim = self.CurrentAnimTable.AimFireAnim
					self.CurrentAimFireAnimationSpeed = self.CurrentModule.AimFireAnimationSpeed
				end
				self.CurrentFireAnim = self.CurrentAnimTable.FireAnim
				self.CurrentFireAnimationSpeed = self.CurrentModule.FireAnimationSpeed
				self.CurrentShotgunPumpinAnim = self.CurrentAnimTable.ShotgunPumpinAnim
				self.CurrentShotgunPumpinAnimationSpeed = self.CurrentModule.ShotgunPumpinSpeed

				self.SmokeTrail:StopEmission()

				if self.CurrentModule.ProjectileMotion then
					local VisualEffects2 = self.VisualEffects
					if self.VisualEffects:FindFirstChild(self.CurrentModule.ModuleName) then
						VisualEffects2 = self.VisualEffects[self.CurrentModule]
					end
					self.Beam, self.Attach0, self.Attach1 = self.ProjectileMotion.ShowProjectilePath(
						VisualEffects2.MotionBeam,
						self.HandleToFire:FindFirstChild("GunFirePoint" .. self.CurrentFireMode).WorldPosition,
						Vector3.new(),
						3,
						self:AddressTableValue(
							self.CurrentModule.ChargeAlterTable.BulletAcceleration,
							self.CurrentModule.BulletAcceleration
						)
					)
				end

				if self.CurrentAnimTable.IdleAnim then
					self.CurrentAnimTable.IdleAnim:Play(nil, nil, self.CurrentModule.IdleAnimationSpeed)
				end

				if self.CurrentModule.AmmoPerMag ~= math.huge and self.CurrentModule.MaxHeat ~= math.huge then
					self.GunGUI.Frame.Visible = true
				end

				self:UpdateGUI()

				if
					self.CommonVariables.ActuallyEquipped
					and self.Module.AutoReload
					and not self.CommonVariables.Reloading
					and (self.CurrentVariables.Ammo > 0 or not self.CurrentModule.LimitedAmmoEnabled)
					and self.CurrentVariables.Mag <= 0
				then
					self:Reload()
				end
			end
		end
	end
end
function GunHandlerClient:chargeEffect()
	self.CommonVariables.CanBeCooledDown = false
	self.CommonVariables.Enabled = false
	if self.CurrentAnimTable.InspectAnim and self.CurrentAnimTable.InspectAnim.IsPlaying then
		self.CurrentAnimTable.InspectAnim:Stop()
	end

	if self.CurrentModule.AimAnimationsEnabled and self.CommonVariables.AimDown then
		if self.CurrentAnimTable.AimChargingAnim and not self.CurrentAnimTable.AimChargingAnim.IsPlaying then
			self.CurrentAnimTable.AimChargingAnim:Play(nil, nil, self.CurrentModule.AimChargingAnimationSpeed)
		end
	else
		if self.CurrentAnimTable.ChargingAnim and not self.CurrentAnimTable.ChargingAnim.IsPlaying then
			self.CurrentAnimTable.ChargingAnim:Play(nil, nil, self.CurrentModule.ChargingAnimationSpeed)
		end
	end
	local ChargingSound = self.HandleToFire[self.CurrentFireMode]:FindFirstChild("ChargingSound")
	local StartTime = os.clock()
	while true do
		local DeltaTime = os.clock() - StartTime
		if self.CurrentVariables.ChargeLevel == 0 and DeltaTime >= self.CurrentModule.Level1ChargingTime then
			self.CurrentVariables.ChargeLevel = 1
			self.GunGUI.ChargeBar.ChargeLevel1:Play()
		elseif self.CurrentVariables.ChargeLevel == 1 and DeltaTime >= self.CurrentModule.Level2ChargingTime then
			self.CurrentVariables.ChargeLevel = 2
			self.GunGUI.ChargeBar.ChargeLevel2:Play()
		elseif self.CurrentVariables.ChargeLevel == 2 and DeltaTime >= self.CurrentModule.AdvancedChargingTime then
			self.CurrentVariables.ChargeLevel = 3
			self.GunGUI.ChargeBar.ChargeLevel3:Play()
			self.GunGUI.ChargeBar.Shine.UIGradient.Offset = Vector2.new(-1, 0)
			TweenService:Create(
				self.GunGUI.ChargeBar.Shine.UIGradient,
				TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
				{ Offset = Vector2.new(1, 0) }
			):Play()
		end
		local ChargePercent = math.min(DeltaTime / self.CurrentModule.AdvancedChargingTime, 1)
		if ChargePercent < 0.5 then --Fade from red to yellow then to green
			self.GunGUI.ChargeBar.Fill.BackgroundColor3 = Color3.new(1, ChargePercent * 2, 0)
		else
			self.GunGUI.ChargeBar.Fill.BackgroundColor3 = Color3.new(1 - ((ChargePercent - 0.5) / 0.5), 1, 0)
		end
		self.GunGUI.ChargeBar.Fill.Size = UDim2.new(ChargePercent, 0, 1, 0)
		if ChargingSound then
			if not ChargingSound.Playing then
				ChargingSound:Play()
			end
			if self.CurrentModule.ChargingSoundIncreasePitch then
				ChargingSound.PlaybackSpeed = self.CurrentModule.ChargingSoundPitchRange[1]
					+ (
						ChargePercent
						* (
							self.CurrentModule.ChargingSoundPitchRange[2]
							- self.CurrentModule.ChargingSoundPitchRange[1]
						)
					)
			end
		end
		self.Thread:Wait()
		if not self.CommonVariables.ActuallyEquipped or not self.CommonVariables.Charging then
			break
		end
	end
	if self.CurrentAnimTable.AimChargingAnim and self.CurrentAnimTable.AimChargingAnim.IsPlaying then
		self.CurrentAnimTable.AimChargingAnim:Stop(0)
	end
	if self.CurrentAnimTable.ChargingAnim and self.CurrentAnimTable.ChargingAnim.IsPlaying then
		self.CurrentAnimTable.ChargingAnim:Stop(0)
	end

	self.GunGUI.ChargeBar.Fill.Size = UDim2.new(0, 0, 1, 0)
	if ChargingSound then
		if ChargingSound.Playing then
			ChargingSound:Stop()
		end
		if self.CurrentModule.ChargingSoundIncreasePitch then
			ChargingSound.PlaybackSpeed = self.CurrentModule.ChargingSoundPitchRange[1]
		end
	end
	if not self.CommonVariables.ActuallyEquipped then
		self.CurrentVariables.ChargeLevel = 0
		self.CommonVariables.Enabled = true
	end
end

function GunHandlerClient:shotShellEjectSpawnLoop(): boolean
	if not self.CommonVariables.ActuallyEquipped then
		return false
	end
	if not self.CurrentModule.ShotgunPump then
		self.Thread:Spawn(function()
			local StartTime = os.clock()
			repeat
				self.Thread:Wait()
				if not self.CommonVariables.ActuallyEquipped then
					break
				end
			until (os.clock() - StartTime) >= self.CurrentModule.BulletShellDelay
			if self.CommonVariables.ActuallyEquipped then
				self:EjectShell(
					((self.Camera.Focus.p - self.Camera.CoordinateFrame.p).Magnitude <= 1) and self.HandleToFire
				)
			end
		end)
	end
	return true
end

function GunHandlerClient:gunCoolDown()
	self.Thread:Spawn(function()
		self.CurrentVariables.ShotID = self.CurrentVariables.ShotID + 1
		local LastShotID = self.CurrentVariables.ShotID
		local Interrupted = false
		local CooldownTime = self.CurrentModule.TimeBeforeCooldown
		local StartTime = os.clock()
		repeat
			self.Thread:Wait()
			if LastShotID ~= self.CurrentVariables.ShotID then
				break
			end
		until (os.clock() - StartTime) >= CooldownTime
		if LastShotID ~= self.CurrentVariables.ShotID then
			Interrupted = true
		end
		if not Interrupted then
			self.CommonVariables.CanBeCooledDown = true
		end
	end)
end

function GunHandlerClient:setUpFiringAnimation()
	if not self.CurrentModule.ShotgunPump then
		self.HandleToFire = (self.HandleToFire == self.Handle and self.CurrentModule.DualFireEnabled) and self.Handle2
			or self.Handle

		if self.CurrentModule.AimAnimationsEnabled then
			self.CurrentAimFireAnim = (
				self.CurrentAimFireAnim == self.CurrentAnimTable.AimFireAnim
				and self.CurrentModule.SecondaryFireAnimationEnabled
			)
					and self.CurrentAnimTable.AimSecondaryFireAnim
				or self.CurrentAnimTable.AimFireAnim
			self.CurrentAimFireAnimationSpeed = (
				self.CurrentAimFireAnimationSpeed == self.CurrentModule.AimFireAnimationSpeed
				and self.CurrentModule.SecondaryFireAnimationEnabled
			)
					and self.CurrentModule.AimSecondaryFireAnimationSpeed
				or self.CurrentModule.AimFireAnimationSpeed
		end

		self.CurrentFireAnim = (
			self.CurrentFireAnim == self.CurrentAnimTable.FireAnim
			and self.CurrentModule.SecondaryFireAnimationEnabled
		)
				and self.CurrentAnimTable.SecondaryFireAnim
			or self.CurrentAnimTable.FireAnim
		self.CurrentFireAnimationSpeed = (
			self.CurrentFireAnimationSpeed == self.CurrentModule.FireAnimationSpeed
			and self.CurrentModule.SecondaryFireAnimationEnabled
		)
				and self.CurrentModule.SecondaryFireAnimationSpeed
			or self.CurrentModule.FireAnimationSpeed
	end
end

function GunHandlerClient:gunDoneCharging()
	return self.CommonVariables.ActuallyEquipped
		and not self.CommonVariables.Enabled
		and not self.CommonVariables.Charging
		and not self.CommonVariables.Reloading
		and not self.CommonVariables.Overheated
		and not self.CommonVariables.HoldDown
		and not self.CommonVariables.Switching
		and not self.CommonVariables.Alting
		and self.CurrentVariables.Mag > 0
		and self.CurrentVariables.Heat < self.CurrentModule.MaxHeat
		and self.Humanoid.Health > 0
end

function GunHandlerClient:gunCanFire()
	return self.CommonVariables.ActuallyEquipped
		and self.CommonVariables.Enabled
		and not self.CommonVariables.Reloading
		and not self.CommonVariables.Overheated
		and not self.CommonVariables.HoldDown
		and not self.CommonVariables.Switching
		and not self.CommonVariables.Alting
		and self.CurrentVariables.Mag > 0
		and self.CurrentVariables.Heat < self.CurrentModule.MaxHeat
		and self.Humanoid.Health > 0
end

function GunHandlerClient:OnFiring()
	-- this is for charging up your gun
	if self.CurrentModule.ChargedShotAdvanceEnabled and not self.CurrentModule.SelectiveFireEnabled then
		self.CommonVariables.Charging = true
		if self:gunCanFire() then
			self:chargeEffect()
			if self:gunDoneCharging() then
				for _ = 1, (self.CurrentModule.BurstFireEnabled and (self:AddressTableValue(
					self.CurrentModule.ChargeAlterTable.BulletPerBurst,
					self.CurrentModule.BulletPerBurst
				)) or 1) do
					local CLDirections = {}
					local SVDirections = {}
					local success = self:shotShellEjectSpawnLoop()
					if not success then
						break
					end
					self.CommonVariables.CurrentRate = self.CommonVariables.CurrentRate
						+ self.CurrentModule.SmokeTrailRateIncrement
					for ii = 1, (self.CurrentModule.ShotgunEnabled and (self:AddressTableValue(
						self.CurrentModule.ChargeAlterTable.BulletPerShot,
						self.CurrentModule.BulletPerShot
					)) or 1) do
						local Position = self:Get3DPosition(self.GunGUI.Crosshair.AbsolutePosition)
						local CurrentSpread = 0 -- Spread removed
						local cframe = (self.Camera.Focus.p - self.Camera.CoordinateFrame.p).Magnitude <= 1
								and CFrame.new(
									self.VMHandleToFire:FindFirstChild("GunFirePoint" .. self.CurrentFireMode).WorldPosition,
									Position
								)
							or CFrame.new(
								self.HandleToFire:FindFirstChild("GunFirePoint" .. self.CurrentFireMode).WorldPosition,
								Position
							)
						local svCframe = CFrame.new(
							self.HandleToFire:FindFirstChild("GunFirePoint" .. self.CurrentFireMode).WorldPosition,
							Position
						)

						if self.CurrentModule.ShotgunPattern and self.CurrentModule.SpreadPattern then
							local X, Y =
								self.CurrentModule.SpreadPattern[ii][1], self.CurrentModule.SpreadPattern[ii][2]
							local SpreadPattern = CFrame.Angles(
								math.rad(self.CurrentSpread * Y / 50),
								math.rad(CurrentSpread * X / 50),
								0
							)
							cframe = cframe * SpreadPattern
							svCframe = svCframe * SpreadPattern
						else
							local SpreadNormal = CFrame.Angles(
								math.rad(math.random(-self.CurrentSpread, CurrentSpread) / 50),
								math.rad(math.random(-self.CurrentSpread, CurrentSpread) / 50),
								0
							)
							cframe = cframe * SpreadNormal
							svCframe = svCframe * SpreadNormal
						end

						local ClDirection = cframe.LookVector
						local SvDirection = svCframe.LookVector
						table.insert(CLDirections, ClDirection)
						table.insert(SVDirections, SvDirection)
					end
					if
						self:AddressTableValue(
							self.CurrentModule.ChargeAlterTable.SelfKnockback,
							self.CurrentModule.SelfKnockback
						)
					then
						local KnockbackPosition = self:Get3DPosition(self.GunGUI.Crosshair.AbsolutePosition)
						self:SelfKnockback(KnockbackPosition, self.Torso.Position)
					end
					self:Fire(self.HandleToFire, self.VMHandleToFire, CLDirections, SVDirections)
					if self.CurrentModule.BatteryEnabled then
						self.CurrentVariables.ShotsForDepletion = self.CurrentVariables.ShotsForDepletion + 1
						if self.CurrentVariables.ShotsForDepletion >= self.CurrentModule.ShotsForDepletion then
							self.CurrentVariables.ShotsForDepletion = 0
							self.CurrentVariables.Ammo = self.CurrentVariables.Ammo
								- Random.new():NextInteger(
									self:AddressTableValue(
										self.CurrentModule.ChargeAlterTable.MinDepletion,
										self.CurrentModule.MinDepletion
									),
									self:AddressTableValue(
										self.CurrentModule.ChargeAlterTable.MaxDepletion,
										self.CurrentModule.MaxDepletion
									)
								)
						end
						self.CurrentVariables.Heat = self.CurrentVariables.Heat
							+ Random.new():NextInteger(
								self:AddressTableValue(
									self.CurrentModule.ChargeAlterTable.HeatPerFireMin,
									self.CurrentModule.HeatPerFireMin
								),
								self:AddressTableValue(
									self.CurrentModule.ChargeAlterTable.HeatPerFireMax,
									self.CurrentModule.HeatPerFireMax
								)
							)
					else
						self.CurrentVariables.Mag = self.CurrentVariables.Mag - 1
					end

					self:updateServerChangeMagAndAmmo()
					self:gunCoolDown()
					self:UpdateGUI()
					if self.CurrentModule.BurstFireEnabled then
						local BurstRate = self:AddressTableValue(
							self.CurrentModule.ChargeAlterTable.BurstRate,
							self.CurrentModule.BurstRate
						)
						local StartTime = os.clock()
						repeat
							self.Thread:Wait()
							if not self.CommonVariables.ActuallyEquipped then
								break
							end
						until (os.clock() - StartTime) >= BurstRate
					end
					if self.CurrentModule.BatteryEnabled then
						if self.CurrentVariables.Heat >= self.CurrentModule.MaxHeat then
							break
						end
					else
						if self.CurrentVariables.Mag <= 0 then
							break
						end
					end
				end
				self:setUpFiringAnimation()
				self.Thread:Wait(
					self:AddressTableValue(self.CurrentModule.ChargeAlterTable.FireRate, self.CurrentModule.FireRate)
				)
				if
					self.CurrentModule.BatteryEnabled and self.CurrentVariables.Heat >= self.CurrentModule.MaxHeat
					or self.CurrentVariables.Mag <= 0
				then
					if
						self.CommonVariables.CurrentRate >= self.CurrentModule.MaximumRate
						and self.CurrentModule.SmokeTrailEnabled
					then
						self.Thread:Spawn(function()
							self.SmokeTrail:StopEmission()
							self.SmokeTrail:EmitSmokeTrail(
								self.HandleToFire["SmokeTrail" .. self.CurrentFireMode],
								self.VMHandleToFire["SmokeTrail" .. self.CurrentFireMode],
								self.CurrentModule.MaximumTime
							)
						end)
					end
				end
				if self.CurrentModule.ShotgunPump then
					if self.CommonVariables.ActuallyEquipped then
						if self.CurrentShotgunPumpinAnim then
							self.CurrentShotgunPumpinAnim:Play(nil, nil, self.CurrentShotgunPumpinAnimationSpeed)
						end
						if self.HandleToFire[self.CurrentFireMode]:FindFirstChild("PumpSound") then
							self.HandleToFire[self.CurrentFireMode].PumpSound:Play()
						end
						self.Thread:Spawn(function()
							local StartTime = os.clock()
							repeat
								self.Thread:Wait()
								if not self.CurrentVariables.ActuallyEquipped then
									break
								end
							until (os.clock() - StartTime) >= self.CurrentModule.BulletShellDelay
							if self.CurrentVariables.ActuallyEquipped then
								self:EjectShell(
									((self.Camera.Focus.p - self.Camera.CoordinateFrame.p).Magnitude <= 1)
										and self.HandleToFire
								)
							end
						end)
					end
					self.HandleToFire = (self.HandleToFire == self.Handle and self.CurrentModule.DualFireEnabled)
							and self.Handle2
						or self.Handle

					if self.CurrentModule.AimAnimationsEnabled then
						self.CurrentAimFireAnim = (
							self.CurrentAimFireAnim == self.CurrentAnimTable.AimFireAnim
							and self.Module.SecondaryFireAnimationEnabled
						)
								and self.CurrentAnimTable.AimSecondaryFireAnim
							or self.CurrentAnimTable.AimFireAnim
						self.CurrentAimFireAnimationSpeed = (
							self.CurrentAimFireAnimationSpeed == self.Module.AimFireAnimationSpeed
							and self.Module.SecondaryFireAnimationEnabled
						)
								and self.Module.AimSecondaryFireAnimationSpeed
							or self.Module.AimFireAnimationSpeed
					end

					self.CurrentFireAnim = (
						self.CurrentFireAnim == self.CurrentAnimTable.FireAnim
						and self.CurrentModule.SecondaryFireAnimationEnabled
					)
							and self.CurrentAnimTable.SecondaryFireAnim
						or self.CurrentAnimTable.FireAnim
					self.CurrentFireAnimationSpeed = (
						self.CurrentFireAnimationSpeed == self.CurrentModule.FireAnimationSpeed
						and self.CurrentModule.SecondaryFireAnimationEnabled
					)
							and self.CurrentModule.SecondaryFireAnimationSpeed
						or self.CurrentModule.FireAnimationSpeed

					self.CurrentShotgunPumpinAnim = (
						self.CurrentShotgunPumpinAnim == self.CurrentAnimTable.ShotgunPumpinAnim
						and self.CurrentModule.SecondaryShotgunPump
					)
							and self.CurrentAnimTable.SecondaryShotgunPumpinAnim
						or self.CurrentAnimTable.ShotgunPumpinAnim
					self.CurrentShotgunPumpinAnimationSpeed = (
						self.CurrentShotgunPumpinAnimationSpeed == self.CurrentModule.ShotgunPumpinAnimationSpeed
						and self.CurrentModule.SecondaryShotgunPump
					)
							and self.CurrentModule.SecondaryShotgunPumpinAnimationSpeed
						or self.CurrentModule.ShotgunPumpinAnimationSpeed

					self.Thread:Wait(self.CurrentModule.ShotgunPumpinSpeed)
				end
				self.CurrentVariables.ChargeLevel = 0
				self.CommonVariables.Enabled = true
				if self.CommonVariables.ActuallyEquipped then
					if self.CurrentModule.BatteryEnabled then
						if self.CurrentVariables.Heat >= self.CurrentModule.MaxHeat then
							self:Overheat()
						end
					else
						if self.Module.AutoReload then
							if self.CurrentVariables.Mag <= 0 then
								self:Reload()
							end
						end
					end
				end
			end
		end

		-- this is for when your gun is chared and ready to fire
	elseif self.CurrentModule.HoldAndReleaseEnabled and not self.CurrentModule.SelectiveFireEnabled then
		self.CommonVariables.Charging = true
		if self:gunCanFire() then
			self:chargeEffect()
			if self:gunDoneCharging() and self.CommonVariables.Charged then
				self.CommonVariables.Charged = false
				for _ = 1, (self.CurrentModule.BurstFireEnabled and self.CurrentModule.BulletPerBurst or 1) do
					local CLDirections = {}
					local SVDirections = {}
					local success = self:shotShellEjectSpawnLoop()
					if not success then
						break
					end
					self.CommonVariables.CurrentRate = self.CommonVariables.CurrentRate
						+ self.CurrentModule.SmokeTrailRateIncrement
					for ii = 1, (self.CurrentModule.ShotgunEnabled and self.CurrentModule.BulletPerShot or 1) do
						local Position = self:Get3DPosition(self.GunGUI.Crosshair.AbsolutePosition)
						local CurrentSpread = 0 -- Spread removed
						local cframe = (self.Camera.Focus.p - self.Camera.CoordinateFrame.p).Magnitude <= 1
								and CFrame.new(
									self.VMHandleToFire:FindFirstChild("GunFirePoint" .. self.CurrentFireMode).WorldPosition,
									Position
								)
							or CFrame.new(
								self.HandleToFire:FindFirstChild("GunFirePoint" .. self.CurrentFireMode).WorldPosition,
								Position
							)
						local svCframe = CFrame.new(
							self.HandleToFire:FindFirstChild("GunFirePoint" .. self.CurrentFireMode).WorldPosition,
							Position
						)

						if self.CurrentModule.ShotgunPattern and self.CurrentModule.SpreadPattern then
							local X, Y =
								self.CurrentModule.SpreadPattern[ii][1], self.CurrentModule.SpreadPattern[ii][2]
							local SpreadPattern = CFrame.Angles(
								math.rad(self.CurrentSpread * Y / 50),
								math.rad(CurrentSpread * X / 50),
								0
							)
							cframe = cframe * SpreadPattern
							svCframe = svCframe * SpreadPattern
						else
							local SpreadNormal = CFrame.Angles(
								math.rad(math.random(-self.CurrentSpread, CurrentSpread) / 50),
								math.rad(math.random(-self.CurrentSpread, CurrentSpread) / 50),
								0
							)
							cframe = cframe * SpreadNormal
							svCframe = svCframe * SpreadNormal
						end

						local ClDirection = cframe.LookVector
						local SvDirection = svCframe.LookVector
						table.insert(CLDirections, ClDirection)
						table.insert(SVDirections, SvDirection)
					end
					if self.CurrentModule.SelfKnockback then
						local KnockbackPosition = self:Get3DPosition(self.GunGUI.Crosshair.AbsolutePosition)
						self:SelfKnockback(KnockbackPosition, self.Torso.Position)
					end
					self:Fire(self.HandleToFire, self.VMHandleToFire, CLDirections, SVDirections)
					if self.CurrentModule.BatteryEnabled then
						self.CurrentVariables.ShotsForDepletion = self.CurrentVariables.ShotsForDepletion + 1
						if self.CurrentVariables.ShotsForDepletion >= self.CurrentModule.ShotsForDepletion then
							self.CurrentVariables.ShotsForDepletion = 0
							self.CurrentVariables.Ammo = self.CurrentVariables.Ammo
								- Random.new()
									:NextInteger(self.CurrentModule.MinDepletion, self.CurrentModule.MaxDepletion)
						end
						self.CurrentVariables.Heat = self.CurrentVariables.Heat
							+ Random.new()
								:NextInteger(self.CurrentModule.HeatPerFireMin, self.CurrentModule.HeatPerFireMax)
					else
						self.CurrentVariables.Mag = self.CurrentVariables.Mag - 1
					end
					self:updateServerChangeMagAndAmmo()
					self:gunCoolDown()
					self:UpdateGUI()
					if self.CurrentModule.BurstFireEnabled then
						local StartTime = os.clock()
						repeat
							self.Thread:Wait()
							if not self.CommonVariables.ActuallyEquipped then
								break
							end
						until (os.clock() - StartTime) >= self.CurrentModule.BurstRate
					end
					if self.CurrentModule.BatteryEnabled then
						if self.CurrentVariables.Heat >= self.CurrentModule.MaxHeat then
							break
						end
					else
						if self.CurrentVariables.Mag <= 0 then
							break
						end
					end
				end
				self:setUpFiringAnimation()
				self.Thread:Wait(self.CurrentModule.FireRate)
				if
					self.CurrentModule.BatteryEnabled and self.CurrentVariables.Heat >= self.CurrentModule.MaxHeat
					or self.CurrentVariables.Mag <= 0
				then
					if
						self.CommonVariables.CurrentRate >= self.CurrentModule.MaximumRate
						and self.CurrentModule.SmokeTrailEnabled
					then
						self.Thread:Spawn(function()
							self.SmokeTrail:StopEmission()
							self.SmokeTrail:EmitSmokeTrail(
								self.HandleToFire["SmokeTrail" .. self.CurrentFireMode],
								self.VMHandleToFire["SmokeTrail" .. self.CurrentFireMode],
								self.CurrentModule.MaximumTime
							)
						end)
					end
				end
				if self.CurrentModule.ShotgunPump then
					if self.CommonVariables.ActuallyEquipped then
						if self.CurrentShotgunPumpinAnim then
							self.CurrentShotgunPumpinAnim:Play(nil, nil, self.CurrentShotgunPumpinAnimationSpeed)
						end
						if self.HandleToFire[self.CurrentFireMode]:FindFirstChild("PumpSound") then
							self.HandleToFire[self.CurrentFireMode].PumpSound:Play()
						end
						self.Thread:Spawn(function()
							local StartTime = os.clock()
							repeat
								self.Thread:Wait()
								if not self.CommonVariables.ActuallyEquipped then
									break
								end
							until (os.clock() - StartTime) >= self.CurrentModule.BulletShellDelay
							if self.CommonVariables.ActuallyEquipped then
								self:EjectShell(
									((self.Camera.Focus.p - self.Camera.CoordinateFrame.p).Magnitude <= 1)
										and self.HandleToFire
								)
							end
						end)
					end
					self.HandleToFire = (self.HandleToFire == self.Handle and self.CurrentModule.DualFireEnabled)
							and self.Handle2
						or self.Handle

					if self.CurrentModule.AimAnimationsEnabled then
						self.CurrentAimFireAnim = (
							self.CurrentAimFireAnim == self.CurrentAnimTable.AimFireAnim
							and self.CurrentModule.SecondaryFireAnimationEnabled
						)
								and self.CurrentAnimTable.AimSecondaryFireAnim
							or self.CurrentAnimTable.AimFireAnim
						self.CurrentAimFireAnimationSpeed = (
							self.CurrentAimFireAnimationSpeed == self.CurrentModule.AimFireAnimationSpeed
							and self.CurrentModule.SecondaryFireAnimationEnabled
						)
								and self.CurrentModule.AimSecondaryFireAnimationSpeed
							or self.CurrentModule.AimFireAnimationSpeed
					end

					self.CurrentFireAnim = (
						self.CurrentFireAnim == self.CurrentAnimTable.FireAnim
						and self.CurrentModule.SecondaryFireAnimationEnabled
					)
							and self.CurrentAnimTable.SecondaryFireAnim
						or self.CurrentAnimTable.FireAnim
					self.CurrentFireAnimationSpeed = (
						self.CurrentFireAnimationSpeed == self.CurrentModule.FireAnimationSpeed
						and self.CurrentModule.SecondaryFireAnimationEnabled
					)
							and self.CurrentModule.SecondaryFireAnimationSpeed
						or self.CurrentModule.FireAnimationSpeed

					self.CurrentShotgunPumpinAnim = (
						self.CurrentShotgunPumpinAnim == self.CurrentAnimTable.ShotgunPumpinAnim
						and self.CurrentModule.SecondaryShotgunPump
					)
							and self.CurrentAnimTable.SecondaryShotgunPumpinAnim
						or self.CurrentAnimTable.ShotgunPumpinAnim
					self.CurrentShotgunPumpinAnimationSpeed = (
						self.CurrentShotgunPumpinAnimationSpeed == self.CurrentModule.ShotgunPumpinAnimationSpeed
						and self.CurrentModule.SecondaryShotgunPump
					)
							and self.CurrentModule.SecondaryShotgunPumpinAnimationSpeed
						or self.CurrentModule.ShotgunPumpinAnimationSpeed

					self.Thread:Wait(self.CurrentModule.ShotgunPumpinSpeed)
				end
				self.CommonVariables.Enabled = true
				if self.CommonVariables.ActuallyEquipped then
					if self.CurrentModule.BatteryEnabled then
						if self.CurrentVariables.Heat >= self.CurrentModule.MaxHeat then
							self:Overheat()
						end
					else
						if self.Module.AutoReload then
							if self.CurrentVariables.Mag <= 0 then
								self:Reload()
							end
						end
					end
				end
			end
		end
	else
		self.CommonVariables.Down = true
		local IsChargedShot = false
		if self:gunCanFire() then
			self.CommonVariables.CanBeCooledDown = false
			self.CommonVariables.Enabled = false
			if self.CurrentAnimTable.InspectAnim and self.CurrentAnimTable.InspectAnim.IsPlaying then
				self.CurrentAnimTable.InspectAnim:Stop()
			end

			if self.CurrentModule.ChargedShotEnabled then
				if
					self.CommonVariables.ActuallyEquipped
					and self.HandleToFire[self.CurrentFireMode]:FindFirstChild("ChargeSound")
				then
					self.HandleToFire[self.CurrentFireMode].ChargeSound:Play()
				end
				self.Thread:Wait(self.CurrentModule.ChargingTime)
				IsChargedShot = true
			end
			if self.CurrentModule.MinigunEnabled then
				if self.CurrentAnimTable.MinigunRevUpAnim and not self.CurrentAnimTable.MinigunRevUpAnim.IsPlaying then
					self.CurrentAnimTable.MinigunRevUpAnim:Play(nil, nil, self.CurrentModule.MinigunRevUpAnimationSpeed)
				end

				if
					self.CommonVariables.ActuallyEquipped
					and self.HandleToFire[self.CurrentFireMode]:FindFirstChild("WindUp")
				then
					self.HandleToFire[self.CurrentFireMode].WindUp:Play()
				end
				self.Thread:Wait(self.CurrentModule.DelayBeforeFiring)
			end
			while (self.CommonVariables.Down or IsChargedShot) and self:gunDoneCharging() do
				IsChargedShot = false
				for _ = 1, ((self.CurrentModule.SelectiveFireEnabled and (self.CurrentVariables.FireModes[self.CurrentVariables.FireMode] ~= true and self.CurrentVariables.FireModes[self.CurrentVariables.FireMode] or 1)) or (self.CurrentModule.BurstFireEnabled and self.CurrentModule.BulletPerBurst) or 1) do
					local CLDirections = {}
					local SVDirections = {}
					local success = self:shotShellEjectSpawnLoop()
					if not success then
						break
					end
					self.CommonVariables.CurrentRate = self.CommonVariables.CurrentRate
						+ self.CurrentModule.SmokeTrailRateIncrement
					for ii = 1, (self.CurrentModule.ShotgunEnabled and self.CurrentModule.BulletPerShot or 1) do
						local Position = self:Get3DPosition(self.GunGUI.Crosshair.AbsolutePosition)
						local Spread = 0 -- Spread removed
						local cframe = CFrame.new(
							self.VMHandleToFire:FindFirstChild("GunFirePoint" .. self.CurrentFireMode).WorldPosition,
							Position
						)
						local svCframe = CFrame.new(
							self.HandleToFire:FindFirstChild("GunFirePoint" .. self.CurrentFireMode).WorldPosition,
							Position
						)

						if self.CurrentModule.ShotgunPattern and self.CurrentModule.SpreadPattern then
							local X, Y =
								self.CurrentModule.SpreadPattern[ii][1], self.CurrentModule.SpreadPattern[ii][2]
							local SpreadPattern = CFrame.Angles(math.rad(Spread * Y / 50), math.rad(Spread * X / 50), 0)
							cframe = cframe * SpreadPattern
							svCframe = svCframe * SpreadPattern
						else
							local SpreadNormal = CFrame.Angles(
								math.rad(math.random(-Spread, Spread) / 50),
								math.rad(math.random(-Spread, Spread) / 50),
								0
							)
							cframe = cframe * SpreadNormal
							svCframe = svCframe * SpreadNormal
						end

						local ClDirection = cframe.LookVector
						local SvDirection = svCframe.LookVector
						table.insert(CLDirections, ClDirection)
						table.insert(SVDirections, SvDirection)
					end
					if self.CurrentModule.SelfKnockback then
						local KnockbackPosition = self:Get3DPosition(self.GunGUI.Crosshair.AbsolutePosition)
						self:SelfKnockback(KnockbackPosition, self.Torso.Position)
					end
					self:Fire(self.HandleToFire, self.VMHandleToFire, CLDirections, SVDirections)
					if self.CurrentModule.BatteryEnabled then
						self.CurrentVariables.ShotsForDepletion = self.CurrentVariables.ShotsForDepletion + 1
						if self.CurrentVariables.ShotsForDepletion >= self.CurrentModule.ShotsForDepletion then
							self.CurrentVariables.ShotsForDepletion = 0
							self.CurrentVariables.Ammo = self.CurrentVariables.Ammo
								- Random.new()
									:NextInteger(self.CurrentModule.MinDepletion, self.CurrentModule.MaxDepletion)
						end
						self.CurrentVariables.Heat = self.CurrentVariables.Heat
							+ Random.new()
								:NextInteger(self.CurrentModule.HeatPerFireMin, self.CurrentModule.HeatPerFireMax)
					else
						self.CurrentVariables.Mag = self.CurrentVariables.Mag - 1
					end
					self:updateServerChangeMagAndAmmo()
					self:gunCoolDown()
					self:UpdateGUI()
					if self.CurrentModule.BurstFireEnabled and not self.CurrentModule.SelectiveFireEnabled then
						local StartTime = os.clock()
						repeat
							self.Thread:Wait()
							if not self.CommonVariables.ActuallyEquipped then
								break
							end
						until (os.clock() - StartTime) >= self.CurrentModule.BurstRate
					end
					if self.CurrentModule.SelectiveFireEnabled then
						local StartTime = os.clock()
						repeat
							self.Thread:Wait()
							if not self.CommonVariables.ActuallyEquipped then
								break
							end
						until (os.clock() - StartTime)
							>= self.CurrentModule.BurstRates[self.CurrentVariables.FireMode]
					end
					if self.CurrentModule.BatteryEnabled then
						if self.CurrentVariables.Heat >= self.CurrentModule.MaxHeat then
							break
						end
					else
						if self.CurrentVariables.Mag <= 0 then
							break
						end
					end
				end
				self:setUpFiringAnimation()
				self.Thread:Wait(
					self.CurrentModule.SelectiveFireEnabled
							and self.CurrentModule.FireRates[self.CurrentVariables.FireMode]
						or self.CurrentModule.FireRate
				)
				if
					self.CurrentModule.BatteryEnabled and self.CurrentVariables.Heat >= self.CurrentModule.MaxHeat
					or self.CurrentVariables.Mag <= 0
				then
					if
						self.CommonVariables.CurrentRate >= self.CurrentModule.MaximumRate
						and self.CurrentModule.SmokeTrailEnabled
					then
						self.Thread:Spawn(function()
							self.SmokeTrail:StopEmission()
							self.SmokeTrail:EmitSmokeTrail(
								self.HandleToFire["SmokeTrail" .. self.CurrentFireMode],
								self.VMHandleToFire["SmokeTrail" .. self.CurrentFireMode],
								self.CurrentModule.MaximumTime
							)
						end)
					end
				end
				if self.CurrentModule.SelectiveFireEnabled then
					if self.CurrentVariables.FireModes[self.CurrentVariables.FireMode] ~= true then
						break
					end
				else
					if not self.CurrentModule.Auto then
						break
					end
				end
			end
			if self.CurrentModule.MinigunEnabled then
				if
					self.CommonVariables.ActuallyEquipped
					and self.CurrentAnimTable.MinigunRevDownAnim
					and not self.CurrentAnimTable.MinigunRevDownAnim.IsPlaying
				then
					self.CurrentAnimTable.MinigunRevDownAnim:Play(
						nil,
						nil,
						self.CurrentModule.MinigunRevDownAnimationSpeed
					)
				end
				if self.CurrentAnimTable.MinigunRevUpAnim and self.CurrentAnimTable.MinigunRevUpAnim.IsPlaying then
					self.CurrentAnimTable.MinigunRevUpAnim:Stop()
				end

				if
					self.CommonVariables.ActuallyEquipped
					and self.HandleToFire[self.CurrentFireMode]:FindFirstChild("WindDown")
				then
					self.HandleToFire[self.CurrentFireMode].WindDown:Play()
				end
				self.Thread:Wait(self.CurrentModule.DelayAfterFiring)
			end
			if self.CurrentModule.ShotgunPump then
				if self.CommonVariables.ActuallyEquipped then
					if self.CurrentShotgunPumpinAnim then
						self.CurrentShotgunPumpinAnim:Play(nil, nil, self.CurrentShotgunPumpinAnimationSpeed)
					end
					if self.HandleToFire[self.CurrentFireMode]:FindFirstChild("PumpSound") then
						self.HandleToFire[self.CurrentFireMode].PumpSound:Play()
					end
					self.Thread:Spawn(function()
						local StartTime = os.clock()
						repeat
							self.Thread:Wait()
							if not self.CommonVariables.ActuallyEquipped then
								break
							end
						until (os.clock() - StartTime) >= self.CurrentModule.BulletShellDelay
						if self.CommonVariables.ActuallyEquipped then
							self:EjectShell(
								((self.Camera.Focus.p - self.Camera.CoordinateFrame.p).Magnitude <= 1)
										and self.VMHandleToFire
									or self.HandleToFire
							)
						end
					end)
				end
				self.HandleToFire = (self.HandleToFire == self.Handle and self.CurrentModule.DualFireEnabled)
						and self.Handle2
					or self.Handle

				if self.CurrentModule.AimAnimationsEnabled then
					self.CurrentAimFireAnim = (
						self.CurrentAimFireAnim == self.CurrentAnimTable.AimFireAnim
						and self.CurrentModule.SecondaryFireAnimationEnabled
					)
							and self.CurrentAnimTable.AimSecondaryFireAnim
						or self.CurrentAnimTable.AimFireAnim
					self.CurrentAimFireAnimationSpeed = (
						self.CurrentAimFireAnimationSpeed == self.CurrentModule.AimFireAnimationSpeed
						and self.CurrentModule.SecondaryFireAnimationEnabled
					)
							and self.CurrentModule.AimSecondaryFireAnimationSpeed
						or self.CurrentModule.AimFireAnimationSpeed
				end

				self.CurrentFireAnim = (
					self.CurrentFireAnim == self.CurrentAnimTable.FireAnim
					and self.CurrentModule.SecondaryFireAnimationEnabled
				)
						and self.CurrentAnimTable.SecondaryFireAnim
					or self.CurrentAnimTable.FireAnim
				self.CurrentFireAnimationSpeed = (
					self.CurrentFireAnimationSpeed == self.CurrentModule.FireAnimationSpeed
					and self.CurrentModule.SecondaryFireAnimationEnabled
				)
						and self.CurrentModule.SecondaryFireAnimationSpeed
					or self.CurrentModule.FireAnimationSpeed

				self.CurrentShotgunPumpinAnim = (
					self.CurrentShotgunPumpinAnim == self.CurrentAnimTable.ShotgunPumpinAnim
					and self.CurrentModule.SecondaryShotgunPump
				)
						and self.CurrentAnimTable.SecondaryShotgunPumpinAnim
					or self.CurrentAnimTable.ShotgunPumpinAnim
				self.CurrentShotgunPumpinAnimationSpeed = (
					self.CurrentShotgunPumpinAnimationSpeed == self.CurrentModule.ShotgunPumpinAnimationSpeed
					and self.CurrentModule.SecondaryShotgunPump
				)
						and self.CurrentModule.SecondaryShotgunPumpinAnimationSpeed
					or self.CurrentModule.ShotgunPumpinAnimationSpeed

				self.Thread:Wait(self.CurrentModule.ShotgunPumpinSpeed)
			end
			self.CommonVariables.Enabled = true
			if self.CurrentVariables.Mag <= 0 then
				self.CurrentFireAnim:Stop()
				self.Empty:Play()
			end
			if self.CommonVariables.ActuallyEquipped then
				if self.CurrentModule.BatteryEnabled then
					if self.CurrentVariables.Heat >= self.CurrentModule.MaxHeat then
						self:Overheat()
					end
				else
					if self.Module.AutoReload then
						if self.CurrentVariables.Mag <= 0 then
							self:Reload()
						end
					end
				end
			end
		end
	end
end

function GunHandlerClient:OnStoppingFiring()
	self.CommonVariables.Down = false
	if self.CurrentModule.ChargedShotAdvanceEnabled or self.CurrentModule.HoldAndReleaseEnabled then
		self.CommonVariables.Charging = false
	end
	if self.CurrentModule.HoldAndReleaseEnabled and not self.CommonVariables.Charged then
		self.CommonVariables.Enabled = true
	end
	if self.CommonVariables.CurrentRate >= self.CurrentModule.MaximumRate and self.CurrentModule.SmokeTrailEnabled then
		self.Thread:Spawn(function()
			self.SmokeTrail:StopEmission()
			self.SmokeTrail:EmitSmokeTrail(
				self.HandleToFire["SmokeTrail" .. self.CurrentFireMode],
				self.VMHandleToFire["SmokeTrail" .. self.CurrentFireMode],
				self.CurrentModule.MaximumTime
			)
		end)
	end
end

function GunHandlerClient:OnMeleeSequenceTriggered(ShootingHandle)
	local Direction = ((ShootingHandle["MeleeHitPoint" .. self.CurrentFireMode].WorldCFrame * CFrame.new(
		0,
		0,
		-self.CurrentModule.MeleeAttackRange
	)).p - ShootingHandle["MeleeHitPoint" .. self.CurrentFireMode].WorldPosition).Unit
	local MeleeRay = Ray.new(
		ShootingHandle["MeleeHitPoint" .. self.CurrentFireMode].WorldPosition,
		Direction * self.CurrentModule.MeleeAttackRange
	)
	local Hit, Pos, Norm, Material = Workspace:FindPartOnRayWithIgnoreList(MeleeRay, { self.Camera, self.Tool.Parent })
	if Hit then
		if Hit.Name == "_glass" then
			self.ShatterGlass:FireServer(Hit, Pos, Direction)
		else
			local Target = Hit:FindFirstAncestorOfClass("Model")
			local TargetHumanoid = Target and Target:FindFirstChildOfClass("Humanoid")
			local TargetTorso = Target and (Target:FindFirstChild("HumanoidRootPart") or Target:FindFirstChild("Head"))
			local VisualEffects2 = self.VisualEffects
			if self.VisualEffects:FindFirstChild(self.CurrentModule.ModuleName) then
				VisualEffects2 = self.VisualEffects[self.CurrentModule]
			end
			if TargetHumanoid and TargetHumanoid.Health > 0 and TargetTorso then
				self.ProjectileHandler:VisualizeHitEffect(
					"Blood",
					Hit,
					Pos,
					Norm,
					Material,
					self.CurrentModule,
					{ BloodEffectFolder = VisualEffects2.MeleeBloodEffect },
					true
				)
				if TargetHumanoid.Health > 0 then
					self.Thread:Spawn(function()
						self.InflictTarget:InvokeServer(
							"GunMelee",
							self.Tool,
							self.CurrentModule,
							TargetHumanoid,
							TargetTorso,
							Hit
						)
					end)
					self:MarkHit(self.CurrentModule, Hit.Name == "Head" and self.CurrentModule.MeleeHeadshotEnabled)
				end
			else
				self.ProjectileHandler:VisualizeHitEffect(
					"Normal",
					Hit,
					Pos,
					Norm,
					Material,
					self.CurrentModule,
					{ HitEffectFolder = VisualEffects2.MeleeHitEffect },
					true
				)
			end
		end
	end
end

function GunHandlerClient:OnMeleeAttacking()
	if self.CurrentModule.MeleeAttackEnabled then
		if self.CurrentAnimTable.MeleeAttackAnim and self.CurrentAnimTable.MeleeAttackAnim.Length > 0 then
			local Connection
			if
				self.CommonVariables.ActuallyEquipped
				and self.CommonVariables.Enabled
				and not self.CommonVariables.Overheated
				and not self.CommonVariables.Switching
				and not self.CommonVariables.Alting
				and not self.CommonVariables.AimDown
				and self.Humanoid.Health > 0
			then
				self.CommonVariables.Enabled = false
				if self.CurrentAnimTable.InspectAnim and self.CurrentAnimTable.InspectAnim.IsPlaying then
					self.CurrentAnimTable.InspectAnim:Stop()
				end
				self.CurrentAnimTable.MeleeAttackAnim:Play(nil, nil, self.CurrentModule.MeleeAttackAnimationSpeed)
				if
					self.CommonVariables.ActuallyEquipped
					and self.HandleToFire[self.CurrentFireMode]:FindFirstChild("MeleeSwingSound")
				then
					self.HandleToFire[self.CurrentFireMode].MeleeSwingSound:Play()
				end
				Connection = self.CurrentAnimTable.MeleeAttackAnim
					:GetMarkerReachedSignal("MeleeDamageSequence")
					:Connect(function()
						if (self.Camera.Focus.p - self.Camera.CoordinateFrame.p).Magnitude > 1 then
							self:OnMeleeSequenceTriggered(self.Handle)
						end
						if Connection then
							Connection:Disconnect()
							Connection = nil
						end
					end)

				if (self.Camera.Focus.p - self.Camera.CoordinateFrame.p).Magnitude <= 1 then
					self.CurrentVMAnimTable.VMMeleeAttackAnim.Stopped:Wait()
				else
					self.CurrentAnimTable.MeleeAttackAnim.Stopped:Wait()
				end
				self.CurrentAnimTable.MeleeAttackAnim.Stopped:Wait()
				self.CommonVariables.Enabled = true
			end
		end
	end
end

function GunHandlerClient:OnEquipt()
	self.GunGUI = self.Hud:Clone()
	self.GunGUI.Parent = self.PlayerGui

	if UserInputService.TouchEnabled then
		local MobileButtons = self.GunGUI:WaitForChild("MobileButtons")
		MobileButtons.Visible = true

		self.connections[#self.connections + 1] = MobileButtons.AimButton.MouseButton1Click:Connect(function()
			self:OnTooglingAiming()
		end)
		self.connections[#self.connections + 1] = MobileButtons.HoldDownButton.MouseButton1Click:Connect(function()
			self:OnHoldingDown()
		end)
		self.connections[#self.connections + 1] = MobileButtons.InspectButton.MouseButton1Click:Connect(function()
			self:OnInspecting()
		end)
		self.connections[#self.connections + 1] = MobileButtons.SwitchButton.MouseButton1Click:Connect(function()
			self:OnSwitching()
		end)
		self.connections[#self.connections + 1] = MobileButtons.ReloadButton.MouseButton1Click:Connect(function()
			self:Reload()
		end)
		self.connections[#self.connections + 1] = MobileButtons.FireButton.MouseButton1Down:Connect(function()
			self:OnFiring()
		end)
		self.connections[#self.connections + 1] = MobileButtons.FireButton.MouseButton1Up:Connect(function()
			self:OnStoppingFiring()
		end)
		self.connections[#self.connections + 1] = MobileButtons.MeleeButton.MouseButton1Click:Connect(function()
			self:OnMeleeAttacking()
		end)
		self.connections[#self.connections + 1] = MobileButtons.AltButton.MouseButton1Click:Connect(function()
			self:OnAlting()
		end)
	end
	self.connections[#self.connections + 1] = UserInputService.InputBegan:Connect(function(...)
		self:InputBegin(...)
	end)
	self.connections[#self.connections + 1] = UserInputService.InputEnded:Connect(function(...)
		self:InputEnded(...)
	end)
	self.connections[#self.connections + 1] = self.MarkerEvent.Event:Connect(function(...)
		self:MarkHit(...)
	end)
	self.connections[#self.connections + 1] = self.ChangeMagAndAmmo.OnClientEvent:Connect(function(...)
		self:OnChangeMagAndAmmoEvent(...)
	end)

	self.connections[#self.connections + 1] = self.Tool.Unequipped:Connect(function()
		self:OnUnequipping()
	end)
	self.connections[#self.connections + 1] = self.Character.Destroying:Connect(function()
		self:OnUnequipping()
	end)
	self.connections[#self.connections + 1] = self.Humanoid.Died:Connect(function()
		self:OnUnequipping()
	end)
	self.connections[#self.connections + 1] = self.Tool.AncestryChanged:Connect(function()
		self:ToolParentChange()
	end)
	self.connections[#self.connections + 1] = self.Player.CharacterRemoving:Connect(function()
		self:OnUnequipping()
	end)
	if self.CurrentVariables.Mag <= 0 then
		self.CurrentFireAnim:Stop()
		self.Empty:Play()
	end

	self.CommonVariables.Equipped = true
	self:UpdateGUI()

	self.Handle[self.CurrentFireMode].EquippedSound:Play()

	if self.Module.WalkSpeedRedutionEnabled then
		self.Humanoid.WalkSpeed = self.Humanoid.WalkSpeed - self.Module.WalkSpeedRedution
	end

	UserInputService.MouseIconEnabled = false

	if self.CurrentModule.ProjectileMotion then
		local VisualEffects2 = self.VisualEffects
		if self.VisualEffects:FindFirstChild(self.CurrentModule.ModuleName) then
			VisualEffects2 = self.VisualEffects[self.CurrentModule]
		end
		self.Beam, self.Attach0, self.Attach1 = self.ProjectileMotion.ShowProjectilePath(
			VisualEffects2.MotionBeam,
			self.HandleToFire:FindFirstChild("GunFirePoint" .. self.CurrentFireMode).WorldPosition,
			Vector3.new(),
			3,
			self:AddressTableValue(
				self.CurrentModule.ChargeAlterTable.BulletAcceleration,
				self.CurrentModule.BulletAcceleration
			)
		)
	end

	RunService:BindToRenderStep(self.BindToStepName, Enum.RenderPriority.Camera.Value, function(dt)
		--Update crosshair and scope
		self:RenderMouse()
		self:RenderScope() -- TODO LOOK in to Removing
		--Update camera
		self:RenderCam()
		--Update rate
		self:RenderRate(dt)
		--Render motion
		if self.CurrentModule.ProjectileMotion then
			self:RenderMotion()
		end
		--Render cooldown
		if self.CurrentModule.BatteryEnabled then
			self:RenderCooldown(dt)
		end
	end)

	if self.CurrentAnimTable.EquippedAnim then
		self.CurrentAnimTable.EquippedAnim:Play(nil, nil, self.CurrentModule.EquippedAnimationSpeed)
	end
	if self.CurrentAnimTable.IdleAnim then
		--TODO I think this animation does not work right for ars
		self.CurrentAnimTable.IdleAnim:Play(nil, nil, self.CurrentModule.IdleAnimationSpeed)
	end

	local StartTime = os.clock()
	repeat
		self.Thread:Wait()
		if not self.CommonVariables.Equipped then
			break
		end
	until (os.clock() - StartTime) >= self.CurrentModule.EquipTime
	if self.CommonVariables.Equipped then
		self.CommonVariables.ActuallyEquipped = true
	end

	if
		self.CommonVariables.ActuallyEquipped
		and self.Module.AutoReload
		and not self.CommonVariables.Reloading
		and (self.CurrentVariables.Ammo > 0 or not self.CurrentModule.LimitedAmmoEnabled)
		and self.CurrentVariables.Mag <= 0
	then
		self:Reload()
	end

	--// connections
end

function GunHandlerClient:OnUnequipping()
	self.Thread:Spawn(function()
		if self.GunGUI then
			self.GunGUI:Destroy()
			self.GunGUI = nil

			self.Empty:Stop()
			if self.CurrentModule.ChargedShotAdvanceEnabled then
				self.CommonVariables.Charging = false
			end
			if self.CurrentModule.HoldAndReleaseEnabled then
				self.CommonVariables.Charged = false
			end
			self.CommonVariables.Equipped = false
			self.CommonVariables.ActuallyEquipped = false

			for _, conn in ipairs(self.connections) do
				conn:Disconnect()
			end

			self.connections = {}

			if self.Module.WalkSpeedRedutionEnabled then
				self.Humanoid.WalkSpeed = self.Humanoid.WalkSpeed + self.Module.WalkSpeedRedution
			end
			UserInputService.MouseIconEnabled = true
			RunService:UnbindFromRenderStep(self.BindToStepName)
			for i, v in pairs(self.KeyframeConnections) do
				v:Disconnect()
				table.remove(self.KeyframeConnections, i)
			end
			table.clear(self.VMKeyframes)
			for i, v in pairs(self.VMKeyframeConnections) do
				v:Disconnect()
				table.remove(self.VMKeyframeConnections, i)
			end
			self.LockedEntity = nil
			if self.Beam then
				self.Beam:Destroy()
				self.Beam = nil
			end
			if self.Attach0 then
				self.Attach0:Destroy()
				self.Attach0 = nil
			end
			if self.Attach1 then
				self.Attach1:Destroy()
				self.Attach1 = nil
			end
			for _, a in pairs(self.CurrentAnimTable) do
				if a and a.IsPlaying then
					a:Stop()
				end
			end

			for _, s in pairs(self.Handle[self.CurrentFireMode]:GetChildren()) do
				if s:IsA("Sound") and s.IsPlaying then
					s:Stop()
				end
			end
			if self.Handle2 then
				for _, s in pairs(self.Handle2[self.CurrentFireMode]:GetChildren()) do
					if s:IsA("Sound") and s.IsPlaying then
						s:Stop()
					end
				end
			end
			if self.CommonVariables.AimDown then
				TweenService:Create(
					self.Camera,
					TweenInfo.new(
						self.CurrentModule.TweenLengthNAD,
						self.CurrentModule.EasingStyleNAD,
						self.CurrentModule.EasingDirectionNAD
					),
					{ FieldOfView = 70 }
				):Play()

				self.CommonVariables.Scoping = false
				self.Player.CameraMode = Enum.CameraMode.Classic
				UserInputService.MouseDeltaSensitivity = self.CommonVariables.InitialSensitivity
				self.CommonVariables.AimDown = false
			end

			self.FakeCamera = nil
		end
	end)
end

return GunHandlerClient
