local skynet = require "skynet"
local netpack = require "netpack"
local socket = require "socket"
local sproto = require "sproto"
local sprotoloader = require "sprotoloader"

local WATCHDOG
local host
local send_request

local CMD = {}
local REQUEST = {}
local client_fd

local player = {}

function string:split(sep)
	local sep, fields = sep or "\t", {}
	local pattern = string.format("([^%s]+)", sep)
	self:gsub(pattern, function(c) fields[#fields+1] = c end)
	return fields
end

-- print lua data
local function dump(obj,oneline)
    local getIndent, quoteStr, wrapKey, wrapVal, dumpObj
    getIndent = function(level)
        return string.rep("\t", level)
    end
    quoteStr = function(str)
        return '"' .. string.gsub(str, '"', '\\"') .. '"'
    end
    wrapKey = function(val)
        if type(val) == "number" then
            return "[" .. val .. "]"
        elseif type(val) == "string" then
            return "[" .. quoteStr(val) .. "]"
        else
            return "[" .. tostring(val) .. "]"
        end
    end
    wrapVal = function(val, level)
        if type(val) == "table" then
            return dumpObj(val, level)
        elseif type(val) == "number" then
            return val
        elseif type(val) == "string" then
            return quoteStr(val)
        else
            return tostring(val)
        end
    end
    dumpObj = function(obj, level)
        if type(obj) ~= "table" then
            return wrapVal(obj)
        end
        level = level + 1
        local tokens = {}
        tokens[#tokens + 1] = "{"
        for k, v in pairs(obj) do
            tokens[#tokens + 1] = getIndent(level) .. wrapKey(k) .. " = " .. wrapVal(v, level) .. ","
        end
        tokens[#tokens + 1] = getIndent(level - 1) .. "}"

        local thestr = "\n"
        if oneline then thestr = " " end
        return table.concat(tokens, thestr)
    end
    return dumpObj(obj, 0)
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
	if player.items[itemid] ~= nil then
		if have_item(item.itemid) then
			player.item[item.itemid].itemcount = player.item[item.itemid].itemcount + item.itemcount
		else
			player.item[item.itemid] = item
		end
		return true
	end
	print ("add_item failed")
	return false
end

local function update_item(item)
	if have_item(item.itemid) == false then
		print ("update_item failed")
		return false
	end
	player.item[item.itemid].itemtype = item.itemtype
	player.item[item.itemid].itemextra = item.itemextra
	return true

end

-- 计算战斗力
local function cal_fightpower()
	return player.basic.playerid * 3
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
	--print "send handshake"
	return { msg = "Welcome to skynet, I will send heartbeat every 5 sec." }
end

function REQUEST:get_player_basic()
	return { data = player.basic }
end

function REQUEST:get_player_rank()
    print ("get_player_rank")
	local res = skynet.call("REDIS_SERVICE","lua","proc","zrank","scoreboard",
		  ""..player.basic.nickname.."|"..player.basic.playerid)

	return { rank = res or 10000 }
end

function REQUEST:login()
	player.playerid = self.playerid

	local sqlstr

	sqlstr = "SELECT playerid,level,gold,diamond,nickname,last_login_time,create_time,cursoul,cur_stayin_level FROM L2.player_basic where playerid = "..player.playerid;
	local res = skynet.call("MYSQL_SERVICE","lua","query",sqlstr)
	player.basic = res[1]

	sqlstr = "SELECT data FROM L2.item_b where playerid = "..player.playerid;
	local items = skynet.call("MYSQL_SERVICE","lua","query",sqlstr)
    _,player.items = pcall(load("return "..items[1].data))

	sqlstr = "SELECT data FROM L2.soul_b where playerid = "..player.playerid;
	local souls = skynet.call("MYSQL_SERVICE","lua","query",sqlstr);
	_,player.souls = pcall(load("return "..souls[1].data))
    
    sqlstr = "SELECT data FROM L2.task_b where playerid = "..player.playerid;
    local tasks = skynet.call("MYSQL_SERVICE","lua","query",sqlstr);
    _,player.tasks = pcall(load("return "..tasks[1].data))
    print ("player "..player.playerid.."is initalized!")

    -- finish task test
    
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
	print "get_rank_data"
	-- local res = skynet.call("REDIS_SERVICE","lua","proc","zadd","scoreboard",self.fightpower,
	-- 	  ""..player.basic.nickname.."|"..player.basic.playerid)

	local res = skynet.call("REDIS_SERVICE","lua","proc","zrevrange","scoreboard",self.start-1,
		  self.start+self.count-2,"withscores")

	print ("aaa"..dump(res))
	local result = {}
	for i=1,self.count*2,2 do
		local tbl = res[i]:split("|")
	    table.insert(result,
	    	{ playerid = tonumber(tbl[2]) , 
	    	  name = tbl[1] , 
	    	  score = tonumber(res[i+1]) , 
	    	  rank = math.ceil((i-1)/2)+self.start })
    end

    return { data = result }

	--return { data = { { playerid = 1 , name = "aa" , rank = 1 , score = 182 },{ playerid = 2, name = "bb" , rank = 2 , score = 175} }}
end

function REQUEST:get_player_soul()
    return { souls = player.souls }
end

function REQUEST:set_player_basic()
	return { result = 1}
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
			--table.insert(player.items,v)
		end
	end

	return { result = 1 }
end

function REQUEST:set_fightpower()
	print "set fightpower~"
	local res = skynet.call("REDIS_SERVICE","lua","proc","zadd","scoreboard",self.fightpower,
		  ""..player.basic.nickname.."|"..player.basic.playerid)
	return { result = 1 }
end

function REQUEST:set_player_soul()
 --    local function exist_soul(soulid)
 --        for i,v in pairs(player.souls) do
 --        	if v.soulid == soulid then
 --        		return true,i
 --        	end
 --        end
 --        return false,nil
 --    end
    

	-- for i,v in pairs(self.souls) do
	-- 	local exist,id = exist_soul(v.soulid)
	-- 	if exist then
	-- 		player.souls[id] = v
	-- 	else 
	-- 		player.souls[v.soulid] = v 
	-- end
	for i,v in pairs(self.souls) do
		player.souls[v.soulid] = v
	end
	return { result = 1}
end

function REQUEST:get_tasks()
	return {
        tasks = {
            { taskid = 0,type = 0,description = "first task",percent = 0},
            { taskid = 1,type = 1,description = "2 task",percent = 50},
            { taskid = 2,type = 2,description = "3 task",percent = 100},
            { taskid = 3,type = 3,description = "4 task",percent = 100},
            { taskid = 4,type = 4,description = "5 task",percent = 100},
            { taskid = 5,type = 5,description = "6 task",percent = 100},
    	}
	}
end



function REQUEST:set_cur_stayin_level()
    player.basic.cur_stayin_level = self.level
    return { result = 1}
end

function REQUEST:strengthen_item()
    if have_enough_gold(self.gold) and have_enough_stone(self.stone) and 
       have_enough_diamond(self.diamond) and have_item(self.item.itemid) then

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

	add_gold(self.gold)
end



--落地数据到数据库
local function save_to_db()
    local theres = skynet.call("MYSQL_SERVICE","lua","query","SELECT playerid from L2.player_basic where playerid = "..player.basic.playerid)
    print("hehehe.."..dump(theres))

    if #theres == 0 then
    	print ("first save this player !!")
	    local name_str = ""
	    local value_str = ""
	    for i,v in pairs(player.basic) do
            name_str = name_str.."`"..i.."`,"
            value_str = value_str.."'"..v.."',"
	    end
	    name_str = string.sub(name_str,0,string.len(name_str)-1)
	    value_str = string.sub(value_str,0,string.len(value_str)-1)
	    local sqlstr = "INSERT INTO L2.player_basic ("..name_str..") VALUES ("..value_str..");"

	    print ("ludiludi sqlstr"..sqlstr)
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



    else
    	print ("the player is exist,update mysql")
        local tmp = ""
        for i,v in pairs(player.basic) do
        	tmp = tmp..i.."='"..v.."',"
        end
        tmp = string.sub(tmp,0,string.len(tmp)-1)
    	local str = "UPDATE L2.player_basic set "..tmp.."where playerid =".. player.basic.playerid
	    local res = skynet.call("MYSQL_SERVICE","lua","query",str)

	    local function get_data_from_mysql(player_table,mysql_table)
	    	local thestr = dump(player[player_table],true)
	        str = "UPDATE L2."..mysql_table.." SET data = '"..thestr.."' where playerid = "..player.basic.playerid;
	        local res = skynet.call("MYSQL_SERVICE","lua","query",str)
	    end


	    get_data_from_mysql("items","item_b")
	    get_data_from_mysql("souls","soul_b")
	    get_data_from_mysql("tasks","task_b")
	
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
            { taskid = 0,type = 0,description = "pass level 1",percent = 0},
            { taskid = 1,type = 1,description = "2 task",percent = 0},
            { taskid = 2,type = 2,description = "3 task",percent = 0},
            { taskid = 3,type = 3,description = "4 task",percent = 0},
            { taskid = 4,type = 4,description = "5 task",percent = 0},
            { taskid = 5,type = 5,description = "6 task",percent = 0},
    	} 
    
    save_to_db()

    -- 战5渣 at first
    local res = skynet.call("REDIS_SERVICE","lua","proc","zadd","scoreboard",5,
		  ""..player.basic.nickname.."|"..player.basic.playerid)


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

local function send_package(pack)
  
	local package = string.pack(">s2", pack)
	socket.write(client_fd, package)
end



skynet.register_protocol {
	name = "client",
	id = skynet.PTYPE_CLIENT,
	unpack = function (msg, sz)
		return host:dispatch(msg, sz)
	end,
	dispatch = function (_, _, type, ...)
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
}



function CMD.chat(themsg)
    print "CMD chat"
	send_package(send_request("chatting",{name = themsg.name ,msg = themsg.msg,time = os.date()}))
end



function CMD.start(conf)
	local fd = conf.client
	local gate = conf.gate
	WATCHDOG = conf.watchdog
	-- slot 1,2 set at main.lua
	host = sprotoloader.load(1):host "package"
	send_request = host:attach(sprotoloader.load(2))

	skynet.fork(function()
		while true do
			print "send heartbeat"
			send_package(send_request "heartbeat")
			skynet.sleep(500)
		end
	end)

	skynet.fork(function()
		while true do
			print "update_task"
			send_package(send_request("update_task",{
			    task = { taskid = 0,type = 0,description = "first task",percent = 100}
			}
			))

			-- send_package(send_request("update_task",{
			--     task = 123
			-- }
			-- ))
			skynet.sleep(1000)
		end
	end)

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
