local Workspace = game:GetService("Workspace")
for _, room in Workspace.TurfSystem:GetChildren() do
	local musicPart = room:FindFirstChild("Area Music", true)
	if musicPart then
		local Sound = musicPart:WaitForChild("Sound")
		Sound:Play()
	end
end

Workspace.Sounds["City Ambience 3 (SFX)"]:Play()
Workspace.Sounds["Night Ambience 2 (SFX)"]:Play()
