modifier_rax_bonus = class({})

function modifier_rax_bonus:IsHidden() return true end
function modifier_rax_bonus:IsPurgable() return false end
function modifier_rax_bonus:IsPurgeException() return false end
function modifier_rax_bonus:RemoveOnDeath() return false end

function modifier_rax_bonus:DeclareFunctions()
	return { MODIFIER_PROPERTY_RESPAWNTIME }
end

function modifier_rax_bonus:GetModifierConstantRespawnTime()
	if IsServer() then
		local rax_bonus = raxBonuses[self:GetParent():GetTeam()] - raxBonuses[self:GetParent():GetOpposingTeamNumber()]
	    if rax_bonus < 0 then rax_bonus = 0 end
		return rax_bonus
	end
end