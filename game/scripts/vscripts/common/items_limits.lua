local lastTimeBuyItemWithCooldown = {}
local maxItemsForPlayersData = {}
LinkLuaModifier("modifier_dummy_inventory_custom", LUA_MODIFIER_MOTION_NONE)
-------------------------------------------------------------------------
local itemsCooldownForPlayer = {
	["item_disable_help_custom"] = 10,
	["item_mute_custom"] = 10,
	["item_tome_of_knowledge"] = 300,
	["item_banhammer"] = 600,
	["item_reset_mmr"] = 20,
}
-------------------------------------------------------------------------
local maxItemsForPlayers = {
	["item_banhammer"] = 2,
}
-------------------------------------------------------------------------
local notFastItems = {
	["item_ward_observer"] = true,
	["item_ward_sentry"] = true,
	["item_smoke_of_deceit"] = true,
	["item_clarity"] = true,
	["item_flask"] = true,
	["item_greater_mango"] = true,
	["item_enchanted_mango"] = true,
	["item_tango"] = true,
	["item_faerie_fire"] = true,
	["item_tpscroll"] = true,
	["item_dust"] = true,
}
-------------------------------------------------------------------------
local fastItems = {
	["item_disable_help_custom"] = true,
	["item_mute_custom"] = true,
	["item_banhammer"] = true,
}
-------------------------------------------------------------------------

function CDOTA_BaseNPC:CheckPersonalCooldown(item)
	local buyerEntIndex = self:GetEntityIndex()
	local itemName = item:GetAbilityName()
	local unique_key = itemName .. "_" .. buyerEntIndex
	local playerID = self:GetPlayerID()

	if not itemsCooldownForPlayer[itemName] or item.isTransfer or not item:CheckMaxItemsForPlayer(unique_key) then return true end

	local playerCanBuyItem = lastTimeBuyItemWithCooldown[unique_key] == nil or ((GameRules:GetGameTime() - lastTimeBuyItemWithCooldown[unique_key]) >= itemsCooldownForPlayer[itemName])

	if playerCanBuyItem then
		lastTimeBuyItemWithCooldown[unique_key] = GameRules:GetGameTime()
		return true
	else
		CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(playerID), "display_custom_error", { message = "#fast_buy_items" })
		return false
	end

	return true
end

-------------------------------------------------------------------------

function CDOTA_BaseNPC:IsMaxItemsForPlayer(item)
	local buyerEntIndex = self:GetEntityIndex()
	local itemName = item:GetAbilityName()
	local unique_key = itemName .. "_" .. buyerEntIndex
	local playerID = self:GetPlayerID()
	if not maxItemsForPlayers[itemName] or item.isTransfer then return true end

	local isPlayerBoughtMaxItems = item:CheckMaxItemsForPlayer(unique_key)

	if isPlayerBoughtMaxItems then
		maxItemsForPlayersData[unique_key] = maxItemsForPlayersData[unique_key] + 1
	else
		CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(playerID), "display_custom_error", { message = "#you_cannot_buy_more_items_this_type" })
		return false
	end

	return true
end

-------------------------------------------------------------------------

function CDOTA_BaseNPC:RefundItem(item)
	self:ModifyGold(item:GetCost(), false, 0)
	UTIL_Remove(item)
end

-------------------------------------------------------------------------

function CDOTA_BaseNPC:DoesHeroHasFreeSlot()
	for i = 0, 15 do
		if self:GetItemInSlot(i) == nil then
			return i
		end
	end
	return false
end

-------------------------------------------------------------------------

function CDOTA_Item:ItemIsFastBuying(playerId)
	return fastItems[self:GetName()] or (Supporters:GetLevel(playerId) > 0)
end

-------------------------------------------------------------------------

function CDOTA_Item:TransferToBuyer(unit)
	local buyer = self:GetPurchaser()
	local itemName = self:GetName()

	if notFastItems[itemName] or unit:IsIllusion() or self.isTransfer or unit:GetClassname() == "npc_dota_lone_druid_bear" then
		return true
	end
	local buyerPlayerId = buyer:GetPlayerID()
	if not buyer:DoesHeroHasFreeSlot() then
		buyer:RefundItem(self)
		CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(buyerPlayerId), "display_custom_error", { message = "#dota_hud_error_cant_purchase_inventory_full" })
		return false
	else
		local newItem = CreateItem( itemName, buyer:GetPlayerOwner(), buyer:GetPlayerOwner() )
		newItem:SetPurchaser(buyer)
		newItem:SetPurchaseTime(GameRules:GetGameTime())
		newItem.isTransfer = true

		self:SetPurchaser(nil)
		self:SetShareability(ITEM_NOT_SHAREABLE)
		local team = buyer:GetTeam()
		local oldCharges = GameRules:GetItemStockCount(team, itemName, buyerPlayerId)
		GameRules:SetItemStockCount(oldCharges - 2, team, itemName, buyerPlayerId)

		buyer:AddItem(newItem)

		Timers:CreateTimer(0, function()
			local container = self:GetContainer()
			if container then
				UTIL_Remove(container)
			end
			UTIL_Remove(self)
			Timers:CreateTimer(0.03, function()
				for i = 0, GameRules:NumDroppedItems() do
					container = GameRules:GetDroppedItem(i)
					if container and not container:GetContainedItem() and container.GetSequence and container:GetSequence() == "gem01_idle" then
						UTIL_Remove(container)
					end
				end
			end)
		end)
		return true
	end
	
	return true
end

-------------------------------------------------------------------------

function CDOTA_Item:CheckMaxItemsForPlayer(unique_key)
	if not maxItemsForPlayers[self:GetAbilityName()] then return true end
	if not maxItemsForPlayersData[unique_key] then
		maxItemsForPlayersData[unique_key] = 1
	end
	return maxItemsForPlayersData[unique_key] <= maxItemsForPlayers[self:GetAbilityName()]
end

-------------------------------------------------------------------------
function CreateDummyInventoryForPlayer(playerId, unit)
	if PlayerResource:GetPlayer(playerId).dummyInventory then
		PlayerResource:GetPlayer(playerId).dummyInventory:Kill(nil, nil)
	end
	local startPointSpawn = unit:GetAbsOrigin() + (RandomFloat(100, 100))
	local dInventory = CreateUnitByName("npc_dummy_inventory", startPointSpawn, true, unit, unit, PlayerResource:GetTeam(playerId))
	dInventory:SetControllableByPlayer(playerId, true)
	dInventory:AddNewModifier(dInventory, nil, "modifier_dummy_inventory_custom", {duration = -1})
	dInventory:AddNoDraw()
	dInventory.isDummy = true
	PlayerResource:GetPlayer(playerId).dummyInventory = dInventory
end
-------------------------------------------------------------------------
function CDOTA_BaseNPC:IsMonkeyClone()
	return (self:HasModifier("modifier_monkey_king_fur_army_soldier") or self:HasModifier("modifier_wukongs_command_warrior"))
end
-------------------------------------------------------------------------
function CDOTA_BaseNPC:IsMainHero()
	return self and (not self:IsNull()) and self:IsRealHero() and (not self:IsTempestDouble()) and (not self:IsMonkeyClone()) and (not self:IsClone())
end
-------------------------------------------------------------------------
