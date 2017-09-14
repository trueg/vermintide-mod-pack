local mod_name = "SkipCutscenes"

local oi = OptionsInjector

SkipCutscenes = {
	SETTINGS = {
		ACTIVE = {
			["save"] = "cb_skip_level_cutscenes",
			["widget_type"] = "stepper",
			["text"] = "Skip Level Cutscenes",
			["tooltip"] =  "Skip Level Cutscenes\n" ..
				"Toggle skip level cutscenes on / off.\n\n" ..
				"Lets you skip the cutscenes at the beginning of a map by pressing [Space].",
			["value_type"] = "boolean",
			["options"] = {
				{text = "Off", value = false},
				{text = "On", value = true},
			},
			["default"] = 1, -- Default first option is enabled. In this case Off
		},
	},
}
local me = SkipCutscenes

local get = Application.user_setting
local set = Application.set_user_setting
local save = Application.save_user_settings

-- ####################################################################################################################
-- ##### Options ######################################################################################################
-- ####################################################################################################################
SkipCutscenes.create_options = function()
	Mods.option_menu:add_item("system", me.SETTINGS.ACTIVE, true)
end

-- ####################################################################################################################
-- ##### Hook #########################################################################################################
-- ####################################################################################################################
Mods.hook.set(mod_name, "MatchmakingManager.update", function(func, ...)
	func(...)
	
	if script_data ~= nil then
		if get(me.SETTINGS.ACTIVE.save) then
			script_data.skippable_cutscenes = true
		else
			script_data.skippable_cutscenes = false
		end	
	end
end)

-- ####################################################################################################################
-- ##### Start ########################################################################################################
-- ####################################################################################################################
me.create_options()