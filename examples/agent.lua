local skynet = require "skynet"
local netpack = require "netpack"
local socket = require "socket"
local sproto = require "sproto"
local sprotoloader = require "sprotoloader"
local ldqueue = require "skynet.ldqueue"
local task = require "logic.task"

local WATCHDOG
local host
local send_request

local CMD = {}
local REQUEST = {}
local client_fd

local player = {}


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
	if player.basic == nil then
		print ("add_gold : player basic not exist")
		return false
	else
		if player.basic.gold + value < 0 then
		    print ("not enough gold")
		    return false
		else 
            player.basic.gold = player.basic.gold + value
		    return true
        end
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
		    return true
        end
    end
end

--增加或减少强化石
local function add_stone(value)
	if player.items == nil then
		print ("player item not exist")
		return false
	else
	    if player.items[1000001] == nil then
	    	player.items[1000001] = { itemid = 1000001 ,
	    	                          itemtype = 1000001,
	    	                          itemextra = 0,
	    	                          itemcount = value}
	    else
	    	player.items[1000001].itemcount = player.items[1000001].itemcount + value
	    end
	    return true
	end
end

--删除物品
local function remove_item(itemid,count)
	if player.items[itemid] ~= nil then
        if count == nil then
        	player.items[itemid] = nil
        else
        	player.items[itemid].itemcount = player.items[itemid].itemcount - count
        	if player.items[itemid].itemcount <= 0 then
        		player.items[itemid] = nil
        	end
        end
        return true
    end
    print ("remove_item failed")
    return false
end

local function add_item(item)
	if player.items ~= nil then
        print ("add_item"..dump(item))
		if have_item(item.itemid) then
			player.items[item.itemid].itemcount = player.items[item.itemid].itemcount + item.itemcount
		else
			player.items[item.itemid] = item
		end
		return true
	end
	print ("add_item failed")
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

--同步战斗数据到redis
local function sync_fight_data_to_redis()

	local one_vs_one_id = player.config.soulid_1v1 
	local three_vs_three_ids = player.config.soulid_3v3

	local tbl = {
        playerid = player.basic.playerid,
        nickname = player.basic.nickname,
        imageid = 3,
        level = player.basic.level,
        one_vs_one_fp = 9876,
        three_vs_three_fp = 8765,
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

local function get_playerrank(ranktype)
	local res
    if ranktype == 1 or 2 then
	    res = skynet.call("REDIS_SERVICE","lua","proc","zrevrank",redis_name_tbl[ranktype],player.basic.playerid)
	    if res then
	    	res = res + 1
	    else
	    	res = 10000
	    end
	elseif ranktype == 3 or 4 then
	    res = skynet.call("REDIS_SERVICE","lua","proc","zscore",redis_name_tbl[ranktype],player.basic.playerid)
		if res then
	    	res = res 
	    else
	    	res = 10000
	    end
	end
	log("player rank type "..ranktype.." : "..res)
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

local function create_rank_for_player()
	skynet.call("REDIS_SERVICE","lua","proc","zadd",redis_single_fp_name,5,""..player.basic.playerid)
    skynet.call("REDIS_SERVICE","lua","proc","zadd",redis_team_fp_name,5,""..player.basic.playerid)

    skynet.call("REDIS_SERVICE","lua","proc","zadd",redis_1v1_name,12000,""..player.basic.playerid)
    skynet.call("REDIS_SERVICE","lua","proc","zadd",redis_3v3_name,13000,""..player.basic.playerid)
end


local function update_task(thetask)
	send_package(send_request("update_task",{
	    task = thetask
	}))
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
	return { rank = get_playerrank(self.ranktype) }
end

function REQUEST:login()
	log("login","info")
	player.playerid = self.playerid

	local sqlstr

	sqlstr = "SELECT playerid,level,gold,diamond,nickname,last_login_time,create_time,cursoul,cur_stayin_level FROM L2.player_basic where playerid = "..player.playerid;
	local res = skynet.call("MYSQL_SERVICE","lua","query",sqlstr)
	player.basic = res[1]


	local function get_data_from_mysql(player_tbl_name,mysql_tbl_name,playerid)
        local sqlstr = "SELECT data FROM L2."..mysql_tbl_name.." where playerid = "..playerid;
        local res = skynet.call("MYSQL_SERVICE","lua","query",sqlstr)
        if res and res[1] then
        	_,player[player_tbl_name] = pcall(load("return "..res[1].data))
        else
        	log("login get_data_from_mysql failed :"..mysql_tbl_name.."playerid =".. playerid)
        end
	end

	get_data_from_mysql("items","item_b",player.playerid)
	get_data_from_mysql("souls","soul_b",player.playerid)
	get_data_from_mysql("tasks","task_b",player.playerid)
	get_data_from_mysql("config","player_config",player.playerid)


    if player.config == nil then
    	player.config = { soulid_1v1 = 1 ; soulid_3v3 = { 1,2,3 } }
    end
    --compatible_with_old_data()
	sync_fight_data_to_redis()
	--create_rank_for_player()

    log ("player "..player.playerid.." is initalized!","info")
    
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
                score = self.ranktype == 3 and fight_data.one_vs_one_fp or three_vs_three_fp ,
                rank = math.ceil((i-1)/2)+self.start 
    		})
        end

    end

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
    --print("lujiajun "..dump(self.items))
    
    if self.items ~= nil then
		for _,v in pairs(self.items) do
			player.items[v.itemid] = v
			--table.insert(player.items,v)
		end
	end
	if player.basic.level == self.level then
        player.basic.level = player.basic.level + 1
    end

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

function REQUEST:set_fightpower()
	log("fightpower"..self.fightpower..","..redis_name_tbl[self.type]..","..player.basic.playerid)

	local res = skynet.call("REDIS_SERVICE","lua","proc","zadd",redis_name_tbl[self.type],self.fightpower,
		  ""..player.basic.playerid)
	return { result = 1 }
end

function REQUEST:set_player_soul()
	if not self.souls then return { result = 1 }end
	for i,v in pairs(self.souls) do
		player.souls[v.soulid] = v
	end
	return { result = 1}
end

function REQUEST:get_tasks()
	if player.tasks ~= nil then
		local tasktbl = {}
		for i,v in pairs(player.tasks) do
			table.insert(tasktbl, {
				    taskid = v.taskid,
				    type = i,
				    icon = i,
				    title = "过关"..i,
				    descriptions = "通过第........"..i.."关",
				    gold = i*1000,
				    diamond = i*100,
				    percent = 100
				})
		end
		return { tasks = tasktbl }
	else
		print ("get_tasks_failed")
	end
end

function REQUEST:get_task_reward()
    local id = self.taskid
    if player.tasks[id] ~= nil then
    	player.tasks[id] = nil	
    	update_task({
				    taskid = id+1,
				    type = id+1,
				    icon = id+1,
				    title = "过关"..id+1,
				    descriptions = "通过第........"..(id+1).."关",
				    gold = (id+1)*1000,
				    diamond = (id+1)*100,
				    percent = 100
				}
    	)
    	return {
            gold = id*1000,
            diamond = 100*id,
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
       add_stone(-self.stone)
       update_item(self.item)

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

	   return { result = 1}
	end

	return { result = 0}
end

function REQUEST:melt_item()
	for _,id in pairs(self.itemids) do
		if have_item(id) == false then return { result = 0} end
	end
    
    for _,id in pairs(self.itemids) do
    	remove_item(id)
    end
    
    add_item(self.newitem)
    add_stone(self.stone)
    
    return { result = 1 }

end

function REQUEST:sell_item()
	for _,id in pairs(self.itemids) do
		if have_item(id) == false then return { result = 0 } end
	end
    
    for _,id in pairs(self.itemids) do
    	remove_item(id)
    end

    add_gold(self.gold[1])
    return { result = 1}
    
end


function REQUEST:fight_with_player_result()
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
	local fight_data_str = skynet.call("REDIS_SERVICE","lua","proc","get",self.playerid.."_data")
    local _,fight_data = pcall(load("return "..fight_data_str))
    return { fightdata = fight_data }
 	-- body
end

function REQUEST:set_fight_soul()
	if player.player_config == nil then
		print ("set_fight_soul failed!")
		return { result = 0 }
	end

    if self.type == 1 then
    	player.player_config.soulid_1v1 = self.soulid[1]
    	sync_fight_data_to_redis()
    elseif self.type == 2 then
    	player.player_config.soulid_3v3 = self.soulid
    	sync_fight_data_to_redis()
    end
    return { result = 1 }
end

function REQUEST:get_fight_player_ids()
	local rank_o = get_playerrank(3)   -- 1v1 rankids
	local rank_t = get_playerrank(4)
	return {
        one_vs_one_ids = { 103 , 1000001 , 1000002} ,
        three_vs_three_ids = { 103 , 1000001, 1000002 }
	}
end



--落地数据到数据库
local function save_to_db()
    local theres = skynet.call("MYSQL_SERVICE","lua","query","SELECT playerid from L2.player_basic where playerid = "..player.basic.playerid)

    if #theres == 0 then
    	log ("first save this player !!","info")
	    local name_str = ""
	    local value_str = ""
	    for i,v in pairs(player.basic) do
            name_str = name_str.."`"..i.."`,"
            value_str = value_str.."'"..v.."',"
	    end
	    name_str = string.sub(name_str,0,string.len(name_str)-1)
	    value_str = string.sub(value_str,0,string.len(value_str)-1)
	    local sqlstr = "INSERT INTO L2.player_basic ("..name_str..") VALUES ("..value_str..");"

	    local res = skynet.call("MYSQL_SERVICE","lua","query",sqlstr)

	    
	    -- save itemdata to mysql
	    local itemstr = dump(player.items,true)
	    str = "INSERT INTO L2.item_b (playerid,data) values ('"..player.basic.playerid.."','"..itemstr.."');"
	    local res = skynet.call("MYSQL_SERVICE","lua","query",str)

	    local soulstr = dump(player.souls,true)
	    str = "INSERT INTO L2.soul_b (playerid,data) values ('"..player.basic.playerid.."','"..soulstr.."');"
	    local res = skynet.call("MYSQL_SERVICE","lua","query",str)

	    local taskstr = dump(player.tasks,true)
	    str = "INSERT INTO L2.task_b (playerid,data) values ('"..player.basic.playerid.."','"..taskstr.."');"
	    local res = skynet.call("MYSQL_SERVICE","lua","query",str)

	    local configstr = dump(player.config,true)
	    str = "INSERT INTO L2.player_config (playerid,data) values ('"..player.basic.playerid.."','"..configstr.."');"
        local res = skynet.call("MYSQL_SERVICE","lua","query",str)

        
    else
    	log ("the player is exist,update mysql","info")
        local tmp = ""
        for i,v in pairs(player.basic) do
        	tmp = tmp..i.."='"..v.."',"
        end
        tmp = string.sub(tmp,0,string.len(tmp)-1)
    	local str = "UPDATE L2.player_basic set "..tmp.."where playerid =".. player.basic.playerid
	    local res = skynet.call("MYSQL_SERVICE","lua","query",str)

	    local function update_mysql_table(player_table,mysql_table)
	    	local thestr = dump(player[player_table],true)
	        str = "UPDATE L2."..mysql_table.." SET data = '"..thestr.."' where playerid = "..player.basic.playerid;
	        local res = skynet.call("MYSQL_SERVICE","lua","query",str)
	    end

	    update_mysql_table("items","item_b")
	    update_mysql_table("souls","soul_b")
	    update_mysql_table("tasks","task_b")


	    if player.config == nil then
	    	-- config 是后加的，之前有的id没有
	    	player.config = { soulid_1v1 = 1 ; soulid_3v3 = { 1,2,3 } }
	    	local configstr = dump(player.config,true)
	    	str = "INSERT INTO L2.player_config (playerid,data) values ('"..player.basic.playerid.."','"..configstr.."');"
        	local res = skynet.call("MYSQL_SERVICE","lua","query",str)
	    else
	        update_mysql_table("config","player_config")
	    end
	
    end
 
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

    print (os.date())

    player.items = { }
    player.souls = { { soulid = 1 , itemids = { -1,-1,-1,-1,-1,-1,-1,-1 } , soul_girl_id = 1} }
    player.tasks = {
            [1] = { taskid = 1,percent = 0},
    	} 
    player.config = { soulid_1v1 = 1 ; soulid_3v3 = { 1,2,3 } }
    
    save_to_db()

    -- 战5渣 at first

    create_rank_for_player()
    

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
end)
