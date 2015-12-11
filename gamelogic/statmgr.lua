local statmgr = {}


function statmgr:set_player(player)
	self.player = player
	self.stat = player.stat
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

function statmgr:set_soul_fp(soulid,fp)
    self.stat.fight_power[soulid] = fp
	return true
end

-- return single if soulid is available, return a table of all fight power if not soulid is available
function statmgr:get_soul_fp(soulid)
	if soulid ~= nil then
		return self.stat.fight_power[soulid] or 0
	else
		return self.stat.fight_power
	end
end


return statmgr