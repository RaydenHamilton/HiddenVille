local ReplicatedStorage = game:GetService("ReplicatedStorage")
local typingRemote = ReplicatedStorage.Remotes:WaitForChild("Typing")

local tweenservice = game:GetService("TweenService")

local function DotAnimation(dot)
	while dot.Visible do
		local goals = {}
		goals.ImageTransparency = 0
		goals.Size = UDim2.new(0.1, 0, 0.1, 0)
		local tween =
			tweenservice:Create(dot, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), goals)
		tween:Play()
		task.wait(0.52)
		local goals2 = {}
		goals2.ImageTransparency = 0.5
		goals2.Size = UDim2.new(0.05, 0, 0.05, 0)
		local tween2 =
			tweenservice:Create(dot, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), goals2)
		tween2:Play()
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
		character.dots.one.Size = UDim2.new(0.05, 0, 0.05, 0)
		character.dots.two.Size = UDim2.new(0.05, 0, 0.05, 0)
		character.dots.three.Size = UDim2.new(0.05, 0, 0.05, 0)
		character.dots.one.ImageTransparency = 0.5
		character.dots.two.ImageTransparency = 0.5
		character.dots.three.ImageTransparency = 0.5
		character.dots.Enabled = false
	end

	character.dots.Changed:Connect(function()
		for _, dot in character:WaitForChild("dots"):GetChildren() do
			task.spawn(function()
				DotAnimation(dot)
			end)
			task.wait(0.1)
		end
	end)
end)
