local value_list = {} 

--[[ 
id 任务id
name 任务名称
task_des 任务描述
task_type 任务类型 1平常任务 2日常任务


trigger_type   触发任务类型
trigger_condition 触发条件  

    trigger_type                 trigger_condition 
  -1不会触发(由别的任务触发)              无效
 0创建人物触发（初始触发）                无效
  1升级（过关)触发                      关卡 
  2解锁武器娘触发                       武器娘type
  3获得物品触发                         物品id
   4解锁系统触发                        系统id
     

needs_type 任务完成需求类型          needs_target          needs_num         
达到等级    1                        等级值
拥有武器娘   2                       武器娘id
拥有物品   3                          物品id
解锁系统   4                          系统id
总计消耗物品  5                       1金币  2钻石           数量
通过关卡   6                          关卡
穿上了装备   7                        装备id
学习了技能   8                         技能id
技能升级到了等级   9                   技能id                技能等级
好友数量   10                          数量
熔炼次数   11                          次数
对战次数   12                   类型1 1v1   类型2 3v3         次数   
聊天次数   13                       次数
在线时长   14                       时间(分钟)

continue 后续任务id
diamond 钻石奖励
gold   金币奖励
extra_reward_taget 奖励物品id
extra_reward_num  奖励物品数量



]]

value_list[1] = {id = 1, name = "通过第一关", task_des = "11111", task_type = 1, trigger_type = 0, trigger_condition = 0, needs_type = 1, needs_target = 1, needs_num = 1, pre = "0", continue = 2, diamond = 5, gold = 1000, extra_reward_taget = 2010101 , extra_reward_num = 1,icon = 1}
value_list[2] = {id = 2, name = "通过第二关", task_des = "22222", task_type = 1, trigger_type = -1, trigger_condition = 1, needs_type = 1, needs_target = 2, needs_num = 1, pre = "0", continue = 3, diamond = 5, gold = 1000, extra_reward_taget = 2010101 , extra_reward_num = 1,icon = 1}
value_list[3] = {id = 3, name = "通过第三关", task_des = "3333", task_type = 1, trigger_type = -1, trigger_condition = 2, needs_type = 1, needs_target = 3, needs_num = 1, pre = "0", continue = 4, diamond = 5, gold = 1000,  extra_reward_taget = nil, extra_reward_num = 1,icon = 1}
value_list[4] = {id = 4, name = "通过第四关", task_des = "4444", task_type = 1, trigger_type = -1, trigger_condition = 3, needs_type = 1, needs_target = 4, needs_num = 3, pre = "0", continue = 5, diamond = 5, gold = 1000, extra_reward_taget = 2010101 , extra_reward_num = 1,icon = 1}
value_list[5] = {id = 5, name = "通过第五关", task_des = "555", task_type = 1, trigger_type = -1, trigger_condition = 3, needs_type = 1, needs_target = 5, needs_num = 3, pre = "0", continue = 6, diamond = 5, gold = 1000, extra_reward_taget = 2010101 , extra_reward_num = 1,icon = 1}
value_list[6] = {id = 6, name = "通过第六关", task_des = "666", task_type = 1, trigger_type = -1, trigger_condition = 3, needs_type = 1, needs_target = 6, needs_num = 3, pre = "0", continue = 7, diamond = 5, gold = 1000, extra_reward_taget = 2010101 , extra_reward_num = 1,icon = 1}
value_list[7] = {id = 7, name = "通过第七关", task_des = "777", task_type = 1, trigger_type = -1, trigger_condition = 3, needs_type = 1, needs_target = 7, needs_num = 3, pre = "0", continue = -1, diamond = 5, gold = 1000, extra_reward_taget = 2010101 , extra_reward_num = 1,icon = 1}
value_list[8] = {id = 8, name = "熔炼1次", task_des = "4444", task_type = 1, trigger_type = 1, trigger_condition = 3, needs_type = 11, needs_target = 1, needs_num = 3, pre = "0", continue = 9, diamond = 5, gold = 1000, extra_reward_taget = 2010101 , extra_reward_num = 1,icon = 1}
value_list[9] = {id = 9, name = "熔炼2次", task_des = "4444", task_type = 1, trigger_type = -1, trigger_condition = 3, needs_type = 11, needs_target = 2, needs_num = 3, pre = "0", continue = 10, diamond = 5, gold = 1000, extra_reward_taget = 2010101 , extra_reward_num = 1,icon = 1}
value_list[10] = {id = 10, name = "熔炼3次", task_des = "4444", task_type = 1, trigger_type = -1, trigger_condition = 3, needs_type = 11, needs_target = 3, needs_num = 3, pre = "0", continue = 11, diamond = 5, gold = 1000, extra_reward_taget = 2010101 , extra_reward_num = 1,icon = 1}
value_list[11] = {id = 11, name = "熔炼5次", task_des = "4444", task_type = 1, trigger_type = -1, trigger_condition = 3, needs_type = 11, needs_target = 5, needs_num = 3, pre = "0", continue = 12, diamond = 5, gold = 1000, extra_reward_taget = 2010101 , extra_reward_num = 1,icon = 1}
value_list[12] = {id = 12, name = "熔炼8次", task_des = "4444", task_type = 1, trigger_type = -1, trigger_condition = 3, needs_type = 11, needs_target = 8, needs_num = 3, pre = "0", continue = -1, diamond = 5, gold = 1000, extra_reward_taget = 2010101 , extra_reward_num = 1,icon = 1}
value_list[13] = {id = 13, name = "消耗100金币", task_des = "4444", task_type = 1, trigger_type = 0, trigger_condition = 3, needs_type = 5, needs_target = 1, needs_num = 100, pre = "0", continue = 14, diamond = 5, gold = 1000, extra_reward_taget = 2010101 , extra_reward_num = 1,icon = 1}
value_list[14] = {id = 14, name = "消耗1000金币", task_des = "4444", task_type = 1, trigger_type = -1, trigger_condition = 3, needs_type = 5, needs_target = 1, needs_num = 1000, pre = "0", continue = 15, diamond = 5, gold = 1000, extra_reward_taget = 2010101 , extra_reward_num = 1,icon = 1}
value_list[15] = {id = 15, name = "消耗10000金币", task_des = "4444", task_type = 1, trigger_type = -1, trigger_condition = 3, needs_type = 5, needs_target = 1, needs_num = 10000, pre = "0", continue = -1, diamond = 5, gold = 1000, extra_reward_taget = 2010101 , extra_reward_num = 1,icon = 1}
value_list[16] = {id = 16, name = "消耗5钻石", task_des = "4444", task_type = 1, trigger_type = 0, trigger_condition = 3, needs_type = 5, needs_target = 2, needs_num = 5, pre = "0", continue = 17, diamond = 5, gold = 1000, extra_reward_taget = 2010101 , extra_reward_num = 1,icon = 1}
value_list[17] = {id = 17, name = "消耗10钻石", task_des = "4444", task_type = 1, trigger_type = -1, trigger_condition = 3, needs_type = 5, needs_target = 2, needs_num = 10, pre = "0", continue = 18, diamond = 5, gold = 1000, extra_reward_taget = 2010101 , extra_reward_num = 1,icon = 1}
value_list[18] = {id = 18, name = "消耗100钻石", task_des = "4444", task_type = 1, trigger_type = -1, trigger_condition = 3, needs_type = 5, needs_target = 2, needs_num = 100, pre = "0", continue = 19, diamond = 5, gold = 1000, extra_reward_taget = 2010101 , extra_reward_num = 1,icon = 1}
value_list[19] = {id = 19, name = "消耗1000钻石", task_des = "4444", task_type = 1, trigger_type = -1, trigger_condition = 3, needs_type = 5, needs_target = 2, needs_num = 1000, pre = "0", continue = -1, diamond = 5, gold = 1000, extra_reward_taget = 2010101 , extra_reward_num = 1,icon = 1}
return value_list 
