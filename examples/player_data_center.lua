local skynet = require "skynet"
require "skynet.manager"	-- import skynet.register
local player_data = {}
local count = 0

local command = {}


local function get_player_data(playerid)
   -- log("player_data!!!"..dump(player_data))
    local res,agent = skynet.call("ONLINE_CENTER","lua","is_online",playerid)
    if res then
    	local res,data = pcall(skynet.call, agent, "lua", "get_data")
    	if res then
    	    player_data[playerid] = data
    	end
    end

	if not player_data[playerid] then
		local sqlstr = "SELECT data FROM L2.player_savedata where playerid = "..playerid;
	    local res = skynet.call("MYSQL_SERVICE","lua","query",sqlstr)
	    if res and res[1] then
	    	local _,player = pcall(load("return "..res[1].data))
	    	player_data[playerid] = player
	    	return player
	    else
	    	log("login get_data_from_mysql failed : playerid = "..playerid)
	    end
	else
		return player_data[playerid]
	end
end

function command.CREATE_ROBOT(nickname)

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
	log(dump(data.souls))
	for i,v in pairs(data.souls[soulid].itemids) do
		if v ~= -1 then
			items[v] = data.items[v]
		end
	end
	return { soul = data.souls[soulid],items = items }
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
