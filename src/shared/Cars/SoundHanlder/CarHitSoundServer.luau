local Sound = game:GetService("ServerStorage"):WaitForChild("Ouch")

local hitSound = {}

function hitSound.play(player)
	if Sound then
		local SoundClone = Sound:Clone()
		SoundClone.Parent = player.Character:FindFirstChild("Head")
		SoundClone:Play()
		game:GetService("Debris"):AddItem(SoundClone, SoundClone.TimeLength)
	end
end

return hitSound
