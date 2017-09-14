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
local FF_FAKE_DAMAGE_TYPE = "knockdown_bleed"

--[[
	Setting defs.
--]]
local MOD_SETTINGS = {
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
}

Mods.hook.set(mod_name, "PlayerDamageExtension.add_damage", function(orig_func, self, attacker_unit, damage_amount, hit_zone_name, damage_type,
			damage_direction, damage_source_name, hit_ragdoll_actor, damaging_unit)

	if user_setting(MOD_SETTINGS.ALTERNATIVE_FF_UI.save) and is_player_unit(attacker_unit) and attacker_unit ~= self.unit then
		-- this type of damage is ignored by the damage indicator (see ignored_damage_types in
		-- damage_indicator_gui.lua, and also in hit_reactions.lua).
		damage_type = FF_FAKE_DAMAGE_TYPE
	end
	orig_func(self, attacker_unit, damage_amount, hit_zone_name, damage_type, damage_direction, damage_source_name, hit_ragdoll_actor, damaging_unit)
end)

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
	hp_share = { match = "medpack_spread", position = 1 },
	grenade_radius = { match = "grenade_radius", position = 3 },
	luck = { match = "increase_luck", position = luck_position },
	grim = { match = "reduce_grimoire_penalty", position = 5 },
	med_dupe = { match = "not_consume_medpack", position = 6 },
	pot_dupe = { match = "not_consume_potion", position = 7 },
	bomb_dupe = { match = "not_consume_grenade", position = 8 },
	dupe = { match = "not_consume_pickup", position = dupe_position },
}

local function get_active_trinket_slots(attachment_extn)

	local active_trinket_slots = {}
	local trinket_icons = {}
	for _, slot_name in ipairs({"slot_trinket_1", "slot_trinket_2", "slot_trinket_3"}) do
		local slot_data =  attachment_extn and attachment_extn._attachments.slots[slot_name]
		local item_key = slot_data and slot_data.item_data.key
		for _, trinket in pairs(tracked_trinkets) do
			if item_key and string.find(item_key, trinket.match) ~= nil then
				table.insert(active_trinket_slots, trinket.position)
				trinket_icons[trinket.position] = ItemMasterList[item_key].inventory_icon
			end
		end
	end
	return active_trinket_slots, trinket_icons
end

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
					local damage_type = strided_array[index + DamageDataIndex.DAMAGE_TYPE]

					-- If this damage is FF, find the HUD area of the attacking player and tell it to
					-- display the FF indicator.
					if damage_type == FF_FAKE_DAMAGE_TYPE and is_player_unit(attacker) and attacker ~= player_unit then
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
				local active_trinket_slots, trinket_icons = {}, {}
				if attachment_extn then
					active_trinket_slots, trinket_icons = get_active_trinket_slots(attachment_extn)
				end
				if unit_frame.data._hudmod_active_trinket_slots ~= active_trinket_slots then
					unit_frame.data._hudmod_active_trinket_slots = active_trinket_slots
					unit_frame.data._hudmod_trinket_icons = trinket_icons
					self._dirty = true
				end
			end
		end
	end
	return orig_func(self, dt, t, my_player)
end)

Mods.hook.set(mod_name, "UnitFrameUI.draw", function(orig_func, self, dt)
	local data = self.data
	if self._is_visible and (data._hudmod_ff_state ~= nil or data._hudmod_active_trinket_slots) then
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

			for i=1,9 do
				widget.content["trinket_"..i].show = false
				if table.has_item(data._hudmod_active_trinket_slots or {}, i) then
					if i < 6 or table.has_item(data._hudmod_active_trinket_slots or {}, i-5) then
						widget.content["trinket_"..i].show = true
						widget.content["trinket_"..i].texture_id = data._hudmod_trinket_icons[i]
					elseif i == dupe_position then
						widget.content["trinket_"..luck_position].show = true
						widget.content["trinket_"..luck_position].texture_id = data._hudmod_trinket_icons[i]
					end
				end
			end

			UIRenderer.draw_widget(ui_renderer, widget)
		end

		UIRenderer.end_pass(ui_renderer)
	end

	return orig_func(self, dt)
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
	Add options for this module to the Options UI.
--]]
local function create_options()
	Mods.option_menu:add_group("hud", "HUD Goodies")

	Mods.option_menu:add_item("hud", MOD_SETTINGS.ALTERNATIVE_FF_UI, true)
	Mods.option_menu:add_item("hud", MOD_SETTINGS.OVERCHARGE_BAR_DYNAMIC_MARKERS, true)
	Mods.option_menu:add_item("hud", MOD_SETTINGS.PARTY_TRINKETS_INDICATORS, true)
	Mods.option_menu:add_item("hud", MOD_SETTINGS.POTION_PICKUP, true)
	Mods.option_menu:add_item("hud", MOD_SETTINGS.DAMAGE_TAKEN, true)
end

local status, err = pcall(create_options)
if err ~= nil then
	EchoConsole(err)
end