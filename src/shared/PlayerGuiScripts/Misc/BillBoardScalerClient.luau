local Workspace = game:GetService("Workspace")
local billboardscaler = {}

local function newBillboard(billboard: BillboardGui)
	if billboard:IsA("BillboardGui") then
		local uiScale = billboard:FindFirstChildOfClass("UIScale")
		if not uiScale then
			uiScale = Instance.new("UIScale")
			uiScale.parent = billboard
		end

		local camera = Workspace.CurrentCamera
		local multiplier = 1 / 1080 -- default resolution

		local x, y = camera.ViewportSize.X, camera.ViewportSize.Y
		local currentScale = if y < x then multiplier * y else multiplier * x

		uiScale.Scale = currentScale
	end
end

function billboardscaler.init()
	for _, billboard in Workspace:QueryDescendants("BillboardGui") do
		newBillboard(billboard)
	end
	Workspace.DescendantAdded:Connect(newBillboard)
end
return billboardscaler
