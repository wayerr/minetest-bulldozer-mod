do
  local mod_name = "bulldozer"
  local mod_path = minetest.get_modpath(mod_name);
  
  function load_module(name) 
    if _G.name then
      return
    end
    local module = dofile(mod_path.."/"..name..".lua")
    rawset(_G, name, module)
  end

  load_module("wr_utils")
  load_module("wr_bulldozer")
  
  local description = "Automation bot Bulldozer"
  local bulldozer_node_name = mod_name..":bulldozer"
  local bulldozer_entity_name = mod_name..":bulldozer_entity"
  minetest.register_node(bulldozer_node_name, {
	  tiles = {"bulldozer_py.png","bulldozer_my.png","bulldozer_px.png","bulldozer_mx.png","bulldozer_pz.png","bulldozer_mz.png"},
	  description = description,
	  groups = {snappy=1,choppy=2,oddly_breakable_by_hand=2},
	  on_punch = function(pos, node, puncher) 
		  local meta = minetest.env:get_meta(pos)
		  local command = meta:get_string("command")
		  if not command or command == "" then
			  return
		  end
		  print("Start command: "..command)
          minetest.env:add_entity(pos, bulldozer_entity_name)
		  --digg(pos, node, command)
	  end,
	  on_construct = function(pos)
		  local meta = minetest.env:get_meta(pos)
          meta:set_string("command", "r:jump(0, -1, 0) r:sphere(5)")
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
      on_receive_fields = function(pos, formname, fields, sender)
		local meta = minetest.env:get_meta(pos)
		meta:set_string("command", fields.command)
	  end,
  })

  minetest.register_craft({
	output = '"'..bulldozer_node_name..'" 2',
	recipe = {
	  {'default:wood', 'default:wood', ''},
	  {'default:wood', 'default:wood', ''},
	  {'', '', ''},
	}
  })
  
  minetest.register_entity(bulldozer_entity_name, {
    initial_properties = {
      hp_max = 1,
      physical = true,
      collisionbox = {-0.17,-0.17,-0.17, 0.17,0.17,0.17},
      visual = "wielditem",
      visual_size = {x=0.20, y=0.20},
      textures = {bulldozer_node_name},
      is_visible = true,
    },

    itemstring = '',
    physical_state = true,

    get_staticdata = function(self)
      --return self.itemstring
      return minetest.serialize({
        itemstring = self.itemstring,
        always_collect = self.always_collect,
      })
    end,

    on_activate = function(self, staticdata)
      if string.sub(staticdata, 1, string.len("return")) == "return" then
        local data = minetest.deserialize(staticdata)
        if data and type(data) == "table" then
          self.itemstring = data.itemstring
          self.always_collect = data.always_collect
        end
      else
        self.itemstring = staticdata
      end
      self.object:set_armor_groups({immortal=1})
      self.object:setvelocity({x=0, y=2, z=0})
      self.object:setacceleration({x=0, y=-10, z=0})
      
    end,

    on_step = function(self, dtime)
      local p = self.object:getpos()
      
    end,

    on_punch = function(self, hitter)
      if self.itemstring ~= '' then
        local left = hitter:get_inventory():add_item("main", self.itemstring)
        if not left:is_empty() then
          self.itemstring = left:to_string()
          return
        end
      end
      self.object:remove()
    end,
  })
  
  function digg(initial_pos, node, command)
      local env = minetest.env
      local meta = env:get_meta(initial_pos)
	  local inv = meta:get_inventory()
	  local pos = wr_utils.copy_table(initial_pos)
      do
        local r = wr_bulldozer.Bulldozer.new(pos);
        local command_func = loadstring(command)
        local context = {
          r = r 
        }
        setmetatable(context, {__index = _G})
        setfenv(command_func, context)
        command_func()
      end 
  end
end
