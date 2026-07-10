local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local soundClient = {}

local connections: { RBXScriptConnection } = {}

function soundClient.new()
	local gui = player.PlayerGui:WaitForChild("A-Chassis Interface") :: PlayerGui

	local FE = Workspace.FilteringEnabled
	local car = gui.Car.Value
	local handler = ReplicatedStorage.Remotes.CarSounds

	local _Tune = require(car["A-Chassis Tune"])

	local on = 0
	local mult = 0
	local det = 0.13
	local trm = 0.4
	local trmmult = 0
	local trmon = 0
	local throt = 0
	local redline = 0
	local shift = 0

	gui:WaitForChild("Rev")

	local rev = gui:FindFirstChild("Rev")
	local seat = car:FindFirstChild("DriveSeat")

	local function clearConnections()
		handler:FireServer("removeSound")
		for _, connection in connections do
			connection:Disconnect()
		end
	end

	if not rev or not seat then
		warn("no rev or no seat")
		return
	end

	-- /// SAFE SOUNDID (no nil, no blank)
	local revSoundId = rev.SoundId
	if not revSoundId or revSoundId == "" then
		revSoundId = "rbxassetid://9125620646"
	end

	local revVolume = rev.Volume

	-- /// GEAR CHANGE SHIFT POP FIX
	connections[#connections + 1] = gui.Values.Gear.Changed:Connect(function()
		mult = 1
		if gui.Values.RPM.Value > 5000 then
			shift = 0.2
		end
	end)

	-- /// DESTROY OLD SOUNDS ONLY IF THEY ARE FROM SOUND_MOD
	for _, child in ipairs(seat:GetChildren()) do
		if gui:FindFirstChild(child.Name) and child:IsA("Sound") then
			child:Stop()
			child:Destroy()
		end
	end

	-- /// MAIN FIX — Never recreate "Rev" if it already exists
	local existingRev = seat:FindFirstChild("Rev")

	if not existingRev then
		handler:FireServer("newSound", "Rev", seat, revSoundId, 0, revVolume, true)
		task.wait(0.05)
	else
		-- force sync SoundId/Volume
		handler:FireServer("updateSound", "Rev", revSoundId, existingRev.Pitch, existingRev.Volume)
	end

	-- /// PLAY ONLY IF IT'S NOT ALREADY PLAYING
	task.wait(0.05)
	local soundObj = seat:WaitForChild("Rev")

	if not soundObj.IsPlaying then
		handler:FireServer("playSound", "Rev")
	end

	-- /// MAIN LOOP (smooth, lag-free)

	local FRAME_TIME = 1 / 30
	local nextFireTime = 0

	connections[#connections + 1] = RunService.Heartbeat:Connect(function()
		local currentTime = os.clock()
		if currentTime < nextFireTime then
			return
		end
		nextFireTime = currentTime + FRAME_TIME

		mult = math.max(0, mult - 0.1)
		local _RPM = gui.Values.RPM.Value

		if gui.Values.Throttle.Value <= _Tune.IdleThrottle / 100 then
			throt = math.max(0.3, throt - 0.2)
			trmmult = math.max(0, trmmult - 0.05)
			trmon = 1
		else
			throt = math.min(1, throt + 0.1)
			trmmult = 1
			trmon = 0
		end

		shift = math.min(1, shift + 0.2)

		if
			gui.Values.RPM.Value > _Tune.Redline - _Tune.RevBounce / 4
			and gui.Values.Throttle.Value > _Tune.IdleThrottle / 100
		then
			redline = 0.5
		else
			redline = 1
		end

		if not gui.IsOn.Value then
			on = math.max(on - 0.015, 0)
		else
			on = 1
		end

		local Volume = (2 * throt * shift * redline) + (trm * trmon * trmmult * (1 - throt) * math.sin(tick() * 50))

		local Pitch = math.max(
			((rev.SetPitch.Value + rev.SetRev.Value * _RPM / _Tune.Redline) * on ^ 2)
				+ (det * mult * math.sin(80 * tick())),
			rev.SetPitch.Value
		)

		-- /// FINAL FIX — never sends invalid SoundId, never spams, never lags
		if FE then
			handler:FireServer("updateSound", "Rev", revSoundId, Pitch, Volume)
		else
			if soundObj then
				soundObj.Volume = Volume
				soundObj.Pitch = Pitch
			end
		end
	end)

	connections[#connections + 1] = gui.Destroying:Connect(clearConnections)
end
return soundClient
