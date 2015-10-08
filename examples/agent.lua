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

function REQUEST:get()
	print("get", self.what)
	local r = skynet.call("SIMPLEDB", "lua", "get", self.what)
	return { result = r }
end

function REQUEST:set()
	print("set", self.what, self.value)
	local r = skynet.call("SIMPLEDB", "lua", "set", self.what, self.value)
end

function REQUEST:handshake()
	--print "send handshake"
	return { msg = "Welcome to skynet, I will send heartbeat every 5 sec." }
end

function REQUEST:getnews()
	print "require news"
	local r = skynet.call("SIMPLENEWS", "lua","getnews")
	return { msg = r }
end

function REQUEST:login_chatroom()
	skynet.call("CHATROOM","lua","login",skynet:self())
end

function REQUEST:logout_chatroom()
    skynet.call("CHATROOM","lua","logout",skynet:self())
end

function REQUEST:login()
	print "request login"
	player.playerid = self.playerid

	sqlstr = "SELECT * FROM L2.player_basic where playerid = "..player.playerid;
	local res = skynet.call("MYSQL_SERVICE","lua","query",sqlstr)
	player.player_basic = res

	sqlstr = "SELECT * FROM L2.equipment where playerid = "..player.playerid;
	local equip = skynet.call("MYSQL_SERVICE","lua","query",sqlstr)
	player.equipment = equip

	return { result = 1 }
end


function REQUEST:get_player_data()
    if self.type == 0 then
    	if self.playerid == player.playerid then
    	    return { data = player.player_basic }
    	else
    		sqlstr = "SELECT * FROM L2.player_basic where playerid = "..player.playerid;
			local res = skynet.call("MYSQL_SERVICE","lua","query",sqlstr)
			player.player_basic = res
			return { data = res }
		end

    	-- 0 basic
    elseif self.type == 1 then
    	-- 1 fight
    elseif self.type == 2 then
    	-- 2 items
    end
end


function REQUEST:chat()
	print ("request chat ")
    skynet.call("CHATROOM","lua","chat",{name = self.name,msg = self.msg})
    return { result = 1 }
end

function REQUEST:quit()
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
    --print ("send pack.."..pack)
	local package = string.pack(">s2", pack)
	--socket.write(client_fd, package)
	socket.write(client_fd, package)
	--socket.write(client_fd, "12321\n")
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

	client_fd = fd
	skynet.call(gate, "lua", "forward", fd)
end


function CMD.disconnect()
	-- todo: do something before exit
    skynet.send("CHATROOM","lua","logout",skynet.self())
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
