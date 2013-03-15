load_module("wr_utils")
load_module("wr_router")

local this = {}

this.Bulldozer = {}
local Bulldozer_mt = {__index = this.Bulldozer}
function this.Bulldozer.new(pos) 
  local env = minetest.env
  local meta = env:get_meta(pos)
  t = wr_utils.copy_table(this.Bulldozer)
  t.env = env
  t.meta = meta
  t.inv = meta:get_inventory()
  setmetatable(t, Bulldozer_mt)
  local mt = {__index =  wr_router.Router}
  setmetatable(t, mt)
  t:init(pos)
  return t
end

function this.Bulldozer:processNode(pos) 
  local processed_node = self.env:get_node_or_nil(pos)
  if not processed_node then
      --print("no node at "..minetest.pos_to_string(pos))
      return
  end
  local drawtype = wr_utils.get_nodedef_field(processed_node.name, "drawtype")
  if drawtype == "normal" and not (pos.x == self.initial_pos.x and pos.y == self.initial_pos.y and pos.z == self.initial_pos.z) then
      
      self.inv:add_item("main", processed_node)
      self.env:remove_node(pos)
  end
end

return this

