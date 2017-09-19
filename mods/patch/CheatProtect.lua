local mod_name = "CheatProtect"

--#### Item Spawning #######################

local NoCheatItemCount = {
	itemcount = -1,
	sender = nil
}

local NoCheatPosition = nil

local NoCheatTrade = {}

Mods.hook.set(mod_name, "InventorySystem.rpc_add_equipment",
function(func, self, sender, go_id, slot_id, item_name_id)
	func(self, sender, go_id, slot_id, item_name_id)
	if slot_id == 7 or slot_id == 8 or slot_id == 9 then
		local unit_storage = Managers.state.unit_spawner.unit_storage
		local items = unit_storage.map_goid_to_unit
		local count = 0
	
		for go_id, unit in pairs(items) do
			count = count + 1
		end

		NoCheatItemCount.itemcount = count
		NoCheatItemCount.sender = sender
		local player = Managers.player:player_from_peer_id(sender, 1)
		NoCheatPosition = POSITION_LOOKUP[player.player_unit]

		local is_a_trade = false
		if NoCheatTrade[sender] then
			local item_name = NetworkLookup.item_names[item_name_id]
			local item_data = ItemMasterList[item_name]
			if BackendUtils.get_item_template(item_data).pickup_data then
				local pickup_name = BackendUtils.get_item_template(item_data).pickup_data.pickup_name
				local pickup_name_id = NetworkLookup.pickup_names[pickup_name]
				for i, item in pairs(NoCheatTrade[sender]) do
					if item == pickup_name_id and not is_a_trade then
						is_a_trade = true
						NoCheatTrade[sender][i] = nil
					end
				end
			end
		end
	end
end)

Mods.hook.set(mod_name, "PickupSystem.rpc_spawn_pickup",
function(func, self, sender, pickup_name_id, position, rotation, spawn_type_id)
	local player = Managers.player:player_from_peer_id(sender, 1)

	local unit_storage = Managers.state.unit_spawner.unit_storage
	local items = unit_storage.map_goid_to_unit
	local count = 0
	
	for go_id, unit in pairs(items) do
		count = count + 1
	end

	if not (sender == Network.peer_id() or (count == NoCheatItemCount.itemcount and sender == NoCheatItemCount.sender)) then
		Managers.chat:send_system_chat_message(1, "CheatProtect : Blocked player '" .. player._cached_name .. "' attempted RPC_SPAWN_PICKUP (without physics) for item " .. NetworkLookup.pickup_names[pickup_name_id] .. ".", 0, true)
		return
	end
	func(self, sender, pickup_name_id, position, rotation, spawn_type_id)
end)

Mods.hook.set(mod_name, "PickupSystem.rpc_spawn_pickup_with_physics",
function(func, self, sender, pickup_name_id, position, rotation, spawn_type_id)
	local player = Managers.player:player_from_peer_id(sender, 1)
	if Unit.alive(player.player_unit) then
		local status_extension = ScriptUnit.extension(player.player_unit, "status_system")
		local position = POSITION_LOOKUP[player.player_unit]
		local is_a_trade = false
		
		if NoCheatTrade[sender] then
			for i, item in pairs(NoCheatTrade[sender]) do
				if item == pickup_name_id and not is_a_trade then
					is_a_trade = true
					NoCheatTrade[sender][i] = nil
				end
			end
		end

		if not (sender == Network.peer_id() or (status_extension and status_extension.dead) or (position == NoCheatPosition) or (is_a_trade)) then
			Managers.chat:send_system_chat_message(1, "CheatProtect : Blocked player '" .. player._cached_name .. "' attempted RPC_SPAWN_PICKUP_WITH_PHYSICS for item " .. NetworkLookup.pickup_names[pickup_name_id] .. ".", 0, true)
			return
		end
	end
	func(self, sender, pickup_name_id, position, rotation, spawn_type_id)
end)

Mods.hook.set(mod_name, "InventorySystem.rpc_give_equipment",
function(func, self, sender, game_object_id, slot_id, item_name_id, position)
	func(self, sender, game_object_id, slot_id, item_name_id, position)
	local unit = self.unit_storage:unit(game_object_id)
	if Unit.alive(unit) and not ScriptUnit.extension(unit, "status_system"):is_dead() then
		local owner = Managers.player:owner(unit)
		if owner.remote then
			local item_name = NetworkLookup.item_names[item_name_id]
			local item_data = ItemMasterList[item_name]
			local pickup_name = BackendUtils.get_item_template(item_data).pickup_data.pickup_name
			local pickup_name_id = NetworkLookup.pickup_names[pickup_name]
			local victim = owner.network_id(owner)

			if not NoCheatTrade[victim] then
				NoCheatTrade[victim] = {}
			end

			NoCheatTrade[victim][#NoCheatTrade[victim] + 1] = pickup_name_id
		end
	end
end)

Mods.hook.set(mod_name, "GameNetworkManager.game_object_created", function(func, self, go_id, owner_id)
	local go_type_id = GameSession.game_object_field(self.game_session, go_id, "go_type")
	local go_type = NetworkLookup.go_types[go_type_id]

	if tostring(go_type) == "pickup_unit" and owner_id ~= Network.peer_id() and Managers.player.is_server then
		local player = Managers.player:player_from_peer_id(owner_id, 1)
		local item_name_id = GameSession.game_object_field(Managers.state.network:game(), go_id, "pickup_name")
		local item_name = NetworkLookup.pickup_names[item_name_id]

		Managers.chat:send_system_chat_message(1, "CheatProtect : Blocked player '" .. player._cached_name .. "' attempted spawning non-owned item '" .. item_name .. "'. This is an advanced anti-cheat bypass attempt, immediate removal of the player is recommended.", 0, true)
		return
	end

	func(self, go_id, owner_id)
end)

--#### Heal Requests #######################

Mods.hook.set(mod_name, "DamageSystem.rpc_request_heal",
function(func, self, sender, unit_go_id, heal_amount, heal_type_id)
	local player = Managers.player:player_from_peer_id(sender, 1)
	local heal_type = NetworkLookup.heal_types[heal_type_id]
	local unit = self.unit_storage:unit(unit_go_id)
	local health_extension = ScriptUnit.extension(unit, "health_system")
	local current_damage = health_extension.current_damage(health_extension)

	if (heal_amount > 120 and heal_type ~= "buff") 
	or (heal_type == "bandage" and heal_amount ~= round(current_damage * 0.8, 3))
	or (heal_type == "proc" and heal_amount ~= 5 and heal_amount ~= 10 and heal_amount ~= 40) 
	or (heal_type == "healing_draught" and heal_amount ~= 75) 
	or (heal_type == "bandage_trinket" and heal_amount > round(current_damage * 0.2, 3))
	or (heal_type == "potion" or heal_type == "buff_shared_medpack" or heal_type == "heal_on_killing_blow")
	or (heal_type == "buff" and (heal_amount ~= 150 and heal_amount ~= 100))
	or (heal_type == "buff" and Managers.state.game_mode._game_mode_key ~= "inn") then 
		Managers.chat:send_system_chat_message(1, "CheatProtect : Blocked player '" .. player._cached_name .. "' attempted heal for " .. heal_amount .. " with heal type " .. heal_type .. ".", 0, true)
		return
	end

	func(self, sender, unit_go_id, heal_amount, heal_type_id)
	return
end)


--#### Teleport protection ##################

Mods.hook.set(mod_name, "LocomotionSystem.rpc_teleport_unit_to", function(func, self, sender, game_object_id, position, rotation)
	local local_player = Managers.player:local_player()
	local target_unit = self.unit_storage:unit(game_object_id)
	local player = Managers.player:player_from_peer_id(sender, 1)
	
	-- Server can not get this rpc call
	-- Nobody can teleport you to a different position
	if Managers.player.is_server or (target_unit and local_player and local_player.player_unit == target_unit) then
		local victim_name = "UNKNOWN"
		for _, player in pairs(Managers.player:human_players()) do
			if player.player_unit == target_unit then
				victim_name = player._cached_name
			end
		end

		if Managers.player.is_server then
			Managers.chat:send_system_chat_message(1, "CheatProtect : Blocked player '" .. player._cached_name .. "' attempted RPC_TELEPORT_UNIT_TO on '" .. victim_name .. "'.", 0, true)
		else
			Managers.chat:send_system_chat_message(1, "CheatProtect [By " .. local_player._cached_name .. "] : Blocked player '" .. player._cached_name .. "' attempted RPC_TELEPORT_UNIT_TO on '" .. victim_name .. "'.", 0, true)
		end
		return
	end
	
	func(self, sender, game_object_id, position, rotation)
end)

--#### Chat impersonation ###################
Mods.hook.set(mod_name, "ChatManager.rpc_chat_message",
function(func, self, sender, channel_id, message_sender, message, localization_param, is_system_message, pop_chat, is_dev)
	if Managers.player.is_server then
		--[[
			If someone sends a message is a different peer_id
		]]--
		if sender ~= message_sender then
			local player = Managers.player:player_from_peer_id(sender, 1)
			local victim = Managers.player:player_from_peer_id(message_sender, 1)
			
			if player and victim then
				-- Cheater Detected
				Managers.chat:send_system_chat_message(1, "CheatProtect : Blocked player '" .. player._cached_name .. "' attempted chat impersonation of player '" .. victim._cached_name .. "'.", 0, true)
				return
			end
		end
	else
		--[[
			If someone sends a rpc_chat_message with message_sender as our peer_id
			it needs to be reported.
			The case is, people send message as a proxy through the server,
			This means the "sender" parameter is always the server peer_id. We can
			not know for sure who it officially sended the orginal message.
		]]--
		local local_player = Managers.player:local_player()
		
		if local_player and local_player.peer_id == message_sender then
			-- Cheater Detected
			Managers.chat:send_system_chat_message(1, "CheatProtect [By " .. local_player._cached_name .. "] : The above message by " .. local_player._cached_name .. " was not sent by that player, but by an impersonator in the lobby.", 0, true)
		end
	end
	
	func(self, sender, channel_id, message_sender, message, localization_param, is_system_message, pop_chat, is_dev)
end)
