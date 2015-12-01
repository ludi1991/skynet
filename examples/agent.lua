local skynet = require "skynet"
local netpack = require "netpack"
local socket = require "socket"
local sproto = require "sproto"
local sprotoloader = require "sprotoloader"
local ldqueue = require "skynet.ldqueue"
local taskmgr = require "gamelogic.taskmgr"
local statmgr = require "gamelogic.statmgr"
local itemmgr = require "gamelogic.itemmgr"
local labmgr = require "gamelogic.labmgr"
local fp_cal = require "gamelogic.fp_calculator"

local WATCHDOG
local host
local send_request

local CMD = {}
local REQUEST = {}
local client_fd

local player = {}

local redis_need_sync = false

local redis_single_fp_name = "fp_single_rank"
local redis_team_fp_name = "fp_team_rank"
local redis_1v1_name = "1v1_rank"
local redis_3v3_name = "3v3_rank"

local redis_name_tbl = {
	redis_single_fp_name,
	redis_team_fp_name,
	redis_1v1_name,
	redis_3v3_name
}


local function send_package(pack)  
	local package = string.pack(">s2", pack)
	socket.write(client_fd, package)
end


local function have_enough_gold(value)
	return player.basic ~= nil and player.basic.gold - value >= 0
end

local function have_enough_diamond(value)
	return player.basic ~= nil and player.basic.diamond - value >= 0
end

local function have_enough_stone(value)
	return player.items ~= nil and 
	       player.items[1000001] ~= nil and
	       player.items[1000001].itemcount - value >= 0
end

local function have_item(itemid)
	return player.items ~= nil and player.items[itemid] ~= nil
end

-- 增加或减少金币
local function add_gold(value)	
	if player.basic.gold + value < 0 then
	    print ("not enough gold")
	    return false
	else 
        player.basic.gold = player.basic.gold + value
        if value < 0 then           	
        	statmgr:add_gold_consumed(-value)         	
        	taskmgr:update_tasks_by_condition_type(5)
  	
        end
	    return true
    end
end

--增加或减少钻石
local function add_diamond(value)
	if player.basic == nil then
		print ("add_diamond : player basic not exist")
		return false
	else
		if player.basic.diamond + value < 0 then
		    print ("not enough gold")
		    return false
		else 
            player.basic.diamond = player.basic.diamond + value
            if value < 0 then
            	statmgr:add_diamond_consumed(-value)
            	taskmgr:update_tasks_by_condition_type(5)
            end
		    return true
        end
    end
end


local function add_item(item)
	if player.items ~= nil then
        log ("add_item"..dump(item))
		if have_item(item.itemid) then
			player.items[item.itemid].itemcount = player.items[item.itemid].itemcount + item.itemcount
		else
			player.items[item.itemid] = item
		end
		return true
	end
	log ("add_item failed")
	return false
end


local function update_item(item)
	if have_item(item.itemid) == false then
		return false
	end
	player.items[item.itemid].itemtype = item.itemtype
	player.items[item.itemid].itemextra = item.itemextra
	return true

end


local function set_sync_redis_flag()
	redis_need_sync = true
end

--同步战斗数据到redis
local function sync_fight_data_to_redis()
	local single_fp = fp_cal:get_highest_fightpower(player)
	local team_fp = fp_cal:get_player_fightpower(player)
	skynet.call("REDIS_SERVICE","lua","proc","zadd",redis_name_tbl[1],single_fp,""..player.basic.playerid)
	skynet.call("REDIS_SERVICE","lua","proc","zadd",redis_name_tbl[2],team_fp,""..player.basic.playerid)


	local one_vs_one_id = player.config.soulid_1v1 
	local three_vs_three_ids = player.config.soulid_3v3

	ofp = fp_cal:get_1v1_fightpower(player)
	tfp = fp_cal:get_3v3_fightpower(player)


	local tbl = {
        playerid = player.basic.playerid,
        nickname = player.basic.nickname,
        imageid = 3,
        level = player.basic.level,
        one_vs_one_fp = ofp,
        three_vs_three_fp = tfp,
        one_vs_one_soul = 
        { 
            soulid = 0 , 
            itemids = { 1,-1,-1,-1,-1,-1,-1,-1 } , 
            soul_girl_id = 1,
        } ,
        one_vs_one_items = 
        {  
            { itemid = 1, itemtype = 1101010 , itemextra = 0 , itemcount = 1} , 
            { itemid = 2 , itemtype = 1101010 , itemextra = 0 ,itemcount = 1} , 
        } ,

        three_vs_three_souls = 
        { 
            { soulid = 0 , itemids = { 1,-1,-1,-1,-1,-1,-1,-1 } , soul_girl_id = 1},
            { soulid = 1 , itemids = { -1,2,-1,-1,-1,-1,-1,-1 } , soul_girl_id = 2},
            { soulid = 2 , itemids = { -1,-1,-1,-1,-1,-1,-1,-1 } , soul_girl_id = 3},
        },

        three_vs_three_items = 
        {
            { itemid = 1 , itemtype = 1010101 , itemextra = 0 , itemcount = 1},
            { itemid = 2 , itemtype = 1010101 , itemextra = 0 , itemcount = 1},
        }
    }

    if one_vs_one_id == nil then
		log (" no one_vs_one_id in player.config")
	else
		tbl.one_vs_one_soul = player.souls[one_vs_one_id]

		local items = {}
		for i,v in pairs(tbl.one_vs_one_soul) do
			table.insert(items,player.items[v])
		end
        tbl.one_vs_one_items = items
	end

	if three_vs_three_ids ~= nil then
		tbl.three_vs_three_souls = {
            player.souls[three_vs_three_ids[1]],
            player.souls[three_vs_three_ids[2]],
            player.souls[three_vs_three_ids[3]], 
	    }
        
        local items = {}
	    for i=1,3 do
	    	if tbl.three_vs_three_souls[i] ~= nil then
	        	for _,v in pairs(tbl.three_vs_three_souls[i]) do
	        		table.insert(items,player.items[v])
	        	end
	        else
	        	log("error when creating fightdata : soul "..i.." not exist!","error")
	        end
        end
        tbl.three_vs_three_items = items

	else
		log("no three vs three ids in player.config")
	end

	local res = skynet.call("REDIS_SERVICE","lua","proc","set",""..player.basic.playerid.."_data",dump(tbl))
    
end

local function get_player_fightpower(ranktype)
	local res
	if ranktype == 1 or ranktype == 2 then
	    res = skynet.call("REDIS_SERVICE","lua","proc","zscore",redis_name_tbl[ranktype],player.basic.playerid)
	    res = tonumber(res)
	elseif ranktype == 3 or ranktype == 4 then
		local fight_data_str = skynet.call("REDIS_SERVICE","lua","proc","get",player.basic.playerid.."_data")
        local _,fight_data = pcall(load("return "..fight_data_str))
        res = ranktype == 3 and fight_data.one_vs_one_fp or fight_data.three_vs_three_fp
    end
    log("get_player_fightpower type:"..ranktype.." ,power:"..res,"info")
    return res
end

local function get_rank(ranktype,playerid)
	local res
    if ranktype == 1 or ranktype == 2 then
	    res = skynet.call("REDIS_SERVICE","lua","proc","zrevrank",redis_name_tbl[ranktype],playerid)
	    if res then
	    	res = res + 1
	    else
	    	res = 10000
	    end
	elseif ranktype == 3 or ranktype == 4 then
	    res = skynet.call("REDIS_SERVICE","lua","proc","zscore",redis_name_tbl[ranktype],playerid)
		if res then
			log(res)
	    	res = tonumber(res) 
	    else
	    	res = 10000
	    end
	end
	log("rank type "..ranktype.." : "..res)
	return res
end

local function lock_fight_player(playerid,type)
    skynet.call("REDIS_SERVICE","lua","proc","set",""..playerid.."_"..type.."_in_fight","working")
    skynet.call("REDIS_SERVICE","lua","proc","expire",""..playerid.."_"..type.."_in_fight",60)
end

local function unlock_fight_player(playerid,type)
	skynet.call("REDIS_SERVICE","lua","proc","del",""..playerid.."_"..type.."_in_fight")
end

local function is_player_in_fight(playerid,type)
	local res = skynet.call("REDIS_SERVICE","lua","proc","get",""..playerid.."_"..type.."_in_fight")
	log ("is_player_in_fight ")
	return res ~= nil
end

local function create_rank_for_player(thetype)
	if thetype == 1 then
		skynet.call("REDIS_SERVICE","lua","proc","zadd",redis_single_fp_name,1,""..player.basic.playerid)
	elseif thetype == 2 then
	    skynet.call("REDIS_SERVICE","lua","proc","zadd",redis_team_fp_name,1,""..player.basic.playerid)
	elseif thetype == 3 then
	    local o_count = skynet.call("REDIS_SERVICE","lua","proc","zcard",redis_1v1_name)
	    skynet.call("REDIS_SERVICE","lua","proc","zadd",redis_1v1_name,o_count+1,""..player.basic.playerid)
	elseif thetype == 4 then
	    local t_count = skynet.call("REDIS_SERVICE","lua","proc","zcard",redis_3v3_name)
	    skynet.call("REDIS_SERVICE","lua","proc","zadd",redis_3v3_name,t_count+1,""..player.basic.playerid)
	end

end


function REQUEST:get()
	print("get", self.what)
	local r = skynet.call("SIMPLEDB", "lua", "get", self.what)
	return { result = r }
end

function REQUEST:set()
	print("set", self.what, self.value)
	local r = skynet.call("SIMPLEDB", "lua", "set", self.what, self.value)
end

function REQUEST:getnews()
	print "require news"
	local r = skynet.call("SIMPLENEWS", "lua","getnews")
	return { msg = r }
end


function REQUEST:chat()
	print ("request chat ")
    skynet.call("CHATROOM","lua","chat",{name = self.name,msg = self.msg})
    return { result = 1 }
end

function REQUEST:handshake()
	return { msg = "Welcome to skynet, I will send heartbeat every 5 sec." }
end

function REQUEST:get_player_basic()
	return { data = player.basic }
end

function REQUEST:get_player_rank()
	return { rank = get_rank(self.ranktype,player.basic.playerid) , fightpower = get_player_fightpower(self.ranktype) }
end

function REQUEST:login()

    player = skynet.call("DATA_CENTER","lua","get_player_data",self.playerid)


	set_sync_redis_flag()

    log ("player "..self.playerid.." is initalized!","info")
    log(dump(player))
    
    taskmgr:set_player(player)
    statmgr:set_player(player)
    itemmgr:set_player(player)
    labmgr:set_player(player)
  

    skynet.fork(function()
		while true do
			if redis_need_sync then
				log ("sync data to redis!")
				sync_fight_data_to_redis()
			    redis_need_sync = false
			end
			skynet.sleep(1000)
		end
    end)

    skynet.call("ONLINE_CENTER","lua","set_online",self.playerid,skynet.self())
	return { result = 1 }
end


function REQUEST:get_player_items()
	local tmp = {}
	for _,v in pairs(player.items) do
		table.insert(tmp,v)
        end
	return { items = tmp }
end

function REQUEST:get_rank_data()
	local res
    if self.ranktype == 1 or self.ranktype == 2 then
	    res = skynet.call("REDIS_SERVICE","lua","proc","zrevrange",redis_name_tbl[self.ranktype],self.start-1,
		self.start+self.count-2,"withscores")
	else
		res = skynet.call("REDIS_SERVICE","lua","proc","zrange",redis_name_tbl[self.ranktype],self.start-1,
		self.start+self.count-2,"withscores")
	end

	local result = {}
	for i=1,self.count*2,2 do
		local theplayerid = res[i]
		local thescore = tonumber(res[i+1])
		log(theplayerid)
		local fight_data_str = skynet.call("REDIS_SERVICE","lua","proc","get",theplayerid.."_data")
        local _,fight_data = pcall(load("return "..fight_data_str))
        if self.ranktype == 1 or self.ranktype == 2 then
		    table.insert(result,
	    	{ 
	    		playerid = tonumber(theplayerid) , 
	    	    name = fight_data.nickname , 
	    	  	score = thescore , 
	    	  	rank = math.ceil((i-1)/2)+self.start 
	    	})
        elseif self.ranktype == 3 or self.ranktype == 4 then


        	table.insert(result,
    		{
                playerid = tonumber(theplayerid),
                name = fight_data.nickname,
                score = self.ranktype == 3 and fight_data.one_vs_one_fp or fight_data.three_vs_three_fp ,
                rank = math.ceil((i-1)/2)+self.start 
    		})
        end

    end
    log ("get_rank_data"..self.ranktype..dump(result))
    return { data = result }

end

function REQUEST:get_player_soul()
    return { souls = player.souls }
end

function REQUEST:set_cursoul()
	player.basic.cursoul = self.soulid
	return { result = 1 } 
end

function REQUEST:get_server_time()
	return { time = os.date("%Y-%m-%d %X") }
end

function REQUEST:pass_boss_level()
	add_gold(self.gold)
	add_diamond(self.diamond)
    
    if self.items ~= nil then
		for _,v in pairs(self.items) do
			player.items[v.itemid] = v
			--table.insert(player.items,v)
		end
	end
	if player.basic.level == self.level then
        player.basic.level = player.basic.level + 1
    end
    
    taskmgr:update_tasks_by_condition_type(1)
    taskmgr:trigger_task(1)
   

	return { result = 1 }
end


function REQUEST:pass_level()
	add_gold(self.gold)
	add_diamond(self.diamond)
    
    if self.items ~= nil then
		for _,v in pairs(self.items) do
			player.items[v.itemid] = v
		end
	end

	return { result = 1 }
end


function REQUEST:set_player_soul()
	if not self.souls then return { result = 1 }end
	for i,v in pairs(self.souls) do
		player.souls[v.soulid] = v
	end
	set_sync_redis_flag()
	return { result = 1}
end

function REQUEST:get_tasks()
	if player.tasks ~= nil then
		return { tasks = taskmgr:generate_tasks(player.tasks)}
	else
		print ("get_tasks_failed")
	end
end

function REQUEST:get_task_reward()
    local id = self.taskid
    if player.tasks[id] ~= nil then
    	taskmgr:finish_task(id)
    	local gold,diamond,item = taskmgr:get_reward(id)
    	if gold ~= nil then
    		add_gold(gold)
    	end

    	if diamond ~= nil then
    		add_diamond(diamond)
    	end
        
        local items = nil    
    	if item ~= nil then
    		local item = itemmgr:add_item(item.itemtype,item.itemcount)
    		items = { item }
    	end

    	return {
            gold = gold,
            diamond = diamond,
            items = items,
        }
    else
    	log("no task!")
    end
end

function REQUEST:set_cur_stayin_level()
    player.basic.cur_stayin_level = self.level
    return { result = 1}
end

function REQUEST:strengthen_item()
    if have_enough_gold(self.gold) and have_enough_stone(self.stone) and 
        have_enough_diamond(self.diamond) and have_item(self.item.itemid) then
        print ("strengthen_item"..dump(self.item))
 
        add_gold(-self.gold)
        add_diamond(-self.diamond)
        itemmgr:add_stone(-self.stone)
        update_item(self.item)
        set_sync_redis_flag()

        return { result = 1}
    end

    return { result = 0 }

  
end

function REQUEST:upgrade_item()
	if have_enough_gold(self.gold) and have_enough_diamond(self.diamond) 
	   and have_item(self.item.itemid) then

	   add_gold(-self.gold)
	   add_diamond(-self.diamond)
	   update_item(self.item)
       set_sync_redis_flag()
	   return { result = 1}
	end

	return { result = 0}
end

function REQUEST:melt_item()

	for _,id in pairs(self.itemids) do
		if have_item(id) == false then return { result = 0 } end
	end
    
    for _,id in pairs(self.itemids) do
    	itemmgr:delete_item(id)
    end
    
    add_item(self.newitem)
    itemmgr:add_stone(self.stone)

    statmgr:add_melt_times(1)
    taskmgr:update_tasks_by_condition_type(11)
    
    return { result = 1 }

end

function REQUEST:sell_item()
	for _,id in pairs(self.itemids) do
		if have_item(id) == false then return { result = 0 } end
	end
    
    for _,id in pairs(self.itemids) do
    	itemmgr:delete_item(id)
    end

    add_gold(self.gold[1])
    return { result = 1 }
    
end


function REQUEST:fight_with_player_result()
	log("enter fight_with_player_result")
    unlock_fight_player(player.basic.playerid,self.fighttype)
    unlock_fight_player(self.enemyid,self.fighttype)
    if self.result == 1 then  -- win
    	local playerrank = skynet.call("REDIS_SERVICE","lua","proc","zscore",redis_name_tbl[2+self.fighttype],player.basic.playerid)
    	local enemyrank = skynet.call("REDIS_SERVICE","lua","proc","zscore",redis_name_tbl[2+self.fighttype],self.enemyid)
    	log(""..redis_name_tbl[2+self.fighttype].." "..playerrank.." "..self.enemyid)
    	skynet.call("REDIS_SERVICE","lua","proc","zadd",redis_name_tbl[2+self.fighttype],playerrank,""..self.enemyid)
    	skynet.call("REDIS_SERVICE","lua","proc","zadd",redis_name_tbl[2+self.fighttype],enemyrank,""..player.basic.playerid)
    	return { result = 1 }
    elseif self.result == 0 then -- lose
    	return { result = 1 }
    end
end

function REQUEST:start_fight_with_player()
	log ("start 1")
	if is_player_in_fight(player.basic.playerid,self.fighttype) or is_player_in_fight(self.playerid,self.fighttype) then
		return { result = -1 }
	else
	    lock_fight_player(player.basic.playerid,self.fighttype)
	    lock_fight_player(self.playerid,self.fighttype)
	    return { result = 1}
	end
end



function REQUEST:add_offline_reward()
	add_gold(self.gold)
	add_diamond(self.diamond)
    
    if self.items ~= nil then
		for _,v in pairs(self.items) do
			player.items[v.itemid] = v
			--table.insert(player.items,v)
		end
	end
	return { result = 1 }
end


function REQUEST:get_fight_data()

    
    local fight_data_str = skynet.call("REDIS_SERVICE","lua","proc","get",player.basic.playerid.."_data")
    local _,player_data = pcall(load("return "..fight_data_str))

  
    local ids 
    local playerrank
    local enemyrank = {}
    if self.fight_type == 1 then
    	ids = { 1000003 , 1000001 , 1000002} 
    	playerrank = get_rank(3,player.basic.playerid)
    	for i,v in pairs(ids) do
    		table.insert(enemyrank,get_rank(3,v))
    	end
    elseif self.fight_type == 2 then
    	ids = { 1000004 , 1000001 , 1000002}
    	playerrank = get_rank(4,player.basic.playerid) 
    	for i,v in pairs(ids) do
    		table.insert(enemyrank,get_rank(4,v))
    	end
    end

    local enemy_data = {}
    for i,v in pairs(ids) do
		local fight_data_str = skynet.call("REDIS_SERVICE","lua","proc","get",v.."_data")
    	local _,fight_data = pcall(load("return "..fight_data_str))
    	table.insert(enemy_data,fight_data)
    end

    return  {  player_data = player_data , enemy_data = enemy_data ,player_rank = playerrank ,enemy_rank = enemyrank} 
end

function REQUEST:set_fight_soul()
	if player.player_config == nil then
		print ("set_fight_soul failed!")
		return { result = 0 }
	end

    if self.type == 1 then
    	player.player_config.soulid_1v1 = self.soulid[1]
    	set_sync_redis_flag()
    elseif self.type == 2 then
    	player.player_config.soulid_3v3 = self.soulid
    	set_sync_redis_flag()
    end
    return { result = 1 }
end

function REQUEST:get_fight_player_ids()
	local rank_o = get_rank(3,player.basic.playerid)   -- 1v1 rankids
	local rank_t = get_rank(4,player.basic.playerid)
	return {
        one_vs_one_ids = { 103 , 1000001 , 1000002} ,
        three_vs_three_ids = { 103 , 1000001, 1000002 }
	}
end


function REQUEST:collect_parachute()
	add_gold(self.gold)
	add_diamond(self.diamond)
	return { result = 1 }
end

function REQUEST:upgrade_gem()
	local res = itemmgr:upgrade_gem(self.diamondid,self.gold)
	return { result = res and 1 or 0}
end

function REQUEST:item_add_hole()
	local res = itemmgr:item_add_hole(self.itemid)
	return { result = res and 1 or 0}
end

function REQUEST:item_inset_gem()
	local res = itemmgr:item_inset_gem(self.itemid,self.gem_type,self.gem_hole_pos)
	set_sync_redis_flag()
	return { result = res and 1 or 0}
end

function REQUEST:item_pry_up_gem()
	log ("item_pry"..dump(self.gem_hole_pos))
	local res = itemmgr:item_pry_up_gem(self.itemid,self.gem_hole_pos)
	set_sync_redis_flag()
	return { result = res and 1 or 0}
end

function REQUEST:new_pass_level()

end

function REQUEST:new_pass_boss_level()
end

--- lab

function REQUEST:lab_register()
	return labmgr:lab_register()
end

function REQUEST:lab_start_hourglass()
	return labmgr:lab_start_hourglass(self.hourglassid,self.sandtype)
end

function REQUEST:lab_help_friend()
    return labmgr:lab_help_friend(self.friendid,self.glassid)
end

function REQUEST:lab_get_data()
	return labmgr:lab_get_data(self.playerid)
end

function REQUEST:lab_match_player()
	return labmgr:lab_match_player()
end

function REQUEST:lab_steal()
	return labmgr:lab_steal(self.playerid)
end

function REQUEST:lab_harvest()
	return labmgr:lab_harvest(self.glassid)
end

function REQUEST:lab_set_keeper()
	return labmgr:lab_set_keeper(self.keeperid)
end

function REQUEST:lab_quick_harvest()
	return labmgr:lab_quick_harvest(self.glassid)
end

function REQUEST:set_unlock_soul()
    player.config.unlock_soul = self.list
    return { result = true}
end

function REQUEST:get_unlock_soul()
	if player.config.unlock_soul == nil then
		player.config.unlock_soul = {}
	end
	return { list = player.config.unlock_soul }
end


--落地数据到数据库
local function save_to_db()
	local res = skynet.call("DATA_CENTER","lua","save_player_data",player)
end

function REQUEST:create_new_player()
    player = {}
    local sqlstr = "SELECT playerid FROM L2.player_basic order by playerid desc limit 1"
	local newplayerid = skynet.call("MYSQL_SERVICE","lua","query",sqlstr)[1].playerid + 1
	
    player.basic = {
        playerid = newplayerid,
        nickname = self.nickname..math.random(100000),
        diamond = 0,
        gold = 0,
        create_time = os.date("%Y-%m-%d %X"),
        level = 1,
        last_login_time = os.date("%Y-%m-%d %X"),
        cursoul = 1,
        cur_stayin_level = 1,
    }

    player.items = { }
    player.souls = { { soulid = 1 , itemids = { -1,-1,-1,-1,-1,-1,-1,-1 } , soul_girl_id = 1} }
    player.tasks = { } 
    player.config = 
    {   
        soulid_1v1 = 1 , 
        soulid_3v3 = { 1,2,3 } ,
        finished_tasks = {} ,
    }
    player.lab = { keeper = 1 , hourglass = {} , keys = 5 , help_list = {} , be_helped_list = {} }
    

    -- 战5渣 at first
    for i=1,4 do create_rank_for_player(i) end

    -- 0 means task for new player
    taskmgr:set_player(player)
    statmgr:set_player(player)
    itemmgr:set_player(player)
    labmgr:set_player(player)
    taskmgr:trigger_task(0)

    save_to_db()


    return { result = 1 , playerid = newplayerid }

   
end



function REQUEST:quit()
	save_to_db()
	skynet.call(WATCHDOG, "lua", "close", client_fd)
end

local function request(name, args, response)
	local f = assert(REQUEST[name])
	local r = f(args)
	if response then
		return response(r)
	end
end


-- 协程在call的时候将不会挂起
local cs = ldqueue(send_package)
local function dispatch_with_queue(_,_,type,...)
	if type == "REQUEST" then
		cs(request,...)
	else
		assert(type == "RESPONSE")
		error "This example doesn't support request client"
	end	
end

local function dispatch(_,_,type,...)
	if type == "REQUEST" then
		local ok, result  = pcall(request, ...)
		if ok then
			if result then
				send_package(result)
			end
		else
			skynet.error(result)
		end
	else
		assert(type == "RESPONSE")
		error "This example doesn't support request client"
	end	
end


skynet.register_protocol {
	name = "client",
	id = skynet.PTYPE_CLIENT,
	unpack = function (msg, sz)
		return host:dispatch(msg, sz)
	end,
	dispatch = dispatch_with_queue
}


function CMD.chat(themsg)
	send_package(send_request("chatting",{name = themsg.name ,msg = themsg.msg,time = os.date()}))
end



function CMD.start(conf)
	local fd = conf.client
	local gate = conf.gate
	WATCHDOG = conf.watchdog
	-- slot 1,2 set at main.lua
	host = sprotoloader.load(1):host "package"
	send_request = host:attach(sprotoloader.load(2))
	log("start","info")
	-- skynet.fork(function()
	-- 	while true do
	-- 		print "send heartbeat"
	-- 		send_package(send_request "heartbeat")
	-- 		skynet.sleep(500)
	-- 	end
	-- end)

	-- skynet.fork(function()
	-- 	while true do
	-- 		print "update_task"
	-- 		send_package(send_request("update_task",{
	-- 		    task = { taskid = 0,type = 0,description = "first task",percent = 100}
	-- 		}
	-- 		))

	-- 		skynet.sleep(1000)
	-- 	end
	-- end)

	client_fd = fd
	skynet.call(gate, "lua", "forward", fd)
end


function CMD.disconnect()
	-- todo: do something before exit
    --skynet.send("CHATROOM","lua","logout",skynet.self())
    player.basic.last_login_time = os.date("%Y-%m-%d %X")
    save_to_db()
    skynet.call("ONLINE_CENTER","lua","set_offline",player.basic.playerid)
	skynet.exit()
end

skynet.start(function()
	skynet.dispatch("lua", function(_,_, command, ...)
		print ("dispatch something "..command)
		local f = CMD[command]
		if f then 
		    skynet.ret(skynet.pack(f(...)))
		else
		end
	end)
	taskmgr:get_task_details(3)
end)
