local skynet = require "skynet"
require "skynet.manager"	-- import skynet.register

local command = {}

function command.GET_RANK_DATA(key)
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
end)
