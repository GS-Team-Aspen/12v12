require("common/game_perks/base_game_perk")

lifesteal = class(base_game_perk)

function lifesteal:DeclareFunctions() return { MODIFIER_PROPERTY_PROCATTACK_FEEDBACK } end
function lifesteal:GetTexture() return "perkIcons/lifesteal" end

function lifesteal:GetModifierProcAttack_Feedback(params)
	if params.damage <= 0 then return end
	if params.target:IsBuilding() then return end
	local attacker = params.attacker
	local steal = params.damage * (self.v/100)

	attacker:Heal(steal, self)

	local particle = ParticleManager:CreateParticle("particles/generic_gameplay/generic_lifesteal.vpcf", PATTACH_OVERHEAD_FOLLOW, params.attacker)
	ParticleManager:SetParticleControl(particle, 0, params.attacker:GetAbsOrigin())
	SendOverheadEventMessage(params.unit, OVERHEAD_ALERT_HEAL, params.attacker, steal, nil)
end

lifesteal_t0 = class(lifesteal)
lifesteal_t1 = class(lifesteal)
lifesteal_t2 = class(lifesteal)
lifesteal_t3 = class(lifesteal)

function lifesteal_t0:OnCreated() self.v = 9 end
function lifesteal_t1:OnCreated() self.v = 18 end
function lifesteal_t2:OnCreated() self.v = 36 end
function lifesteal_t3:OnCreated() self.v = 72 end
