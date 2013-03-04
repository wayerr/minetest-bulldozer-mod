load_module("wr_utils")

local this = {}

function this.pos(x, y, z) 
  return {x=x, y=y, z=z}
end

this.Router = {}
local Router_mt = {__index:Router}

function Router.new(pos) 
  return setmetatable({pos={
      x=pos.x,
      y=pos.y,
      z=pos.z,
    }, Router_mt)
end

function Router.jump(pos)
  self.x
end

return this

