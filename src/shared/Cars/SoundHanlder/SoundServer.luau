local ReplicatedStorage = game:GetService("ReplicatedStorage")
local serverSounds = {}

local Sounds = {}
local F = {}

F.newSound = function(name, par, id, pitch, volume, loop)
	local sn = Sounds[name]
	if sn then
		sn.SoundId = id
		sn.Pitch = pitch
		sn.Volume = volume
		sn.Looped = loop
		return
	end
	sn = Instance.new("Sound")
	sn.Name = name
	sn.Parent = par
	sn.SoundId = id
	sn.Pitch = pitch
	sn.Volume = volume
	sn.Looped = loop
	Sounds[name] = sn
end

F.updateSound = function(sound, id, pit, vol)
	local sn = Sounds[sound]
	if sn then
		if id ~= sn.SoundId then
			sn.SoundId = id
		end
		if pit ~= sn.Pitch then
			sn.Pitch = pit
		end
		if vol ~= sn.Volume then
			sn.Volume = vol
		end
	end
end

F.playSound = function(sound)
	local sn = Sounds[sound]
	if sn then
		sn:Play()
	end
end

F.pauseSound = function(sound)
	local sn = Sounds[sound]
	if sn then
		sn:Pause()
	end
end

F.stopSound = function(sound)
	local sn = Sounds[sound]
	if sn then
		sn:Stop()
	end
end

F.removeSound = function(sound)
	local sn = Sounds[sound]
	if sn then
		sn:Stop()
		sn:Destroy()
		Sounds[sound] = nil
	end
end

function serverSounds.new(car)
	car.DriveSeat.ChildRemoved:Connect(function(child)
		if child.Name == "SeatWeld" then
			F.removeSound("Rev")
			F.removeSound("Elec")
		end
	end)
end

function serverSounds.init()
	ReplicatedStorage.Remotes.CarSounds.OnServerEvent:Connect(function(_, Fnc, ...)
		local func = F[Fnc]
		if func then
			func(...)
		end
	end)
end

return serverSounds
