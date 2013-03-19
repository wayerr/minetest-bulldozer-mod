load_module("wr_utils")
load_module("wr_router")

local this = {}


function is_stone(node)
  return minetest.get_item_group(node.name,'stone') > 0
end

-- site begin
this.Site = {}
function this.Site:new(x, y, z) --dimensions
  site = {
    _size = wr_router.pos(x, y, z),
    _data = {}
  }
  setmetatable(site, {__index = this.Site})
  return site;
end

function this.Site:set(pos, node) 
  local s = self._size
  local index = 1 + pos.x + s.x * pos.y + s.y * s.z * pos.z
  self:_set_by_i(index, node)
end

function this.Site:set_all(node)
  local s = self._size
  for i = 1, s.x * s.y * s.z do
    self:_set_by_i(i, node)
  end
end

function this.Site:_set_by_i(i, node)
  local n = self._data[i]
  if not n and not node then
    self._data[i] = nil
  elseif n then
    n.state = node.state
  else
    self._data[i] = {state = node.state}
  end
end

function this.Site:cells()
  local i = 0
  local size = self._size
  local yz = size.z * size.y
  local max = size.x * yz  
  local f = function (state, previous_pos) 
    if i > max then
      return nil, nil
    end
    local cell = self._data[i]
    local crds = i - 1
    local xy = crds % yz
    pos = {
      z = math.floor(crds / yz),
      x = math.floor(xy % size.x),
      y = math.floor(xy / size.x),
    }
    i = i + 1
    return pos, cell
  end
  return f
end
-- site end

this.Bulldozer = {}
local Bulldozer_mt = {__index = this.Bulldozer}
function this.Bulldozer:new(pos) 
  local env = minetest.env
  local meta = env:get_meta(pos)
  t = wr_utils.copy_table(this.Bulldozer)
  t.env = env
  t.meta = meta
  t.inv = meta:get_inventory()
  t.queue = {}
  t.build_node_name = 'default:cobble' --name of nodetype which used for building
  t.state = '+' --build state, allowed states '+', '-' or nil
  setmetatable(t, Bulldozer_mt)
  local mt = {__index =  wr_router.Router}
  setmetatable(t, mt)
  t:init(pos)
  return t
end

function this.Bulldozer:is_empty() 
  return #self.queue == 0
end

function this.Bulldozer:go_home()
  self.pos = wr_utils.copy_table(self.initial_pos)
end

function this.Bulldozer:build()
  self.state = '+'
end

function this.Bulldozer:erase()
  self.state = '-'
end

function this.Bulldozer:quarry(x, y, z)
  self.quarry_pos = wr_router.pos(x, y, z)
end

function this.Bulldozer:_quarrying()
  if not self.digg_pos then
    return
  end
  --first we need to find stone
  --[[
  local cursor = wr_utils.copy_table(self.quarry_pos)
  local max_size = 20 --max value of quarry raduis
  local around = 0    --counter for 27 nodes aound cursor
  while true do
    --find stone around self
    local shiff_pos = wr_utils.copy_table(cursor)
    for i = -1, 1 do
      for j = -1, 1 do
        for k = -1, 1 do
          wr_router.add(sniff_pos, i, j, k)
          local node = self:env:get_node_or_nil(cursor)
          if is_stone(node) then
            continue
          end
        end
      end
    end
    local node = self:env:get_node_or_nil(cursor)
    if is_stone(node) then
      local res = self:_grab_node(cursor, node)
      if res == nil then
        --we full
        return
      end
    else
      
      return -- we stop when no stone nodes in quarry
    end
  end
  ]]--
end

function this.Bulldozer:building_site(x, y, z) 
  self.bsite = {
    cursor = wr_router.pos(0, 0, 0), --building site cursor
    site = this.Site:new(x, y, z)
  }
end

function this.Bulldozer:clean_building_site()
  local bsite = self.bsite
  if not bsite then
    return
  end
  bsite.site:set_all({state = '-'})
end

function this.Bulldozer:process_node(pos) 
  print("process_node(pos="..minetest.pos_to_string(pos))
  self.bsite.site:set(pos, {state = self.state})
end

function this.Bulldozer:draw()
  
  local ip = self.initial_pos
  local bsite = self.bsite
  for pos, node in bsite.site:cells()  do
    if node and node.state then
      local pos = wr_router.pos(ip.x + pos.x, ip.y + pos.y, ip.z + pos.z)
      print(minetest.pos_to_string(pos).." "..tostring(node.state))
      table.insert(self.queue, {
        pos = pos,
        state = node.state
      })
    end
  end
end

function this.Bulldozer:_get_new_node(context) 
  self.inv:add_item("main", node)
  return {name = self.build_node_name}
end

function this.Bulldozer:_grab_node(pos, node)
  self.env:remove_node(pos)
  local obj = self.inv:add_item("main", node)
  return obj
end

function this.Bulldozer:_grab_node_if_normal(pos, node)
  if not node then
      --print("_grab_node: no node at "..minetest.pos_to_string(pos))
      return nil
  end
  local drawtype = wr_utils.get_nodedef_field(node.name, "drawtype")
  if drawtype == "normal" then
      self:_grab_node(pos, node)
      return pos
  end
  return nil
end

function this.Bulldozer:_put_node(pos, node)
  if node then --first grab existed node
    self:_grab_node_if_normal(pos, node)
  end
  self.env:set_node(pos, self:_get_new_node({pos = pos, old_node = node}))
  return pos
end

function this.Bulldozer:on_step()
  local task = table.remove(self.queue, 1)
  if not task then
    return nil
  end
  local pos = task.pos
  local ip = self.initial_pos
  if (pos.x == ip.x and pos.y == ip.y and pos.z == ip.z)  --skip bulldozer node position
      then 
    return nil
  end
  --print("Bulldozer:on_step(pos="..minetest.pos_to_string(pos))
  local node = self.env:get_node_or_nil(pos)
  local result = nil;
  if task.state == '+' then
    result = self:_put_node(pos, node)
  elseif task.state == '-' then
    result = self:_grab_node_if_normal(pos, node)
  end --skip nil state
  return result
end

return this

