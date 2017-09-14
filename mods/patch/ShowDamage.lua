local mod_name = "ShowPlayerDamage"
--[[ 
	Show player damage
		- Show floating damage numbers over unit heads.
		
	Author: grasmann
--]]

local oi = OptionsInjector

ShowPlayerDamage = {

	SETTINGS = {
		FLTNRS = {
			["save"] = "cb_show_damage_floating_numbers",
			["widget_type"] = "stepper",
			["text"] = "Floating Numbers",
			["tooltip"] = "Show Floating Numbers\n" ..
				"Toggle floating numbers on / off.\n\n" ..
				"Floating numbers will appear over the heads of damaged skaven.",
			["value_type"] = "boolean",
			["options"] = {
				{text = "Off", value = false},
				{text = "On", value = true}
			},
			["default"] = 1, -- Default first option is enabled. In this case Off
			["hide_options"] = {
				{
					false,
					mode = "hide",
					options = {
						"cb_show_damage_floating_numbers_source",
					}
				},
				{
					true,
					mode = "show",
					options = {
						"cb_show_damage_floating_numbers_source",
					}
				},
			},
		},
		FLTNRS_SOURCE = {
			["save"] = "cb_show_damage_floating_numbers_source",
			["widget_type"] = "dropdown",
			["text"] = "Source",
			["tooltip"] = "Show Player Damage Source\n" ..
				"Switch source for the player damage output.\n\n" ..
				"-- OFF --\nNo messages will be posted.\n\n" ..
				"-- ME ONLY --\nOnly show damage messages for yourself.\n\n" ..
				"-- ALL --\nShows damage messages for all players, including bots.\n\n" ..
				"-- CUSTOM --\nChoose the players you want to see damage messages of.\n\n",
			["value_type"] = "number",
			["options"] = {
				{text = "Me Only", value = 1},
				{text = "All", value = 2},
				{text = "Custom", value = 3},
			},
			["default"] = 1, -- Default first option is enabled. In this case "Me Only"
			["hide_options"] = {
				{
					1,
					mode = "hide",
					options = {
						"cb_show_damage_floating_numbers_dyn_player_1",
						"cb_show_damage_floating_numbers_dyn_player_2",
						"cb_show_damage_floating_numbers_dyn_player_3",
						"cb_show_damage_floating_numbers_dyn_player_4",
					}
				},
				{
					2,
					mode = "hide",
					options = {
						"cb_show_damage_floating_numbers_dyn_player_1",
						"cb_show_damage_floating_numbers_dyn_player_2",
						"cb_show_damage_floating_numbers_dyn_player_3",
						"cb_show_damage_floating_numbers_dyn_player_4",
					}
				},
				{
					3,
					mode = "show",
					options = {
						"cb_show_damage_floating_numbers_dyn_player_1",
						"cb_show_damage_floating_numbers_dyn_player_2",
						"cb_show_damage_floating_numbers_dyn_player_3",
						"cb_show_damage_floating_numbers_dyn_player_4",
					}
				},
			},
		},
		FLTNRS_CHAR = "cb_show_damage_floating_numbers_dyn_player_",
		FLTNRS_CHAR1 = {
			["save"] = "cb_show_damage_floating_numbers_dyn_player_1",
			["widget_type"] = "checkbox",
			["text"] = "cb_show_damage_floating_numbers_dyn_player_1",
			["default"] = false,
			["dynamic"] = true,
		},
		FLTNRS_CHAR2 = {
			["save"] = "cb_show_damage_floating_numbers_dyn_player_2",
			["widget_type"] = "checkbox",
			["text"] = "cb_show_damage_floating_numbers_dyn_player_2",
			["default"] = false,
			["dynamic"] = true,
		},
		FLTNRS_CHAR3 = {
			["save"] = "cb_show_damage_floating_numbers_dyn_player_3",
			["widget_type"] = "checkbox",
			["text"] = "cb_show_damage_floating_numbers_dyn_player_3",
			["default"] = false,
			["dynamic"] = true,
		},
		FLTNRS_CHAR4 = {
			["save"] = "cb_show_damage_floating_numbers_dyn_player_4",
			["widget_type"] = "checkbox",
			["text"] = "cb_show_damage_floating_numbers_dyn_player_4",
			["default"] = false,
			["dynamic"] = true,
		},
		HK_TOGGLE_FLOAT = {
			["save"] = "cb_show_damage_hotkey_float_toggle",
			["widget_type"] = "keybind",
			["text"] = "Toggle Floating Numbers On / Off",
			["default"] = {
				"f",
				oi.key_modifiers.CTRL_ALT,
			},
			["exec"] = {"patch/action", "floating_numbers"},
		},
	},

	t = 0,

	NAME_LENGTH = 20,
	
	floating = {
		corpses = {},
		units = {},
		delete = {},
		fade_time = 2,
		definition = {
			position = nil,
			damage = 0,
			color = nil,
			timer = 0,
		},
	},
	
	players = {},
	
	enemies = {
		specials = {
			"skaven_storm_vermin",
			"skaven_storm_vermin_commander",
			"skaven_storm_vermin_champion",
			"skaven_loot_rat",
			"skaven_rat_ogre",
			"skaven_gutter_runner",
			"skaven_poison_wind_globadier",
			"skaven_pack_master",
			"skaven_ratling_gunner",
			"skaven_grey_seer",
		},
		breed_names = {
			skaven_slave = "Slave Rat",
			skaven_storm_vermin = "Stormvermin",
			skaven_storm_vermin_commander = "Stormvermin",
			skaven_storm_vermin_champion = "Stormvermin Champion",
			skaven_clan_rat = "Clan Rat",
			skaven_loot_rat = "Loot Rat",
			skaven_rat_ogre = "Rat Ogre",
			skaven_gutter_runner = "Gutter Runner",
			skaven_poison_wind_globadier = "Globadier",
			skaven_pack_master = "Pack Master",
			skaven_ratling_gunner = "Ratling Gunner",
			skaven_grey_seer = "Grey Seer",
			critter_pig = "Pig",
			critter_rat = "Rat",
		},
		hit_zones = {
			full = "",
			head = "Head",
			right_arm = "R. Arm",
			left_arm = "L. Arm",
			torso = "Torso",
			right_leg = "R. Leg",
			left_leg = "L. Leg",
			tail = "Tail",
			neck = "Neck",
		},
		offsets = {
			default = 1,
			skaven_slave = 1,
			skaven_clan_rat = 1,
			skaven_storm_vermin = 1,
			skaven_storm_vermin_commander = 1,
			skaven_storm_vermin_champion = 1,
			skaven_gutter_runner = 1,
			skaven_ratling_gunner = 1,
			skaven_pack_master = 1,
			skaven_poison_wind_globadier = 1,
			skaven_rat_ogre = 2,
			skaven_loot_rat = 1,
			skaven_grey_seer = 2,
			critter_pig = 0.5,
			critter_rat = 0,
		},
	},
	
	strings = {},
	console = {},
	
}
local me = ShowPlayerDamage

local get = function(data)
	return Application.user_setting(data.save)
end
local set = Application.set_user_setting
local save = Application.save_user_settings

-- ####################################################################################################################
-- ##### Options ######################################################################################################
-- ####################################################################################################################
--[[
	Create options
--]]
ShowPlayerDamage.create_options = function()
	Mods.option_menu:add_group("show_damage", "Show Player Damage")
	
	Mods.option_menu:add_item("show_damage", me.SETTINGS.FLTNRS, true)
	Mods.option_menu:add_item("show_damage", me.SETTINGS.FLTNRS_SOURCE)
	Mods.option_menu:add_item("show_damage", me.SETTINGS.FLTNRS_CHAR1)
	Mods.option_menu:add_item("show_damage", me.SETTINGS.FLTNRS_CHAR2)
	Mods.option_menu:add_item("show_damage", me.SETTINGS.FLTNRS_CHAR3)
	Mods.option_menu:add_item("show_damage", me.SETTINGS.FLTNRS_CHAR4)

	Mods.option_menu:add_item("show_damage", me.SETTINGS.HK_TOGGLE_FLOAT, true)
end

-- ####################################################################################################################
-- ##### Players ######################################################################################################
-- ####################################################################################################################
--[[
	Get a generic character name
--]]
ShowPlayerDamage.players.unit_name = function(unit_name)
	if unit_name == "empire_soldier" then
		return "Empire Soldier"
	elseif unit_name == "witch_hunter" then
		return "Witch Hunter"
	elseif unit_name == "bright_wizard" then
		return "Bright Wizard"
	elseif unit_name == "dwarf_ranger" then
		return "Dwarf Ranger"
	elseif unit_name == "wood_elf" then
		return "Waywatcher"
	end
	return nil
end
--[[
	Check if unit is player unit
--]]
ShowPlayerDamage.players.is_player_unit = function(unit)
	return DamageUtils.is_player_unit(unit)
end
--[[
	Get player from player unit
--]]
ShowPlayerDamage.players.from_player_unit = function(player_unit)
	local player_manager = Managers.player
	local players = player_manager:human_and_bot_players()
	for _, player in pairs(players) do
		if player.player_unit == player_unit then
			return player
		end
	end
	return nil
end
--[[
	Get player name from index
--]]
ShowPlayerDamage.players.name_from_index = function(index)
	local name = "N/A"
	local player_manager = Managers.player
	local players = player_manager:human_and_bot_players()
	local i = 1
	for _, player in pairs(players) do
		if i == index then
			return me.strings.check({player._cached_name, me.players.unit_name(player.player_name)})		
		end
		i = i + 1
	end
	return name
end

-- ####################################################################################################################
-- ##### Strings ######################################################################################################
-- ####################################################################################################################
--[[
	Shorten string
--]]
ShowPlayerDamage.strings.shorten = function(str)
	if string.len(str) >= me.NAME_LENGTH then
		return string.sub(str, 1, me.NAME_LENGTH)
	end
	return str
end
--[[
	Check if objects are strings
	Returns first string
--]]
ShowPlayerDamage.strings.check = function(strings, default)
	if type(strings) == "table" then
		for _, str in pairs(strings) do
			if type(str) == "string" and Utf8.valid(str) then
				return me.strings.shorten(str)
			end
		end
	elseif type(strings) == "string" and Utf8.valid(strings) then
		return me.strings.shorten(strings)
	end
	if type(default) == "string" and Utf8.valid(default) then
		return me.strings.shorten(default)
	end
	return "N/A"
end

-- ####################################################################################################################
-- ##### Floating damage numbers ######################################################################################
-- ####################################################################################################################
--[[
	Floating number fonts
--]]
ShowPlayerDamage.floating.fonts = function(size)
	-- Return font_group, font_path, font_size
	if size == nil then size = 20 end
	if size > 32 then
		return "hell_shark_arial", "materials/fonts/gw_body_64", size
	else
		return "hell_shark", "materials/fonts/gw_body_32", size
	end
end
--[[
	Post message
--]]
ShowPlayerDamage.floating.handle = function(self, unit, biggest_hit, parameters)
	if get(me.SETTINGS.FLTNRS) and me.floating.has_unit(unit) then
		local breed_data = Unit.get_data(unit, "breed")
		local attacker_unit = biggest_hit[DamageDataIndex.ATTACKER]
		local damage_amount = biggest_hit[DamageDataIndex.DAMAGE_AMOUNT]
		local hit_zone_name = biggest_hit[DamageDataIndex.HIT_ZONE]
		local unit_is_dead = parameters.death
		
		if get(me.SETTINGS.FLTNRS_SOURCE) == 1 then
			me.floating.local_player(attacker_unit, unit, damage_amount, unit_is_dead, breed_data.name)
		elseif get(me.SETTINGS.FLTNRS_SOURCE) == 2 then
			me.floating.all(attacker_unit, unit, damage_amount, unit_is_dead, breed_data.name)
		elseif get(me.SETTINGS.FLTNRS_SOURCE) == 3 then
			me.floating.custom(attacker_unit, unit, damage_amount, unit_is_dead, breed_data.name)
		end
		
		if not self.health_extension.is_alive(self.health_extension) then
			me.floating.delete[unit] = unit
		end
	end
end

ShowPlayerDamage.floating.render = function(unit)
	
	if me.floating.units[unit] ~= nil then
		if #me.floating.units[unit] > 0 then
			local breed = Unit.get_data(unit, "breed")
			local offset = me.enemies.offsets[breed.name] or me.enemies.offsets.default
			local player = Managers.player:local_player()
			--local world = tutorial_ui.world_manager:world("level_world")
			local world = Managers.world:world("level_world")
			local viewport = ScriptWorld.viewport(world, player.viewport_name)
			local camera = ScriptViewport.camera(viewport)
			
			--local color = Color(255, 255, 255, 255)
			local font, font_, font_size = me.floating.fonts(30)
			local scale = UIResolutionScale()
			
			-- local enemy_pos = Unit.world_position(unit, 0)
			-- local dmg_pos = Vector3(enemy_pos[1], enemy_pos[2], enemy_pos[3] + offset)
			-- local hp_bar_pos_2d = Camera.world_to_screen(camera, dmg_pos)
			
			--EchoConsole(string.format("x=%i;y=%i", hp_bar_pos_2d[1], hp_bar_pos_2d[2]))
			
			local index = 1
			local visibility_offset = 0
			for _, unit_dmg in pairs(me.floating.units[unit]) do
				if me.t - unit_dmg.timer < me.floating.fade_time then
					if unit_dmg.damage > 0 then
						local damage = tostring(unit_dmg.damage)
						local life = (me.t - unit_dmg.timer) / me.floating.fade_time
						local alpha = life*2
						if alpha > 1 then alpha = 2 - alpha end
						local color = Color(unit_dmg.color[1] * alpha, unit_dmg.color[2], unit_dmg.color[3], unit_dmg.color[4])
						local black = Color(255 * alpha, 0, 0, 0)
						--local position = Vector3Aux.unbox(unit_dmg.position)
						local position = Unit.world_position(unit, 0)
						position[3] = position[3] + offset
						local position2d, depth = Camera.world_to_screen(camera, position)
						local offset_height = (100 * scale) * life
						local offset_vis = {0, 0}
						if visibility_offset == 1 then
							offset_vis[2] = -50 * scale
						elseif visibility_offset == 2 then
							offset_vis[1] = -50 * scale
						elseif visibility_offset == 3 then
							offset_vis[2] = 50 * scale
						elseif visibility_offset == 4 then
							offset_vis[1] = 50 * scale
						end
						if depth < 1 then
							Mods.gui.text(damage, position2d[1]+2 + offset_vis[1], position2d[2]-2 + offset_vis[2] + offset_height, 1, font_size, black, font)
							Mods.gui.text(damage, position2d[1]+2 + offset_vis[1], position2d[2]+2 + offset_vis[2] + offset_height, 1, font_size, black, font)
							Mods.gui.text(damage, position2d[1]-2 + offset_vis[1], position2d[2]-2 + offset_vis[2] + offset_height, 1, font_size, black, font)
							Mods.gui.text(damage, position2d[1]-2 + offset_vis[1], position2d[2]+2 + offset_vis[2] + offset_height, 1, font_size, black, font)
							Mods.gui.text(damage, position2d[1] + offset_vis[1], position2d[2] + offset_vis[2] + offset_height, 1, font_size, color, font)
							
							visibility_offset = visibility_offset + 1
							if visibility_offset > 4 then visibility_offset = 0 end
						end
					end
				else
					table.remove(me.floating.units[unit], index)
				end
				index = index + 1
			end
		else
			if table.has_item2(me.floating.delete, unit) then
				me.floating.units[unit] = nil
				me.floating.corpses[unit] = nil
				me.floating.delete[unit] = nil
			end
		end
	end
end

--[[
	Post message for local player
--]]
ShowPlayerDamage.floating.local_player = function(attacker_unit, unit, damage_amount, dead, breed)
	local local_player = Managers.player:local_player()
	if attacker_unit == local_player.player_unit and (not me.floating.corpses[unit]) then
		local position = Unit.world_position(unit, 0)
		position[2] = position[2] + me.enemies.offsets[breed]
		local color = {255, 255, 255, 255}
		if dead then color = {255, 255, 56, 56} end
		me.floating.units[unit][#me.floating.units[unit]+1] = me.floating.new(position, damage_amount, color)
	end
	if dead then me.floating.corpses[unit] = true end
end
--[[
	Post message for every player
--]]
ShowPlayerDamage.floating.all = function(attacker_unit, unit, damage_amount, dead, breed)
	if me.players.is_player_unit(attacker_unit) and (not me.floating.corpses[unit]) then
		local position = Unit.world_position(unit, 0)
		position[2] = position[2] + me.enemies.offsets[breed]
		local color = {255, 255, 255, 255}
		if dead then color = {255, 255, 56, 56} end
		me.floating.units[unit][#me.floating.units[unit]+1] = me.floating.new(position, damage_amount, color)
	end
	if dead then me.floating.corpses[unit] = true end
end
--[[
	Post message for custom chosen player
--]]
ShowPlayerDamage.floating.custom = function(attacker_unit, unit, damage_amount, dead, breed)
	if me.players.is_player_unit(attacker_unit) then			
		local player_manager = Managers.player
		local players = player_manager:human_and_bot_players()				
		local i = 1
		for _, p in pairs(players) do
			if get(me.SETTINGS.FLTNRS_CHAR .. tostring(i)) then
				if attacker_unit == p.player_unit and (not me.floating.corpses[unit]) then
					local position = Unit.world_position(unit, 0)
					position[2] = position[2] + me.enemies.offsets[breed]
					local color = {255, 255, 255, 255}
					if dead then color = {255, 255, 56, 56} end
					me.floating.units[unit][#me.floating.units[unit]+1] = me.floating.new(position, damage_amount, color)
				end
			end
			i = i + 1
		end
	end
	if dead then me.floating.corpses[unit] = true end
end
--[[
	Remove damage numbers from gutter runner when he's vanishing
--]]
Mods.hook.set(mod_name, "BTSelector_gutter_runner.run", function(func, self, unit, blackboard, ...)
	func(self, unit, blackboard, ...)
	local child_running = self.current_running_child(self, blackboard)
	local node_ninja_vanish = self._children[5]
	if node_ninja_vanish == child_running then
		me.floating.units[unit] = nil
	end
end)

-- ####################################################################################################################
-- ##### Hooks ########################################################################################################
-- ####################################################################################################################
--[[
	Update - Add units to system if alive
--]]
Mods.hook.set(mod_name, "GenericHitReactionExtension.update", function(func, self, unit, input, dt, context, t, ...)
	
	-- Save current time
	me.t = t
	
	-- Add new units to process
	me.add_unit(self, unit)
	
	-- Render damages
	me.floating.render(unit)
	
	-- Original function
	func(self, unit, input, dt, context, t, ...)
	
end)

ShowPlayerDamage.floating.has_unit = function(unit)
	return me.floating.units[unit] ~= nil
end

--[[
	Execute Effect - Post message and remove unit from system
--]]
Mods.hook.set(mod_name, "GenericHitReactionExtension._execute_effect", 
function(func, self, unit, effect_template, biggest_hit, parameters)

	-- Original function
	func(self, unit, effect_template, biggest_hit, parameters)

	local damage_extension = self.damage_extension
	local damages, num_damages = damage_extension.recent_damages(damage_extension)

	local damage_total = 0
	local stride = DamageDataIndex.STRIDE

	for i = 1, num_damages, stride do
		damage_total = damage_total + damages[(i + DamageDataIndex.DAMAGE_AMOUNT) - 1]
	end

	biggest_hit[DamageDataIndex.DAMAGE_AMOUNT] = damage_total
	
	-- Floating numbers
	me.floating.handle(self, unit, biggest_hit, parameters)
	
end)

ShowPlayerDamage.floating.new = function(position, damage, color)
	local unit_dmg = table.clone(me.floating.definition)
	unit_dmg.position = Vector3Aux.box(nil, position)
	unit_dmg.damage = damage or 0
	unit_dmg.color = color or {255, 255, 255, 255}
	unit_dmg.timer = me.t
	return unit_dmg
end

-- ####################################################################################################################
-- ##### Common #######################################################################################################
-- ####################################################################################################################
--[[
	Add unit to process
--]]
ShowPlayerDamage.add_unit = function(self, unit)
	if not me.floating.has_unit(unit) then
		if self.health_extension.is_alive(self.health_extension) then
			me.floating.units[unit] = {}
		end
	end
end

ShowPlayerDamage.create_dynamic_text = function()
	safe_pcall(function()
		local oi = OptionsInjector
		oi.add_dynamic_text("cb_show_damage_dyn_player_1", "N/A", function()
			return ShowPlayerDamage.players.name_from_index(1)
		end)
		oi.add_dynamic_text("cb_show_damage_dyn_player_2", "N/A", function()
			return ShowPlayerDamage.players.name_from_index(2)
		end)
		oi.add_dynamic_text("cb_show_damage_dyn_player_3", "N/A", function()
			return ShowPlayerDamage.players.name_from_index(3)
		end)
		oi.add_dynamic_text("cb_show_damage_dyn_player_4", "N/A", function()
			return ShowPlayerDamage.players.name_from_index(4)
		end)
		oi.add_dynamic_text("cb_show_damage_floating_numbers_dyn_player_1", "N/A", function()
			return ShowPlayerDamage.players.name_from_index(1)
		end)
		oi.add_dynamic_text("cb_show_damage_floating_numbers_dyn_player_2", "N/A", function()
			return ShowPlayerDamage.players.name_from_index(2)
		end)
		oi.add_dynamic_text("cb_show_damage_floating_numbers_dyn_player_3", "N/A", function()
			return ShowPlayerDamage.players.name_from_index(3)
		end)
		oi.add_dynamic_text("cb_show_damage_floating_numbers_dyn_player_4", "N/A", function()
			return ShowPlayerDamage.players.name_from_index(4)
		end)
	end)
end

-- ####################################################################################################################
-- ##### Start ########################################################################################################
-- ####################################################################################################################
me = ShowPlayerDamage
me.create_options()
me.create_dynamic_text()