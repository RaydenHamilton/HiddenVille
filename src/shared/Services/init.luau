--!strict
--[[ SERVICES ]]--
local RunService = game:GetService("RunService")

--[[ VARIABLES ]]--
local index = RunService:IsServer() and "serverInit" or "clientInit"

--[[ SCRIPT ]]--
for _, module: ModuleScript in script:GetChildren() do
	local init = require(module)[index] :: ((...any) -> any)?
	if init then init() end
end

--[[ RETURN ]]--
return nil