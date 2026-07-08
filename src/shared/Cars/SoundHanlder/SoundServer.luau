local ReplicatedStorage = game:GetService("ReplicatedStorage")
local serverSounds = {}

local Sounds = {}
local F = {}

F.newSound = function(player, name, par, id, pitch, volume, loop)
	local sn = Sounds[player]
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
	Sounds[player] = sn
end

F.updateSound = function(player, sound, id, pit, vol)
	local sn = Sounds[player]
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

F.playSound = function(player)
	local sn = Sounds[player]
	if sn then
		sn:Play()
	end
end

F.pauseSound = function(player)
	local sn = Sounds[player]
	if sn then
		sn:Pause()
	end
end

F.stopSound = function(player)
	local sn = Sounds[player]
	if sn then
		sn:Stop()
	end
end

F.removeSound = function(player)
	local sn = Sounds[player]
	if sn then
		sn:Stop()
		sn:Destroy()
		Sounds[player] = nil
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
	ReplicatedStorage.Remotes.CarSounds.OnServerEvent:Connect(function(player, Fnc, ...)
		local func = F[Fnc]
		if func then
			func(player, ...)
		end
	end)
end

return serverSounds
