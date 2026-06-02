local ReplicatedStorage = game:GetService("ReplicatedStorage")
local typingRemote = ReplicatedStorage.Remotes:WaitForChild("Typing")

local tweenservice = game:GetService("TweenService")

local downGoal = {}
downGoal.ImageTransparency = 0.5
downGoal.Size = UDim2.fromScale(0.05, 0.05)

local upGoal = {}
upGoal.ImageTransparency = 0
upGoal.Size = UDim2.fromScale(0.1, 0.1)

local playertypingServer = {}

function playertypingServer.init()
	local function DotAnimation(dot, TweenUp, TweenDown)
		while dot.Parent.Enabled do
			TweenUp:Play()
			task.wait(0.52)
			TweenDown:Play()
			task.wait(0.52)
		end
	end

	typingRemote.OnServerEvent:Connect(function(player, typingornot)
		local character = player.Character
		if typingornot == "typing" then
			character.isusertyping.TextLabel.Text = tostring(player) .. " is typing"
			character.dots.Enabled = true
		end
		if typingornot == "nottyping" then
			character.isusertyping.TextLabel.Text = ""
			character.dots.one.Size = UDim2.fromOffset(0.05, 0.05)
			character.dots.two.Size = UDim2.fromOffset(0.05, 0.05)
			character.dots.three.Size = UDim2.fromOffset(0.05, 0.05)
			character.dots.one.ImageTransparency = 0.5
			character.dots.two.ImageTransparency = 0.5
			character.dots.three.ImageTransparency = 0.5
			character.dots.Enabled = false
		end

		character.dots.Changed:Connect(function()
			if character.dots.Enabled then
				for _, dot in character:WaitForChild("dots"):GetChildren() do
					task.spawn(function()
						local TweenUp = tweenservice:Create(
							dot,
							TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
							upGoal
						)

						local TweenDown = tweenservice:Create(
							dot,
							TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
							downGoal
						)
						DotAnimation(dot, TweenUp, TweenDown)
					end)
					task.wait(0.1)
				end
			end
		end)
	end)
end
return playertypingServer
