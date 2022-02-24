require("common/game_perks/base_game_perk")

debuff_time = class(base_game_perk)

function debuff_time:DeclareFunctions() return { MODIFIER_PROPERTY_STATUS_RESISTANCE_CASTER } end
function debuff_time:GetTexture() return "perkIcons/debuff_time" end
function debuff_time:GetModifierStatusResistanceCaster() return -self.v end

debuff_time_t0 = class(debuff_time)
debuff_time_t1 = class(debuff_time)
debuff_time_t2 = class(debuff_time)
debuff_time_t3 = class(debuff_time)

function debuff_time_t0:OnCreated() self.v = 9 end
function debuff_time_t1:OnCreated() self.v = 18 end
function debuff_time_t2:OnCreated() self.v = 36 end
function debuff_time_t3:OnCreated() self.v = 72 end
