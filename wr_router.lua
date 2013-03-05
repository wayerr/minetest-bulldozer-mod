load_module("wr_utils")

local this = {}

function this.pos(x, y, z) 
  return {x=x, y=y, z=z}
end

this.Router = {}
local Router_mt = {__index = this.Router}

function this.Router.new(pos) 
  local env = minetest.env
  local meta = env:get_meta(pos)
  t = {
    initial_pos = wr_utils.copy_table(pos),
    pos = wr_utils.copy_table(pos),
    env = env,
    meta = meta,
    inv = meta:get_inventory()
  }
  print("new router with pos="..minetest.pos_to_string(t.pos))
  return setmetatable(t, Router_mt)
end

function this.Router:processNode(pos) 
  local processed_node = self.env:get_node_or_nil(pos)
  if not processed_node then
      print("no node at "..minetest.pos_to_string(pos))
      return
  end
  local drawtype = wr_utils.get_nodedef_field(processed_node.name, "drawtype")
  if drawtype == "normal" and not (pos.x == self.initial_pos.x and pos.y == self.initial_pos.y and pos.z == self.initial_pos.z) then
      self.inv:add_item("main", processed_node)
      self.env:remove_node(pos)
  end
end

function this.Router:jump(x, y, z)
  local p = self.pos
  print("jump to "..minetest.pos_to_string(p))
  p.x = p.x + x
  p.y = p.y + y
  p.z = p.z + z
end

function this.Router:move(pos)
  print("move")
end

function this.Router:rect(r)
  local p = wr_utils.copy_table(self.pos)
  local halfr = math.floor(r/2) 
  for i = -halfr, halfr do
    for j = -halfr, halfr do
      p.x = self.pos.x + i
      p.z = self.pos.z + j
      self:processNode(p)
    end
  end
end

function this.Router:cube(r)
  local p = wr_utils.copy_table(self.pos)
  local halfr = math.floor(r/2) 
  for i = -halfr, halfr do
    for j = -halfr, halfr do
      for k = -halfr, halfr do
        p.x = self.pos.x + i
        p.z = self.pos.z + j
        p.y = self.pos.y + k
        self:processNode(p)
      end
    end
  end
end

return this

