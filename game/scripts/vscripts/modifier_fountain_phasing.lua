modifier_fountain_phasing = class({})
modifier_fountain_phasing_effect = class({})

LinkLuaModifier("modifier_fountain_phasing_effect", 'modifier_fountain_phasing', LUA_MODIFIER_MOTION_NONE)

function modifier_fountain_phasing:IsAura() return true end
function modifier_fountain_phasing:GetModifierAura() return "modifier_fountain_phasing_effect" end
function modifier_fountain_phasing:IsHidden() return true end
function modifier_fountain_phasing:IsPurgable() return false end
function modifier_fountain_phasing:IsPurgeException() return false end
function modifier_fountain_phasing:RemoveOnDeath() return false end
function modifier_fountain_phasing:IsHidden() return false end
function modifier_fountain_phasing:GetAuraSearchTeam() return DOTA_UNIT_TARGET_TEAM_FRIENDLY end
function modifier_fountain_phasing:GetAuraSearchType() return DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_CREEP end
function modifier_fountain_phasing:GetAuraSearchFlags() return DOTA_UNIT_TARGET_FLAG_INVULNERABLE end
function modifier_fountain_phasing:GetAuraRadius() return 1200 end

function modifier_fountain_phasing_effect:IsHidden() return true end
function modifier_fountain_phasing_effect:IsPurgable() return false end
function modifier_fountain_phasing_effect:IsPurgeException() return false end
function modifier_fountain_phasing_effect:RemoveOnDeath() return false end
function modifier_fountain_phasing_effect:CheckState() return {
		[MODIFIER_STATE_NO_UNIT_COLLISION] = true,
	}
end
