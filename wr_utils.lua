local this = {}

function this.copy_table(t)
    local u = { }
    for k, v in pairs(t) do u[k] = v end
    return setmetatable(u, getmetatable(t))
end

function this.print_table(table)
  for k,v in pairs(table) do 
    print(k.."=",tostring(v)) 
  end
end 

return this

  