local taskmgr = {}

local task_data = require "data.task_data"
local statmgr = require "gamelogic.statmgr"

function taskmgr:get_task_details(taskid)
	return task_data[taskid]
end


--完成了任务调用 会删除任务，把任务放到config中，并且根据任务有没有后续，增加新的任务
function taskmgr:finish_task(taskid)
	local player = self.player
	if player.tasks and player.tasks[taskid] and player.tasks[taskid].percent == 100 then
		player.tasks[taskid] = nil
		self:add_to_finished_table(taskid)
        local detail = self:get_task_details(taskid)

		if detail.continue ~= nil and detail.continue ~= -1 then
            self:add_task(detail.continue)
        end
	else
		log ("taskmgr:finish task failed ,id : "..taskid ,"error")
	end
end

function taskmgr:add_task(taskid)

	local player = self.player
	local percent = taskmgr:cal_task_percent(taskid)
	self.player.tasks[taskid] = { taskid = taskid , percent = percent}
	--log (dump(player))
end

-- 计算任务完成了多少
function taskmgr:cal_task_percent(taskid)
	local details = self:get_task_details(taskid)
	--log (dump(details))
	local condition_type = details.needs_type
	local param1 = details.needs_target
	local param2 = details.needs_num
	--log ("cal_task_percent "..param1.." "..param2)
	if self:check_condition(condition_type,param1,param2) then
		return 100
	else
		return 0
	end
end

-- 更新任务
function taskmgr:update_tasks_by_condition_type(condition_type)
    for i,v in pairs(self.player.tasks) do
    	local detail = self:get_task_details(v.taskid)
    	if detail.needs_type == condition_type then
    		self:update_task(v.taskid)
    	end
    end
end

function taskmgr:update_task(taskid)
	local player = self.player
	local percent = self:cal_task_percent(taskid)
	if player.tasks[taskid] ~= nil then
		player.tasks[taskid].percent = percent
	end 
end


function taskmgr:add_to_finished_table(taskid)
	local player = self.player
	if player and player.config then
		if player.config.finished_tasks == nil then
			player.config.finished_tasks = {}
		end
		player.config.finished_tasks[taskid] = true;
	end
end

--check if the task can be triggered ，only 4 types is possile for now 
-- -1.won't trigger or trigger by last task
-- 0. new player
-- 1. level upgrade
-- 2. get new soul
-- 3. get item
-- 4. unlock system
function taskmgr:trigger_task(thetype)
	local player = self.player
    for i,v in pairs(task_data) do

        if self:have_finished_task(v.id) then
        	log ("i have finished task "..v.id )
        	-- jump
		elseif thetype == 0 then
			
			if v.trigger_type == 0 then
				self:add_task(v.id)
			end			
		elseif thetype == 1 then						
			if v.trigger_type == 1 then
				if player.basic.level >= v.trigger_condition then
					self:add_task(v.id)
				end
			end
		end	
	end
end


-- get reward for a task
function taskmgr:get_reward(taskid)
	local details = task_data[taskid]
	local item = { itemtype = details.extra_reward_taget , itemcount = extra_reward_num}
	return details.gold,details.diamond,item
end


function taskmgr:generate_tasks(save_tbl)
	local res = {}
    for i,v in pairs(save_tbl) do
    	data = task_data[i]
    	local task = {
            taskid = v.taskid,
            type = 1,
            icon = 1,
            title = data.name,
            descriptions = data.task_des,
            gold = data.gold,
            diamond = data.diamond,
            percent = v.percent,
            items = { { itemid = 0 , itemtype = data.extra_reward_taget , itemextra = 0 , itemcount = data.extra_reward_num } }
    	}


        table.insert(res,task)
    end
    return res
end

function taskmgr:set_player(player)
	self.player = player
end


function taskmgr:check_condition(type,...)
	log ("taskmgr check_condition : "..type)
    return self.condition_checker[type](self,...)
end

-----------------  条件检测
function taskmgr:have_get_enough_level(level)
	log("checking have get enough level")
	return self.player.basic.level > level
end

function taskmgr:have_souls(soul_girl_id)
end

function taskmgr:have_item(itemtype)
end

function taskmgr:have_unlocked_system(systemid)
end

--itemtype 1 gold ,itemtype 2 diamond ,itemtype 3 stone
function taskmgr:have_consumed_enough(itemtype,count)
	if itemtype == 1 then
		return statmgr:get_gold_consumed() >= count
	elseif itemtype == 2 then
		return statmgr:get_diamond_consumed() >= count
	end
end

function taskmgr:have_passed_level(levelid)
end

function taskmgr:have_wear_equip(itemid)
end

function taskmgr:have_learned_skill(skillid)
end

function taskmgr:have_get_skill_level(skillid,level)
end

function taskmgr:have_enough_friend(friend)
end

function taskmgr:have_melt_enough_times(times)
	return statmgr:get_melt_times() >= times
end

function taskmgr:have_fight_player_enough_times(type,times)
end

function taskmgr:have_talked_enough_times(times)
end

function taskmgr:have_enough_online_time(time)
	return statmgr:get_online_time() >= time
end

function taskmgr:have_finished_task(taskid)
	return self.player.config.finished_tasks[taskid] ~= nil 
end

taskmgr.condition_checker = {
	taskmgr.have_get_enough_level,    --1
	taskmgr.have_souls,                 --2
	taskmgr.have_item,               --3
	taskmgr.have_unlocked_system,      --4
	taskmgr.have_consumed_enough,      -- 5
	taskmgr.have_passed_level,       --6
	taskmgr.have_wear_equip,         --7
	taskmgr.have_learned_skill,      --8
	taskmgr.have_get_skill_level,     --9
	taskmgr.have_enough_friend,       --10
	taskmgr.have_melt_enough_times,     --11
	taskmgr.have_fight_player_enough_time,     --12
	taskmgr.have_talked_enough_times,      --13
	taskmgr.have_enough_online_time,       --14
   	taskmgr.have_finished_task,         --15
}


return taskmgr