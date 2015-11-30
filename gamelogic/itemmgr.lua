local itemmgr = {}

itemmgr.items = {}

local item_data = require "data.equipdata"

function itemmgr:set_player(player)
    self.player = player
	self.items = player.items
end


function itemmgr:can_stack(itemtype)
	--if itemid == 1000001 then return true end
	if itemtype < 2000000 then return true end
	return false
end

function itemmgr:generate_new_id()
	return #(self.items)+1
end

function itemmgr:get_details(itemtype)
	return item_data[itemtype]
end

function itemmgr:add_item_by_object(item)
	if self:have_item(item.itemid) then
		self.items[item.itemid].itemcount = self.items[item.itemid].itemcount + item.itemcount
	else
		self.items[item.itemid] = item
	end
	return true
end

function itemmgr:add_item(itemtype,count)	
	local items = self.items
    if self:can_stack(itemtype) then
        if items[itemtype] == nil then
            items[itemtype] = {
                itemid = itemtype,
                itemtype = itemtype,
                itemcount = count,
        	}
        	return items[itemtype]
        else
            items[itemtype].itemcount = items[itemtype].itemcount + count
            return items[itemtype]
        end
    else
		local newid = self:generate_new_id()
	    items[newid] = {
            itemid = newid,
	        itemtype = itemtype,
	        itemextra = 0,
	        itemcount = 1,
		}
		return items[newid]
	end
end

function itemmgr:delete_item(itemid,count)
	count = count or 1
	if self:have_item(itemid,count) then
		self.items[itemid].itemcount = self.items[itemid].itemcount - count
		if self.items[itemid].itemcount == 0 then
			self.items[itemid] = nil
		end
	    return true
	else 
		return false
    end
end


function itemmgr:have_item(itemid,count)
	count = count or 1
	if self.items[itemid] ~= nil and self.items[itemid].itemcount >= count then
		return true
	else
		return false
	end
end


function itemmgr:upgrade_gem(itemtype)
    local gold = self:get_details(itemtype).price
    local count = self:get_details(itemtype).upgrade_cost
	if self.player.basic.gold < gold then
		return false
	end

    
	if self:have_item(itemtype,count) then
		if self:delete_item(itemtype,count) then
			self:add_item(itemtype+1,1)
			self.player.basic.gold = self.player.basic.gold - gold
			return true
		else
			return false
		end
	else
		return false
	end
end


function itemmgr:item_add_hole(itemid)
    if self:have_item(itemid) then
    	if not self.items[itemid].gem_id then
    		self.items[itemid].gem_id = {}
    	end
    	local next_hole = #(self.items[itemid].gem_id) + 1
    	self.items[itemid].gem_id[next_hole] = -1
        return true
    else
    	return false
    end
end

function itemmgr:item_inset_gem(itemid,gem_type,gem_hole_pos)
	if self:have_item(itemid) == false then return false end
	if self:have_item(gem_type) == false then return false end
	if self.items[itemid].gem_id[gem_hole_pos] ~= nil then
		self.items[itemid].gem_id[gem_hole_pos] = gem_type
		return true
	else 
		return false
	end

end

function itemmgr:item_pry_up_gem(itemid,gem_hole_pos)
	if self:have_item(itemid) == false then return false end
	for i,v in pairs(gem_hole_pos) do
		if self.items[itemid].gem_id[v] == nil then
			return false
		end
	end
    
	for i,v in pairs(gem_hole_pos) do
		self:add_item(self.items[itemid].gem_id[v],1)
		self.items[itemid].gem_id[v] = -1
	end
    return true;
end

function itemmgr:add_stone(value)
	if value >= 0 then
		self:add_item(1000001)
	else
		self:delete_item(1000001)
	end
	return true
end




return itemmgr
