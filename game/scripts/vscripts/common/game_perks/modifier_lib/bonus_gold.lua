require("common/game_perks/base_game_perk")

bonus_gold = class(base_game_perk)

function bonus_gold:GetTexture() return "perkIcons/bonus_gold" end

bonus_gold_t0 = class(bonus_gold)
bonus_gold_t1 = class(bonus_gold)
bonus_gold_t2 = class(bonus_gold)
bonus_gold_t3 = class(bonus_gold)

function bonus_gold_t0:OnCreated()
	if not IsServer() then return end
	local parent = self:GetParent()
	if not parent:IsRealHero() or parent:IsClone() or parent:IsTempestDouble() then return end
	parent:ModifyGold(300, true, 0)
end

function bonus_gold_t1:OnCreated()
	if not IsServer() then return end
	local parent = self:GetParent()
	if not parent:IsRealHero() or parent:IsClone() or parent:IsTempestDouble() then return end
	parent:ModifyGold(600, true, 0)
end

function bonus_gold_t2:OnCreated()
	if not IsServer() then return end
	local parent = self:GetParent()
	if not parent:IsRealHero() or parent:IsClone() or parent:IsTempestDouble() then return end
	parent:ModifyGold(1200, true, 0)
end

function bonus_gold_t3:OnCreated()
	if not IsServer() then return end
	local parent = self:GetParent()
	if not parent:IsRealHero() or parent:IsClone() or parent:IsTempestDouble() then return end
	parent:ModifyGold(2400, true, 0)
end
