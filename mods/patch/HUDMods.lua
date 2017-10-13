--[[
	authors: grimalackt, iamlupo, walterr

	HUD Modifications.
	*	Alternative UI for friendly fire, replacing the red screen flash and arrow with a red rect
		behind the HUD area of the offending player.
	*	Make the black markers on the Overcharge Bar dynamic: they will move to show the postion at
		which the next chunk of damage will apply.
--]]
local mod_name = "HudMods"

local is_player_unit = DamageUtils.is_player_unit
local user_setting = Application.user_setting
local set_user_setting = Application.set_user_setting
local DAMAGE_DATA_STRIDE = DamageDataIndex.STRIDE
local FF_STATE_STARTING = 1
local FF_STATE_ONGOING = 2

--[[
	Setting defs.
--]]
local MOD_SETTINGS = {
	SUB_GROUP = {
		["save"] = "cb_hudmod_subgroup",
		["widget_type"] = "dropdown_checkbox",
		["text"] = "Goodies",
		["default"] = false,
		["hide_options"] = {
			{
				true,
				mode = "show",
				options = {
					"cb_hudmod_alt_ff_ui",
					"cb_hudmod_dynamic_ocharge_pips",
					"cb_hud_party_trinkets_indicators",
					"cb_potion_pickup_enabled",
					"cb_damage_taken_enabled",
					"cb_damage_hp_procs_fx",
					"cb_hudmod_dodge_tired",
					"cb_hud_force_gamepad_hud"
				},
			},
			{
				false,
				mode = "hide",
				options = {
					"cb_hudmod_alt_ff_ui",
					"cb_hudmod_dynamic_ocharge_pips",
					"cb_hud_party_trinkets_indicators",
					"cb_potion_pickup_enabled",
					"cb_damage_taken_enabled",
					"cb_damage_hp_procs_fx",
					"cb_hudmod_dodge_tired",
					"cb_hud_force_gamepad_hud"
				},
			},
		},
	},
	ALTERNATIVE_FF_UI = {
		["save"] = "cb_hudmod_alt_ff_ui",
		["widget_type"] = "stepper",
		text = "Alternative Friendly Fire UI",
		tooltip = "Alternative Friendly Fire UI\n" ..
				"Instead of a red screen flash and directional indicator when hit by friendly " ..
				"fire, show a red rectangle beneath the HUD area of the player who hit you.",
		["value_type"] = "boolean",
		["options"] = {
			{text = "Off", value = false},
			{text = "On", value = true},
		},
		["default"] = 1, -- Default second option is enabled. In this case Off
	},
	OVERCHARGE_BAR_DYNAMIC_MARKERS = {
		["save"] = "cb_hudmod_dynamic_ocharge_pips",
		["widget_type"] = "stepper",
		["text"] = "Dynamic Markers on Overcharge Bar",
		["tooltip"] = "Dynamic Markers on Overcharge Bar\n" ..
				"On the Overcharge Bar shown for Bright Wizard staffs and Drakefire Pistols, " ..
				"makes the small black markers move around as the amount of overcharge changes, " ..
				"to show the position at which the next increment of damage will be incurred if " ..
				"overcharge is fully vented.",
		["value_type"] = "boolean",
		["options"] = {
			{text = "Off", value = false},
			{text = "On", value = true},
		},
		["default"] = 1, -- Default second option is enabled. In this case Off
	},
	PARTY_TRINKETS_INDICATORS = {
		["save"] = "cb_hud_party_trinkets_indicators",
		["widget_type"] = "stepper",
		["text"] = "Party Trinkets Indicators",
		["tooltip"] = "Party Trinkets Indicators\n" ..
			"Show icons for hp share, pot share, luck and dupe, and the grim trinket " ..
			"below the player's hero UI if the player has one of those trinkets equipped.",
		["value_type"] = "boolean",
		["options"] = {
			{text = "Off", value = false},
			{text = "On", value = true},
		},
		["default"] = 1, -- Default second option is enabled. In this case Off
		["hide_options"] = {
			{
				false,
				mode = "hide",
				options = {
					"cb_hud_party_trinkets_homogenize_icons",
				}
			},
			{
				true,
				mode = "show",
				options = {
					"cb_hud_party_trinkets_homogenize_icons",
				}
			},
		},
	},
	HOMOGENIZE_PARTY_TRINKET_ICONS = {
		["save"] = "cb_hud_party_trinkets_homogenize_icons",
		["widget_type"] = "stepper",
		["text"] = "Homogenize Event Icons",
		["tooltip"] = "Homogenize Event Icons\n" ..
			"Make event trinkets have icon of its closest equivalent.",
		["value_type"] = "boolean",
		["options"] = {
			{text = "Off", value = false},
			{text = "On", value = true},
		},
		["default"] = 1, -- Off
	},
	POTION_PICKUP = {
		["save"] = "cb_potion_pickup_enabled",
		["widget_type"] = "stepper",
		["text"] = "Show Potion Type When Carrying Grimoire",
		["tooltip"] = "Show Potion Type When Carrying Grimoire\n" ..
			"Show which potion type you are looking at even if you are carrying a grimoire on the 'Must drop grimoire' tooltip.",
		["value_type"] = "boolean",
		["options"] = {
			{text = "Off", value = false},
			{text = "On", value = true},
		},
		["default"] = 1, -- Default second option is enabled. In this case Off
	},
	DAMAGE_TAKEN = {
		["save"] = "cb_damage_taken_enabled",
		["widget_type"] = "stepper",
		["text"] = "Damage Taken Scoreboard Fix",
		["tooltip"] = "Damage Taken Scoreboard Fix\n" ..
			"Ignore damage taken while already downed for the purpose of the end match scoreboard.",
		["value_type"] = "boolean",
		["options"] = {
			{text = "Off", value = false},
			{text = "On", value = true},
		},
		["default"] = 1, -- Default second option is enabled. In this case Off
	},
	HP_PROCS_FX = {
		["save"] = "cb_damage_hp_procs_fx",
		["widget_type"] = "stepper",
		["text"] = "Hide Bloodlust/Regrowth Proc Effects",
		["tooltip"] = "Hide Bloodlust/Regrowth Proc Effects\n" ..
			"Hide graphic effects on bloodlust/regrowth procs.",
		["value_type"] = "boolean",
		["options"] = {
			{text = "Off", value = false},
			{text = "On", value = true},
		},
		["default"] = 1, -- Default second option is enabled. In this case Off
	},
	DODGE_TIRED = {
		["save"] = "cb_hudmod_dodge_tired",
		["widget_type"] = "stepper",
		text = "Too Tired to Dodge Display",
		tooltip = "Too Tired to Dodge Display\n" ..
			"Displays a warning when you are too tired to dodge.",
		["value_type"] = "boolean",
		["options"] = {
			{text = "Off", value = false},
			{text = "On", value = true},
		},
		["default"] = 1, -- Default second option is enabled. In this case Off
	},
	FORCE_GAMEPAD_HUD = {
		["save"] = "cb_hud_force_gamepad_hud",
		["widget_type"] = "stepper",
		["text"] = "Always Use Gamepad HUD",
		["tooltip"] = "Always Use Gamepad HUD\n" ..
			"A different HUD is used when you play the game with a gamepad, one which has a larger health " ..
			"bar but is more compact overall. Enabling this option will cause the gamepad HUD to be used " ..
			"even when you are not using a gamepad.",
		["value_type"] = "boolean",
		["options"] = {
			{text = "Off", value = false},
			{text = "On", value = true},
		},
		["default"] = 1, -- By default first option is selected, in this case "Off"
	},
}

local MAX_INDICATOR_WIDGETS = 10
local ignored_damage_types_reaction = {
    buff_shared_medpack = true,
    kinetic = true,
    wounded_dot = true,
    buff = true,
    heal = true,
    knockdown_bleed = true
}
local ignored_damage_types_indicator = {
    globadier_gas_dot = true,
    buff_shared_medpack = true,
    wounded_dot = true,
    buff = true,
    heal = true,
    damage_over_time = true,
    knockdown_bleed = true
}

local function trigger_player_taking_damage_buffs(player_unit, attacker_unit, is_server)
	if ScriptUnit.has_extension(player_unit, "buff_system") then
	local buff_extension = ScriptUnit.extension(player_unit, "buff_system")

		if buff_extension.has_buff_type(buff_extension, "chance_to_bonus_fatigue_reg_damage_taken") then
			local percentage_chance = 1
			percentage_chance = buff_extension.apply_buffs_to_value(buff_extension, percentage_chance, StatBuffIndex.CHANCE_TO_BONUS_FATIGUE_REG_DAMAGE_TAKEN, BuffTypes.PLAYER) - 1
			percentage_chance = percentage_chance - 1

			if percentage_chance <= math.random() then
				buff_extension.add_buff(buff_extension, "melee_weapon_proc_bonus_fatigue_regen")
			end
		end
	end

	return
end
 
local function trigger_player_friendly_fire_dialogue(player_unit, attacker_unit)
	local player_manager = Managers.player

	if player_unit ~= attacker_unit and player_manager.is_player_unit(player_manager, attacker_unit) then
		local profile_name_victim = ScriptUnit.extension(player_unit, "dialogue_system").context.player_profile
		local profile_name_attacker = ScriptUnit.extension(attacker_unit, "dialogue_system").context.player_profile
		local dialogue_input = ScriptUnit.extension_input(player_unit, "dialogue_system")
		local event_data = FrameTable.alloc_table()
		event_data.target = profile_name_victim
		event_data.player_profile = profile_name_attacker

		dialogue_input.trigger_dialogue_event(dialogue_input, "friendly_fire", event_data)
	end
 
	return
end

--[[
	Implementation of dynamic markers on overcharge bar.
--]]

-- These values are hard-coded in OverChargeExtension.update. The vent_damage_pool value in
-- OverChargeExtension is scaled up by a factor of 2 for some reason.
local VENT_DAMAGE_POOL_SCALING = 2
local MAX_VENT_DAMAGE_POOL = (20 / VENT_DAMAGE_POOL_SCALING)

-- Overcharge decays over time when you are not producing more of it, and this continues even while
-- venting, which means you can vent slightly *more* than MAX_VENT_DAMAGE_POOL between chunks of
-- damage. The value below is used to compensate for this effect approximately, since I found it too
-- difficult to calculate exactly.
local DECAY_FUDGE_FACTOR = 1.05

Mods.hook.set(mod_name, "OverchargeBarUI.create_ui_elements", function(orig_func, self)
	orig_func(self)
	if user_setting(MOD_SETTINGS.OVERCHARGE_BAR_DYNAMIC_MARKERS.save) then
		-- Put the black markers above the white overcharge end markers so they are easier to see.
		local widget_style = self.charge_bar.style
		widget_style.black_divider_left.offset[3] = 2
		widget_style.black_divider_right.offset[3] = 2
	end
end)

Mods.hook.set(mod_name, "OverchargeBarUI.set_charge_bar_fraction", function(orig_func, self, overcharge_fraction, threshold_fraction, anim_blend_overcharge)
	orig_func(self, overcharge_fraction, threshold_fraction, anim_blend_overcharge)
	if not user_setting(MOD_SETTINGS.OVERCHARGE_BAR_DYNAMIC_MARKERS.save) then
		return
	end

	-- If this function is called we know overcharge_extn etc. cant be nil.
	local equipment = ScriptUnit.extension(Managers.player:local_player().player_unit, "inventory_system"):equipment()
	local rh_unit = equipment.right_hand_wielded_unit
	local lh_unit = equipment.left_hand_wielded_unit
	local overcharge_extn = (rh_unit and ScriptUnit.has_extension(rh_unit, "overcharge_system")) or
		(lh_unit and ScriptUnit.has_extension(lh_unit, "overcharge_system"))
	local max_overcharge = overcharge_extn:get_max_value()

	local next_damage_fraction
	if overcharge_extn.venting_overcharge then
		-- We are venting so put the markers at the position where vent_damage_pool will hit zero.
		local vent_damage_pool_fraction = (MAX_VENT_DAMAGE_POOL - overcharge_extn.vent_damage_pool / VENT_DAMAGE_POOL_SCALING) / max_overcharge
		next_damage_fraction = overcharge_fraction - vent_damage_pool_fraction
		if next_damage_fraction < threshold_fraction or overcharge_extn.no_damage then
			next_damage_fraction = threshold_fraction
		end
	elseif threshold_fraction < overcharge_fraction then
		-- Overcharge is over the no-damage threshold so put the markers at the position where an
		-- additional chunk of damage will occur if the user chooses to vent fully.
		local max_vent_damage_fraction = (MAX_VENT_DAMAGE_POOL / max_overcharge) * DECAY_FUDGE_FACTOR
		next_damage_fraction = math.ceil(overcharge_fraction / max_vent_damage_fraction) * max_vent_damage_fraction
		next_damage_fraction = math.clamp(next_damage_fraction, max_vent_damage_fraction * 2, 1)
	else
		-- Overcharge is within the no-damage threshold so put the markers at the threshold.
		next_damage_fraction = threshold_fraction
	end

	-- This code based on OverchargeBarUI.setup_charge_bar.
	local widget_style = self.charge_bar.style
	local marker_fraction = next_damage_fraction * 0.82
	local r = 265
	local x = r * math.sin(marker_fraction)
	local y = r * -math.cos(marker_fraction)
	widget_style.black_divider_left.offset[1] = -x
	widget_style.black_divider_left.offset[2] = y
	widget_style.black_divider_right.offset[1] = x
	widget_style.black_divider_right.offset[2] = y
	local one_side_max_angle = 45
	local current_angle = next_damage_fraction * one_side_max_angle
	local radians = math.degrees_to_radians(current_angle)
	widget_style.black_divider_right.angle = -radians
	widget_style.black_divider_left.angle = radians
end)

--[[
	Party trinkets indicators, by Grundlid.
--]]
local trinkets_widget =
{
	scenegraph_id = "pivot",
	offset = { 55, -88, -2 },
	element = {
		passes = (function()
						local passes = {}
						for i=1,9 do
							table.insert(passes, {
									pass_type = "texture_uv",
									style_id = "trinket_"..i,
									content_id = "trinket_"..i,
									content_check_function = function(ui_content)
										return ui_content and ui_content.show or false
									end,
								})
						end
						return passes
					end)()
	},
	content = (function()
					local content = {}
					local trinket_icons = {
						"icon_trophy_twig_of_loren_01_03",
						"icon_trophy_potion_rack_t3_01",
						"icon_trophy_valten_saga_01_03",
						"icon_trophy_luckstone_01_01",
						"icon_trophy_carrion_claw_01_01",
						"icon_trophy_fish_t3_01",
						"icon_trophy_wine_bottle_01_01",
						"icon_trophy_honing_kit_with_carroburg_seal_01_03",
						"icon_trophy_ornamented_scroll_case_01_03"
					}
					for i, icon in ipairs(trinket_icons) do
						content["trinket_"..i] = {
							show = false,
							texture_id = icon,
							uvs = i < 6 and { { 0.17, 0.17 }, { 0.83, 0.83 } } or { { 0.17, 0.5 }, { 0.83, 0.83 } },
						}
					end
					return content
				end)(),
	style = (function()
					local style = {}
					for i, offset in ipairs({0, 37, 37*2, 37*3+10, 37*4+20}) do
						style["trinket_"..i] = {
							color = { 255, 255, 255, 255 },
							offset = { offset, 0, 1 },
							size = { 32, 32 },
						}
					end
					for i, offset in ipairs({0, 37, 37*2, 37*3+10, 37*4+20}) do
						style["trinket_"..(i+5)] = {
							color = { 255, 255, 255, 255 },
							offset = { offset, 0, 2 },
							size = { 32, 16 },
						}
					end
					return style
				end)(),
}

local luck_position = 4
local dupe_position = luck_position + 5
local tracked_trinkets = {
	pot_share = { match = "potion_spread", position = 2 },
	pot_share_skulls = { match = "pot_share", position = 2 },
	dove = { match = "heal_self_on_heal_other", position = 1, priority = 2 },
	hp_share = { match = "medpack_spread", position = 1, priority = 1 },
	grenade_radius = { match = "grenade_radius", position = 3 },
	luck = { match = "increase_luck", position = luck_position },
	grim = { match = "reduce_grimoire_penalty", position = 5 },
	med_dupe = { match = "not_consume_medpack", position = 6 },
	pot_dupe = { match = "not_consume_potion", position = 7 },
	bomb_dupe = { match = "not_consume_grenade", position = 8 },
	dupe = { match = "not_consume_pickup", position = dupe_position },
}
local trinket_icon_replacements = {
	["icon_trophy_skull_encased_t3_03"] = "icon_trophy_potion_rack_t3_01",
	["icon_trophy_garlic_01"] = "icon_trophy_twig_of_loren_01_02",
	["icon_trophy_moot_charm_01_01"] = "icon_trophy_luckstone_01_01",
	["icon_trophy_flower_flask_01_01"] = "icon_trophy_carrion_claw_01_01",
}

local dodge_tired_widget = {
	scenegraph_id = "pivot",
	offset = { -40, 45, -2 },
	element = {
		passes = {
			{
				style_id = "dodge_tired_text",
				pass_type = "text",
				text_id = "dodge_tired_text",
			}
		}
	},
	content = {
		dodge_tired_text = ""
	},
	style = {
		dodge_tired_text = {
			font_type = "hell_shark",
			size = { 27, 30 },
			text_color = Colors.color_definitions.red,
			font_size = 27,
			offset = { 0, 0, 1 }
		}
	}
}

local function get_active_trinket_slots(attachment_extn)
	local active_trinkets = {}
	for _, slot_name in ipairs({"slot_trinket_1", "slot_trinket_2", "slot_trinket_3"}) do
		local slot_data =  attachment_extn and attachment_extn._attachments.slots[slot_name]
		local item_key = slot_data and slot_data.item_data.key
		for _, trinket in pairs(tracked_trinkets) do
			if item_key and string.find(item_key, trinket.match) ~= nil then
				local pos = trinket.position
				if not (active_trinkets[pos] and active_trinkets[pos].info.priority < trinket.priority) then
					active_trinkets[pos] = {info = trinket, icon = ItemMasterList[item_key].inventory_icon}
					if user_setting(MOD_SETTINGS.HOMOGENIZE_PARTY_TRINKET_ICONS.save) then
						for icon_name, replacement_icon_name in pairs(trinket_icon_replacements) do
							if active_trinkets[pos].icon == icon_name then
								active_trinkets[pos].icon = replacement_icon_name
							end
						end
					end
				end
			end
		end
	end
	return active_trinkets
end

Mods.hook.set(mod_name, "UnitFramesHandler._create_unit_frame_by_type", function(orig_func, self, ...)
	if user_setting(MOD_SETTINGS.FORCE_GAMEPAD_HUD.save) then
		-- The gamepad HUD will be used if the platform is not "win32"
		local real_platform = self.platform
		self.platform = "definitely-not-win32"
		local result = orig_func(self, ...)
		self.platform = real_platform
		return result
	else
		return orig_func(self, ...)
	end
end)

Mods.hook.set(mod_name, "UnitFramesHandler.update", function(orig_func, self, dt, t, my_player)
	local player_unit = self.my_player.player_unit
	if player_unit then
		-- Check recent damages for FF.
		if user_setting(MOD_SETTINGS.ALTERNATIVE_FF_UI.save) then
			local damage_extension = ScriptUnit.extension(player_unit, "damage_system")
			local strided_array, array_length = damage_extension:recent_damages()
			if 0 < array_length then
				for i = 1, array_length/DAMAGE_DATA_STRIDE, 1 do
					local index = (i - 1) * DAMAGE_DATA_STRIDE
					local attacker = strided_array[index + DamageDataIndex.ATTACKER]

					-- If this damage is FF, find the HUD area of the attacking player and tell it to
					-- display the FF indicator.
					if is_player_unit(attacker) and attacker ~= player_unit then
						for _, unit_frame in ipairs(self._unit_frames) do
							local team_member = unit_frame.player_data.player
							if team_member and team_member.player_unit == attacker then
								unit_frame.data._hudmod_ff_state = FF_STATE_STARTING
							end
						end
					end
				end
			end
		end

		-- Update equipped trinkets.
		if user_setting(MOD_SETTINGS.PARTY_TRINKETS_INDICATORS.save) then
			local unit_frame = self._unit_frames[self._current_frame_index]
			if unit_frame and unit_frame.sync then
				local extensions = unit_frame.player_data.extensions
				if extensions and not extensions.attachment and ScriptUnit.has_extension(unit_frame.player_data.player_unit, "attachment_system") then
					extensions.attachment = ScriptUnit.extension(unit_frame.player_data.player_unit, "attachment_system")
				end
				local attachment_extn = extensions and extensions.attachment
				local active_trinkets = {}
				if attachment_extn then
					active_trinkets = get_active_trinket_slots(attachment_extn)
				end
				if unit_frame.data._hudmod_active_trinkets ~= active_trinkets then
					unit_frame.data._hudmod_active_trinkets = active_trinkets
					self._dirty = true
				end
			end
		end

		-- Update dodge info.
		if user_setting(MOD_SETTINGS.DODGE_TIRED.save) then
			local player_unit_frame = nil
			local my_player_unit = Managers.player:local_player().player_unit
			for _,unit_frame in ipairs(self._unit_frames) do
				if unit_frame.player_data.player_unit and unit_frame.player_data.player_unit == my_player_unit then
					player_unit_frame = unit_frame
					break
				end
			end
			if player_unit_frame then
				local dodge_value = nil
				if Unit.alive(my_player_unit) then
					local status_extension = ScriptUnit.extension(my_player_unit, "status_system")
					if status_extension then
						local movement_settings_table = PlayerUnitMovementSettings.get_movement_settings_table(my_player_unit)
						dodge_value = movement_settings_table.dodging.distance*movement_settings_table.dodging.distance_modifier*status_extension:get_dodge_cooldown()
					end
				end
				if player_unit_frame.data._hudmod_dodge_value ~= dodge_value then
					player_unit_frame.data._hudmod_dodge_value = dodge_value
					self._dirty = true
				end
			end
		end
	end

	-- Check whether the FORCE_GAMEPAD_HUD setting has changed.
	local force_gamepad_hud = user_setting(MOD_SETTINGS.FORCE_GAMEPAD_HUD.save)
	if not force_gamepad_hud ~= not self._unit_frames[1].gamepad_version then
		if force_gamepad_hud then
			self:on_gamepad_activated()
		else
			self:on_gamepad_deactivated()
		end
		self.ingame_ui.ingame_hud.player_inventory_ui:set_visible(self._is_visible)
	end

	return orig_func(self, dt, t, my_player)
end)

Mods.hook.set(mod_name, "HitReactions.templates.player.unit", function(func, unit, dt, context, t, hit)
	if not user_setting(MOD_SETTINGS.ALTERNATIVE_FF_UI.save) then
		return func(unit, dt, context, t, hit)
	end

	local damage_type = hit[DamageDataIndex.DAMAGE_TYPE]

	if not ignored_damage_types_reaction[damage_type] then
		local attacker = hit[DamageDataIndex.ATTACKER]
		local damage_type = hit[DamageDataIndex.DAMAGE_TYPE]
		local damage_source_name = hit[DamageDataIndex.DAMAGE_SOURCE_NAME]

		if not is_player_unit(attacker) or attacker == unit then
			if ((damage_type ~= "burn" and damage_type ~= "burninating") or
				(string.find(damage_source_name, "bw_skullstaff_geiser") == nil and
				(damage_type ~= "burninating" or string.find(damage_source_name, "grenade_fire") == nil))) then
 
				local first_person_extension = ScriptUnit.extension(unit, "first_person_system")

				if 0 < hit[DamageDataIndex.DAMAGE_AMOUNT] then
					first_person_extension.animation_event(first_person_extension, "shake_get_hit")
				end
			end
		end

		trigger_player_taking_damage_buffs(unit, attacker, true)
		trigger_player_friendly_fire_dialogue(unit, attacker)
	end

	return
end)
 
Mods.hook.set(mod_name, "DamageIndicatorGui.update", function(func, self, dt)
    if not user_setting(MOD_SETTINGS.ALTERNATIVE_FF_UI.save) then
        return func(self, dt)
    end
 
    local input_manager = self.input_manager
    local input_service = input_manager.get_service(input_manager, "ingame_menu")
    local ui_renderer = self.ui_renderer
    local ui_scenegraph = self.ui_scenegraph
    local indicator_widgets = self.indicator_widgets
    local peer_id = self.peer_id
    local my_player = self.player_manager:player_from_peer_id(peer_id)
    local player_unit = my_player.player_unit
 
    if not player_unit then
        return
    end
 
    UIRenderer.begin_pass(ui_renderer, ui_scenegraph, input_service, dt, "damage_indicator_center")
 
    local damage_extension = ScriptUnit.extension(player_unit, "damage_system")
    local strided_array, array_length = damage_extension.recent_damages(damage_extension)
    local indicator_positions = self.indicator_positions
 
    if 0 < array_length then
        for i = 1, array_length/DamageDataIndex.STRIDE, 1 do
            local index = (i - 1)*DamageDataIndex.STRIDE
            local attacker = strided_array[index + DamageDataIndex.ATTACKER]
            local damage_type = strided_array[index + DamageDataIndex.DAMAGE_TYPE]
            local damage_source_name = strided_array[index + DamageDataIndex.DAMAGE_SOURCE_NAME]
            local show_direction = not ignored_damage_types_indicator[damage_type]
 
            if ((is_player_unit(attacker) and attacker ~= player_unit) or
                (damage_type == "burninating" and string.find(damage_source_name, "grenade_fire") ~= nil) or
                ((damage_type == "burn" or damage_type == "burninating") and string.find(damage_source_name, "bw_skullstaff_geiser") ~= nil)) then
                show_direction = false
            end
 
            if attacker and Unit.alive(attacker) and show_direction then
                local next_active_indicator = self.num_active_indicators + 1
 
                if next_active_indicator <= MAX_INDICATOR_WIDGETS then
                    self.num_active_indicators = next_active_indicator
                else
                    next_active_indicator = 1
                end
 
                local widget = indicator_widgets[next_active_indicator]
                local indicator_position = indicator_positions[next_active_indicator]
                local attacker_position = POSITION_LOOKUP[attacker] or Unit.world_position(attacker, 0)
 
                Vector3Aux.box(indicator_position, attacker_position)
 
                indicator_position[3] = 0
 
                UIWidget.animate(widget, UIAnimation.init(UIAnimation.function_by_time, widget.style.rotating_texture.color, 1, 255, 0, 1, math.easeInCubic))
            end
        end
    end
 
    local first_person_extension = ScriptUnit.extension(player_unit, "first_person_system")
    local my_pos = Vector3.copy(POSITION_LOOKUP[player_unit])
    local my_rotation = first_person_extension.current_rotation(first_person_extension)
    local my_direction = Quaternion.forward(my_rotation)
    my_direction.z = 0
    my_direction = Vector3.normalize(my_direction)
    local my_left = Vector3.cross(my_direction, Vector3.up())
    my_pos.z = 0
    local i = 1
    local num_active_indicators = self.num_active_indicators
 
    while i <= num_active_indicators do
        local widget = indicator_widgets[i]
 
        if not UIWidget.has_animation(widget) then
            local swap = indicator_widgets[num_active_indicators]
            indicator_widgets[i] = swap
            indicator_widgets[num_active_indicators] = widget
            num_active_indicators = num_active_indicators - 1
        else
            local direction = Vector3.normalize(Vector3Aux.unbox(indicator_positions[i]) - my_pos)
            local forward_dot_dir = Vector3.dot(my_direction, direction)
            local left_dot_dir = Vector3.dot(my_left, direction)
            local angle = math.atan2(left_dot_dir, forward_dot_dir)
            widget.style.rotating_texture.angle = angle
            i = i + 1
 
            UIRenderer.draw_widget(ui_renderer, widget)
        end
    end
 
    self.num_active_indicators = num_active_indicators
 
    UIRenderer.end_pass(ui_renderer)
 
    return
end)

Mods.hook.set(mod_name, "UnitFrameUI.draw", function(orig_func, self, dt)
	local data = self.data
	if self._is_visible and (data._hudmod_ff_state ~= nil or data._hudmod_active_trinkets or data._hudmod_dodge_value ~= nil) then
		local ui_renderer = self.ui_renderer
		local input_service = self.input_manager:get_service("ingame_menu")
		UIRenderer.begin_pass(ui_renderer, self.ui_scenegraph, input_service, dt, nil, self.render_settings)

		if data._hudmod_ff_state ~= nil then
			local widget = self._hudmod_ff_widget
			if not widget then
				-- This is the first FF from this player, create the indicator widget for his HUD area.
				local rect = UIWidgets.create_simple_rect("pivot", Colors.get_table("firebrick"))
				rect.style.rect.size = { 308, 132 }
				rect.style.rect.offset = { -50, -65 }
				widget = UIWidget.init(rect)
				self._hudmod_ff_widget = widget
			end

			if data._hudmod_ff_state == FF_STATE_STARTING then
				-- New damage, restart the animation.
				UIWidget.animate(widget, UIAnimation.init(UIAnimation.function_by_time, widget.style.rect.color, 1, 255, 0, 1, math.easeInCubic))
				data._hudmod_ff_state = FF_STATE_ONGOING
			end

			if UIWidget.has_animation(widget) then
				UIRenderer.draw_widget(ui_renderer, widget)
				self._dirty = true
			else
				-- Animation is finished, reset the FF state.
				data._hudmod_ff_state = nil
			end
		end

		UIRenderer.end_pass(ui_renderer)

		---------------------------------

		UIRenderer.begin_pass(ui_renderer, self.ui_scenegraph, input_service, dt, nil, self.render_settings)

		if user_setting(MOD_SETTINGS.PARTY_TRINKETS_INDICATORS.save) then
			local widget = self._trinkets_widget
			if not widget then
				widget = UIWidget.init(trinkets_widget)
				self._trinkets_widget = widget

				if self._hudmod_is_own_player then
					for _, trinket_style in pairs(widget.style) do
						trinket_style.offset[1] = trinket_style.offset[1] - 295
					end
				end
			end

			local important_trinkets = data._hudmod_active_trinkets or {}
			for i=1,9 do
				widget.content["trinket_"..i].show = false
				if important_trinkets[i] then
					if i < 6 or important_trinkets[i-5] then
						widget.content["trinket_"..i].show = true
						widget.content["trinket_"..i].texture_id = important_trinkets[i].icon
					elseif i == dupe_position then
						widget.content["trinket_"..luck_position].show = true
						widget.content["trinket_"..luck_position].texture_id = important_trinkets[i].icon
					end
				end
			end

			UIRenderer.draw_widget(ui_renderer, widget)
		end

		UIRenderer.end_pass(ui_renderer)

		---------------------------------

		UIRenderer.begin_pass(ui_renderer, self.ui_scenegraph, input_service, dt, nil, self.render_settings)

		if user_setting(MOD_SETTINGS.DODGE_TIRED.save) then
			local widget = self._dodge_tired_widget
 
			if not widget then
				local widget_settings = {}
				widget_settings = table.create_copy(widget_settings, dodge_tired_widget)
				widget = UIWidget.init(widget_settings)
				self._dodge_tired_widget = widget
			end
 
			if data._hudmod_dodge_value == nil or data._hudmod_dodge_value >= 1.7 then
				widget.content.dodge_tired_text = ""
			else
				widget.content.dodge_tired_text = "TIRED"
			end
 
			UIRenderer.draw_widget(ui_renderer, widget)
		end
 
		UIRenderer.end_pass(ui_renderer)
	end

	return orig_func(self, dt)
end)

Mods.hook.set(mod_name, "PlayerInventoryUI.set_visible", function (orig_func, self, visible)
	-- In the gamepad HUD the inventory UI is part of the unit frame.
	if user_setting(MOD_SETTINGS.FORCE_GAMEPAD_HUD.save) then
		visible = false
	end
	return orig_func(self, visible)
end)

Mods.hook.set(mod_name, "BoonUI.update", function (func, self, dt, t)
	func(self, dt, t)
	-- Force update boon positions when mod turned on/off
	if user_setting(MOD_SETTINGS.FORCE_GAMEPAD_HUD.save) then
		if not self.force_gamepad_active_last_frame then
			self.force_gamepad_active_last_frame = true

			self.on_gamepad_activated(self)
		end
	elseif self.force_gamepad_active_last_frame then
		self.force_gamepad_active_last_frame = false

		self.on_gamepad_deactivated(self)
	end
end)

Mods.hook.set(mod_name, "BoonUI._align_widgets", function (func, self)
	func(self)
	-- -250 X widget offset on boons for gamepad needs to be manually reapplied
	if user_setting(MOD_SETTINGS.FORCE_GAMEPAD_HUD.save) then
		local boon_width = 38
		local boon_spacing = 15
		local widget_total_width = 0
		for _, data in ipairs(self._active_boons) do
			local widget = data.widget
			local widget_offset = widget.offset
			widget_offset[1] = -250 + widget_total_width
			widget_total_width = widget_total_width - (boon_width + boon_spacing)
		end
	end
end)

--[[
	Show Potion Type, by Grundlid.
--]]
Mods.hook.set(mod_name, "GenericUnitInteractorExtension.interaction_description", function (func, self, fail_reason, interaction_type)
	if not user_setting(MOD_SETTINGS.POTION_PICKUP.save) then
		return func(self, fail_reason, interaction_type)
	end

	local interaction_type = interaction_type or self.interaction_context.interaction_type
	local interaction_template = InteractionDefinitions[interaction_type]
	local hud_description, extra_param = interaction_template.client.hud_description(self.interaction_context.interactable_unit, interaction_template.config, fail_reason, self.unit)
	local hud_description_no_failure, extra_param_no_failure = interaction_template.client.hud_description(self.interaction_context.interactable_unit, interaction_template.config, nil, self.unit)

	if hud_description == nil then
		return "<ERROR: UNSPECIFIED INTERACTION HUD DESCRIPTION>"
	end

	if hud_description and hud_description_no_failure and hud_description == "grimoire_equipped" and string.find(hud_description_no_failure, "potion") ~= nil then
		return "DONT_LOCALIZE_"..Localize("grimoire_equipped").." "..Localize(hud_description_no_failure)
	end

	return func(self, fail_reason, interaction_type)
end)

Mods.hook.set(mod_name, "Localize", function (func, id, ...)
	if user_setting(MOD_SETTINGS.POTION_PICKUP.save) and string.find(id, "DONT_LOCALIZE_") == 1 then
		return string.sub(id, 15)
	end
	return func(id, ...)
end)

--[[
	Damage Taken Scoreboard Fix, by Grundlid.
--]]
Mods.hook.set(mod_name, "GenericUnitDamageExtension.add_damage", function (func, self, attacker_unit, damage_amount, hit_zone_name, damage_type, damage_direction, damage_source_name, hit_ragdoll_actor, damaging_unit)
	if not user_setting(MOD_SETTINGS.DAMAGE_TAKEN.save) then
		return func(self, attacker_unit, damage_amount, hit_zone_name, damage_type, damage_direction, damage_source_name, hit_ragdoll_actor, damaging_unit)
	end

	local original_register_damage = StatisticsUtil.register_damage

	if Managers.player:owner(self.unit) and ScriptUnit.has_extension(self.unit, "health_system") and ScriptUnit.has_extension(self.unit, "buff_system") then
		local health_extension = ScriptUnit.extension(self.unit, "health_system")
		local buff_extension = ScriptUnit.extension(self.unit, "buff_system")

		StatisticsUtil.register_damage = function(victim_unit, damage_data, statistics_db)
			local overflow = health_extension.damage + damage_amount - health_extension.health
			if buff_extension:has_buff_type("knockdown bleed") then
				damage_data[DamageDataIndex.DAMAGE_AMOUNT] = 0
			elseif overflow > 0 then
				damage_data[DamageDataIndex.DAMAGE_AMOUNT] = damage_data[DamageDataIndex.DAMAGE_AMOUNT] - overflow
			end
			original_register_damage(victim_unit, damage_data, statistics_db)
		end
	end

	func(self, attacker_unit, damage_amount, hit_zone_name, damage_type, damage_direction, damage_source_name, hit_ragdoll_actor, damaging_unit)

	StatisticsUtil.register_damage = original_register_damage
end)

--[[
	No hp procs fx, by Grundlid.
--]]
Mods.hook.set(mod_name, "GenericStatusExtension.healed", function (func, self, reason)
	if not user_setting(MOD_SETTINGS.HP_PROCS_FX.save) then
		return func(self, reason)
	end

	if reason == "proc" and self.player.local_player then return end

	func(self, reason)
end)

--[[
	Add options for this module to the Options UI.
--]]
local function create_options()
	Mods.option_menu:add_group("hud_group", "HUD Related Mods")

	Mods.option_menu:add_item("hud_group", MOD_SETTINGS.SUB_GROUP, true)
	Mods.option_menu:add_item("hud_group", MOD_SETTINGS.ALTERNATIVE_FF_UI)
	Mods.option_menu:add_item("hud_group", MOD_SETTINGS.OVERCHARGE_BAR_DYNAMIC_MARKERS)
	Mods.option_menu:add_item("hud_group", MOD_SETTINGS.PARTY_TRINKETS_INDICATORS)
	Mods.option_menu:add_item("hud_group", MOD_SETTINGS.HOMOGENIZE_PARTY_TRINKET_ICONS)
	Mods.option_menu:add_item("hud_group", MOD_SETTINGS.POTION_PICKUP)
	Mods.option_menu:add_item("hud_group", MOD_SETTINGS.DAMAGE_TAKEN)
	Mods.option_menu:add_item("hud_group", MOD_SETTINGS.HP_PROCS_FX)
	Mods.option_menu:add_item("hud_group", MOD_SETTINGS.DODGE_TIRED)
	Mods.option_menu:add_item("hud_group", MOD_SETTINGS.FORCE_GAMEPAD_HUD)
end

local status, err = pcall(create_options)
if err ~= nil then
	EchoConsole(err)
end
