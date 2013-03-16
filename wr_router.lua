load_module("wr_utils")

local this = {}

--make axes map
local axes_table = {'x','z','y'}
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

this.Router = {}
local Router_mt = {__index = this.Router}
this.Router.mt = Router_mt

function this.Router.new() 
  t = {}
  return setmetatable(t, Router_mt)
end

function this.Router:init(pos) 
  self.initial_pos = wr_utils.copy_table(pos)
  self.pos = wr_utils.copy_table(pos)
end

function this.Router:_move(cursor_pos, axes, i, j)
  cursor_pos[axes[1]] = self.pos[axes[1]] + i
  cursor_pos[axes[2]] = self.pos[axes[2]] + j
end

function this.Router:jump(x, y, z)
  local p = self.pos
  p.x = p.x + x
  p.y = p.y + y
  p.z = p.z + z
end

function this.Router:cube(r)
  self:cuboid(r, r, r)
end

function this.Router:cuboid(x,y,z)
  local p = wr_utils.copy_table(self.pos)
  local halfx = math.floor(x/2)
  local halfy = math.floor(y/2) 
  local halfz = math.floor(z/2) 
  for k = 0, y do
    p.y = self.pos.y + k
    for i = 0, x do
      p.x = self.pos.x + i
      for j = 0, z do
        p.z = self.pos.z + j
        self:process_node(p)
      end
    end
  end
end

function this.Router:circle(axis, r)
  local p = wr_utils.copy_table(self.pos)
  local r2 = r*r;
  local e = math.floor(r/math.sqrt(2))
  local axes = axes_table[axis]
  p[axis] = self.pos[axis]
  for i = 0, e do
    local i2 = i*i
    local j = math.sqrt(r2 - i2)
    local fi = math.floor(i)
    local fj = math.floor(j)
    
    self:_move(p, axes,  fi,  fj)
    self:process_node(p)
    self:_move(p, axes, -fi,  fj)
    self:process_node(p)
    self:_move(p, axes,  fi, -fj)
    self:process_node(p)
    self:_move(p, axes, -fi, -fj)
    self:process_node(p)
    self:_move(p, axes,  fj,  fi)
    self:process_node(p)
    self:_move(p, axes, -fj,  fi)
    self:process_node(p)
    self:_move(p, axes,  fj, -fi)
    self:process_node(p)
    self:_move(p, axes, -fj, -fi)
    self:process_node(p)
  end
end

function this.Router:square(axis, len)
  self:rect(axis, len, len)
end

function this.Router:rect(axis, width, height)
  local p = wr_utils.copy_table(self.pos)
  local axes = axes_table[axis]
  p[axis] = self.pos[axis]
  local full_len = (width + height) * 2 - 1
  local i = 0
  local j = 0
  for counter = 0, full_len do
    if counter < width then
      i = i + 1
    elseif counter < width + height then
      j = j + 1
    elseif counter < width*2 + height then
      i = i - 1
    else
      j = j - 1
    end
    self:_move(p, axes, i, j)
    self:process_node(p)
  end
end

function this.Router:sphere(r)
  self:spheroid(r, r, r)
end

function this.Router:spheroid(rx, ry, rz)
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
          self:process_node(p)
        end
      end
    end  
  end
end

function this.Router:cylinder(axis, r, h)
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
        self:_move(p, axes,  x,  y)
        for hi = hstart, hend do
          p[axis] = self.pos[axis] + hi
          self:process_node(p)
        end
      end
    end
  end
end

return this