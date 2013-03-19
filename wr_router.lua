load_module("wr_utils")

local this = {}

--make axes map
this.axes_table = {'x','z','y'}
do
  local copy_axes = wr_utils.copy_table(this.axes_table);
  for k,v in ipairs(copy_axes) do
    --make x={y,z} tables
    this.axes_table[v] = wr_utils.copy_table(this.axes_table);
    table.remove(this.axes_table[v], k)
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
  pos.x=pos.x + dx
  pos.y=pos.y + dy
  pos.z=pos.z + dz
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
  self._path = {}
end

function this.Router:_move(base_pos, cursor_pos, axes, i, j)
  cursor_pos[axes[1]] = base_pos[axes[1]] + i
  cursor_pos[axes[2]] = base_pos[axes[2]] + j
end

function this.Router:jump(x, y, z)
  this.add(self.bsite.cursor, x, y, z)
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
      self:process_node(exentry)
    end
  end
end

function this.Router:path(...)
  local first_v
  for i,v in ipairs(arg) do
    local axis = (i-1) % 2
    if axis == 0 then
      first_v = v
    else
      self:line(first_v, v)
    end
  end
end

function this.Router:line(di, dj)
  local cursor = self.bsite.cursor
  local p = wr_utils.copy_table(cursor)
  -- used DDA algorithm
  local dmax = math.max( math.abs(di), math.abs(dj))
  if dmax == 0 then
    return
  end
  local istep = di/dmax
  local jstep = dj/dmax
  for d = 0, dmax do --TODO implement path cursor
    p.x = p.x + istep
    p.z = p.z + jstep
    local pos = this.round(p)
    --print("line pos="..minetest.pos_to_string(pos))
    table.insert(self._path, pos)
  end
  self.bsite.cursor = p
end

function this.Router:cube(r)
  self:cuboid(r, r, r)
end

function this.Router:cuboid(x,y,z)
  local cursor = self.bsite.cursor
  local p = wr_utils.copy_table(cursor)
  for k = 1, y do
    p.y = cursor.y + k - 1
    for i = 1, x do
      p.x = cursor.x + i - 1
      for j = 1, z do
        p.z = cursor.z + j - 1
        self:process_node(p)
      end
    end
  end
end

function this.Router:circle(axis, r)
  local cursor = self.bsite.cursor
  local p = wr_utils.copy_table(cursor)
  local r2 = r*r;
  local e = math.ceil(r/math.sqrt(2))
  local axes = this.axes_table[axis]
  p[axis] = cursor[axis]
  for i = 0, e do
    local i2 = i*i
    local j = math.sqrt(r2 - i2)
    local fi = math.ceil(i)
    local fj = math.ceil(j)
    
    self:_move(cursor, p, axes,  fi,  fj)
    self:process_node(p)
    self:_move(cursor, p, axes, -fi,  fj)
    self:process_node(p)
    self:_move(cursor, p, axes,  fi, -fj)
    self:process_node(p)
    self:_move(cursor, p, axes, -fi, -fj)
    self:process_node(p)
    self:_move(cursor, p, axes,  fj,  fi)
    self:process_node(p)
    self:_move(cursor, p, axes, -fj,  fi)
    self:process_node(p)
    self:_move(cursor, p, axes,  fj, -fi)
    self:process_node(p)
    self:_move(cursor, p, axes, -fj, -fi)
    self:process_node(p)
  end
end

function this.Router:square(axis, len)
  self:rect(axis, len, len)
end

function this.Router:rect(axis, width, height)
  local cursor = self.bsite.cursor
  local p = wr_utils.copy_table(cursor)
  local axes = this.axes_table[axis]
  p[axis] = cursor[axis]
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
    self:_move(cursor, p, axes, i, j)
    self:process_node(p)
  end
end

function this.Router:sphere(r)
  self:spheroid(r, r, r)
end

function this.Router:spheroid(rx, ry, rz)
  local cursor = self.bsite.cursor
  local p = wr_utils.copy_table(cursor)
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
          p.x = cursor.x + x
          p.y = cursor.y + y
          p.z = cursor.z + z
          self:process_node(p)
        end
      end
    end  
  end
end

function this.Router:cylinder(axis, r, h)
  local cursor = self.bsite.cursor
  local p = wr_utils.copy_table(cursor)
  local r2 = r*r
  local axes = this.axes_table[axis]
  local hstart = math.min(0, h)
  local hend = math.max(0, h)
  for x = -r, r do
    local x2 = x*x
    for y = -r, r do
      local y2 = y*y
      if x2 + y2 <= r2 then
        self:_move(cursor, p, axes,  x,  y)
        for hi = hstart, hend do
          p[axis] = cursor[axis] + hi
          self:process_node(p)
        end
      end
    end
  end
end

return this