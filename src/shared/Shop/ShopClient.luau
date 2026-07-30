local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local shopClient = {}

local player = Players.LocalPlayer

local closest = nil
local lastClosest = nil

local startingCFrame = {}
local currentTween = {}

local TweenInfo = TweenInfo.new(0.5)

local function tweenModel(model, cframe)
	local CFrameValue = Instance.new("CFrameValue")
	CFrameValue.Value = model.PrimaryPart.CFrame

	if currentTween[model] then
		currentTween[model]:Cancel()
	end

	CFrameValue:GetPropertyChangedSignal("Value"):Connect(function()
		model:PivotTo(CFrameValue.Value)
	end)

	currentTween[model] = TweenService:Create(CFrameValue, TweenInfo, { Value = cframe })
	currentTween[model]:Play()

	currentTween[model].Completed:Connect(function()
		CFrameValue:Destroy()
	end)
end

local function enable(model: Model)
	local gui = model:FindFirstChild("NameTag") :: BillboardGui
	-- gui.Enabled = true
	local cframe =
		CFrame.lookAt(startingCFrame[model].Position, player.Character:FindFirstChild("HumanoidRootPart").Position)
	tweenModel(model, cframe * CFrame.new(0, 1, 0) * CFrame.Angles(math.rad(-90), math.rad(0), math.rad(-0)))
end

local function disable(model: Model)
	local gui = model:FindFirstChild("NameTag") :: BillboardGui
	-- gui.Enabled = false

	tweenModel(model, startingCFrame[model])
end

function shopClient.init()
	for _, item in Workspace.BuyableItems:QueryDescendants("Model") do
		local gui = item:FindFirstChild("NameTag", true) :: BillboardGui
		startingCFrame[item] = item.PrimaryPart.CFrame
		-- gui.Enabled = false
	end

	for _, item in Workspace.BlackMarket:QueryDescendants("Model") do
		local gui = item:FindFirstChild("NameTag", true) :: BillboardGui
		startingCFrame[item] = item.PrimaryPart.CFrame
		-- gui.Enabled = false
	end

	local count = 0
	local disance = 5

	RunService.Heartbeat:Connect(function(dt: number)
		count += dt

		local character = player.Character :: Model

		if count < 0.667 and character then
			count = 0
			for _, item in Workspace.BuyableItems:QueryDescendants("Model") do
				local position = item:WaitForChild("Handle").Position :: BasePart
				local closestMag = closest
					and (closest:WaitForChild("Handle").Position - character.PrimaryPart.Position).Magnitude
				local itemMag = (position - character.PrimaryPart.Position).Magnitude
				if
					(position - character.PrimaryPart.Position).Magnitude < disance
					and (not closest or closestMag > itemMag)
				then
					closest = item
				end
			end

			for _, item in Workspace.BlackMarket:QueryDescendants("Model") do
				local position = item:WaitForChild("Handle").Position :: BasePart
				local closestMag = closest
					and (closest:WaitForChild("Handle").Position - character.PrimaryPart.Position).Magnitude
				local itemMag = (position - character.PrimaryPart.Position).Magnitude
				if
					(position - character.PrimaryPart.Position).Magnitude < disance
					and (not closest or closestMag > itemMag)
				then
					closest = item
				end
			end

			local lastMag = lastClosest
				and (lastClosest:WaitForChild("Handle").Position - character.PrimaryPart.Position).Magnitude
			if lastMag and lastMag > disance then
				disable(closest)
			elseif lastMag then
				enable(closest)
			end

			if lastClosest ~= closest then
				if lastClosest then
					disable(lastClosest)
				end

				enable(closest)
				lastClosest = closest
			end
		end
	end)
end

return shopClient
