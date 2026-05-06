local Fist = {}

function Fist.new(Tool)
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local Players = game:GetService("Players")

	local PunchedRemote = Tool:FindFirstChild("FistHandler")
	local KnockoutRemote = ReplicatedStorage.Remotes:WaitForChild("KnockoutEvent")

	local recentHits = {}

	local function IsAlive(character)
		return character and character:FindFirstChild("Humanoid") and character.Humanoid.Health > 0
	end

	local function ValidateTarget(player, targetHumanoid)
		local targetCharacter = targetHumanoid and targetHumanoid.Parent
		local attackerCharacter = player.Character

		if not (targetCharacter and attackerCharacter) then
			return false
		end
		if targetCharacter == attackerCharacter then
			return false
		end
		if not IsAlive(attackerCharacter) or not IsAlive(targetCharacter) then
			return false
		end

		local attackerRoot = attackerCharacter:FindFirstChild("HumanoidRootPart")
		local targetRoot = targetCharacter:FindFirstChild("HumanoidRootPart")
		if not (attackerRoot and targetRoot) then
			return false
		end

		local distance = (attackerRoot.Position - targetRoot.Position).Magnitude
		return distance <= 10
	end

	local function HandleAction(player, targetHumanoid, damage, actionType)
		if not ValidateTarget(player, targetHumanoid) then
			return
		end

		local fistTool = player.Character:FindFirstChild("Fist")
		if not (fistTool and fistTool:FindFirstChild("CanAttack") and fistTool.CanAttack.Value) then
			return
		end

		local targetCharacter = targetHumanoid.Parent
		local attackerName = player.Name
		local targetName = targetCharacter.Name

		recentHits[attackerName] = recentHits[attackerName] or {}
		recentHits[attackerName][targetName] = recentHits[attackerName][targetName] or { Count = 0, LastLogged = 0 }

		local hitData = recentHits[attackerName][targetName]
		local currentTime = os.clock()

		if currentTime - hitData.LastLogged <= 0.5 then
			return
		end

		hitData.Count += 1
		hitData.LastLogged = currentTime

		local function applyKnockback(force)
			local targetRoot = targetCharacter:FindFirstChild("HumanoidRootPart")
			local attackerRoot = player.Character:FindFirstChild("HumanoidRootPart")
			if targetRoot and attackerRoot then
				local direction = (targetRoot.Position - attackerRoot.Position).Unit
				local knockback = Instance.new("BodyVelocity")
				knockback.Velocity = direction * force
				knockback.MaxForce = Vector3.new(1e5, 1e5, 1e5)
				knockback.Parent = targetRoot
				game:GetService("Debris"):AddItem(knockback, 0.2)
			end
		end

		print(string.format("%s %s %s (%dx)", attackerName, actionType:lower(), targetName, hitData.Count))

		local function calculateDamage(baseDamage, criticalChance, multiplier)
			local isCritical = math.random(1, 100) <= criticalChance
			local damageDealt = isCritical and (baseDamage * multiplier) or baseDamage
			return isCritical, damageDealt
		end

		local animations = {
			Stomped = Tool.Animations:FindFirstChild("Stomped"),
			Pushed = Tool.Animations:FindFirstChild("Pushed"),
		}

		local function applyState(player, duration)
			KnockoutRemote:FireClient(player, duration)
		end

		local function playSound(sound, parent)
			local soundClone = sound:Clone()
			soundClone.Parent = parent
			soundClone:Play()

			soundClone.Ended:Connect(function()
				soundClone:Destroy()
			end)
		end

		local function playAnimation(humanoid, anim)
			if not humanoid or not anim then
				return
			end
			local loadedAnim = humanoid:LoadAnimation(anim)
			loadedAnim:Play()
		end

		local actionLog = {
			Punch = function()
				if not IsAlive(targetCharacter) then
					return
				end
				local fist = targetCharacter:FindFirstChild("Fist")
				if fist and fist:FindFirstChild("IsHittable") and not fist.IsHittable.Value then
					return
				end

				local isCritical, criticalDamage = calculateDamage(damage, 14, 1.5)
				local isKnockout, knockoutDamage = calculateDamage(damage, 8, 2.3)

				playSound(Tool.Handle:FindFirstChild("Hit"), targetCharacter.HumanoidRootPart)

				if isKnockout then
					targetHumanoid:TakeDamage(knockoutDamage)
					applyKnockback(20)
					applyState(Players:GetPlayerFromCharacter(targetCharacter), 10)
					if fist and fist:FindFirstChild("CanAttack") then
						fist.CanAttack.Value = false
						task.wait(10)
						fist.CanAttack.Value = true
					end
				else
					targetHumanoid:TakeDamage(criticalDamage)
					if isCritical then
						applyKnockback(15)
						applyState(Players:GetPlayerFromCharacter(targetCharacter), 1)
						local fist = targetCharacter:FindFirstChild("Fist")
						if fist and fist:FindFirstChild("CanAttack") then
							fist.CanAttack.Value = false
							task.wait(1)
							fist.CanAttack.Value = true
						end
					end
				end

				print(
					string.format(
						"Punch: %s | Damage Dealt: %.1f | %s",
						isCritical and "Critical" or "Normal",
						isKnockout and knockoutDamage or criticalDamage,
						isKnockout and "Knockout" or "Withstood"
					)
				)
			end,

			Stomp = function()
				if not IsAlive(targetCharacter) then
					return
				end
				local fist = targetCharacter:FindFirstChild("Fist")
				if fist and fist:FindFirstChild("IsHittable") and not fist.IsHittable.Value then
					return
				end

				local isCritical, damageDealt = calculateDamage(damage, 12, 1.2)

				targetHumanoid:TakeDamage(damageDealt)

				if targetHumanoid:GetState() == Enum.HumanoidStateType.Physics then
					playAnimation(targetHumanoid, animations.Stomped)
				end

				playSound(Tool.Handle:FindFirstChild("Hit"), targetCharacter.HumanoidRootPart)

				print(
					string.format("Stomp: %s | Damage Dealt: %.1f", isCritical and "Critical" or "Normal", damageDealt)
				)
			end,

			Push = function()
				if not IsAlive(targetCharacter) then
					return
				end
				local fist = targetCharacter:FindFirstChild("Fist")
				if fist and fist:FindFirstChild("IsHittable") and not fist.IsHittable.Value then
					return
				end

				local isHurtful = math.random(1, 100) <= 12
				local targetPlayer = Players:GetPlayerFromCharacter(targetCharacter)

				if isHurtful then
					applyKnockback(30)
					if targetPlayer then
						applyState(targetPlayer, 1)
					end
					targetHumanoid:TakeDamage(4)
					print("Push | Damage Dealt: 4")
				else
					applyKnockback(25)
					print("Push | No Damage")
				end

				playAnimation(targetHumanoid, animations.Pushed)
				playSound(Tool.Handle:FindFirstChild("Push"), targetCharacter.HumanoidRootPart)

				if fist and fist:FindFirstChild("CanAttack") and fist.CanAttack.Value then
					fist.CanAttack.Value = false
					task.delay(3, function()
						if fist and fist:FindFirstChild("CanAttack") then
							fist.CanAttack.Value = true
						end
					end)
				end
			end,

			Dodge = function()
				if not IsAlive(targetCharacter) then
					return
				end
				Tool.IsHittable.Value = not Tool.IsHittable.Value
			end,
		}

		if actionLog[actionType] then
			actionLog[actionType]()
		else
			warn("Invalid action type: " .. tostring(actionType))
		end

		task.delay(2, function()
			if recentHits[attackerName] and recentHits[attackerName][targetName] then
				recentHits[attackerName][targetName] = nil
			end
		end)
	end

	PunchedRemote.OnServerEvent:Connect(function(player, targetHumanoid, damage, actionType)
		HandleAction(player, targetHumanoid, damage, actionType)
	end)
end

return Fist
