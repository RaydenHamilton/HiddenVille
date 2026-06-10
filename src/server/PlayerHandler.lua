PlayerHandler = {}

PlayerHandler.__index = PlayerHandler

local function getPlayerData(player)


	local defaultData= {
		Money = 0,
		XP = 0,
        Level = 1,
        kills = 0,
        ClaimedGroup = false,

	}

	return defaultData
end

function PlayerHandler.new(player)
	local self = setmetatable({}, PlayerHandler)
	self.player = player
	self.Data = getPlayerData(player)
	return self
end

function PlayerHandler:AddMoney(amount)
	self.Data.Money = self.Data.Money + amount
end

function PlayerHandler:SetData()
    self = nil
end

return PlayerHandler
