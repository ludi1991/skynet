local skynet = require "skynet"
require "skynet.manager"	-- import skynet.register
local db = {}

local command = {}

function command.DAILYUPDATE(count)
   
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
	skynet.register "DAILYUPDATE"
end)
