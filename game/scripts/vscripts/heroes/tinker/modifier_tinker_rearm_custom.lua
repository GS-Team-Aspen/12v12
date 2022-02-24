modifier_tinker_rearm_custom = modifier_tinker_rearm_custom or class({})

function modifier_tinker_rearm_custom:OnCreated()
	if not IsServer() then return end
	
	local level = self:GetAbility():GetLevel()
	local caster = self:GetParent()
	
	if not level or not caster then return end
	
	caster:EmitSound("Hero_Tinker.RearmStart")
	caster:EmitSound("Hero_Tinker.Rearm")

	self.pfx = ParticleManager:CreateParticle("particles/units/heroes/hero_tinker/tinker_rearm.vpcf", PATTACH_POINT_FOLLOW, caster)
	ParticleManager:SetParticleControlEnt(self.pfx, 0, caster, PATTACH_POINT_FOLLOW, "attach_attack2", caster:GetOrigin(), true)
	
	caster:StartGesture(_G["ACT_DOTA_TINKER_REARM" .. level])
end

function modifier_tinker_rearm_custom:OnDestroy()
	if not IsServer() then return end
	
	ParticleManager:DestroyParticle(self.pfx, false)
	ParticleManager:ReleaseParticleIndex(self.pfx)
end 
