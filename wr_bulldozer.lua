load_module("wr_utils")
load_module("wr_router")

local this = {}

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
  t.build_node_name = nil --name of nodetype which used for building
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
  self:set_build_mode(true)
end

function this.Bulldozer:erase()
  self:set_build_mode(false)
end

function this.Bulldozer:set_build_mode(flag)
  if flag then
    self.build_node_name = 'default:stone'
  else
    self.build_node_name = nil
  end
  print("set_build_mode "..tostring(self.build_node_name))
end

function this.Bulldozer:is_build_mode() 
  return self.build_node_name and  self.build_node_name ~= ''
end

function this.Bulldozer:process_node(pos) 
  --print("process_node(pos="..minetest.pos_to_string(pos))
  table.insert(self.queue, {
    pos = wr_utils.copy_table(pos),
    build_mode = self:is_build_mode() 
  })
end

function this.Bulldozer:_get_new_node(context) 
  return {name = self.build_node_name}
end

function this.Bulldozer:_grab_node(pos, node)
  if not node then
      --print("_grab_node: no node at "..minetest.pos_to_string(pos))
      return nil
  end
  local drawtype = wr_utils.get_nodedef_field(node.name, "drawtype")
  if drawtype == "normal" then
      self.inv:add_item("main", node)
      self.env:remove_node(pos)
      return pos
  end
  return nil
end

function this.Bulldozer:_put_node(pos, node)
  if node then --first grab existed node
    self:_grab_node(pos, node)
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
  if (pos.x == self.initial_pos.x and pos.y == self.initial_pos.y and pos.z == self.initial_pos.z)  --skip bulldozer node position
      then 
    return nil
  end
  --print("Bulldozer:on_step(pos="..minetest.pos_to_string(pos))
  local node = self.env:get_node_or_nil(pos)
  local result = nil;
  if task.build_mode then
    result = self:_put_node(pos, node)
  else
    result = self:_grab_node(pos, node)
  end
  return result
end

return this

