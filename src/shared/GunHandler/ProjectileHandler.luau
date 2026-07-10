--!strict
local ProjectileHandler = {}

local CollectionService = game:GetService("CollectionService")
local Debris = game:GetService("Debris")
local SoundService = game:GetService("SoundService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Player = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local Modules = ReplicatedStorage:WaitForChild("Modules")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local ParticleFramework = require(Modules.ParticleFramework)
local DamageModule = require(Modules.DamageModule)
local Utilities = require(Modules.Utilities)
local Thread = Utilities.Thread
local ScreenCulling = Utilities.ScreenCulling
local Math = Utilities.Math

local InflictTarget = Remotes.InflictTarget
local VisualizeBullet = Remotes.VisualizeBullet
local VisualizeHitEffect = Remotes.VisualizeHitEffect
local ShatterGlass = Remotes.ShatterGlass

-- Properties
local OptimalEffects = false
local RenderDistance = 400
local ScreenCullingEnabled = true
local ScreenCullingRadius = 16

local Beam = Instance.new("Beam")
Beam.TextureSpeed = 0
Beam.LightEmission = 0
Beam.LightInfluence = 1
Beam.Transparency = NumberSequence.new(0)
type IgnoreList = { Instance }

local function GetSeatedVehicleModel(character: Model?): Model?
	if not character then
		return nil
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local seat = humanoid and humanoid.SeatPart
	if not seat then
		return nil
	end

	-- Typically returns the car model
	local vehicle = seat:FindFirstAncestorWhichIsA("Model")
	-- Avoid returning the character model if something is odd
	if vehicle == character then
		return nil
	end
	return vehicle
end

local function AppendSeatedVehicleToIgnore(ignoreList: IgnoreList, character: Model?)
	local vehicle = GetSeatedVehicleModel(character)
	if vehicle then
		table.insert(ignoreList, vehicle)
	end

	-- Also ignore the actual seat part (cheap + helps if hierarchy is unusual)
	if character then
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		local seat = humanoid and humanoid.SeatPart
		if seat then
			table.insert(ignoreList, seat)
		end
	end
end

local function AddressTableValue(enabled, level, v1, v2)
	if v1 ~= nil and enabled and level then
		return ((level == 1 and v1.Level1) or (level == 2 and v1.Level2) or (level == 3 and v1.Level3) or v2)
	else
		return v2
	end
end

local function EnumName(enumItem)
	-- Robustly resolve EnumItem -> name string
	if typeof(enumItem) == "EnumItem" then
		return enumItem.Name
	end
	if type(enumItem) == "string" then
		return enumItem
	end
	return tostring(enumItem)
end

local function SafeRandomFromArray(arr)
	if type(arr) ~= "table" then
		return nil
	end
	local n = #arr
	if n <= 0 then
		return nil
	end
	return arr[math.random(1, n)]
end

local function GetMaterialFolder(rootFolder: Instance?, materialEnum: any)
	if not rootFolder then
		return nil
	end
	local matName = EnumName(materialEnum)
	local folder = rootFolder:FindFirstChild(matName)
	if folder and folder:IsA("Folder") then
		return folder
	end
	local custom = rootFolder:FindFirstChild("Custom")
	if custom and custom:IsA("Folder") then
		return custom
	end
	-- last resort: allow any instance
	return folder or custom
end

local function FadeAndDestroyBeamDecal(
	beamClone: Beam?,
	a0: Attachment?,
	a1: Attachment?,
	hole: Attachment?,
	visibleTime: number,
	fadeTime: number
)
	Thread:Delay(visibleTime, function()
		if not beamClone or not hole then
			if a0 then
				a0:Destroy()
			end
			if a1 then
				a1:Destroy()
			end
			if beamClone then
				beamClone:Destroy()
			end
			if hole then
				hole:Destroy()
			end
			return
		end

		if visibleTime <= 0 then
			if a0 then
				a0:Destroy()
			end
			if a1 then
				a1:Destroy()
			end
			beamClone:Destroy()
			hole:Destroy()
			return
		end

		if fadeTime <= 0 then
			if a0 then
				a0:Destroy()
			end
			if a1 then
				a1:Destroy()
			end
			beamClone:Destroy()
			hole:Destroy()
			return
		end

		local t0 = os.clock()
		while hole and hole.Parent do
			local alpha = math.min((os.clock() - t0) / fadeTime, 1)
			if beamClone then
				beamClone.Transparency = NumberSequence.new(Math.Lerp(0, 1, alpha))
			end
			if alpha >= 1 then
				break
			end
			Thread:Wait()
		end

		if a0 then
			a0:Destroy()
		end
		if a1 then
			a1:Destroy()
		end
		if beamClone then
			beamClone:Destroy()
		end
		if hole then
			hole:Destroy()
		end
	end)
end

local function EmitWithQuality(particle: ParticleEmitter, count: number)
	Thread:Delay(0.01, function()
		if OptimalEffects then
			local quality = UserSettings().GameSettings.SavedQualityLevel
			if quality == Enum.SavedQualitySetting.Automatic then
				particle:Emit(count * 0.5)
			else
				local compressor = quality.Value / 21
				particle:Emit(count * compressor)
			end
		else
			particle:Emit(count)
		end
		Debris:AddItem(particle, particle.Lifetime.Max)
	end)
end

local function MakeImpactFX(Hit, Position, Normal, Material, ParentToPart, ClientModule, Miscs, Replicate, IsMelee)
	local SurfaceCF = CFrame.new(Position, Position + Normal)

	local HitEffectEnabled = ClientModule.HitEffectEnabled
	local HitSoundIDs = AddressTableValue(
		ClientModule.ChargedShotAdvanceEnabled,
		Miscs.ChargeLevel,
		ClientModule.ChargeAlterTable.HitSoundIDs,
		ClientModule.HitSoundIDs
	)
	local HitSoundPitchMin = AddressTableValue(
		ClientModule.ChargedShotAdvanceEnabled,
		Miscs.ChargeLevel,
		ClientModule.ChargeAlterTable.HitSoundPitchMin,
		ClientModule.HitSoundPitchMin
	)
	local HitSoundPitchMax = AddressTableValue(
		ClientModule.ChargedShotAdvanceEnabled,
		Miscs.ChargeLevel,
		ClientModule.ChargeAlterTable.HitSoundPitchMax,
		ClientModule.HitSoundPitchMax
	)
	local HitSoundVolume = AddressTableValue(
		ClientModule.ChargedShotAdvanceEnabled,
		Miscs.ChargeLevel,
		ClientModule.ChargeAlterTable.HitSoundVolume,
		ClientModule.HitSoundVolume
	)
	local CustomHitEffect = AddressTableValue(
		ClientModule.ChargedShotAdvanceEnabled,
		Miscs.ChargeLevel,
		ClientModule.ChargeAlterTable.CustomHitEffect,
		ClientModule.CustomHitEffect
	)

	local BulletHoleEnabled = ClientModule.BulletHoleEnabled
	local BulletHoleSize = AddressTableValue(
		ClientModule.ChargedShotAdvanceEnabled,
		Miscs.ChargeLevel,
		ClientModule.ChargeAlterTable.BulletHoleSize,
		ClientModule.BulletHoleSize
	)
	local BulletHoleTexture = AddressTableValue(
		ClientModule.ChargedShotAdvanceEnabled,
		Miscs.ChargeLevel,
		ClientModule.ChargeAlterTable.BulletHoleTexture,
		ClientModule.BulletHoleTexture
	)
	local PartColor = AddressTableValue(
		ClientModule.ChargedShotAdvanceEnabled,
		Miscs.ChargeLevel,
		ClientModule.ChargeAlterTable.PartColor,
		ClientModule.PartColor
	)
	local BulletHoleVisibleTime = ClientModule.BulletHoleVisibleTime
	local BulletHoleFadeTime = ClientModule.BulletHoleFadeTime

	if IsMelee then
		HitEffectEnabled = ClientModule.MeleeHitEffectEnabled
		HitSoundIDs = ClientModule.MeleeHitSoundIDs
		HitSoundPitchMin = ClientModule.MeleeHitSoundPitchMin
		HitSoundPitchMax = ClientModule.MeleeHitSoundPitchMax
		HitSoundVolume = ClientModule.MeleeHitSoundVolume
		CustomHitEffect = ClientModule.CustomMeleeHitEffect

		BulletHoleEnabled = ClientModule.MarkerEffectEnabled
		BulletHoleSize = ClientModule.MarkerEffectSize
		BulletHoleTexture = ClientModule.MarkerEffectTexture
		BulletHoleVisibleTime = ClientModule.MarkerEffectVisibleTime
		BulletHoleFadeTime = ClientModule.MarkerEffectFadeTime
		PartColor = ClientModule.MarkerPartColor
	end

	if not HitEffectEnabled then
		return
	end

	local hitEffectFolder = Miscs and Miscs.HitEffectFolder
	if not hitEffectFolder then
		return
	end

	local attachment = Instance.new("Attachment")
	attachment.CFrame = SurfaceCF
	attachment.Parent = Workspace.Terrain

	local function Spawner(materialEnum)
		local matFolder = GetMaterialFolder(hitEffectFolder, materialEnum)
		if not matFolder then
			return
		end

		-- Sound selection (material-specific overrides supported)
		local soundObj: Sound? = nil
		local matSounds = matFolder:FindFirstChild("MaterialSounds")
		if matSounds and matSounds:IsA("Folder") then
			local tracks = matSounds:GetChildren()
			if #tracks > 0 then
				local track = tracks[math.random(1, #tracks)]
				if track and track:IsA("Sound") then
					soundObj = track:Clone()
					local pitch = track:FindFirstChild("Pitch")
					if
						pitch
						and pitch:IsA("Folder")
						and pitch:FindFirstChild("Min")
						and pitch:FindFirstChild("Max")
					then
						soundObj.PlaybackSpeed = Random.new():NextNumber(pitch.Min.Value, pitch.Max.Value)
					else
						soundObj.PlaybackSpeed = Random.new():NextNumber(HitSoundPitchMin, HitSoundPitchMax)
					end
					local vol = track:FindFirstChild("Volume")
					if vol and vol:IsA("Folder") and vol:FindFirstChild("Min") and vol:FindFirstChild("Max") then
						soundObj.Volume = Random.new():NextNumber(vol.Min.Value, vol.Max.Value)
					else
						soundObj.Volume = HitSoundVolume
					end
					soundObj.Parent = attachment
				end
			end
		end

		if not soundObj then
			local chosenId = SafeRandomFromArray(HitSoundIDs)
			if chosenId then
				soundObj = Instance.new("Sound")
				soundObj.SoundId = "rbxassetid://" .. tostring(chosenId)
				soundObj.PlaybackSpeed = Random.new():NextNumber(HitSoundPitchMin, HitSoundPitchMax)
				soundObj.Volume = HitSoundVolume
				soundObj.Parent = attachment
			end
		end

		-- Particles
		for _, v in ipairs(matFolder:GetChildren()) do
			if v:IsA("ParticleEmitter") then
				local particle = v:Clone()
				particle.Parent = attachment

				local count = 1
				local emitCount = particle:FindFirstChild("EmitCount")
				if emitCount and emitCount:IsA("IntValue") then
					count = emitCount.Value
				end

				local partColorFlag = particle:FindFirstChild("PartColor")
				if partColorFlag and partColorFlag:IsA("BoolValue") and partColorFlag.Value then
					local hitPartColor = (Hit and Hit:IsA("BasePart")) and Hit.Color or Color3.fromRGB(255, 255, 255)
					if Hit and Hit:IsA("Terrain") then
						hitPartColor = Workspace.Terrain:GetMaterialColor(Material or Enum.Material.Sand)
					end
					particle.Color = ColorSequence.new(hitPartColor, hitPartColor)
				end

				EmitWithQuality(particle, count)
			end
		end

		if soundObj then
			soundObj:Play()
		end

		-- Bullet hole / decal
		if BulletHoleEnabled then
			local hole = Instance.new("Attachment")
			hole.Parent = ParentToPart and Hit or Workspace.Terrain
			hole.WorldCFrame = SurfaceCF * CFrame.Angles(math.rad(90), math.rad(180), 0)

			if ParentToPart and Hit then
				local scale = BulletHoleSize
				local matHoleSize = matFolder:FindFirstChild("MaterialHoleSize")
				if matHoleSize and matHoleSize:IsA("NumberValue") then
					scale = matHoleSize.Value
				end

				local a0 = Instance.new("Attachment")
				local a1 = Instance.new("Attachment")
				local beamClone = Beam:Clone()
				beamClone.Width0 = scale
				beamClone.Width1 = scale

				local matDecals = matFolder:FindFirstChild("MaterialDecals")
				if matDecals and matDecals:IsA("Folder") then
					local decals = matDecals:GetChildren()
					if #decals > 0 then
						local decal = decals[math.random(1, #decals)]
						if decal and decal:IsA("ValueBase") then
							beamClone.Texture = "rbxassetid://" .. tostring(decal.Value)
							local decalPartColorFlag = decal:FindFirstChild("PartColor")
							if
								decalPartColorFlag
								and decalPartColorFlag:IsA("BoolValue")
								and decalPartColorFlag.Value
							then
								local hitPartColor = (Hit and Hit:IsA("BasePart")) and Hit.Color
									or Color3.fromRGB(255, 255, 255)
								if Hit and Hit:IsA("Terrain") then
									hitPartColor = Workspace.Terrain:GetMaterialColor(Material or Enum.Material.Sand)
								end
								beamClone.Color = ColorSequence.new({
									ColorSequenceKeypoint.new(0, hitPartColor),
									ColorSequenceKeypoint.new(1, hitPartColor),
								})
							end
						end
					end
				else
					local chosenTex = SafeRandomFromArray(BulletHoleTexture)
					if chosenTex then
						beamClone.Texture = "rbxassetid://" .. tostring(chosenTex)
					end
					if PartColor then
						local hitPartColor = (Hit and Hit:IsA("BasePart")) and Hit.Color
							or Color3.fromRGB(255, 255, 255)
						if Hit and Hit:IsA("Terrain") then
							hitPartColor = Workspace.Terrain:GetMaterialColor(Material or Enum.Material.Sand)
						end
						beamClone.Color = ColorSequence.new({
							ColorSequenceKeypoint.new(0, hitPartColor),
							ColorSequenceKeypoint.new(1, hitPartColor),
						})
					end
				end

				beamClone.Attachment0 = a0
				beamClone.Attachment1 = a1

				a0.Parent = Hit
				a1.Parent = Hit
				a0.WorldCFrame = hole.WorldCFrame * CFrame.new(scale / 2, -0.01, 0) * CFrame.Angles(math.rad(90), 0, 0)
				a1.WorldCFrame = hole.WorldCFrame
					* CFrame.new(-scale / 2, -0.01, 0)
					* CFrame.Angles(math.rad(90), math.rad(180), 0)

				beamClone.Parent = Workspace.Terrain
				FadeAndDestroyBeamDecal(beamClone, a0, a1, hole, BulletHoleVisibleTime, BulletHoleFadeTime)
			else
				Debris:AddItem(hole, 5)
			end
		end
	end

	-- Use correct folder resolution without WaitForChild(EnumItem) (which errors).
	if not CustomHitEffect then
		Spawner((Hit and Hit.Material) or Material or Enum.Material.Plastic)
	else
		Spawner("Custom")
	end

	Debris:AddItem(attachment, 10)
end

local function MakeBloodFX(Hit, Position, Normal, Material, ParentToPart, ClientModule, Miscs, Replicate, IsMelee)
	local SurfaceCF = CFrame.new(Position, Position + Normal)

	local BloodEnabled = ClientModule.BloodEnabled
	local HitCharSndIDs = AddressTableValue(
		ClientModule.ChargedShotAdvanceEnabled,
		Miscs.ChargeLevel,
		ClientModule.ChargeAlterTable.HitCharSndIDs,
		ClientModule.HitCharSndIDs
	)
	local HitCharSndPitchMin = AddressTableValue(
		ClientModule.ChargedShotAdvanceEnabled,
		Miscs.ChargeLevel,
		ClientModule.ChargeAlterTable.HitCharSndPitchMin,
		ClientModule.HitCharSndPitchMin
	)
	local HitCharSndPitchMax = AddressTableValue(
		ClientModule.ChargedShotAdvanceEnabled,
		Miscs.ChargeLevel,
		ClientModule.ChargeAlterTable.HitCharSndPitchMax,
		ClientModule.HitCharSndPitchMax
	)
	local HitCharSndVolume = AddressTableValue(
		ClientModule.ChargedShotAdvanceEnabled,
		Miscs.ChargeLevel,
		ClientModule.ChargeAlterTable.HitCharSndVolume,
		ClientModule.HitCharSndVolume
	)

	local BloodWoundEnabled = ClientModule.BloodWoundEnabled
	local BloodWoundTexture = AddressTableValue(
		ClientModule.ChargedShotAdvanceEnabled,
		Miscs.ChargeLevel,
		ClientModule.ChargeAlterTable.BloodWoundTexture,
		ClientModule.BloodWoundTexture
	)
	local BloodWoundSize = AddressTableValue(
		ClientModule.ChargedShotAdvanceEnabled,
		Miscs.ChargeLevel,
		ClientModule.ChargeAlterTable.BloodWoundSize,
		ClientModule.BloodWoundSize
	)
	local BloodWoundTextureColor = AddressTableValue(
		ClientModule.ChargedShotAdvanceEnabled,
		Miscs.ChargeLevel,
		ClientModule.ChargeAlterTable.BloodWoundTextureColor,
		ClientModule.BloodWoundTextureColor
	)
	local BloodWoundPartColor = AddressTableValue(
		ClientModule.ChargedShotAdvanceEnabled,
		Miscs.ChargeLevel,
		ClientModule.ChargeAlterTable.BloodWoundPartColor,
		ClientModule.BloodWoundPartColor
	)
	local BloodWoundVisibleTime = ClientModule.BloodWoundVisibleTime
	local BloodWoundFadeTime = ClientModule.BloodWoundFadeTime

	if IsMelee then
		BloodEnabled = ClientModule.MeleeBloodEnabled
		HitCharSndIDs = ClientModule.MeleeHitCharSndIDs
		HitCharSndPitchMin = ClientModule.MeleeHitCharSndPitchMin
		HitCharSndPitchMax = ClientModule.MeleeHitCharSndPitchMax
		HitCharSndVolume = ClientModule.MeleeHitCharSndVolume

		-- FIX: these were incorrectly swapped in your version
		BloodWoundEnabled = ClientModule.MeleeBloodWoundEnabled
		BloodWoundTexture = ClientModule.MeleeBloodWoundTexture
		BloodWoundSize = ClientModule.MeleeBloodWoundSize
		BloodWoundTextureColor = ClientModule.MeleeBloodWoundTextureColor
		BloodWoundPartColor = ClientModule.MeleeBloodWoundPartColor
		BloodWoundVisibleTime = ClientModule.MeleeBloodWoundVisibleTime
		BloodWoundFadeTime = ClientModule.MeleeBloodWoundFadeTime
	end

	if not BloodEnabled then
		return
	end

	local bloodFolder = Miscs and Miscs.BloodEffectFolder
	if not bloodFolder then
		return
	end

	local attachment = Instance.new("Attachment")
	attachment.CFrame = SurfaceCF
	attachment.Parent = Workspace.Terrain

	local chosenId = SafeRandomFromArray(HitCharSndIDs)
	if chosenId then
		local sound = Instance.new("Sound")
		sound.SoundId = "rbxassetid://" .. tostring(chosenId)
		sound.PlaybackSpeed = Random.new():NextNumber(HitCharSndPitchMin, HitCharSndPitchMax)
		sound.Volume = HitCharSndVolume
		sound.Parent = attachment
		sound:Play()
	end

	for _, v in ipairs(bloodFolder:GetChildren()) do
		if v:IsA("ParticleEmitter") then
			local particle = v:Clone()
			particle.Parent = attachment

			local count = 1
			local emitCount = particle:FindFirstChild("EmitCount")
			if emitCount and emitCount:IsA("IntValue") then
				count = emitCount.Value
			end

			EmitWithQuality(particle, count)
		end
	end

	Debris:AddItem(attachment, 10)

	if BloodWoundEnabled then
		local hole = Instance.new("Attachment")
		hole.Parent = ParentToPart and Hit or Workspace.Terrain
		hole.WorldCFrame = SurfaceCF * CFrame.Angles(math.rad(90), math.rad(180), 0)

		if ParentToPart and Hit then
			local a0 = Instance.new("Attachment")
			local a1 = Instance.new("Attachment")
			local beamClone = Beam:Clone()

			beamClone.Width0 = BloodWoundSize
			beamClone.Width1 = BloodWoundSize

			local chosenTex = SafeRandomFromArray(BloodWoundTexture)
			if chosenTex then
				beamClone.Texture = "rbxassetid://" .. tostring(chosenTex)
			end

			beamClone.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, BloodWoundTextureColor),
				ColorSequenceKeypoint.new(1, BloodWoundTextureColor),
			})

			if BloodWoundPartColor then
				local hitPartColor = (Hit and Hit:IsA("BasePart")) and Hit.Color or Color3.fromRGB(255, 255, 255)
				if Hit and Hit:IsA("Terrain") then
					hitPartColor = Workspace.Terrain:GetMaterialColor(Material or Enum.Material.Sand)
				end
				beamClone.Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, hitPartColor),
					ColorSequenceKeypoint.new(1, hitPartColor),
				})
			end

			beamClone.Attachment0 = a0
			beamClone.Attachment1 = a1

			a0.Parent = Hit
			a1.Parent = Hit
			a0.WorldCFrame = hole.WorldCFrame
				* CFrame.new(BloodWoundSize / 2, -0.01, 0)
				* CFrame.Angles(math.rad(90), 0, 0)
			a1.WorldCFrame = hole.WorldCFrame
				* CFrame.new(-BloodWoundSize / 2, -0.01, 0)
				* CFrame.Angles(math.rad(90), math.rad(180), 0)

			beamClone.Parent = Workspace.Terrain
			FadeAndDestroyBeamDecal(beamClone, a0, a1, hole, BloodWoundVisibleTime, BloodWoundFadeTime)
		else
			Debris:AddItem(hole, 5)
		end
	end
end

local function ShouldShowEffects(Position: Vector3)
	local camPos = Camera.CFrame.Position
	local distOk = (Position - camPos).Magnitude <= RenderDistance
	if not distOk then
		return false
	end
	if not ScreenCullingEnabled then
		return true
	end
	return ScreenCulling(Position, ScreenCullingRadius)
end

local function OnRayHit(Origin, Direction, Hit, Position, Normal, Material, Tool, ClientModule, Miscs, Replicate)
	if not Hit or not Hit.Parent then
		return
	end

	local showEffects = ShouldShowEffects(Position)

	if
		not AddressTableValue(
			ClientModule.ChargedShotAdvanceEnabled,
			Miscs.ChargeLevel,
			ClientModule.ChargeAlterTable.ExplosiveEnabled,
			ClientModule.ExplosiveEnabled
		)
	then
		local parentModel = Hit:FindFirstAncestorOfClass("Model")
		if parentModel and parentModel.Name == "Windows" then
			return
		end

		-- Vehicle damage block (guard remote existence)
		do
			local body = Hit:FindFirstAncestor("Body")
			if body then
				local car = body:FindFirstAncestorWhichIsA("Model")
				local myVehicle = GetSeatedVehicleModel((Tool and Tool.Parent) :: any)
				if myVehicle and car and car == myVehicle then
					return
				end
				local carHealth = car and car:FindFirstChild("Health")
				local damageRemote = ReplicatedStorage.Remotes:FindFirstChild("CarDamageRemote")
				if car and carHealth and damageRemote and damageRemote:IsA("RemoteEvent") then
					if Tool and Tool:IsA("Tool") then
						local settingsModule = Tool:FindFirstChild("Setting") and Tool.Setting:FindFirstChild("1")
						if settingsModule then
							local moduleOk, Module = pcall(require, settingsModule)
							if moduleOk and Module and Module.BaseDamage then
								damageRemote:FireServer(car, Module.BaseDamage)
							end
						end
					end
				end
			end
		end
		local distance = (Position - Origin).Magnitude
		local target = Hit:FindFirstAncestorOfClass("Model")
		local targetHumanoid = target and target:FindFirstChildOfClass("Humanoid")
		local targetTorso = target and (target:FindFirstChild("HumanoidRootPart") or target:FindFirstChild("Head"))

		if targetHumanoid and targetTorso then
			if showEffects then
				MakeBloodFX(Hit, Position, Normal, Material, true, ClientModule, Miscs, Replicate)
			end
			if Replicate then
				Thread:Spawn(function()
					InflictTarget:InvokeServer(
						"Gun",
						Tool,
						ClientModule,
						targetHumanoid,
						targetTorso,
						Hit,
						Miscs,
						distance
					)
				end)

				if Tool and Tool:FindFirstChild("GunClient") and Tool.GunClient:FindFirstChild("MarkerEvent") then
					Tool.GunClient.MarkerEvent:Fire(ClientModule, Hit.Name == "Head" and ClientModule.HeadshotEnabled)
				end

				-- Keep your vest logic intact, but guard nils
				if Tool and Tool:FindFirstChild("GunClient") and Tool.GunClient:FindFirstChild("VestEvent") then
					local vestHealth = Hit.Parent and Hit.Parent:FindFirstChild("VestHealth")
					if vestHealth and vestHealth.Value >= 1 then
						Tool.GunClient.VestEvent:Fire(
							ClientModule,
							Hit.Name == "UpperTorso" and ClientModule.HeadshotEnabled
						)
					end
					local targetVest = targetHumanoid.Parent and targetHumanoid.Parent:FindFirstChild("VestHealth")
					if targetVest and targetVest.Value == 0 then
						if Tool.GunClient:FindFirstChild("BreakVestEvent") then
							Tool.GunClient.BreakVestEvent:Fire()
						end
						targetVest:Destroy()
						if targetHumanoid.Parent:FindFirstChild("_Vest") then
							local part = targetHumanoid.Parent:FindFirstChild("UpperTorso")
							if part then
								local vestRemote = ReplicatedStorage:FindFirstChild("Remotes")
									and ReplicatedStorage.Remotes:FindFirstChild("Vest")
								if vestRemote and vestRemote:IsA("RemoteEvent") then
									vestRemote:FireServer(part)
								end
							end
						end
					end
				end
			end
		else
			if showEffects then
				MakeImpactFX(Hit, Position, Normal, Material, true, ClientModule, Miscs, Replicate)
			end
		end

		return
	end

	-- Explosive
	if ClientModule.ExplosionSoundEnabled then
		local soundTable = AddressTableValue(
			ClientModule.ChargedShotAdvanceEnabled,
			Miscs.ChargeLevel,
			ClientModule.ChargeAlterTable.ExplosionSoundIDs,
			ClientModule.ExplosionSoundIDs
		)
		local chosen = SafeRandomFromArray(soundTable)
		if chosen then
			local att = Instance.new("Attachment")
			att.CFrame = CFrame.new(Position)
			att.Parent = Workspace.Terrain

			local sound = Instance.new("Sound")
			sound.SoundId = "rbxassetid://" .. tostring(chosen)
			sound.PlaybackSpeed = Random.new():NextNumber(
				AddressTableValue(
					ClientModule.ChargedShotAdvanceEnabled,
					Miscs.ChargeLevel,
					ClientModule.ChargeAlterTable.ExplosionSoundPitchMin,
					ClientModule.ExplosionSoundPitchMin
				),
				AddressTableValue(
					ClientModule.ChargedShotAdvanceEnabled,
					Miscs.ChargeLevel,
					ClientModule.ChargeAlterTable.ExplosionSoundPitchMax,
					ClientModule.ExplosionSoundPitchMax
				)
			)
			sound.Volume = AddressTableValue(
				ClientModule.ChargedShotAdvanceEnabled,
				Miscs.ChargeLevel,
				ClientModule.ChargeAlterTable.ExplosionSoundVolume,
				ClientModule.ExplosionSoundVolume
			)
			sound.Parent = att
			sound:Play()
			Debris:AddItem(att, 10)
		end
	end

	local explosion = Instance.new("Explosion")
	explosion.BlastRadius = AddressTableValue(
		ClientModule.ChargedShotAdvanceEnabled,
		Miscs.ChargeLevel,
		ClientModule.ChargeAlterTable.ExplosionRadius,
		ClientModule.ExplosionRadius
	)
	explosion.BlastPressure = 0
	explosion.ExplosionType = Enum.ExplosionType.NoCraters
	explosion.Position = Position
	explosion.Parent = Camera

	local surfaceCF = CFrame.new(Position, Position + Normal)

	if ClientModule.CustomExplosion then
		explosion.Visible = false
		if showEffects then
			local att = Instance.new("Attachment")
			att.CFrame = surfaceCF
			att.Parent = Workspace.Terrain

			local fxFolder = Miscs and Miscs.ExplosionEffectFolder
			if fxFolder then
				for _, v in ipairs(fxFolder:GetChildren()) do
					if v:IsA("ParticleEmitter") then
						local particle = v:Clone()
						particle.Parent = att

						local count = 1
						local emitCount = particle:FindFirstChild("EmitCount")
						if emitCount and emitCount:IsA("IntValue") then
							count = emitCount.Value
						end

						EmitWithQuality(particle, count)
					end
				end
			end

			Debris:AddItem(att, 10)
		end
	end

	local hitHumanoids = {}

	explosion.Hit:Connect(function(hitPart, hitDist)
		if not Replicate or not hitPart then
			return
		end

		-- FIX: precedence/parent guard
		if hitPart.Parent and (hitPart.Name == "HumanoidRootPart" or hitPart.Name == "Head") then
			local target = hitPart:FindFirstAncestorOfClass("Model")
			local targetHumanoid = target and target:FindFirstChildOfClass("Humanoid")
			local targetTorso = target and (target:FindFirstChild("HumanoidRootPart") or target:FindFirstChild("Head"))

			if targetHumanoid and targetTorso and not hitHumanoids[targetHumanoid] then
				if ClientModule.ExplosionKnockback then
					local multipler = AddressTableValue(
						ClientModule.ChargedShotAdvanceEnabled,
						Miscs.ChargeLevel,
						ClientModule.ChargeAlterTable.ExplosionKnockbackMultiplierOnTarget,
						ClientModule.ExplosionKnockbackMultiplierOnTarget
					)
					local velocityMod = (targetTorso.Position - explosion.Position).Unit
						* AddressTableValue(
							ClientModule.ChargedShotAdvanceEnabled,
							Miscs.ChargeLevel,
							ClientModule.ChargeAlterTable.ExplosionKnockbackPower,
							ClientModule.ExplosionKnockbackPower
						)

					local airVelocity = targetTorso.Velocity
						- Vector3.new(0, targetTorso.Velocity.Y, 0)
						+ Vector3.new(velocityMod.X, 0, velocityMod.Z)

					if DamageModule.CanDamage(target, Tool.Parent, ClientModule.FriendlyFire) then
						local torsoFly = Instance.new("BodyVelocity")
						torsoFly.MaxForce = Vector3.new(math.huge, 0, math.huge)
						torsoFly.Velocity = airVelocity
						torsoFly.Parent = targetTorso
						targetTorso.Velocity = targetTorso.Velocity + Vector3.new(0, velocityMod.Y * multipler, 0)
						Debris:AddItem(torsoFly, 0.25)
					else
						if targetHumanoid.Parent and targetHumanoid.Parent.Name == Player.Name then
							multipler = AddressTableValue(
								ClientModule.ChargedShotAdvanceEnabled,
								Miscs.ChargeLevel,
								ClientModule.ChargeAlterTable.ExplosionKnockbackMultiplierOnPlayer,
								ClientModule.ExplosionKnockbackMultiplierOnPlayer
							)
							local torsoFly = Instance.new("BodyVelocity")
							torsoFly.MaxForce = Vector3.new(math.huge, 0, math.huge)
							torsoFly.Velocity = airVelocity
							torsoFly.Parent = targetTorso
							targetTorso.Velocity = targetTorso.Velocity + Vector3.new(0, velocityMod.Y * multipler, 0)
							Debris:AddItem(torsoFly, 0.25)
						end
					end
				end

				Thread:Spawn(function()
					InflictTarget:InvokeServer(
						"Gun",
						Tool,
						ClientModule,
						targetHumanoid,
						targetTorso,
						Hit,
						Miscs,
						hitDist
					)
				end)

				if Tool and Tool:FindFirstChild("GunClient") and Tool.GunClient:FindFirstChild("MarkerEvent") then
					Tool.GunClient.MarkerEvent:Fire(ClientModule, Hit.Name == "Head" and ClientModule.HeadshotEnabled)
				end

				hitHumanoids[targetHumanoid] = true
			end
		elseif hitPart.Name == "_glass" then
			ShatterGlass:FireServer(hitPart, hitPart.Position, Direction)
		end
	end)
end

local function OnRayBounced(
	Origin,
	Direction,
	Hit,
	Position,
	Normal,
	Material,
	Tool,
	ClientModule,
	Miscs,
	NoExplosion,
	Replicate
)
	if not Hit or not Hit.Parent then
		return
	end

	local showEffects = ShouldShowEffects(Position)

	if
		not AddressTableValue(
			ClientModule.ChargedShotAdvanceEnabled,
			Miscs.ChargeLevel,
			ClientModule.ChargeAlterTable.ExplosiveEnabled,
			ClientModule.ExplosiveEnabled
		)
	then
		if Hit.Name == "_glass" then
			if Replicate then
				ShatterGlass:FireServer(Hit, Position, Direction)
			end
			return
		end

		local distance = (Position - Origin).Magnitude
		local target = Hit:FindFirstAncestorOfClass("Model")
		local targetHumanoid = target and target:FindFirstChildOfClass("Humanoid")
		local targetTorso = target and (target:FindFirstChild("HumanoidRootPart") or target:FindFirstChild("Head"))

		if targetHumanoid and targetTorso then
			if showEffects then
				MakeBloodFX(Hit, Position, Normal, Material, true, ClientModule, Miscs, Replicate)
			end
			if Replicate then
				Thread:Spawn(function()
					InflictTarget:InvokeServer(
						"Gun",
						Tool,
						ClientModule,
						targetHumanoid,
						targetTorso,
						Hit,
						Miscs,
						distance
					)
				end)
				if Tool and Tool:FindFirstChild("GunClient") and Tool.GunClient:FindFirstChild("MarkerEvent") then
					Tool.GunClient.MarkerEvent:Fire(ClientModule, Hit.Name == "Head" and ClientModule.HeadshotEnabled)
				end
			end
		else
			if showEffects then
				MakeImpactFX(Hit, Position, Normal, Material, true, ClientModule, Miscs, Replicate)
			end
		end
		return
	end

	-- Explosive bounce
	if NoExplosion then
		if Hit.Name == "_glass" then
			if Replicate then
				ShatterGlass:FireServer(Hit, Position, Direction)
			end
			return
		end

		local distance = (Position - Origin).Magnitude
		local target = Hit:FindFirstAncestorOfClass("Model")
		local targetHumanoid = target and target:FindFirstChildOfClass("Humanoid")
		local targetTorso = target and (target:FindFirstChild("HumanoidRootPart") or target:FindFirstChild("Head"))

		if targetHumanoid and targetTorso then
			if showEffects then
				MakeBloodFX(Hit, Position, Normal, Material, true, ClientModule, Miscs, Replicate)
			end
			if Replicate then
				Thread:Spawn(function()
					InflictTarget:InvokeServer(
						"Gun",
						Tool,
						ClientModule,
						targetHumanoid,
						targetTorso,
						Hit,
						Miscs,
						distance
					)
				end)
				if Tool and Tool:FindFirstChild("GunClient") and Tool.GunClient:FindFirstChild("MarkerEvent") then
					Tool.GunClient.MarkerEvent:Fire(ClientModule, Hit.Name == "Head" and ClientModule.HeadshotEnabled)
				end
			end
		else
			if showEffects then
				MakeImpactFX(Hit, Position, Normal, Material, true, ClientModule, Miscs, Replicate)
			end
		end
		return
	end

	-- If not NoExplosion, reuse the same explosion path by calling OnRayHit explosive branch:
	OnRayHit(Origin, Direction, Hit, Position, Normal, Material, Tool, ClientModule, Miscs, Replicate)
end

local function OnRayPenetrated(Origin, Direction, Hit, Position, Normal, Material, Tool, ClientModule, Miscs, Replicate)
	if not Hit or not Hit.Parent then
		return
	end

	local showEffects = ShouldShowEffects(Position)

	if Hit.Name == "_glass" then
		if Replicate then
			ShatterGlass:FireServer(Hit, Position, Direction)
		end
		return
	end

	local distance = (Position - Origin).Magnitude
	local target = Hit:FindFirstAncestorOfClass("Model")
	local targetHumanoid = target and target:FindFirstChildOfClass("Humanoid")
	local targetTorso = target and (target:FindFirstChild("HumanoidRootPart") or target:FindFirstChild("Head"))

	if targetHumanoid and targetTorso then
		if showEffects then
			MakeBloodFX(Hit, Position, Normal, Material, true, ClientModule, Miscs, Replicate)
		end
		if Replicate then
			Thread:Spawn(function()
				InflictTarget:InvokeServer("Gun", Tool, ClientModule, targetHumanoid, targetTorso, Hit, Miscs, distance)
			end)
			if Tool and Tool:FindFirstChild("GunClient") and Tool.GunClient:FindFirstChild("MarkerEvent") then
				Tool.GunClient.MarkerEvent:Fire(ClientModule, Hit.Name == "Head" and ClientModule.HeadshotEnabled)
			end
		end
	else
		if showEffects then
			MakeImpactFX(Hit, Position, Normal, Material, true, ClientModule, Miscs, Replicate)
		end
	end
end

local function OnRayExited(Origin, Direction, Hit, Position, Normal, Material, Tool, ClientModule, Miscs, Replicate)
	if not Hit or not Hit.Parent then
		return
	end

	local showEffects = ShouldShowEffects(Position)
	if not showEffects then
		return
	end

	local target = Hit:FindFirstAncestorOfClass("Model")
	local targetHumanoid = target and target:FindFirstChildOfClass("Humanoid")
	local targetTorso = target and (target:FindFirstChild("HumanoidRootPart") or target:FindFirstChild("Head"))

	if targetHumanoid and targetTorso then
		MakeBloodFX(Hit, Position, Normal, Material, true, ClientModule, Miscs, Replicate)
	else
		MakeImpactFX(Hit, Position, Normal, Material, true, ClientModule, Miscs, Replicate)
	end
end

function ProjectileHandler:VisualizeHitEffect(Type, Hit, Position, Normal, Material, ClientModule, Miscs, Replicate)
	if Replicate then
		VisualizeHitEffect:FireServer(Type, Hit, Position, Normal, Material, ClientModule, Miscs, nil)
	end

	if not ShouldShowEffects(Position) then
		return
	end

	if Type == "Normal" then
		MakeImpactFX(Hit, Position, Normal, Material, true, ClientModule, Miscs, Replicate, true)
	elseif Type == "Blood" then
		MakeBloodFX(Hit, Position, Normal, Material, true, ClientModule, Miscs, Replicate, true)
	end
end

function ProjectileHandler:SimulateProjectile(
	Tool,
	Handle,
	VMHandle,
	ClientModule,
	CLDirections,
	SVDirections,
	FirePointObject,
	MuzzlePointObject,
	Miscs,
	Replicate
)
	if not (ClientModule and Tool and Handle) then
		return
	end

	if Replicate then
		VisualizeBullet:FireServer(
			Tool,
			Handle,
			nil,
			ClientModule,
			nil,
			SVDirections,
			FirePointObject,
			MuzzlePointObject,
			Miscs,
			nil
		)
	end

	local muzzleObject = MuzzlePointObject
	local directions = SVDirections

	if VMHandle ~= nil then
		local vmMuzzle = VMHandle:FindFirstChild("GunMuzzlePoint" .. ClientModule.ModuleName)
		if vmMuzzle then
			muzzleObject = vmMuzzle
		end
		directions = CLDirections
	end

	if ClientModule.MuzzleFlashEnabled and muzzleObject and Miscs and Miscs.MuzzleFolder then
		for _, v in ipairs(Miscs.MuzzleFolder:GetChildren()) do
			if v:IsA("ParticleEmitter") then
				local particle = v:Clone()
				particle.Parent = muzzleObject

				local count = 1
				local emitCount = particle:FindFirstChild("EmitCount")
				if emitCount and emitCount:IsA("IntValue") then
					count = emitCount.Value
				end

				Thread:Delay(0.01, function()
					particle:Emit(count)
					Debris:AddItem(particle, particle.Lifetime.Max)
				end)
			end
		end
	end

	if ClientModule.MuzzleLightEnabled and muzzleObject then
		local light = Instance.new("PointLight")
		light.Brightness = AddressTableValue(
			ClientModule.ChargedShotAdvanceEnabled,
			Miscs.ChargeLevel,
			ClientModule.ChargeAlterTable.LightBrightness,
			ClientModule.LightBrightness
		)
		light.Color = AddressTableValue(
			ClientModule.ChargedShotAdvanceEnabled,
			Miscs.ChargeLevel,
			ClientModule.ChargeAlterTable.LightColor,
			ClientModule.LightColor
		)
		light.Range = AddressTableValue(
			ClientModule.ChargedShotAdvanceEnabled,
			Miscs.ChargeLevel,
			ClientModule.ChargeAlterTable.LightRange,
			ClientModule.LightRange
		)
		light.Shadows = ClientModule.LightShadows
		light.Enabled = true
		light.Parent = muzzleObject
		Debris:AddItem(light, ClientModule.VisibleTime)
	end

	for _, direction in pairs(directions) do
		if FirePointObject == nil then
			continue
		end

		local cfrm = FirePointObject.WorldCFrame
		local origin = FirePointObject.WorldPosition
		local dir = direction

		if VMHandle ~= nil then
			local vmFire = VMHandle:FindFirstChild("GunFirePoint" .. ClientModule.ModuleName)
			if vmFire then
				cfrm = vmFire.WorldCFrame
				origin = vmFire.WorldPosition
			end
		end

		local filterList = { Camera, Tool, Tool.parent }

		AppendSeatedVehicleToIgnore(filterList, Tool.Parent)
		for i, v in pairs(CollectionService:GetTagged("NoShoot")) do
			table.insert(filterList, v)
		end

		local raycastParams = RaycastParams.new()
		raycastParams.FilterDescendantsInstances = filterList
		raycastParams.FilterType = Enum.RaycastFilterType.Exclude

		-- FIX: guard HumanoidRootPart usage
		local humanoidRootPart = Tool.Parent and Tool.Parent:FindFirstChild("HumanoidRootPart")
		if humanoidRootPart and humanoidRootPart:IsA("BasePart") then
			local tipCFrame = cfrm
			local tipPos = tipCFrame.Position
			local tipDir = tipCFrame.LookVector
			local amountToCheatBack = math.abs((humanoidRootPart.Position - tipPos):Dot(tipDir)) + 1

			local result = Workspace:Raycast(
				tipPos - tipDir.Unit * amountToCheatBack,
				tipDir.Unit * amountToCheatBack,
				raycastParams
			)
			if result and result.Instance and math.abs((tipPos - result.Position).Magnitude) > 0 then
				origin = result.Position - tipDir.Unit * 0.1
			end
		end

		local vel = dir
			* AddressTableValue(
				ClientModule.ChargedShotAdvanceEnabled,
				Miscs.ChargeLevel,
				ClientModule.ChargeAlterTable.BulletSpeed,
				ClientModule.BulletSpeed
			)

		ParticleFramework.new({
			position = origin,
			velocity = vel,
			acceleration = AddressTableValue(
				ClientModule.ChargedShotAdvanceEnabled,
				Miscs.ChargeLevel,
				ClientModule.ChargeAlterTable.BulletAcceleration,
				ClientModule.BulletAcceleration
			),
			visible = AddressTableValue(
				ClientModule.ChargedShotAdvanceEnabled,
				Miscs.ChargeLevel,
				ClientModule.ChargeAlterTable.VisibleBullet,
				ClientModule.VisibleBullet
			),
			motionblur = AddressTableValue(
				ClientModule.ChargedShotAdvanceEnabled,
				Miscs.ChargeLevel,
				ClientModule.ChargeAlterTable.MotionBlur,
				ClientModule.MotionBlur
			),
			size = AddressTableValue(
				ClientModule.ChargedShotAdvanceEnabled,
				Miscs.ChargeLevel,
				ClientModule.ChargeAlterTable.BulletSize,
				ClientModule.BulletSize
			),
			bloom = AddressTableValue(
				ClientModule.ChargedShotAdvanceEnabled,
				Miscs.ChargeLevel,
				ClientModule.ChargeAlterTable.BulletBloom,
				ClientModule.BulletBloom
			),
			brightness = AddressTableValue(
				ClientModule.ChargedShotAdvanceEnabled,
				Miscs.ChargeLevel,
				ClientModule.ChargeAlterTable.BulletBrightness,
				ClientModule.BulletBrightness
			),
			windspeed = AddressTableValue(
				ClientModule.ChargedShotAdvanceEnabled,
				Miscs.ChargeLevel,
				ClientModule.ChargeAlterTable.WindSpeed,
				ClientModule.WindSpeed
			),
			windresistance = AddressTableValue(
				ClientModule.ChargedShotAdvanceEnabled,
				Miscs.ChargeLevel,
				ClientModule.ChargeAlterTable.WindResistance,
				ClientModule.WindResistance
			),
			life = AddressTableValue(
				ClientModule.ChargedShotAdvanceEnabled,
				Miscs.ChargeLevel,
				ClientModule.ChargeAlterTable.BulletLifetime,
				ClientModule.BulletLifetime
			),
			visualorigin = origin,
			visualdirection = dir,
			penetrationtype = ClientModule.PenetrationType,
			penetrationdepth = AddressTableValue(
				ClientModule.ChargedShotAdvanceEnabled,
				Miscs.ChargeLevel,
				ClientModule.ChargeAlterTable.PenetrationDepth,
				ClientModule.PenetrationDepth
			),
			penetrationamount = AddressTableValue(
				ClientModule.ChargedShotAdvanceEnabled,
				Miscs.ChargeLevel,
				ClientModule.ChargeAlterTable.PenetrationAmount,
				ClientModule.PenetrationAmount
			),
			ricochetamount = AddressTableValue(
				ClientModule.ChargedShotAdvanceEnabled,
				Miscs.ChargeLevel,
				ClientModule.ChargeAlterTable.RicochetAmount,
				ClientModule.RicochetAmount
			),
			bounceelasticity = AddressTableValue(
				ClientModule.ChargedShotAdvanceEnabled,
				Miscs.ChargeLevel,
				ClientModule.ChargeAlterTable.BounceElasticity,
				ClientModule.BounceElasticity
			),
			frictionconstant = AddressTableValue(
				ClientModule.ChargedShotAdvanceEnabled,
				Miscs.ChargeLevel,
				ClientModule.ChargeAlterTable.FrictionConstant,
				ClientModule.FrictionConstant
			),
			noexplosionwhilebouncing = AddressTableValue(
				ClientModule.ChargedShotAdvanceEnabled,
				Miscs.ChargeLevel,
				ClientModule.ChargeAlterTable.NoExplosionWhileBouncing,
				ClientModule.NoExplosionWhileBouncing
			),
			stopbouncingonhithumanoid = AddressTableValue(
				ClientModule.ChargedShotAdvanceEnabled,
				Miscs.ChargeLevel,
				ClientModule.ChargeAlterTable.StopBouncingOnHitHumanoid,
				ClientModule.StopBouncingOnHitHumanoid
			),
			superricochet = AddressTableValue(
				ClientModule.ChargedShotAdvanceEnabled,
				Miscs.ChargeLevel,
				ClientModule.ChargeAlterTable.SuperRicochet,
				ClientModule.SuperRicochet
			),
			bullettype = AddressTableValue(
				ClientModule.ChargedShotAdvanceEnabled,
				Miscs.ChargeLevel,
				ClientModule.ChargeAlterTable.BulletType,
				ClientModule.BulletType
			),
			projectiletype = AddressTableValue(
				ClientModule.ChargedShotAdvanceEnabled,
				Miscs.ChargeLevel,
				ClientModule.ChargeAlterTable.ProjectileType,
				ClientModule.ProjectileType
			),
			canspinpart = ClientModule.CanSpinPart,
			spinx = AddressTableValue(
				ClientModule.ChargedShotAdvanceEnabled,
				Miscs.ChargeLevel,
				ClientModule.ChargeAlterTable.SpinX,
				ClientModule.SpinX
			),
			spiny = AddressTableValue(
				ClientModule.ChargedShotAdvanceEnabled,
				Miscs.ChargeLevel,
				ClientModule.ChargeAlterTable.SpinY,
				ClientModule.SpinY
			),
			spinz = AddressTableValue(
				ClientModule.ChargedShotAdvanceEnabled,
				Miscs.ChargeLevel,
				ClientModule.ChargeAlterTable.SpinZ,
				ClientModule.SpinZ
			),
			homing = AddressTableValue(
				ClientModule.ChargedShotAdvanceEnabled,
				Miscs.ChargeLevel,
				ClientModule.ChargeAlterTable.Homing,
				ClientModule.Homing
			),
			homingdistance = AddressTableValue(
				ClientModule.ChargedShotAdvanceEnabled,
				Miscs.ChargeLevel,
				ClientModule.ChargeAlterTable.HomingDistance,
				ClientModule.HomingDistance
			),
			turnratepersecond = AddressTableValue(
				ClientModule.ChargedShotAdvanceEnabled,
				Miscs.ChargeLevel,
				ClientModule.ChargeAlterTable.TurnRatePerSecond,
				ClientModule.TurnRatePerSecond
			),
			homethroughwall = AddressTableValue(
				ClientModule.ChargedShotAdvanceEnabled,
				Miscs.ChargeLevel,
				ClientModule.ChargeAlterTable.HomeThroughWall,
				ClientModule.HomeThroughWall
			),
			lockononhovering = ClientModule.LockOnOnHovering,
			lockedentity = Miscs.LockedEntity,
			toucheventontimeout = AddressTableValue(
				ClientModule.ChargedShotAdvanceEnabled,
				Miscs.ChargeLevel,
				ClientModule.ChargeAlterTable.TouchEventOnTimeout,
				ClientModule.TouchEventOnTimeout
			),
			hitscan = ClientModule.HitscanMode,
			character = Tool.Parent,
			friendlyfire = ClientModule.FriendlyFire,
			physicsignore = raycastParams.FilterDescendantsInstances,

			ontouch = function(self, part, pos, norm, material)
				OnRayHit(origin, dir, part, pos, norm, material, Tool, ClientModule, Miscs, Replicate)
			end,

			onenter = function(self, part, pos, norm, material, exited)
				OnRayPenetrated(origin, dir, part, pos, norm, material, Tool, ClientModule, Miscs, Replicate)
			end,

			onexit = function(self, exitpart, exitpos, exitnorm, exitmaterial)
				OnRayExited(
					origin,
					dir,
					exitpart,
					exitpos,
					exitnorm,
					exitmaterial,
					Tool,
					ClientModule,
					Miscs,
					Replicate
				)
			end,

			onbounce = function(self, part, pos, norm, material, noexplosion)
				OnRayBounced(origin, dir, part, pos, norm, material, Tool, ClientModule, Miscs, noexplosion, Replicate)
			end,

			onstep = function(part, dt)
				if not ClientModule.WhizSoundEnabled then
					return
				end
				if Replicate then
					return
				end

				local vel2 = part.velocity
				local dpos = dt * vel2
				local pos2 = part.position - dpos
				local headpos = Camera.CFrame.Position

				local denom = Vector3.new().Dot(dpos, dpos)
				if denom <= 0 then
					return
				end

				local d = Vector3.new().Dot(headpos - pos2, dpos) / denom
				if d > 0 and d < 1 then
					local dist = (pos2 + d * dpos - headpos).Magnitude
					dist = dist < 2 and 2 or dist
					if dist < ClientModule.WhizDistance then
						local whizId = SafeRandomFromArray(ClientModule.WhizSoundID)
						if not whizId then
							return
						end

						local sound = Instance.new("Sound")
						sound.SoundId = "rbxassetid://" .. tostring(whizId)
						sound.Volume = ClientModule.WhizSoundVolume
						sound.PlaybackSpeed =
							Random.new():NextNumber(ClientModule.WhizSoundPitchMin, ClientModule.WhizSoundPitchMax)
						sound.Parent = SoundService
						sound:Play()
						Debris:AddItem(sound, sound.TimeLength / math.max(sound.PlaybackSpeed, 0.01))
					end
				end
			end,
		})
	end
end

return ProjectileHandler
