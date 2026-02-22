local GunLaser = {}
local GunLaserClass = {}

local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

GunLaserClass.__index = GunLaserClass
function GunLaser.new(Tool: Tool)
	local self = setmetatable({}, GunLaserClass)
	self.Tool = Tool
	self.BeamOrigin = Tool:FindFirstChild("Origin", true)
	self.BeamEnd = Tool:FindFirstChild("End", true)

	if not (self.BeamEnd and self.BeamOrigin) then
		self = nil
		return
	end

	self.Connections = {
		EquippedConnection = Tool.Equipped:Connect(function()
			self:Equipped()
		end),
		UnequippedConnection = Tool.Unequipped:Connect(function()
			self:Unequipped()
		end),
		ToolDestroying = Tool.Destroying:Connect(function()
			self:Destroying()
		end),
	} :: { RBXScriptConnection }
end

function GunLaserClass:Destroying()
	for _, connection in self.Connections do
		connection:Disconnect()
	end
end

function GunLaserClass:Equipped()
	self.Connections.HeartBeatConnection = RunService.Heartbeat:Connect(function()
		self:RenderLaser()
	end)
end

function GunLaserClass:Unequipped()
	if self.Connections.HeartBeatConnection then
		self.Connections.HeartBeatConnection:Disconnect()
	end
end

function GunLaserClass:RenderLaser()
	if not (self.BeamOrigin and self.BeamEnd) then
		return
	end
	local origin = self.BeamOrigin.WorldPosition
	local direction = self.BeamOrigin.WorldCFrame.LookVector * 300
	local raycastParams = RaycastParams.new()
	raycastParams.FilterDescendantsInstances = { self.Tool, self.Character }
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	raycastParams.IgnoreWater = true
	local result = Workspace:Raycast(origin, direction, raycastParams)
	local endPos = result and result.Position or (origin + direction)

	self.BeamEnd.WorldPosition = endPos
end

return GunLaser
