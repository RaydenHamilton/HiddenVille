local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Client = {}

local player = Players.LocalPlayer
local remote = ReplicatedStorage.Remotes.Tutorial

local steps = {

	-- Car Robberies
	-- break in to car
	-- take money

	-- chips
	-- buy the stuff
	-- make the chips
	-- sell the chips

	-- buy gun
}

local quest = {

	-- buy a car
	-- rob the bank
}

local function findClosestCar(): BasePart
	local character: Model = player.Character or player.CharacterAdded:Wait()
	local closest
	local object
	for _, v in Workspace.CarRobberySystem:GetChildren() do
		if v.Name == "Car" then
			local glass: BasePart = v:FindFirstChild("Glass")
			local rootpart = character:WaitForChild("HumanoidRootPart")
			print(glass, rootpart)
			if glass and rootpart then
				local mag = (glass.Position - rootpart.Position).magnitude
				if not closest or mag < closest then
					closest = mag
					object = glass
				end
			end
		end
	end
	return object
end

local function askToStart(): boolean
	return false
end

function path(targetPart: BasePart)
	local pathPart = Instance.new("Part")
	pathPart.Name = "TutorialPath"
	pathPart.Anchored = true
	pathPart.CanCollide = false
	pathPart.CanTouch = false
	pathPart.CanQuery = false
	pathPart.Material = Enum.Material.Neon
	pathPart.Color = Color3.fromRGB(255, 255, 0)
	pathPart.Transparency = 1
	pathPart.Parent = workspace

	local icon = Instance.new("Texture")
	icon.Parent = pathPart
	icon.Texture = "rbxassetid://13360801719"
	icon.Face = "Top"
	icon.StudsPerTileU = 1
	icon.StudsPerTileV = 2
	icon.Transparency = 0.8

	local count = 1
	local connection
	connection = RunService.RenderStepped:Connect(function(ds)
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")

		if not root or not targetPart or not targetPart.Parent then
			return
		end

		local startPos = root.Position
		local endPos = targetPart.Position

		local direction = endPos - startPos
		local distance = direction.Magnitude

		-- MIDPOINT
		local middle = startPos + direction / 2

		count -= 0.1
		icon.OffsetStudsV = count
		-- SIZE
		pathPart.Size = Vector3.new(1, 0.2, distance)

		icon.Face = "Top"
		-- ROTATION + POSITION
		pathPart.CFrame = CFrame.lookAt(middle, endPos)
	end)

	return pathPart, connection
end

function Client.new(stepIndex, QuestIndex)
	if askToStart() then
		-- if stepIndex == 0 then
		path(findClosestCar())
		-- end
	end
end

function text(text: string) end

return Client
