local BASE_TIME = 360
local WARN_TIME = 240
local BLOCK_TIME = 600
local MIN_WARDS_FOR_TRACKING = 5
local TIME_STEP = 2

_G.WARDS_LIST = {
	["item_ward_observer"] = true,
	["item_ward_sentry"] = true,
	["item_ward_dispenser"] = true,
}

local blocked_player_for_wards = {}
local tracked_players = {}
local items_holding_time = {}

function InitWardsChecker()
	Timers:CreateTimer(0, function()
		for player_id = 0, 24 do
			if tracked_players[player_id] then
				local player = PlayerResource:GetPlayer(player_id)
				local team = PlayerResource:GetTeam(player_id)
				
				if player and not player:IsNull() and team then
					local wards_in_shop = GameRules:GetItemStockCount(team, "item_ward_observer", player_id) + GameRules:GetItemStockCount(team, "item_ward_sentry", player_id)
					local wards_in_inventory = 0
					
					CallbackHeroAndCourier(player_id, function(unit)
						for i = 0, 20 do
							local item = unit:GetItemInSlot(i)
							if item and not item:IsNull() and item.GetAbilityName and WARDS_LIST[item:GetAbilityName()] then
								wards_in_inventory = wards_in_inventory + item:GetCurrentCharges() + item:GetSecondaryCharges()
							end
						end
					end)

					if (wards_in_shop <= 0 and wards_in_inventory >= MIN_WARDS_FOR_TRACKING) then
						items_holding_time[player_id] = (items_holding_time[player_id] or 0) + TIME_STEP
					end

					if items_holding_time[player_id] == WARN_TIME then
						CustomGameEventManager:Send_ServerToPlayer(player, "custom_hud_message:send", { message = "#wards_holding_warning" })
					elseif items_holding_time[player_id] >= BASE_TIME then
						
						blocked_player_for_wards[player_id] = true
						StopTrackPlayer(player_id)
						
						Timers:CreateTimer(BLOCK_TIME, function()
							blocked_player_for_wards[player_id] = false
						end)
						
						CallbackHeroAndCourier(player_id, DropWardsInBase)
						return nil
					end
				else
					StopTrackPlayer(player_id)
				end
			end
		end
		return TIME_STEP
	end)
end

function StartTrackPlayer(player_id)
	tracked_players[player_id] = true
	items_holding_time[player_id] = 0
end

function StopTrackPlayer(player_id)
	tracked_players[player_id] = nil
	items_holding_time[player_id] = 0
end

function ReloadTimerHoldingCheckerForPlayer(player_id)
	local b_has_ward = false
	CallbackHeroAndCourier(player_id, function(unit)
		for i = 0, 20 do
			local item = unit:GetItemInSlot(i)
			if item and not item:IsNull() and item.GetAbilityName and WARDS_LIST[item:GetAbilityName()] then
				b_has_ward = true
			end
		end
	end)
	if b_has_ward then
		StartTrackPlayer(player_id)
	else
		StopTrackPlayer(player_id)
	end
end

function DropWardsInBase(unit)
	local team = unit:GetTeam()
	local fountain
	local multiplier

	if team == DOTA_TEAM_GOODGUYS then
		multiplier = -350
		fountain = Entities:FindByName(nil, "ent_dota_fountain_good")
	elseif team == DOTA_TEAM_BADGUYS then
		multiplier = -650
		fountain = Entities:FindByName(nil, "ent_dota_fountain_bad")
	end

	local fountain_pos = fountain:GetAbsOrigin()
	local pos_item = fountain_pos:Normalized() * multiplier + RandomVector(RandomFloat(0, 200)) + fountain_pos
	pos_item.z = fountain_pos.z

	for i = 0, 20 do
		local currentItem = unit:GetItemInSlot(i)
		if currentItem and WARDS_LIST[currentItem:GetName()] then
			unit:DropItemAtPositionImmediate(currentItem, pos_item)
		end
	end
end

function BlockedWardsFilter(player_id, error_mess)
	if blocked_player_for_wards[player_id] then
		CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(player_id), "display_custom_error", { message = error_mess })
		return false
	elseif not tracked_players[player_id] then
		StartTrackPlayer(player_id)
	end
end
