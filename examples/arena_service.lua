local skynet = require "skynet"
require "skynet.manager"    -- import skynet.register

local command = {}

local arena_1v1 = {}
local arena_3v3 = {}

local arena_1v1_index = {}
local arena_3v3_index = {}

--[[
playerid,fp
]]




function command.GET_1v1_RANK_DATA()

end

function command.GET_3v3_RANK_DATA()
end

function command.MATCH()
end


local function init_robot()
    for i=1,100 do
        arena_1v1[i] = 1000+i
        arena_1v1_index[1000+i] = i
        arena_3v3[i] = 1000+i
        arena_3v3_index[1000+i] = i
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
    skynet.register "RANK_SERVICE"
    init_robot()

end)
