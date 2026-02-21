local GunHanlderServer = {}

function GunHanlderServer.new(Tool)
	local Workspace = game:GetService("Workspace")
	local Debris = game:GetService("Debris")

	local Tool = Tool
	local Setting = Tool:WaitForChild("Setting")
	local Handle = Tool:WaitForChild(require(Setting).PrimaryHandle)
	local Handle2
	local Grip2

	local Module = require(Setting)

	if Module.DualWeldEnabled then
		Handle2 = Tool:WaitForChild(Module.SecondaryHandle, 1)
		if not Handle2 then
			error('"Dual" setting is enabled but "Handle2" is missing!')
		end
	end

	local AnimationFolder = Instance.new("Folder")
	AnimationFolder.Name = "AnimationFolder"
	AnimationFolder.Parent = Tool

	local ValueFolder = Instance.new("Folder")
	ValueFolder.Name = "ValueFolder"
	ValueFolder.Parent = Tool

	local ChangeMagAndAmmo = Tool:WaitForChild("ChangeMagAndAmmo")

	-- Helper function to create values
	local function CreateValue(name, value, parent)
		local val = Instance.new("NumberValue")
		val.Name = name
		val.Value = value
		val.Parent = parent
		return val
	end

	-- Helper function to load animation
	local function LoadAnim(name, id, parent)
		if id then
			local anim = Instance.new("Animation")
			anim.Name = name
			anim.AnimationId = "rbxassetid://" .. id
			anim.Parent = parent
		end
	end

	for i, v in ipairs(Setting:GetChildren()) do
		local Module2 = require(v)

		local ValFolder = Instance.new("Folder")
		ValFolder.Name = i
		ValFolder.Parent = ValueFolder

		CreateValue("Mag", Module2.AmmoPerMag, ValFolder)
		CreateValue("Ammo", Module2.LimitedAmmoEnabled and Module2.Ammo or 0, ValFolder)
		CreateValue("Heat", 0, ValFolder)

		local AnimFolder = Instance.new("Folder")
		AnimFolder.Name = i
		AnimFolder.Parent = AnimationFolder

		local ThirdPerson = Instance.new("Folder")
		ThirdPerson.Name = "ThirdPerson"
		ThirdPerson.Parent = AnimFolder

		local FirstPerson = Instance.new("Folder")
		FirstPerson.Name = "FirstPerson"
		FirstPerson.Parent = AnimFolder

		-- Animation Definitions
		local TPAnims = {
			{ "IdleAnim", Module2.IdleAnimationID },
			{ "FireAnim", Module2.FireAnimationID },
			{ "ReloadAnim", Module2.ReloadAnimationID },
			{ "ShotgunClipinAnim", Module2.ShotgunClipinAnimationID },
			{ "ShotgunPumpinAnim", Module2.ShotgunPumpinAnimationID },
			{ "HoldDownAnim", Module2.HoldDownAnimationID },
			{ "EquippedAnim", Module2.EquippedAnimationID },
			{ "SecondaryFireAnim", Module2.SecondaryFireAnimationEnabled and Module2.SecondaryFireAnimationID },
			{
				"SecondaryShotgunPumpinAnim",
				Module2.SecondaryShotgunPump and Module2.SecondaryShotgunPumpinAnimationID,
			},
			{ "AimIdleAnim", Module2.AimAnimationsEnabled and Module2.AimIdleAnimationID },
			{ "AimFireAnim", Module2.AimAnimationsEnabled and Module2.AimFireAnimationID },
			{ "AimSecondaryFireAnim", Module2.AimAnimationsEnabled and Module2.AimSecondaryFireAnimationID },
			{ "AimChargingAnim", Module2.AimAnimationsEnabled and Module2.AimChargingAnimationID },
			{ "TacticalReloadAnim", Module2.TacticalReloadAnimationEnabled and Module2.TacticalReloadAnimationID },
			{ "InspectAnim", Module2.InspectAnimationEnabled and Module2.InspectAnimationID },
			{
				"PreShotgunReloadAnim",
				Module2.ShotgunReload and Module2.PreShotgunReload and Module2.PreShotgunReloadAnimationID,
			},
			{ "MinigunRevUpAnim", Module2.MinigunRevUpAnimationID },
			{ "MinigunRevDownAnim", Module2.MinigunRevDownAnimationID },
			{ "ChargingAnim", Module2.ChargingAnimationEnabled and Module2.ChargingAnimationID },
			{ "SwitchAnim", Module2.SelectiveFireEnabled and Module2.SwitchAnimationID },
			{ "OverheatAnim", Module2.BatteryEnabled and Module2.OverheatAnimationID },
			{ "MeleeAttackAnim", Module2.MeleeAttackEnabled and Module2.MeleeAttackAnimationID },
			{ "AltAnim", Module.AltFire and Module2.AltAnimationID },
		}

		local FPAnims = {
			{ "VMIdleAnim", Module2.VMIdleAnimationID },
			{ "VMFireAnim", Module2.VMFireAnimationID },
			{ "VMReloadAnim", Module2.VMReloadAnimationID },
			{ "VMShotgunClipinAnim", Module2.VMShotgunClipinAnimationID },
			{ "VMShotgunPumpinAnim", Module2.VMShotgunPumpinAnimationID },
			{ "VMHoldDownAnim", Module2.VMHoldDownAnimationID },
			{ "VMEquippedAnim", Module2.VMEquippedAnimationID },
			{ "VMSecondaryFireAnim", Module2.SecondaryFireAnimationEnabled and Module2.VMSecondaryFireAnimationID },
			{
				"VMSecondaryShotgunPumpinAnim",
				Module2.VMSecondaryShotgunPump and Module2.VMSecondaryShotgunPumpinAnimationID,
			},
			{ "VMTacticalReloadAnim", Module2.TacticalReloadAnimationEnabled and Module2.VMTacticalReloadAnimationID },
			{ "VMInspectAnim", Module2.InspectAnimationEnabled and Module2.VMInspectAnimationID },
			{
				"VMPreShotgunReloadAnim",
				Module2.ShotgunReload and Module2.PreShotgunReload and Module2.VMPreShotgunReloadAnimationID,
			},
			{ "VMMinigunRevUpAnim", Module2.VMMinigunRevUpAnimationID },
			{ "VMMinigunRevDownAnim", Module2.VMMinigunRevDownAnimationID },
			{ "VMChargingAnim", Module2.ChargingAnimationEnabled and Module2.VMChargingAnimationID },
			{ "VMSwitchAnim", Module2.SelectiveFireEnabled and Module2.VMSwitchAnimationID },
			{ "VMOverheatAnim", Module2.BatteryEnabled and Module2.VMOverheatAnimationID },
			{ "VMMeleeAttackAnim", Module2.MeleeAttackEnabled and Module2.VMMeleeAttackAnimationID },
			{ "VMAltAnim", Module.AltFire and Module2.VMAltAnimationID },
		}

		for _, anim in ipairs(TPAnims) do
			LoadAnim(anim[1], anim[2], ThirdPerson)
		end
		for _, anim in ipairs(FPAnims) do
			LoadAnim(anim[1], anim[2], FirstPerson)
		end
	end

	local Motor6DInstance
	local GripId = 0

	local function GetInstanceFromAncestor(Table)
		if Table[1] == "Tool" then
			return Tool:FindFirstChild(Table[2], true)
		end
		if Table[1] == "Character" then
			return Tool.Parent:FindFirstChild(Table[2], true)
		end
	end

	local function SetCustomGrip(Enabled, AlignFromDefaultGrip)
		if Enabled then
			GripId += 1
			local LastGripId = GripId
			if not Motor6DInstance then
				local Part0 = GetInstanceFromAncestor(Module.CustomGripPart0)
				local Part1 = GetInstanceFromAncestor(Module.CustomGripPart1)
				if Part0 and Part1 then
					Motor6DInstance = Instance.new("Motor6D")
					Motor6DInstance.Name = Module.CustomGripName
					Motor6DInstance.Part0 = Part0
					Motor6DInstance.Part1 = Part1

					local RightArm = Tool.Parent:FindFirstChild("Right Arm") or Tool.Parent:FindFirstChild("RightHand")
					if Handle.Name == "Handle" and RightArm then
						repeat
							task.wait()
							if LastGripId ~= GripId then
								break
							end
						until RightArm:FindFirstChild("RightGrip")
						if LastGripId == GripId then
							local RightGrip = RightArm:FindFirstChild("RightGrip")
							if RightGrip then
								if AlignFromDefaultGrip then
									Motor6DInstance.C0 = RightGrip.C0
									Motor6DInstance.C1 = RightGrip.C1
								end
								RightGrip.Enabled = false
								RightGrip:Destroy()
								if Module.CustomGripCFrame then
									Motor6DInstance.C0 *= Module.CustomGripC0
									Motor6DInstance.C1 *= Module.CustomGripC1
								end
								Motor6DInstance.Parent = Part0
							end
						end
					else
						if Module.CustomGripCFrame then
							Motor6DInstance.C0 *= Module.CustomGripC0
							Motor6DInstance.C1 *= Module.CustomGripC1
						end
						Motor6DInstance.Parent = Part0
					end
				end
			end
		else
			GripId += 1
			if Motor6DInstance then
				Motor6DInstance:Destroy()
				Motor6DInstance = nil
			end
		end
	end

	ChangeMagAndAmmo.OnServerEvent:Connect(function(_, Id, Mag, Ammo, Heat)
		if ValueFolder:FindFirstChild(Id) then
			ValueFolder[Id].Mag.Value = Mag
			ValueFolder[Id].Ammo.Value = Ammo
			ValueFolder[Id].Heat.Value = Heat
		end
	end)

	local function OnEquip()
		local Character = Tool.Parent
		local LeftArm = Character:FindFirstChild("Left Arm") or Character:FindFirstChild("LeftHand")
		local RightArm = Character:FindFirstChild("Right Arm") or Character:FindFirstChild("RightHand")

		if Module.CustomGripEnabled and not Tool.RequiresHandle then
			if not Motor6DInstance then
				SetCustomGrip(true, Module.AlignC0AndC1FromDefaultGrip)
			end
		end

		if Module.DualWeldEnabled and not Module.CustomGripEnabled and Tool.RequiresHandle then
			Handle2.CanCollide = false
			if RightArm then
				local Grip = RightArm:WaitForChild("RightGrip", 0.01)
				if Grip then
					Grip2 = Grip:Clone()
					Grip2.Name = "LeftGrip"
					Grip2.Part0 = LeftArm
					Grip2.Part1 = Handle2
					Grip2.Parent = LeftArm
				end
			end
		end
	end
	Tool.Equipped:Connect(OnEquip)

	Tool.Unequipped:Connect(function()
		if Module.CustomGripEnabled and not Tool.RequiresHandle then
			if Motor6DInstance then
				SetCustomGrip(false)
			end
		end
		if Module.DualWeldEnabled and not Module.CustomGripEnabled and Tool.RequiresHandle then
			Handle2.CanCollide = true
			if Grip2 then
				Grip2:Destroy()
			end
		end
	end)

	Tool.AncestryChanged:Connect(function()
		if not Tool:IsDescendantOf(game) then
			if Module.CustomGripEnabled and not Tool.RequiresHandle then
				if Motor6DInstance then
					SetCustomGrip(false)
				end
			end
			if Module.DualWeldEnabled and not Module.CustomGripEnabled and Tool.RequiresHandle then
				Handle2.CanCollide = true
				if Grip2 then
					Grip2:Destroy()
				end
			end
		end
	end)

	Tool.Magdrop.OnServerEvent:Connect(function()
		local mag = Tool:FindFirstChild("Magx")
		if not mag then
			return
		end

		local Clone = mag:Clone()
		mag.Transparency = 1
		Clone.Parent = Workspace
		Clone.Transparency = 0
		Clone.CFrame = mag.CFrame
		Clone.CanCollide = true

		local sound = Tool:FindFirstChild("Sound")
		if sound then
			local sClone = sound:Clone()
			sClone.Parent = Clone
			sClone:Play()
		end

		if Tool:FindFirstChild("Handle") and Tool.Handle:FindFirstChild("SmokeTrail1") then
			Tool.Handle.SmokeTrail1.Enabled = true
			task.delay(1.5, function()
				if Tool and Tool:FindFirstChild("Handle") and Tool.Handle:FindFirstChild("SmokeTrail1") then
					Tool.Handle.SmokeTrail1.Enabled = false
				end
				if mag then
					mag.Transparency = 0
				end
			end)
		else
			task.delay(1.5, function()
				if mag then
					mag.Transparency = 0
				end
			end)
		end

		Debris:AddItem(Clone, 20)
	end)

	-- Dead body fling/push when shot
	local FlingDeadBody = Instance.new("RemoteEvent")
	FlingDeadBody.Name = "FlingDeadBody"
	FlingDeadBody.Parent = Tool

	local FLING_FORCE = 150
	local FLING_UPWARD = 50

	FlingDeadBody.OnServerEvent:Connect(function(player, hitPart, direction)
		if not hitPart or not hitPart:IsA("BasePart") or not direction or typeof(direction) ~= "Vector3" then
			return
		end

		local model = hitPart:FindFirstAncestorOfClass("Model")
		if not model then
			return
		end

		local humanoid = model:FindFirstChildOfClass("Humanoid")
		if humanoid and humanoid.Health > 0 then
			return
		end -- Only fling dead bodies

		local force = (direction.Unit * FLING_FORCE) + Vector3.new(0, FLING_UPWARD, 0)

		if not hitPart.Anchored then
			hitPart.AssemblyLinearVelocity += force
			hitPart.AssemblyAngularVelocity += Vector3.new(
				math.random(-30, 30),
				math.random(-30, 30),
				math.random(-30, 30)
			)
		end
	end)
end

return GunHanlderServer
