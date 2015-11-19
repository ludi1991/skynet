local itemmgr = {}

itemmgr.items = {}

function itemmgr:set_player(player)
    self.player = player
	self.items = player.items
end


function itemmgr:can_stack(itemtype)
	if itemid == 1000001 then return true end
	return false
end

function itemmgr:generate_new_id()
	return #(self.items)+1
end

function itemmgr:get_details(itemtype)
end

function itemmgr:add_item(itemtype,count)	
	local items = self.items
    if self:can_stack(itemtype) then
        if items[itemtype] == nil then
            items[itemtype] = {
                itemid = itemtype,
                itemtype = itemid,
                itemcount = count,
        	}
        else
            items[itemtype].count = items[itemtype].count + count
        end
    else
		local newid = self:generate_new_id()
	    items[newid] = {
            itemid = newid,
	        itemtype = itemtype,
	        itemextra = 0,
	        itemcount = 1,
		}
	end
end

function itemmgr:delete_item(itemid,count)
	count = count or 1
	if self:have_item(itemid,count) then
		self.items[itemid].count = self.items[itemid].count - count
		if self.items[itemid].count == 0 then
			self.items[itemid] = nil
		end
	    return true
	else 
		return false
    end
end

function itemmgr:update_item()
end


function itemmgr:generate_item()
end

function itemmgr:strengthen_item()

end
--
function itemmgr:upgrade_item()
end

function itemmgr:melt_item()
end

function itemmgr:have_item(itemid,count)
	count = count or 1
	if self.items[itemid] ~= nil and self.items[itemid].count >= count then
		return true
	else
		return false
	end
end


function itemmgr:upgrade_diamond(itemtype)
	if self:have_item(itemtype,2) then
		if self:delete_item(itemtype,2) then
			self:add_item(itemtype+1,1)
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
    	if not self.items[itemid].dia_id then
    		self.items[itemid].dia_id = {}
    	end
    	local next_hole = #(self.items[itemid].dia_id) + 1
    	self.items[itemid].dia_id[next_hole] = -1
        return true
    else
    	return false
    end
end

function itemmgr:item_inset_diamond(itemid,dia_type,dia_hole_pos)
	if self:have_item(itemid) == false then return false end
	if self:have_item(dia_type) == false then return false end
	if self.items[itemid].dia_id[dia_hole_pos] ~= nil then
		self.items[itemid].dia_id[dia_hole_pos] = dia_type
		return true
	else 
		return false
	end

end

function itemmgr:item_pry_up_diamond(itemid,dia_hole_pos)
	if self:have_item(itemid) == false then return false end
	for i,v in pairs(dia_hole_pos) do
		if self.items[itemid].dia_id[v] == nil then
			return false
		end
	end

	for i,v in pairs(dia_hole_pos) do
		self:add_item(self.items[itemid].dia_id[v],1)
		self.items[itemid].dia_id[v] = -1
		return true
	end

end



return itemmgr