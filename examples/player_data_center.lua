local skynet = require "skynet"
require "skynet.manager"	-- import skynet.register
local player_data = {}
local count = 0

local command = {}


local function get_player_data(playerid)
    log("player_data!!!"..dump(player_data))
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
	for i,v in pairs(data.souls[soulid].itemids) do
		items[v] = data.items[v]
	end
	return { soul = data.souls[soulid],items = items }
end

function command.SAVE_PLAYER_DATA(player)
	player_data[player.basic.playerid] = player
	local theres = skynet.call("MYSQL_SERVICE","lua","query","SELECT playerid from L2.player_basic where playerid = "..player.basic.playerid)

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
