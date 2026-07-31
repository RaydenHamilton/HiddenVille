local hooks = {}

function hooks.init()
	-- Auto-create CivCars
	if not workspace:FindFirstChild("CivCars") then
		local f = Instance.new("Folder")
		f.Name = "CivCars"
		f.Parent = workspace
	end

	-- Services
	local DataStoreService = game:GetService("DataStoreService")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local TextService = game:GetService("TextService")
	local Players = game:GetService("Players")
	local ServerStorage = game:GetService("ServerStorage")
	local PlayerDataServerService =
		require(ReplicatedStorage.Shared.PlayerDataHandler.SystemPackage.PlayerDataServerService)

	-- DataStores
	local CarsData = DataStoreService:GetDataStore("HiddenvilleCarsRelease")

	-- Remotes
	local NotificationEvent = ReplicatedStorage:WaitForChild("Remotes"):FindFirstChild("Notification")
	local GarageEvent = ReplicatedStorage:FindFirstChild("GarageEvent")
	if not GarageEvent then
		GarageEvent = Instance.new("RemoteEvent")
		GarageEvent.Name = "GarageEvent"
		GarageEvent.Parent = ReplicatedStorage
	end

	-- State
	local alphabet = {}
	local process = {}
	local debounce = {}
	local licenses = {}
	local vinnumbers = {}
	local ownedCache = setmetatable({}, { __mode = "k" })
	local customizing = {}

	-- Constants
	local Colors = {
		"Bright red",
		"Bright orange",
		"Bright yellow",
		"Bright green",
		"Dark blue",
		"Light lilac",
		"Crimson",
		"Bright blue",
		"Dark indigo",
		"Royal purple",
		"Black",
		"Really black",
		"White",
		"Electric blue",
		"Dark stone grey",
		"Cool yellow",
		"Teal",
		"Fire Yellow",
		"Light grey metallic",
		"Bright bluish violet",
		"Earth green",
		"Hot pink",
		"Dark green",
		"Dark grey",
		"nil",
	}
	local Tints = { "None", "Light Smoke", "Medium Smoke", "Dark Smoke", "Limo" }

	-- Helpers
	for i = 97, 122 do
		table.insert(alphabet, utf8.char(i))
	end

	local function formatCash(n)
		local s = tostring(n)
		local k
		repeat
			s, k = s:gsub("^(-?%d+)(%d%d%d)", "%1,%2")
		until k == 0
		return "$" .. s
	end

	local function notify(p, m)
		if NotificationEvent then
			NotificationEvent:FireClient(p, m, "Notify")
		end
	end

	local function spawnNotifcation(p, m)
		if NotificationEvent then
			NotificationEvent:FireClient(p, m, "Car")
		end
	end

	local function generateVIN()
		local chars = "ABCDEFGHJKLMNPRSTUVWXYZ0123456789"
		local vin = ""
		for i = 1, 17 do
			local rand = math.random(1, #chars)
			vin ..= chars:sub(rand, rand)
		end
		return vin
	end

	-- Car template lookup (Step 1): prefer ServerStorage, fallback to RS for safety
	local function getCarTemplate(carName)
		local ssCars = ServerStorage:FindFirstChild("Cars") or ServerStorage:WaitForChild("Cars")
		local ss = ssCars and ssCars:FindFirstChild(carName)
		if ss then
			return ss
		end

		-- Transitional fallback ONLY (remove once RS.Cars is deleted/renamed)
		local rsCars = ReplicatedStorage:FindFirstChild("Cars")
		return rsCars and rsCars:FindFirstChild(carName) or nil
	end

	-- Profanity
	local function isPlateFiltered(txt, uid)
		local ok1, res = pcall(function()
			return TextService:FilterStringAsync(txt, uid)
		end)
		if not ok1 or not res then
			return true, "FILTER_FAIL"
		end
		local ok2, f = pcall(function()
			return res:GetNonChatStringForUserAsync(uid)
		end)
		if not ok2 then
			return true, "FILTER_FAIL"
		end
		local raw, low = txt:lower(), f:lower()
		return (low ~= raw) or low:match("^%*+$") or low:find("%*"), f
	end

	-- === PERMANENT PLATE RENDER FIX HELPERS ===
	local function parsePlateColor(colorStr)
		local r, g, b = tostring(colorStr or "0,0,0"):match("([^,]+),([^,]+),([^,]+)")
		r, g, b = tonumber(r), tonumber(g), tonumber(b)
		if not (r and g and b) then
			return Color3.new(0, 0, 0)
		end

		-- Support both 0-1 and 0-255 formats safely
		if r > 1 or g > 1 or b > 1 then
			return Color3.fromRGB(math.clamp(r, 0, 255), math.clamp(g, 0, 255), math.clamp(b, 0, 255))
		end

		return Color3.new(math.clamp(r, 0, 1), math.clamp(g, 0, 1), math.clamp(b, 0, 1))
	end

	local function makeDefaultPlateForPlayer(p)
		local name = p.DisplayName or p.Name or "AAA"
		local cleaned = name:upper():gsub("[^A-Z0-9]", "")
		local prefix = cleaned:sub(1, 3)
		if #prefix < 3 then
			prefix ..= string.rep("X", 3 - #prefix)
		end
		local digits = ("%03d"):format(math.random(0, 999))
		return prefix .. "-" .. digits
	end

	local function applyPlateFix(carModel, plateText, plateImage, plateColorStr)
		if not carModel or not carModel:IsA("Model") then
			return
		end
		local body = carModel:FindFirstChild("Body")
		if not body then
			return
		end

		local plateFolder = body:FindFirstChild("Plate")
			or body:FindFirstChild("Licence plate")
			or body:FindFirstChild("License plate")

		if not plateFolder then
			return
		end

		local col = parsePlateColor(plateColorStr)

		for _, sg in ipairs(plateFolder:GetDescendants()) do
			if sg:IsA("SurfaceGui") then
				-- Critical render fix (prevents decal/mesh from hiding UI)
				sg.AlwaysOnTop = false
				sg.ZOffset = math.max(sg.ZOffset, 5)

				for _, ui in ipairs(sg:GetDescendants()) do
					if ui:IsA("TextLabel") then
						ui.Text = tostring(plateText or "")
						ui.BackgroundTransparency = 1
						ui.TextTransparency = 0
						ui.TextColor3 = col
					end
				end

				-- Plate image decal/texture
				local plateImageObj = sg.Parent and sg.Parent:FindFirstChild("PlateImage")
				if plateImageObj and plateImage and plateImage ~= "" then
					if plateImageObj:IsA("Decal") or plateImageObj:IsA("Texture") then
						plateImageObj.Texture = plateImage
					end
				end
			end
		end
	end
	-- === END PLATE HELPERS ===

	-- Cached load/save
	local function loadPlayerCars(p)
		if ownedCache[p] then
			return ownedCache[p]
		end
		local carsOwned = {}
		local ok, data = pcall(function()
			return CarsData:GetAsync(p.UserId)
		end)
		if ok and type(data) == "table" then
			carsOwned = data
		end
		ownedCache[p] = carsOwned
		return carsOwned
	end

	local function savePlayerCars(p, carsOwned)
		ownedCache[p] = carsOwned
		local ok, err = pcall(function()
			CarsData:SetAsync(p.UserId, carsOwned)
		end)
		if not ok then
			warn("Failed to save cars for " .. p.Name .. ":" .. tostring(err))
		end
	end

	-- Global hooks
	if not _G.hookLicenseRemove then
		_G.hookLicenseRemove = function(l)
			if l then
				licenses[l] = nil
			end
		end
	end

	if not _G.hookCarRemove then
		_G.hookCarRemove = function(car, player)
			if customizing[player] then
				return
			end
			local carOwner = player or Players:FindFirstChild(car:FindFirstChild("Owner").Value)
			if not carOwner then
				return
			end
			local carsOwned = loadPlayerCars(carOwner)
			local cType = car:FindFirstChild("CarType") and car.CarType.Value
			if cType and carsOwned[cType] then
				carsOwned[cType]["Fuel"] = math.huge
			end
			savePlayerCars(carOwner, carsOwned)
			local seat = car:FindFirstChildOfClass("VehicleSeat")
			if seat and seat.Occupant then
				seat.Occupant.Jump = true
			end
			car:Destroy()
		end
	end

	if not _G.checkCarOwnership then
		_G.checkCarOwnership = function(p, c)
			local co = loadPlayerCars(p)
			return co[c] ~= nil
		end
	end

	if not _G.getCarInfo then
		_G.getCarInfo = function(p, c)
			return loadPlayerCars(p)[c] or nil
		end
	end

	-- Spawned helpers
	local function isCarSpawned(p)
		for _, v in ipairs(workspace:WaitForChild("CivCars"):GetChildren()) do
			if v:FindFirstChild("Owner") and v.Owner.Value == p.Name then
				return true
			end
		end
		task.wait()
		return false
	end

	local function getSpawnedCar(p)
		for _, v in ipairs(workspace:WaitForChild("CivCars"):GetChildren()) do
			if v:FindFirstChild("Owner") and v.Owner.Value == p.Name then
				return v
			end
		end
		task.wait()
		return nil
	end

	local function isBayFree(spawnPart, radius)
		for _, car in ipairs(workspace.CivCars:GetChildren()) do
			if car:IsA("Model") and car.PrimaryPart then
				if (car.PrimaryPart.Position - spawnPart.Position).Magnitude <= radius then
					return false
				end
			end
		end
		return true
	end

	local function pickDealerBay(radius)
		local parkingFolder = workspace.Map.UtilityBuildings["Car Dealer"].Parking
		local free = {}
		for _, bay in ipairs(parkingFolder:GetChildren()) do
			if bay.Name:match("^CarSpawn") and isBayFree(bay, radius) then
				table.insert(free, bay)
			end
		end
		if #free > 0 then
			return free[math.random(1, #free)]
		end
	end

	local function checkOccupied(p)
		local car = getSpawnedCar(p)
		if not car then
			return false
		end
		local ds = car:FindFirstChildOfClass("DriveSeat")
		if not ds then
			return false
		end
		if ds.Occupant then
			local hum = ds.Occupant
			local plr = hum and hum.Parent and Players:GetPlayerFromCharacter(hum.Parent)
			return plr ~= nil
		end
		return false
	end

	-- SPAWN
	if not _G.spawnCar then
		_G.spawnCar = function(p, carName)
			if not game.ServerStorage.Cars:FindFirstChild(carName) then
				return
			end
			if process[p] or debounce[p] then
				return
			end
			debounce[p], process[p] = true, true
			local done = false
			task.delay(2, function()
				debounce[p] = nil
			end)
			task.delay(2, function()
				if process[p] and not done then
					process[p] = nil
					done = true
				end
			end)

			if isCarSpawned(p) then
				local occ = checkOccupied(p)
				if not occ then
					_G.hookCarRemove(getSpawnedCar(p), p)
				else
					process[p] = nil
					return
				end
			end

			repeat
				task.wait(0.1)
			until not isCarSpawned(p)

			local carsOwned = loadPlayerCars(p)
			if carsOwned[carName] then
				local clon = game.ServerStorage.Cars[carName]:Clone()
				clon.FUEL.Value = (carsOwned[carName] and carsOwned[carName]["Fuel"]) or math.huge
				clon.Owner.Value = p.Name
				if clon.FUEL.Value == 0 then
					clon.FUEL.Value = math.huge
				end

				do
					local carInfo = carsOwned[carName]

					-- Paint
					local paint = carInfo["EXTRA"] or "White"
					if clon:FindFirstChild("Body") and clon.Body:FindFirstChild("CHANGE") then
						for _, part in ipairs(clon.Body.CHANGE:GetChildren()) do
							if part:IsA("MeshPart") or part:IsA("Part") then
								part.BrickColor = BrickColor.new(paint)
							end
						end
					end

					-- Underglow
					local underglow = carInfo["EXTRA2"]
					if underglow and clon:FindFirstChild("Body") and clon.Body:FindFirstChild("Underglow") then
						for _, neon in ipairs(clon.Body.Underglow:GetChildren()) do
							if neon.Name == "Neon" then
								local light = neon:FindFirstChild("PointLight")
								if light then
									if underglow == "None" then
										light.Enabled = false
									else
										light.Color = BrickColor.new(underglow).Color
										light.Enabled = true
									end
								end
							end
						end
					end

					-- Tint
					local tint = carInfo["EXTRA3"] or "None"
					if clon:FindFirstChild("Body") and clon.Body:FindFirstChild("Windows") then
						for _, w in ipairs(clon.Body.Windows:GetChildren()) do
							w.Transparency = ({
								None = 0.9,
								["Light Smoke"] = 0.7,
								["Medium Smoke"] = 0.5,
								["Dark Smoke"] = 0.3,
								["Limo"] = 0,
							})[tint] or 0.9
						end
					end

					-- Rims
					local rimColor = carInfo["EXTRA4"] or "White"
					if clon:FindFirstChild("Wheels") then
						for _, r in ipairs(clon.Wheels:GetDescendants()) do
							if (r:IsA("MeshPart") or r:IsA("Part")) and r.Name == "Rim" then
								r.BrickColor = BrickColor.new(rimColor)
							end
						end
					end

					-- Plate: ensure stable defaults, persist if missing, and store attributes for post-parent fix
					local plateData = carInfo["EXTRA6"]
					if type(plateData) ~= "table" then
						plateData = {}
					end

					plateData.Image = plateData.Image or "rbxassetid://4751081104"
					plateData.Color = plateData.Color or "0,0,0"

					local wrote = false

					if type(plateData.Text) ~= "string" or plateData.Text == "" then
						plateData.Text = makeDefaultPlateForPlayer(p)
						wrote = true
					end

					if wrote then
						carInfo["EXTRA6"] = plateData
						carsOwned[carName]["EXTRA6"] = plateData
						savePlayerCars(p, carsOwned)
					end

					clon:SetAttribute("PlateText", plateData.Text)
					clon:SetAttribute("PlateImage", plateData.Image)
					clon:SetAttribute("PlateColor", plateData.Color)
				end

				local spawn = pickDealerBay(12)
				if not spawn then
					process[p] = nil
					done = true
					notify(p, "No free bay.")
					return
				end

				clon:SetPrimaryPartCFrame(spawn.CFrame)
				clon.Parent = workspace.CivCars
				clon.Name = p.Name .. "'s Car"

				-- Apply plate render fix AFTER parenting (and re-apply after 1s to beat late init scripts)
				do
					local t = clon:GetAttribute("PlateText")
					local img = clon:GetAttribute("PlateImage")
					local col = clon:GetAttribute("PlateColor")

					applyPlateFix(clon, t, img, col)
					task.delay(1, function()
						if clon and clon.Parent then
							applyPlateFix(clon, t, img, col)
						end
					end)
				end

				local vin = Instance.new("StringValue")
				vin.Name = "VIN"
				vin.Value = generateVIN()
				vin.Parent = clon
				vinnumbers[clon] = vin.Value

				spawnNotifcation(p, "Your " .. carName .. " has been spawned!")
			end

			process[p] = nil
			done = true
		end
	end

	-- BUY
	if not _G.hookCarBuy then
		_G.hookCarBuy = function(p, carName)
			local carTemplate = getCarTemplate(carName)
			if not carTemplate then
				return
			end

			local Price = carTemplate:FindFirstChild("Price")
			if not Price then
				return
			end

			local RequiredLevel = carTemplate:FindFirstChild("RequiredLevel")
			const Level = PlayerDataServerService.get(p, "Level")
			if Level and RequiredLevel and Level < RequiredLevel.Value then
				notify(p, "You must be Level " .. RequiredLevel.Value .. " to buy this car.")
				return
			end

			local Money = PlayerDataServerService.get(p, "Money")

			if Money < Price.Value then
				notify(p, "You cannot afford this car.")
				return
			end

			local carsOwned = loadPlayerCars(p) or {}
			if carsOwned[carName] then
				notify(p, "You already own this car.")
				return
			end

			PlayerDataServerService.add(p, "Money", -Price.Value)

			carsOwned[carName] = {
				Fuel = math.huge,
				Miles = 0,
				Settings = {},
				EXTRA = "White",
				EXTRA2 = "None",
				EXTRA3 = "None",
				EXTRA4 = "White",
				EXTRA5 = "None",
				EXTRA6 = { Image = "rbxassetid://4751081104", Text = nil, Color = "0,0,0" },
			}
			savePlayerCars(p, carsOwned)

			notify(p, "You bought a " .. carName .. " for " .. formatCash(Price.Value) .. "!")
			if ReplicatedStorage:FindFirstChild("server") then
				ReplicatedStorage.server:FireClient(p, "money", Price.Value)
			end
		end
	end

	-- SELL
	if not _G.hookCarSell then
		_G.hookCarSell = function(player, carName)
			if not game.ServerStorage:FindFirstChild("Cars") or not game.ServerStorage.Cars:FindFirstChild(carName) then
				warn(carName .. " does not exist.")
				return
			end
			local Price = game.ServerStorage.Cars[carName]:FindFirstChild("Price")
			local Money = PlayerDataServerService.get(player, "Money")
			if not (Price and Money) then
				return
			end
			local carsOwned = loadPlayerCars(player)
			if not carsOwned[carName] then
				notify(player, "You do not own this car.")
				return
			end
			local payout = math.floor(Price.Value / 2)

			PlayerDataServerService.add(player, "Money", payout)
			carsOwned[carName] = nil
			savePlayerCars(player, carsOwned)
			local spawnedCar = workspace:FindFirstChild("CivCars")
				and workspace.CivCars:FindFirstChild(player.Name .. "'s Car")
			if spawnedCar then
				local seat = spawnedCar:FindFirstChild("DriveSeat")
				if seat and seat.Occupant then
					seat.Occupant.Jump = true
				end
				spawnedCar:Destroy()
			end
			notify(player, "You sold your " .. carName .. " for " .. formatCash(payout) .. "!")
		end
	end

	-- GARAGE / CUSTOMIZATION

	-- PAINT (EXTRA)
	if not _G.HookCarExtra then
		_G.HookCarExtra = function(p, car, color)
			if not game.ServerStorage.Cars:FindFirstChild(car) then
				return
			end
			local current = workspace:FindFirstChild("CivCars") and workspace.CivCars:FindFirstChild(p.Name .. "'s Car")
			if not current then
				return
			end
			if not table.find(Colors, color) then
				return
			end

			local Wallet = PlayerDataServerService.get(p, "Money")
			local carsOwned = loadPlayerCars(p)
			if not carsOwned[car] then
				return
			end

			if carsOwned[car]["EXTRA"] == color then
				notify(p, "You already have this paint color.")
				return
			end

			if Wallet >= 2000 then
				PlayerDataServerService.add(p, "Money", -2000)
				carsOwned[car]["EXTRA"] = color
				savePlayerCars(p, carsOwned)

				local change = current:FindFirstChild("Body") and current.Body:FindFirstChild("CHANGE")
				if change then
					for _, part in pairs(change:GetChildren()) do
						if part:IsA("MeshPart") or part:IsA("Part") then
							part.BrickColor = BrickColor.new(color)
						end
					end
				end

				notify(p, "You changed your car color to " .. color .. " for " .. formatCash(2000) .. "!")
				if ReplicatedStorage:FindFirstChild("server") then
					ReplicatedStorage.server:FireClient(p, "money", 2000)
				end
			else
				notify(p, "You cannot afford this paint.")
			end
		end
	end

	-- UNDERGLOW (EXTRA2)
	if not _G.HookCarExtra2 then
		_G.HookCarExtra2 = function(p, car, underglow)
			if not game.ServerStorage.Cars:FindFirstChild(car) then
				return
			end
			local current = workspace.CivCars:FindFirstChild(p.Name .. "'s Car")
			if not current then
				return
			end
			if not table.find(Colors, underglow) then
				return
			end

			local Wallet = PlayerDataServerService.get(p, "Money")

			local carsOwned = loadPlayerCars(p)
			if not carsOwned[car] then
				return
			end

			if carsOwned[car]["EXTRA2"] == underglow then
				notify(p, "You already have this underglow.")
				return
			end

			local isNone = (underglow == "None")
			if Wallet >= 1000 or isNone then
				if not isNone then
					PlayerDataServerService.add(p, "Money", -1000)
				end
				carsOwned[car]["EXTRA2"] = underglow
				savePlayerCars(p, carsOwned)

				local u = current:FindFirstChild("Body") and current.Body:FindFirstChild("Underglow")
				if u then
					for _, v in ipairs(u:GetChildren()) do
						if v.Name == "Neon" then
							local light = v:FindFirstChild("PointLight")
							if light then
								if isNone then
									light.Enabled = false
									notify(p, "You removed your underglow.")
								else
									light.Color = BrickColor.new(underglow).Color
									light.Enabled = true
									notify(p, "You added " .. underglow .. " underglow for " .. formatCash(1000) .. "!")
								end
							end
						end
					end
				end

				if not isNone and ReplicatedStorage:FindFirstChild("server") then
					ReplicatedStorage.server:FireClient(p, "money", 1000)
				end
			else
				notify(p, "You cannot afford this underglow.")
			end
		end
	end

	-- TINT (EXTRA3)
	if not _G.HookCarExtra3 then
		_G.HookCarExtra3 = function(p, car, tint)
			if not game.ServerStorage.Cars:FindFirstChild(car) then
				return
			end
			local current = workspace.CivCars:FindFirstChild(p.Name .. "'s Car")
			if not current then
				return
			end
			if not table.find(Tints, tint) and tint ~= "nil" then
				return
			end

			local Wallet = PlayerDataServerService.get(p, "Money")
			local carsOwned = loadPlayerCars(p)
			if not carsOwned[car] then
				return
			end

			if carsOwned[car]["EXTRA3"] == tint then
				notify(p, "You already have this tint.")
				return
			end

			if Wallet >= 1000 or tint == "nil" then
				if tint ~= "nil" then
					PlayerDataServerService.add(p, "Money", -1000)
				end
				carsOwned[car]["EXTRA3"] = tint
				savePlayerCars(p, carsOwned)

				local windows = current:FindFirstChild("Body") and current.Body:FindFirstChild("Windows")
				if windows then
					for _, v in ipairs(windows:GetChildren()) do
						v.Transparency = ({
							None = 0.9,
							["Light Smoke"] = 0.7,
							["Medium Smoke"] = 0.5,
							["Dark Smoke"] = 0.3,
							["Limo"] = 0,
						})[tint] or 0.9
					end
				end

				if tint ~= "nil" then
					notify(p, "You applied " .. tint .. " window tint for " .. formatCash(1000) .. "!")
					if ReplicatedStorage:FindFirstChild("server") then
						ReplicatedStorage.server:FireClient(p, "money", 1000)
					end
				else
					notify(p, "You reset your window tint.")
				end
			else
				notify(p, "You cannot afford this tint.")
			end
		end
	end

	-- RIMS (EXTRA4)
	if not _G.HookCarExtra4 then
		_G.HookCarExtra4 = function(p, car, color)
			if not game.ServerStorage.Cars:FindFirstChild(car) then
				return
			end
			local current = workspace.CivCars:FindFirstChild(p.Name .. "'s Car")
			if not current then
				return
			end
			if not table.find(Colors, color) then
				return
			end

			local Wallet = PlayerDataServerService.get(p, "Money")
			local carsOwned = loadPlayerCars(p)
			if not carsOwned[car] then
				return
			end

			if carsOwned[car]["EXTRA4"] == color then
				notify(p, "You already have this rim color.")
				return
			end

			if Wallet >= 1500 then
				PlayerDataServerService.add(p, "Money", -1500)
				carsOwned[car]["EXTRA4"] = color
				savePlayerCars(p, carsOwned)

				local wheels = current:FindFirstChild("Wheels")
				if wheels then
					for _, rim in pairs(wheels:GetDescendants()) do
						if (rim:IsA("MeshPart") or rim:IsA("Part")) and rim.Name == "Rim" then
							rim.BrickColor = BrickColor.new(color)
						end
					end
				end

				notify(p, "You changed your rim color to " .. color .. " for " .. formatCash(1500) .. "!")
				if ReplicatedStorage:FindFirstChild("server") then
					ReplicatedStorage.server:FireClient(p, "money", 1500)
				end
			else
				notify(p, "You cannot afford this rim color.")
			end
		end
	end

	-- WRAP (EXTRA5)
	if not _G.HookCarExtra5 then
		_G.HookCarExtra5 = function(p, car, wrap)
			if not game.ServerStorage.Cars:FindFirstChild(car) then
				return
			end
			local playerCar = workspace.CivCars:FindFirstChild(p.Name .. "'s Car")
			if not playerCar then
				return
			end

			local wrapFolder = ReplicatedStorage:FindFirstChild("CarWraps")
			if not wrapFolder then
				return
			end
			local wrapObject = wrapFolder:FindFirstChild(wrap)
			if not wrapObject and wrap ~= "None" then
				return
			end

			local Wallet = PlayerDataServerService.get(p, "Money")

			local carsOwned = loadPlayerCars(p)
			if not carsOwned[car] then
				return
			end

			if carsOwned[car]["EXTRA5"] == wrap then
				notify(p, "You already have this wrap.")
				return
			end

			if Wallet >= 1500 then
				PlayerDataServerService.add(p, "Money", -1500)
				carsOwned[car]["EXTRA5"] = wrap
				savePlayerCars(p, carsOwned)

				local changeFolder = playerCar:FindFirstChild("Body") and playerCar.Body:FindFirstChild("CHANGE")
				if changeFolder then
					for _, part in ipairs(changeFolder:GetChildren()) do
						if part:IsA("BasePart") then
							if part:IsA("MeshPart") then
								part.TextureID = ""
							end
							for _, child in ipairs(part:GetChildren()) do
								if child:IsA("Decal") or child:IsA("Texture") or child:IsA("SurfaceAppearance") then
									child:Destroy()
								end
							end
						end
					end
					if wrap ~= "None" then
						notify(p, "You applied a " .. wrap .. " wrap for " .. formatCash(1500) .. "!")
					else
						notify(p, "You removed your car wrap.")
					end
				end

				if ReplicatedStorage:FindFirstChild("server") then
					ReplicatedStorage.server:FireClient(p, "money", 1500)
				end
			else
				notify(p, "You cannot afford this wrap.")
			end
		end
	end

	-- PLATE (EXTRA6)
	if not _G.HookCarExtra6 then
		_G.HookCarExtra6 = function(p, car, plateImage, plateText, plateColor)
			if not game.ServerStorage.Cars:FindFirstChild(car) then
				return
			end
			local playerCar = workspace.CivCars:FindFirstChild(p.Name .. "'s Car")
			if not playerCar then
				return
			end

			local Wallet = PlayerDataServerService.get(p, "Money")
			local carsOwned = loadPlayerCars(p)
			if not carsOwned[car] then
				return
			end

			local saved = carsOwned[car]["EXTRA6"] or { Image = "", Text = "", Color = "1,1,1" }

			local changedImage = plateImage ~= saved.Image
			local changedText = plateText ~= saved.Text
			local changedColor = tostring(plateColor) ~= tostring(saved.Color)

			if not (changedImage or changedText or changedColor) then
				notify(p, "You already have this plate setup.")
				return
			end

			if changedText then
				if typeof(plateText) ~= "string" or plateText == "" then
					notify(p, "Plate text cannot be empty.")
					return
				end
				if not plateText:match("^[%w%-]+$") then
					notify(p, "Only letters, numbers, and '-' allowed.")
					return
				end
				if #plateText < 5 or #plateText > 7 then
					print("no")
					notify(p, "Plate text must be 5 to 7 characters long.")
					return
				end
				local filtered, filteredText = isPlateFiltered(plateText or "", p.UserId)
				if filtered then
					print(
						string.format(
							"[Suspicious Plate] %s (%d) tried '%s' → '%s'",
							p.Name,
							p.UserId,
							plateText,
							filteredText
						)
					)
					notify(p, "Plate contains inappropriate language. Purchase cancelled.")
					return
				end
			end

			local cost = 0
			if changedImage then
				cost += 450
			end
			if changedText then
				cost += 500
			end
			if changedColor then
				cost += 250
			end

			if Wallet < cost then
				notify(p, "You cannot afford this plate customization (" .. formatCash(cost) .. ").")
				return
			end

			PlayerDataServerService.add(p, "Money", cost)

			carsOwned[car]["EXTRA6"] = {
				Image = plateImage,
				Text = changedText and plateText or saved.Text,
				Color = tostring(plateColor),
			}
			savePlayerCars(p, carsOwned)

			-- Permanent render fix for "broken" cars
			local pd = carsOwned[car]["EXTRA6"]
			applyPlateFix(playerCar, pd.Text, pd.Image, pd.Color)
			task.delay(1, function()
				if playerCar and playerCar.Parent then
					applyPlateFix(playerCar, pd.Text, pd.Image, pd.Color)
				end
			end)

			notify(p, "You customized your license plate for " .. formatCash(cost) .. "!")
			if ReplicatedStorage:FindFirstChild("server") then
				ReplicatedStorage.server:FireClient(p, "money", cost)
			end
		end
	end

	-- leave/despawn
	Players.PlayerRemoving:Connect(function(p)
		customizing[p] = nil
		ownedCache[p] = nil
		for _, v in pairs(workspace.CivCars:GetChildren()) do
			if v:FindFirstChild("DriveSeat") and v:FindFirstChild("Owner") and v.Owner.Value == p.Name then
				local DS = v:FindFirstChild("DriveSeat")
				local seats = { DS }
				local body = v:FindFirstChild("Body")
				if body then
					for _, s in pairs(body:GetChildren()) do
						if s:IsA("Seat") or s:IsA("VehicleSeat") then
							table.insert(seats, s)
						end
					end
				end
				for _, seat in pairs(seats) do
					if seat and seat.Occupant then
						seat.Occupant.Jump = true
						repeat
							task.wait()
						until seat.Occupant == nil
					end
					if seat then
						seat:Destroy()
					end
				end
				_G.hookCarRemove(v, p)
			end
		end
	end)

	-- Main remote
	ReplicatedStorage:WaitForChild("Remotes")
		:WaitForChild("CarHandler").OnServerEvent
		:Connect(function(Player, String, Car, Extra)
			if String == "CustomizeStart" then
				customizing[Player] = true
				return
			end
			if String == "CustomizeEnd" then
				customizing[Player] = nil
				return
			end
			if not game.ServerStorage.Cars:FindFirstChild(Car) and (String == "Spawn" or String:match("^Buy")) then
				return
			end
			if String == "Spawn" then
				_G.spawnCar(Player, Car)
			elseif String == "Buy" then
				_G.hookCarBuy(Player, Car)
			elseif String == "Sell" then
				_G.hookCarSell(Player, Car)
			elseif String == "BuyExtra" then
				_G.HookCarExtra(Player, Car, Extra)
			elseif String == "BuyExtra2" then
				_G.HookCarExtra2(Player, Car, Extra)
			elseif String == "BuyExtra3" then
				_G.HookCarExtra3(Player, Car, Extra)
			elseif String == "BuyExtra4" then
				_G.HookCarExtra4(Player, Car, Extra)
			elseif String == "BuyExtra5" then
				_G.HookCarExtra5(Player, Car, Extra)
			elseif String == "BuyExtra6" then
				local plateImage = Extra.Image
				local plateText = Extra.Text
				local plateColor = Extra.Color
				_G.HookCarExtra6(Player, Car, plateImage, plateText, plateColor)
			else
				Player:Kick()
			end
		end)

	-- Proximity hooks: Garage open + Despawn/Return
	local function hookPrompt(pp)
		if not pp or not pp:IsA("ProximityPrompt") then
			return
		end
		local action = (pp:GetAttribute("CarAction") or pp.Name or ""):lower()

		if action:find("customize") or action:find("editor") then
			pp.Triggered:Connect(function(player)
				customizing[player] = true
				GarageEvent:FireClient(player, "Open")
			end)
			return
		end

		if action:find("garage") or action:find("open garage") then
			pp.Triggered:Connect(function(player)
				GarageEvent:FireClient(player, "Open")
			end)
			return
		end

		if action:find("despawn") or action:find("return") then
			pp.Triggered:Connect(function(player)
				if customizing[player] then
					return
				end
				local car = getSpawnedCar(player)
				if car then
					_G.hookCarRemove(car, player)
				end
				GarageEvent:FireClient(player, "Close")
			end)
		end
	end

	for _, d in ipairs(workspace:GetDescendants()) do
		if d:IsA("ProximityPrompt") then
			hookPrompt(d)
		end
	end

	workspace.DescendantAdded:Connect(function(obj)
		if obj:IsA("ProximityPrompt") then
			hookPrompt(obj)
		end
	end)

	-- RemoteFunctions
	ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("FilteredTag").OnServerInvoke = function(p, t)
		local b, _ = isPlateFiltered(t or "", p.UserId)
		return b
	end

	ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("GetOwnedCars").OnServerInvoke = function(p)
		return loadPlayerCars(p)
	end
end
return hooks
