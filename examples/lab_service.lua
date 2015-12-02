local skynet = require "skynet"
require "skynet.manager"	-- import skynet.register


local lab_data = {}

local working_glasses = {}

local command = {}

local MAX_ACC = 30

-- 4 status of sandglass
local GLASS_CLOSED = -1
local GLASS_EMPTY = 0
local GLASS_PRODUCING = 1
local GLASS_FULL = 2

local HELP_ACC = 3
local HELP_GOLD_PERCENT = 0.03
local STEAL_GOLD_PERCENT = 0.1

local TIME_TBL = {
	60*60,
	60*60*2,
	60*60*3,
}

local GOLD_LOWER_TBL = {
	5000,
	10000,
	50000
}


local GOLD_UPPER_TBL = {
	10000,
	30000,
	150000,
}




local function lock_player(playerid)
	lab_data[playerid].lock = true
end

local function unlock_player(playerid)
	lab_data[playerid].lock = false
end

local function is_locked(playerid)
	return lab_data[playerid].lock
end

local function cal_steal_gold(hourglass)
	if hourglass.status == GLASS_PRODUCING or hourglass == GLASS_FULL then
		return math.floor(hourglass.curtime / (TIME_TBL(hourglass.sandtype) * (1-0.01*hourglass.acc)) * hourglass.gold_can_get)
	else
		return -1
	end
end

-- status -1 not open 0 empty  1 producing 2 full
function command.REGISTER(playerid)
	if lab_data[playerid] ~= nil then
		lab_data[playerid] = 
		{ 
			keeper = 1 , 
			atk_count = 0,
	        be_attacked_list = {
	            [1] = { playerid = 1, lost = 0, nickname = "abc",head_sculpture = 3,result = false ,attack_time = os.date("%Y-%m-%d %X")},
	            [2] = { playerid = 2, lost = 1500, nickname = "def",head_sculpture = 1,result = false,attack_time = os.date("%Y-%m-%d %X")}
	    	},
			hourglass = {	
				{ 
				    playerid = playerid ,
				    glassid = 1,
				    sandtype = -1 , 
				    curtime = -1, 
				    status = GLASS_EMPTY,
				    gold_loss = -1,
				    gold_can_get = -1,
				    acc = 0,
			    } ,
			    {
				    playerid = playerid ,
				    glassid = 2,
				    sandtype = -1 , 
				    curtime = -1, 
				    status = GLASS_CLOSED,
				    gold_loss = 0,
				    gold_can_get = -1,
				    acc = 0
			    } ,  
			    {
				    playerid = playerid ,
				    glassid = 3,
				    sandtype = -1 , 
				    curtime = -1, 
				    status = GLASS_CLOSED,
				    gold_loss = 0,
				    gold_can_get = -1,
				    acc = 0,
			    } ,   
			}, 
	    }
	    return true
	else
		return false
	end
end	



function command.START_HOURGALSS(playerid,glassid,sandtype)
	if lab_data[playerid] == nil then 
	    log("no playerid")
	    return false
	end
	local hg = lab_data[playerid].hourglass[glassid]
	hg.sandtype = sandtype
	hg.curtime = 0
	hg.status = GLASS_PRODUCING
    hg.acc = 0
    hg.gold_loss = 0
    hg.gold_can_get = math.random(GOLD_LOWER_TBL(sandtype),GOLD_UPPER_TBL(sandtype))
	table.insert( working_glasses , lab_data[playerid][glassid])
	return true
end

function command.HELP_FRIEND(playerid,targetid,glassid)
	local hg = lab_data[targetid].glassid
	if hg.status ~= GLASS_PRODUCING then
		return false
	else
		hg.acc = hg.acc+HELP_ACC
		return true,math.floor(hg.gold_can_get*HELP_GOLD_PERCENT)
	end
end

function command.MATCH_PLAYER()
	return true,160
end


function command.STEAL(playerid,targetid,result)
	local count = lab_data[playerid].atk_count
	if count >= 10 then
		return false
	else
		if result == 1 then

			local gold_steal_total = 0

		    for i=1,3 do
		    	if hourglass.status == GLASS_PRODUCING or hourglass == GLASS_FULL then
		    		local hg = lab_data[playerid].hourglass[i]
		    		local gold = cal_steal_gold(hg)
		    		hg.gold_loss = hg.gold_loss + gold
		            gold_steal_total = gold_steal_total + gold
		        else
		        	-- nothing
		        end
		    end
            
            local basic = skynet.call("DATA_CENTER","lua","get_player_data_part",playerid,"basic")

	   		lab_data[playerid].be_attacked_list[count+1] = 
	   		{   
	   			playerid = playerid , 
	   		    gold = gold_steal_total ,
	   		    nickname = basic.nickname, 
	   		    head_sculpture = basic.head_sculpture,
	   		    result = true,
	   		    attack_time = os.date("%Y-%m-%d %X")
	   		}
	   		lab_data[playerid].atk_count = lab_data[playerid].atk_count + 1
	   		return true,gold_steal_total

	   	elseif result == 0 then

	   		lab_data[playerid].be_attacked_list[count+1] = { playerid = playerid ,gold = 0 ,nickname = "haha",result = false}
	   		lab_data[playerid].atk_count = lab_data[playerid].atk_count + 1
	   	    return true,0

	   	end
	end
end


function command.HARVEST(playerid,glassid)
	if lab_data[playerid].hourglass[glassid].status == GLASS_FULL then
        local hourglass = lab_data[playerid].hourglass[glassid]
        local gold = hourglass.gold_can_get - hourglass.gold_loss
        hourglass.status = GLASS_EMPTY
        hourglass.gold_loss = 0
        hourglass.curtime = -1
        hourglass.sandtype = -1
        hourglass.acc = 0
        hourglass.gold_can_get = 0
        return true,gold
    else
    	return false
    end
end

function command.QUICK_HARVEST(playerid,glassid)
	if lab_data[playerid].hourglass[glassid].status == GLASS_PRODUCING then
		local hourglass = lab_data[playerid].hourglass[glassid]
		local gold = hourglass.gold_can_get - hourglass.gold_loss
		hourglass.status = GLASS_EMPTY
		hourglass.gold_loss = 0	
		hourglass.curtime = -1
		hourglass.sandtype = -1
		hourglass.acc = 0 
		hourglass.gold_can_get = 0
		return true,gold
	else 
		return false
    end

end

function command.GET_DATA(playerid)
	if lab_data[playerid] then
		local fight_data = skynet.call("DATA_CENTER","lua","get_player_fight_data")
		return true, { lab_data = lab_data[playerid] , fight_data = fight_data }
	else
		return false
	end
end


function command.SET_KEEPER(playerid,keeper)
    lab_data[playerid].keeper = keeper
    return true
end

function command.UNLOCK_HOURGLASS(playerid,glassid)
	if lab_data[playerid] and lab_data[playerid].hourglass[glassid].status == GLASS_CLOSED then
		lab_data[playerid].hourglass[glassid].status = GLASS_EMPTY
		return true
	else
		return false
	end
end

local function update()
	while true do
		local count = 0
	    for i,v in pairs(working_glasses) do
	    	v.curtime = v.curtime + 1
	    	if v.curtime >= math.floor(TIME_TBL[v.sandtype] * lab_data[v.playerid].acc * 0.01) then
	    		v.status = GLASS_FULL
	    		v.curtime = 0
	    		working_glasses[i] = nil
	    		log("remove glass")
	    	end
	    	count = count + 1
	    end
        
        log(""..count.." glasses is working ")

	    skynet.sleep(100)
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
	skynet.fork(update)
	skynet.register "LAB_SERVICE"
end)
