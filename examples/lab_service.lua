local skynet = require "skynet"
require "skynet.manager"	-- import skynet.register


local lab_data = {}

local working_glasses = {}


-- player under protection
local safe_tbl = {}

local command = {}


local MAX_ACC = 30

local ROBOT_IDS = { 905,904,903 }

-- 4 status of sandglass
local GLASS_CLOSED = -1
local GLASS_EMPTY = 0
local GLASS_PRODUCING = 1
local GLASS_FULL = 2

local HELP_ACC = 10
local HELP_GOLD_PERCENT = 0.03
local STEAL_GOLD_PERCENT = 0.1

local SAFE_TIME_GIVEN = 600

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


local function add_to_working_table(hg)
	if not working_glasses[hg.playerid] then
		working_glasses[hg.playerid] = {}
	end
	working_glasses[hg.playerid][hg.glassid] = hg
end

local function remove_from_working_table(hg)
	working_glasses[hg.playerid][hg.glassid] = nil
    local count = 0
    for i,v in pairs(working_glasses[hg.playerid]) do
    	count = count + 1
    end
    if count == 0 then
		working_glasses[hg.playerid] = nil
	end
end

local function protect_player(playerid)
	safe_tbl[playerid] = true
	lab_data[playerid].safe_time = SAFE_TIME_GIVEN
end

local function stop_protect_player(playerid)
	safe_tbl[playerid] = nil
	lab_data[playerid].safe_time = -1
end

local function is_safe(playerid)
	return safe_tbl[playerid] ~= nil
end

local function update_safe_tbl()
	while true do
		for playerid,_ in pairs(safe_tbl) do
			lab_data[playerid].safe_time = lab_data[playerid].safe_time - 1
			if lab_data[playerid].safe_time <= 0 then
				stop_protect_player()
			end
		end
		skynet.sleep(100)
	end
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
	log("register!")
	if lab_data[playerid] == nil then
		log("first one")
		lab_data[playerid] = 
		{ 
			keeper = 1 , 
			atk_count = 0,
			safe_time = -1,
	        be_attacked_list = {
	            [1] = { playerid = 905, lost = 0, nickname = "abc",head_sculpture = 3,result = false ,attack_time = os.date("%Y-%m-%d %X"),level = 3},
	            [2] = { playerid = 904, lost = 1500, nickname = "def",head_sculpture = 1,result = false,attack_time = os.date("%Y-%m-%d %X"),level = 4}
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
				    unique_id = "",
			    } ,
			    {
				    playerid = playerid ,
				    glassid = 2,
				    sandtype = -1 , 
				    curtime = -1, 
				    status = GLASS_CLOSED,
				    gold_loss = 0,
				    gold_can_get = -1,
				    acc = 0,
				    unique_id = ""
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
				    unique_id = "",
			    } ,   
			}, 
	    }
	    return true
	else
		return false
	end
end	



function command.START_HOURGLASS(playerid,glassid,sandtype)
	log("start_hourglass "..playerid.." "..glassid.." "..sandtype)
	if lab_data[playerid] == nil then 
	    log("no playerid")
	    return false
	end
	--log (dump(lab_data[playerid].hourglass[glassid]))
	if lab_data[playerid].hourglass[glassid].status ~= GLASS_EMPTY then
		return false
    end

	local hg = lab_data[playerid].hourglass[glassid]
	hg.sandtype = sandtype
	hg.curtime = 0
	hg.status = GLASS_PRODUCING
    hg.acc = 0
    hg.gold_loss = 0
    hg.gold_can_get = math.random(GOLD_LOWER_TBL[sandtype],GOLD_UPPER_TBL[sandtype])
    hg.unique_id = os.date("%Y-%m-%d %X")

    add_to_working_table(hg)
	return true
end

function command.HELP_FRIEND(playerid,targetid,glassid,unique_id)
	log ("help friend"..playerid.." "..targetid.." "..glassid.." "..unique_id)
	local hg = lab_data[targetid].hourglass[glassid]
	if hg.status ~= GLASS_PRODUCING then
		return false
	elseif hg.unique_id ~= unique_id then
		return false
	else
		hg.acc = hg.acc+HELP_ACC
		local res,agent = skynet.call("ONLINE_CENTER","lua","is_online",targetid)
		if res then
			skynet.call(agent,"lua","lab_friend_helped")
		end
		return true,math.floor(hg.gold_can_get*HELP_GOLD_PERCENT)
	end
end

function command.MATCH_PLAYER()
	local playerid = 904
    local basic = skynet.call("DATA_CENTER","lua","get_player_data_part",playerid,"basic")
	return {
        result = 1,
        playerid = playerid,
        nickname = basic.nickname,
        head_sculpture = basic.head_sculpture,
        level = basic.level
	}
end

function command.START_STEAL(targetid)
	if is_safe(targetid) then
		return false
	else
		protect_player(targetid)
		return true
	end
end


function command.STEAL(playerid,targetid,result)
	if  is_safe(targetid) then
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
	   		    attack_time = os.date("%Y-%m-%d %X"),
	   		    level = basic.level
	   		}
	   		lab_data[playerid].atk_count = lab_data[playerid].atk_count + 1

            local res,agent = skynet.call("ONLINE_CENTER","lua","is_online",targetid)
			if res then
				skynet.call(agent,"lua","lab_friend_helped")
			end

	   		return true,gold_steal_total

	   	elseif result == 0 then

	   		lab_data[playerid].be_attacked_list[count+1] = { playerid = playerid ,gold = 0 ,nickname = "haha",result = false}
	   		lab_data[playerid].atk_count = lab_data[playerid].atk_count + 1

	   		local res,agent = skynet.call("ONLINE_CENTER","lua","is_online",targetid)
			if res then
				skynet.call(agent,"lua","lab_friend_helped")
			end
	   	    return true,0

	   	end
	end
end


function command.HARVEST(playerid,glassid)
	log ("harvest"..playerid.." "..glassid)
	--log ("glass"..dump(lab_data[playerid].hourglass[glassid]))
	if lab_data[playerid].hourglass[glassid].status == GLASS_FULL then
        local hourglass = lab_data[playerid].hourglass[glassid]
        local gold = hourglass.gold_can_get - hourglass.gold_loss
        hourglass.status = GLASS_EMPTY
        hourglass.gold_loss = 0
        hourglass.curtime = -1
        hourglass.sandtype = -1
        hourglass.acc = 0
        hourglass.gold_can_get = 0
        hourglass.unique_id = ""
        return true,gold
    else
    	return false
    end
end

function command.QUICK_HARVEST(playerid,glassid)
	log ("quick harvest"..playerid.." "..glassid)
	--log ("glass"..dump(lab_data[playerid].hourglass[glassid]))
	if lab_data[playerid].hourglass[glassid].status == GLASS_PRODUCING then
		local hourglass = lab_data[playerid].hourglass[glassid]
		local gold = hourglass.gold_can_get - hourglass.gold_loss
		hourglass.status = GLASS_EMPTY
		hourglass.gold_loss = 0	
		hourglass.curtime = -1
		hourglass.sandtype = -1
		hourglass.acc = 0 
		hourglass.gold_can_get = 0
		hourglass.unique_id = ""
		remove_from_working_table(hourglass)
		return true,gold
	else 
		return false
    end

end

function command.GET_DATA(playerid)
	if lab_data[playerid] then
		local fight_data = skynet.call("DATA_CENTER","lua","get_player_fight_data",playerid,lab_data[playerid].keeper)
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
	log("unlock_hourglass"..playerid.." "..glassid)
	if lab_data[playerid] and lab_data[playerid].hourglass[glassid].status == GLASS_CLOSED then
		lab_data[playerid].hourglass[glassid].status = GLASS_EMPTY
		log ("ok")
		return true
	else
		return false
	end
end

local function update_working_glass()
	while true do
		local count = 0
		local pairs = pairs
	    for _,player in pairs(working_glasses) do
	    	for _,v in pairs(player) do
		    	v.curtime = v.curtime + 1
		    	if v.curtime >= math.floor(TIME_TBL[v.sandtype] * (1 - v.acc * 0.01)) then
		    		v.status = GLASS_FULL
		    		v.curtime = 0
		    		remove_from_working_table(v)
		    	end
		    	count = count + 1		    	
		    end
	    end
        
        log(""..count.." glasses is working ")

	    skynet.sleep(100)
	end
end




local function robot_register()
	for i,v in pairs(ROBOT_IDS) do
		command.REGISTER(v)
		command.UNLOCK_HOURGLASS(v,2)
		command.UNLOCK_HOURGLASS(v,3)
	end
end

local function robot_work()
    while true do
        for _,robotid in pairs(ROBOT_IDS) do	
        	for _,hg in pairs(lab_data[robotid].hourglass) do
        		if hg.status == GLASS_EMPTY then
        			command.START_HOURGLASS(hg.playerid,hg.glassid,math.random(1,3))
        		elseif hg.status == GLASS_FULL then
        			command.HARVEST(hg.playerid,hg.glassid)
        		end
        	end
        end

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
	skynet.fork(update_working_glass)
	skynet.fork(update_safe_tbl)
	skynet.fork(robot_register)
	skynet.fork(robot_work,1000)
	skynet.register "LAB_SERVICE"
end)
