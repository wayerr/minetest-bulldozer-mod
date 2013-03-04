load_module("wr_utils")

local this = {}

function this.pos(x, y, z) 
  return {x=x, y=y, z=z}
end

this.Router = {}
local Router_mt = {__index = this.Router}

function this.Router.new(pos) 
  return setmetatable({pos={
      x=pos.x,
      y=pos.y,
      z=pos.z}
    }, Router_mt)
end

function this.Router.jump(pos)
  print("jump")
end

function this.Router.move(pos)
  print("move")
end

function this.Router.rect(pos, r)
  print("rect(r="..tostring(r))
end

return this

