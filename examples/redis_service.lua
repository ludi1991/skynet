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

local redis_single_fp_name = "fp_single_rank"
local redis_team_fp_name = "fp_team_rank"
local redis_1v1_name = "1v1_rank"
local redis_3v3_name = "3v3_rank"



function command.PROC(func,...)
    print "proc"
    print (func)
    print (...)
    local res = db[func](db,...)
    return res
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
    
    --add 1000 robot
    for i=1,1000 do
        db:zadd(redis_single_fp_name,i,"robot_s"..i.."|"..i)
        db:zadd(redis_team_fp_name,i,"robot_t"..i.."|"..i)
        db:zadd(redis_1v1_name,i,"robot_1"..i.."|"..i)
        db:zadd(redis_3v3_name,i,"robot_3"..i.."|"..i)
    end

    
    --print (db:zrange(redis_single_fp_name,0,2))
    
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

