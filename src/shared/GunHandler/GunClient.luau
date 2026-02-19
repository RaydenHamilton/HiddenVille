--!strict
local GunHandlerClient = {}

GunHandlerClient.__index = GunHandlerClient

function GunHandlerClient.new(tool)
	--// Services
	local HttpService = game:GetService("HttpService")
	local GuiService = game:GetService("GuiService")
	local RunService = game:GetService("RunService")
	local UserInputService = game:GetService("UserInputService")
	local TweenService = game:GetService("TweenService")
	local Debris = game:GetService("Debris")
	local Workspace = game:GetService("Workspace")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local Players = game:GetService("Players")

	--// References
	local Miscs = ReplicatedStorage:WaitForChild("Miscs")
	local Modules = ReplicatedStorage:WaitForChild("Modules")
	local Remotes = ReplicatedStorage:WaitForChild("Remotes")
	local Setting = tool:WaitForChild("Setting")

	--// Modules
	local ProjectileHandler = require(Modules.ProjectileHandler)
	local AudioHandler = require(Modules.AudioHandler)
	local SmokeTrail = require(Modules.SmokeTrail)
	local DamageModule = require(Modules.DamageModule)
	local Utilities = require(Modules.Utilities)
	local Module = require(Setting)

	--// Variables
	local Tool = tool
	local Handle
	local AnimationFolder = Tool:WaitForChild("AnimationFolder")
	local ValueFolder = Tool:WaitForChild("ValueFolder")
	local Player = Players.LocalPlayer
	local Character = Workspace:WaitForChild(Player.Name)
	local Humanoid = Character:WaitForChild("Humanoid")
	local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
	local Torso = Character:FindFirstChild("Torso") or Character:FindFirstChild("UpperTorso")
	local PlayerGui = Player:WaitForChild("PlayerGui")
	local Mouse = Player:GetMouse()
	local Camera = Workspace.CurrentCamera
	local GUI = ReplicatedStorage:WaitForChild("GunGUI")
	local GunGUI
	local Empty = game.Players.LocalPlayer.Character.Humanoid:LoadAnimation(Tool.Empty)
	local TouchGui
	local TouchControlFrame

	if UserInputService.TouchEnabled then
		TouchGui = PlayerGui:WaitForChild("TouchGui")
		TouchControlFrame = TouchGui:WaitForChild("TouchControlFrame")
		TouchControlFrame:WaitForChild("JumpButton")
	end

	local MarkerEvent = Tool:WaitForChild("MarkerEvent")
	local ChangeMagAndAmmo = Tool:WaitForChild("ChangeMagAndAmmo")
	local FlingDeadBody = Tool:WaitForChild("FlingDeadBody")

	local GunVisualEffects = Miscs.GunVisualEffects

	local Thread = Utilities.Thread
	local ProjectileMotion = Utilities.ProjectileMotion
	local Math = Utilities.Math

	local InflictTarget = Remotes.InflictTarget
	local ShatterGlass = Remotes.ShatterGlass

	Handle = Tool:WaitForChild(Module.PrimaryHandle)

	local BindToStepName = "UpdateGun_" .. HttpService:GenerateGUID()

	local VisualEffects = Module.UseCommonVisualEffects and GunVisualEffects.Common or GunVisualEffects[Tool.Name]

	--Viewmodel

	local FakeCamera
	local VMHandle2
	local VMHandleToFire = Tool.Handle
	local CFAngles

	local VMKeyframes = {}
	local VMKeyframeConnections = {}
	--
	local Handle2
	local HandleToFire = Handle
	local Beam, Attach0, Attach1
	local Animations = {}
	local SettingModules = {}
	local Variables = {}
	local KeyframeConnections = {}
	local TwoDeeShells = {}
	local connections = {}

	if Module.DualWeldEnabled then
		Handle2 = Tool:WaitForChild(Module.SecondaryHandle, 2)
		if Handle2 == nil and Module.DualWeldEnabled then
			error('"Dual" setting is enabled but "Handle2" is missing!')
		end
	end

	local LockedEntity
	local CommonVariables = {
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
		TwoDeeShellCount = 0,
		InitialSensitivity = UserInputService.MouseDeltaSensitivity,
	}

	for i, v in ipairs(Setting:GetChildren()) do
		table.insert(SettingModules, require(v))
		table.insert(Variables, {
			Mag = ValueFolder[i].Mag.Value,
			Ammo = ValueFolder[i].Ammo.Value,
			Heat = ValueFolder[i].Heat.Value,
			MaxAmmo = SettingModules[i].MaxAmmo,
			ElapsedCooldownTime = 0,
			ChargeLevel = 0,
			FireModes = SettingModules[i].FireModes,
			FireMode = 1,
			ShotsForDepletion = 0,
			ShotID = 0,
		})
	end

	for i, v in ipairs(AnimationFolder:GetChildren()) do
		local AnimTable = {}
		if SettingModules[i].EquippedAnimationID ~= nil then
			AnimTable.EquippedAnim = v.ThirdPerson:WaitForChild("EquippedAnim")
			AnimTable.EquippedAnim = Humanoid:LoadAnimation(AnimTable.EquippedAnim)
		end
		if SettingModules[i].IdleAnimationID ~= nil then
			AnimTable.IdleAnim = v.ThirdPerson:WaitForChild("IdleAnim")
			AnimTable.IdleAnim = Humanoid:LoadAnimation(AnimTable.IdleAnim)
		end

		if SettingModules[i].FireAnimationID ~= nil then
			AnimTable.FireAnim = v.ThirdPerson:WaitForChild("FireAnim")
			AnimTable.FireAnim = Humanoid:LoadAnimation(AnimTable.FireAnim)
		end
		if SettingModules[i].ShotgunPumpinAnimationID ~= nil then
			AnimTable.ShotgunPumpinAnim = v.ThirdPerson:WaitForChild("ShotgunPumpinAnim")
			AnimTable.ShotgunPumpinAnim = Humanoid:LoadAnimation(AnimTable.ShotgunPumpinAnim)
		end
		if SettingModules[i].ShotgunClipinAnimationID ~= nil then
			AnimTable.ShotgunClipinAnim = v.ThirdPerson:WaitForChild("ShotgunClipinAnim")
			AnimTable.ShotgunClipinAnim = Humanoid:LoadAnimation(AnimTable.ShotgunClipinAnim)
		end
		if SettingModules[i].ReloadAnimationID ~= nil then
			AnimTable.ReloadAnim = v.ThirdPerson:WaitForChild("ReloadAnim")
			AnimTable.ReloadAnim = Humanoid:LoadAnimation(AnimTable.ReloadAnim)
		end
		if SettingModules[i].HoldDownAnimationID ~= nil then
			AnimTable.HoldDownAnim = v.ThirdPerson:WaitForChild("HoldDownAnim")
			AnimTable.HoldDownAnim = Humanoid:LoadAnimation(AnimTable.HoldDownAnim)
		end
		if SettingModules[i].SecondaryFireAnimationEnabled and SettingModules[i].SecondaryFireAnimationID ~= nil then
			AnimTable.SecondaryFireAnim = v.ThirdPerson:WaitForChild("SecondaryFireAnim")
			AnimTable.SecondaryFireAnim = Humanoid:LoadAnimation(AnimTable.SecondaryFireAnim)
		end
		if SettingModules[i].SecondaryShotgunPump and SettingModules[i].SecondaryShotgunPumpinAnimationID ~= nil then
			AnimTable.SecondaryShotgunPumpinAnim = v.ThirdPerson:WaitForChild("SecondaryShotgunPumpinAnim")
			AnimTable.SecondaryShotgunPumpinAnim = Humanoid:LoadAnimation(AnimTable.SecondaryShotgunPumpinAnim)
		end
		if SettingModules[i].AimAnimationsEnabled and SettingModules[i].AimIdleAnimationID ~= nil then
			AnimTable.AimIdleAnim = v.ThirdPerson:WaitForChild("AimIdleAnim")
			AnimTable.AimIdleAnim = Humanoid:LoadAnimation(AnimTable.AimIdleAnim)
		end
		if SettingModules[i].AimAnimationsEnabled and SettingModules[i].AimFireAnimationID ~= nil then
			AnimTable.AimFireAnim = v.ThirdPerson:WaitForChild("AimFireAnim")
			AnimTable.AimFireAnim = Humanoid:LoadAnimation(AnimTable.AimFireAnim)
		end
		if SettingModules[i].AimAnimationsEnabled and SettingModules[i].AimSecondaryFireAnimationID ~= nil then
			AnimTable.AimSecondaryFireAnim = v.ThirdPerson:WaitForChild("AimSecondaryFireAnim")
			AnimTable.AimSecondaryFireAnim = Humanoid:LoadAnimation(AnimTable.AimSecondaryFireAnim)
		end
		if SettingModules[i].AimAnimationsEnabled and SettingModules[i].AimChargingAnimationID ~= nil then
			AnimTable.AimChargingAnim = v.ThirdPerson:WaitForChild("AimChargingAnim")
			AnimTable.AimChargingAnim = Humanoid:LoadAnimation(AnimTable.AimChargingAnim)
		end
		if SettingModules[i].TacticalReloadAnimationEnabled and SettingModules[i].TacticalReloadAnimationID ~= nil then
			AnimTable.TacticalReloadAnim = v.ThirdPerson:WaitForChild("TacticalReloadAnim")
			AnimTable.TacticalReloadAnim = Humanoid:LoadAnimation(AnimTable.TacticalReloadAnim)
		end
		if SettingModules[i].InspectAnimationEnabled and SettingModules[i].InspectAnimationID ~= nil then
			AnimTable.InspectAnim = v.ThirdPerson:WaitForChild("InspectAnim")
			AnimTable.InspectAnim = Humanoid:LoadAnimation(AnimTable.InspectAnim)
		end
		if
			SettingModules[i].ShotgunReload
			and SettingModules[i].PreShotgunReload
			and SettingModules[i].PreShotgunReloadAnimationID ~= nil
		then
			AnimTable.PreShotgunReloadAnim = v.ThirdPerson:WaitForChild("PreShotgunReloadAnim")
			AnimTable.PreShotgunReloadAnim = Humanoid:LoadAnimation(AnimTable.PreShotgunReloadAnim)
		end
		if SettingModules[i].MinigunRevUpAnimationID ~= nil then
			AnimTable.MinigunRevUpAnim = v.ThirdPerson:WaitForChild("MinigunRevUpAnim")
			AnimTable.MinigunRevUpAnim = Humanoid:LoadAnimation(AnimTable.MinigunRevUpAnim)
		end
		if SettingModules[i].MinigunRevDownAnimationID ~= nil then
			AnimTable.MinigunRevDownAnim = v.ThirdPerson:WaitForChild("MinigunRevDownAnim")
			AnimTable.MinigunRevDownAnim = Humanoid:LoadAnimation(AnimTable.MinigunRevDownAnim)
		end
		if SettingModules[i].ChargingAnimationEnabled and SettingModules[i].ChargingAnimationID ~= nil then
			AnimTable.ChargingAnim = v.ThirdPerson:WaitForChild("ChargingAnim")
			AnimTable.ChargingAnim = Humanoid:LoadAnimation(AnimTable.ChargingAnim)
		end
		if SettingModules[i].SelectiveFireEnabled and SettingModules[i].SwitchAnimationID ~= nil then
			AnimTable.SwitchAnim = v.ThirdPerson:WaitForChild("SwitchAnim")
			AnimTable.SwitchAnim = Humanoid:LoadAnimation(AnimTable.SwitchAnim)
		end
		if SettingModules[i].BatteryEnabled and SettingModules[i].OverheatAnimationID ~= nil then
			AnimTable.OverheatAnim = v.ThirdPerson:WaitForChild("OverheatAnim")
			AnimTable.OverheatAnim = Humanoid:LoadAnimation(AnimTable.OverheatAnim)
		end
		if SettingModules[i].MeleeAttackEnabled and SettingModules[i].MeleeAttackAnimationID ~= nil then
			AnimTable.MeleeAttackAnim = v.ThirdPerson:WaitForChild("MeleeAttackAnim")
			AnimTable.MeleeAttackAnim = Humanoid:LoadAnimation(AnimTable.MeleeAttackAnim)
		end
		if Module.AltFire and SettingModules[i].AltAnimationID ~= nil then
			AnimTable.AltAnim = v.ThirdPerson:WaitForChild("AltAnim")
			AnimTable.AltAnim = Humanoid:LoadAnimation(AnimTable.AltAnim)
		end
		table.insert(Animations, AnimTable)
	end

	local CurrentFireMode = 1
	local CurrentModule = SettingModules[CurrentFireMode]
	local CurrentVariables = Variables[CurrentFireMode]
	local CurrentAnimTable = Animations[CurrentFireMode]

	local CurrentAimFireAnim
	local CurrentAimFireAnimationSpeed
	if CurrentModule.AimAnimationsEnabled then
		CurrentAimFireAnim = CurrentAnimTable.AimFireAnim
		CurrentAimFireAnimationSpeed = CurrentModule.AimFireAnimationSpeed
	end
	local CurrentFireAnim = CurrentAnimTable.FireAnim
	local CurrentFireAnimationSpeed = CurrentModule.FireAnimationSpeed
	local CurrentShotgunPumpinAnim = CurrentAnimTable.ShotgunPumpinAnim
	local CurrentShotgunPumpinAnimationSpeed = CurrentModule.ShotgunPumpinSpeed

	--Viewmodel
	local CurrentVMAnimTable
	local CurrentVMShotgunPumpinAnim
	local CurrentVMShotgunPumpinAnimationSpeed

	local Spring = Utilities.Spring

	--scope

	--for the scope wiggle
	local Scope = Spring.spring.new(Vector3.new(0, 200, 0))
	Scope.s = CurrentModule.ScopeSwaySpeed
	Scope.d = CurrentModule.ScopeSwayDamper
	--for the knockback wiggle
	local Knockback = Spring.spring.new(Vector3.new())
	Knockback.s = CurrentModule.ScopeKnockbackSpeed
	Knockback.d = CurrentModule.ScopeKnockbackDamper

	--camera

	local CameraSpring = Spring.spring.new(Vector3.new())
	CameraSpring.s = CurrentModule.RecoilSpeed
	CameraSpring.d = CurrentModule.RecoilDamper

	local CrosshairColors = {
		Idle = Color3.fromRGB(255, 255, 255), -- White when idle
		Aiming = Color3.fromRGB(150, 150, 150), -- Gray when aiming at someone
		Hit = Color3.fromRGB(199, 2, 2), -- Red when shot someone
	}
	local CurrentCrosshairState = "Idle"
	local CrosshairHitResetTime = 0.15 -- Time in seconds for red color to show after hitting

	local function SetCrosshairColor(color)
		if GunGUI and GunGUI:FindFirstChild("Crosshair") then
			local CrossFrame = GunGUI.Crosshair:FindFirstChild("Main")
			if CrossFrame then
				local Center = CrossFrame:FindFirstChild("Center")
				if Center then
					Center.ImageColor3 = color
				end
			end
		end
	end

	local function IsAimingAtPlayer()
		if not GunGUI or not GunGUI:FindFirstChild("Crosshair") then
			return false
		end

		local crosshairPos = GunGUI.Crosshair.AbsolutePosition
		local InputRay = Camera:ScreenPointToRay(crosshairPos.X, crosshairPos.Y)
		local raycastParams = RaycastParams.new()
		raycastParams.FilterDescendantsInstances = { Camera, Tool, Character }
		raycastParams.FilterType = Enum.RaycastFilterType.Exclude

		local raycastResult = Workspace:Raycast(InputRay.Origin, InputRay.Direction * 1000, raycastParams)
		if raycastResult and raycastResult.Instance then
			local hitPart = raycastResult.Instance
			local model = hitPart:FindFirstAncestorOfClass("Model")
			if model then
				local humanoid = model:FindFirstChildOfClass("Humanoid")
				if humanoid and humanoid.Health > 0 then
					-- Make sure it's a damageable target
					if DamageModule.CanDamage(model, Character, CurrentModule.FriendlyFire) then
						return true
					end
				end
			end
		end
		return false
	end

	-- Dead body fling cooldown to prevent packet spam
	local LastFlingTime = 0
	local FLING_COOLDOWN = 0.1 -- Only send fling request every 0.1 seconds max

	-- Screen effect for hitting dead bodies (Da Bronx style)
	local DeadBodyHitEffect = nil
	local function PlayDeadBodyHitEffect()
		if not GunGUI then
			return
		end

		-- Create flash effect if it doesn't exist
		if not DeadBodyHitEffect or not DeadBodyHitEffect.Parent then
			DeadBodyHitEffect = Instance.new("Frame")
			DeadBodyHitEffect.Name = "DeadBodyHitEffect"
			DeadBodyHitEffect.Size = UDim2.fromScale(1, 1)
			DeadBodyHitEffect.Position = UDim2.new(0, 0, 0, 0)
			DeadBodyHitEffect.BackgroundTransparency = 1
			DeadBodyHitEffect.BorderSizePixel = 0
			DeadBodyHitEffect.ZIndex = 100
			DeadBodyHitEffect.Parent = GunGUI

			-- Create white flash overlay
			local flashOverlay = Instance.new("Frame")
			flashOverlay.Name = "FlashOverlay"
			flashOverlay.Size = UDim2.fromScale(1, 1)
			flashOverlay.Position = UDim2.new(0, 0, 0, 0)
			flashOverlay.BackgroundColor3 = Color3.fromRGB(255, 255, 255) -- Bright white
			flashOverlay.BackgroundTransparency = 1
			flashOverlay.BorderSizePixel = 0
			flashOverlay.ZIndex = 100
			flashOverlay.Parent = DeadBodyHitEffect
		end

		local flashOverlay = DeadBodyHitEffect:FindFirstChild("FlashOverlay")

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

	-- Function to check if we hit a dead body and fling it
	local function CheckAndFlingDeadBody(fireDirection)
		-- Check cooldown first to prevent spam
		local currentTime = tick()
		if currentTime - LastFlingTime < FLING_COOLDOWN then
			return
		end

		if not GunGUI or not GunGUI:FindFirstChild("Crosshair") then
			return
		end

		local crosshairPos = GunGUI.Crosshair.AbsolutePosition
		local InputRay = Camera:ScreenPointToRay(crosshairPos.X, crosshairPos.Y)
		local raycastParams = RaycastParams.new()
		raycastParams.FilterDescendantsInstances = { Camera, Tool, Character }
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
					LastFlingTime = currentTime
					local direction = fireDirection or InputRay.Direction
					local dir = direction.Unit
					-- Send the part reference directly (Roblox serializes this efficiently)
					FlingDeadBody:FireServer(hitPart, dir)

					-- Show red crosshair when hitting dead body
					SetCrosshairColor(CrosshairColors.Hit)
					CurrentCrosshairState = "Hit"
					task.delay(CrosshairHitResetTime, function()
						if CurrentCrosshairState == "Hit" then
							CurrentCrosshairState = "Idle"
						end
					end)

					-- Play screen effect
					PlayDeadBodyHitEffect()

					-- Play random shot sound effect on the dead body
					local shotSound = math.random(1, 2) == 1 and Tool:FindFirstChild("Shot1")
						or Tool:FindFirstChild("Shot2")
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

	local function Random2DDirection(Velocity, X, Y)
		return Vector2.new(X, Y) * (Velocity or 1)
	end

	local function AddressTableValue(v1, v2)
		if v1 ~= nil and CurrentModule.ChargedShotAdvanceEnabled then
			return (
				(CurrentVariables.ChargeLevel == 1 and v1.Level1)
				or (CurrentVariables.ChargeLevel == 2 and v1.Level2)
				or (CurrentVariables.ChargeLevel == 3 and v1.Level3)
				or v2
			)
		else
			return v2
		end
	end

	local function PopulateHumanoids(mdl)
		if mdl.ClassName == "Humanoid" then
			if DamageModule.CanDamage(mdl.Parent, Character, CurrentModule.FriendlyFire) then
				table.insert(Humanoids, mdl)
			end
		end
		for _, mdl2 in ipairs(mdl:GetChildren()) do
			PopulateHumanoids(mdl2)
		end
	end

	local function CastRay(StartPos, Direction, Length)
		local Hit, EndPos =
			Workspace:FindPartOnRayWithIgnoreList(Ray.new(StartPos, Direction * Length), { Camera, Tool, Character })
		if Hit then
			local FirePointObject = HandleToFire:FindFirstChild("GunFirePoint" .. CurrentFireMode)
			if FirePointObject ~= nil then
				local TipCFrame = FirePointObject.WorldCFrame
				local TipPos = TipCFrame.Position
				local TipDir = TipCFrame.LookVector
				local AmountToCheatBack = math.abs((HumanoidRootPart.Position - TipPos):Dot(TipDir)) + 1
				local GunRay = Ray.new(TipPos - TipDir.Unit * AmountToCheatBack, TipDir.Unit * AmountToCheatBack)
				local HitPart, HitPoint =
					Workspace:FindPartOnRayWithIgnoreList(GunRay, { Camera, Tool, Character }, false, true)
				if HitPart and math.abs((TipPos - HitPoint).Magnitude) > 0 then
					return CastRay(EndPos + (Direction * 0.01), Direction, Length - (StartPos - EndPos).Magnitude)
				end
			end
		end
		return EndPos
	end

	local function Get3DPosition(CurrentPosOnScreen)
		local InputRay = Camera:ScreenPointToRay(CurrentPosOnScreen.X, CurrentPosOnScreen.Y)
		local EndPos = InputRay.Origin + InputRay.Direction
		return CastRay(Camera.CFrame.p, (EndPos - Camera.CFrame.p).Unit, 5000)
	end

	local function WorldToScreen(Viewpoint)
		local ToObjectSpace = Camera.CFrame:pointToObjectSpace(Viewpoint)
		local FieldOfView = math.tan(math.rad(Camera.FieldOfView) / 2)
		return Vector2.new(
			Camera.ViewportSize.X
				* (
					0.5
					+ 0.5
						* (ToObjectSpace.X / ToObjectSpace.Z / -(Camera.ViewportSize.X / Camera.ViewportSize.Y * FieldOfView))
				),
			Camera.ViewportSize.Y * (0.5 + 0.5 * (ToObjectSpace.Y / ToObjectSpace.Z / FieldOfView))
		)
	end

	local function FindNearestEntity()
		Humanoids = {}
		PopulateHumanoids(Workspace)
		local MinOffset = nil
		local TargetModel = nil
		local TargetHumanoid = nil
		local TargetTorso = nil
		for _, v in ipairs(Humanoids) do
			local torso = v.Parent:FindFirstChild("HumanoidRootPart")
				or v.Parent:FindFirstChild("Torso")
				or v.Parent:FindFirstChild("UpperTorso")
			if v and torso then
				local Dist = (Character.Head.Position - torso.Position).Magnitude
				local MousePos = Get3DPosition(GunGUI.Crosshair.AbsolutePosition)
				local MouseDirection = (MousePos - Character.Head.Position).Unit
				local Offset = (((MouseDirection * Dist) + Character.Head.Position) - torso.Position).Magnitude
				if Offset < CurrentModule.LockOnRadius and (not MinOffset or Offset < MinOffset) and v.Health > 0 then
					if DamageModule.CanDamage(v.Parent, Character, CurrentModule.FriendlyFire) then
						TargetModel = v.Parent
						TargetHumanoid = v
						TargetTorso = torso
					end
				end
			end
		end
		return TargetModel, TargetHumanoid, TargetTorso
	end

	local function UpdateGUI()
		GunGUI.Frame.Mag.Fill:TweenSize(
			UDim2.fromScale(CurrentVariables.Mag / CurrentModule.AmmoPerMag, 1),
			Enum.EasingDirection.Out,
			Enum.EasingStyle.Quint,
			0.25,
			true
		)
		GunGUI.Frame.Ammo.Fill:TweenSize(
			UDim2.fromScale(CurrentVariables.Ammo / CurrentModule.MaxAmmo, 1),
			Enum.EasingDirection.Out,
			Enum.EasingStyle.Quint,
			0.25,
			true
		)
		GunGUI.Frame.Heat.Fill:TweenSize(
			UDim2.fromScale(CurrentVariables.Heat / CurrentModule.MaxHeat, 1),
			Enum.EasingDirection.Out,
			Enum.EasingStyle.Quint,
			0.25,
			true
		)
		GunGUI.Frame.Mag.Current.Text = CurrentVariables.Mag
		GunGUI.AmmoWidgetContainer.ContentLayer.CurrentAmmoTxt.Text = CurrentVariables.Mag
		GunGUI.Frame.Mag.Max.Text = CurrentModule.AmmoPerMag
		GunGUI.Frame.Mag.FireMode.Text = Tool.Name
		GunGUI.Frame.Ammo.Current.Text = CurrentVariables.Ammo
		GunGUI.Frame.Ammo.Max.Text = CurrentModule.MaxAmmo
		GunGUI.Frame.Heat.Current.Text = CurrentVariables.Heat
		GunGUI.Frame.Heat.Max.Text = CurrentModule.MaxHeat
		GunGUI.Frame.Heat.FireMode.Text = CurrentModule.FireModeTexts[CurrentVariables.FireMode]

		GunGUI.Frame.Mag.Current.Visible = not CommonVariables.Reloading
		GunGUI.Frame.Mag.Max.Visible = not CommonVariables.Reloading
		GunGUI.Frame.Mag.Frame.Visible = not CommonVariables.Reloading
		GunGUI.Frame.Mag.Reloading.Visible = CommonVariables.Reloading
		GunGUI.Frame.Mag.FireMode.Visible = CurrentModule.SelectiveFireEnabled

		GunGUI.Frame.Ammo.Current.Visible = not (CurrentVariables.Ammo <= 0)
		GunGUI.Frame.Ammo.Max.Visible = not (CurrentVariables.Ammo <= 0)
		GunGUI.Frame.Ammo.Frame.Visible = not (CurrentVariables.Ammo <= 0)
		GunGUI.Frame.Ammo.NoMoreAmmo.Visible = (CurrentVariables.Ammo <= 0)

		GunGUI.Frame.Heat.Visible = CurrentModule.BatteryEnabled
		GunGUI.Frame.Heat.Current.Visible = not CommonVariables.Overheated
		GunGUI.Frame.Heat.Max.Visible = not CommonVariables.Overheated
		GunGUI.Frame.Heat.Frame.Visible = not CommonVariables.Overheated
		GunGUI.Frame.Heat.Overheated.Visible = CommonVariables.Overheated
		GunGUI.Frame.Heat.FireMode.Visible = CurrentModule.SelectiveFireEnabled

		GunGUI.ChargeBar.Visible = (CurrentModule.ChargedShotAdvanceEnabled or CurrentModule.HoldAndReleaseEnabled)
		GunGUI.ChargeBar.Level1.Visible = not CurrentModule.HoldAndReleaseEnabled
		GunGUI.ChargeBar.Level2.Visible = not CurrentModule.HoldAndReleaseEnabled
		GunGUI.ChargeBar.Level1.Position =
			UDim2.fromScale(CurrentModule.Level1ChargingTime / CurrentModule.AdvancedChargingTime, 0.5)
		GunGUI.ChargeBar.Level2.Position =
			UDim2.fromScale(CurrentModule.Level2ChargingTime / CurrentModule.AdvancedChargingTime, 0.5)

		GunGUI.Frame.Mag.Visible = not CurrentModule.BatteryEnabled
		GunGUI.Frame.Ammo.Visible = CurrentModule.LimitedAmmoEnabled
		GunGUI.Frame.Heat.Visible = CurrentModule.BatteryEnabled

		GunGUI.MobileButtons.Visible = UserInputService.TouchEnabled --For mobile version
		local AimButton = GunGUI.MobileButtons.AimButton
		local HoldDownButton = GunGUI.MobileButtons.HoldDownButton
		local InspectButton = GunGUI.MobileButtons.InspectButton
		local ReloadButton = GunGUI.MobileButtons.ReloadButton
		local SwitchButton = GunGUI.MobileButtons.SwitchButton
		local MeleeButton = GunGUI.MobileButtons.MeleeButton
		local AltButton = GunGUI.MobileButtons.AltButton

		AimButton.Visible = CurrentModule.SniperEnabled or CurrentModule.IronsightEnabled
		HoldDownButton.Visible = CurrentModule.HoldDownEnabled
		InspectButton.Visible = CurrentModule.InspectAnimationEnabled
		SwitchButton.Visible = CurrentModule.SelectiveFireEnabled
		ReloadButton.Visible = not CurrentModule.BatteryEnabled
		MeleeButton.Visible = CurrentModule.MeleeAttackEnabled
		AltButton.Visible = Module.AltFire
	end

	local function RenderScope()
		Knockback.t = Knockback.t:Lerp(Vector3.new(), 0.2)
	end

	local function RenderMouse()
		local Delta = UserInputService:GetMouseDelta() / CurrentModule.ScopeSensitive
		local Offset = GunGUI.Scope.AbsoluteSize.X * 0.5

		if CommonVariables.Scoping and UserInputService.MouseEnabled and UserInputService.KeyboardEnabled then --For pc version
			GunGUI.Scope.Position =
				UDim2.fromOffset(Scope.p.X + (Knockback.p.Y * 1000), Scope.p.Y + (Knockback.p.X * 200))
			Scope.t = Vector3.new(Mouse.X - Offset - Delta.X, Mouse.Y - Offset - Delta.Y, 0)
		elseif
			CommonVariables.Scoping
			and UserInputService.TouchEnabled
			and not UserInputService.MouseEnabled
			and not UserInputService.KeyboardEnabled
		then --For mobile version, but in first-person view
			GunGUI.Scope.Position =
				UDim2.fromOffset(Scope.p.X + (Knockback.p.Y * 1000), Scope.p.Y + (Knockback.p.X * 200))
			Scope.t = Vector3.new(
				GunGUI.Crosshair.AbsolutePosition.X - Offset - Delta.X,
				GunGUI.Crosshair.AbsolutePosition.Y - Offset - Delta.Y,
				0
			)
		end

		GunGUI.Scope.Visible = CommonVariables.Scoping
		if not CommonVariables.Scoping then
			GunGUI.Crosshair.Main.Visible = true
			Scope.t = Vector3.new(600, 200, 0)
		else
			GunGUI.Crosshair.Main.Visible = false
		end

		if UserInputService.MouseEnabled and UserInputService.KeyboardEnabled then --For pc version
			if FakeCamera then
				CFAngles = CFrame.fromEulerAnglesXYZ(FakeCamera.Transform:ToEulerAnglesXYZ()) or CFrame.new()
				if (Camera.Focus.p - Camera.CoordinateFrame.p).Magnitude <= 1 then
					if CFAngles then
						local v = WorldToScreen((Camera.CFrame * CFAngles:Inverse() * CFrame.new(0, 0, -4)).Position)
						local v2 = Camera.ViewportSize / 2
						GunGUI.Crosshair.Position = (v - v2).Magnitude > 0.08 and UDim2.fromOffset(v.X, v.Y)
							or UDim2.fromOffset(v2.X, v2.Y)
					else
						GunGUI.Crosshair.Position = UDim2.fromOffset(Mouse.X, Mouse.Y)
					end
				else
					GunGUI.Crosshair.Position = UDim2.fromOffset(Mouse.X, Mouse.Y)
				end
			else
				GunGUI.Crosshair.Position = UDim2.fromOffset(Mouse.X, Mouse.Y)
			end
		elseif
			UserInputService.TouchEnabled
			and not UserInputService.MouseEnabled
			and not UserInputService.KeyboardEnabled
			and (Character.Head.Position - Camera.CoordinateFrame.p).Magnitude > 2
		then --For mobile version, but in third-person view
			GunGUI.Crosshair.Position = UDim2.fromScale(0.5, 0.2)
		elseif
			UserInputService.TouchEnabled
			and not UserInputService.MouseEnabled
			and not UserInputService.KeyboardEnabled
			and (Character.Head.Position - Camera.CoordinateFrame.p).Magnitude <= 2
		then --For mobile version, but in first-person view
			if FakeCamera then
				CFAngles = CFrame.fromEulerAnglesXYZ(FakeCamera.Transform:ToEulerAnglesXYZ()) or CFrame.new()
				if (Camera.Focus.p - Camera.CoordinateFrame.p).Magnitude <= 1 then
					if CFAngles then
						local v = WorldToScreen((Camera.CFrame * CFAngles:Inverse() * CFrame.new(0, 0, -4)).Position)
						local v2 = Camera.ViewportSize / 2
						GunGUI.Crosshair.Position = (v - v2).Magnitude > 0.08 and UDim2.fromOffset(v.X, v.Y)
							or UDim2.fromOffset(v2.X, v2.Y)
					else
						GunGUI.Crosshair.Position = UDim2.fromScale(0.5, 0.2)
					end
				else
					GunGUI.Crosshair.Position = UDim2.fromScale(0.5, 0.2)
				end
			else
				GunGUI.Crosshair.Position = UDim2.fromScale(0.5, 0.2)
			end
		end

		if
			AddressTableValue(CurrentModule.ChargeAlterTable.Homing, CurrentModule.Homing)
			and CurrentModule.LockOnOnHovering
			and not CurrentModule.HitscanMode
		then
			local TargetEntity, TargetHumanoid, TargetTorso = FindNearestEntity()
			if TargetEntity and TargetHumanoid and TargetTorso then
				LockedEntity = TargetEntity
			else
				LockedEntity = nil
			end
		end

		-- Update crosshair color based on state (only if not in hit state)
		if CurrentCrosshairState ~= "Hit" then
			if IsAimingAtPlayer() then
				SetCrosshairColor(CrosshairColors.Aiming)
				CurrentCrosshairState = "Aiming"
			else
				SetCrosshairColor(CrosshairColors.Idle)
				CurrentCrosshairState = "Idle"
			end
		end
	end

	local function RenderCam()
		Camera.CoordinateFrame = Camera.CoordinateFrame
			* CFrame.Angles(CameraSpring.p.X, CameraSpring.p.Y, CameraSpring.p.Z)
	end

	local function RenderRate(dt)
		CommonVariables.ElapsedTime = CommonVariables.ElapsedTime + dt
		if CommonVariables.ElapsedTime >= 1 then
			CommonVariables.ElapsedTime = 0
			CommonVariables.CurrentRate = CommonVariables.CurrentRate - CommonVariables.LastRate
			CommonVariables.LastRate = CommonVariables.CurrentRate
		end
	end

	local function RenderMotion()
		if Beam and Attach0 and Attach1 then
			local Position = Get3DPosition(GunGUI.Crosshair.AbsolutePosition)
			local cframe =
				CFrame.new(HandleToFire:FindFirstChild("GunFirePoint" .. CurrentFireMode).WorldPosition, Position)
			local direction = cframe.LookVector

			if direction then
				ProjectileMotion.UpdateProjectilePath(
					Beam,
					Attach0,
					Attach1,
					HandleToFire:FindFirstChild("GunFirePoint" .. CurrentFireMode).WorldPosition,
					direction * AddressTableValue(CurrentModule.ChargeAlterTable.BulletSpeed, CurrentModule.BulletSpeed),
					3,
					AddressTableValue(
						CurrentModule.ChargeAlterTable.BulletAcceleration,
						CurrentModule.BulletAcceleration
					)
				)
			end
		end
	end

	local function RenderCooldown(dt)
		CurrentVariables.ElapsedCooldownTime = CurrentVariables.ElapsedCooldownTime + dt
		if CurrentVariables.ElapsedCooldownTime >= CurrentModule.CooldownTime then
			CurrentVariables.ElapsedCooldownTime = 0
			if not CommonVariables.Down then
				if not CommonVariables.Overheated then
					if CommonVariables.CanBeCooledDown then
						if CurrentVariables.Heat > 0 then
							CurrentVariables.Heat =
								math.clamp(CurrentVariables.Heat - CurrentModule.CooldownRate, 0, CurrentModule.MaxHeat)
							UpdateGUI()
						end
					end
				end
			end
		end
	end

	local function RenderTwoDeeShell(dt)
		local TopbarOffset = (GunGUI.IgnoreGuiInset and GuiService:GetGuiInset()) or Vector2.new(0, 0)
		local Killzone = GunGUI.AbsoluteSize.Y + TopbarOffset.Y + 100
		local Drag = Module.Drag ^ dt
		for twoDeeShell, data in pairs(TwoDeeShells) do
			if twoDeeShell.Parent then
				data.Vel = (data.Vel * Drag) + Module.Gravity * dt
				data.Pos = data.Pos + data.Vel * dt
				data.RotVel = data.RotVel * Drag
				data.Rot = data.Rot + data.RotVel * dt
				twoDeeShell.Position = UDim2.new(0, data.Pos.X, 0, data.Pos.Y)
				twoDeeShell.Rotation = data.Rot
				if twoDeeShell.AbsolutePosition.Y > Killzone then
					twoDeeShell:Destroy()
					CommonVariables.TwoDeeShellCount = CommonVariables.TwoDeeShellCount - 1
					TwoDeeShells[twoDeeShell] = nil
				end
			else
				CommonVariables.TwoDeeShellCount = CommonVariables.TwoDeeShellCount - 1
				TwoDeeShells[twoDeeShell] = nil
			end
		end
	end

	-- Crosshair hit animation function
	-- Store original values and active tweens to prevent rapid fire bugs
	local CrosshairOriginalValues = {
		CenterSize = UDim2.fromOffset(7, 7),
		CenterRotation = 0,
		HR_Position = nil,
		HL_Position = nil,
		VD_Position = nil,
		VU_Position = nil,
	}
	local ActiveCrosshairTweens = {}

	local function CancelCrosshairTweens()
		for _, tween in pairs(ActiveCrosshairTweens) do
			if tween then
				tween:Cancel()
			end
		end
		ActiveCrosshairTweens = {}
	end

	local function PlayCrosshairHitAnimation(IsHeadshot)
		if not GunGUI or not GunGUI:FindFirstChild("Crosshair") then
			return
		end

		local CrosshairMain = GunGUI.Crosshair:FindFirstChild("Main")
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
		CancelCrosshairTweens()

		-- Cache original positions on first run
		if CrosshairOriginalValues.HR_Position == nil then
			if CrossParts.HR then
				CrosshairOriginalValues.HR_Position = CrossParts.HR.Position
			end
			if CrossParts.HL then
				CrosshairOriginalValues.HL_Position = CrossParts.HL.Position
			end
			if CrossParts.VD then
				CrosshairOriginalValues.VD_Position = CrossParts.VD.Position
			end
			if CrossParts.VU then
				CrosshairOriginalValues.VU_Position = CrossParts.VU.Position
			end
		end

		-- Animation settings
		local punchScale = IsHeadshot and 1.5 or 1.3
		local punchDuration = 0.06
		local returnDuration = 0.1
		local rotationAmount = IsHeadshot and 45 or 25

		-- Animate Center (punch scale + rotation)
		if Center then
			local originalSize = CrosshairOriginalValues.CenterSize
			local originalRotation = CrosshairOriginalValues.CenterRotation

			-- Reset to base first, then animate
			Center.Size = originalSize
			Center.Rotation = originalRotation

			-- Punch out animation
			local punchTween = TweenService:Create(
				Center,
				TweenInfo.new(punchDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{
					Size = UDim2.fromOffset(5 * punchScale, 5 * punchScale),
					Rotation = originalRotation + rotationAmount,
				}
			)
			table.insert(ActiveCrosshairTweens, punchTween)
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
			table.insert(ActiveCrosshairTweens, returnTween)

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
			if part and CrosshairOriginalValues[name .. "_Position"] then
				local originalPos = CrosshairOriginalValues[name .. "_Position"]
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
				table.insert(ActiveCrosshairTweens, spreadTween)
				spreadTween:Play()

				-- Return
				local returnTween = TweenService:Create(
					part,
					TweenInfo.new(returnDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
					{
						Position = originalPos,
					}
				)
				table.insert(ActiveCrosshairTweens, returnTween)

				spreadTween.Completed:Connect(function()
					returnTween:Play()
				end)
			end
		end
	end

	local function MarkHit(ClientModule, IsHeadshot)
		if ClientModule.HitmarkerEnabled then
			if IsHeadshot then
				GunGUI.Crosshair.Hitmarker.ImageColor3 = ClientModule.HitmarkerColorHS
				GunGUI.Crosshair.Hitmarker.ImageTransparency = 0
				TweenService:Create(
					GunGUI.Crosshair.Hitmarker,
					TweenInfo.new(ClientModule.HitmarkerFadeTimeHS, Enum.EasingStyle.Linear, Enum.EasingDirection.Out),
					{ ImageTransparency = 1 }
				):Play()
				local MarkerSound = GunGUI.Crosshair.MarkerSound:Clone()
				MarkerSound.SoundId = "rbxassetid://"
					.. ClientModule.HitmarkerSoundID[math.random(1, #ClientModule.HitmarkerSoundID)]
				MarkerSound.PlaybackSpeed = ClientModule.HitmarkerSoundPitchHS
				MarkerSound.Parent = Player.PlayerGui
				MarkerSound:Play()
				MarkerSound.Ended:Connect(function()
					MarkerSound:Destroy()
				end)
			else
				GunGUI.Crosshair.Hitmarker.ImageColor3 = ClientModule.HitmarkerColor
				GunGUI.Crosshair.Hitmarker.ImageTransparency = 0
				TweenService:Create(
					GunGUI.Crosshair.Hitmarker,
					TweenInfo.new(ClientModule.HitmarkerFadeTime, Enum.EasingStyle.Linear, Enum.EasingDirection.Out),
					{ ImageTransparency = 1 }
				):Play()
				local MarkerSound = GunGUI.Crosshair.MarkerSound:Clone()
				MarkerSound.SoundId = "rbxassetid://"
					.. ClientModule.HitmarkerSoundID[math.random(1, #ClientModule.HitmarkerSoundID)]
				MarkerSound.PlaybackSpeed = ClientModule.HitmarkerSoundPitch
				MarkerSound.Parent = Player.PlayerGui
				MarkerSound:Play()
				MarkerSound.Ended:Connect(function()
					MarkerSound:Destroy()
				end)
			end
		end

		-- Play cool crosshair hit animation
		PlayCrosshairHitAnimation(IsHeadshot)

		-- Set crosshair to red temporarily when hitting someone
		CurrentCrosshairState = "Hit"
		SetCrosshairColor(CrosshairColors.Hit)
		task.delay(CrosshairHitResetTime, function()
			if CurrentCrosshairState == "Hit" then
				CurrentCrosshairState = "Idle" -- Will be updated to correct state in next RenderMouse call
			end
		end)
		--end)
	end

	local function EjectShell(ShootingHandle)
		ShootingHandle = Tool.Handle
		if CurrentModule.BulletShellEnabled then
			if CurrentModule.BulletShellParticles then
				local function Spawner()
					for i, v in pairs(VisualEffects.ShellEjectEffect:GetChildren()) do
						if v.ClassName == "ParticleEmitter" then
							local Count = 1
							local Particle = v:Clone()
							Particle.Parent = ShootingHandle["ShellEjectParticlePoint" .. CurrentFireMode]
							if Particle:FindFirstChild("EmitCount") then
								Count = Particle.EmitCount.Value
							end
							Thread:Delay(0.01, function()
								Particle:Emit(Count)
								Debris:AddItem(Particle, Particle.Lifetime.Max)
							end)
						end
					end
				end
				Thread:Spawn(Spawner)
			end
			local Shell = Instance.new("Part")
			Shell.CFrame = ShootingHandle["ShellEjectPoint" .. CurrentFireMode].WorldCFrame
			Shell.Material = Enum.Material.Metal

			Shell.Size = CurrentModule.ShellSize
			Shell.CanCollide = false -- Disable collision to prevent flinging the player
			Shell.CanQuery = false -- Don't interfere with raycasts
			Shell.CanTouch = false -- Don't trigger touch events
			Shell.Name = "Shell"
			Shell.Velocity = ShootingHandle["ShellEjectPoint" .. CurrentFireMode].WorldCFrame.LookVector
				* CurrentModule.BulletShellVelocity
			Shell.RotVelocity = ShootingHandle["ShellEjectPoint" .. CurrentFireMode].WorldCFrame.LookVector
				* CurrentModule.BulletShellRotVelocity
			Shell.Parent = Camera
			local Shellmesh = Instance.new("SpecialMesh")
			Shellmesh.Scale = CurrentModule.ShellScale
			Shellmesh.MeshId = "rbxassetid://" .. CurrentModule.ShellMeshID
			Shellmesh.TextureId = "rbxassetid://" .. CurrentModule.ShellTextureID
			Shellmesh.MeshType = "FileMesh"
			Shellmesh.Parent = Shell
			Debris:AddItem(Shell, CurrentModule.DisappearTime)
		end
	end

	local function RecoilCamera()
		if CurrentModule.CameraRecoilingEnabled then
			local Recoil = AddressTableValue(CurrentModule.ChargeAlterTable.Recoil, CurrentModule.Recoil)
			local CurrentRecoil = Recoil * (CommonVariables.AimDown and 1 - CurrentModule.RecoilRedution or 1)
			local RecoilX = math.rad(
				CurrentRecoil
					* Math.Randomize2(CurrentModule.AngleX_Min, CurrentModule.AngleX_Max, CurrentModule.Accuracy)
			)
			local RecoilY = math.rad(
				CurrentRecoil
					* Math.Randomize2(CurrentModule.AngleY_Min, CurrentModule.AngleY_Max, CurrentModule.Accuracy)
			)
			local RecoilZ = math.rad(
				CurrentRecoil
					* Math.Randomize2(CurrentModule.AngleZ_Min, CurrentModule.AngleZ_Max, CurrentModule.Accuracy)
			)
			Knockback:Accelerate(
				Vector3.new(
					-RecoilX * CurrentModule.ScopeKnockbackMultiplier,
					-RecoilY * CurrentModule.ScopeKnockbackMultiplier,
					0
				)
			)
			CameraSpring:Accelerate(Vector3.new(RecoilX, RecoilY, RecoilZ))
			Thread:Wait(0.03)
			CameraSpring:Accelerate(Vector3.new(-RecoilX, -RecoilY, 0))
		end
	end

	local function SelfKnockback(p1, p2)
		local SelfKnockbackPower =
			AddressTableValue(CurrentModule.ChargeAlterTable.SelfKnockbackPower, CurrentModule.SelfKnockbackPower)
		local SelfKnockbackMultiplier = AddressTableValue(
			CurrentModule.ChargeAlterTable.SelfKnockbackMultiplier,
			CurrentModule.SelfKnockbackMultiplier
		)
		local SelfKnockbackRedution =
			AddressTableValue(CurrentModule.ChargeAlterTable.SelfKnockbackRedution, CurrentModule.SelfKnockbackRedution)
		local Power = Humanoid:GetState() ~= Enum.HumanoidStateType.Freefall
				and SelfKnockbackPower * SelfKnockbackMultiplier * (1 - SelfKnockbackRedution)
			or SelfKnockbackPower * SelfKnockbackMultiplier
		local VelocityMod = (p1 - p2).Unit
		local AirVelocity = Torso.Velocity
			- Vector3.new(0, Torso.Velocity.Y, 0)
			+ Vector3.new(VelocityMod.X, 0, VelocityMod.Z) * -Power
		local TorsoFly = Instance.new("BodyVelocity")
		TorsoFly.MaxForce = Vector3.new(math.huge, 0, math.huge)
		TorsoFly.Velocity = AirVelocity
		TorsoFly.Parent = Torso
		Torso.Velocity = Torso.Velocity + Vector3.new(0, VelocityMod.Y * 2, 0) * -Power
		Debris:AddItem(TorsoFly, 0.25)
	end

	local function CreateTwoDeeShell(ObjRot, Pos, Size, Vel, type, shockwave)
		local MaxedOut = CommonVariables.TwoDeeShellCount >= Module.MaxCount
		if MaxedOut and Module.RemoveOldAtMax and math.random() then
			-- This is the best method I can figure for removing a random item from a dictionary of known length
			local RemoveCoutndown = math.random(1, Module.MaxCount)
			for twoDeeShell, _ in pairs(TwoDeeShells) do
				RemoveCoutndown = RemoveCoutndown - 1
				if RemoveCoutndown <= 0 then
					twoDeeShell:Destroy()
					CommonVariables.TwoDeeShellCount = CommonVariables.TwoDeeShellCount - 1
					TwoDeeShells[twoDeeShell] = nil
					MaxedOut = CommonVariables.TwoDeeShellCount >= Module.MaxCount
					break
				end
			end
		end
		if not MaxedOut then
			CommonVariables.TwoDeeShellCount = CommonVariables.TwoDeeShellCount + 1
			local Rot = ObjRot --math.random() * 360

			local XCenter = Pos.X + (Size.X / 2)
			local YCenter = Pos.Y + (Size.Y / 2)
			local Data = {
				RotVel = (math.random() * 2 - 1) * Module.MaxRotationSpeed,
				Rot = Rot,
				Pos = Vector2.new(900, 900), --(Pos and Vector2.new(XCenter, YCenter) or Vector2.new(0, 0)) + TopbarOffset,   --(Pos and Vector2.new(XCenter, YCenter) or Vector2.new(0, 0)) + TopbarOffset
				Vel = Vel or Vector2.new(0, 0),
			}
			local TwoDeeShell = GunGUI.ShellSpawn --GunGUI.Shell.UIGridLayout.Shell
			if type == "bullet" then
				TwoDeeShell = GunGUI.ShellSpawn
			end
			local Clone = TwoDeeShell:Clone()
			Clone.ImageTransparency = 0
			Clone.Rotation = Rot
			TwoDeeShells[Clone] = Data
			--	Clone.Position = GUI.ShellSpawn.Position
			Clone.Parent = GunGUI
			-- if shockwave then
			-- 	Thread:Spawn(function()
			-- 		local ShockwaveClone = GunGUI.MagCartridge.UIGridLayout.Shockwave
			-- 			:Clone()
			-- 		local Degree = math.rad(math.random(360))
			-- 		ShockwaveClone.Position = UDim2.new(0, XCenter, 0, YCenter)
			-- 		ShockwaveClone.Rotation = math.deg(Degree)
			-- 		ShockwaveClone.Parent = GunGUI
			-- 		local Tween = TweenService:Create(
			-- 			ShockwaveClone,
			-- 			TweenInfo.new(0.25, Enum.EasingStyle.Linear, Enum.EasingDirection.Out),
			-- 			{ Size = UDim2.new(0, 50, 0, 50), ImageTransparency = 1 }
			-- 		)
			-- 		Tween:Play()
			-- 		Tween.Completed:Wait()
			-- 		ShockwaveClone:Destroy()
			-- 	end)
			-- end
		end
	end

	local function Fire(ShootingHandle, ShootingVMHandle, FireClientDirections, FireServerDirections)
		if CurrentModule.AimAnimationsEnabled and CommonVariables.AimDown == true then
			if CurrentAimFireAnim then
				CurrentAimFireAnim:Play(nil, nil, CurrentAimFireAnimationSpeed)
			end
		else
			if CurrentFireAnim then
				CurrentFireAnim:Play(nil, nil, CurrentFireAnimationSpeed)
			end
		end

		if CurrentAnimTable.MinigunRevUpAnim and CurrentAnimTable.MinigunRevUpAnim.IsPlaying then
			CurrentAnimTable.MinigunRevUpAnim:Stop()
		end

		local FireSounds = ShootingHandle[CurrentFireMode].FireSounds
		local VisualEffects2 = VisualEffects
		if VisualEffects:FindFirstChild(CurrentModule.ModuleName) then
			VisualEffects2 = VisualEffects[CurrentModule]
		end
		local MuzzleFolder = VisualEffects2.MuzzleEffect
		local HitEffectFolder = VisualEffects2.HitEffect
		local BloodEffectFolder = VisualEffects2.BloodEffect
		local ExplosionEffectFolder = VisualEffects2.ExplosionEffect
		local GoreEffectFolder = VisualEffects2.GoreEffect
		if CurrentModule.ChargedShotAdvanceEnabled then
			if CurrentVariables.ChargeLevel == 1 then
				if ShootingHandle[CurrentFireMode]:FindFirstChild("FireSoundsLvl1") then
					FireSounds = ShootingHandle[CurrentFireMode].FireSoundsLvl1
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
			elseif CurrentVariables.ChargeLevel == 2 then
				if ShootingHandle[CurrentFireMode]:FindFirstChild("FireSoundsLvl2") then
					FireSounds = ShootingHandle[CurrentFireMode].FireSoundsLvl2
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
			elseif CurrentVariables.ChargeLevel == 3 then
				if ShootingHandle[CurrentFireMode]:FindFirstChild("FireSoundsLvl3") then
					FireSounds = ShootingHandle[CurrentFireMode].FireSoundsLvl3
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
			AudioHandler:PlayAudio({
				SoundId = Track.SoundId,
				EmitterSize = Track.EmitterSize,
				MaxDistance = Track.MaxDistance,
				Volume = Track.Volume,
				Pitch = Track.PlaybackSpeed,
				Origin = ShootingHandle:FindFirstChild("GunMuzzlePoint" .. CurrentFireMode),
				Echo = CurrentModule.EchoEffect,
				Silenced = CurrentModule.SilenceEffect,
			}, {
				Enabled = CurrentModule.LowAmmo,
				CurrentAmmo = CurrentVariables.Mag,
				AmmoPerMag = CurrentModule.AmmoPerMag,
				SoundId = ShootingHandle[CurrentFireMode].LowAmmoSound.SoundId,
				EmitterSize = ShootingHandle[CurrentFireMode].LowAmmoSound.EmitterSize,
				MaxDistance = ShootingHandle[CurrentFireMode].LowAmmoSound.MaxDistance,
				Volume = ShootingHandle[CurrentFireMode].LowAmmoSound.Volume,
				Pitch = CurrentModule.RaisePitch and (math.max(math.abs(CurrentVariables.Mag / 10 - 1), 0.4))
					or ShootingHandle[CurrentFireMode].LowAmmoSound.PlaybackSpeed,
				Origin = ShootingHandle:FindFirstChild("GunMuzzlePoint" .. CurrentFireMode),
			}, true)
		end
		if IsAimingAtPlayer() then
			MarkHit(CurrentModule, false)
		end
		ProjectileHandler:SimulateProjectile(
			Tool,
			ShootingHandle,
			(Camera.Focus.p - Camera.CoordinateFrame.p).Magnitude <= 1 and ShootingVMHandle or nil,
			CurrentModule,
			FireClientDirections,
			FireServerDirections,
			ShootingHandle:FindFirstChild("GunFirePoint" .. CurrentFireMode),
			ShootingHandle:FindFirstChild("GunMuzzlePoint" .. CurrentFireMode),
			{
				MuzzleFolder = MuzzleFolder,
				HitEffectFolder = HitEffectFolder,
				BloodEffectFolder = BloodEffectFolder,
				ExplosionEffectFolder = ExplosionEffectFolder,
				GoreEffect = GoreEffectFolder,
				ChargeLevel = CurrentVariables.ChargeLevel,
				LockedEntity = LockedEntity,
			},
			true
		)

		-- Check if we hit a dead body and fling it
		if FireClientDirections and #FireClientDirections > 0 then
			CheckAndFlingDeadBody(FireClientDirections[1])
		else
			CheckAndFlingDeadBody(nil)
		end

		Thread:Spawn(RecoilCamera)
	end

	local function Overheat()
		if
			CommonVariables.ActuallyEquipped
			and CommonVariables.Enabled
			and not CommonVariables.Overheated
			and (CurrentVariables.Ammo > 0 or not CurrentModule.LimitedAmmoEnabled)
			and CurrentVariables.Heat >= CurrentModule.MaxHeat
		then
			CommonVariables.Overheated = true
			if CurrentAnimTable.InspectAnim and CurrentAnimTable.InspectAnim.IsPlaying then
				CurrentAnimTable.InspectAnim:Stop()
			end

			if CommonVariables.AimDown then
				TweenService:Create(
					Camera,
					TweenInfo.new(
						CurrentModule.TweenLengthNAD,
						CurrentModule.EasingStyleNAD,
						CurrentModule.EasingDirectionNAD
					),
					{ FieldOfView = 70 }
				):Play()
				--SetCrossScale(1)
				if
					CurrentModule.AimAnimationsEnabled
					and CurrentAnimTable.AimIdleAnim
					and CurrentAnimTable.AimIdleAnim.IsPlaying
				then
					CurrentAnimTable.AimIdleAnim:Stop()

					if CurrentAnimTable.IdleAnim then
						CurrentAnimTable.IdleAnim:Play(nil, nil, CurrentModule.IdleAnimationSpeed)
					end
				end

				CommonVariables.Scoping = false
				Player.CameraMode = Enum.CameraMode.Classic
				UserInputService.MouseDeltaSensitivity = CommonVariables.InitialSensitivity
				CommonVariables.AimDown = false
			end
			UpdateGUI()
			if CommonVariables.ActuallyEquipped then
				if CurrentAnimTable.OverheatAnim then
					CurrentAnimTable.OverheatAnim:Play(nil, nil, CurrentModule.OverheatAnimationSpeed)
				end

				Handle[CurrentFireMode].OverheatSound:Play()
			end
			--Thread:Wait(CurrentModule.OverheatTime)
			for _ = 1, CurrentModule.MaxHeat do
				Thread:Wait(CurrentModule.OverheatTime / CurrentModule.MaxHeat)
				CurrentVariables.Heat = CurrentVariables.Heat - 1
				UpdateGUI()
				if CurrentVariables.Heat == 0 then
					CommonVariables.Overheated = false
					break
				end
			end
			CommonVariables.Overheated = false
			UpdateGUI()
		end
	end

	local function updateServerChangeMagAndAmmo()
		ChangeMagAndAmmo:FireServer(CurrentFireMode, CurrentVariables.Mag, CurrentVariables.Ammo, CurrentVariables.Heat)
	end

	local function Reload()
		if
			CommonVariables.ActuallyEquipped
			and CommonVariables.Enabled
			and not CommonVariables.Reloading
			and (CurrentVariables.Ammo > 0 or not CurrentModule.LimitedAmmoEnabled)
			and CurrentVariables.Mag < CurrentModule.AmmoPerMag
		then
			CommonVariables.Reloading = true

			if CurrentModule.MagDrop == true then
				Tool.Magdrop:FireServer()
			end

			if CurrentAnimTable.InspectAnim and CurrentAnimTable.InspectAnim.IsPlaying then
				CurrentAnimTable.InspectAnim:Stop()
			end

			if not CurrentModule.KeepAimingOnReloading then
				if CommonVariables.AimDown then
					TweenService:Create(
						Camera,
						TweenInfo.new(
							CurrentModule.TweenLengthNAD,
							CurrentModule.EasingStyleNAD,
							CurrentModule.EasingDirectionNAD
						),
						{ FieldOfView = 70 }
					):Play()
					if
						CurrentModule.AimAnimationsEnabled
						and CurrentAnimTable.AimIdleAnim
						and CurrentAnimTable.AimIdleAnim.IsPlaying
					then
						CurrentAnimTable.AimIdleAnim:Stop()
						if CurrentAnimTable.IdleAnim then
							CurrentAnimTable.IdleAnim:Play(nil, nil, CurrentModule.IdleAnimationSpeed)
						end
					end

					CommonVariables.Scoping = false
					Player.CameraMode = Enum.CameraMode.Classic
					UserInputService.MouseDeltaSensitivity = CommonVariables.InitialSensitivity
					CommonVariables.AimDown = false
				end
			end
			UpdateGUI()
			if CurrentModule.ShotgunReload then
				if CurrentModule.PreShotgunReload then
					if CommonVariables.ActuallyEquipped then
						if CurrentAnimTable.PreShotgunReloadAnim then
							CurrentAnimTable.PreShotgunReloadAnim:Play(
								nil,
								nil,
								CurrentModule.PreShotgunReloadAnimationSpeed
							)
						end

						Handle[CurrentFireMode].PreReloadSound:Play()
					end
					local StartTime = os.clock()
					repeat
						Thread:Wait()
						if not CommonVariables.ActuallyEquipped then
							break
						end
					until (os.clock() - StartTime) >= CurrentModule.PreShotgunReloadSpeed
				end
				for _ = 1, (CurrentModule.AmmoPerMag - CurrentVariables.Mag) do
					if CommonVariables.ActuallyEquipped then
						if CurrentAnimTable.ShotgunClipinAnim then
							CurrentAnimTable.ShotgunClipinAnim:Play(nil, nil, CurrentModule.ShotgunClipinAnimationSpeed)
						end

						Handle[CurrentFireMode].ShotgunClipin:Play()
					end
					local StartTime = os.clock()
					repeat
						Thread:Wait()
						if not CommonVariables.ActuallyEquipped then
							break
						end
					until (os.clock() - StartTime) >= CurrentModule.ShellClipinSpeed
					if CurrentVariables.Mag < CurrentModule.AmmoPerMag then
						if CommonVariables.ActuallyEquipped then
							if CurrentModule.LimitedAmmoEnabled then
								if CurrentVariables.Ammo > 0 then
									CurrentVariables.Mag = CurrentVariables.Mag + 1
									CurrentVariables.Ammo = CurrentVariables.Ammo - 1
									updateServerChangeMagAndAmmo()
									-- if Module.MagCartridge and not CurrentModule.BatteryEnabled then
									-- 	for i = 1, CurrentVariables.Mag do
									-- 		GunGUI.MagCartridge[i].Visible = true
									-- 	end
									-- end
									UpdateGUI()
								end
							else
								CurrentVariables.Mag = CurrentVariables.Mag + 1
								CurrentVariables.Ammo = CurrentVariables.Ammo - 1
								updateServerChangeMagAndAmmo()
								-- if Module.MagCartridge and not CurrentModule.BatteryEnabled then
								-- 	for i = 1, CurrentVariables.Mag do
								-- 		GunGUI.MagCartridge[i].Visible = true
								-- 	end
								-- end
								UpdateGUI()
							end
						end
					else
						break
					end
					if CurrentModule.LimitedAmmoEnabled then
						if (not CommonVariables.ActuallyEquipped) or (CurrentVariables.Ammo <= 0) then
							break
						end
					else
						if not CommonVariables.ActuallyEquipped then
							break
						end
					end
				end
			end
			if CommonVariables.ActuallyEquipped then
				if CurrentModule.TacticalReloadAnimationEnabled then
					if CurrentVariables.Mag > 0 then
						if CurrentAnimTable.TacticalReloadAnim then
							CurrentAnimTable.TacticalReloadAnim:Play(
								nil,
								nil,
								CurrentModule.TacticalReloadAnimationSpeed
							)
						end

						Handle[CurrentFireMode].TacticalReloadSound:Play()
					else
						if CurrentAnimTable.ReloadAnim then
							CurrentAnimTable.ReloadAnim:Play(nil, nil, CurrentModule.ReloadAnimationSpeed)
						end

						Handle[CurrentFireMode].ReloadSound:Play()
					end
				else
					if CurrentAnimTable.ReloadAnim then
						CurrentAnimTable.ReloadAnim:Play(nil, nil, CurrentModule.ReloadAnimationSpeed)
					end

					Handle[CurrentFireMode].ReloadSound:Play()
				end
			end
			local ReloadTime = (CurrentVariables.Mag > 0 and CurrentModule.TacticalReloadAnimationEnabled)
					and CurrentModule.TacticalReloadTime
				or CurrentModule.ReloadTime
			local StartTime = os.clock()
			repeat
				Thread:Wait()
				if not CommonVariables.ActuallyEquipped then
					break
				end
			until (os.clock() - StartTime) >= ReloadTime
			if CommonVariables.ActuallyEquipped then
				if not CurrentModule.ShotgunReload then
					-- if Module.MagCartridge and Module.DropAllRemainingBullets and not CurrentModule.BatteryEnabled then
					-- 	for i = 1, CurrentVariables.Mag do
					-- 		local Bullet = GunGUI.MagCartridge:FindFirstChild(i)
					-- 		local Vel = Random2DDirection(
					-- 			Module.DropVelocity,
					-- 			math.random(Module.DropXMin, Module.DropXMax),
					-- 			math.random(Module.DropYMin, Module.DropYMax)
					-- 		) * (math.random() ^ 0.5)
					-- 		CreateTwoDeeShell(
					-- 			Bullet.Rotation,
					-- 			Bullet.AbsolutePosition,
					-- 			Bullet.AbsoluteSize,
					-- 			Vel,
					-- 			"bullet"
					-- 		)
					-- 	end
					-- end
					if CurrentModule.LimitedAmmoEnabled then
						local ammoToUse =
							math.min(CurrentModule.AmmoPerMag - CurrentVariables.Mag, CurrentVariables.Ammo)
						CurrentVariables.Mag = CurrentVariables.Mag + ammoToUse
						CurrentVariables.Ammo = CurrentVariables.Ammo - ammoToUse
					else
						CurrentVariables.Mag = CurrentModule.AmmoPerMag
					end
					updateServerChangeMagAndAmmo()
				end
			end
			CommonVariables.Reloading = false
			Empty:Stop()
			UpdateGUI()
		end
	end

	local function OnTooglingAiming()
		if
			not CommonVariables.Reloading
			and not CommonVariables.Overheated
			and not CommonVariables.HoldDown
			and not CommonVariables.Alting
			and not CommonVariables.AimDown
			and CommonVariables.ActuallyEquipped
			and CurrentModule.IronsightEnabled
			and (Camera.Focus.p - Camera.CoordinateFrame.p).Magnitude <= 1
		then
			if not CurrentModule.KeepAimingOnReloading then
				if CommonVariables.Reloading or CommonVariables.Overheated then
					return
				end
			end
			TweenService:Create(
				Camera,
				TweenInfo.new(CurrentModule.TweenLength, CurrentModule.EasingStyle, CurrentModule.EasingDirection),
				{ FieldOfView = CurrentModule.FieldOfViewIS }
			):Play()
			--SetCrossScale(CurrentModule.CrossScaleIS)
			if CurrentAnimTable.InspectAnim and CurrentAnimTable.InspectAnim.IsPlaying then
				CurrentAnimTable.InspectAnim:Stop()
			end

			if
				CurrentModule.AimAnimationsEnabled
				and CurrentAnimTable.IdleAnim
				and CurrentAnimTable.IdleAnim.IsPlaying
			then
				CurrentAnimTable.IdleAnim:Stop()
				if CurrentAnimTable.AimIdleAnim then
					CurrentAnimTable.AimIdleAnim:Play(nil, nil, CurrentModule.AimIdleAnimationSpeed)
				end
			end

			Player.CameraMode = Enum.CameraMode.LockFirstPerson
			UserInputService.MouseDeltaSensitivity = CommonVariables.InitialSensitivity * CurrentModule.MouseSensitiveIS
			CommonVariables.AimDown = true
		elseif
			not CommonVariables.Reloading
			and not CommonVariables.Overheated
			and not CommonVariables.HoldDown
			and not CommonVariables.Alting
			and CommonVariables.AimDown
			and CommonVariables.ActuallyEquipped
			and CurrentModule.SniperEnabled
			and (Camera.Focus.p - Camera.CoordinateFrame.p).Magnitude <= 1
		then
			if not CurrentModule.KeepAimingOnReloading then
				if CommonVariables.Reloading or CommonVariables.Overheated then
					return
				end
			end
			TweenService:Create(
				Camera,
				TweenInfo.new(CurrentModule.TweenLength, CurrentModule.EasingStyle, CurrentModule.EasingDirection),
				{ FieldOfView = CurrentModule.FieldOfViewS }
			):Play()
			if CurrentAnimTable.InspectAnim and CurrentAnimTable.InspectAnim.IsPlaying then
				CurrentAnimTable.InspectAnim:Stop()
			end

			if
				CurrentModule.AimAnimationsEnabled
				and CurrentAnimTable.IdleAnim
				and CurrentAnimTable.IdleAnim.IsPlaying
			then
				CurrentAnimTable.IdleAnim:Stop()
				if CurrentAnimTable.AimIdleAnim then
					CurrentAnimTable.AimIdleAnim:Play(nil, nil, CurrentModule.AimIdleAnimationSpeed)
				end
			end

			CommonVariables.AimDown = true
			local StartTime = os.clock()
			repeat
				Thread:Wait()
				if not (CommonVariables.ActuallyEquipped or CommonVariables.AimDown) then
					break
				end
			until (os.clock() - StartTime) >= CurrentModule.ScopeDelay
			if CommonVariables.ActuallyEquipped and CommonVariables.AimDown then
				local ZoomSound = GunGUI.Scope.ZoomSound:Clone()
				ZoomSound.Parent = Player.PlayerGui
				ZoomSound:Play()
				ZoomSound.Ended:Connect(function()
					ZoomSound:Destroy()
				end)
				Player.CameraMode = Enum.CameraMode.LockFirstPerson
				UserInputService.MouseDeltaSensitivity = CommonVariables.InitialSensitivity
					* CurrentModule.MouseSensitiveS
				CommonVariables.Scoping = true
			end
		else
			TweenService:Create(
				Camera,
				TweenInfo.new(
					CurrentModule.TweenLengthNAD,
					CurrentModule.EasingStyleNAD,
					CurrentModule.EasingDirectionNAD
				),
				{ FieldOfView = 70 }
			):Play()
			if
				CurrentModule.AimAnimationsEnabled
				and CurrentAnimTable.AimIdleAnim
				and CurrentAnimTable.AimIdleAnim.IsPlaying
			then
				CurrentAnimTable.AimIdleAnim:Stop()
				if CurrentAnimTable.IdleAnim then
					CurrentAnimTable.IdleAnim:Play(nil, nil, CurrentModule.IdleAnimationSpeed)
				end
			end

			CommonVariables.Scoping = false
			Player.CameraMode = Enum.CameraMode.Classic
			UserInputService.MouseDeltaSensitivity = CommonVariables.InitialSensitivity
			CommonVariables.AimDown = false
		end
	end

	local function OnHoldingDown()
		if CurrentModule.HoldDownEnabled then
			if
				not CommonVariables.Reloading
				and not CommonVariables.Overheated
				and CommonVariables.ActuallyEquipped
				and CommonVariables.Enabled
			then
				if not CommonVariables.HoldDown then
					CommonVariables.HoldDown = true
					if CurrentAnimTable.AimIdleAnim and CurrentAnimTable.AimIdleAnim.IsPlaying then
						CurrentAnimTable.AimIdleAnim:Stop()
					end
					if CurrentAnimTable.IdleAnim and CurrentAnimTable.IdleAnim.IsPlaying then
						CurrentAnimTable.IdleAnim:Stop()
					end

					if CurrentAnimTable.HoldDownAnim then
						CurrentAnimTable.HoldDownAnim:Play(nil, nil, CurrentModule.HoldDownAnimationSpeed)
					end

					if CommonVariables.AimDown then
						TweenService:Create(
							Camera,
							TweenInfo.new(
								CurrentModule.TweenLengthNAD,
								CurrentModule.EasingStyleNAD,
								CurrentModule.EasingDirectionNAD
							),
							{ FieldOfView = 70 }
						):Play()
						--SetCrossScale(1)

						CommonVariables.Scoping = false
						Player.CameraMode = Enum.CameraMode.Classic
						UserInputService.MouseDeltaSensitivity = CommonVariables.InitialSensitivity
						CommonVariables.AimDown = false
					end
				else
					CommonVariables.HoldDown = false
					if CurrentAnimTable.IdleAnim then
						CurrentAnimTable.IdleAnim:Play(nil, nil, CurrentModule.IdleAnimationSpeed)
					end

					if CurrentAnimTable.HoldDownAnim and CurrentAnimTable.HoldDownAnim.IsPlaying then
						CurrentAnimTable.HoldDownAnim:Stop()
					end
				end
			end
		end
	end

	local function OnInspecting()
		if
			not CommonVariables.Reloading
			and not CommonVariables.Overheated
			and CommonVariables.ActuallyEquipped
			and CommonVariables.Enabled
			and not CommonVariables.AimDown
			and not CommonVariables.Inspecting
			and not CommonVariables.Switching
			and not CommonVariables.Alting
			and CurrentModule.InspectAnimationEnabled
		then
			CommonVariables.Inspecting = true
			if CurrentAnimTable.InspectAnim then
				CurrentAnimTable.InspectAnim:Play(nil, nil, CurrentModule.InspectAnimationSpeed)
			end

			local StartTime = os.clock()
			repeat
				Thread:Wait()
				if
					not CommonVariables.ActuallyEquipped
					or CommonVariables.Reloading
					or CommonVariables.Overheated
					or not CommonVariables.Enabled
					or CommonVariables.AimDown
					or CommonVariables.Switching
				then
					break
				end
			until (os.clock() - StartTime) >= CurrentAnimTable.InspectAnim.Length / CurrentAnimTable.InspectAnim.Speed
			CommonVariables.Inspecting = false
		end
	end

	local function OnSwitching()
		if
			not CommonVariables.Reloading
			and not CommonVariables.Overheated
			and CommonVariables.ActuallyEquipped
			and CommonVariables.Enabled
			and not CommonVariables.Inspecting
			and not CommonVariables.Switching
			and not CommonVariables.Alting
			and CurrentModule.SelectiveFireEnabled
		then
			CommonVariables.Switching = true
			if CurrentAnimTable.SwitchAnim then
				CurrentAnimTable.SwitchAnim:Play(nil, nil, CurrentModule.SwitchAnimationSpeed)
			end

			local StartTime = os.clock()
			repeat
				Thread:Wait()
				if
					not CommonVariables.ActuallyEquipped
					or CommonVariables.Reloading
					or CommonVariables.Overheated
					or not CommonVariables.Enabled
					or CommonVariables.Inspecting
				then
					break
				end
			until (os.clock() - StartTime) >= CurrentModule.SwitchTime
			CommonVariables.Switching = false
			if
				CommonVariables.ActuallyEquipped
				and not CommonVariables.Reloading
				and not CommonVariables.Overheated
				and CommonVariables.Enabled
				and not CommonVariables.Inspecting
			then
				Handle[CurrentFireMode].SwitchSound:Play()
				CurrentVariables.FireMode = CurrentVariables.FireMode % #CurrentVariables.FireModes + 1
				UpdateGUI()
			end
		end
	end

	local function OnAlting()
		if Module.AltFire and #Setting:GetChildren() > 1 then
			if
				not CommonVariables.Reloading
				and not CommonVariables.Overheated
				and CommonVariables.ActuallyEquipped
				and CommonVariables.Enabled
				and not CommonVariables.Inspecting
				and not CommonVariables.Alting
				and not CommonVariables.Switching
			then
				CommonVariables.Alting = true
				if CurrentAnimTable.InspectAnim and CurrentAnimTable.InspectAnim.IsPlaying then
					CurrentAnimTable.InspectAnim:Stop()
				end

				if CommonVariables.AimDown then
					TweenService:Create(
						Camera,
						TweenInfo.new(
							CurrentModule.TweenLengthNAD,
							CurrentModule.EasingStyleNAD,
							CurrentModule.EasingDirectionNAD
						),
						{ FieldOfView = 70 }
					):Play()
					--SetCrossScale(1)
					if
						CurrentModule.AimAnimationsEnabled
						and CurrentAnimTable.AimIdleAnim
						and CurrentAnimTable.AimIdleAnim.IsPlaying
					then
						CurrentAnimTable.AimIdleAnim:Stop()
						if CurrentAnimTable.IdleAnim then
							CurrentAnimTable.IdleAnim:Play(nil, nil, CurrentModule.IdleAnimationSpeed)
						end
					end

					CommonVariables.Scoping = false
					Player.CameraMode = Enum.CameraMode.Classic
					UserInputService.MouseDeltaSensitivity = CommonVariables.InitialSensitivity
					CommonVariables.AimDown = false
				end
				if CurrentAnimTable.AltAnim then
					CurrentAnimTable.AltAnim:Play(nil, nil, CurrentModule.SwitchAnimationSpeed)
				end
				Handle[CurrentFireMode].AltSound:Play()
				local StartTime = os.clock()
				repeat
					Thread:Wait()
					if
						not CommonVariables.ActuallyEquipped
						or CommonVariables.Reloading
						or CommonVariables.Overheated
						or not CommonVariables.Enabled
						or CommonVariables.Inspecting
					then
						break
					end
				until (os.clock() - StartTime) >= CurrentModule.SwitchTime
				CommonVariables.Alting = false
				if
					CommonVariables.ActuallyEquipped
					and not CommonVariables.Reloading
					and not CommonVariables.Overheated
					and CommonVariables.Enabled
					and not CommonVariables.Inspecting
				then
					LockedEntity = nil
					if Beam then
						Beam:Destroy()
						Beam = nil
					end
					if Attach0 then
						Attach0:Destroy()
						Attach0 = nil
					end
					if Attach1 then
						Attach1:Destroy()
						Attach1 = nil
					end
					for _, a in pairs(CurrentAnimTable) do
						if
							a --[[and not a.Animation.Name == "AltAnim"]]
						then
							if a.IsPlaying then
								a:Stop()
							end
						end
					end

					HandleToFire = Handle

					CommonVariables.CurrentRate = 0
					CommonVariables.LastRate = 0
					CommonVariables.ElapsedTime = 0

					CurrentFireMode = CurrentFireMode % #Setting:GetChildren() + 1
					CurrentModule = SettingModules[CurrentFireMode]
					CurrentVariables = Variables[CurrentFireMode]
					CurrentAnimTable = Animations[CurrentFireMode]

					if CurrentModule.AimAnimationsEnabled then
						CurrentAimFireAnim = CurrentAnimTable.AimFireAnim
						CurrentAimFireAnimationSpeed = CurrentModule.AimFireAnimationSpeed
					end
					CurrentFireAnim = CurrentAnimTable.FireAnim
					CurrentFireAnimationSpeed = CurrentModule.FireAnimationSpeed
					CurrentShotgunPumpinAnim = CurrentAnimTable.ShotgunPumpinAnim
					CurrentShotgunPumpinAnimationSpeed = CurrentModule.ShotgunPumpinSpeed

					-- if
					-- 	Module.MagCartridge
					-- 	and not CurrentModule.BatteryEnabled
					-- 	and CurrentModule.AmmoPerMag ~= math.huge
					-- then
					-- 	for _, v in pairs(GunGUI.MagCartridge:GetChildren()) do
					-- 		if not v:IsA("UIGridLayout") then
					-- 			v:Destroy()
					-- 		end
					-- 	end
					-- 	for i = 1, CurrentModule.AmmoPerMag do
					-- 		local Bullet = GunGUI.MagCartridge.UIGridLayout.Template:Clone()
					-- 		Bullet.Name = i
					-- 		Bullet.LayoutOrder = i
					-- 		if i > CurrentVariables.Mag then
					-- 			Bullet.Visible = false
					-- 		end
					-- 		Bullet.Parent = GunGUI.MagCartridge
					-- 	end
					-- end

					SmokeTrail:StopEmission()

					if CurrentModule.ProjectileMotion then
						local VisualEffects2 = VisualEffects
						if VisualEffects:FindFirstChild(CurrentModule.ModuleName) then
							VisualEffects2 = VisualEffects[CurrentModule]
						end
						Beam, Attach0, Attach1 = ProjectileMotion.ShowProjectilePath(
							VisualEffects2.MotionBeam,
							HandleToFire:FindFirstChild("GunFirePoint" .. CurrentFireMode).WorldPosition,
							Vector3.new(),
							3,
							AddressTableValue(
								CurrentModule.ChargeAlterTable.BulletAcceleration,
								CurrentModule.BulletAcceleration
							)
						)
					end

					if CurrentAnimTable.IdleAnim then
						CurrentAnimTable.IdleAnim:Play(nil, nil, CurrentModule.IdleAnimationSpeed)
					end

					if CurrentModule.AmmoPerMag ~= math.huge and CurrentModule.MaxHeat ~= math.huge then
						GunGUI.Frame.Visible = true
					end

					UpdateGUI()

					if
						CommonVariables.ActuallyEquipped
						and Module.AutoReload
						and not CommonVariables.Reloading
						and (CurrentVariables.Ammo > 0 or not CurrentModule.LimitedAmmoEnabled)
						and CurrentVariables.Mag <= 0
					then
						Reload()
					end
				end
			end
		end
	end
	local function chargeEffect()
		CommonVariables.CanBeCooledDown = false
		CommonVariables.Enabled = false
		if CurrentAnimTable.InspectAnim and CurrentAnimTable.InspectAnim.IsPlaying then
			CurrentAnimTable.InspectAnim:Stop()
		end

		if CurrentModule.AimAnimationsEnabled and CommonVariables.AimDown then
			if CurrentAnimTable.AimChargingAnim and not CurrentAnimTable.AimChargingAnim.IsPlaying then
				CurrentAnimTable.AimChargingAnim:Play(nil, nil, CurrentModule.AimChargingAnimationSpeed)
			end
		else
			if CurrentAnimTable.ChargingAnim and not CurrentAnimTable.ChargingAnim.IsPlaying then
				CurrentAnimTable.ChargingAnim:Play(nil, nil, CurrentModule.ChargingAnimationSpeed)
			end
		end
		local ChargingSound = HandleToFire[CurrentFireMode]:FindFirstChild("ChargingSound")
		local StartTime = os.clock()
		while true do
			local DeltaTime = os.clock() - StartTime
			if CurrentVariables.ChargeLevel == 0 and DeltaTime >= CurrentModule.Level1ChargingTime then
				CurrentVariables.ChargeLevel = 1
				GunGUI.ChargeBar.ChargeLevel1:Play()
			elseif CurrentVariables.ChargeLevel == 1 and DeltaTime >= CurrentModule.Level2ChargingTime then
				CurrentVariables.ChargeLevel = 2
				GunGUI.ChargeBar.ChargeLevel2:Play()
			elseif CurrentVariables.ChargeLevel == 2 and DeltaTime >= CurrentModule.AdvancedChargingTime then
				CurrentVariables.ChargeLevel = 3
				GunGUI.ChargeBar.ChargeLevel3:Play()
				GunGUI.ChargeBar.Shine.UIGradient.Offset = Vector2.new(-1, 0)
				TweenService:Create(
					GunGUI.ChargeBar.Shine.UIGradient,
					TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
					{ Offset = Vector2.new(1, 0) }
				):Play()
			end
			local ChargePercent = math.min(DeltaTime / CurrentModule.AdvancedChargingTime, 1)
			if ChargePercent < 0.5 then --Fade from red to yellow then to green
				GunGUI.ChargeBar.Fill.BackgroundColor3 = Color3.new(1, ChargePercent * 2, 0)
			else
				GunGUI.ChargeBar.Fill.BackgroundColor3 = Color3.new(1 - ((ChargePercent - 0.5) / 0.5), 1, 0)
			end
			GunGUI.ChargeBar.Fill.Size = UDim2.new(ChargePercent, 0, 1, 0)
			if ChargingSound then
				if not ChargingSound.Playing then
					ChargingSound:Play()
				end
				if CurrentModule.ChargingSoundIncreasePitch then
					ChargingSound.PlaybackSpeed = CurrentModule.ChargingSoundPitchRange[1]
						+ (
							ChargePercent
							* (CurrentModule.ChargingSoundPitchRange[2] - CurrentModule.ChargingSoundPitchRange[1])
						)
				end
			end
			Thread:Wait()
			if not CommonVariables.ActuallyEquipped or not CommonVariables.Charging then
				break
			end
		end
		if CurrentAnimTable.AimChargingAnim and CurrentAnimTable.AimChargingAnim.IsPlaying then
			CurrentAnimTable.AimChargingAnim:Stop(0)
		end
		if CurrentAnimTable.ChargingAnim and CurrentAnimTable.ChargingAnim.IsPlaying then
			CurrentAnimTable.ChargingAnim:Stop(0)
		end

		GunGUI.ChargeBar.Fill.Size = UDim2.new(0, 0, 1, 0)
		if ChargingSound then
			if ChargingSound.Playing then
				ChargingSound:Stop()
			end
			if CurrentModule.ChargingSoundIncreasePitch then
				ChargingSound.PlaybackSpeed = CurrentModule.ChargingSoundPitchRange[1]
			end
		end
		if not CommonVariables.ActuallyEquipped then
			CurrentVariables.ChargeLevel = 0
			CommonVariables.Enabled = true
		end
	end

	local function shotShellEjectSpawnLoop(): boolean
		if not CommonVariables.ActuallyEquipped then
			return false
		end
		if not CurrentModule.ShotgunPump then
			Thread:Spawn(function()
				local StartTime = os.clock()
				repeat
					Thread:Wait()
					if not CommonVariables.ActuallyEquipped then
						break
					end
				until (os.clock() - StartTime) >= CurrentModule.BulletShellDelay
				if CommonVariables.ActuallyEquipped then
					EjectShell(((Camera.Focus.p - Camera.CoordinateFrame.p).Magnitude <= 1) and HandleToFire)
				end
			end)
		end
		return true
	end

	local function gunCoolDown()
		Thread:Spawn(function()
			CurrentVariables.ShotID = CurrentVariables.ShotID + 1
			local LastShotID = CurrentVariables.ShotID
			local Interrupted = false
			local CooldownTime = CurrentModule.TimeBeforeCooldown
			local StartTime = os.clock()
			repeat
				Thread:Wait()
				if LastShotID ~= CurrentVariables.ShotID then
					break
				end
			until (os.clock() - StartTime) >= CooldownTime
			if LastShotID ~= CurrentVariables.ShotID then
				Interrupted = true
			end
			if not Interrupted then
				CommonVariables.CanBeCooledDown = true
			end
		end)
	end

	local function setUpFiringAnimation()
		if not CurrentModule.ShotgunPump then
			HandleToFire = (HandleToFire == Handle and CurrentModule.DualFireEnabled) and Handle2 or Handle

			if CurrentModule.AimAnimationsEnabled then
				CurrentAimFireAnim = (
					CurrentAimFireAnim == CurrentAnimTable.AimFireAnim
					and CurrentModule.SecondaryFireAnimationEnabled
				)
						and CurrentAnimTable.AimSecondaryFireAnim
					or CurrentAnimTable.AimFireAnim
				CurrentAimFireAnimationSpeed = (
					CurrentAimFireAnimationSpeed == CurrentModule.AimFireAnimationSpeed
					and CurrentModule.SecondaryFireAnimationEnabled
				)
						and CurrentModule.AimSecondaryFireAnimationSpeed
					or CurrentModule.AimFireAnimationSpeed
			end

			CurrentFireAnim = (
				CurrentFireAnim == CurrentAnimTable.FireAnim and CurrentModule.SecondaryFireAnimationEnabled
			)
					and CurrentAnimTable.SecondaryFireAnim
				or CurrentAnimTable.FireAnim
			CurrentFireAnimationSpeed = (
				CurrentFireAnimationSpeed == CurrentModule.FireAnimationSpeed
				and CurrentModule.SecondaryFireAnimationEnabled
			)
					and CurrentModule.SecondaryFireAnimationSpeed
				or CurrentModule.FireAnimationSpeed
		end
	end

	local function gunDoneCharging()
		return CommonVariables.ActuallyEquipped
			and not CommonVariables.Enabled
			and not CommonVariables.Charging
			and not CommonVariables.Reloading
			and not CommonVariables.Overheated
			and not CommonVariables.HoldDown
			and not CommonVariables.Switching
			and not CommonVariables.Alting
			and CurrentVariables.Mag > 0
			and CurrentVariables.Heat < CurrentModule.MaxHeat
			and Humanoid.Health > 0
	end

	local function gunCanFire()
		return CommonVariables.ActuallyEquipped
			and CommonVariables.Enabled
			and not CommonVariables.Reloading
			and not CommonVariables.Overheated
			and not CommonVariables.HoldDown
			and not CommonVariables.Switching
			and not CommonVariables.Alting
			and CurrentVariables.Mag > 0
			and CurrentVariables.Heat < CurrentModule.MaxHeat
			and Humanoid.Health > 0
	end

	local function OnFiring()
		-- this is for charging up your gun
		if CurrentModule.ChargedShotAdvanceEnabled and not CurrentModule.SelectiveFireEnabled then
			CommonVariables.Charging = true
			if gunCanFire() then
				chargeEffect()
				if gunDoneCharging() then
					for _ = 1, (CurrentModule.BurstFireEnabled and (AddressTableValue(
						CurrentModule.ChargeAlterTable.BulletPerBurst,
						CurrentModule.BulletPerBurst
					)) or 1) do
						local CLDirections = {}
						local SVDirections = {}
						local success = shotShellEjectSpawnLoop()
						if not success then
							break
						end
						CommonVariables.CurrentRate = CommonVariables.CurrentRate
							+ CurrentModule.SmokeTrailRateIncrement
						for ii = 1, (CurrentModule.ShotgunEnabled and (AddressTableValue(
							CurrentModule.ChargeAlterTable.BulletPerShot,
							CurrentModule.BulletPerShot
						)) or 1) do
							local Position = Get3DPosition(GunGUI.Crosshair.AbsolutePosition)
							local CurrentSpread = 0 -- Spread removed
							local cframe = (Camera.Focus.p - Camera.CoordinateFrame.p).Magnitude <= 1
									and CFrame.new(
										VMHandleToFire:FindFirstChild("GunFirePoint" .. CurrentFireMode).WorldPosition,
										Position
									)
								or CFrame.new(
									HandleToFire:FindFirstChild("GunFirePoint" .. CurrentFireMode).WorldPosition,
									Position
								)
							local svCframe = CFrame.new(
								HandleToFire:FindFirstChild("GunFirePoint" .. CurrentFireMode).WorldPosition,
								Position
							)

							if CurrentModule.ShotgunPattern and CurrentModule.SpreadPattern then
								local X, Y = CurrentModule.SpreadPattern[ii][1], CurrentModule.SpreadPattern[ii][2]
								local SpreadPattern =
									CFrame.Angles(math.rad(CurrentSpread * Y / 50), math.rad(CurrentSpread * X / 50), 0)
								cframe = cframe * SpreadPattern
								svCframe = svCframe * SpreadPattern
							else
								local SpreadNormal = CFrame.Angles(
									math.rad(math.random(-CurrentSpread, CurrentSpread) / 50),
									math.rad(math.random(-CurrentSpread, CurrentSpread) / 50),
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
							AddressTableValue(CurrentModule.ChargeAlterTable.SelfKnockback, CurrentModule.SelfKnockback)
						then
							local KnockbackPosition = Get3DPosition(GunGUI.Crosshair.AbsolutePosition)
							SelfKnockback(KnockbackPosition, Torso.Position)
						end
						Fire(HandleToFire, VMHandleToFire, CLDirections, SVDirections)
						if CurrentModule.BatteryEnabled then
							CurrentVariables.ShotsForDepletion = CurrentVariables.ShotsForDepletion + 1
							if CurrentVariables.ShotsForDepletion >= CurrentModule.ShotsForDepletion then
								CurrentVariables.ShotsForDepletion = 0
								CurrentVariables.Ammo = CurrentVariables.Ammo
									- Random.new():NextInteger(
										AddressTableValue(
											CurrentModule.ChargeAlterTable.MinDepletion,
											CurrentModule.MinDepletion
										),
										AddressTableValue(
											CurrentModule.ChargeAlterTable.MaxDepletion,
											CurrentModule.MaxDepletion
										)
									)
							end
							CurrentVariables.Heat = CurrentVariables.Heat
								+ Random.new():NextInteger(
									AddressTableValue(
										CurrentModule.ChargeAlterTable.HeatPerFireMin,
										CurrentModule.HeatPerFireMin
									),
									AddressTableValue(
										CurrentModule.ChargeAlterTable.HeatPerFireMax,
										CurrentModule.HeatPerFireMax
									)
								)
						else
							-- if
							-- 	Module.MagCartridge
							-- 	and not CurrentModule.BatteryEnabled
							-- 	and CurrentModule.AmmoPerMag ~= math.huge
							-- then
							-- 	local Bullet = GunGUI.MagCartridge
							-- 		:FindFirstChild(CurrentVariables.Mag)
							-- 	if Module.Ejection then
							-- 		local Vel = Random2DDirection(
							-- 			Module.Velocity,
							-- 			math.random(Module.XMin, Module.XMax),
							-- 			math.random(Module.YMin, Module.YMax)
							-- 		) * (math.random() ^ 0.5)
							-- 		CreateTwoDeeShell(
							-- 			Bullet.Rotation,
							-- 			Bullet.AbsolutePosition,
							-- 			Bullet.AbsoluteSize,
							-- 			Vel,
							-- 			"shell",
							-- 			Module.Shockwave
							-- 		)
							-- 	end
							-- 	Bullet.Visible = false
							-- end
							CurrentVariables.Mag = CurrentVariables.Mag - 1
						end

						updateServerChangeMagAndAmmo()
						gunCoolDown()
						UpdateGUI()
						if CurrentModule.BurstFireEnabled then
							local BurstRate =
								AddressTableValue(CurrentModule.ChargeAlterTable.BurstRate, CurrentModule.BurstRate)
							local StartTime = os.clock()
							repeat
								Thread:Wait()
								if not CommonVariables.ActuallyEquipped then
									break
								end
							until (os.clock() - StartTime) >= BurstRate
						end
						if CurrentModule.BatteryEnabled then
							if CurrentVariables.Heat >= CurrentModule.MaxHeat then
								break
							end
						else
							if CurrentVariables.Mag <= 0 then
								break
							end
						end
					end
					setUpFiringAnimation()
					Thread:Wait(AddressTableValue(CurrentModule.ChargeAlterTable.FireRate, CurrentModule.FireRate))
					if
						CurrentModule.BatteryEnabled and CurrentVariables.Heat >= CurrentModule.MaxHeat
						or CurrentVariables.Mag <= 0
					then
						if
							CommonVariables.CurrentRate >= CurrentModule.MaximumRate
							and CurrentModule.SmokeTrailEnabled
						then
							Thread:Spawn(function()
								SmokeTrail:StopEmission()
								SmokeTrail:EmitSmokeTrail(
									HandleToFire["SmokeTrail" .. CurrentFireMode],
									VMHandleToFire["SmokeTrail" .. CurrentFireMode],
									CurrentModule.MaximumTime
								)
							end)
						end
					end
					if CurrentModule.ShotgunPump then
						if CommonVariables.ActuallyEquipped then
							if CurrentShotgunPumpinAnim then
								CurrentShotgunPumpinAnim:Play(nil, nil, CurrentShotgunPumpinAnimationSpeed)
							end
							if CurrentVMShotgunPumpinAnim then
								CurrentVMShotgunPumpinAnim:Play(nil, nil, CurrentVMShotgunPumpinAnimationSpeed)
							end
							if HandleToFire[CurrentFireMode]:FindFirstChild("PumpSound") then
								HandleToFire[CurrentFireMode].PumpSound:Play()
							end
							Thread:Spawn(function()
								local StartTime = os.clock()
								repeat
									Thread:Wait()
									if not CurrentVariables.ActuallyEquipped then
										break
									end
								until (os.clock() - StartTime) >= CurrentModule.BulletShellDelay
								if CurrentVariables.ActuallyEquipped then
									EjectShell(
										((Camera.Focus.p - Camera.CoordinateFrame.p).Magnitude <= 1) and HandleToFire
									)
								end
							end)
						end
						HandleToFire = (HandleToFire == Handle and CurrentModule.DualFireEnabled) and Handle2 or Handle

						if CurrentModule.AimAnimationsEnabled then
							CurrentAimFireAnim = (
								CurrentAimFireAnim == CurrentAnimTable.AimFireAnim
								and Module.SecondaryFireAnimationEnabled
							)
									and CurrentAnimTable.AimSecondaryFireAnim
								or CurrentAnimTable.AimFireAnim
							CurrentAimFireAnimationSpeed = (
								CurrentAimFireAnimationSpeed == Module.AimFireAnimationSpeed
								and Module.SecondaryFireAnimationEnabled
							)
									and Module.AimSecondaryFireAnimationSpeed
								or Module.AimFireAnimationSpeed
						end

						CurrentFireAnim = (
							CurrentFireAnim == CurrentAnimTable.FireAnim
							and CurrentModule.SecondaryFireAnimationEnabled
						)
								and CurrentAnimTable.SecondaryFireAnim
							or CurrentAnimTable.FireAnim
						CurrentFireAnimationSpeed = (
							CurrentFireAnimationSpeed == CurrentModule.FireAnimationSpeed
							and CurrentModule.SecondaryFireAnimationEnabled
						)
								and CurrentModule.SecondaryFireAnimationSpeed
							or CurrentModule.FireAnimationSpeed

						CurrentShotgunPumpinAnim = (
							CurrentShotgunPumpinAnim == CurrentAnimTable.ShotgunPumpinAnim
							and CurrentModule.SecondaryShotgunPump
						)
								and CurrentAnimTable.SecondaryShotgunPumpinAnim
							or CurrentAnimTable.ShotgunPumpinAnim
						CurrentShotgunPumpinAnimationSpeed = (
							CurrentShotgunPumpinAnimationSpeed == CurrentModule.ShotgunPumpinAnimationSpeed
							and CurrentModule.SecondaryShotgunPump
						)
								and CurrentModule.SecondaryShotgunPumpinAnimationSpeed
							or CurrentModule.ShotgunPumpinAnimationSpeed

						Thread:Wait(CurrentModule.ShotgunPumpinSpeed)
					end
					CurrentVariables.ChargeLevel = 0
					CommonVariables.Enabled = true
					if CommonVariables.ActuallyEquipped then
						if CurrentModule.BatteryEnabled then
							if CurrentVariables.Heat >= CurrentModule.MaxHeat then
								Overheat()
							end
						else
							if Module.AutoReload then
								if CurrentVariables.Mag <= 0 then
									Reload()
								end
							end
						end
					end
				end
			end

		-- this is for when your gun is chared and ready to fire
		elseif CurrentModule.HoldAndReleaseEnabled and not CurrentModule.SelectiveFireEnabled then
			CommonVariables.Charging = true
			if gunCanFire() then
				chargeEffect()
				if gunDoneCharging() and CommonVariables.Charged then
					CommonVariables.Charged = false
					for _ = 1, (CurrentModule.BurstFireEnabled and CurrentModule.BulletPerBurst or 1) do
						local CLDirections = {}
						local SVDirections = {}
						local success = shotShellEjectSpawnLoop()
						if not success then
							break
						end
						CommonVariables.CurrentRate = CommonVariables.CurrentRate
							+ CurrentModule.SmokeTrailRateIncrement
						for ii = 1, (CurrentModule.ShotgunEnabled and CurrentModule.BulletPerShot or 1) do
							local Position = Get3DPosition(GunGUI.Crosshair.AbsolutePosition)
							local CurrentSpread = 0 -- Spread removed
							local cframe = (Camera.Focus.p - Camera.CoordinateFrame.p).Magnitude <= 1
									and CFrame.new(
										VMHandleToFire:FindFirstChild("GunFirePoint" .. CurrentFireMode).WorldPosition,
										Position
									)
								or CFrame.new(
									HandleToFire:FindFirstChild("GunFirePoint" .. CurrentFireMode).WorldPosition,
									Position
								)
							local svCframe = CFrame.new(
								HandleToFire:FindFirstChild("GunFirePoint" .. CurrentFireMode).WorldPosition,
								Position
							)

							if CurrentModule.ShotgunPattern and CurrentModule.SpreadPattern then
								local X, Y = CurrentModule.SpreadPattern[ii][1], CurrentModule.SpreadPattern[ii][2]
								local SpreadPattern =
									CFrame.Angles(math.rad(CurrentSpread * Y / 50), math.rad(CurrentSpread * X / 50), 0)
								cframe = cframe * SpreadPattern
								svCframe = svCframe * SpreadPattern
							else
								local SpreadNormal = CFrame.Angles(
									math.rad(math.random(-CurrentSpread, CurrentSpread) / 50),
									math.rad(math.random(-CurrentSpread, CurrentSpread) / 50),
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
						if CurrentModule.SelfKnockback then
							local KnockbackPosition = Get3DPosition(GunGUI.Crosshair.AbsolutePosition)
							SelfKnockback(KnockbackPosition, Torso.Position)
						end
						Fire(HandleToFire, VMHandleToFire, CLDirections, SVDirections)
						if CurrentModule.BatteryEnabled then
							CurrentVariables.ShotsForDepletion = CurrentVariables.ShotsForDepletion + 1
							if CurrentVariables.ShotsForDepletion >= CurrentModule.ShotsForDepletion then
								CurrentVariables.ShotsForDepletion = 0
								CurrentVariables.Ammo = CurrentVariables.Ammo
									- Random.new():NextInteger(CurrentModule.MinDepletion, CurrentModule.MaxDepletion)
							end
							CurrentVariables.Heat = CurrentVariables.Heat
								+ Random.new():NextInteger(CurrentModule.HeatPerFireMin, CurrentModule.HeatPerFireMax)
						else
							-- if
							-- 	Module.MagCartridge
							-- 	and not CurrentModule.BatteryEnabled
							-- 	and CurrentModule.AmmoPerMag ~= math.huge
							-- then
							-- 	local Bullet = GunGUI.MagCartridge
							-- 		:FindFirstChild(CurrentVariables.Mag)
							-- 	if Module.Ejection then
							-- 		local vel = Random2DDirection(
							-- 			Module.Velocity,
							-- 			math.random(Module.XMin, Module.XMax),
							-- 			math.random(Module.YMin, Module.YMax)
							-- 		) * (math.random() ^ 0.5)
							-- 		CreateTwoDeeShell(
							-- 			Bullet.Rotation,
							-- 			Bullet.AbsolutePosition,
							-- 			Bullet.AbsoluteSize,
							-- 			vel,
							-- 			"shell",
							-- 			Module.Shockwave
							-- 		)
							-- 	end
							-- 	Bullet.Visible = false
							-- end
							CurrentVariables.Mag = CurrentVariables.Mag - 1
						end
						updateServerChangeMagAndAmmo()
						gunCoolDown()
						UpdateGUI()
						if CurrentModule.BurstFireEnabled then
							local StartTime = os.clock()
							repeat
								Thread:Wait()
								if not CommonVariables.ActuallyEquipped then
									break
								end
							until (os.clock() - StartTime) >= CurrentModule.BurstRate
						end
						if CurrentModule.BatteryEnabled then
							if CurrentVariables.Heat >= CurrentModule.MaxHeat then
								break
							end
						else
							if CurrentVariables.Mag <= 0 then
								break
							end
						end
					end
					setUpFiringAnimation()
					Thread:Wait(CurrentModule.FireRate)
					if
						CurrentModule.BatteryEnabled and CurrentVariables.Heat >= CurrentModule.MaxHeat
						or CurrentVariables.Mag <= 0
					then
						if
							CommonVariables.CurrentRate >= CurrentModule.MaximumRate
							and CurrentModule.SmokeTrailEnabled
						then
							Thread:Spawn(function()
								SmokeTrail:StopEmission()
								SmokeTrail:EmitSmokeTrail(
									HandleToFire["SmokeTrail" .. CurrentFireMode],
									VMHandleToFire["SmokeTrail" .. CurrentFireMode],
									CurrentModule.MaximumTime
								)
							end)
						end
					end
					if CurrentModule.ShotgunPump then
						if CommonVariables.ActuallyEquipped then
							if CurrentShotgunPumpinAnim then
								CurrentShotgunPumpinAnim:Play(nil, nil, CurrentShotgunPumpinAnimationSpeed)
							end
							if CurrentVMShotgunPumpinAnim then
								CurrentVMShotgunPumpinAnim:Play(nil, nil, CurrentVMShotgunPumpinAnimationSpeed)
							end
							if HandleToFire[CurrentFireMode]:FindFirstChild("PumpSound") then
								HandleToFire[CurrentFireMode].PumpSound:Play()
							end
							Thread:Spawn(function()
								local StartTime = os.clock()
								repeat
									Thread:Wait()
									if not CommonVariables.ActuallyEquipped then
										break
									end
								until (os.clock() - StartTime) >= CurrentModule.BulletShellDelay
								if CommonVariables.ActuallyEquipped then
									EjectShell(
										((Camera.Focus.p - Camera.CoordinateFrame.p).Magnitude <= 1) and HandleToFire
									)
								end
							end)
						end
						HandleToFire = (HandleToFire == Handle and CurrentModule.DualFireEnabled) and Handle2 or Handle

						if CurrentModule.AimAnimationsEnabled then
							CurrentAimFireAnim = (
								CurrentAimFireAnim == CurrentAnimTable.AimFireAnim
								and CurrentModule.SecondaryFireAnimationEnabled
							)
									and CurrentAnimTable.AimSecondaryFireAnim
								or CurrentAnimTable.AimFireAnim
							CurrentAimFireAnimationSpeed = (
								CurrentAimFireAnimationSpeed == CurrentModule.AimFireAnimationSpeed
								and CurrentModule.SecondaryFireAnimationEnabled
							)
									and CurrentModule.AimSecondaryFireAnimationSpeed
								or CurrentModule.AimFireAnimationSpeed
						end

						CurrentFireAnim = (
							CurrentFireAnim == CurrentAnimTable.FireAnim
							and CurrentModule.SecondaryFireAnimationEnabled
						)
								and CurrentAnimTable.SecondaryFireAnim
							or CurrentAnimTable.FireAnim
						CurrentFireAnimationSpeed = (
							CurrentFireAnimationSpeed == CurrentModule.FireAnimationSpeed
							and CurrentModule.SecondaryFireAnimationEnabled
						)
								and CurrentModule.SecondaryFireAnimationSpeed
							or CurrentModule.FireAnimationSpeed

						CurrentShotgunPumpinAnim = (
							CurrentShotgunPumpinAnim == CurrentAnimTable.ShotgunPumpinAnim
							and CurrentModule.SecondaryShotgunPump
						)
								and CurrentAnimTable.SecondaryShotgunPumpinAnim
							or CurrentAnimTable.ShotgunPumpinAnim
						CurrentShotgunPumpinAnimationSpeed = (
							CurrentShotgunPumpinAnimationSpeed == CurrentModule.ShotgunPumpinAnimationSpeed
							and CurrentModule.SecondaryShotgunPump
						)
								and CurrentModule.SecondaryShotgunPumpinAnimationSpeed
							or CurrentModule.ShotgunPumpinAnimationSpeed

						Thread:Wait(CurrentModule.ShotgunPumpinSpeed)
					end
					CommonVariables.Enabled = true
					if CommonVariables.ActuallyEquipped then
						if CurrentModule.BatteryEnabled then
							if CurrentVariables.Heat >= CurrentModule.MaxHeat then
								Overheat()
							end
						else
							if Module.AutoReload then
								if CurrentVariables.Mag <= 0 then
									Reload()
								end
							end
						end
					end
				end
			end
		else
			CommonVariables.Down = true
			local IsChargedShot = false
			if gunCanFire() then
				CommonVariables.CanBeCooledDown = false
				CommonVariables.Enabled = false
				if CurrentAnimTable.InspectAnim and CurrentAnimTable.InspectAnim.IsPlaying then
					CurrentAnimTable.InspectAnim:Stop()
				end

				if CurrentModule.ChargedShotEnabled then
					if
						CommonVariables.ActuallyEquipped
						and HandleToFire[CurrentFireMode]:FindFirstChild("ChargeSound")
					then
						HandleToFire[CurrentFireMode].ChargeSound:Play()
					end
					Thread:Wait(CurrentModule.ChargingTime)
					IsChargedShot = true
				end
				if CurrentModule.MinigunEnabled then
					if CurrentAnimTable.MinigunRevUpAnim and not CurrentAnimTable.MinigunRevUpAnim.IsPlaying then
						CurrentAnimTable.MinigunRevUpAnim:Play(nil, nil, CurrentModule.MinigunRevUpAnimationSpeed)
					end

					if CommonVariables.ActuallyEquipped and HandleToFire[CurrentFireMode]:FindFirstChild("WindUp") then
						HandleToFire[CurrentFireMode].WindUp:Play()
					end
					Thread:Wait(CurrentModule.DelayBeforeFiring)
				end
				while (CommonVariables.Down or IsChargedShot) and gunDoneCharging() do
					IsChargedShot = false
					for _ = 1, ((CurrentModule.SelectiveFireEnabled and (CurrentVariables.FireModes[CurrentVariables.FireMode] ~= true and CurrentVariables.FireModes[CurrentVariables.FireMode] or 1)) or (CurrentModule.BurstFireEnabled and CurrentModule.BulletPerBurst) or 1) do
						local CLDirections = {}
						local SVDirections = {}
						local success = shotShellEjectSpawnLoop()
						if not success then
							break
						end
						CommonVariables.CurrentRate = CommonVariables.CurrentRate
							+ CurrentModule.SmokeTrailRateIncrement
						for ii = 1, (CurrentModule.ShotgunEnabled and CurrentModule.BulletPerShot or 1) do
							local Position = Get3DPosition(GunGUI.Crosshair.AbsolutePosition)
							local Spread = 0 -- Spread removed
							local cframe = CFrame.new(
								Tool.Handle:FindFirstChild("GunFirePoint" .. CurrentFireMode).WorldPosition,
								Position
							)
							local svCframe = CFrame.new(
								HandleToFire:FindFirstChild("GunFirePoint" .. CurrentFireMode).WorldPosition,
								Position
							)

							if CurrentModule.ShotgunPattern and CurrentModule.SpreadPattern then
								local X, Y = CurrentModule.SpreadPattern[ii][1], CurrentModule.SpreadPattern[ii][2]
								local SpreadPattern =
									CFrame.Angles(math.rad(Spread * Y / 50), math.rad(Spread * X / 50), 0)
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
						if CurrentModule.SelfKnockback then
							local KnockbackPosition = Get3DPosition(GunGUI.Crosshair.AbsolutePosition)
							SelfKnockback(KnockbackPosition, Torso.Position)
						end
						Fire(HandleToFire, VMHandleToFire, CLDirections, SVDirections)
						if CurrentModule.BatteryEnabled then
							CurrentVariables.ShotsForDepletion = CurrentVariables.ShotsForDepletion + 1
							if CurrentVariables.ShotsForDepletion >= CurrentModule.ShotsForDepletion then
								CurrentVariables.ShotsForDepletion = 0
								CurrentVariables.Ammo = CurrentVariables.Ammo
									- Random.new():NextInteger(CurrentModule.MinDepletion, CurrentModule.MaxDepletion)
							end
							CurrentVariables.Heat = CurrentVariables.Heat
								+ Random.new():NextInteger(CurrentModule.HeatPerFireMin, CurrentModule.HeatPerFireMax)
						else
							-- if
							-- 	Module.MagCartridge
							-- 	and not CurrentModule.BatteryEnabled
							-- 	and CurrentModule.AmmoPerMag ~= math.huge
							-- then
							-- 	local Bullet = GunGUI.MagCartridge
							-- 		:FindFirstChild(CurrentVariables.Mag)
							-- 	if Module.Ejection then
							-- 		local Vel = Random2DDirection(
							-- 			Module.Velocity,
							-- 			math.random(Module.XMin, Module.XMax),
							-- 			math.random(Module.YMin, Module.YMax)
							-- 		) * (math.random() ^ 0.5)
							-- 		CreateTwoDeeShell(
							-- 			Bullet.Rotation,
							-- 			Bullet.AbsolutePosition,
							-- 			Bullet.AbsoluteSize,
							-- 			Vel,
							-- 			"shell",
							-- 			Module.Shockwave
							-- 		)
							-- 	end
							-- end
							CurrentVariables.Mag = CurrentVariables.Mag - 1
						end
						updateServerChangeMagAndAmmo()
						gunCoolDown()
						UpdateGUI()
						if CurrentModule.BurstFireEnabled and not CurrentModule.SelectiveFireEnabled then
							local StartTime = os.clock()
							repeat
								Thread:Wait()
								if not CommonVariables.ActuallyEquipped then
									break
								end
							until (os.clock() - StartTime) >= CurrentModule.BurstRate
						end
						if CurrentModule.SelectiveFireEnabled then
							local StartTime = os.clock()
							repeat
								Thread:Wait()
								if not CommonVariables.ActuallyEquipped then
									break
								end
							until (os.clock() - StartTime) >= CurrentModule.BurstRates[CurrentVariables.FireMode]
						end
						if CurrentModule.BatteryEnabled then
							if CurrentVariables.Heat >= CurrentModule.MaxHeat then
								break
							end
						else
							if CurrentVariables.Mag <= 0 then
								break
							end
						end
					end
					setUpFiringAnimation()
					Thread:Wait(
						CurrentModule.SelectiveFireEnabled and CurrentModule.FireRates[CurrentVariables.FireMode]
							or CurrentModule.FireRate
					)
					if
						CurrentModule.BatteryEnabled and CurrentVariables.Heat >= CurrentModule.MaxHeat
						or CurrentVariables.Mag <= 0
					then
						if
							CommonVariables.CurrentRate >= CurrentModule.MaximumRate
							and CurrentModule.SmokeTrailEnabled
						then
							Thread:Spawn(function()
								SmokeTrail:StopEmission()
								SmokeTrail:EmitSmokeTrail(
									HandleToFire["SmokeTrail" .. CurrentFireMode],
									VMHandleToFire["SmokeTrail" .. CurrentFireMode],
									CurrentModule.MaximumTime
								)
							end)
						end
					end
					if CurrentModule.SelectiveFireEnabled then
						if CurrentVariables.FireModes[CurrentVariables.FireMode] ~= true then
							break
						end
					else
						if not CurrentModule.Auto then
							break
						end
					end
				end
				if CurrentModule.MinigunEnabled then
					if
						CommonVariables.ActuallyEquipped
						and CurrentAnimTable.MinigunRevDownAnim
						and not CurrentAnimTable.MinigunRevDownAnim.IsPlaying
					then
						CurrentAnimTable.MinigunRevDownAnim:Play(nil, nil, CurrentModule.MinigunRevDownAnimationSpeed)
					end
					if CurrentAnimTable.MinigunRevUpAnim and CurrentAnimTable.MinigunRevUpAnim.IsPlaying then
						CurrentAnimTable.MinigunRevUpAnim:Stop()
					end

					if
						CommonVariables.ActuallyEquipped and HandleToFire[CurrentFireMode]:FindFirstChild("WindDown")
					then
						HandleToFire[CurrentFireMode].WindDown:Play()
					end
					Thread:Wait(CurrentModule.DelayAfterFiring)
				end
				if CurrentModule.ShotgunPump then
					if CommonVariables.ActuallyEquipped then
						if CurrentShotgunPumpinAnim then
							CurrentShotgunPumpinAnim:Play(nil, nil, CurrentShotgunPumpinAnimationSpeed)
						end
						if CurrentVMShotgunPumpinAnim then
							CurrentVMShotgunPumpinAnim:Play(nil, nil, CurrentVMShotgunPumpinAnimationSpeed)
						end
						if HandleToFire[CurrentFireMode]:FindFirstChild("PumpSound") then
							HandleToFire[CurrentFireMode].PumpSound:Play()
						end
						Thread:Spawn(function()
							local StartTime = os.clock()
							repeat
								Thread:Wait()
								if not CommonVariables.ActuallyEquipped then
									break
								end
							until (os.clock() - StartTime) >= CurrentModule.BulletShellDelay
							if CommonVariables.ActuallyEquipped then
								EjectShell(
									((Camera.Focus.p - Camera.CoordinateFrame.p).Magnitude <= 1) and VMHandleToFire
										or HandleToFire
								)
							end
						end)
					end
					HandleToFire = (HandleToFire == Handle and CurrentModule.DualFireEnabled) and Handle2 or Handle

					if CurrentModule.AimAnimationsEnabled then
						CurrentAimFireAnim = (
							CurrentAimFireAnim == CurrentAnimTable.AimFireAnim
							and CurrentModule.SecondaryFireAnimationEnabled
						)
								and CurrentAnimTable.AimSecondaryFireAnim
							or CurrentAnimTable.AimFireAnim
						CurrentAimFireAnimationSpeed = (
							CurrentAimFireAnimationSpeed == CurrentModule.AimFireAnimationSpeed
							and CurrentModule.SecondaryFireAnimationEnabled
						)
								and CurrentModule.AimSecondaryFireAnimationSpeed
							or CurrentModule.AimFireAnimationSpeed
					end

					CurrentFireAnim = (
						CurrentFireAnim == CurrentAnimTable.FireAnim and CurrentModule.SecondaryFireAnimationEnabled
					)
							and CurrentAnimTable.SecondaryFireAnim
						or CurrentAnimTable.FireAnim
					CurrentFireAnimationSpeed = (
						CurrentFireAnimationSpeed == CurrentModule.FireAnimationSpeed
						and CurrentModule.SecondaryFireAnimationEnabled
					)
							and CurrentModule.SecondaryFireAnimationSpeed
						or CurrentModule.FireAnimationSpeed

					CurrentShotgunPumpinAnim = (
						CurrentShotgunPumpinAnim == CurrentAnimTable.ShotgunPumpinAnim
						and CurrentModule.SecondaryShotgunPump
					)
							and CurrentAnimTable.SecondaryShotgunPumpinAnim
						or CurrentAnimTable.ShotgunPumpinAnim
					CurrentShotgunPumpinAnimationSpeed = (
						CurrentShotgunPumpinAnimationSpeed == CurrentModule.ShotgunPumpinAnimationSpeed
						and CurrentModule.SecondaryShotgunPump
					)
							and CurrentModule.SecondaryShotgunPumpinAnimationSpeed
						or CurrentModule.ShotgunPumpinAnimationSpeed

					Thread:Wait(CurrentModule.ShotgunPumpinSpeed)
				end
				CommonVariables.Enabled = true
				if CurrentVariables.Mag <= 0 then
					CurrentFireAnim:Stop()
					Empty:Play()
				end
				if CommonVariables.ActuallyEquipped then
					if CurrentModule.BatteryEnabled then
						if CurrentVariables.Heat >= CurrentModule.MaxHeat then
							Overheat()
						end
					else
						if Module.AutoReload then
							if CurrentVariables.Mag <= 0 then
								Reload()
							end
						end
					end
				end
			end
		end
	end

	local function OnStoppingFiring()
		CommonVariables.Down = false
		if CurrentModule.ChargedShotAdvanceEnabled or CurrentModule.HoldAndReleaseEnabled then
			CommonVariables.Charging = false
		end
		if CurrentModule.HoldAndReleaseEnabled and not CommonVariables.Charged then
			CommonVariables.Enabled = true
		end
		if CommonVariables.CurrentRate >= CurrentModule.MaximumRate and CurrentModule.SmokeTrailEnabled then
			Thread:Spawn(function()
				SmokeTrail:StopEmission()
				print(HandleToFire:FindFirstAncestorOfClass("Tool").Name)
				SmokeTrail:EmitSmokeTrail(
					HandleToFire["SmokeTrail" .. CurrentFireMode],
					VMHandleToFire["SmokeTrail" .. CurrentFireMode],
					CurrentModule.MaximumTime
				)
			end)
		end
	end

	local function OnMeleeSequenceTriggered(ShootingHandle)
		local Direction = ((ShootingHandle["MeleeHitPoint" .. CurrentFireMode].WorldCFrame * CFrame.new(
			0,
			0,
			-CurrentModule.MeleeAttackRange
		)).p - ShootingHandle["MeleeHitPoint" .. CurrentFireMode].WorldPosition).Unit
		local MeleeRay = Ray.new(
			ShootingHandle["MeleeHitPoint" .. CurrentFireMode].WorldPosition,
			Direction * CurrentModule.MeleeAttackRange
		)
		local Hit, Pos, Norm, Material = Workspace:FindPartOnRayWithIgnoreList(MeleeRay, { Camera, Tool.Parent })
		if Hit then
			if Hit.Name == "_glass" then
				ShatterGlass:FireServer(Hit, Pos, Direction)
			else
				local Target = Hit:FindFirstAncestorOfClass("Model")
				local TargetHumanoid = Target and Target:FindFirstChildOfClass("Humanoid")
				local TargetTorso = Target
					and (Target:FindFirstChild("HumanoidRootPart") or Target:FindFirstChild("Head"))
				local VisualEffects2 = VisualEffects
				if VisualEffects:FindFirstChild(CurrentModule.ModuleName) then
					VisualEffects2 = VisualEffects[CurrentModule]
				end
				if TargetHumanoid and TargetHumanoid.Health > 0 and TargetTorso then
					ProjectileHandler:VisualizeHitEffect(
						"Blood",
						Hit,
						Pos,
						Norm,
						Material,
						CurrentModule,
						{ BloodEffectFolder = VisualEffects2.MeleeBloodEffect },
						true
					)
					if TargetHumanoid.Health > 0 then
						Thread:Spawn(function()
							InflictTarget:InvokeServer(
								"GunMelee",
								Tool,
								CurrentModule,
								TargetHumanoid,
								TargetTorso,
								Hit
							)
						end)
						MarkHit(CurrentModule, Hit.Name == "Head" and CurrentModule.MeleeHeadshotEnabled)
					end
				else
					ProjectileHandler:VisualizeHitEffect(
						"Normal",
						Hit,
						Pos,
						Norm,
						Material,
						CurrentModule,
						{ HitEffectFolder = VisualEffects2.MeleeHitEffect },
						true
					)
				end
			end
		end
	end

	local function OnMeleeAttacking()
		if CurrentModule.MeleeAttackEnabled then
			if
				(CurrentAnimTable.MeleeAttackAnim and CurrentAnimTable.MeleeAttackAnim.Length > 0)
				and (CurrentVMAnimTable.VMMeleeAttackAnim and CurrentVMAnimTable.VMMeleeAttackAnim.Length > 0)
			then
				local Connection
				if
					CommonVariables.ActuallyEquipped
					and CommonVariables.Enabled
					and not CommonVariables.Overheated
					and not CommonVariables.Switching
					and not CommonVariables.Alting
					and not CommonVariables.AimDown
					and Humanoid.Health > 0
				then
					CommonVariables.Enabled = false
					if CurrentAnimTable.InspectAnim and CurrentAnimTable.InspectAnim.IsPlaying then
						CurrentAnimTable.InspectAnim:Stop()
					end
					if CurrentVMAnimTable.VMInspectAnim and CurrentVMAnimTable.VMInspectAnim.IsPlaying then
						CurrentVMAnimTable.VMInspectAnim:Stop()
					end
					CurrentAnimTable.MeleeAttackAnim:Play(nil, nil, CurrentModule.MeleeAttackAnimationSpeed)
					CurrentVMAnimTable.VMMeleeAttackAnim:Play(nil, nil, CurrentModule.VMMeleeAttackAnimationSpeed)
					if
						CommonVariables.ActuallyEquipped
						and HandleToFire[CurrentFireMode]:FindFirstChild("MeleeSwingSound")
					then
						HandleToFire[CurrentFireMode].MeleeSwingSound:Play()
					end
					Connection = CurrentAnimTable.MeleeAttackAnim
						:GetMarkerReachedSignal("MeleeDamageSequence")
						:Connect(function(ParamString)
							--print(ParamString)
							if (Camera.Focus.p - Camera.CoordinateFrame.p).Magnitude > 1 then
								OnMeleeSequenceTriggered(Handle, Module.MeleeAttackRange)
							end
							if Connection then
								--print("Disconnected")
								Connection:Disconnect()
								Connection = nil
							end
						end)

					if (Camera.Focus.p - Camera.CoordinateFrame.p).Magnitude <= 1 then
						CurrentVMAnimTable.VMMeleeAttackAnim.Stopped:Wait()
					else
						CurrentAnimTable.MeleeAttackAnim.Stopped:Wait()
					end
					CurrentAnimTable.MeleeAttackAnim.Stopped:Wait()
					CommonVariables.Enabled = true
				end
			end
		end
	end

	local function OnUnequipping()
		Thread:Spawn(function()
			print(Tool.Name .. " Stopped")
			Empty:Stop()
			if CurrentModule.ChargedShotAdvanceEnabled then
				CommonVariables.Charging = false
			end
			if CurrentModule.HoldAndReleaseEnabled then
				CommonVariables.Charged = false
			end
			CommonVariables.Equipped = false
			CommonVariables.ActuallyEquipped = false

			GunGUI:Destroy()

			for _, conn in ipairs(connections) do
				conn:Disconnect()
			end
			connections = {}

			if Module.WalkSpeedRedutionEnabled then
				Humanoid.WalkSpeed = Humanoid.WalkSpeed + Module.WalkSpeedRedution
			else
				Humanoid.WalkSpeed = Humanoid.WalkSpeed
			end
			UserInputService.MouseIconEnabled = true
			RunService:UnbindFromRenderStep(BindToStepName)
			for i, v in pairs(KeyframeConnections) do
				v:Disconnect()
				table.remove(KeyframeConnections, i)
			end
			table.clear(VMKeyframes)
			for i, v in pairs(VMKeyframeConnections) do
				v:Disconnect()
				table.remove(VMKeyframeConnections, i)
			end
			LockedEntity = nil
			if Beam then
				Beam:Destroy()
				Beam = nil
			end
			if Attach0 then
				Attach0:Destroy()
				Attach0 = nil
			end
			if Attach1 then
				Attach1:Destroy()
				Attach1 = nil
			end
			for _, a in pairs(CurrentAnimTable) do
				if a and a.IsPlaying then
					a:Stop()
				end
			end

			for _, s in pairs(Handle[CurrentFireMode]:GetChildren()) do
				if s:IsA("Sound") and s.IsPlaying then
					s:Stop()
				end
			end
			if Handle2 then
				for _, s in pairs(Handle2[CurrentFireMode]:GetChildren()) do
					if s:IsA("Sound") and s.IsPlaying then
						s:Stop()
					end
				end
			end
			if CommonVariables.AimDown then
				TweenService:Create(
					Camera,
					TweenInfo.new(
						CurrentModule.TweenLengthNAD,
						CurrentModule.EasingStyleNAD,
						CurrentModule.EasingDirectionNAD
					),
					{ FieldOfView = 70 }
				):Play()
				--SetCrossScale(1)

				CommonVariables.Scoping = false
				Player.CameraMode = Enum.CameraMode.Classic
				UserInputService.MouseDeltaSensitivity = CommonVariables.InitialSensitivity
				CommonVariables.AimDown = false
			end

			FakeCamera = nil
		end)
	end

	UserInputService.InputBegan:Connect(function(Input, GameProcessed)
		if GameProcessed then
			return
		end
		if not UserInputService.TouchEnabled then
			if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.KeyCode == Module.Controller.Fire then
				OnFiring()
			elseif Input.KeyCode == Module.Keyboard.Reload or Input.KeyCode == Module.Controller.Reload then
				Reload()
			elseif Input.KeyCode == Module.Keyboard.HoldDown or Input.KeyCode == Module.Controller.HoldDown then
				OnHoldingDown()
			elseif Input.KeyCode == Module.Keyboard.Inspect or Input.KeyCode == Module.Controller.Inspect then
				OnInspecting()
			elseif Input.KeyCode == Module.Keyboard.Switch or Input.KeyCode == Module.Controller.Switch then
				OnSwitching()
			elseif Input.KeyCode == Module.Keyboard.ToogleAim or Input.KeyCode == Module.Controller.ToogleAim then
				OnTooglingAiming()
			elseif Input.KeyCode == Module.Keyboard.Melee or Input.KeyCode == Module.Controller.Melee then
				OnMeleeAttacking()
			elseif Input.KeyCode == Module.Keyboard.AltFire or Input.KeyCode == Module.Controller.AltFire then
				OnAlting()
			elseif Input.UserInputType == Enum.UserInputType.MouseButton2 then
				if
					not CommonVariables.Reloading
					and not CommonVariables.Overheated
					and not CommonVariables.HoldDown
					and not CommonVariables.Alting
					and not CommonVariables.AimDown
					and CommonVariables.ActuallyEquipped
					and CurrentModule.IronsightEnabled
					and (Camera.Focus.p - Camera.CoordinateFrame.p).Magnitude <= 1
				then
					if not CurrentModule.KeepAimingOnReloading then
						if CommonVariables.Reloading or CommonVariables.Overheated then
							return
						end
					end
					TweenService:Create(
						Camera,
						TweenInfo.new(
							CurrentModule.TweenLength,
							CurrentModule.EasingStyle,
							CurrentModule.EasingDirection
						),
						{ FieldOfView = CurrentModule.FieldOfViewIS }
					):Play()
					--SetCrossScale(CurrentModule.CrossScaleIS)
					if CurrentAnimTable.InspectAnim and CurrentAnimTable.InspectAnim.IsPlaying then
						CurrentAnimTable.InspectAnim:Stop()
					end
					if CurrentVMAnimTable.VMInspectAnim and CurrentVMAnimTable.VMInspectAnim.IsPlaying then
						CurrentVMAnimTable.VMInspectAnim:Stop()
					end
					if
						CurrentModule.AimAnimationsEnabled
						and CurrentAnimTable.IdleAnim
						and CurrentAnimTable.IdleAnim.IsPlaying
					then
						CurrentAnimTable.IdleAnim:Stop()
						if CurrentAnimTable.AimIdleAnim then
							CurrentAnimTable.AimIdleAnim:Play(nil, nil, CurrentModule.AimIdleAnimationSpeed)
						end
					end

					Player.CameraMode = Enum.CameraMode.LockFirstPerson
					UserInputService.MouseDeltaSensitivity = CommonVariables.InitialSensitivity
						* CurrentModule.MouseSensitiveIS
					CommonVariables.AimDown = true
				elseif
					not CommonVariables.Reloading
					and not CommonVariables.Overheated
					and not CommonVariables.HoldDown
					and not CommonVariables.Alting
					and not CommonVariables.AimDown
					and CommonVariables.ActuallyEquipped
					and CurrentModule.SniperEnabled
					and (Camera.Focus.p - Camera.CoordinateFrame.p).Magnitude <= 1
				then
					if not CurrentModule.KeepAimingOnReloading then
						if CommonVariables.Reloading or CommonVariables.Overheated then
							return
						end
					end
					TweenService:Create(
						Camera,
						TweenInfo.new(
							CurrentModule.TweenLength,
							CurrentModule.EasingStyle,
							CurrentModule.EasingDirection
						),
						{ FieldOfView = CurrentModule.FieldOfViewS }
					):Play()
					--SetCrossScale(CurrentModule.CrossScaleS)
					if CurrentAnimTable.InspectAnim and CurrentAnimTable.InspectAnim.IsPlaying then
						CurrentAnimTable.InspectAnim:Stop()
					end
					if CurrentVMAnimTable.VMInspectAnim and CurrentVMAnimTable.VMInspectAnim.IsPlaying then
						CurrentVMAnimTable.VMInspectAnim:Stop()
					end
					if
						CurrentModule.AimAnimationsEnabled
						and CurrentAnimTable.IdleAnim
						and CurrentAnimTable.IdleAnim.IsPlaying
					then
						CurrentAnimTable.IdleAnim:Stop()
						if CurrentAnimTable.AimIdleAnim then
							CurrentAnimTable.AimIdleAnim:Play(nil, nil, CurrentModule.AimIdleAnimationSpeed)
						end
					end

					CommonVariables.AimDown = true
					local StartTime = os.clock()
					repeat
						Thread:Wait()
						if not (CommonVariables.ActuallyEquipped or CommonVariables.AimDown) then
							break
						end
					until (os.clock() - StartTime) >= CurrentModule.ScopeDelay
					if CommonVariables.ActuallyEquipped and CommonVariables.AimDown then
						local ZoomSound = GunGUI.Scope.ZoomSound:Clone()
						ZoomSound.Parent = Player.PlayerGui
						ZoomSound:Play()
						ZoomSound.Ended:Connect(function()
							ZoomSound:Destroy()
						end)
						Player.CameraMode = Enum.CameraMode.LockFirstPerson
						UserInputService.MouseDeltaSensitivity = CommonVariables.InitialSensitivity
							* CurrentModule.MouseSensitiveS
						CommonVariables.Scoping = true
					end
				end
			end
		end
	end)

	UserInputService.InputEnded:Connect(function(Input, GameProcessed)
		if GameProcessed then
			return
		end
		if not UserInputService.TouchEnabled then
			if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.KeyCode == Module.Controller.Fire then
				OnStoppingFiring()
			elseif Input.UserInputType == Enum.UserInputType.MouseButton2 then
				if CommonVariables.AimDown then
					TweenService:Create(
						Camera,
						TweenInfo.new(
							CurrentModule.TweenLengthNAD,
							CurrentModule.EasingStyleNAD,
							CurrentModule.EasingDirectionNAD
						),
						{ FieldOfView = 70 }
					):Play()
					--SetCrossScale(1)
					if
						CurrentModule.AimAnimationsEnabled
						and CurrentAnimTable.AimIdleAnim
						and CurrentAnimTable.AimIdleAnim.IsPlaying
					then
						CurrentAnimTable.AimIdleAnim:Stop()
						if CurrentAnimTable.IdleAnim then
							CurrentAnimTable.IdleAnim:Play(nil, nil, CurrentModule.IdleAnimationSpeed)
						end
					end

					CommonVariables.Scoping = false
					Player.CameraMode = Enum.CameraMode.Classic
					UserInputService.MouseDeltaSensitivity = CommonVariables.InitialSensitivity
					CommonVariables.AimDown = false
				end
			end
		end
	end)

	MarkerEvent.Event:Connect(MarkHit)

	ChangeMagAndAmmo.OnClientEvent:Connect(function(Values)
		for i, v in ipairs(Values) do
			Variables[v.Id].Mag = v.Mag
			Variables[v.Id].Ammo = v.Ammo
			Variables[v.Id].Heat = v.Heat
		end
		UpdateGUI()
	end)

	Tool.Equipped:Connect(function()
		local existingGunGUI = Player.PlayerGui:FindFirstChild("GunGUI")
		if existingGunGUI then
			existingGunGUI:Destroy()
		end

		GunGUI = GUI:Clone()
		GunGUI.Parent = Player.PlayerGui

		-- Center the crosshair on the cursor by setting AnchorPoint to center
		if GunGUI:FindFirstChild("Crosshair") then
			GunGUI.Crosshair.AnchorPoint = Vector2.new(0.5, 0.5)
		end

		if UserInputService.TouchEnabled then
			local MobileButtons = GunGUI:WaitForChild("MobileButtons")
			MobileButtons.Visible = true

			connections[#connections + 1] = MobileButtons.AimButton.MouseButton1Click:Connect(OnTooglingAiming)
			connections[#connections + 1] = MobileButtons.HoldDownButton.MouseButton1Click:Connect(OnHoldingDown)
			connections[#connections + 1] = MobileButtons.InspectButton.MouseButton1Click:Connect(OnInspecting)
			connections[#connections + 1] = MobileButtons.SwitchButton.MouseButton1Click:Connect(OnSwitching)
			connections[#connections + 1] = MobileButtons.ReloadButton.MouseButton1Click:Connect(Reload)
			connections[#connections + 1] = MobileButtons.FireButton.MouseButton1Down:Connect(OnFiring)
			connections[#connections + 1] = MobileButtons.FireButton.MouseButton1Up:Connect(OnStoppingFiring)
			connections[#connections + 1] = MobileButtons.MeleeButton.MouseButton1Click:Connect(OnMeleeAttacking)
			connections[#connections + 1] = MobileButtons.AltButton.MouseButton1Click:Connect(OnAlting)
		end

		if CurrentVariables.Mag <= 0 then
			CurrentFireAnim:Stop()
			Empty:Play()
		end

		CommonVariables.Equipped = true
		if CurrentModule.AmmoPerMag ~= math.huge and CurrentModule.MaxHeat ~= math.huge then
			GunGUI.Frame.Visible = true
		end
		Player.CharacterRemoving:Connect(function()
			GunGUI:Destroy()
		end)
		UpdateGUI()

		--Viewmodel

		if Module.DualWeldEnabled then
			VMHandle2 = Viewmodel:WaitForChild(Module.SecondaryHandle, 2)
			if VMHandle2 == nil and Module.DualWeldEnabled then
				error('"Dual" setting is enabled but "VMHandle2" is missing!')
			end
		end

		Handle[CurrentFireMode].EquippedSound:Play()
		if Module.WalkSpeedRedutionEnabled then
			Humanoid.WalkSpeed = Humanoid.WalkSpeed - Module.WalkSpeedRedution
		else
			Humanoid.WalkSpeed = Humanoid.WalkSpeed
		end
		--SetCrossSettings(CurrentModule.CrossSize, CurrentModule.CrossSpeed, CurrentModule.CrossDamper)
		UserInputService.MouseIconEnabled = false
		if CurrentModule.ProjectileMotion then
			local VisualEffects2 = VisualEffects
			if VisualEffects:FindFirstChild(CurrentModule.ModuleName) then
				VisualEffects2 = VisualEffects[CurrentModule]
			end
			Beam, Attach0, Attach1 = ProjectileMotion.ShowProjectilePath(
				VisualEffects2.MotionBeam,
				HandleToFire:FindFirstChild("GunFirePoint" .. CurrentFireMode).WorldPosition,
				Vector3.new(),
				3,
				AddressTableValue(CurrentModule.ChargeAlterTable.BulletAcceleration, CurrentModule.BulletAcceleration)
			)
		end

		RunService:BindToRenderStep(BindToStepName, Enum.RenderPriority.Camera.Value, function(dt)
			--Update crosshair and scope
			RenderMouse()
			RenderScope()
			--	RenderCrosshair()
			--Update camera
			RenderCam()
			--Update rate
			RenderRate(dt)
			--Render motion
			if CurrentModule.ProjectileMotion then
				RenderMotion()
			end
			--Render cooldown
			if CurrentModule.BatteryEnabled then
				RenderCooldown(dt)
			end
			--Render 2D shell
			RenderTwoDeeShell(dt)
		end)

		if CurrentAnimTable.EquippedAnim then
			CurrentAnimTable.EquippedAnim:Play(nil, nil, CurrentModule.EquippedAnimationSpeed)
		end
		if CurrentAnimTable.IdleAnim then
			CurrentAnimTable.IdleAnim:Play(nil, nil, CurrentModule.IdleAnimationSpeed)
		end

		local StartTime = os.clock()
		repeat
			Thread:Wait()
			if not CommonVariables.Equipped then
				break
			end
		until (os.clock() - StartTime) >= CurrentModule.EquipTime
		if CommonVariables.Equipped then
			CommonVariables.ActuallyEquipped = true
		end

		if
			CommonVariables.ActuallyEquipped
			and Module.AutoReload
			and not CommonVariables.Reloading
			and (CurrentVariables.Ammo > 0 or not CurrentModule.LimitedAmmoEnabled)
			and CurrentVariables.Mag <= 0
		then
			Reload()
		end
	end)

	Tool.Unequipped:Connect(OnUnequipping)
	Character.Destroying:Connect(OnUnequipping)
	Humanoid.Died:Connect(OnUnequipping)

	Tool.AncestryChanged:Connect(function()
		if
			not Tool:IsDescendantOf(game)
			or Tool:IsDescendantOf(Workspace) and (not Tool:FindFirstAncestorOfClass("Model") or not Players:GetPlayerFromCharacter(
				Tool:FindFirstAncestorOfClass("Model")
			))
			or not Tool:IsDescendantOf(Workspace)
		then
			print("Parent Change")
			OnUnequipping()
		end
	end)
end

return GunHandlerClient
