Managers.state.debug.time_paused = not Managers.state.debug.time_paused
if Managers.state.debug.time_paused then
	Managers.state.debug.set_time_paused(Managers.state.debug)
	EchoConsole("Pause game On")
else
	Managers.state.debug.set_time_scale(Managers.state.debug, Managers.state.debug.time_scale_index)
	EchoConsole("Pause game Off")
end