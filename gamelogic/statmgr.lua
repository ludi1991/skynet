local statmgr = {}


function statmgr:set_player(player)
	self.player = player
	if player.config.stat == nil then
		player.config.stat = {
			gold_consumed = 0 ,
	        diamond_consumed = 0 , 
	        melt_times = 0 ,
	        total_online_time = 0 ,
	    }
	end
	self.stat = player.config.stat
end

function statmgr:add_gold_consumed(count)
	local stat = self.stat
	stat.gold_consumed = stat.gold_consumed + count
end

function statmgr:add_diamond_consumed(count)
	local stat = self.stat
	stat.diamond_consumed = stat.diamond_consumed + count
end

function statmgr:add_melt_times(count)
	--log("add_melt_times"..dump(self.player))
	local stat = self.stat
	stat.melt_times = stat.melt_times + count
end

function statmgr:add_total_online_time(time)
	local stat = self.stat
	stat.total_online_time = stat.total_online_time + time
end

function statmgr:get_gold_consumed()
	local stat = self.stat
	return stat.gold_consumed
end

function statmgr:get_diamond_consumed()
	local stat = self.stat
	return stat.diamond_consumed
end

function statmgr:get_melt_times()
	local stat = self.stat
	return stat.melt_times
end

function statmgr:get_total_online_time()
	local stat = self.stat
	return stat.total_online_time
end


return statmgr