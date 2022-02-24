SyncedChat = SyncedChat or {}


function SyncedChat:Init()
	SyncedChat.poll_delay = 60
	
	SyncedChat.current_messages = {}
	
	RegisterCustomEventListener("synced_chat:send", function(data) SyncedChat:Send(data) end)
	RegisterCustomEventListener("synced_chat:request_inital", function(data) SyncedChat:SendInitialMessages(data) end)
	RegisterCustomEventListener("synced_chat:get_older_messages", function(data) SyncedChat:GetOlderMessages(data) end)
	RegisterCustomEventListener("synced_chat:window_state", function(data) SyncedChat:SetWindowState(data) end)
	SyncedChat.last_seen_id = 0

	SyncedChat.player_windows_state = {}
	SyncedChat.muted_players = {}
	for i = 0, 24 do
		SyncedChat.player_windows_state[i] = false
	end

	self.last_page = 1
end


function SyncedChat:GetOlderMessages()
	WebApi:Send(
		"match/get_older_messages",
		{
			customGame = WebApi.customGame,
			pageNum = self.last_page + 1,
		},
		function(response)
			self.last_page = self.last_page + 1

			for key, val in pairs(response) do
				if SyncedChat.current_messages[val.id] then
					response[key] = nil
				else
					SyncedChat.current_messages[val.id] = val
					if val.id > SyncedChat.last_seen_id then SyncedChat.last_seen_id = val.id end
				end
			end
			CustomGameEventManager:Send_ServerToAllClients("synced_chat:add_older_messages", response)
		end
	)
end


function SyncedChat:Poll(b_ping)
	WebApi:Send(
		"match/poll_chat_messages",
		{
			customGame = WebApi.customGame,
			lastSeenMessageId = SyncedChat.last_seen_id > 0 and SyncedChat.last_seen_id or nil,
		},
		function(response)
			CustomGameEventManager:Send_ServerToAllClients("synced_chat:poll_result", {
				msg = response,
				ping = b_ping,
				pool_delay = self.poll_delay,
			})
			for _, val in pairs(response) do
				SyncedChat.current_messages[val.id] = val
				if val.id > SyncedChat.last_seen_id then SyncedChat.last_seen_id = val.id end
			end
		end
	)
end


function SyncedChat:Send(data)
	local player_id = data.PlayerID
	if not player_id then return end
	
	local supp_level = Supporters:GetLevel(player_id)
	if not supp_level or supp_level <= 0 then return end
	
	if data.text and data.text == "" then return end

	if self.muted_players[player_id] then return end

	local anon = data.anon == 1

	WebApi:Send(
		"match/send_chat_message",
		{
			customGame = WebApi.customGame,
			steamId = data.steamId,
			steamName = data.steamName,
			text = data.text,
			anon = anon,
			supporterLevel = supp_level
		},
		function(resp)
			if resp.id > SyncedChat.last_seen_id then SyncedChat.last_seen_id = resp.id end
			CustomGameEventManager:Send_ServerToAllClients("synced_chat:message_sent", resp)
		end,
		function(err)
			print("failed to sent message: ", err)
			if err and type(err) == "table" and err.status_code and err.status_code == 403 and err.body then
				local unmute_date
				if string.match(err.body, "^Source player is muted until ") then
					unmute_date = string.gsub(err.body, "^Source player is muted until ", "")
				end
				if unmute_date then self:MutePlayer(player_id, unmute_date, true) end
			end
		end
	)
end

function SyncedChat:InitSchedule()
	SyncedChat:Poll(false)
	SyncedChat.poll_delay = 20
	
	Timers:CreateTimer("sync_chat:poll_timer", {
		useGameTime = false,
		endTime = SyncedChat.poll_delay,
		callback = function()
			SyncedChat:Poll(true)
			return SyncedChat.poll_delay
		end
	})
end

function SyncedChat:SetWindowState(data)
	local player_id = data.PlayerID
	if not player_id then return end

	local b_open = data.state == 1

	if not self.first_open and b_open then
		self.first_open = true
		self:InitSchedule()
	end
	
	SyncedChat.player_windows_state[player_id] = b_open

	-- set poll delay shorter if anyone is having chat open
	for p_id, state in pairs(SyncedChat.player_windows_state) do
		if state then
			SyncedChat.poll_delay = 20
			return
		end
	end
	SyncedChat.poll_delay = 60
end


function SyncedChat:SendInitialMessages(data)
	local player_id = data.PlayerID
	if not player_id then return end
	
	local player = PlayerResource:GetPlayer(player_id)
	
	if player and not player:IsNull() then
		CustomGameEventManager:Send_ServerToPlayer(player, "synced_chat:poll_result", {
			msg = SyncedChat.current_messages, 
			account_id = PlayerResource:GetSteamAccountID(player_id) or nil,
			unmute_date = self.muted_players[player_id]
		})
	end
end

function SyncedChat:MutePlayer(player_id, date, b_update_client)
	self.muted_players[player_id] = date

	if b_update_client then
		local player = PlayerResource:GetPlayer(player_id)
		CustomGameEventManager:Send_ServerToPlayer(player, "synced_chat:mute", { unmute_date = date })
	end
end
