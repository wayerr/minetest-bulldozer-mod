do
  local description = "Automation bot Buldozzer"
  local name = "buldozzer:buldozzer"
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
	  end,
	  on_construct = function(pos)
		  local meta = minetest.env:get_meta(pos)
		  meta:set_string("formspec",
				  "size[8,11]"..
				  "list[current_name;main;0,0;8,4;]"..
				  "list[current_player;main;0,5;8,4;]"..
		          "textarea[0.3,9.3;7,2;command;Command;]"..
				  "button[7,9.2;1,1;do_commnad;Save]")
		  meta:set_string("infotext", description)
		  local inv = meta:get_inventory()
		  inv:set_size("main", 8*4)
	  end,
	  can_dig = function(pos,player)
		  local meta = minetest.env:get_meta(pos);
		  local inv = meta:get_inventory()
		  return inv:is_empty("main")
	  end,
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
end
