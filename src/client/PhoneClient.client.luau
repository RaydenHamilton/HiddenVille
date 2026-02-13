local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local phoneGui = Player:WaitForChild("PlayerGui"):WaitForChild("majicPhoneGUI")
for _, button in phoneGui:getDescendants() do
	if button.Name == "homeButton" then
		button.MouseButton1Click:Connect(function()
			button.Parent.Visible = false
			button.Parent.Parent.Visible = false
			button.Parent.Parent.Parent.clickSound:Play()
		end)
	end
end

--// Cash app

--// Balance display
local leaderstats = Player:WaitForChild("leaderstats")
local moneyValue = leaderstats:WaitForChild("Money")

local function addCommas(n)
	local left, right = tostring(n):match("([^%.]+)%.?(.*)")
	left = left:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
	return right ~= "" and (left .. "." .. right) or left
end

local function formatMoney(amount)
	if amount >= 1e12 then
		return string.format("%.2fT", amount / 1e12)
	elseif amount >= 1e9 then
		return string.format("%.2fB", amount / 1e9)
	elseif amount >= 1e6 then
		return string.format("%.2fM", amount / 1e6)
	else
		return addCommas(amount)
	end
end

local function updateText()
	local formatted = "$" .. formatMoney(moneyValue.Value)
	if phoneGui.borderFrame.homeFrame.cashAppFrame.mainFrame.balanceText.Text ~= formatted then
		phoneGui.borderFrame.homeFrame.cashAppFrame.mainFrame.balanceText.Text = formatted
	end
end

updateText()
moneyValue:GetPropertyChangedSignal("Value"):Connect(updateText)

