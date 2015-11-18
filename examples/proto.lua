local sprotoparser = require "sprotoparser"

local proto = {}

proto.c2s = sprotoparser.parse [[
.package {
    type 0 : integer
    session 1 : integer
}

.item {          #物品
    itemid 0 : integer      #物品id,对应格子
    itemtype 1 : integer    #物品类型
    itemextra 2: integer    #物品的额外属性
    itemcount 3: integer    #物品的数量
    dia_hole_count 4 : integer #所开孔的数量
    dia_id 5 : *integer # 宝石的ids 
}

.player_basic {    #玩家基础数据
    playerid 0 : integer    #游戏角色的唯一标识id
    level 1 : integer       #玩家等级
    gold 2 : integer        #金钱
    diamond 3 : integer     #钻石
    nickname 4 : string     #昵称
    last_login_time 5 : string    #上次登录时间
    create_time 6 : string        #创建时间
    cursoul 7 : integer #当前使用的魂
    cur_stayin_level 8 : integer #当前挂机关卡
}

.rankdata {       #排名信息
    playerid 0 : integer      #玩家角色id        
    name 1 : string           #玩家昵称
    rank 2 : integer           #玩家排名
    score 3 : integer         #分数
}


.skill {
    skillid 0 : integer
    level 1 : integer
}

.soul {            #魂的信息
    soulid 0: integer      #魂的id(1~12)
    itemids 1: *integer    #魂的每个部位对应装备id
    soul_girl_id 2 :integer  #魂的武器娘id
    skill 3 : *skill # 技能 
}

.fightdata {  #玩家战斗信息
    playerid 0 : integer
    nickname 1 : string
    imageid 2 : integer
    level 3 : integer
    one_vs_one_fp 4 : integer
    one_vs_one_soul 5: soul
    one_vs_one_items 6 : *item
    three_vs_three_fp 7 : integer
    three_vs_three_souls 8 : *soul
    three_vs_three_items 9 : *item
}

.task {
    taskid 0: integer  #任务id   
    type 1 :integer    #任务类型
    icon 2 :integer    #任务icon
    title 3 : string   #任务名
    description 4: string  #任务描述
    gold 5 : integer
    diamond 6 : integer
    items 7: *item
    percent 8: integer    #完成百分比
}


handshake 1 {
    response {
        msg 0  : string
    }
}

get 2 {
    request {
        what 0 : string
    }
    response {
        result 0 : string
    }
}

set 3 {
    request {
        what 0 : string
        value 1 : string
    }
}

quit 4 {}

getnews 5 {
    response {
        msg 0 : string
    }
}

chat 6 {     #聊天
    request {
        msg 0 : string      #信息
        name 1 : string     #昵称
    }
    response {
        result 1 : integer    #结果(1表示成功，0表示失败)
    }
}

get_player_basic 7 {   #获取玩家基本数据
    request {
        playerid 0: integer    #玩家
    }
    response {
        data 0: player_basic
    }
}

#获取玩家排名
get_player_rank 8{ 
    request {
        ranktype 0 : integer #1个人战力 2团队战力 3 1v1paiming 4 3v3排名
    }    
    response {
        rank 0: integer       #排名
        fightpower 1: integer   #战斗力
    }
}

#登录
login 9 {   
    request {
        playerid 0: integer       #角色id
    }
    response {
        result 0: integer        #结果(1:成功 0:失败)
    }
}

#获取玩家物品
get_player_items 10 {  
    request {
        start 0 :integer   #起始的index   
        count 1 :integer   #发多少个
    }
    response {
        items 0 : *item    #物品列表
    }
}

#获取排行榜信息
get_rank_data 11 {
    request {
        start 0 : integer    #起始的index(1是第一个)
        count 1 : integer    #数量
        ranktype 2 : integer 
    }

    response {
        data 0 : *rankdata  #排名列表
    }
}

#获取玩家魂的信息  
get_player_soul 12 {
    response {
        souls 0: *soul    #魂信息的列表
    }
}


#过关
pass_level 14 {
    request {
        level 0 : integer  #第几关
        items 1 : *item
        gold 2 : integer
        diamond 3 :integer
    }
    response {
        result 0 : integer
    }
}




#设置灵魂
set_player_soul 15 {
    request {
        souls 0: *soul #设置灵魂
    }
    response {  
        result 0 : integer #1成功 0失败
    }
}


#任务
get_tasks 16 {
    response {
        tasks 0 : *task
    }
}

#创建人物
create_new_player 17 {
    request { 
        nickname 0: string
    }
    response {
        result 0 : integer #1成功0失败
        playerid 1 : integer
    }
}

#设置当前灵魂
set_cursoul 18 {
    request {
        soulid 0 : integer #灵魂的id
    }
    response {
        result 1 :integer   #1成功0失败
    }
}

#获取当前服务器时间
get_server_time 19 {
    response {
        time 0 : string #服务器时间,格式  "2015-10-23 19:20:39"
    }
}





#领取奖励
get_task_reward 20 {
    request {
        taskid 0 :integer 
    }
    response {
        gold 0 : integer
        diamond 1 : integer
        items 2: *item
    }
}

pass_boss_level 21 {
    request {
        level 0 : integer  #第几关
        items 1 : *item
        gold 2 : integer
        diamond 3 :integer
    }
    response {
        result 0 : integer
    }
}

#设置玩家战斗力
set_fightpower 22{
    request {
        fightpower 0 : integer
        type 1 :integer #1 单独武器娘战斗力 2团队战斗力 
    }
    response {
        result 0 : integer #1success0failed
    }
}

#获取玩家的战斗信息(用于玩家对战)
get_fight_data 23 {
    request {
        fight_type 0 : integer  #type 1 1v1 3 3v3
    }
    response {
        enemy_data 0 : *fightdata
        player_data 1 : fightdata
        enemy_rank 2 : *integer
        player_rank 3 : integer

    }
}

set_cur_stayin_level 24 {
    request {
        level 0 : integer
    }
    response {
        result 0 : integer #1成功0失败
    }
}



strengthen_item 25 {
    request {
        gold 0 : integer
        diamond 1 : integer
        stone 2 : integer
        item 3 : item
    }   
    response {
        result 0 : integer #1成功 0nomoney 2noitem
    }    
}

upgrade_item 26 {
    request {
        gold 0 : integer
        diamond 1 : integer
        item 2 : item
    }
    response {
        result 0 :integer #1success 0nostone 2noitem
    }
}

#熔炼装备
melt_item 27 {
    request {
        itemids 0 : *integer 
        newitem 1 : item
        stone 2 : integer
    }
    response {
        result 0 :integer #1success 0noitem
    }
}

#卖物品
sell_item 28 {
    request {
        itemids 0 : *integer
        gold 1 : *integer
    }
    response {
        result 0: integer #1success 0noitem
    }
}

#玩家对战结果
fight_with_player_result 29{
    request {
        enemyid 0 : integer
        fighttype 1 : integer #1 1v1 2 3v3
        result 2 : integer #1win 2lose
    }
    response {
        result 0 : integer #1success 0 failed
    }
}

#离线战斗奖励
add_offline_reward 30 {
    request {
        level 0 : integer  #第几关
        items 1 : *item
        gold 2 : integer
        diamond 3 :integer
    }
    response {
        result 0 : integer
    }
}

#设置出战的武器娘
set_fight_soul 31 {
    request {
        type 0 : integer #1 1v1 2 3v3
        soulid 1 : *integer #武器娘id如果是1v1就是1个值,如果是3v3就是3个值
    }
    response {
        result 0 : integer #1success0failed
    }
}

#获得对战玩家的id
get_fight_player_ids 32 {
    response {
        one_vs_one_ids 0 : *integer
        three_vs_three_ids 1 : *integer
    }
}

start_fight_with_player 33 {
    request {
        playerid 0 : integer #enemy playerid
        fighttype 1 : integer 
    }
    response {
        result 0 : integer # 1 success 0 occupid -1 failed
    }
}

collect_parachute 34 {
    request {
        gold 0 : integer
        diamond 1 : integer
    }
    response {
        result 0 : integer # 1 success 0 failed
    }
}


upgrade_diamond 35 {
    request {
        diamondid 0 :integer
    }    
    response {
        result 0 : integer # 1 success 0 failed
    }
}

item_add_hole 36 {
    request {
        itemid 0 : integer
    }
    response {
        result 0 : integer # 1 success 0 failed
    }
}




]]

proto.s2c = sprotoparser.parse [[
.package {
    type 0 : integer
    session 1 : integer
}

.item {          #物品
    itemid 0 : integer      #物品id,对应格子
    itemtype 1 : integer    #物品类型
    itemextra 2: integer    #物品的额外属性
    itemcount 3: integer    #物品的数量
}

.task {
    taskid 0: integer  #任务id   
    type 1 :integer    #任务类型
    icon 2 :integer    #任务icon
    title 3 : string   #任务名
    description 4: string  #任务描述
    gold 5 : integer
    diamond 6 : integer
    items 7: *item
    percent 8: integer    #完成百分比
}

heartbeat 1 {}

#聊天返回
chatting 2 {
    request {
        name 0 : string
        msg 1 : string
        time 2 : string 
    }
}

#更新任务
update_task 3 {
    request {
        task 0: task
    }   
}


]]

return proto
