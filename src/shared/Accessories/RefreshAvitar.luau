local Players = game:GetService("Players")
local refresh = {}

function refresh.refresh(player)
	local humanoid = player.Character:FindFirstChild("Humanoid")
	local description = Players:GetHumanoidDescriptionFromUserId(player.UserId)
	description.HeightScale = 1.2
	humanoid:ApplyDescription(description)
end
return refresh
