local skynet = require "skynet"
require "skynet.manager"	-- import skynet.register
local sharedata = require "sharedata"



local command = {}


function command.update()
	return 0
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
    
	skynet.register "SHOP_SERVICE"

end)
