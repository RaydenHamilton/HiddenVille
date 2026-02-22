local Debris = game:GetService("Debris")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local Miscs = ReplicatedStorage:WaitForChild("Miscs")
local Modules = ReplicatedStorage:WaitForChild("Modules")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

--local GlassShattering = require(Modules.GlassShattering)
local DamageModule = require(Modules.DamageModule)

local PlayAudio = Remotes.PlayAudio
local VisualizeHitEffect = Remotes.VisualizeHitEffect
local VisualizeBullet = Remotes.VisualizeBullet
local VisualizeGore = Remotes.VisualizeGore
local ShatterGlass = Remotes.ShatterGlass
local InflictTarget = Remotes.InflictTarget
local RegenTime = 180
_G.TempBannedPlayers = {}

local KickPlayer = true
local PhysicEffect = true --For base parts (blocks) only (Glass shattering)

-- Blood splatter related variables
local splatids = { "" } -- Update this list with valid decal IDs
local CivCars = Workspace:WaitForChild("CivCars")

local function getSeatedCarModel(character)
	if not character then
		return nil
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return nil
	end

	local seat = humanoid.SeatPart
	if not seat or not (seat:IsA("Seat") or seat:IsA("VehicleSeat")) then
		return nil
	end

	local cur = seat
	while cur and cur ~= CivCars do
		if cur:IsA("Model") and cur.Parent == CivCars then
			return cur
		end
		cur = cur.Parent
	end
	return nil
end

-- Function to spawn blood splatters with a random chance
local function spawnBloodSplat(position, normal)
	-- Define the spawn chance (e.g., 50%)
	local spawnChance = 0.5

	-- Generate a random number between 0 and 1
	if math.random() <= spawnChance then
		-- Only spawn the blood splat if the random number is less than or equal to spawnChance
		local splatPart = Instance.new("Part")
		splatPart.Size = Vector3.new(7, 7)
		splatPart.Transparency = 1
		splatPart.CanCollide = false
		splatPart.Material = "SmoothPlastic"
		splatPart.CanTouch = false
		splatPart.CanQuery = false
		splatPart.Anchored = true

		local decal = Instance.new("Decal", splatPart)
		decal.Texture = "rbxassetid://" .. splatids[math.random(1, #splatids)] -- Random decal ID
		decal.Color3 = Color3.fromRGB(110, 0, 0)
		decal.Transparency = 0

		-- Align the part to the hit surface
		splatPart.CFrame = CFrame.new(position, position + normal)

		-- Add the blood splat to the workspace
		splatPart.Parent = workspace

		-- Clean up after 10 seconds
		Debris:AddItem(splatPart, 8)
	end
end

-- Function to spawn blood in multiple directions from the hit position
local function spawnBloodInAllDirections(hitPart, hitPosition, hitNormal)
	-- Define the directions to cast rays (backward, forward, left, right, up, down)
	local directions = {
		Vector3.new(-1, 0, 0), -- Left
		Vector3.new(1, 0, 0), -- Right
		Vector3.new(0, -1, 0), -- Down
		Vector3.new(0, 1, 0), -- Up
		Vector3.new(0, 0, -1), -- Backward
		Vector3.new(0, 0, 1), -- Forward
	}

	-- Raycast parameters
	local raycastParams = RaycastParams.new()
	raycastParams.FilterDescendantsInstances = { hitPart.Parent }
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	raycastParams.IgnoreWater = true

	-- Cast rays in each direction
	for _, direction in ipairs(directions) do
		local rayOrigin = hitPosition
		local rayDirection = direction * 4 -- Raycast 4 studs in the given direction

		-- Perform the raycast
		local result = Workspace:Raycast(rayOrigin, rayDirection, raycastParams)

		if result then
			-- Spawn blood splat at the position where the ray hits
			local hitPosition = result.Position
			local hitNormal = result.Normal
			spawnBloodSplat(hitPosition, hitNormal)
		end
	end
end

local function CompareTables(arr1, arr2)
	for i, v in pairs(arr1) do
		if typeof(v) == "table" then
			if CompareTables(arr2[i], v) == false then
				return false
			end
		else
			if v ~= arr2[i] then
				return false
			end
		end
	end
	return true
end

local function SecureSettings(Player, Tool, Module)
	if Player then
		local PreNewModule = Tool:FindFirstChild("Setting")
		if Tool and PreNewModule then
			local NewModule = require(PreNewModule:FindFirstChild(Module.ModuleName))
			if CompareTables(Module, NewModule) == false then
				if KickPlayer then
					if MarketplaceService:UserOwnsGamePassAsync(Player.UserId, 98100769) then
						for i, v in pairs(Player.Character:GetChildren()) do
							if v:IsA("Tool") then
								if not v:FindFirstChild("SwitchKit") then
									Player:Kick(
										"You have been kicked and blocked from rejoining this specific server for exploiting tool stats."
									)
									warn(Player.Name .. " has been kicked for exploiting tool stats.")
									table.insert(_G.TempBannedPlayers, Player)
								end

								return
							end
						end
					else
						for i, v in pairs(Player.Character:GetChildren()) do
							if v:IsA("Tool") then
								if not v:FindFirstChild("Suppressor") then
									Player:Kick(
										"You have been kicked and blocked from rejoining this specific server for exploiting tool stats."
									)
									warn(Player.Name .. " has been kicked for exploiting tool stats.")
									table.insert(_G.TempBannedPlayers, Player)
								end

								return
							end
						end
					end
				else
					warn(Player.Name .. " - Potential Exploiter Bypass! Case 2: Changed Tool Stats From Client")
				end
				return
			end
		else
			--[[if KickPlayer then
				Player:Kick("Tool and Module are not found. Kicked!")
				warn("Tool and Module are missing from "..Player.Name.."'s inventory.")
			else
				warn(Player.Name.." - Potential Exploiter Bypass! Case 1: Missing Tool And Module")	
			end]]
			warn(Player.Name .. " - Potential Exploiter Bypass! Case 1: Missing Tool And Module")
			return
		end
	else
		warn("Player does not exist.")
		return
	end
end

local function AddressTableValue(v2)
	return v2
end

local function CalculateDamage(Damage, TravelDistance, ZeroDamageDistance, FullDamageDistance)
	local ZeroDamageDistance = ZeroDamageDistance or 10000
	local FullDamageDistance = FullDamageDistance or 1000
	local DistRange = ZeroDamageDistance - FullDamageDistance
	local FallOff = math.clamp(1 - (math.max(0, TravelDistance - FullDamageDistance) / math.max(1, DistRange)), 0, 1)
	return math.max(Damage * FallOff, 0)
end

PlayAudio.OnServerEvent:Connect(function(Player, Audio, Replicate)
	for _, plr in next, Players:GetPlayers() do
		if plr ~= Player then
			PlayAudio:FireClient(plr, Audio, Replicate)
		end
	end
end)

VisualizeHitEffect.OnServerEvent:Connect(
	function(Player, Type, Hit, Position, Normal, Material, ClientModule, Misc, Replicate)
		for _, plr in next, Players:GetPlayers() do
			if plr ~= Player then
				VisualizeHitEffect:FireClient(plr, Type, Hit, Position, Normal, Material, ClientModule, Misc, Replicate)
			end
		end
	end
)

VisualizeBullet.OnServerEvent:Connect(
	function(
		Player,
		Tool,
		Handle,
		VMHandle,
		ClientModule,
		CLDirections,
		SVDirections,
		FirePointObject,
		MuzzlePointObject,
		Misc,
		Replicate
	)
		for _, plr in next, Players:GetPlayers() do
			if plr ~= Player then
				VisualizeBullet:FireClient(
					plr,
					Tool,
					Handle,
					VMHandle,
					ClientModule,
					CLDirections,
					SVDirections,
					FirePointObject,
					MuzzlePointObject,
					Misc,
					Replicate
				)
			end
		end
	end
)

ShatterGlass.OnServerEvent:Connect(function(_, Hit)
	if Hit then
		if Hit.Name == "_glass" then
			local ogtran = Hit.Transparency
			if Hit.Transparency ~= 1 then
				if PhysicEffect then
					if Hit.Parent:FindFirstChild("_repair") then
						Hit.Parent:FindFirstChild("_repair").ClickDetector.Enabled = true
					end
					local Sound = Instance.new("Sound")
					Sound.SoundId = "http://roblox.com/asset/?id=2978605361"
					Sound.TimePosition = 0.1
					Sound.Volume = 1
					Sound.Parent = Hit
					Sound:Play()
					Sound.Ended:Connect(function()
						Sound:Destroy()
					end)
					--GlassShattering:Shatter(Hit, Pos, Dir + Vector3.new(math.random(-25, 25), math.random(-25, 25), math.random(-25, 25)))
					Hit.CanCollide = false
					Hit.CanQuery = false
					Hit.Transparency = 1

					task.wait(RegenTime)
					if Hit.Parent:FindFirstChild("_repair") then
						Hit.Parent:FindFirstChild("_repair").ClickDetector.Enabled = false
						Hit.Parent:FindFirstChild("_repair").CanCollide = false
						Hit.Parent:FindFirstChild("_repair").Transparency = 1
					end
					Hit.CanQuery = true
					Hit.CanCollide = true
					Hit.Transparency = ogtran
					--[[local LifeTime = 5
					local FadeTime = 1
					local SX, SY, SZ = Hit.Size.X, Hit.Size.Y, Hit.Size.Z
					for X = 1, 4 do
						for Y = 1, 4 do
							local Part = Hit:Clone()
							local position = Vector3.new(X - 2.1, Y - 2.1, 0) * Vector3.new(SX / 4, SY / 4, SZ)
							local currentTransparency = Part.Transparency
							Part.Name = "_shatter"
							Part.Size = Vector3.new(SX / 4, SY / 4, SZ)
							Part.CFrame = Hit.CFrame * (CFrame.new(Part.Size / 8) - Hit.Size / 8 + position)			
							Part.Velocity = Vector3.new(math.random(-10, 10), math.random(-10, 10), math.random(-10, 10))
							Part.Parent = workspace
							--Debris:AddItem(Part, 10)
							task.delay(LifeTime, function()
								if Part.Parent ~= nil then
									if LifeTime > 0 then
										local t0 = os.clock()
										while true do
											local Alpha = math.min((os.clock() - t0) / FadeTime, 1)
											Part.Transparency = Math.Lerp(currentTransparency, 1, Alpha)
							    			if Alpha == 1 then break end
						      				task.wait()
										end
										Part:Destroy()
									else
										Part:Destroy()
					    			end
								end
							end)
							Part.Anchored = false
						end
					end]]
				else
					local Sound = Instance.new("Sound")
					Sound.SoundId = "http://roblox.com/asset/?id=2978605361"
					Sound.TimePosition = 0.1
					Sound.Volume = 1
					Sound.Parent = Hit
					Sound:Play()
					Sound.Ended:Connect(function()
						Sound:Destroy()
					end)
					local Particle = script.Shatter:Clone()
					Particle.Color = ColorSequence.new(Hit.Color)
					Particle.Transparency = NumberSequence.new({
						NumberSequenceKeypoint.new(0, Hit.Transparency), --(time, value)
						NumberSequenceKeypoint.new(1, 1),
					})
					Particle.Parent = Hit
					task.delay(0.01, function()
						Particle:Emit(10 * math.abs(Hit.Size.magnitude))
						Debris:AddItem(Particle, Particle.Lifetime.Max)
					end)
				end
			end
		else
			error("Hit part's name must be '_glass'.")
		end
	else
		error("Hit part doesn't exist.")
	end
end)

local function InflictGun(Player, Tool, ClientModule, TargetHumanoid, TargetTorso, Hit, Misc, HitDist)
	SecureSettings(Player, Tool, ClientModule)
	local ModifiedSetting = {
		ExplosiveEnabled = AddressTableValue(ClientModule.ExplosiveEnabled),
		ExplosionRadius = AddressTableValue(ClientModule.ExplosionRadius),
		SelfDamage = AddressTableValue(ClientModule.SelfDamage),
		SelfDamageRedution = AddressTableValue(ClientModule.SelfDamageRedution),
		ReduceSelfDamageOnAirOnly = AddressTableValue(ClientModule.ReduceSelfDamageOnAirOnly),
		BaseDamage = AddressTableValue(ClientModule.BaseDamage),
		HeadshotDamageMultiplier = AddressTableValue(ClientModule.HeadshotDamageMultiplier),
		ZeroDamageDistance = AddressTableValue(ClientModule.ZeroDamageDistance),
		FullDamageDistance = AddressTableValue(ClientModule.FullDamageDistance),
		CriticalBaseChance = AddressTableValue(ClientModule.CriticalBaseChance),
		CriticalDamageMultiplier = AddressTableValue(ClientModule.CriticalDamageMultiplier),
		Knockback = AddressTableValue(ClientModule.Knockback),
		Lifesteal = AddressTableValue(ClientModule.Lifesteal),
		DebuffName = AddressTableValue(ClientModule.DebuffName),
		DebuffChance = AddressTableValue(ClientModule.DebuffChance),
	}
	local Character = Player.Character
	local Humanoid = Character:FindFirstChildOfClass("Humanoid")
	local IsHeadshot = (Hit and Hit.Name == "Head" and ClientModule.HeadshotEnabled)
	local TrueDamage
	if HitDist and ModifiedSetting.ExplosiveEnabled then
		local DamageMultiplier = (1 - math.clamp((HitDist / ModifiedSetting.ExplosionRadius), 0, 1))
		TrueDamage = ClientModule.DamageBasedOnDistance
				and (IsHeadshot and ModifiedSetting.BaseDamage * ModifiedSetting.HeadshotDamageMultiplier or ModifiedSetting.BaseDamage) * DamageMultiplier
			or (
				IsHeadshot and ModifiedSetting.BaseDamage * ModifiedSetting.HeadshotDamageMultiplier
				or ModifiedSetting.BaseDamage
			)
	else
		TrueDamage = ClientModule.DamageDropOffEnabled
				and CalculateDamage(
					IsHeadshot and ModifiedSetting.BaseDamage * ModifiedSetting.HeadshotDamageMultiplier
						or ModifiedSetting.BaseDamage,
					HitDist,
					ModifiedSetting.ZeroDamageDistance,
					ModifiedSetting.FullDamageDistance
				)
			or (
				IsHeadshot and ModifiedSetting.BaseDamage * ModifiedSetting.HeadshotDamageMultiplier
				or ModifiedSetting.BaseDamage
			)
	end

	local TweenService = game:GetService("TweenService")

	local BloodStains = game.ReplicatedStorage.BloodStains
	local validBodyParts = {
		"Head",
		"UpperTorso",
		"LowerTorso",
		"LeftUpperArm",
		"LeftLowerArm",
		"LeftHand",
		"RightUpperArm",
		"RightLowerArm",
		"RightHand",
		"LeftUpperLeg",
		"LeftLowerLeg",
		"LeftFoot",
		"RightUpperLeg",
		"RightLowerLeg",
		"RightFoot",
	}

	if Hit then
		if not table.find(validBodyParts, Hit.Name) then
			local Attachment = Hit:FindFirstAncestorOfClass("Attachment")
			if Attachment and Attachment.Parent then
				Hit = Attachment.Parent
			end
		end
		-- Check if the hit part is a valid body part
		if table.find(validBodyParts, Hit.Name) then
			local HighLighter = Instance.new("Highlight")
			HighLighter.Parent = Hit
			HighLighter.FillTransparency = 0.5 -- Make it fully visible
			HighLighter.OutlineTransparency = 1 -- Make the outline fully visible
			HighLighter.DepthMode = "Occluded" -- Make the outline fully visible

			-- Create tween info
			local tweenInfo = TweenInfo.new(1, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
			-- Create tween goals (what properties to change)
			local tweenGoals = {
				FillTransparency = 1, -- Fully transparent
				OutlineTransparency = 1, -- Fully transparent
			}

			-- Create the tween
			local tween = TweenService:Create(HighLighter, tweenInfo, tweenGoals)
			tween:Play()

			-- Remove the highlight after the tween is finished
			tween.Completed:Connect(function()
				HighLighter:Destroy()
			end)
		end
		if TargetHumanoid then
			spawnBloodInAllDirections(Hit, Hit.Position, Hit.CFrame.LookVector)
		end
		if TargetHumanoid.Health <= 0 then
			-- Check if the hit part is a valid body part
			if table.find(validBodyParts, Hit.Name) then
				-- Apply velocity to the hit body part based on bullet impact direction
				-- Check if the body part has an attribute to track decal count
				if not Hit:GetAttribute("DecalCount") then
					-- Initialize the decal count if it doesn't exist
					Hit:SetAttribute("DecalCount", 0)
				end
				-- Get the current count of decals on this body part
				local currentCount = Hit:GetAttribute("DecalCount")
				-- Only proceed if the decal count is less than 3
				if currentCount < 1 then
					for _, decal in pairs(BloodStains:GetChildren()) do
						if decal:IsA("Decal") then
							local bloodDecal = decal:Clone()
							bloodDecal.Parent = Hit -- Parent the decal to the body part that was hit

							-- Increment the decal count
							Hit:SetAttribute("DecalCount", currentCount + 1)
						end
					end

					-- Apply velocity to the hit body part based on bullet impact direction
					local bodyVelocity = Instance.new("BodyVelocity")
					bodyVelocity.Velocity = Vector3.new(0, 5, 0)
					bodyVelocity.P = 20 -- Tweak damping to simulate realistic motion
					bodyVelocity.Parent = Hit
					-- Clean up the velocities after 0.2 seconds to prevent unwanted behavior
					game:GetService("Debris"):AddItem(bodyVelocity, 0.02)
				end
			end
		end
	end

	if Player and Character and Humanoid then
		local CanDamage = DamageModule.CanDamage(TargetHumanoid.Parent, Tool.Parent, ClientModule.FriendlyFire)
		if ModifiedSetting.ExplosiveEnabled and ModifiedSetting.SelfDamage then
			if TargetHumanoid.Parent.Name == Player.Name then
				CanDamage = (TargetHumanoid.Parent.Name == Player.Name)
				if ModifiedSetting.ReduceSelfDamageOnAirOnly then
					TrueDamage = TargetHumanoid:GetState() ~= Enum.HumanoidStateType.Freefall and TrueDamage
						or (TrueDamage * (1 - ModifiedSetting.SelfDamageRedution))
				else
					TrueDamage = TrueDamage * (1 - ModifiedSetting.SelfDamageRedution)
				end
			end
		end
		if TargetHumanoid and TargetTorso and CanDamage then
			local creator = TargetHumanoid:FindFirstChild("creator")
			if not creator then
				creator = Instance.new("ObjectValue")
				creator.Name = "creator"
				creator.Parent = TargetHumanoid
			end

			creator.Value = Player

			if ClientModule.CriticalDamageEnabled then
				local CriticalChanceRandom = Random.new():NextInteger(0, 100)
				if CriticalChanceRandom <= ModifiedSetting.CriticalBaseChance then
					TargetHumanoid:TakeDamage(TrueDamage * ModifiedSetting.CriticalDamageMultiplier)
				else
					if TargetHumanoid.Parent:FindFirstChild("VestHealth") then
						if TargetHumanoid.Parent:FindFirstChild("VestHealth").Value >= 1 then
							TargetHumanoid.Parent:FindFirstChild("VestHealth").Value = TargetHumanoid.Parent:FindFirstChild(
								"VestHealth"
							).Value - TrueDamage
							local NewDamage = TrueDamage / 1.5

							TargetHumanoid:TakeDamage(NewDamage)
							if TargetHumanoid.Parent:FindFirstChild("VestHealth").Value == 0 then
								Tool.GunClient.BreakVestEvent:Fire()
							end
						else
							TargetHumanoid:TakeDamage(TrueDamage)
						end
					else
						TargetHumanoid:TakeDamage(TrueDamage)
					end
				end
			else
				if TargetHumanoid.Parent:FindFirstChild("VestHealth") then
					if TargetHumanoid.Parent:FindFirstChild("VestHealth").Value >= 1 then
						TargetHumanoid.Parent:FindFirstChild("VestHealth").Value = TargetHumanoid.Parent:FindFirstChild(
							"VestHealth"
						).Value - TrueDamage
						local NewDamage = TrueDamage / 1.5

						TargetHumanoid:TakeDamage(NewDamage)

						if TargetHumanoid.Parent:FindFirstChild("VestHealth").Value == 0 then
							Tool.GunClient.BreakVestEvent:Fire()
						end
					else
						TargetHumanoid:TakeDamage(TrueDamage)
					end
				else
					TargetHumanoid:TakeDamage(TrueDamage)
				end
			end
			if ModifiedSetting.Knockback > 0 then
				if not (ModifiedSetting.ExplosiveEnabled and ClientModule.ExplosionKnockback) then
					local Shover = Character:FindFirstChild("HumanoidRootPart") or Character:FindFirstChild("Head")
					local Duration = 0.1
					local Speed = ModifiedSetting.Knockback / Duration
					local Velocity = (TargetTorso.Position - Shover.Position).Unit * Speed
					local ShoveForce = Instance.new("BodyVelocity")
					ShoveForce.MaxForce = Vector3.new(1e9, 1e9, 1e9)
					ShoveForce.Velocity = Velocity
					ShoveForce.Parent = TargetTorso
					Debris:AddItem(ShoveForce, Duration)
				end
			end
			if ModifiedSetting.Lifesteal > 0 and Humanoid.Health ~= 0 then
				local HealAmount = TrueDamage * ModifiedSetting.Lifesteal
				Humanoid.Health = Humanoid.Health + HealAmount
			end
			if ClientModule.Debuff then
				if ClientModule.DebuffName ~= "" then
					local Roll = Random.new():NextInteger(0, 100)
					if Roll <= ModifiedSetting.DebuffChance then
						if not TargetHumanoid.Parent:FindFirstChild(ModifiedSetting.DebuffName) then
							local Debuff = Miscs.Debuffs[ModifiedSetting.DebuffName]:Clone()
							Debuff.creator.Value = creator.Value
							Debuff.Parent = TargetHumanoid.Parent
							Debuff.Disabled = false
						end
					end
				end
			end
			if TargetHumanoid.Health - TrueDamage <= 0 and not TargetHumanoid.Parent:FindFirstChild("gibbed") then
				if Hit then
					if
						Hit.Name == "Head"
						or Hit.Name == "Torso"
						or Hit.Name == "Left Arm"
						or Hit.Name == "Right Arm"
						or Hit.Name == "Right Leg"
						or Hit.Name == "Left Leg"
						or Hit.Name == "UpperTorso"
						or Hit.Name == "LowerTorso"
						or Hit.Name == "LeftUpperArm"
						or Hit.Name == "LeftLowerArm"
						or Hit.Name == "LeftHand"
						or Hit.Name == "RightUpperArm"
						or Hit.Name == "RightLowerArm"
						or Hit.Name == "RightHand"
						or Hit.Name == "RightUpperLeg"
						or Hit.Name == "RightLowerLeg"
						or Hit.Name == "RightFoot"
						or Hit.Name == "LeftUpperLeg"
						or Hit.Name == "LeftLowerLeg"
						or Hit.Name == "LeftFoot"
					then
						VisualizeGore:FireAllClients(Hit, TargetHumanoid.Parent, ClientModule, Misc.GoreEffect)
					end
				end
			end
		end
	else
		warn("Unable to register damage because player is no longer existing here")
	end

	if Hit.Name == "_Door" then
		if Hit:FindFirstChild("_DoorHealth") then
			if Hit:FindFirstChild("_DoorHealth").Value > 0 then
				Hit:FindFirstChild("_DoorHealth").Value = Hit:FindFirstChild("_DoorHealth").Value
					- ModifiedSetting.BaseDamage
			end
		end
	end

	if Hit.Name == "_Safe" then
		if Hit:FindFirstChild("_SafeHealth") then
			if Hit:FindFirstChild("_SafeHealth").Value > 0 then
				Hit:FindFirstChild("_SafeHealth").Value = Hit:FindFirstChild("_SafeHealth").Value - 10
			end
		end
	end

	if Hit.Name == "_SafeDoor" then
		if Hit.Parent:FindFirstChild("_Safe"):FindFirstChild("_SafeHealth") then
			if Hit.Parent:FindFirstChild("_Safe"):FindFirstChild("_SafeHealth").Value > 0 then
				Hit.Parent:FindFirstChild("_Safe"):FindFirstChild("_SafeHealth").Value = Hit.Parent
					:FindFirstChild("_Safe")
					:FindFirstChild("_SafeHealth").Value - 10
			end
		end
	end
end

local function InflictGunMelee(Player, Tool, ClientModule, TargetHumanoid, TargetTorso, Hit)
	SecureSettings(Player, Tool, ClientModule)
	local character = Player and Player.Character
	if character then
		local seatedVehicle = getSeatedCarModel(character)
		if seatedVehicle then
			-- 1) Never allow damage to resolve back to the shooter while seated
			if TargetHumanoid and TargetHumanoid.Parent == character then
				return
			end

			-- 2) If the hit part is inside the seated vehicle, only block it when it's NOT a humanoid target.
			-- This keeps "shoot other players from inside car" working, even if their rig ends up parented under the car.
			if Hit and typeof(Hit) == "Instance" and Hit:IsDescendantOf(seatedVehicle) then
				local isHumanoidTarget = (TargetHumanoid ~= nil)
					and (TargetHumanoid.Parent ~= nil)
					and (TargetHumanoid.Parent ~= character)
				if not isHumanoidTarget then
					return
				end
			end
		end
	end

	local Character = Player.Character
	local Humanoid = Character:FindFirstChildOfClass("Humanoid")
	local IsHeadshot = (Hit and Hit.Name == "Head" and ClientModule.MeleeHeadshotEnabled)
	local TrueDamage = IsHeadshot and ClientModule.MeleeDamage * ClientModule.MeleeHeadshotDamageMultiplier
		or ClientModule.MeleeDamage
	if Player and Character and Humanoid then
		if
			TargetHumanoid
			and TargetHumanoid.Health ~= 0
			and TargetTorso
			and DamageModule.CanDamage(TargetHumanoid.Parent, Character, ClientModule.FriendlyFire)
		then
			local creator = TargetHumanoid:FindFirstChild("creator")
			if not creator then
				creator = Instance.new("ObjectValue")
				creator.Name = "creator"
				creator.Parent = TargetHumanoid
			end

			creator.Value = Player
			if ClientModule.MeleeCriticalDamageEnabled then
				local CriticalChanceRandom = Random.new():NextInteger(0, 100)
				if CriticalChanceRandom <= ClientModule.MeleeCriticalBaseChance then
					TargetHumanoid:TakeDamage(TrueDamage * ClientModule.MeleeCriticalDamageMultiplier)
				else
					TargetHumanoid:TakeDamage(TrueDamage)
				end
			else
				TargetHumanoid:TakeDamage(TrueDamage)
			end
			if ClientModule.MeleeKnockback > 0 then
				local Shover = Character:FindFirstChild("HumanoidRootPart") or Character:FindFirstChild("Head")
				local Duration = 0.1
				local Speed = ClientModule.MeleeKnockback / Duration
				local Velocity = (TargetTorso.Position - Shover.Position).Unit * Speed
				local ShoveForce = Instance.new("BodyVelocity")
				ShoveForce.MaxForce = Vector3.new(1e9, 1e9, 1e9)
				ShoveForce.Velocity = Velocity
				ShoveForce.Parent = TargetTorso
				Debris:AddItem(ShoveForce, Duration)
			end
			if ClientModule.MeleeLifesteal > 0 and Humanoid.Health ~= 0 then
				local HealAmount = TrueDamage * ClientModule.MeleeLifesteal
				Humanoid.Health = Humanoid.Health + HealAmount
			end
			if ClientModule.MeleeDebuff then
				if ClientModule.MeleeDebuffName ~= "" then
					local Roll = Random.new():NextInteger(0, 100)
					if Roll <= ClientModule.MeleeDebuffChance then
						if not TargetHumanoid.Parent:FindFirstChild(ClientModule.MeleeDebuffName) then
							local Debuff = Miscs.Debuffs[ClientModule.MeleeDebuffName]:Clone()
							Debuff.creator.Value = creator.Value
							Debuff.Parent = TargetHumanoid.Parent
							Debuff.Disabled = false
						end
					end
				end
			end
		end
	else
		warn("Unable to register damage because player/character is no longer existing here")
	end
end
local MAX_GUN_RANGE = 700
local MAX_ORIGIN_DRIFT = 12
local SHOTS_PER_SECOND = 15

local shotBucket = {} -- [Player] = {t=number, tokens=number}
Players.PlayerRemoving:Connect(function(plr)
	shotBucket[plr] = nil
end)

local function allowShot(plr)
	local now = os.clock()
	local b = shotBucket[plr]
	if not b then
		b = { t = now, tokens = SHOTS_PER_SECOND }
		shotBucket[plr] = b
	end

	local dt = now - b.t
	b.t = now
	b.tokens = math.min(SHOTS_PER_SECOND, b.tokens + dt * SHOTS_PER_SECOND)

	if b.tokens < 1 then
		return false
	end
	b.tokens -= 1
	return true
end

local function getMuzzleOrigin(plr, tool)
	local char = plr.Character
	if not char then
		return nil
	end

	if tool and tool:IsA("Tool") then
		local handle = tool:FindFirstChild("Handle")
		if handle and handle:IsA("BasePart") then
			local att = handle:FindFirstChild("Muzzle") or handle:FindFirstChild("Barrel")
			if att and att:IsA("Attachment") then
				return att.WorldPosition
			end
			return handle.Position
		end
	end

	local head = char:FindFirstChild("Head")
	if head and head:IsA("BasePart") then
		return head.Position
	end

	local hrp = char:FindFirstChild("HumanoidRootPart")
	return (hrp and hrp.Position) or nil
end

local function getTorso(model)
	return model:FindFirstChild("HumanoidRootPart")
		or model:FindFirstChild("UpperTorso")
		or model:FindFirstChild("Torso")
end

InflictTarget.OnServerInvoke = function(Player, Type, ...)
	if Type == "Gun" then
		local Tool, ClientModule, _TargetHumanoid, _TargetTorso, ClientHit, Misc, _HitDist = ...

		-- Basic tool sanity (prevents invoking with a random Tool instance)
		if typeof(Tool) ~= "Instance" or not Tool:IsA("Tool") then
			return false, "bad_tool"
		end
		if not Player.Character or Tool.Parent ~= Player.Character then
			return false, "tool_not_equipped"
		end

		if not allowShot(Player) then
			return false, "rate_limited"
		end

		if typeof(Misc) ~= "table" then
			Misc = {}
		end
		-- Prevent crazy values (still allows 1-3)
		Misc.ChargeLevel = math.clamp(tonumber(Misc.ChargeLevel) or 1, 1, 3)

		local origin = getMuzzleOrigin(Player, Tool)
		if not origin then
			return false, "no_origin"
		end

		-- We only have an Instance (ClientHit) to aim at, so we raycast to its position.
		if typeof(ClientHit) ~= "Instance" or not ClientHit:IsA("BasePart") then
			return false, "bad_hit"
		end

		local claimedPos = ClientHit.Position
		local delta = claimedPos - origin
		local dist = delta.Magnitude
		if dist <= 0 or dist > MAX_GUN_RANGE then
			return false, "out_of_range"
		end

		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude

		local ignore = { Player.Character, Tool }

		for _, character in Workspace:GetChildren() do -- make only players by doing player.character
			if character:FindFirstChild("Humanoid") then
				table.insert(ignore, character:FindFirstChild("HumanoidRootPart"))
			end
		end

		local seatedCar = getSeatedCarModel(Player.Character)
		if seatedCar then
			table.insert(ignore, seatedCar) -- key fix
		end

		params.FilterDescendantsInstances = ignore
		params.IgnoreWater = true

		local result = Workspace:Raycast(origin, delta, params)
		if not result or not result.Instance then
			return false, "no_raycast_hit"
		end

		local hitPart = result.Instance
		local targetModel = hitPart:FindFirstAncestorOfClass("Model")
		if not targetModel or targetModel == Player.Character then
			return false, "bad_target"
		end

		local targetHumanoid = targetModel:FindFirstChildOfClass("Humanoid")
		if not targetHumanoid or targetHumanoid.Health <= 0 then
			return false, "not_humanoid"
		end

		local targetTorso = getTorso(targetModel)
		if not targetTorso or not targetTorso:IsA("BasePart") then
			return false, "no_torso"
		end

		-- Server-authoritative distance
		local hitDist = (result.Position - origin).Magnitude

		-- IMPORTANT: we pass SERVER-derived Hit/TargetHumanoid/TargetTorso/HitDist into InflictGun
		InflictGun(Player, Tool, ClientModule, targetHumanoid, targetTorso, hitPart, Misc, hitDist)
		return true
	elseif Type == "GunMelee" then
		local Tool, ClientModule, TargetHumanoid, TargetTorso, Hit = ...

		-- Minimal melee sanity (prevents “hit anyone anywhere”)
		local char = Player.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		if not hrp then
			return false, "no_hrp"
		end
		if typeof(TargetTorso) ~= "Instance" or not TargetTorso:IsA("BasePart") then
			return false, "bad_melee_target"
		end
		if (TargetTorso.Position - hrp.Position).Magnitude > 10 then
			return false, "melee_too_far"
		end

		InflictGunMelee(Player, Tool, ClientModule, TargetHumanoid, TargetTorso, Hit)
		return true
	end
end

Players.PlayerAdded:Connect(function(player)
	for i, v in pairs(_G.TempBannedPlayers) do
		if v == player.Name then
			player:Kick("You cannot rejoin a server where you were kicked from.")
			warn(player.Name .. " tried to rejoin a server where he/she was kicked from.")
			break
		end
	end
end)
