modifier_gold_bonus = class({})

function modifier_gold_bonus:GetAttributes() return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE end
function modifier_gold_bonus:IsPurgable() return false end
function modifier_gold_bonus:RemoveOnDeath() return false end

if IsClient() then return end

function modifier_gold_bonus:OnCreated(kv)
	self.gold = kv.gold
	self:SetStackCount(self.gold)

	local tick_duration = self:GetDuration() / kv.gold
	self:StartIntervalThink(tick_duration)
end

function modifier_gold_bonus:OnIntervalThink()
	self.gold = self.gold - 1
	self:SetStackCount(self.gold)

	PlayerResource:ModifyGold(self:GetParent():GetPlayerOwnerID(), 1, true, DOTA_ModifyGold_GameTick)

	if self.gold <= 0 then
		self:Destroy()
	end
end