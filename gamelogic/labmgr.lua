local labmgr = {}
local skynet = require "skynet"


function labmgr:set_player(player)
	self.player = player
	player.lab = player.lab or {}
	self.lab = lab
end

function labmgr:lab_register()
	local res = skynet.call("LAB_SERVICE","lua","register",self.player.basic.playerid)
	if res == true then
		return { res = 1 }
	else 
		return { res = 0 }
	end
end

function labmgr:lab_start_hourglass(hourglassid,sandtype)
	local res = skynet.call("LAB_SERVICE","lua","start_hourglass",self.player.basic.playerid,hourglassid,sandtype)
	if res == true then
		return { res = 1 }
	else 
		return { res = 0 }
	end
end

function labmgr:lab_help_friend(friendid)
	local res,gold = skynet.call("LAB_SERVICE","lua","help_friend",self.player.basic.playerid,friendid)
    if res == true then
    	self.player.basic.gold = self.player.basic.gold + gold
    	return { res = 1 ,gold = gold}
    else
    	return { res = 0 ,gold = 0}
    end
end

function labmgr:lab_get_data(playerid)
	local res,data = skynet.call("LAB_SERVICE","lua","get_data",playerid)
	if res then
		return data
	else
	    log("lab_get_data playerid "..playerid.." failed!") 
		return {}
	end
end

function labmgr:lab_match_player()
	local res,playerid = skynet.call("LAB_SERVICE","lua","match_player")
	if res == true then
		return { res = 1, playerid = playerid}
	else
		return { res = 0 , playerid = 0}
	end
end

function labmgr:lab_steal(targetid,result)
	local res,gold = skynet.call("LAB_SERVICE","lua","steal",self.player.basic.playerid,targetid,result)
	if res == true then
		self.player.basic.gold = self.player.basic.gold + gold
		return { res = 1, gold = gold }
    else
    	return { res = 0 ,gold = 0}
    end
end

function labmgr:lab_harvest(glassid)
	local res,gold = skynet.call("LAB_SERVICE","lua","harvest",self.player.basic.playerid,glassid)
	if res == true then
		self.player.basic.gold = self.player.basic.gold + gold
		return { res = 1 , gold = gold }
	else
		return { res = 0, gold = 0}
	end
end

function labmgr:lab_set_keeper(keeperid)
    local res = skynet.call("LAB_SERVICE","lua","set_keeper",keeperid)	
    if res == true then
    	return { res = 1}
    else
    	return { res = 0}
    end
end

function labmgr:lab_quick_harvest(glassid)
	local res,gold = skynet.call("LAB_SERVICE","lua","harvest",self.player.basic.playerid,glassid)
	if res == true then
		self.player.basic.gold = self.player.basic.gold + gold
		return { res = 1 , gold = gold }
	else
		return { res = 0, gold = 0}
	end
end

function labmgr:lab_unlock_glasshour(glassid)
	local res = skynet.call("LAB_SERVICE","lua","unlock_glasshour",glassid)
	if res == true then
		return { res = 1}
	else
		return { res = 0}
	end
end

return labmgr