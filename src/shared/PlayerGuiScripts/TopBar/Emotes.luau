local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local emotes = {}

local camera = Workspace.Camera

local player = Players.LocalPlayer

local currentTrack

local animationEvents = {}

function emotes.playAnimation(animationId, noRun)
	local character = player.Character
	local humanoid = character and character:FindFirstChild("Humanoid")
	if humanoid then
		if currentTrack then
			if currentTrack.Animation.AnimationId == animationId then
				currentTrack:Stop()

				currentTrack = nil

				return
			else
				currentTrack:Stop()
				currentTrack = nil
			end
		end

		local anim = Instance.new("Animation")
		anim.AnimationId = animationId
		local track = humanoid:LoadAnimation(anim)
		anim:Destroy()

		currentTrack = track

		animationEvents[#animationEvents + 1] = track.Stopped:Connect(function()
			track:Destroy()
			camera.CameraSubject = humanoid
			if currentTrack == track then
				currentTrack = nil
			end
			for _, v in animationEvents do
				v:Disconnect()
			end
		end)

		track:Play()
		camera.CameraSubject = character:FindFirstChild("Head")
		animationEvents[#animationEvents + 1] = humanoid.Running:Connect(function(speed)
			if speed > 0 and not noRun then
				track.Priority = Enum.AnimationPriority.Idle
				task.wait(1.5)
				track:Stop()
			end
		end)
	end
end
return emotes
