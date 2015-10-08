local skynet = require "skynet"
require "skynet.manager"
local mysql = require "mysql"

local function dump(obj)
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
        return table.concat(tokens, "\n")
    end
    return dumpObj(obj, 0)
end


local command = {}
local db

function command.QUERY(str)
    print ("mysql_service query "..str)
    res = db:query(str)
    print (dump(res))
    return res
end

skynet.start(function()
    
    db=mysql.connect{
        host="121.40.241.223",
        port=3306,
        database="L2",
        user="ludi",
        password="67108864ld",
        max_packet_size = 1024 * 1024
    }
    if not db then
        print("failed to connect")
    end
    print("mysql_service success to connect to mysql server")

    skynet.dispatch("lua", function(session, address, cmd, ...)
        local f = command[string.upper(cmd)]
        if f then
            skynet.ret(skynet.pack(f(...)))
        else
            error(string.format("Unknown command %s", tostring(cmd)))
        end
    end)
    skynet.register "MYSQL_SERVICE"
    --db:query("set names utf8")
  

    -- local res = db:query("drop table if exists cats")
    -- res = db:query("create table cats "
    --                    .."(id serial primary key, ".. "name varchar(5))")
    -- print( dump( res ) )

    -- res = db:query("insert into cats (name) "
    --                          .. "values (\'Bob\'),(\'\'),(null)")
    -- print ( dump( res ) )

    -- res = db:query("select * from cats order by id asc")
    -- print ( dump( res ) )

    -- -- test in another coroutine
    -- skynet.fork( test2, db)
    -- skynet.fork( test3, db)
    -- -- multiresultset test
    -- res = db:query("select * from cats order by id asc ; select * from cats")
    -- print ("multiresultset test result=", dump( res ) )

    -- print ("escape string test result=", mysql.quote_sql_str([[\mysql escape %string test'test"]]) )

    -- -- bad sql statement
    -- local res =  db:query("select * from notexisttable" )
    -- print( "bad query test result=" ,dump(res) )

    -- local i=1
    -- while true do
    --     local    res = db:query("select * from cats order by id asc")
    --     print ( "test1 loop times=" ,i,"\n","query result=",dump( res ) )

    --     res = db:query("select * from cats order by id asc")
    --     print ( "test1 loop times=" ,i,"\n","query result=",dump( res ) )


    --     skynet.sleep(1000)
    --     i=i+1
    -- end

    --db:disconnect()
    --skynet.exit()
end)
