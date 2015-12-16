local skynet = require "skynet"
require "skynet.manager"	-- import skynet.register
local player_data = {}

local count = 0

local command = {}

local function get_robot_data(playerid)
    local player = {}    
    player.basic = {
        playerid = playerid,
        nickname = "robot"..playerid,
        diamond = 0,
        gold = 0,
        create_time = os.date("%Y-%m-%d %X"),
        level = 1,
        last_login_time = os.date("%Y-%m-%d %X"),
        cursoul = 1,
        cur_stayin_level = 1,
        head_sculpture = 1,
    }

    player.items = { 
    [1] = {
            ["itemcount"] = 1,
            ["itemtype"] = 2010301,
            ["itemextra"] = 107,
            ["itemid"] = 1,
        },
        [2] = {
            ["itemcount"] = 1,
            ["itemtype"] = 2010201,
            ["itemextra"] = 107,
            ["itemid"] = 2,
        },
        [3] = {
            ["itemcount"] = 1,
            ["itemtype"] = 2010301,
            ["itemextra"] = 106,
            ["itemid"] = 3,
        },
        [4] = {
            ["itemcount"] = 1,
            ["itemtype"] = 2010301,
            ["itemextra"] = 100,
            ["itemid"] = 4,
        },
        [5] = {
            ["itemcount"] = 1,
            ["itemtype"] = 2010401,
            ["itemextra"] = 105,
            ["itemid"] = 5,
        },
        [6] = {
            ["itemcount"] = 1,
            ["itemtype"] = 2010501,
            ["itemextra"] = 107,
            ["itemid"] = 6,
        },
        [7] = {
            ["itemcount"] = 1,
            ["itemtype"] = 2020101,
            ["itemextra"] = 107,
            ["itemid"] = 7,
        },
        [8] = {
            ["itemcount"] = 1,
            ["itemtype"] = 2010601,
            ["itemextra"] = 101,
            ["itemid"] = 8,
        },
        [9] = {
            ["itemcount"] = 1,
            ["itemtype"] = 2020201,
            ["itemextra"] = 102,
            ["itemid"] = 9,
        },
        [10] = {
            ["itemcount"] = 1,
            ["itemtype"] = 2020301,
            ["itemextra"] = 104,
            ["itemid"] = 10,
        },
        [11] = {
            ["itemcount"] = 1,
            ["itemtype"] = 2010701,
            ["itemextra"] = 103,
            ["itemid"] = 11,
        },
        [12] = {
            ["itemcount"] = 1,
            ["itemtype"] = 2010801,
            ["itemextra"] = 105,
            ["itemid"] = 12,
        },
        [13] = {
            ["itemcount"] = 1,
            ["itemtype"] = 2020401,
            ["itemextra"] = 100,
            ["itemid"] = 13,
        },
    }
    player.souls = { 
        {   
            soulid = 1 , 
            itemids = { 1,2,-1,-1,-1,-1,-1,-1 } , 
            soul_girl_id = 1
        } , 
        {   
            soulid = 2, 
            itemids = { 3,4,-1,-1,-1,-1,-1,-1} ,
            soul_girl_id = 2
        } ,
        {
            soulid = 3, 
            itemids = { 5,6,-1,-1,-1,-1,-1,-1} ,
            soul_girl_id = 3,
        } ,
        {
            soulid = 4, 
            itemids = { 7,-1,8,-1,9,-1,-1,-1} ,
            soul_girl_id = 4,
        }
    }


    player.tasks = { }
    player.config =
    {
        soulid_1v1 = 1 ,
        soulid_3v3 = { 1,2,4 } ,
        finished_tasks = {} ,
        guide_step = 0,
        task_total_score = 0,
    }
    player.friend = {
        905,904,903
    }
    player.stat = 
    {
        gold_consumed = 0 ,
        diamond_consumed = 0 , 
        melt_times = 0 ,
        total_online_time = 0 ,
        kill_boss = 0,
        quick_fight = 0,
        lab_harvest = 0,
        lab_steal = 0,
        lab_help = 0,
        arena_single_times = 0,
        arena_team_times = 0,
        arena_single_victory = 0,
        arena_team_victory = 0,
        fight_power = { [1] = 77 , [2] = 25, [3] = 37,[4] = 55},
        daily = {
            strengthen_equip = 0,
            upgrade_equip = 0,
            inset_gem = 0,
            upgrage_gem = 0,
            arena_single_times = 0,
            arena_team_times = 0,
            arena_single_victory = 0,
            arena_team_victory = 0,
            lab_harvest = 0,
            lab_steal = 0,
            lab_help = 0,
            kill_boss,
            quick_fight = 0,
        }
    }
    return player,4
end


-- 1:from online player
-- 2:from mysql
-- 3:from memory
-- 4:from robot
local function get_player_data(playerid)
    if playerid > 1000000 then
        return get_robot_data(playerid)
    else
        local source_from

        local res,agent = skynet.call("ONLINE_CENTER","lua","is_online",playerid)
        if res then
        	local res,data = pcall(skynet.call, agent, "lua", "get_data")
        	if res then
        	    player_data[playerid] = data
                source_from = 1
                return player_data[playerid],source_from
        	else
                log("agent not exist")
            end
        end

    	if not player_data[playerid] then
    		local sqlstr = "SELECT data FROM L2.player_savedata where playerid = "..playerid;
    	    local res = skynet.call("MYSQL_SERVICE","lua","query",sqlstr)
    	    if res and res[1] then
    	    	local _,player = pcall(load("return "..res[1].data))
    	    	player_data[playerid] = player
                source_from = 2
    	    	return player,source_from
    	    else
    	    	log(" get_data_from_mysql failed : playerid = "..playerid)
                return {},-1
    	    end
    	else
            source_from = 3
    		return player_data[playerid],source_from
    	end
    end
end

-- 
function command.GENERATE_SOUL_ITEMS(playerid,soulid)
    local data = get_player_data(playerid)
    local items = {}
    --log(dump(data.souls))
    if type(soulid) == "number" then
        soulid = { soulid }
    end
    for _,id in pairs(soulid) do
        if data.souls[id] ~= nil then
            for i,v in pairs(data.souls[id].itemids) do
                if v ~= -1 then
                    items[v] = data.items[v]
                end
            end
        end
    end
    return items
end

function command.CREATE_PLAYER(nickname)
	local player = {}
    local sqlstr = "SELECT playerid FROM L2.player_savedata order by playerid desc limit 1"
	local newplayerid = skynet.call("MYSQL_SERVICE","lua","query",sqlstr)[1].playerid + 1

    player.basic = {
        playerid = newplayerid,
        nickname = nickname..newplayerid,
        diamond = 0,
        gold = 0,
        create_time = os.date("%Y-%m-%d %X"),
        level = 1,
        last_login_time = os.date("%Y-%m-%d %X"),
        cursoul = 1,
        cur_stayin_level = 1,
        head_sculpture = 1,
    }

    player.items = { }
    player.souls = { { soulid = 1 , itemids = { -1,-1,-1,-1,-1,-1,-1,-1 } , soul_girl_id = 1} }
    player.tasks = { }
    player.config =
    {
        soulid_1v1 = 1 ,
        soulid_3v3 = { 1,2,3 } ,
        finished_tasks = {} ,
        guide_step = 0,
        task_total_score = 0,
    }
    player.friend = {
        905,904,903
    }
    player.stat = 
    {
        gold_consumed = 0 ,
        diamond_consumed = 0 , 
        melt_times = 0 ,
        total_online_time = 0 ,
        kill_boss = 0,
        quick_fight = 0,
        lab_harvest = 0,
        lab_steal = 0,
        lab_help = 0,
        arena_single_times = 0,
        arena_team_times = 0,
        arena_single_victory = 0,
        arena_team_victory = 0,
        fight_power = { [1] = 77 , [2] = 25, [3] = 37,[4] = 55},
        daily = {
            strengthen_equip = 0,
            upgrade_equip = 0,
            inset_gem = 0,
            upgrage_gem = 0,
            arena_single_times = 0,
            arena_team_times = 0,
            arena_single_victory = 0,
            arena_team_victory = 0,
            lab_harvest = 0,
            lab_steal = 0,
            lab_help = 0,
            kill_boss = 0,
            quick_fight = 0,
        }
    }
	return newplayerid,player
end


function command.GET_PLAYER_DATA(playerid)
    return get_player_data(playerid)
end


function command.GET_PLAYER_DATA_PART(playerid,part)
	local data = get_player_data(playerid)	-- body
	return data[part]
end


function command.GET_PLAYER_FIGHT_DATA(playerid,soulid)
	local data = get_player_data(playerid)
	local items = {}
	log("playerid"..playerid.."soulid"..soulid)
	--log(dump(data.souls))
	for i,v in pairs(data.souls[soulid].itemids) do
		if v ~= -1 then
			items[v] = data.items[v]
		end
	end
	return { soul = data.souls[soulid],items = items }
end



-- list type 1 rank  2 arena
function command.GET_PLAYER_FIGHTPOWER(playerid,ranktype,listtype)
    local player = get_player_data(playerid)
    log("get_player_fightpower "..playerid)
    local fp = player.stat.fight_power

    if listtype == 1 then

        if ranktype == 1 then
            return fp[player.basic.cursoul]        
        elseif ranktype == 2 then
            local sum = 0
            for _,v in pairs(fp) do
                sum = sum + v
            end
            return sum
        end

    elseif listtype == 2 then
        if ranktype == 1 then
            return fp[player.config.soulid_1v1]
        elseif ranktype == 2 then
            local sum = 0
            for _,v in pairs(player.config.soulid_3v3) do 
                if fp[v] ~= nil then
                    sum = sum + fp[v]
                end
            end
            return sum
        end
    end
end


function command.SAVE_PLAYER_DATA(player)
	player_data[player.basic.playerid] = player
	local theres = skynet.call("MYSQL_SERVICE","lua","query","SELECT playerid from L2.player_savedata where playerid = "..player.basic.playerid)

    if #theres == 0 then
    	log ("first save this player !!","info")
        local allstr = dump(player,true)
        str = "INSERT INTO L2.player_savedata (playerid,data) values ('"..player.basic.playerid.."','"..allstr.."');"
        local res = skynet.call("MYSQL_SERVICE","lua","query",str)      
    else
    	log ("the player is exist,update mysql","info")      
	    local thestr = dump(player,true)
	    str = "UPDATE L2.player_savedata SET data = '"..thestr.."' where playerid = "..player.basic.playerid;
        local res = skynet.call("MYSQL_SERVICE","lua","query",str)	
    end
	return true
end






skynet.start(function()
	skynet.dispatch("lua", function(session, address, cmd, ...)
		local f = command[string.upper(cmd)]
		if f then
			skynet.ret(skynet.pack(f(...)))
		else
			error(string.format("Unknown command %s", tostring(cmd)))
		end
	end)

	skynet.register "DATA_CENTER"
end)
