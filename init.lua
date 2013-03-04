do
  local mod_name = "buldozzer"
  local mod_path = minetest.get_modpath(mod_name);
  
  function load_module(name) 
    if _G.name then
      return
    end
    local module = dofile(mod_path.."/"..name..".lua")
    rawset(_G, name, module)
  end

  load_module("wr_utils")
  load_module("wr_router")
  
  local description = "Automation bot Buldozzer"
  local name = mod_name..":buldozzer"
  minetest.register_node(name, {
	  tiles = {"buldozzer.png"},
	  description = description,
	  groups = {snappy=1,choppy=2,oddly_breakable_by_hand=2,flammable=3},
	  on_punch = function(pos, node, puncher) 
		  local meta = minetest.env:get_meta(pos)
		  local command = meta:get_string("command")
		  if not command or command == "" then
			  return
		  end
		  print("Start command: "..command)
		  digg(pos, node, command)
	  end,
	  on_construct = function(pos)
		  local meta = minetest.env:get_meta(pos)
          meta:set_string("command", "move(-1,0,0) rect(10)")
		  meta:set_string("formspec",
				  "size[8,11]"..
				  "list[current_name;main;0,0;8,4;]"..
				  "list[current_player;main;0,5;8,4;]"..
		          "textarea[0.3,9.3;7,2;command;Command;${command}]"..
				  "button[7,9.2;1,1;do_commnad;Save]")
		  meta:set_string("infotext", description)
		  local inv = meta:get_inventory()
		  inv:set_size("main", 8*4)
	  end,
	  --[[can_dig = function(pos,player)
		  local meta = minetest.env:get_meta(pos);
		  local inv = meta:get_inventory()
		  return inv:is_empty("main")
	  end,]]--
	  on_metadata_inventory_move = function(pos, from_list, from_index, to_list, to_index, count, player)
		  minetest.log("action", player:get_player_name()..
				  " moves stuff in chest at "..minetest.pos_to_string(pos))
	  end,
	  on_metadata_inventory_put = function(pos, listname, index, stack, player)
		  minetest.log("action", player:get_player_name()..
				  " moves stuff to chest at "..minetest.pos_to_string(pos))
	  end,
	  on_metadata_inventory_take = function(pos, listname, index, stack, player)
		  minetest.log("action", player:get_player_name()..
				  " takes stuff from chest at "..minetest.pos_to_string(pos))
	  end,
      on_receive_fields = function(pos, formname, fields, sender)
		local meta = minetest.env:get_meta(pos)
		meta:set_string("command", fields.command)
	  end,
  })

  minetest.register_craft({
	output = '"'..name..'" 2',
	recipe = {
	  {'default:wood', 'default:wood', ''},
	  {'default:wood', 'default:wood', ''},
	  {'', '', ''},
	}
  })
  
  function get_nodedef_field(nodename, fieldname)
      if not minetest.registered_nodes[nodename] then
          return nil
      end
      return minetest.registered_nodes[nodename][fieldname]
  end
  
  function digg(initial_pos, node, command)
      local env = minetest.env
      local meta = env:get_meta(initial_pos)
	  local inv = meta:get_inventory()
	  local pos = wr_utils.copy_table(initial_pos)
      local command_func = loadstring(command)
      command_func()
      --[[
      local step = 1
      for command in commands do
	      print("On step="..step.." do command "..command)
          local axis = string.sub(command, 1, 1)
          local direction = string.sub(command, 2, 2)
          local count_str = string.sub(command, 3)
          local count = math.abs(tonumber(count_str))
          local increment
          print("dir="..direction)
          if direction == "-" then 
            increment = -1 
          else 
            increment = 1 
          end
          while count > 0 do
              pos[axis] = pos[axis] + increment;
              local processed_node = env:get_node_or_nil(pos)
              if not processed_node then
                  print("no node at "..minetest.pos_to_string(pos))
                  break
              end
              local drawtype = get_nodedef_field(processed_node.name, "drawtype")
              if drawtype == "normal" and not (pos.x == initial_pos.x and pos.y == initial_pos.y and pos.z == initial_pos.z) then
                  inv:add_item("main", processed_node)
                  env:remove_node(pos)
              end
              count = count - 1
          end
		  step = step + 1
      end]]--
  end
end
