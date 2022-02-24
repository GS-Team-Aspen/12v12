require("common/game_perks/base_game_perk")

LinkLuaModifier("linken_ready", "common/game_perks/modifier_lib/linken", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("linken_cooldown", "common/game_perks/modifier_lib/linken", LUA_MODIFIER_MOTION_NONE)
linken = class(base_game_perk)

linken.OnCreated = function(self)
	if not IsServer() then return end
	local parent = self:GetParent()
	parent:AddNewModifier(parent, nil, "linken_ready", {})
end

function linken:IsHidden() return true end
function linken:DeclareFunctions() return { MODIFIER_PROPERTY_ABSORB_SPELL } end
function linken:GetTexture() return "perkIcons/linken" end

function linken:GetAbsorbSpell(params)
	if not IsServer() then return nil end
	local parent = self:GetParent()
	if not parent or parent:IsNull() then return nil end
	
	if params.ability:GetCaster():GetTeamNumber() == parent:GetTeamNumber() then return nil end
	if parent:FindModifierByName("linken_cooldown") then return nil end

	-- modifier_item_sphere_target already has highest priority, so no need to check that
	local sphere_modifier = parent:FindModifierByName("modifier_item_sphere")
	if sphere_modifier and not sphere_modifier:IsNull() then
		local item = sphere_modifier:GetAbility()
		if item and not item:IsNull() then
			local is_cd_ready = item:IsCooldownReady()
			if is_cd_ready then return nil end
		end
	end

	local qop_modifier = parent:FindModifierByName("modifier_special_bonus_spell_block")
	if qop_modifier and not qop_modifier:IsNull() then
		local remaining_time = qop_modifier:GetRemainingTime()
		if remaining_time and remaining_time <= 0 then return nil end
	end

	parent:EmitSound("DOTA_Item.LinkensSphere.Activate")
	
	local pfx = ParticleManager:CreateParticle("particles/items_fx/immunity_sphere.vpcf", PATTACH_POINT_FOLLOW, parent)
	ParticleManager:SetParticleControlEnt(pfx, 0, parent, PATTACH_POINT_FOLLOW, "attach_hitloc", parent:GetAbsOrigin(), true)
	ParticleManager:ReleaseParticleIndex(pfx)
	
	parent:AddNewModifier(parent, nil, "linken_cooldown", {duration = self.v})
	local modifier = parent:FindModifierByName("linken_ready")
	if modifier and not modifier:IsNull() then
		parent:RemoveModifierByName("linken_ready")
	end
	
	return 1
end

linken_cooldown = class({})

function linken_cooldown:IsHidden() return false end
function linken_cooldown:IsDebuff() return false end
function linken_cooldown:IsPurgable() return false end
function linken_cooldown:RemoveOnDeath() return false end
function linken_cooldown:GetTexture() return "perkIcons/linken" end
function linken_cooldown:GetAttributes() return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE end

function linken_cooldown:OnDestroy()
	if not IsServer() then return end
	local parent = self:GetParent()
	parent:AddNewModifier(parent, nil, "linken_ready", {})
end

linken_ready = class({})

function linken_ready:IsHidden() return false end
function linken_ready:IsDebuff() return false end
function linken_ready:IsPurgable() return false end
function linken_ready:RemoveOnDeath() return false end
function linken_ready:GetTexture() return "perkIcons/linken" end
function linken_ready:GetAttributes() return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE end

function linken_ready:GetEffectName()
	return "particles/linken_orb_small.vpcf"
end

function linken_ready:GetEffectAttachType()
	return PATTACH_OVERHEAD_FOLLOW
end

function linken_ready:ShouldUseOverheadOffset()
	return true
end

linken_t0 = class(linken)
linken_t0.v = 200
linken_t1 = class(linken)
linken_t1.v = 100
linken_t2 = class(linken)
linken_t2.v = 50
linken_t3 = class(linken)
linken_t3.v = 25
