local playerControls = {}
local Players = game:GetService("Players")

function playerControls.new()
	local gui = Players.LocalPlayer.PlayerGui:WaitForChild("A-Chassis Interface")
	local frame = gui.AC6_Controls_Module

	---Controls UI
	gui:WaitForChild("Controls")
	gui:WaitForChild("ControlsOpen")
	frame:WaitForChild("Window")
	frame:WaitForChild("Toggle")

	local car = gui.Car.Value
	local _Tune = require(car["A-Chassis Tune"])
	local UserInputService = game:GetService("UserInputService")
	local cPanel = frame
	local Controls = gui.Controls

	local ver = require(car["A-Chassis Tune"].README)
	cPanel.Window["//INSPARE"].Text = "A-Chassis " .. ver .. " // INSPARE"

	local controlsOpen = false
	local cInputB = nil
	local cInputT = nil
	local cInput = false

	local UIS1 = nil
	local UIS2 = nil

	for i, v in pairs(_Tune.Peripherals) do
		gui.Controls:WaitForChild(i)
		local slider = cPanel.Window.Content[i]
		slider.Text = v .. "%"
		slider.S.CanvasPosition = Vector2.new(v * (slider.S.CanvasSize.X.Offset - slider.S.Size.X.Offset) / 100, 0)
		slider.S.Changed:connect(function(property)
			if property == "CanvasPosition" then
				Controls[i].Value = math.floor(
					100 * slider.S.CanvasPosition.x / (slider.S.CanvasSize.X.Offset - slider.S.Size.X.Offset)
				)
				slider.Text = Controls[i].Value .. "%"
			end
		end)
	end

	for i, v in pairs(_Tune.Controls) do
		gui.Controls:WaitForChild(i)
		local button = cPanel.Window.Content[i]
		button.Text = v.Name
		button.Activated:connect(function()
			if UIS1 ~= nil then
				UIS1:disconnect()
			end
			if UIS2 ~= nil then
				UIS2:disconnect()
			end
			UIS1 = UserInputService.InputBegan:connect(function(input)
				if cInput then
					cInputB = input.KeyCode
					cInputT = input.UserInputType
				end
			end)
			UIS2 = UserInputService.InputChanged:connect(function(input)
				if
					cInput and (input.KeyCode == Enum.KeyCode.Thumbstick1 or input.KeyCode == Enum.KeyCode.Thumbstick2)
				then
					cInputB = input.KeyCode
					cInputT = input.UserInputType
				end
			end)
			gui.ControlsOpen.Value = true
			cPanel.Window.Overlay.Visible = true
			cInput = true
			repeat
				task.wait()
			until cInputB ~= nil
			if UIS1 ~= nil then
				UIS1:disconnect()
			end
			if UIS2 ~= nil then
				UIS2:disconnect()
			end
			if cInputB == Enum.KeyCode.Return or cInputB == Enum.KeyCode.KeypadEnter then
			--do nothing
			elseif string.find(i, "Contlr") ~= nil then
				if cInputT.Name:find("Gamepad") then
					Controls[i].Value = cInputB.Name
					button.Text = cInputB.Name
				else
					cPanel.Window.Error.Visible = true
				end
			elseif i == "MouseThrottle" or i == "MouseBrake" then
				if cInputT == Enum.UserInputType.MouseButton1 or cInputT == Enum.UserInputType.MouseButton2 then
					Controls[i].Value = cInputT.Name
					button.Text = cInputT.Name
				elseif cInputT == Enum.UserInputType.Keyboard then
					Controls[i].Value = cInputB.Name
					button.Text = cInputB.Name
				else
					cPanel.Window.Error.Visible = true
				end
			else
				if cInputT == Enum.UserInputType.Keyboard then
					Controls[i].Value = cInputB.Name
					button.Text = cInputB.Name
				else
					cPanel.Window.Error.Visible = true
				end
			end
			cInputB = nil
			cInputT = nil
			cInput = false
			task.wait(0.2)
			cPanel.Window.Overlay.Visible = false
			gui.ControlsOpen.Value = false
		end)
	end

	cPanel.Window.Error.Changed:connect(function(property)
		if property == "Visible" then
			task.wait(3)
			cPanel.Window.Error.Visible = false
		end
	end)

	cPanel.Toggle.Activated:connect(function()
		controlsOpen = not controlsOpen
		if controlsOpen then
			cPanel.Toggle.BackgroundColor3 = Color3.new(1, 85 / 255, 0.5)
			cPanel.Window:TweenPosition(
				UDim2.new(0.5, -250, 0.5, -250),
				Enum.EasingDirection.Out,
				Enum.EasingStyle.Quad,
				0.7,
				true
			)
		else
			if UIS1 ~= nil then
				UIS1:disconnect()
			end
			if UIS2 ~= nil then
				UIS2:disconnect()
			end
			cPanel.Toggle.BackgroundColor3 = Color3.new(1, 170 / 255, 0)
			cPanel.Window:TweenPosition(
				UDim2.new(0.5, -250, 0, -500),
				Enum.EasingDirection.Out,
				Enum.EasingStyle.Quad,
				0.7,
				true
			)
		end
	end)

	cPanel.Window.Tabs.Keyboard.Activated:connect(function()
		cPanel.Window.Content:TweenPosition(
			UDim2.new(0, 0, 0, 60),
			Enum.EasingDirection.Out,
			Enum.EasingStyle.Quad,
			0.4,
			true
		)
		cPanel.Window.Tabs.Keyboard:TweenPosition(
			UDim2.new(0, 5, 0, 0),
			Enum.EasingDirection.Out,
			Enum.EasingStyle.Quad,
			0.4,
			true
		)
		cPanel.Window.Tabs.Mouse:TweenPosition(
			UDim2.new(0, 120, 0, -5),
			Enum.EasingDirection.Out,
			Enum.EasingStyle.Quad,
			0.4,
			true
		)
		cPanel.Window.Tabs.Controller:TweenPosition(
			UDim2.new(0, 235, 0, -5),
			Enum.EasingDirection.Out,
			Enum.EasingStyle.Quad,
			0.4,
			true
		)
	end)

	cPanel.Window.Tabs.Mouse.Activated:connect(function()
		cPanel.Window.Content:TweenPosition(
			UDim2.new(-1, 0, 0, 60),
			Enum.EasingDirection.Out,
			Enum.EasingStyle.Quad,
			0.4,
			true
		)
		cPanel.Window.Tabs.Keyboard:TweenPosition(
			UDim2.new(0, 5, 0, -5),
			Enum.EasingDirection.Out,
			Enum.EasingStyle.Quad,
			0.4,
			true
		)
		cPanel.Window.Tabs.Mouse:TweenPosition(
			UDim2.new(0, 120, 0, 0),
			Enum.EasingDirection.Out,
			Enum.EasingStyle.Quad,
			0.4,
			true
		)
		cPanel.Window.Tabs.Controller:TweenPosition(
			UDim2.new(0, 235, 0, -5),
			Enum.EasingDirection.Out,
			Enum.EasingStyle.Quad,
			0.4,
			true
		)
	end)

	cPanel.Window.Tabs.Controller.Activated:connect(function()
		cPanel.Window.Content:TweenPosition(
			UDim2.new(-2, 0, 0, 60),
			Enum.EasingDirection.Out,
			Enum.EasingStyle.Quad,
			0.4,
			true
		)
		cPanel.Window.Tabs.Keyboard:TweenPosition(
			UDim2.new(0, 5, 0, -5),
			Enum.EasingDirection.Out,
			Enum.EasingStyle.Quad,
			0.4,
			true
		)
		cPanel.Window.Tabs.Mouse:TweenPosition(
			UDim2.new(0, 120, 0, -5),
			Enum.EasingDirection.Out,
			Enum.EasingStyle.Quad,
			0.4,
			true
		)
		cPanel.Window.Tabs.Controller:TweenPosition(
			UDim2.new(0, 235, 0, 0),
			Enum.EasingDirection.Out,
			Enum.EasingStyle.Quad,
			0.4,
			true
		)
	end)

	task.wait(0.5)
	cPanel.Toggle:TweenPosition(
		UDim2.new(0.5, -50, 1, -25),
		Enum.EasingDirection.Out,
		Enum.EasingStyle.Quad,
		0.4,
		false
	)
	for i = 1, 6 do
		cPanel.Toggle.BackgroundColor3 = Color3.new(100 / 255, 100 / 255, 100 / 255)
		task.wait(0.2)
		if controlsOpen then
			cPanel.Toggle.BackgroundColor3 = Color3.new(1, 85 / 255, 0.5)
		else
			cPanel.Toggle.BackgroundColor3 = Color3.new(1, 170 / 255, 0)
		end
		task.wait(0.2)
	end
end

return playerControls
