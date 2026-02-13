local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")

local SpawnToolEvent = ReplicatedStorage:WaitForChild("SpawnTool")
local UpdateSpawns = ReplicatedStorage:WaitForChild("UpdateSpawns")
local SendSpawners = ReplicatedStorage:WaitForChild("SendSpawners")
local RequestSpawners = ReplicatedStorage:WaitForChild("RequestSpawners")

local MAX_SPAWNS = 5
local REGEN_TIME = 1500

local SpawnersFolder = ReplicatedStorage:FindFirstChild("Spawners")
local ToolStorage = SpawnersFolder and SpawnersFolder:FindFirstChild("Gamepass Spawners")
local CustomsStorage = SpawnersFolder and SpawnersFolder:FindFirstChild("Custom Spawners")

local playerData = {}

local function initializePlayer(player)
	playerData[player.UserId] = {
		spawns = {},
		ownedSpawners = {},
		spawnLimits = {},
	}

	local CustomSpawnerLimits = {
		["legalGlokk"] = {
			["Golden Ak"] = 8,
			["KrissVector"] = 10,
			["Wes's Bag"] = 300,
			["ChainSaw"] = 200,
			["GLOKK"] = 200,
			["Admin Fist"] = 200,
			["Fire powers"] = 200,
			["YOU GONE LOVE THIS"] = 200,
		},
	}

	local customSpawners = {
		["legalGlokk"] = {
			"200 Pump",
			"legalglokk's AWP",
			"Jaden's Banana Switch",
			"ChainSaw",
			"FENDII",
			"YOU GONE LOVE THIS",
			"Admin Fist",
			"NerfGun",
			"Golden Ak",
			"KrissVector",
			"DOLLAZ AR",
			"Wes's Bag",
			"RPGSwitch",
			"GLOKK",
		},
		["ragnram25"] = {
			"200 Pump",
			"legalglokk's AWP",
			"Jaden's Banana Switch",
			"ChainSaw",
			"FENDII",
			"YOU GONE LOVE THIS",
			"Admin Fist",
			"NerfGun",
			"Golden Ak",
			"KrissVector",
			"DOLLAZ AR",
			"Wes's Bag",
			"RPGSwitch",
			"GLOKK",
		},
		["6riox"] = {
			"MRBEAST ARP",
			"Red Crown Switch",
			"Jaden's Banana Switch",
			"ChainSaw",
			"DOLLAZ AR",
			"YOU GONE LOVE THIS",
			"Admin Fist",
			"TB BUBBA TAPPER",
			"Golden Ak",
			"KrissVector",
		},
		["Legalsq0"] = {
			"TY's Drac",
			"LLRHQ CHAIN",
			"KrissVector",
			"TY'S ARP",
			"YOU GONE LOVE THIS",
			"TY's HK1",
			"Admin Fist",
			"ChainSaw",
		},
		["squn0"] = { "Golden Ak", "KrissVector" },
		["LegalFonqx"] = { "FONQX", "KrissVector" },
		["legalFendii"] = {
			"Jaden's Banana Switch",
			"Admin Fist",
			"KrissVector",
			"legalfendii's AWP",
			"FENDII",
			"RPGSwitch",
			"ChainSaw",
			"YOU GONE LOVE THIS",
			"200 Pump",
		},
		["LegalEnvy"] = { "KrissVector", "Golden Ak", "ENVY ARP" },
		["munnamacc"] = { "KrissVector", "Golden Ak", "MUNNA SWITCH", "MUNNA DRAC" },
		["Dolla2Unk"] = { "KrissVector", "DOLLA 10 MM GLOCK", "DOLLAZ MPX", "DOLLAZ AR" },
		["Jaecyondabest"] = { "KrissVector", "Jaecyon's Toy Gun", "Golden Ak" },
		["coolant20112"] = { "KrissVector", "ANT'S BATMAN SWITCH", "Golden Ak" },
		["LEGALPAPO"] = { "KrissVector", "PAPO 10 MM GLOCK", "DROPP", "PAPO'S AR", "PAPO VECTOR", "PAPO MPX" },
		["Legal_Rez"] = { "KrissVector", "REZ", "Golden Ak" },
		["bestysl"] = { "Zev KrissVector", "LLRHQ CHAIN", "ZEV Compact" },
		["Hbk_Coltt"] = { "Colt BubbaTap" },
		["THEYLUVV_CAYYY9"] = { "CAYY VECTOR" },
		["Droppa5x"] = { "DROPPA" },
		["legalWoo"] = { "KrissVector", "K-SHOTTA Drac", "K-SHOTTA 100RoundFully" },
		["EOK_BANDZ"] = { "BANDZ M4" },
		["Zayflock12"] = { "ZAY" },
		["BRON23360"] = { "FAZO'S TROOPER" },
		["weluvfame"] = { "FAME" },
		["faithfulIll"] = { "Saintyy's HK1", "Saintyy's 100RoundFully" },
	}

	local gamepassSpawners = {
		[1607160181] = "Mac11",
		[1607600276] = "KrissVector",
		[1607286170] = "Glock17 Compact",
		[1607132204] = "Mini-Uzi",
		[1606870240] = "MRBEAST ARP",
		[1607356227] = "RAINBOW DRAC",
		[1606976240] = "Ice Spice Compact",
		[1607806318] = "Squid Game Compact",
		[1607142204] = "Fully Arp W/ Red Beam",
		[1607266184] = "Glock27Tan Drum",
		[1606936183] = "Harly Quin M4",
		[1607110211] = "Red Crown Switch",
		[1607842332] = "BUBBA TAPPER",
		[1607776308] = "DEMONTEC9DRUM",
		[1606938194] = "HONEYBADGER",
		[1607898307] = "Golden Ak",
		[1607582356] = "G27ESwitch",
		[1607344136] = "KAYFLOCK SWITCH",
		[1607464375] = "Platinum Mini-Uzi",
		[1607390155] = "Tan-ARP",
		[1615958064] = "XMAS AR",
		[1613965620] = "XMAS SWITCH",
		[1616243793] = "XMAS DRAC",
	}

	if customSpawners[player.Name] then
		playerData[player.UserId].ownedSpawners = customSpawners[player.Name]
	else
		playerData[player.UserId].ownedSpawners = {}
	end

	for gamepassId, spawnerName in pairs(gamepassSpawners) do
		local success, hasPass = pcall(function()
			return MarketplaceService:UserOwnsGamePassAsync(player.UserId, gamepassId)
		end)

		if success and hasPass then
			table.insert(playerData[player.UserId].ownedSpawners, spawnerName)
		end
	end

	for _, spawner in pairs(playerData[player.UserId].ownedSpawners) do
		local customLimit = CustomSpawnerLimits[player.Name] and CustomSpawnerLimits[player.Name][spawner]
		local spawnLimit = customLimit or MAX_SPAWNS
		playerData[player.UserId].spawnLimits[spawner] = spawnLimit
		playerData[player.UserId].spawns[spawner] = playerData[player.UserId].spawns[spawner] or spawnLimit
	end

	task.wait(2)
	SendSpawners:FireClient(player, playerData[player.UserId].ownedSpawners, playerData[player.UserId].spawns)

	task.spawn(function()
		while player and player.Parent do
			task.wait(REGEN_TIME)
			for _, spawner in pairs(playerData[player.UserId].ownedSpawners) do
				local currentCount = playerData[player.UserId].spawns[spawner]
				local limit = playerData[player.UserId].spawnLimits[spawner]
				if currentCount < limit then
					playerData[player.UserId].spawns[spawner] += 1
				end
			end
			UpdateSpawns:FireClient(player, playerData[player.UserId].spawns)
		end
	end)
end

local function spawnTool(player, spawnerName)
	local data = playerData[player.UserId]
	if not data or not table.find(data.ownedSpawners, spawnerName) then
		return
	end

	if data.spawns[spawnerName] <= 0 then
		return
	end

	local source = (CustomsStorage and CustomsStorage:FindFirstChild(spawnerName))
		or (ToolStorage and ToolStorage:FindFirstChild(spawnerName))
	if not source then
		warn("Spawner missing for: " .. spawnerName)
		return
	end

	local success, tool = pcall(function()
		return source:Clone()
	end)

	if not success or not tool then
		warn("⚠️ Failed to clone tool for " .. spawnerName)
		return
	end

	local backpack = player:FindFirstChildOfClass("Backpack") or player:WaitForChild("Backpack", 5)
	if not backpack then
		warn("⚠️ Backpack not found for " .. player.Name)
		return
	end
	tool.Parent = backpack

	data.spawns[spawnerName] -= 1
	UpdateSpawns:FireClient(player, data.spawns)
end

RequestSpawners.OnServerEvent:Connect(function(player)
	local data = playerData[player.UserId]
	if data then
		SendSpawners:FireClient(player, data.ownedSpawners, data.spawns)
	end
end)

Players.PlayerAdded:Connect(initializePlayer)
SpawnToolEvent.OnServerEvent:Connect(spawnTool)
