local skynet = require "skynet"
require "skynet.manager"
local redis = require "redis"

local conf = {
    host = "127.0.0.1" ,
    port = 6379 ,
    db = 0
}

local command = {}
local db

local board_name = "scoreboard"


function command.PROC(func,...)
    print "proc"
    print (func)
    print (...)
    return db[func](db,...)
   -- return db:zadd(...)
  --  return db[func](self,...)
end


local function watching()
    local w = redis.watch(conf)
    w:subscribe "foo"
    w:psubscribe "hello.*"
    while true do
        print("Watch", w:message())
    end
end

skynet.start(function()
    skynet.fork(watching)
    db = redis.connect(conf)
    if not db then
        print ("redis_connection failed")
    end

    skynet.dispatch("lua",function(session,address,cmd,...)
        local f = command[string.upper(cmd)]
        if f then
            skynet.ret(skynet.pack(f(...)))
        else
            error(string.format("Unknown command %s", tostring(cmd)))
        end
    end)
    skynet.register "REDIS_SERVICE"
    
    for i=1,1000 do
        db:zadd(board_name,i,"robot"..i.."|"..i)
    end



    db:zadd(board_name,100,"playerid|80")
    db:zadd(board_name,100,"xiaoge|75")
    db:zadd(board_name,90,"xiaogege|85")
    
    print (db:zrange(board_name,0,2))
    
    -- db:del "C"
    -- db:set("A", "hello")
    -- db:set("B", "world")
    -- db:sadd("C", "one")

    -- print(db:get("A"))
    -- print(db:get("B"))

    -- db:del "D"
    -- for i=1,10 do
    --     db:hset("D",i,i)
    -- end
    -- local r = db:hvals "D"
    -- for k,v in pairs(r) do
    --     print(k,v)
    -- end

    -- db:multi()
    -- db:get "A"
    -- db:get "B"
    -- local t = db:exec()
    -- for k,v in ipairs(t) do
    --     print("Exec", v)
    -- end

    -- print(db:exists "A")
    -- print(db:get "A")
    -- print(db:set("A","hello world"))
    -- print(db:get("A"))
    -- print(db:sismember("C","one"))
    -- print(db:sismember("C","two"))

    -- print("===========publish============")

    -- for i=1,10 do
    --     db:publish("foo", i)
    -- end
    -- for i=11,20 do
    --     db:publish("hello.foo", i)
    -- end

    --db:disconnect()
    
--  skynet.exit()
end)

