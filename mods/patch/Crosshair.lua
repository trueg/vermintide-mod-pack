local mod_name = "Crosshair"

local oi = OptionsInjector

local preserve_default_sized
if Crosshair and Crosshair.default_sizes then
	preserve_default_sized = Crosshair.default_sizes
end

local Default = 1
local Red = 2
local Green = 3

local enlarge_off = 1
local enlarge_slightly = 2
local enlarge_heavily = 3

Crosshair = {
	SETTINGS = {
		SHOW = "cb_crosshair",
		COLOR = "cb_crosshair_color",
		ENLARGE = "cb_crosshair_enlarge",
	},

	SETTINGS = {
		COLOR = {
			["save"] = "cb_crosshair_color",
			["widget_type"] = "dropdown",
			["text"] = "Color",
			["tooltip"] =  "Color\n" ..
				"Changes the color of your crosshair.",
			["value_type"] = "number",
			["options"] = {
				{text = "Default", value = Default},
				{text = "Red", value = Red},
				{text = "Green", value = Green},
			},
			["default"] = Default,
		},
		ENLARGE = {
			["save"] = "cb_crosshair_enlarge",
			["widget_type"] = "stepper",
			["text"] = "Enlarge",
			["tooltip"] =  "Enlarge\n" ..
				"Increases the size of your crosshair.",
			["value_type"] = "number",
			["options"] = {
				{text = "Off", value = enlarge_off},
				{text = "Slightly", value = enlarge_slightly},
				{text = "Heavily", value = enlarge_heavily},
			},
			["default"] = enlarge_off,
		},
	},
}

if preserve_default_sized then
	Crosshair.default_sizes = preserve_default_sized
end

local me = Crosshair

local get = function(data)
	return Application.user_setting(data.save)
end
local set = Application.set_user_setting
local save = Application.save_user_settings

local colors = {
	{255, 255, 255, 255},
	{255, 255, 0, 0},
	{255, 0, 255, 0},
}


-- ####################################################################################################################
-- ##### Options ######################################################################################################
-- ####################################################################################################################
Crosshair.create_options = function()
	Mods.option_menu:add_group("crosshair_customizations", "Crosshair Customizations")

	Mods.option_menu:add_item("crosshair_customizations", me.SETTINGS.COLOR, true)
	Mods.option_menu:add_item("crosshair_customizations", me.SETTINGS.ENLARGE, true)
end

local populate_defaults = function(self)
	if not Crosshair.default_sizes then
		Crosshair.default_sizes = {
			crosshair_dot = table.clone(self.ui_scenegraph.crosshair_dot.size),
			crosshair_up = table.clone(self.ui_scenegraph.crosshair_up.size),
			crosshair_down = table.clone(self.ui_scenegraph.crosshair_down.size),
			crosshair_left = table.clone(self.ui_scenegraph.crosshair_left.size),
			crosshair_right = table.clone(self.ui_scenegraph.crosshair_right.size),
		}
	end
end

local change_crosshair_color = function(self)
  self.crosshair_dot.style.color = colors[get(me.SETTINGS.COLOR)]
	self.crosshair_up.style.color = colors[get(me.SETTINGS.COLOR)]
	self.crosshair_down.style.color = colors[get(me.SETTINGS.COLOR)]
	self.crosshair_left.style.color = colors[get(me.SETTINGS.COLOR)]
	self.crosshair_right.style.color = colors[get(me.SETTINGS.COLOR)]

  if not self.hit_marker_animations[1] then
    for i,v in ipairs(self.hit_markers) do
      v.style.rotating_texture.color = table.clone(colors[get(me.SETTINGS.COLOR)])
      v.style.rotating_texture.color[1] = 0
    end
  end
end

local change_crosshair_scale = function(self)
  local crosshair_dot_scale = 1
  local crosshair_lines_scale = 1

  if get(me.SETTINGS.ENLARGE) == enlarge_slightly then
    crosshair_dot_scale = 1.5
    crosshair_lines_scale = 1.2
  elseif get(me.SETTINGS.ENLARGE) == enlarge_heavily then
    crosshair_dot_scale = 2
    crosshair_lines_scale = 1.5
  end

  for k,v in pairs(Crosshair.default_sizes) do
    for i,v in ipairs(Crosshair.default_sizes[k]) do
      self.ui_scenegraph[k].size[i] = v * crosshair_lines_scale
    end
  end

  for i,v in ipairs(Crosshair.default_sizes.crosshair_dot) do
    self.ui_scenegraph.crosshair_dot.size[i] = v * crosshair_dot_scale
  end
end

Mods.hook.set(mod_name, "CrosshairUI.draw_dot_style_crosshair", function(func, self, ...)

	populate_defaults(self)

	change_crosshair_scale(self)
	change_crosshair_color(self)

    return func(self, ...)
end)

Mods.hook.set(mod_name, "CrosshairUI.draw_default_style_crosshair", function(func, self, ...)

	populate_defaults(self)

	change_crosshair_scale(self)
	change_crosshair_color(self)

    return func(self, ...)
end)

Crosshair.create_options()
