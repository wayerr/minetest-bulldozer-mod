local this = {}

function this.copy_table(t)
    local u = { }
    for k, v in pairs(t) do u[k] = v end
    return setmetatable(u, getmetatable(t))
end

function this.print_table(table)
  for k,v in pairs(table) do 
    print(k.."="..tostring(v)) 
  end
end 

function this.get_nodedef_field(nodename, fieldname)
    if not minetest.registered_nodes[nodename] then
        return nil
    end
    return minetest.registered_nodes[nodename][fieldname]
end

return this

  