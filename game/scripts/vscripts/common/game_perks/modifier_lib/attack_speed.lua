require("common/game_perks/base_game_perk")

attack_speed = class(base_game_perk)

function attack_speed:DeclareFunctions() return { MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT } end
function attack_speed:GetTexture() return "perkIcons/attack_speed" end
function attack_speed:GetModifierAttackSpeedBonus_Constant()
	return self:GetPerkValue(self.v[1], self.v[2], self.v[3])
end

attack_speed_t0 = class(attack_speed)
attack_speed_t1 = class(attack_speed)
attack_speed_t2 = class(attack_speed)
attack_speed_t3 = class(attack_speed)

function attack_speed_t0:OnCreated() self.v = {5, 1, 0.75} end
function attack_speed_t1:OnCreated() self.v = {10, 1, 1.5} end
function attack_speed_t2:OnCreated() self.v = {20, 1, 3} end
function attack_speed_t3:OnCreated() self.v = {40, 1, 6} end
