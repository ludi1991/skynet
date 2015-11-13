local cal_fight_power = {}
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


function cal_fight_power:get_soul_fightpower(player,soulid)
	log ("get_soul_fightpower")
	-- TODO: get fight power
	return 38
end

function cal_fight_power:get_player_fightpower(player)
	log ("get_player_fightpower")
	-- TODO: get player fight power
    return 456 
end



return cal_fight_power