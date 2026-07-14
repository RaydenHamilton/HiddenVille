local mobileButtons = {}
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local mobileButtonsHooked = false
local function SetupMobileButtons()
	if mobileButtonsHooked then
		return
	end
	if not UserInputService.TouchEnabled then
		return
	end
	local touchGui = playerGui:FindFirstChild("TouchGui") or playerGui:WaitForChild("TouchGui", 5)

	if not touchGui then
		warn("[Movement] TouchGui not found in PlayerGui (mobile buttons not attached).")
		return
	end

	local buttonFrame = touchGui:FindFirstChild("TouchControlFrame") or touchGui:WaitForChild("TouchControlFrame", 5)

	if not buttonFrame then
		warn("[Movement] TouchControlFrame not found in TouchGui (mobile buttons not attached).")
		return
	end

	-- Clear any previous clones to avoid duplicates
	for _, child in ipairs(buttonFrame:GetChildren()) do
		if child.Name ~= "DynamicThumbstickFrame" and child.Name ~= "JumpButton" then
			child:Destroy()
		end
	end

	local MobileGui = playerGui:FindFirstChild("MobileGui")

	if not MobileGui then
		warn("[Movement] PlayerGui.MobileGui missing (no SprintButton/CrouchButton to clone).")
		return
	end

	MobileGui.Enabled = false

	local jumpButton = buttonFrame:WaitForChild("JumpButton") :: GuiButton
	local offset = jumpButton.Position

	for _, object in MobileGui:GetChildren() do
		object:Clone().Parent = buttonFrame
		if object:IsA("Folder") then
			for _, button in object:GetChildren() do
				button.Position =
					UDim2.new(button.Position.X.Scale, offset.X.Offset, button.Position.Y.Scale, offset.Y.Offset)
			end
			continue
		end

		object.Position = UDim2.new(object.Position.X.Scale, offset.X.Offset, object.Position.Y.Scale, offset.Y.Offset)
	end

	mobileButtonsHooked = true
end

function mobileButtons.init()
	SetupMobileButtons()
	playerGui.ChildAdded:Connect(function(child)
		if child.Name == "TouchGui" or child.Name == "MobileGui" then
			task.wait(0.1)
			SetupMobileButtons()
		end
	end)
	Players.LocalPlayer.CharacterAdded:Connect(function()
		mobileButtonsHooked = false
		task.wait(1)
		SetupMobileButtons()
	end)
end

return mobileButtons
