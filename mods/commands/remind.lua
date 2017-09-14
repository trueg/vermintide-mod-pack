--[[
    author: Aussiemon
 
    -----
 
    Copyright 2017 Aussiemon
 
    Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
    The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 
    -----
   
    Allows the player to input a string that will reappear at the end of a mission.
--]]
 
local command_name = "remind"
 
local auto_clear_after_display = true -- Set to false to prevent the auto-clear of reminders after they display for the first time.
 
-- Initialize reminder_string global
if not reminder_string then
    reminder_string = ""
end
 
-- Hook the scoreboard function to play back reminders upon entry
if not ScoreboardUI_on_enter_hooked then
    Mods.hook.set(mod_name, "ScoreboardUI.on_enter", function (func, self, ignore_input_blocking)
       
        -- Playback reminders and show chat window
        if reminder_string ~= "" then
            EchoConsole("============ REMINDER: ============\n" .. reminder_string .. "\n===================================")
            if not Managers.chat:chat_is_focused() then
                local chat_gui = Managers.chat.chat_gui
                chat_gui:show_chat()
            end
            if auto_clear_after_display then
                reminder_string = ""
            end
        end
       
        -- Original function continues
        local result = func(self, ignore_input_blocking)
        return result
    end)
    ScoreboardUI_on_enter_hooked = true
end
 
-- Process reminders with respect to existing reminders, use "clear" to reset.
local args = {...}
if #args > 0 then
    local this_reminder = ""
   
    -- Start new line if existing reminders
    if reminder_string ~= "" then
        reminder_string = reminder_string .. "\n"
    end
   
    -- Process/format arguments into a new reminder
    for key, value in pairs(args) do
        if type(value) == "string" then
            if reminder_string ~= "" then
                reminder_string = reminder_string .. " " .. value
            else
                reminder_string = value
            end
            this_reminder = this_reminder .. value
        elseif type(value) == "table" then
            for value_key, value_value in pairs(value) do
                if type(value_value) == "string" then
                    if reminder_string ~= "" then
                        reminder_string = reminder_string .. " " .. value_value
                    else
                        reminder_string = value_value
                    end
                    this_reminder = this_reminder .. value_value
                end
            end
        end
    end
   
    -- Make sure this isn't a clearing command before confirming saved reminder
    if this_reminder ~= " clear" and this_reminder ~= "clear" then
        EchoConsole("Reminder saved: " .. this_reminder)
    else
        reminder_string = ""
        EchoConsole("Reminders cleared!")
    end
else
    if reminder_string == "" then
        EchoConsole("No reminder given!")
    end
end