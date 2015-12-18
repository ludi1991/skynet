---------------------------
--the data's from an Excel, don't edit it here
---------------------------
local value_list = {} 
value_list[20100] = {id = 20100, name = "魂器天赋", learn_level = 1, learn_quity = nil, price = 26, level_count = 1, skill_level = 1, target = 1, section_count = nil, damage_factor = nil, damage = nil, armorpenetration = nil, hit = nil, critical = nil, critical_dam_add = 9, dam2blood_percent = nil, blood_recover = nil, status_add1 = nil, target_add1 = nil, status_add2 = nil, target_add2 = nil, icon = "skill_00", double_hit_per = nil, description = "暴击伤害增加25%", upgrade_info = nil, operation_mode = 0, trigger = 3, trigger_chance = 1, cd = 0, rage = 0}
value_list[20101] = {id = 20101, name = "普攻三连", learn_level = 1, learn_quity = nil, price = 0, level_count = 1, skill_level = 1, target = 1, section_count = 3, damage_factor = 0.3, damage = nil, armorpenetration = nil, hit = nil, critical = nil, critical_dam_add = nil, dam2blood_percent = nil, blood_recover = nil, status_add1 = nil, target_add1 = nil, status_add2 = nil, target_add2 = nil, icon = "skill_01", double_hit_per = nil, description = "普通三段攻击", upgrade_info = nil, operation_mode = nil, trigger = nil, trigger_chance = nil, cd = 0, rage = 2}
value_list[20102] = {id = 20102, name = "镭射毁灭", learn_level = 1, learn_quity = nil, price = 0, level_count = 1, skill_level = 1, target = 1, section_count = 1, damage_factor = 1, damage = nil, armorpenetration = nil, hit = nil, critical = nil, critical_dam_add = nil, dam2blood_percent = nil, blood_recover = nil, status_add1 = "14 1 1", target_add1 = 3, status_add2 = nil, target_add2 = nil, icon = "skill_02", double_hit_per = nil, description = "单次伤害，如果命中则必然暴击", upgrade_info = nil, operation_mode = nil, trigger = nil, trigger_chance = nil, cd = 0, rage = -2}
value_list[20103] = {id = 20103, name = "幻紫爆破", learn_level = 2, learn_quity = nil, price = 39, level_count = 1, skill_level = 1, target = 1, section_count = 3, damage_factor = 0.3, damage = nil, armorpenetration = nil, hit = nil, critical = nil, critical_dam_add = nil, dam2blood_percent = nil, blood_recover = nil, status_add1 = "17 1 3", target_add1 = 3, status_add2 = nil, target_add2 = nil, icon = "skill_03", double_hit_per = nil, description = "造成伤害并提升攻击力，持续3回合", upgrade_info = nil, operation_mode = nil, trigger = nil, trigger_chance = nil, cd = 0, rage = -2}
value_list[20104] = {id = 20104, name = "幻紫流星", learn_level = 3, learn_quity = nil, price = 55, level_count = 1, skill_level = 1, target = 1, section_count = 6, damage_factor = 0.5, damage = nil, armorpenetration = nil, hit = nil, critical = nil, critical_dam_add = nil, dam2blood_percent = nil, blood_recover = nil, status_add1 = "12 1 1", target_add1 = 3, status_add2 = nil, target_add2 = nil, icon = "skill_04", double_hit_per = nil, description = "高额伤害，且暴击概率翻倍", upgrade_info = nil, operation_mode = nil, trigger = nil, trigger_chance = nil, cd = 10, rage = -6}
value_list[20200] = {id = 20200, name = "血流不止", learn_level = 1, learn_quity = nil, price = 0, level_count = 1, skill_level = 1, target = 1, section_count = nil, damage_factor = nil, damage = nil, armorpenetration = nil, hit = nil, critical = nil, critical_dam_add = nil, dam2blood_percent = nil, blood_recover = nil, status_add1 = "7 1 9999", target_add1 = 1, status_add2 = nil, target_add2 = nil, icon = "skill_00", double_hit_per = nil, description = "攻击使敌人出血，叠加5层则狂怒", upgrade_info = nil, operation_mode = nil, trigger = nil, trigger_chance = nil, cd = 0, rage = nil}
value_list[20201] = {id = 20201, name = "镰刀三段", learn_level = 1, learn_quity = nil, price = 0, level_count = 1, skill_level = 1, target = 1, section_count = 3, damage_factor = 0.3, damage = nil, armorpenetration = nil, hit = nil, critical = nil, critical_dam_add = nil, dam2blood_percent = nil, blood_recover = nil, status_add1 = nil, target_add1 = nil, status_add2 = nil, target_add2 = nil, icon = "skill_01", double_hit_per = nil, description = "普通三段攻击", upgrade_info = nil, operation_mode = nil, trigger = nil, trigger_chance = nil, cd = 0, rage = 2}
value_list[20202] = {id = 20202, name = "一击必杀", learn_level = 1, learn_quity = nil, price = 0, level_count = 1, skill_level = 1, target = 1, section_count = 1, damage_factor = 2, damage = nil, armorpenetration = nil, hit = nil, critical = nil, critical_dam_add = nil, dam2blood_percent = nil, blood_recover = nil, status_add1 = nil, target_add1 = nil, status_add2 = nil, target_add2 = nil, icon = "skill_02", double_hit_per = nil, description = "攻击回复与出血层数相关的血量", upgrade_info = nil, operation_mode = nil, trigger = nil, trigger_chance = nil, cd = 0, rage = -2}
value_list[20203] = {id = 20203, name = "死亡刀舞", learn_level = 2, learn_quity = nil, price = 39, level_count = 1, skill_level = 1, target = 1, section_count = 3, damage_factor = 0.3, damage = nil, armorpenetration = nil, hit = nil, critical = nil, critical_dam_add = nil, dam2blood_percent = nil, blood_recover = nil, status_add1 = "16 1 3", target_add1 = 1, status_add2 = nil, target_add2 = nil, icon = "skill_03", double_hit_per = nil, description = "割裂敌人护甲，降低防御3回合", upgrade_info = nil, operation_mode = nil, trigger = nil, trigger_chance = nil, cd = 0, rage = -2}
value_list[20204] = {id = 20204, name = "幻影死歌", learn_level = 3, learn_quity = nil, price = 55, level_count = 1, skill_level = 1, target = 1, section_count = 14, damage_factor = 0.2, damage = nil, armorpenetration = nil, hit = nil, critical = nil, critical_dam_add = nil, dam2blood_percent = nil, blood_recover = nil, status_add1 = nil, target_add1 = nil, status_add2 = nil, target_add2 = nil, icon = "skill_04", double_hit_per = nil, description = "多段攻击，出血爆炸成附加伤害", upgrade_info = nil, operation_mode = nil, trigger = nil, trigger_chance = nil, cd = 10, rage = -6}
value_list[20300] = {id = 20300, name = "电压击穿", learn_level = 1, learn_quity = nil, price = 0, level_count = 1, skill_level = 1, target = 1, section_count = nil, damage_factor = nil, damage = nil, armorpenetration = nil, hit = nil, critical = nil, critical_dam_add = nil, dam2blood_percent = nil, blood_recover = nil, status_add1 = "8 1 9999", target_add1 = 1, status_add2 = nil, target_add2 = nil, icon = "skill_00", double_hit_per = nil, description = "攻击使敌人触电，降低防御，可叠加", upgrade_info = nil, operation_mode = nil, trigger = nil, trigger_chance = nil, cd = 0, rage = nil}
value_list[20301] = {id = 20301, name = "雷电攻击", learn_level = 1, learn_quity = nil, price = 0, level_count = 1, skill_level = 1, target = 1, section_count = 3, damage_factor = 0.3, damage = nil, armorpenetration = nil, hit = nil, critical = nil, critical_dam_add = nil, dam2blood_percent = nil, blood_recover = nil, status_add1 = nil, target_add1 = nil, status_add2 = nil, target_add2 = nil, icon = "skill_01", double_hit_per = nil, description = "普通三段攻击，造成1层触电", upgrade_info = nil, operation_mode = nil, trigger = nil, trigger_chance = nil, cd = 0, rage = 2}
value_list[20302] = {id = 20302, name = "电磁炮击", learn_level = 1, learn_quity = nil, price = 0, level_count = 1, skill_level = 1, target = 1, section_count = 1, damage_factor = 2, damage = nil, armorpenetration = nil, hit = nil, critical = nil, critical_dam_add = nil, dam2blood_percent = nil, blood_recover = nil, status_add1 = nil, target_add1 = nil, status_add2 = nil, target_add2 = nil, icon = "skill_02", double_hit_per = nil, description = "单次高额伤害，造成1层触电", upgrade_info = nil, operation_mode = nil, trigger = nil, trigger_chance = nil, cd = 0, rage = -2}
value_list[20303] = {id = 20303, name = "脉冲辐射", learn_level = 2, learn_quity = nil, price = 39, level_count = 1, skill_level = 1, target = 1, section_count = 1, damage_factor = 1, damage = nil, armorpenetration = nil, hit = nil, critical = nil, critical_dam_add = nil, dam2blood_percent = nil, blood_recover = nil, status_add1 = "10 1 1", target_add1 = 3, status_add2 = nil, target_add2 = nil, icon = "skill_03", double_hit_per = nil, description = "去除自身负面buff，造成3层触电", upgrade_info = nil, operation_mode = nil, trigger = nil, trigger_chance = nil, cd = 0, rage = -2}
value_list[20304] = {id = 20304, name = "超电磁炮", learn_level = 3, learn_quity = nil, price = 55, level_count = 1, skill_level = 1, target = 1, section_count = 1, damage_factor = 3, damage = nil, armorpenetration = nil, hit = nil, critical = nil, critical_dam_add = nil, dam2blood_percent = nil, blood_recover = nil, status_add1 = "11 1 1", target_add1 = 1, status_add2 = "18 1 1", target_add2 = 3, icon = "skill_04", double_hit_per = nil, description = "必然命中，眩晕5层触电的敌人一回合", upgrade_info = nil, operation_mode = nil, trigger = nil, trigger_chance = nil, cd = 10, rage = -6}
value_list[20400] = {id = 20400, name = "铁甲重拳", learn_level = 1, learn_quity = nil, price = 0, level_count = 1, skill_level = 1, target = 1, section_count = nil, damage_factor = nil, damage = nil, armorpenetration = nil, hit = nil, critical = nil, critical_dam_add = nil, dam2blood_percent = nil, blood_recover = nil, status_add1 = "9 1 9999", target_add1 = 3, status_add2 = nil, target_add2 = nil, icon = "skill_00", double_hit_per = nil, description = "战斗时25%防御额外转换成攻击力", upgrade_info = nil, operation_mode = nil, trigger = nil, trigger_chance = nil, cd = 0, rage = nil}
value_list[20401] = {id = 20401, name = "旋风组合", learn_level = 1, learn_quity = nil, price = 0, level_count = 1, skill_level = 1, target = 1, section_count = 4, damage_factor = 0.3, damage = nil, armorpenetration = nil, hit = nil, critical = nil, critical_dam_add = nil, dam2blood_percent = nil, blood_recover = nil, status_add1 = nil, target_add1 = nil, status_add2 = nil, target_add2 = nil, icon = "skill_01", double_hit_per = nil, description = "普通四段攻击", upgrade_info = nil, operation_mode = nil, trigger = nil, trigger_chance = nil, cd = 0, rage = 2}
value_list[20402] = {id = 20402, name = "碎裂一击", learn_level = 1, learn_quity = nil, price = 0, level_count = 1, skill_level = 1, target = 1, section_count = 1, damage_factor = 2, damage = nil, armorpenetration = nil, hit = nil, critical = nil, critical_dam_add = nil, dam2blood_percent = nil, blood_recover = nil, status_add1 = "18 1 1", target_add1 = 3, status_add2 = nil, target_add2 = nil, icon = "skill_02", double_hit_per = nil, description = "高额伤害，且强制命中", upgrade_info = nil, operation_mode = nil, trigger = nil, trigger_chance = nil, cd = 0, rage = -2}
value_list[20403] = {id = 20403, name = "防守反击", learn_level = 2, learn_quity = nil, price = 39, level_count = 1, skill_level = 1, target = 1, section_count = 0, damage_factor = 0, damage = nil, armorpenetration = nil, hit = nil, critical = nil, critical_dam_add = nil, dam2blood_percent = nil, blood_recover = nil, status_add1 = "13 1 2", target_add1 = 3, status_add2 = nil, target_add2 = nil, icon = "skill_03", double_hit_per = nil, description = "进入防守姿态并且受击时会反击", upgrade_info = nil, operation_mode = nil, trigger = nil, trigger_chance = nil, cd = 0, rage = -2}
value_list[20404] = {id = 20404, name = "天霸烈轰", learn_level = 3, learn_quity = nil, price = 55, level_count = 1, skill_level = 1, target = 1, section_count = 6, damage_factor = 0.5, damage = nil, armorpenetration = nil, hit = nil, critical = nil, critical_dam_add = nil, dam2blood_percent = nil, blood_recover = nil, status_add1 = "19 1 1", target_add1 = 1, status_add2 = nil, target_add2 = nil, icon = "skill_04", double_hit_per = nil, description = "多段攻击，无视敌人防御", upgrade_info = nil, operation_mode = nil, trigger = nil, trigger_chance = nil, cd = 10, rage = -6}
value_list[20405] = {id = 20405, name = "防守反击", learn_level = 2, learn_quity = nil, price = 39, level_count = 1, skill_level = 1, target = 1, section_count = 1, damage_factor = 1, damage = nil, armorpenetration = nil, hit = nil, critical = nil, critical_dam_add = nil, dam2blood_percent = nil, blood_recover = nil, status_add1 = nil, target_add1 = nil, status_add2 = nil, target_add2 = nil, icon = "skill_03", double_hit_per = nil, description = "进入防守姿态并且受击时会反击", upgrade_info = nil, operation_mode = nil, trigger = nil, trigger_chance = nil, cd = 0, rage = 0}

return value_list
