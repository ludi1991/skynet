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
	return { rank = 5 }
end




function REQUEST:login()
	player.playerid = self.playerid

	local sqlstr

	  -- playerid 0 : integer
   --  level 1 : integer
   --  gold 2 : integer
   --  diamond 3 : integer
   --  nickname 4 : string
   --  last_login_time 5 : string
   --  create_time 6 : string

	sqlstr = "SELECT playerid,level,gold,diamond,nickname,last_login_time,create_time,cursoul FROM L2.player_basic where playerid = "..player.playerid;
	local res = skynet.call("MYSQL_SERVICE","lua","query",sqlstr)
	player.basic = res[1]


	-- sqlstr = "SELECT itemid,itemtype,itemextra,itemcount FROM L2.item where playerid = "..player.playerid;
	-- local items = skynet.call("MYSQL_SERVICE","lua","query",sqlstr)
	-- player.items = items

	sqlstr = "SELECT data FROM L2.item_b where playerid = "..player.playerid;
	local items = skynet.call("MYSQL_SERVICE","lua","query",sqlstr)
    print ("eeeee"..items[1].data)
    _,player.items = pcall(load("return "..items[1].data))
    print ("eeee"..dump(player.items))

	sqlstr = "SELECT * FROM L2.soul where playerid = "..player.playerid;
	local souls = skynet.call("MYSQL_SERVICE","lua","query",sqlstr);
    
    player.souls = {}
    for i,v in pairs(souls) do
        local temp = {}
        temp.soulid = i
        temp.itemids = {}
        for k = 1,12 do

        	local str = "pos"..k.."_itemid"
        	if v[str] ~= nil then
        		temp.itemids[k] = v[str]
        	else
        		temp.itemids[k] = -1
        	end
        end

        player.souls[i] = temp  	
    end

    print (dump(player.souls))

    print ("player "..player.playerid.."is initalized!")

    -- finish task test
    



	return { result = 1 }
end


function REQUEST:get_player_items()
	return { items = player.items }
end

function REQUEST:get_rank_data()
	return { data = { { playerid = 1 , name = "aa" , rank = 1 , score = 182 },{ playerid = 2, name = "bb" , rank = 2 , score = 175} }}
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
	return { time = os.date("%Y-%m-%M %X") }
end



function REQUEST:pass_level()
	player.basic.gold = player.basic.gold + self.gold
	player.basic.diamond = player.basic.diamond + self.diamond
	for _,v in pairs(self.items) do
		table.insert(player.items,v)
	end
	if player.basic.level == self.level then
        player.basic.level = player.basic.level + 1
    end

	print(dump(player.items))
	return { result = 1 }
end

function REQUEST:set_player_soul()
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

function REQUEST:create_new_player()

    player = {}


    local sqlstr = "SELECT playerid FROM L2.player_basic order by playerid desc limit 1"
	local newplayerid = skynet.call("MYSQL_SERVICE","lua","query",sqlstr)[1].playerid + 1
	
    player.basic = {
        playerid = newplayerid,
        nickname = self.nickname..math.random(100000),
        diamond = 0,
        gold = 0,
        create_time = os.date("%Y-%m-%M %X"),
        level = 1,
        last_login_time = os.date("%Y-%m-%M %X"),
        cursoul = 1,
    }

    print (os.date())

    player.items = {}
    player.souls = {}
    player.tasks = {
            { taskid = 0,type = 0,description = "first task",percent = 0},
            { taskid = 1,type = 1,description = "2 task",percent = 0},
            { taskid = 2,type = 2,description = "3 task",percent = 0},
            { taskid = 3,type = 3,description = "4 task",percent = 0},
            { taskid = 4,type = 4,description = "5 task",percent = 0},
            { taskid = 5,type = 5,description = "6 task",percent = 0},
    	} 

    return { result = 1 , playerid = newplayerid }
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
	    str = "INSERT INTO L2.item_b (playerid,data) values ('"..player.basic.playerid.."','"..soulstr.."');"
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
	
	    local itemstr = dump(player.items,true)
	    str = "UPDATE L2.item_b SET data = '"..itemstr.."' where playerid = "..player.basic.playerid;
	    local res = skynet.call("MYSQL_SERVICE","lua","query",str)

    end
 
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
