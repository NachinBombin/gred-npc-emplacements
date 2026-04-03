-- gred_npc_emp_soldier/init.lua
-- Combine soldier NPC that physically walks to and mans any gred_emp_* emplacement.

include("shared.lua")

ENT.Model = Model("models/combine_soldier.mdl")

local SEARCH_RADIUS   = 3000
local SEARCH_INTERVAL = 2
local USE_DISTANCE    = 90

function ENT:Initialize()
    self:SetModel(self.Model)
    self:SetHullType(HULL_HUMAN)
    self:SetHullSizeNormal()
    self:SetSolid(SOLID_BBOX)
    self:SetMoveType(MOVETYPE_STEP)
    self:SetBloodColor(BLOOD_COLOR_RED)
    self:SetMaxHealth(100)
    self:SetHealth(100)
    self:CapabilitiesAdd(bit.bor(CAP_MOVE_GROUND, CAP_OPEN_DOORS, CAP_USE))

    self.NextSearchTime    = 0
    self.TargetEmplacement = nil
    self.IsManning         = false
    self.ScheduleState     = "SEARCH"

    self:SetSchedule(SCHED_IDLE_STAND)
end

function ENT:FindNearestEmplacement()
    local myPos    = self:GetPos()
    local best     = nil
    local bestDist = SEARCH_RADIUS * SEARCH_RADIUS

    for _, ent in ipairs(ents.GetAll()) do
        if not IsValid(ent) then continue end
        local cls = ent:GetClass()
        if not string.StartWith(cls, "gred_emp_") then continue end
        if cls == "gred_emp_base" then continue end
        if IsValid(ent:GetShooter()) then continue end
        if ent:GetBotMode() then continue end

        local d = myPos:DistToSqr(ent:GetPos())
        if d < bestDist then
            bestDist = d
            best     = ent
        end
    end

    return best
end

function ENT:Think()
    if not self:Alive() then return end

    local ct = CurTime()

    -- Manning check
    if self.IsManning then
        local emp = self.TargetEmplacement
        if not IsValid(emp) or emp:GetShooter() ~= self then
            self.IsManning              = false
            self.TargetEmplacement      = nil
            self._gredActiveEmplacement = nil
            self.ScheduleState          = "SEARCH"
        else
            local enemy = self:GetEnemy()
            if IsValid(enemy) then
                emp:SetTarget(enemy)
            end
            self:NextThink(ct + 0.1)
            return true
        end
    end

    -- SEARCH
    if self.ScheduleState == "SEARCH" and ct >= self.NextSearchTime then
        self.NextSearchTime    = ct + SEARCH_INTERVAL
        self.TargetEmplacement = self:FindNearestEmplacement()
        if IsValid(self.TargetEmplacement) then
            self.ScheduleState = "MOVE"
        end
    end

    -- MOVE
    if self.ScheduleState == "MOVE" then
        local emp = self.TargetEmplacement
        if not IsValid(emp) then
            self.ScheduleState = "SEARCH"
            self:NextThink(ct + 0.1)
            return true
        end
        if IsValid(emp:GetShooter()) then
            self.ScheduleState  = "SEARCH"
            self.NextSearchTime = ct
            self:NextThink(ct + 0.1)
            return true
        end

        if self:GetPos():Distance(emp:GetPos()) <= USE_DISTANCE then
            self.ScheduleState = "USE"
        else
            self:SetTarget(emp)
            self:SetLastPosition(emp:GetPos())
            self:SetSchedule(SCHED_MOVE_TO_GOALENT)
        end
    end

    -- USE
    if self.ScheduleState == "USE" then
        local emp = self.TargetEmplacement
        if not IsValid(emp) then
            self.ScheduleState = "SEARCH"
            self:NextThink(ct + 0.1)
            return true
        end

        self:SetSchedule(SCHED_IDLE_STAND)
        local ang = (emp:GetPos() - self:GetPos()):Angle()
        ang.p = 0
        self:SetAngles(ang)

        emp:Use(self, self, USE_SIMPLE, 1)

        if emp:GetShooter() == self then
            self.IsManning = true
            emp:SetBotMode(true)
            local enemy = self:GetEnemy()
            if IsValid(enemy) then emp:SetTarget(enemy) end
        else
            self.ScheduleState  = "SEARCH"
            self.NextSearchTime = ct + SEARCH_INTERVAL
        end
    end

    self:NextThink(ct + 0.1)
    return true
end

function ENT:OnRemove()
    local emp = self.TargetEmplacement
    if IsValid(emp) and emp:GetShooter() == self then
        emp:LeaveTurret(self)
        emp:SetBotMode(false)
    end
end

function ENT:OnTakeDamage(dmg)
    self:SetHealth(self:Health() - dmg:GetDamage())
    if self:Health() <= 0 then
        local emp = self.TargetEmplacement
        if IsValid(emp) and emp:GetShooter() == self then
            emp:LeaveTurret(self)
            emp:SetBotMode(false)
        end
        self:Remove()
    end
end
