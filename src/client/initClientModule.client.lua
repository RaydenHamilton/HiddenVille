local ReplicatedStorage = game:GetService("ReplicatedStorage")

local function canInit(theModule: ModuleScript)
	if string.find(string.lower(theModule.Name), "client") then
		local pass, message = pcall(function()
			local module = require(theModule)
			local containsFunction = (type(module) == "table") and (type(module["init"]) == "function")
			if containsFunction then
				module.init()
			end
		end)
		if not pass then
			warn(pass, message)
		end
	end
	return false
end

for _, module in ReplicatedStorage.Shared:GetDescendants() do
	if module:IsA("ModuleScript") then
		canInit(module)
	end
end
