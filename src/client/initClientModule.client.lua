local ReplicatedStorage = game:GetService("ReplicatedStorage")

local function canInit(theModule: ModuleScript)
	if string.find(string.lower(theModule.Name), "client") then
		local pass, message = pcall(function()
			local module = require(theModule)
			task.spawn(function()
				local containsFunction = (type(module) == "table") and (type(module["init"]) == "function")
				if containsFunction then
					module.init()
				end
			end)
		end)
		if not pass then
			warn(theModule, message)
		end
	end
	return false
end

for _, module in ReplicatedStorage.Shared:QueryDescendants("ModuleScript") do
	canInit(module)
end
