local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TutorialClient = require(ReplicatedStorage.Shared.Tutorail.TutorialClient)

local startTutorialClient = {}
function startTutorialClient.init()
	TutorialClient.new()
end
return TutorialClient
