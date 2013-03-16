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

function this.round(p) 
  return {
    x=math.floor(p.x + .5), 
    y=math.floor(p.y + .5), 
    z=math.floor(p.z + .5)
  }
end

function this.add(pos, dx, dy, dz) 
  return {
    x=pos.x + dx, 
    y=pos.y + dy, 
    z=pos.z + dz
  }
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
  self._path = {}
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

function this.Router:extend(axis, lenght)
  local path = self._path
  if not path or #path == 0 then
    return
  end
  local path_len = #path
  for i = 1, lenght do
    for path_idx = 1, path_len do
      local exentry = wr_utils.copy_table(path[path_idx])
      exentry[axis] = exentry[axis] + i
      table.insert(path, exentry)
    end
  end
end

function this.Router:path(...)
  local diff = {}
  for i,v in ipairs(arg) do
    local axis = (i-1) % 3
    if axis == 0 then
      diff.dx = v
    elseif axis == 1 then
      diff.dy = v
    else
      diff.dz = v
      self:line(diff.dx, diff.dy, diff.dz)
    end
  end
end

function this.Router:line(dx, dy, dz)
  local p = wr_utils.copy_table(self.pos)
  -- used DDA algorithm
  local adx = math.abs(dx)
  local ady = math.abs(dy)
  local adz = math.abs(dz)
  local dmax = math.max(adx,math.max(ady, adz))
  if dmax == 0 then
    return
  end
  local xstep = dx/dmax
  local ystep = dy/dmax
  local zstep = dz/dmax
  for d = 0, dmax do
    p.x = p.x + xstep
    p.y = p.y + ystep
    p.z = p.z + zstep
    local pos = this.round(p)
    --print("line pos="..minetest.pos_to_string(pos))
    table.insert(self._path, pos)
  end
  self.pos = p;
end

function this.Router:draw()
  while true do
    local p = table.remove(self._path, 1)
    if not p then
      break
    end
    self:process_node(p)
  end
end

function this.Router:cube(r)
  self:cuboid(r, r, r)
end

function this.Router:cuboid(x,y,z)
  local p = wr_utils.copy_table(self.pos)
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