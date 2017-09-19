Mods.init = function()
	Mods.exec("", "CommandList")

	Mods.exec("patch/function", "Table")
	Mods.exec("patch/function", "Mods.hook")
	Mods.exec("patch/function", "Mods.chat")
	Mods.exec("patch/function", "Mods.keyboard")
	Mods.exec("patch/function", "Mods.whisper")
	Mods.exec("patch/function", "Mods.ban")
	Mods.exec("patch/function", "Mods.network")

	Mods.exec("patch/function", "Mods.gui")
	Mods.exec("patch/function", "Mods.debug")
	Mods.exec("patch/function", "Mods.ui")

	Mods.exec("patch/options", "Mods.option_menu")

	Mods.exec("patch/options", "Keyboard")
	Mods.exec("patch/options", "OptionsInjector")

	Mods.exec("patch", "AnimationFix")
	Mods.exec("patch", "CheatProtect")
	Mods.exec("patch", "PlayerListPing")
	Mods.exec("patch", "PlayerListKickBan")
	Mods.exec("patch", "PlayerListShowEquipment")
	Mods.exec("patch", "LoadoutSaver")
	Mods.exec("patch", "InventoryFiltering")
	Mods.exec("patch", "BotImprovements")
	Mods.exec("patch", "ThirdPerson")
	Mods.exec("patch", "HealthBar")
	Mods.exec("patch", "ShowDamage")
	Mods.exec("patch", "ChatBlock")
	Mods.exec("patch", "Crosshair")
	Mods.exec("patch", "AmmoMeters")
	Mods.exec("patch", "HUDMods")
	Mods.exec("patch", "HUDToggle")
	Mods.exec("patch", "TrueflightTweaks")
	Mods.exec("patch", "LuckAndDupeIndicators")
	Mods.exec("patch", "UITimers")
	Mods.exec("patch", "SaveGrimoire")
	Mods.exec("patch", "WeaponSwitching")
	Mods.exec("patch", "ThirdPersonEquipment_Definitions")
	Mods.exec("patch", "ThirdPersonEquipment")
	Mods.exec("patch", "LobbyImprovements")
	Mods.exec("patch", "SkinDisabler")
	Mods.exec("patch", "MutatorSelector")
	Mods.exec("patch", "ChangeWeaponModelsWarning")
	
	-- Unstable mod loaded only if the warning setting is enabled.
	if Application.user_setting("cb_weapon_model_warning") then
		Mods.exec("patch", "ChangeWeaponModels")
	end

	Mods.exec("patch", "PauseGame")
	Mods.exec("patch", "SkipCutscenes")
	
	--Additional mods go here :
	--Mods.exec("patch", "Mod file name here")



	-- Draw options menu
	Mods.option_menu:draw()
end
Mods.init()