local skynet = require "skynet"
local arenamgr = {}



function arenamgr:set_player(player)
    self.player = player
end

function arenamgr:get_player_arena_rank(arena_type)
    local player = self.player
    local rank = skynet.call("ARENA_SERVICE","lua","get_index_by_playerid",player.basic.playerid,arena_type)
    local fight_power = skynet.call("DATA_CENTER","lua","get_player_fightpower",player.basic.playerid,arena_type,2) 
    return { rank = rank , fightpower = fight_power}
end


function arenamgr:get_rank_data(start,count,arena_type)
    local res = {}
    for i=start,start+count-1 do
        local playerid = skynet.call("ARENA_SERVICE","lua","get_playerid_by_index",i,arena_type)
        local data = skynet.call("DATA_CENTER","lua","get_player_data",playerid)
        local fight_power = skynet.call("DATA_CENTER","lua","get_player_fightpower",playerid,arena_type,2)
        table.insert(res,
        {
            playerid = playerid,
            name = data.basic.nickname,
            score = fight_power,
            rank = i,
            level = data.basic.level,
            head_sculpture = data.basic.head_sculpture,
        })
    end
    return { data = res}
end

function arenamgr:get_fight_data(arena_type)
    local skynet = skynet

    local function gen_fd(playerid)
        local v = playerid
        local data = skynet.call("DATA_CENTER","lua","get_player_data",v)
        local one_vs_one_fp = skynet.call("DATA_CENTER","lua","get_player_fightpower",v,1,2)
        local three_vs_three_fp = skynet.call("DATA_CENTER","lua","get_player_fightpower",v,2,2)
        local one_vs_one_items = skynet.call("DATA_CENTER","lua","generate_soul_items",v,data.config.soulid_1v1)
        local three_vs_three_items = skynet.call("DATA_CENTER","lua","generate_soul_items",v,data.config.soulid_3v3)
        local three_vs_three_souls = {}
        for i,v in pairs(data.config.soulid_3v3) do
            if data.souls[v] then
                three_vs_three_souls[v] = data.souls[v]
            else
                log ("soul "..v.."not exist")
            end
        end
        local fightdata = {
            playerid = v,
            nickname = data.basic.nickname,
            imageid = data.basic.head_sculpture,
            level = data.basic.level,
            one_vs_one_fp = one_vs_one_fp,
            one_vs_one_soul = data.souls[data.config.soulid_1v1],
            one_vs_one_items = one_vs_one_items,
            three_vs_three_fp = three_vs_three_fp,
            three_vs_three_souls = three_vs_three_souls,
            three_vs_three_items = three_vs_three_items,
        }
        return fightdata
    end
    
    local player_data = gen_fd(self.player.basic.playerid)
    local player_rank = skynet.call("ARENA_SERVICE","lua","get_index_by_playerid",self.player.basic.playerid,arena_type)


    local ids = 
    { 
        skynet.call("ARENA_SERVICE","lua","get_playerid_by_index",math.floor(player_rank*0.9)),
        skynet.call("ARENA_SERVICE","lua","get_playerid_by_index",math.floor(player_rank*0.8)),
        skynet.call("ARENA_SERVICE","lua","get_playerid_by_index",math.floor(player_rank*0.7)),
    }
    
    
    
    local enemy_data = {}
    local enemy_rank = {}
    for i,v in pairs(ids) do
        table.insert(enemy_data,gen_fd(v))
        table.insert(enemy_rank,skynet.call("ARENA_SERVICE","lua","get_index_by_playerid",v,arena_type))
    end

    return {
        enemy_data = enemy_data,
        player_data = player_data,
        enemy_rank = enemy_rank,
        player_rank = player_rank,
    }

end

function arenamgr:fight(enemyid,arena_type,result)
    local res = skynet.call("ARENA_SERVICE","lua","fight",self.player.basic.playerid,enemyid,arena_type,result)
    if res then
        return { result = 1 }
    else
        return { result = 0 }
    end
end

function arenamgr:start_fight(enemyid,arena_type)
    local res = skynet.call("ARENA_SERVICE","lua","start_fight",self.player.basic.playerid,enemyid,arena_type)
    if res then
        return { result = 1 }
    else
        return { result = 0 }
    end
end


return arenamgr