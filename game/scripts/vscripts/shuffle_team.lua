ShuffleTeam = class({})
DEFAULT_MMR = 1500
BASE_BONUS = 5
MIN_DIFF = 150
BONUS_MMR_STEP = 100
BONUS_FOR_STEP = 2
MAX_BONUS = 100
MAX_PLAYERS_IN_TEAM = 12
LinkLuaModifier("modifier_bonus_for_weak_team_in_mmr", "modifier_bonus_for_weak_team_in_mmr", LUA_MODIFIER_MOTION_NONE)

function ShuffleTeam:SortInMMR()
	if GameOptions:OptionsIsActive("no_mmr_sort") then
		return
	end
	self.multGold = 1
	self.weakTeam = 0
	self.mmrDiff = 0
	local players = {}
	local playersStats = CustomNetTables:GetTableValue("game_state", "player_stats");
	if not playersStats then return end
	
	for playerId = 0, 23 do
		local player_id_str = tostring(playerId)
		if not playersStats[player_id_str] then
			playersStats[player_id_str] = {
				rating = DEFAULT_MMR
			}
		end
		local playerRating = playersStats[player_id_str].rating and playersStats[player_id_str].rating or 0
		local partyID = tostring(PlayerResource:GetPartyID(playerId))
		players[playerId] = {
			mmr = playerRating
		}
		if PlayerResource:GetConnectionState(playerId) == DOTA_CONNECTION_STATE_NOT_YET_CONNECTED or partyID ~= "0" then
			players[playerId].partyID = partyID
		end
	end
	
	local teams = { [2] = { players = {}, mmr = 0}, [3] = { players = {}, mmr = 0}}
	local parties = {}
	local players_for_sorting = {}

	for playerId, data in pairs(players) do
		local partyID = data.partyID
		if partyID then
			parties[partyID] = parties[partyID] or {}
			parties[partyID].players = parties[partyID].players or {}
			parties[partyID].mmr = (parties[partyID].mmr or 0) + data.mmr
			table.insert(parties[partyID].players, playerId)
		else
			table.insert(players_for_sorting, { players = { playerId }, mmr = data.mmr})
		end
	end
	for _, data in pairs(parties) do
		table.insert(players_for_sorting, data)
	end
	
	table.sort(players_for_sorting, function(a,b)
		return a.mmr > b.mmr
	end)

	local SortTeam = function(MinDiffPlayersCount)
		for _, partyData in pairs(players_for_sorting) do
			if #partyData.players >= MinDiffPlayersCount and not partyData.sorted then
				partyData.sorted = true
				local teamId = 2
				if teams[teamId].mmr > teams[3].mmr then
					teamId = 3
				end

				if (#teams[teamId].players + #partyData.players) > MAX_PLAYERS_IN_TEAM then
					teamId = teamId == 2 and 3 or 2
				end
				
				for _, playerId in pairs(partyData.players) do
					if (#teams[teamId].players + 1) > MAX_PLAYERS_IN_TEAM then
						teamId = teamId == 2 and 3 or 2
					end
					table.insert(teams[teamId].players, playerId)
					teams[teamId].mmr = (teams[teamId].mmr or 0) + players[playerId].mmr
				end
			end
		end
	end
	SortTeam(2)
	SortTeam(1)
	GameRules:SetCustomGameTeamMaxPlayers(DOTA_TEAM_GOODGUYS, 13)
	GameRules:SetCustomGameTeamMaxPlayers(DOTA_TEAM_BADGUYS, 13)
	local set_team = function(player_id, team_id)
		local player = PlayerResource:GetPlayer(player_id)
		if player then
			player:SetTeam(team_id)
		end
		PlayerResource:SetCustomTeamAssignment(player_id, team_id)
	end
	for player_id = 0, 23 do
		set_team(player_id, DOTA_TEAM_NOTEAM)
	end
	for team_id, team_data in pairs(teams) do
		for _, player_id in pairs(team_data.players) do
			if PlayerResource:GetPlayerCountForTeam(team_id) >= MAX_PLAYERS_IN_TEAM then
				team_id = team_id == 2 and 3 or 2
			end
			set_team(player_id, team_id)
		end
	end
	GameRules:SetCustomGameTeamMaxPlayers(DOTA_TEAM_GOODGUYS, 12)
	GameRules:SetCustomGameTeamMaxPlayers(DOTA_TEAM_BADGUYS, 12)
	self.weakTeam = teams[2].mmr < teams[3].mmr and 2 or 3
	self.mmrDiff = math.abs(math.floor(teams[2].mmr/MAX_PLAYERS_IN_TEAM) - math.floor(teams[3].mmr/MAX_PLAYERS_IN_TEAM))
	
	--DEBUG PRINT PART
	for teamId,teamData in pairs(teams) do
		AutoTeam:Debug("", true)
		AutoTeam:Debug("Team: ["..teamId.."]", true)
		for id, playerId in pairs(teamData.players) do
			AutoTeam:Debug(id .. " pid: "..playerId .. "	> "..playerId.." MMR: "..players[playerId].mmr .. " TEAM: ".. (players[playerId].partyID or "0"), true)
		end
	end
	AutoTeam:Debug("", true)
	AutoTeam:Debug("Team 2 averages MMR: " .. math.floor(teams[2].mmr/MAX_PLAYERS_IN_TEAM), true)
	AutoTeam:Debug("Team 3 averages MMR: " .. math.floor(teams[3].mmr/MAX_PLAYERS_IN_TEAM), true)
end

function ShuffleTeam:SendNotificationForWeakTeam()
	if GameOptions:OptionsIsActive("no_bonus_for_weak_team") or GameOptions:OptionsIsActive("no_mmr_sort") then
		return
	end
	if not self.bonusPct then return end
	CustomGameEventManager:Send_ServerToTeam(self.weakTeam, "WeakTeamNotification", { goldPct = self.bonusPct, expPct = self.bonusExp, mmrDiff = self.mmrDiff})
end

function ShuffleTeam:GiveBonusToHero(playerId)
	local hero = PlayerResource:GetSelectedHeroEntity(playerId)
		
	-- Check if player has a hero yet
	if hero and hero:IsAlive() then
		-- Apply weak team modifier granting bonus xp and gold gain based on difference in MMR between teams
		hero:AddNewModifier(hero, nil, "modifier_bonus_for_weak_team_in_mmr", { duration = -1, bonusPct = self.bonusExp })
		return
	end
	
	-- Keep checking every 2 seconds until player has a hero
	Timers:CreateTimer(2, function()
		self:GiveBonusToHero(playerId)
	end)
end

function ShuffleTeam:GiveBonusToWeakTeam()
	if GameOptions:OptionsIsActive("no_bonus_for_weak_team") or GameOptions:OptionsIsActive("no_mmr_sort") then
		return
	end
	if self.mmrDiff < MIN_DIFF then return end
	self.bonusPct = math.min(BASE_BONUS + (math.floor((self.mmrDiff - MIN_DIFF) / BONUS_MMR_STEP)) * BONUS_FOR_STEP, MAX_BONUS)
	self.multGold = 1 + self.bonusPct / 100
	self.bonusExp = self.bonusPct / 2
	for playerId = 0, 23 do
		if PlayerResource:GetTeam(playerId) == self.weakTeam then
			self:GiveBonusToHero(playerId)
		end
	end
end
