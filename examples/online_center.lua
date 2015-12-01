local skynet = require "skynet"
require "skynet.manager"	-- import skynet.register
local online_players = {}
local count = 0

local command = {}


function command.GET_ONLINE_PLAYERS_COUNT()
	return count
end

function command.SET_ONLINE(playerid, agent)
	if online_players[playerid] == nil then
		online_players[playerid] = agent
		count = count +1
		log("player "..playerid.." is online ,total online count : "..count)
	end
end

function command.SET_OFFLINE(playerid)
	if online_players[playerid] ~= nil then
		online_players[playerid] = nil
	    count = count -1
	    log("player "..playerid.." is offline ,total online count : "..count)
	end
end

function command.IS_ONLINE(playerid)
	if online_players[playerid] ~= nil then
		return true,online_players[playerid]
    else 
    	return false
    end
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
	skynet.register "ONLINE_CENTER"
end)
