local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local XPEvent = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("XPEvent")

local baseXP = 1000

local function calculateXP(level)
	return baseXP + (level - 1) * 150
end

local function isFiniteNumber(x)
	return typeof(x) == "number" and x == x and x ~= math.huge and x ~= -math.huge
end

local function clampInt(n, minv, maxv)
	if not isFiniteNumber(n) then
		return minv
	end
	n = math.floor(n + 0.0)
	if n < minv then
		return minv
	end
	if maxv ~= nil and n > maxv then
		return maxv
	end
	return n
end

local savingState = {}
local processingXP = {}

local function getState(player)
	local st = savingState[player]
	if not st then
		st = {
			loaded = false,
			closing = false,
			dirty = false,
			saving = false,
			lastSave = 0,
			lastSnapshot = nil,
		}
		savingState[player] = st
	end
	return st
end


local function checkAndHandleLevelUp(player)
	local st = getState(player)
	if not st.loaded then
		return
	end
	if processingXP[player] then
		return
	end

	local hiddenstats = player:FindFirstChild("hiddenstats")
	if not hiddenstats then
		return
	end

	local xp = hiddenstats:FindFirstChild("XP")
	local level = hiddenstats:FindFirstChild("Level")
	if not (xp and level) then
		return
	end

	processingXP[player] = true

	local safety = 0
	while xp.Value >= calculateXP(level.Value) do
		safety += 1
		if safety > 5000 then
			xp.Value = 0
			level.Value = math.max(level.Value, 1)
			break
		end

		local need = calculateXP(level.Value)
		if need <= 0 then
			break
		end

		xp.Value -= need
		level.Value += 1

		local XPBar = ReplicatedStorage:WaitForChild("Remotes"):FindFirstChild("XPBarUpdate")
		if XPBar then
			XPBar:FireClient(player, xp.Value, level.Value, calculateXP(level.Value))
		end
	end

	processingXP[player] = false
end

local function addXP(player, amount)
	local st = getState(player)
	if not st.loaded then
		return
	end

	local hiddenstats = player:FindFirstChild("hiddenstats")
	if not hiddenstats then
		return
	end
	local xp = hiddenstats:FindFirstChild("XP")
	if not xp then
		return
	end

	amount = clampInt(amount, 1, 2000000000)
	xp.Value = clampInt(xp.Value + amount, 0, 2000000000)
	checkAndHandleLevelUp(player)
end
game:BindToClose(function()
	local threads = 0

	local start = os.clock()
	while threads > 0 and (os.clock() - start) < 25 do
		task.wait(0.1)
	end
end)

XPEvent.OnServerEvent:Connect(function(player, amount)
	if typeof(amount) == "number" and amount > 0 then
		addXP(player, amount)
	end
end)
-- SOFT SHUTDOWN SUPPORT: Listen for save-all request
local SaveAllPlayers = ReplicatedStorage:FindFirstChild("SaveAllPlayers")
if SaveAllPlayers then
	SaveAllPlayers.Event:Connect(function()
		print("💾 Soft shutdown: Saving all players...")
		local threads = 0
		for _, plr in ipairs(Players:GetPlayers()) do
			threads += 1
			task.spawn(function()
				threads -= 1
			end)
		end
		-- Wait for saves to complete (max 10 seconds)
		local start = os.clock()
		while threads > 0 and (os.clock() - start) < 10 do
			task.wait(0.1)
		end
		print("💾 All players saved!")
	end)
end

