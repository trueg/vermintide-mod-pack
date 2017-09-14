--[[
	author: Aussiemon
 
	-----
 
	Copyright 2017 Aussiemon

	Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

	The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 
	-----
 
	Reports number of completed attempts for each level.
--]]

local command_name = "missionstats"

-- Level name lookup table
if not mod.LevelKeyLookups then
	mod.LevelKeyLookups = {
		magnus = "Horn of Magnus",
		merchant = "Supply and Demand",
		wizard = "Wizard's Tower",
		sewers_short = "Smuggler's Run",
		farm = "Wheat and Chaff",
		bridge = "Black Powder",
		forest_ambush = "Engines of War",
		cemetery = "Garden of Morr",
		courtyard_level = "Well Watch",
		end_boss = "White Rat",
		tunnels = "Enemy Below",
		city_wall = "Man the Ramparts",
		docks_short_level = "Waterfront",
		dlc_survival_ruins = "The Fall",
		dlc_survival_magnus = "Town Meeting",
		dlc_portals = "Summoner's Peak",
		dlc_castle = "Castle Drachenfels",
		dlc_castle_dungeon = "The Dungeons",
		dlc_dwarf_beacons = "Chain of Fire",
		dlc_dwarf_exterior = "Cursed Rune",
		dlc_dwarf_interior = "Khazid Kro",
		dlc_stromdorf_hills = "The Courier",
		dlc_stromdorf_town = "Reaching Out",
		dlc_challenge_wizard = "Trials of the Foolhardy",
	}
end

-- Print stats to console.
safe_pcall(function()
	if not Managers.player then
		EchoConsole("Please wait: stats not yet loaded!")
		return
	end

	local local_player = Managers.player:local_player()
	if not local_player then
		EchoConsole("Please wait: stats not yet loaded!")
		return
	end

	local stat_db = Managers.player:statistics_db()
	if not stat_db then
		EchoConsole("Please wait: stats not yet loaded!")
		return
	end

	local stats_id = local_player.stats_id(local_player)
	if not stats_id then
		EchoConsole("Please wait: stats not yet loaded!")
		return
	end

	local total_completed = 0

	EchoConsole("------------------------------")
	EchoConsole("Mission Completions")
	EchoConsole("------------------------------")

	for _, level_name in ipairs(UnlockableLevels) do

		local translated_name = mod.LevelKeyLookups[level_name] or level_name
		
		local this_completion = stat_db.get_persistent_stat(stat_db, stats_id, "completed_levels", level_name) or 0
		total_completed = total_completed + this_completion
		
		local survival_level_name = nil
		local this_total_kills = nil
		local this_veteran_waves = nil
		local this_champion_waves = nil
		local this_heroic_waves = nil
		
		if level_name == "dlc_survival_ruins" then
			survival_level_name = "ruins"
		elseif level_name == "dlc_survival_magnus" then
			survival_level_name = "magnus"
		end
		
		if survival_level_name then
			this_total_kills = 
				stat_db.get_persistent_stat(stat_db, stats_id, ("survival_dlc_survival_" .. survival_level_name .. "_survival_hard_kills")) 
				+ stat_db.get_persistent_stat(stat_db, stats_id, ("survival_dlc_survival_" .. survival_level_name .. "_survival_harder_kills")) 
				+ stat_db.get_persistent_stat(stat_db, stats_id, ("survival_dlc_survival_" .. survival_level_name .. "_survival_hardest_kills"))
			this_veteran_waves = 
				stat_db.get_persistent_stat(stat_db, stats_id, ("survival_dlc_survival_" .. survival_level_name .. "_survival_hard_waves")) 
			this_champion_waves =
				stat_db.get_persistent_stat(stat_db, stats_id, ("survival_dlc_survival_" .. survival_level_name .. "_survival_harder_waves")) 
			this_heroic_waves =
				stat_db.get_persistent_stat(stat_db, stats_id, ("survival_dlc_survival_" .. survival_level_name .. "_survival_hardest_waves"))
		end
		
		if not survival_level_name then
			EchoConsole(translated_name .. ": " .. this_completion)
		else
			EchoConsole(translated_name .. ": " .. this_total_kills .. " kills, (" .. this_veteran_waves .. ", " .. this_champion_waves .. ", " .. this_heroic_waves .. ") best waves")
		end
	end

	local total_badges = stat_db.get_persistent_stat(stat_db, stats_id, "endurance_badges")

	EchoConsole("Total Completions: " .. total_completed)
	EchoConsole("Total Endurance Badges: " .. total_badges)
	EchoConsole("------------------------------")
end)