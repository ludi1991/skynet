local fp_calculator = {}
--[[
{
	["config"] = {
		["soulid_1v1"] = 1,
		["soulid_3v3"] = {
			[1] = 1,
			[2] = 2,
			[3] = 3,
		},
	},
	["items"] = {
		[1000001] = {
			["itemextra"] = 100,
			["itemid"] = 1000001,
			["itemtype"] = 1000001,
			["itemcount"] = 55,
		},
		[1] = {
			["itemextra"] = 100,
			["itemid"] = 1,
			["itemtype"] = 2010101,
			["itemcount"] = 1,
		},
	},
	["playerid"] = 189,
	["souls"] = {
		[1] = {
			["itemids"] = {
				[8] = -1,
				[1] = 1,
				[2] = -1,
				[3] = -1,
				[4] = -1,
				[5] = -1,
				[6] = -1,
				[7] = -1,
			},
			["soulid"] = 1,
			["soul_girl_id"] = 1,
		},
	},
	["tasks"] = {
		[1] = {
			["percent"] = 0,
			["taskid"] = 1,
		},
	},
	["basic"] = {
		["level"] = 2,
		["nickname"] = "new91652",
		["diamond"] = 0,
		["last_login_time"] = "2015-11-06 21:27:23",
		["gold"] = 3723,
		["playerid"] = 189,
		["cursoul"] = 1,
		["cur_stayin_level"] = 1,
		["create_time"] = "2015-11-06 16:15:40",
	},
}
]]
local equipManager = require "controller.equip_manager"
local modelManager = require "controller.model_manager"
local equipData    = require "data.equipdata"

--单个武器娘属性   
function fp_calculator:get_soul_fightpower(player,soulid)
	log ("get_soul_fightpower")
	local playerbasic = player["basic"]
	local playersoul = player["souls"]
	local items = {}
	local strInfo = equipManager:getStrengthenTab()
        local pairs = pairs
	for k,v in pairs(playersoul) do
		if v.soul_girl_id == soulid then
			for k1,v1 in pairs(v.itemids) do
				if v1 ~= -1 and player.items[v1] then
					local itemtmp = player.items[v1]
					local quality = equipData[itemtmp.itemtype].equip_quality
					local level   = itemtmp.itemextra%100
					local value   = 0
			        if strInfo[quality][level] then
			            value = strInfo[quality][level].strengthen_attribute
			            if equipData[itemtmp.itemtype].main_attribute == "hp" then value = value*10 end
			        end
					items[itemtmp.itemid] = {itemid = itemtmp.itemid, itemtype = math.floor(itemtmp.itemtype/100000), item_entity_id = itemtmp.itemtype,
                           					equiped = true, strengthenLv = level, strengthenValue = value, number = itemtmp.itemcount}
				end
			end
		end
	end
	local character = modelManager:generateCharacter(playerbasic.level, soulid, items)
	return character.power
end

-- 所有武器娘的属性
function fp_calculator:get_player_fightpower(player)
	log ("get_player_fightpower")
	local power = 0
	local playersoul = player["souls"]
	local items = {}
	for k,v in pairs(playersoul) do
		local character = self:get_soul_fightpower(player, v.soul_girl_id)
		power = power + character.power
	end
	return power
end



return fp_calculator
