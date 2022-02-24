require("common/game_perks/base_game_perk")

cast_time = class(base_game_perk)

function cast_time:DeclareFunctions() return { MODIFIER_PROPERTY_CASTTIME_PERCENTAGE } end
function cast_time:GetTexture() return "perkIcons/cast_time" end
function cast_time:GetModifierPercentageCasttime()
	return self.v
end

cast_time_t0 = class(cast_time)
cast_time_t1 = class(cast_time)
cast_time_t2 = class(cast_time)
cast_time_t3 = class(cast_time)

function cast_time_t0:OnCreated() self.v = 25 end
function cast_time_t1:OnCreated() self.v = 50 end
function cast_time_t2:OnCreated() self.v = 75 end
function cast_time_t3:OnCreated() self.v = 100 end
