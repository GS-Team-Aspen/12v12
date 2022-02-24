modifier_super_tower = class({})

function modifier_super_tower:IsHidden() return false end
function modifier_super_tower:IsPurgable() return false end
function modifier_super_tower:RemoveOnDeath() return false end

function modifier_super_tower:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_EXTRA_HEALTH_BONUS,
		MODIFIER_PROPERTY_BASE_ATTACK_TIME_CONSTANT
	}
end

local hp_bonus_by_tier = {
	[1] = 800,
	[2] = 2100,
	[3] = 2000,
	[4] = 2100,
}

function modifier_super_tower:OnCreated()
	self.hp_bonus = 0
	local tower = self:GetParent()
	local tower_tier = string.match(tower:GetUnitName(), "npc_dota_.*_tower%d")
	if tower_tier then
		self.hp_bonus = hp_bonus_by_tier[tonumber(tower_tier:sub(-1))]
	end
end

function modifier_super_tower:GetTexture()
	return "super_tower"
end

function modifier_super_tower:GetModifierExtraHealthBonus()
	return self.hp_bonus
end

function modifier_super_tower:GetModifierBaseAttackTimeConstant()
	return 0.65
end
