local ReplicatedStorage = game:GetService("ReplicatedStorage")

local function canInit(theModule: ModuleScript)
	if string.find(string.lower(theModule.Name), "server") then
		local module = require(theModule)
		local containsFunction = (type(module) == "table") and (type(module["init"]) == "function")
		if containsFunction then
			module.init()
		end
	end
	return false
end

for _, module in ReplicatedStorage.Shared:GetDescendants() do
	if module:IsA("ModuleScript") then
		canInit(module)
	end
end
