item_reset_mmr = item_reset_mmr or class({})

function item_reset_mmr:OnSpellStart()
	if not IsServer() then return end
	
	local playerId = self:GetCaster():GetPlayerOwnerID()
	if not playerId then return end

	CustomGameEventManager:Send_ServerToPlayer( PlayerResource:GetPlayer(playerId), "reset_mmr:show", {})
	self:RemoveSelf()
end
