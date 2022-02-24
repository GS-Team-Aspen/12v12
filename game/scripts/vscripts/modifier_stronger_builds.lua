modifier_stronger_builds = class({})

function modifier_stronger_builds:IsHidden() return false end
function modifier_stronger_builds:IsPurgable() return false end
function modifier_stronger_builds:RemoveOnDeath() return false end

function modifier_stronger_builds:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_EXTRA_HEALTH_BONUS,
		MODIFIER_PROPERTY_BASE_ATTACK_TIME_CONSTANT
	}
end

local hp_bonus_by_build_type = {
	["fort"] = 4500,
	["melee_rax"] = 2200,
	["range_rax"] = 1300,
}

local clear_tags = {
	"npc_dota_badguys_",
	"npc_dota_goodguys_",
	"_top",
	"_bot",
	"_mid",
}

function modifier_stronger_builds:OnCreated()
	self.hp_bonus = 0
	local parent = self:GetParent()
	local build_type = parent:GetUnitName()
	for _, tag in pairs(clear_tags) do
		build_type = build_type:gsub(tag, "");
	end
	if hp_bonus_by_build_type[build_type] then
		self.hp_bonus = hp_bonus_by_build_type[build_type]
	end
end

function modifier_stronger_builds:GetTexture()
	return "super_tower"
end

function modifier_stronger_builds:GetModifierExtraHealthBonus()
	return self.hp_bonus
end
