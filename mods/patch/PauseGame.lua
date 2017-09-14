local mod_name = "PauseGame"
--[[
	PauseGame:
		Pauses and unpauses game
		/freezeall
--]]


local oi = OptionsInjector

GiveOtherItems = {
	SETTINGS = {		
		PAUSE = {
			["save"] = "cb_pause_game_hotkey",
			["widget_type"] = "keybind",
			["text"] = "Pause Game",
			["default"] = {
				"p",
				oi.key_modifiers.CTRL_SHIFT,
			},
			["exec"] = {"commands", "freezeall"},
		},
	},
}

local me = GiveOtherItems

GiveOtherItems.create_options = function()
	Mods.option_menu:add_item("cheats", me.SETTINGS.PAUSE, true)
end

me.create_options()