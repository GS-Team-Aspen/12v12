NeutralItemsDrop = NeutralItemsDrop or {}

NEUTRAL_STASH_TELEPORT_DELAY = 6

function DropItem(data)
	if not data.PlayerID then return end
	
	local item = EntIndexToHScript( data.item )
	local player = PlayerResource:GetPlayer(data.PlayerID)
	local team = PlayerResource:GetTeam(data.PlayerID)
	local fountain
	local multiplier

	if team == DOTA_TEAM_GOODGUYS then
		multiplier = -350
		fountain = Entities:FindByName( nil, "ent_dota_fountain_good" )
	elseif team == DOTA_TEAM_BADGUYS then
		multiplier = -650
		fountain = Entities:FindByName( nil, "ent_dota_fountain_bad" )
	end

	local fountain_pos = fountain:GetAbsOrigin()
	local pos_item = fountain_pos:Normalized() * multiplier + RandomVector( RandomFloat( 0, 200 ) ) + fountain_pos
	pos_item.z = fountain_pos.z

	CreateItemOnPositionSync(pos_item, item)

	item.neutralDropInBase = true

	for i = 0, 24 do
		if data.PlayerID ~= i and PlayerResource:GetTeam(i) == team then -- remove check "data.PlayerID ~= i" if you want test system
			local player = PlayerResource:GetPlayer(i)

			CustomGameEventManager:Send_ServerToPlayer( player, "neutral_item_dropped", { 
				item = data.item,
				secret = item.secret_key
			})
		end
	end
	
	Timers:CreateTimer(15,function() -- !!! You need put here time from function NeutralItemDropped from neutral_items.js - Schedule
		if not item or item:IsNull() then return end

		local container = item:GetContainer()
		if not container or container:IsNull() then return end

		AddNeutralItemToStashWithEffects(data.PlayerID, team, item)
	end)
end

function CheckNeutralItemForUnit(unit)
	local count = 0
	if unit and unit:HasInventory() then
		for i = 0, 20 do
			local item = unit:GetItemInSlot(i)
			if item then
				if _G.neutralItems[item:GetAbilityName()] then count = count + 1 end
			end
		end
	end
	return count
end

function CheckCountOfNeutralItemsForPlayer(playerId)
	local hero = PlayerResource:GetSelectedHeroEntity(playerId)
	local neutralItemsForPlayer = CheckNeutralItemForUnit(hero)
	if neutralItemsForPlayer >= MAX_NEUTRAL_ITEMS_FOR_PLAYER then return neutralItemsForPlayer end
	local playersCourier
	local couriers = Entities:FindAllByName("npc_dota_courier")
	for _, courier in pairs(couriers) do
		if courier:GetPlayerOwnerID() == playerId then
			playersCourier = courier
		end
	end
	if playersCourier then
		neutralItemsForPlayer = neutralItemsForPlayer + CheckNeutralItemForUnit(playersCourier)
	end
	return neutralItemsForPlayer
end

function NotificationToAllPlayerOnTeam(data)
	for id = 0, 24 do
		if PlayerResource:GetTeam( data.PlayerID ) == PlayerResource:GetTeam( id ) then
			CustomGameEventManager:Send_ServerToPlayer( PlayerResource:GetPlayer( id ), "neutral_item_taked", { item = data.item, player = data.PlayerID } )
		end
	end
end

RegisterCustomEventListener( "neutral_item_keep", function( data )
	local item = EntIndexToHScript( data.item )
	local container = item:GetContainer()

	if not item:IsNeutralDrop() or not item.secret_key or item.secret_key ~= data.secret then return end

	if CheckCountOfNeutralItemsForPlayer(data.PlayerID) >= _G.MAX_NEUTRAL_ITEMS_FOR_PLAYER then
		DropItem(data)
		DisplayError(data.PlayerID, "#player_still_have_a_lot_of_neutral_items")
		return
	end

	local hero = PlayerResource:GetSelectedHeroEntity( data.PlayerID )
	local freeSlot = hero:DoesHeroHasFreeSlot()

	if freeSlot then
		item.secret_key = nil
		hero:AddItem(item)
		NotificationToAllPlayerOnTeam(data)

		if container then
			container:RemoveSelf()
		end
	else
		DropItem(data)
		CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(data.PlayerID), "display_custom_error", { message = "#inventory_full_custom_message" })
	end
end )

RegisterCustomEventListener( "neutral_item_take", function( data )
	local item = EntIndexToHScript( data.item )
	local hero = PlayerResource:GetSelectedHeroEntity( data.PlayerID )
	local freeSlot = hero:DoesHeroHasFreeSlot()

	if not item:IsNeutralDrop() or not item.secret_key or item.secret_key ~= data.secret then return end

	if CheckCountOfNeutralItemsForPlayer(data.PlayerID) >= MAX_NEUTRAL_ITEMS_FOR_PLAYER then
		DisplayError(data.PlayerID, "#player_still_have_a_lot_of_neutral_items")
		return
	end

	if freeSlot then
		if item.neutralDropInBase then
			item.secret_key = nil
			item.neutralDropInBase = false
			local container = item:GetContainer()
			UTIL_Remove( container )
			hero:AddItem( item )
			NotificationToAllPlayerOnTeam(data)
		end
	else
		CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(data.PlayerID), "display_custom_error", { message = "#inventory_full_custom_message" })
	end
end )

RegisterCustomEventListener( "neutral_item_drop", function( data )
	DropItem(data)
end )

function SearchCorrectNeutralShopByTeam(team)
	local neutralShops = Entities:FindAllByClassname('ent_dota_neutral_item_stash')
	for _, focusShop in pairs(neutralShops) do
		if focusShop:GetTeamNumber() == team then
			return focusShop
		end
	end
	return false
end

function NeutralItemsDrop:OnItemSpawned(event)
	local item = EntIndexToHScript(event.item_ent_index) ---@type CDOTA_Item

	if item and item:IsNeutralDrop() then
		self.lastDroppedItem = item
		self.dropFrame = GetFrameCount()
	end
end

function NeutralItemsDrop:OnEntityKilled(event)
	if self.dropFrame ~= GetFrameCount() then return end

	local killed = EntIndexToHScript(event.entindex_killed or -1) ---@type CDOTA_BaseNPC
	local attacker = EntIndexToHScript(event.entindex_attacker or -1) ---@type CDOTA_BaseNPC

	if not attacker then return end

	local hero = PlayerResource:GetSelectedHeroEntity(attacker:GetPlayerOwnerID())

	if hero and killed and killed:IsNeutralUnitType() and killed:GetTeam() == DOTA_TEAM_NEUTRALS then
		self:OnNeutralItemDropped(self.lastDroppedItem, hero)

		self.lastDroppedItem = nil
		self.dropFrame = nil
	end
end

-- Called when neutral item dropped from neutral creeps
function NeutralItemsDrop:OnNeutralItemDropped(item, hero)
	local container = item:GetContainer()

	if not container then return end

	Timers:CreateTimer(NEUTRAL_STASH_TELEPORT_DELAY, function()
		-- if container destroyed item already picked up by somebody
		if IsValidEntity(container) then
			item.old = true 
			item.secret_key = RandomInt(1,999999)

			local pos = container:GetAbsOrigin()
			local pFX = ParticleManager:CreateParticle("particles/items2_fx/neutralitem_teleport.vpcf", PATTACH_WORLDORIGIN, nil)
			ParticleManager:SetParticleControl(pFX, 0, pos)
			ParticleManager:ReleaseParticleIndex(pFX)
			StartSoundEventFromPosition("NeutralItem.TeleportToStash", pos)

			container:RemoveSelf()

			DropItem({
				PlayerID = hero:GetPlayerOwnerID(),
				item = item:entindex()
			})
		end
	end)
end

-- Fired when hero loses item from inventory
function NeutralItemsDrop:OnItemStateChanged(event)
	local item = EntIndexToHScript(event.item_entindex) ---@type CDOTA_Item
	local hero = EntIndexToHScript(event.hero_entindex) ---@type CDOTA_BaseNPC_Hero

	if not item or not hero then return end

	local container = item:GetContainer()
	
	-- If item has container then it dropped to ground
	if item:IsNeutralDrop() and container then
		AddNeutralItemToStashWithEffects(hero:GetPlayerOwnerID(), hero:GetTeam(), item)
	end
end

function AddNeutralItemToStashWithEffects(playerID, team, item)
	PlayerResource:AddNeutralItemToStash(playerID, team, item)

	local container = item:GetContainer()

	if not container then return end

	local pos = container:GetAbsOrigin()

	local pFX = ParticleManager:CreateParticle("particles/items2_fx/neutralitem_teleport.vpcf", PATTACH_WORLDORIGIN, nil)
	ParticleManager:SetParticleControl(pFX, 0, pos)
	ParticleManager:ReleaseParticleIndex(pFX)
	StartSoundEventFromPosition("NeutralItem.TeleportToStash", pos)

	container:RemoveSelf()
end

function NeutralItemsDrop:Init()
	ListenToGameEvent("dota_item_spawned", Dynamic_Wrap(NeutralItemsDrop, "OnItemSpawned"), self)
	ListenToGameEvent("entity_killed", Dynamic_Wrap(NeutralItemsDrop, "OnEntityKilled"), self)
	ListenToGameEvent("dota_hero_inventory_item_change", Dynamic_Wrap(NeutralItemsDrop, "OnItemStateChanged"), self)
end
