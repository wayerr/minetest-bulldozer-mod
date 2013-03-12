load_module("wr_utils")

local this = {}

--make axes map
local axes_table = {'x','y','z'}
do
  local copy_axes = wr_utils.copy_table(axes_table);
  for k,v in ipairs(copy_axes) do
    --make x={y,z} tables
    axes_table[v] = wr_utils.copy_table(axes_table);
    table.remove(axes_table[v], k)
  end
end

function this.pos(x, y, z) 
  return {x=x, y=y, z=z}
end

this.Bulldozer = {}
local Bulldozer_mt = {__index = this.Bulldozer}

function this.Bulldozer.new(pos) 
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
  return setmetatable(t, Bulldozer_mt)
end

function this.Bulldozer:processNode(pos) 
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

function this.Bulldozer:jump(x, y, z)
  local p = self.pos
  print("jump to "..minetest.pos_to_string(p))
  p.x = p.x + x
  p.y = p.y + y
  p.z = p.z + z
end

function this.Bulldozer:cube(r)
  self:cuboid(r, r, r)
end

function this.Bulldozer:cuboid(x,y,z)
  local p = wr_utils.copy_table(self.pos)
  local halfx = math.floor(x/2)
  local halfy = math.floor(y/2) 
  local halfz = math.floor(z/2) 
  for i = -halfx, halfx do
    for j = -halfz, halfz do
      for k = -halfy, halfy do
        p.x = self.pos.x + i
        p.z = self.pos.z + j
        p.y = self.pos.y + k
        self:processNode(p)
      end
    end
  end
end

function this.Bulldozer:circle(rx)
  local p = wr_utils.copy_table(self.pos)
  local rx2 = rx*rx;
  local endx = math.floor(rx/math.sqrt(2))
  for x = 0, endx do
    local x2 = x*x
    local y = math.sqrt(rx2 - x2)
    local fx = math.floor(x)
    local fy = math.floor(y)
    p.y = self.pos.y
    -- need refactoring!
    p.x = self.pos.x + fx
    p.z = self.pos.z + fy
    self:processNode(p)
    p.x = self.pos.x - fx
    p.z = self.pos.z + fy
    self:processNode(p)
    p.x = self.pos.x + fx
    p.z = self.pos.z - fy
    self:processNode(p)
    p.x = self.pos.x - fx
    p.z = self.pos.z - fy
    self:processNode(p)
    p.x = self.pos.x + fy
    p.z = self.pos.z + fx
    self:processNode(p)
    p.x = self.pos.x - fy
    p.z = self.pos.z + fx
    self:processNode(p)
    p.x = self.pos.x + fy
    p.z = self.pos.z - fx
    self:processNode(p)
    p.x = self.pos.x - fy
    p.z = self.pos.z - fx
    self:processNode(p)
  end
end

function this.Bulldozer:sphere(r)
  self:spheroid(r, r, r)
end

function this.Bulldozer:spheroid(rx, ry, rz)
  local p = wr_utils.copy_table(self.pos)
  local rx2 = rx*rx
  local ry2 = ry*ry
  local rz2 = rz*rz
  for x = -rx, rx do
    local x2 = x*x
    for y = -ry, ry do
      local y2 = y*y
      for z = -rz, rz do
        local z2 = z*z
        if x2/rx2 + y2/ry2 + z2/rz2 <= 1 then
          p.x = self.pos.x + x
          p.y = self.pos.y + y
          p.z = self.pos.z + z
          self:processNode(p)
        end
      end
    end  
  end
end

function this.Bulldozer:cylinder(axis, r, h)
  local p = wr_utils.copy_table(self.pos)
  local r2 = r*r
  local axes = axes_table[axis]
  local hstart = math.min(0, h)
  local hend = math.max(0, h)
  for x = -r, r do
    local x2 = x*x
    for y = -r, r do
      local y2 = y*y
      if x2 + y2 <= r2 then
        --may be 'for' statement?
        p[axes[1]] = self.pos[axes[1]] + x
        p[axes[2]] = self.pos[axes[2]] + y
        for hi = hstart, hend do
          p[axis] = self.pos[axis] + hi
          self:processNode(p)
        end
      end
    end
  end
end

return this

