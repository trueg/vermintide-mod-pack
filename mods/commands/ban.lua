if Mods.ban.kicked.peer_id ~= "" then
	Mods.ban.add_player(Mods.ban.kicked.peer_id, Mods.ban.kicked.name)
	
	-- Confirmation message
	EchoConsole("Banned player " .. Mods.ban.kicked.name .. ".")
	
	-- remove data
	Mods.ban.kicked.peer_id = ""
	Mods.ban.kicked.name = ""
else
	EchoConsole("There are no recently kicked players to ban.")
end