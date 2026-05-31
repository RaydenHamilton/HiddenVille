local MobileSupport = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

function MobileSupport.new()
	local gui = Players.LocalPlayer.PlayerGui:WaitForChild("A-Chassis Interface")

	local Buttons = gui:WaitForChild("Buttons")
	local Mobile = UserInputService.TouchEnabled

	RunService.Heartbeat:Connect(function()
		if Mobile then
			Buttons.Visible = true
		else
			return
		end
	end)
end

return MobileSupport
