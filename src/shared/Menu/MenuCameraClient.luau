const menuClient = {}

function menuClient.init()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local Players = game:GetService("Players")
	local RunService = game:GetService("RunService")

	if RunService:IsStudio() or true then
		return {}
	end

	local player = Players.LocalPlayer
	local camera = workspace.CurrentCamera

	-- Run-once guard (prevents re-cloning / re-locking camera if this script re-runs)
	if player:GetAttribute("__MenuRanOnce") then
		return
	end
	player:SetAttribute("__MenuRanOnce", true)

	-- If camera isn't ready, just bail safely (rare, but avoids hard errors)
	if not camera then
		warn("[Menu] CurrentCamera not available")
		return
	end

	-- Get menu template with a timeout so we don't infinite-yield and "brick" startup
	local menuTemplate = ReplicatedStorage:WaitForChild("Menu", 10)
	if not menuTemplate then
		warn("[Menu] ReplicatedStorage.Menu missing (timeout)")
		return
	end

	-- Optional: disable player controls locally (safe, does not affect server spawning)
	local controls
	do
		local ok, playerModule = pcall(function()
			local ps = player:WaitForChild("PlayerScripts", 10)
			if not ps then
				return nil
			end
			local pm = ps:FindFirstChild("PlayerModule") or ps:WaitForChild("PlayerModule", 5)
			if not pm then
				return nil
			end
			return require(pm)
		end)

		if ok and playerModule and playerModule.GetControls then
			controls = playerModule:GetControls()
			if controls and controls.Disable then
				controls:Disable()
			end
		end
	end

	-- Clean up any leftover local menu from a previous run (extra safety)
	local existing = workspace:FindFirstChild("Menu_LOCAL")
	if existing then
		existing:Destroy()
	end

	-- Clone menu locally
	local menuFolder = menuTemplate:Clone()
	menuFolder.Name = "Menu_LOCAL"
	menuFolder.Parent = workspace

	-- Menu camera (timeout prevents infinite yield)
	local menuCam = menuFolder:WaitForChild("MenuCamera", 10)
	if not menuCam then
		warn("[Menu] MenuCamera missing in menu folder")
		menuFolder:Destroy()
		if controls and controls.Enable then
			controls:Enable()
		end
		return
	end

	-- Switch camera to menu
	camera.CameraType = Enum.CameraType.Scriptable
	camera.CFrame = menuCam.CFrame

	-- Helper: restore camera subject safely (works whether character exists now or later)
	local function restoreCameraSubject()
		local character = player.Character
		if not character then
			return
		end
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			camera.CameraSubject = humanoid
		end
	end

	-- After 5 seconds, restore
	task.delay(5, function()
		-- Destroy menu
		if menuFolder and menuFolder.Parent then
			menuFolder:Destroy()
		end

		-- Restore camera
		camera.CameraType = Enum.CameraType.Custom
		restoreCameraSubject()

		-- If character wasn't ready yet, fix CameraSubject when it spawns
		if not player.Character then
			player.CharacterAdded:Once(function()
				task.defer(restoreCameraSubject)
			end)
		end

		-- Re-enable controls
		if controls and controls.Enable then
			controls:Enable()
		end
	end)
end
return menuClient
