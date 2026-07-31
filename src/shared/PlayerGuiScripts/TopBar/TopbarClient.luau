local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Icon = require(ReplicatedStorage.Modules.Icon)
local EmotesSettings = require(script.Parent.EmotesSettings)
local Player = Players.LocalPlayer

const requestPlayerData = ReplicatedStorage.Remotes.RequestPlayerData

local topbar = {}

function topbar.init()
	if not game:IsLoaded() then
		game.Loaded:Wait()
	end

	if Player:WaitForChild("PlayerGui"):FindFirstChild("MainMenu") then
		repeat
			task.wait()
		until Player:WaitForChild("PlayerGui"):FindFirstChild("MainMenu").Enabled == false
	end

	local opened

	local PlayerGui = Player:WaitForChild("PlayerGui")
	local MainScreen = PlayerGui:WaitForChild("MainScreen", 10)
	local ClickSound = ReplicatedStorage:WaitForChild("ClickSound")

	local lastOpenedButton = nil

	local DROP_COOLDOWN = 3
	local canDrop = true
	table.sort(EmotesSettings, function(a, b)
		local order = {
			Dance = 1,
			Duo = 2,
			GS = 3,
		}
		if order[a.Image] == order[b.Image] then
			return a.Name < b.Name
		else
			return (order[a.Image] or 99) < (order[b.Image] or 99)
		end
	end)

	local function formatMoney(amount)
		if amount >= 1e12 then
			return string.format("%.2fT", amount / 1e12)
		elseif amount >= 1e9 then
			return string.format("%.2fB", amount / 1e9)
		elseif amount >= 1e6 then
			return string.format("%.2fM", amount / 1e6)
		else
			return tostring(amount):reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
		end
	end

	local function updateCashLabel(icon)
		local money = requestPlayerData:InvokeServer("Money")
		icon:setLabel("💰 $" .. formatMoney(money))
		icon:setCaption("Cash Amount")
	end

	local function showOnly(panelToShow)
		local allowedUIs = {
			["GameplayFrame"] = true,
			["Notifications"] = true,
			["XPBar"] = true,
			["Warning"] = true,
			["SafezoneWarning"] = true,
			["MoneyLabel"] = true,
		}

		for _, panel in pairs(MainScreen:GetChildren()) do
			if panel ~= panelToShow and not allowedUIs[panel.Name] then
				if panel:IsA("GuiObject") then
					panel.Visible = false
				elseif panel:IsA("ScreenGui") then
					panel.Enabled = false
				end
			end
		end

		if panelToShow then
			opened = panelToShow
			if panelToShow:IsA("ScreenGui") then
				panelToShow.Enabled = true
			elseif panelToShow:IsA("GuiObject") then
				panelToShow.Visible = true
			end
		end
	end

	local function togglePanel(panel)
		local isOpen = (panel:IsA("ScreenGui") and panel.Enabled) or (panel:IsA("GuiObject") and panel.Visible)
		local lastOpened = (opened and opened:IsA("ScreenGui") and opened.Enabled)
			or (opened and opened:IsA("GuiObject") and opened.Visible)
		if lastOpened then
			if opened:IsA("ScreenGui") then
				opened.Enabled = false
			else
				opened.Visible = false
			end
		end
		if isOpen then
			if panel:IsA("ScreenGui") then
				panel.Enabled = false
			else
				panel.Visible = false
			end
		else
			showOnly(panel)
		end
	end

	local function createButton(label, text, caption, callback)
		local button = Icon
			.new()
			--:setImage(label)
			:setLabel(text)
			:setCaption(caption)

		button:bindEvent("selected", function()
			if lastOpenedButton and lastOpenedButton ~= button then
				lastOpenedButton:deselect()
			end
			lastOpenedButton = button
		end)

		button:bindEvent("deselected", function(icon)
			if ClickSound then
				ClickSound:Play()
			end
			if lastOpenedButton == button then
				lastOpenedButton = nil
			end
			callback(icon)
		end)

		button:oneClick()
		return button
	end

	local createEmotesButton = function()
		local list = {}
		for _, v in EmotesSettings do
			local button = createButton("", v.Name, v.Image, v.Callback)

			table.insert(list, button)
		end
		return Icon.new()
			:setLabel("Emotes")
			:setCaption("Open Emotes")
			:modifyTheme({ "Menu", "MaxIcons", 5 })
			:setDropdown(list)
	end

	Icon.new():setLabel("Menu"):modifyTheme({ "Menu", "MaxIcons", 4 }):setMenu({
		createButton("rbxassetid://", "Settings", "Open Settings", function()
			togglePanel(MainScreen:FindFirstChild("Settings"))
		end),
		createButton("rbxassetid://", "Drop", "Drop Item", function(button)
			if not canDrop then
				return
			end

			local dropItemEvent = ReplicatedStorage.Remotes:WaitForChild("DropItem")
			local Character = Player.Character or Player.CharacterAdded:Wait()
			if Character then
				local tool = Character:FindFirstChildWhichIsA("Tool")

				if tool then
					if tool.Name == "Phone" or tool.Name == "Fist" then
						return
					end

					canDrop = false

					-- Fire drop
					dropItemEvent:FireServer(Player)

					-- Cooldown UI feedback
					task.spawn(function()
						for i = DROP_COOLDOWN, 1, -1 do
							button:setLabel(i .. "s")
							task.wait(1)
						end
						button:setLabel("Drop")
						canDrop = true
					end)
				end
			else
				warn("Character is not loaded.")
			end
		end),
		createEmotesButton(),
		createButton("rbxassetid://", "Spawners", "Open Spawners", function()
			togglePanel(MainScreen:FindFirstChild("Spawners"))
		end),
	})

	local moneyIcon = Icon.new()
		:setLabel("$" .. formatMoney(requestPlayerData:InvokeServer("Money")))
		:setCaption("Cash Amount")
		:oneClick()

	ReplicatedStorage.Remotes.UpdataPlayerMoney.OnClientEvent:Connect(function()
		updateCashLabel(moneyIcon)
	end)

	updateCashLabel(moneyIcon)
end

return topbar
