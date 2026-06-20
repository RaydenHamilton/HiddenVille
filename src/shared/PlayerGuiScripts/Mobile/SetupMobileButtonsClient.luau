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

	-- Movment
	local RunGui = MobileGui:FindFirstChild("SprintButton")
	local CrouchGui = MobileGui:FindFirstChild("CrouchButton")
	local DiveGui = MobileGui:FindFirstChild("DiveButton")
	-- Gun
	local GunGui = MobileGui:FindFirstChild("GunGui")

	if not (RunGui and CrouchGui and DiveGui) then
		warn("[Movement] SprintButton or CrouchButton missing inside MobileGui.")
		return
	end

	RunGui:Clone().Parent = buttonFrame
	CrouchGui:Clone().Parent = buttonFrame
	DiveGui:Clone().Parent = buttonFrame
	GunGui:Clone().Parent = buttonFrame
	local button = buttonFrame:WaitForChild("JumpButton") :: GuiButton

	local offset = button.Position
	for i, v in buttonFrame:GetDescendants() do
		if v:IsA("GuiButton") then
			v.Position = UDim2.new(v.Position.X.Scale, offset.X.Offset, v.Position.Y.Scale, offset.Y.Offset)
		end
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
