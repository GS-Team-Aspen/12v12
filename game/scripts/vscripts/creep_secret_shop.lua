local DEFAULT_THINK_TIME = 2
local NOT_HOME_THINK_TIME = 30

creep_secret_shop = class({})

function creep_secret_shop:IsHidden() return true end
function creep_secret_shop:RemoveOnDeath() return false end
function creep_secret_shop:IsPurgeException() return false end
function creep_secret_shop:RemoveOnDeath() return false end

local secret_shop_pos = {
	[DOTA_TEAM_BADGUYS] = Vector(4860, -1228, 129),
	[DOTA_TEAM_GOODGUYS] = Vector(-4894, 1745, 129)
}
local home_shop_pos = {
	[DOTA_TEAM_BADGUYS] = Vector(6980, 6334, 390),
	[DOTA_TEAM_GOODGUYS] = Vector(-7045, -6480, 384)
}

function creep_secret_shop:OnCreated()
	if not IsServer() then return end
	
	local parent = self:GetParent()
	if not parent then return end

	local team = parent:GetTeam()
	if not team or not secret_shop_pos[team] or not home_shop_pos[team] then return end

	self.is_secret_shop = false
	self.parent = parent
	self.team = team
	self.time = 0
	self.home_pos = home_shop_pos[team] + RandomVector(RandomFloat(100, 100))
	self.secret_pos = secret_shop_pos[team] + RandomVector(RandomFloat(50, 50))

	self.last_pos = self.parent:GetAbsOrigin()
	
	self:StartIntervalThink(DEFAULT_THINK_TIME)
end

function creep_secret_shop:ForceToSecretShop()
	self.is_secret_shop = true
	self.parent:AddNoDraw()
	self:MoveToPos(self.secret_pos)
end

function creep_secret_shop:OnIntervalThink()
	if not IsServer() then return end
	if not self.parent:IsAlive() then return end
	
	local current_pos = self.parent:GetAbsOrigin()
	
	if current_pos == self.secret_pos then return end

	self.time = self.time + DEFAULT_THINK_TIME
	
	if self.last_pos == current_pos and (self.parent:IsInRangeOfShop(DOTA_SHOP_HOME, true) or self.time >= NOT_HOME_THINK_TIME) then
		self:ForceToSecretShop()
	else
		self.last_pos = current_pos
	end
end

function creep_secret_shop:OrderFilter(data)
	if not IsServer() then return end

	local current_pos = self.parent:GetAbsOrigin()

	if self.is_secret_shop then
		self:MoveToPos(self.home_pos)
		self.parent:RemoveNoDraw()
	end
	
	self.last_pos = current_pos
	self.is_secret_shop = false
	self.time = 0
	
	self:StartIntervalThink(DEFAULT_THINK_TIME)
end

function creep_secret_shop:MoveToPos(pos)
	self.parent:SetAbsOrigin(pos)
	self.last_pos = pos
end

function creep_secret_shop:CheckState()
	local state = {}
	if self.is_secret_shop then
		state = {
			[MODIFIER_STATE_NOT_ON_MINIMAP] = true,
			[MODIFIER_STATE_ATTACK_IMMUNE] = true,
			[MODIFIER_STATE_MAGIC_IMMUNE] = true,
			[MODIFIER_STATE_NO_HEALTH_BAR] = true,
			[MODIFIER_STATE_INVULNERABLE] = true,
			[MODIFIER_STATE_NO_UNIT_COLLISION] = true,
			[MODIFIER_STATE_DISARMED] = true,
			[MODIFIER_STATE_INVISIBLE] = true,
			[MODIFIER_STATE_BLIND] = true,
		}
	end
	return state
end
