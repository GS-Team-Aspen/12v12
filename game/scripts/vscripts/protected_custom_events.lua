if not ProtectedCustomEvents then
	ProtectedCustomEvents = {}

	-- This library inject auth token(unique for each connection) into every custom event to autentificate events sended from server 
	-- Clients reject events that doesn't contain that token and thus prevent cheats that use GameEvents.SendCustomGameEventToClient
	-- Token sends to server by client after connection on UI initialization phase
	
	local player_tokens = {} -- Get player's token by entity index (of CDOTAPlayer entity), player_tokens[entindex] = token
	local player_userid = {} -- Get player's userID by entity index, player_userid[entindex] = player's user_id
	local player_entindex = {} -- Get player's entity index by userID, player_entindex[user_id] = player's entindex

	-- UserID is a unique integer given to each player who connects to a server. Never changes during game after assigned.
	-- EntityIndex of a player can change after each reconnection, since player's entity destroying after disconnect.
	-- PlayerID never changes like UserID, but for spectators or at some early games stages can be -1.

	function ProtectedCustomEvents:OnConnect(event)
		--DeepPrint(event, "OnConnect ")

		if event.bot == 1 then return end

		local entindex = event.index + 1

		player_entindex[event.userid] = entindex
		player_userid[entindex] = event.userid
	end
	ListenToGameEvent("player_connect", Dynamic_Wrap(ProtectedCustomEvents, "OnConnect"), ProtectedCustomEvents)

	CustomGameEventManager:RegisterListener("secret_token", function(user_id, event)
		if user_id == -1 then return end -- Spectators 
		local entindex = player_entindex[user_id]
		local player = PlayerInstanceFromIndex(entindex)
		--print(user_id, event.PlayerID, event.token, player, entindex)

		player_tokens[entindex] = event.token
	end)

	CCustomGameEventManager.Send_ServerToPlayerEngine = CCustomGameEventManager.Send_ServerToPlayer
	CCustomGameEventManager.Send_ServerToPlayer = function(self, player, event_name, event_data) 
		local new_table = { 
			event_data = event_data 
		}
		
		if not player or player:IsNull() then 
			print("CCustomGameEventManager.Send_ServerToPlayer: invalid player entity")
			return 
		end
		
		local player_id = player:GetPlayerID()
		local entindex = player:GetEntityIndex()
		local user_id = player_userid[entindex]

		if player_tokens[entindex] then
			new_table.chc_secret_token = player_tokens[entindex]
		elseif player_id ~= -1 and not PlayerResource:IsFakeClient(player_id) then
			print("Server have no secret token for playerID "..player_id..", userID "..user_id)
		end

		--print(player, eventName)
		--DeepPrintTable(eventData)

		CustomGameEventManager:Send_ServerToPlayerEngine(player, event_name, new_table)
	end

	CCustomGameEventManager.Send_ServerToAllClientsEngine = CCustomGameEventManager.Send_ServerToAllClients
	CCustomGameEventManager.Send_ServerToAllClients = function(self, event_name, event_data) 
		for entindex = 1,DOTA_MAX_PLAYERS do -- Possible entity indexes of players, including spectators
			local player = PlayerInstanceFromIndex(entindex)
			if player then
				CustomGameEventManager:Send_ServerToPlayer(player, event_name, event_data)
			end
		end
	end

	CCustomGameEventManager.Send_ServerToTeamEngine = CCustomGameEventManager.Send_ServerToTeam
	CCustomGameEventManager.Send_ServerToTeam = function(self, team, event_name, event_data) 
		for entindex,_ in pairs(player_tokens) do
			local player = PlayerInstanceFromIndex(entindex)
			if player and player:GetTeam() == team then
				CustomGameEventManager:Send_ServerToPlayer(player, event_name, event_data)
			end
		end
	end
end
