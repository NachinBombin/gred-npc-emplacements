-- gred_npc_emp_controller/init.lua
-- SERVER side: NPC management, aiming and firing logic.
-- This entity is invisible and non-solid. It attaches to any gred_emp_* gun,
-- takes ownership as the "shooter", enables bot mode, and feeds enemy targets
-- sourced from nearby hostile NPCs.

AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

local IsValid = IsValid
local math    = math
local ents    = ents
local CurTime = CurTime

-- How often (seconds) to search for a new target
local TARGET_SEARCH_INTERVAL = 0.25
-- How often to verify the current target is still alive/visible
local TARGET_VALIDATE_INTERVAL = 0.1
-- Sphere radius to search for enemies around the gun muzzle
local SEARCH_RADIUS = 2500


-- ──────────────────────────────────────────────
-- Initialise
-- ──────────────────────────────────────────────

function ENT:Initialize()
    self:SetNoDraw(true)
    self:SetNotSolid(true)
    self:SetMoveType(MOVETYPE_NONE)
    self:SetCollisionGroup(COLLISION_GROUP_WORLD)

    self.NextTargetSearch   = 0
    self.NextTargetValidate = 0
    self.Gun                = nil  -- the gred_emp_* entity we control
end


-- ──────────────────────────────────────────────
-- Public API: attach this controller to a gun
-- ──────────────────────────────────────────────

function ENT:AttachToGun(gun)
    if not IsValid(gun) then return end
    self.Gun = gun

    -- Position on top of the gun so distance checks pass
    self:SetPos(gun:GetPos())
    self:SetParent(gun)

    -- Take the shooter slot with ourselves so the gun\'s Think() treats us like a bot
    gun:SetBotMode(true)
    gun:GrabTurret(self)

    -- We handle target finding ourselves; disable the gun\'s own FindBotTarget
    -- by keeping SetTarget fed from our side.
    gred_npc_emp.RegisterController(gun, self)
end


-- ──────────────────────────────────────────────
-- Required stubs so the gun doesn\'t error when
-- it calls player-specific methods on us
-- ──────────────────────────────────────────────

function ENT:IsPlayer()     return false end
function ENT:IsNPC()        return false end
function ENT:Alive()        return true  end
function ENT:Team()         return TEAM_UNASSIGNED end
function ENT:GetPos()       return self.BaseClass.GetPos(self) end
function ENT:EyeAngles()    return self.Gun and self.Gun:GetAngles() or Angle(0,0,0) end
function ENT:GetVehicle()   return NULL end
function ENT:InVehicle()    return false end
function ENT:GetActiveWeapon() return NULL end
function ENT:GetPreviousWeapon() return NULL end
function ENT:DrawViewModel(b) end
function ENT:StripWeapon(c) end
function ENT:SelectWeapon(c) end
function ENT:CrosshairEnable() end
function ENT:ExitVehicle()  end
function ENT:EnterVehicle(v) end
function ENT:PrintMessage(t,m) end
function ENT:Give(c)        return NULL end
function ENT:SetActiveWeapon(w) end

-- KeyDown: the gun\'s Think calls ply:KeyDown(IN_ATTACK) and ply:KeyDown(IN_RELOAD)
-- We return attack=true whenever target is valid, reload when gun is empty
function ENT:KeyDown(key)
    if not IsValid(self.Gun) then return false end
    if key == IN_ATTACK then
        return self.Gun:GetTargetValid()
    elseif key == IN_RELOAD then
        return self.Gun:GetAmmo() <= 0
    end
    return false
end


-- ──────────────────────────────────────────────
-- Target finding
-- ──────────────────────────────────────────────

-- Returns true if `ent` is a hostile NPC that the gun can theoretically hit
local function IsValidEnemy(gun, ent)
    if not IsValid(ent) then return false end
    if not ent:IsNPC() and not ent:IsPlayer() then return false end
    if ent:Health() <= 0 then return false end

    -- Use the gun\'s own team-hostility logic when available
    if gun.IsValidTarget then
        return gun:IsValidTarget(ent)
    end

    return true
end

function ENT:FindNewTarget()
    local gun = self.Gun
    if not IsValid(gun) then return end

    local muzzlePos
    if gun.TurretMuzzles and gun.TurretMuzzles[1] then
        muzzlePos = gun:LocalToWorld(gun.TurretMuzzles[1].Pos)
    else
        muzzlePos = gun:GetPos()
    end

    local best      = nil
    local bestDistSq = math.huge
    local r2        = SEARCH_RADIUS * SEARCH_RADIUS

    for _, ent in ipairs(ents.FindInSphere(muzzlePos, SEARCH_RADIUS)) do
        if IsValidEnemy(gun, ent) then
            local dSq = muzzlePos:DistToSqr(ent:GetPos())
            if dSq < r2 and dSq < bestDistSq then
                -- Quick LOS check
                local tr = util.QuickTrace(muzzlePos, ent:GetPos() - muzzlePos, {gun, self})
                if not tr.Hit or tr.Entity == ent then
                    bestDistSq = dSq
                    best       = ent
                end
            end
        end
    end

    if IsValid(best) then
        gun:SetTarget(best)
        gun:SetTargetValid(true)
    else
        gun:SetTarget(nil)
        gun:SetTargetValid(false)
    end
end

function ENT:ValidateCurrentTarget()
    local gun    = self.Gun
    if not IsValid(gun) then return end
    local target = gun:GetTarget()

    if not IsValid(target) or target:Health() <= 0 then
        gun:SetTarget(nil)
        gun:SetTargetValid(false)
    end
end


-- ──────────────────────────────────────────────
-- Think
-- ──────────────────────────────────────────────

function ENT:Think()
    local gun = self.Gun
    if not IsValid(gun) then
        self:Remove()
        return
    end

    -- Keep our position synced to the gun
    self:SetPos(gun:GetPos())

    local ct = CurTime()

    if ct >= self.NextTargetValidate then
        self.NextTargetValidate = ct + TARGET_VALIDATE_INTERVAL
        self:ValidateCurrentTarget()
    end

    -- Only search if we don\'t have a good target already
    if not gun:GetTargetValid() and ct >= self.NextTargetSearch then
        self.NextTargetSearch = ct + TARGET_SEARCH_INTERVAL
        self:FindNewTarget()
    end

    self:NextThink(CurTime() + 0.05)
    return true
end


-- ──────────────────────────────────────────────
-- Cleanup
-- ──────────────────────────────────────────────

function ENT:OnRemove()
    local gun = self.Gun
    if IsValid(gun) then
        -- Release the shooter slot so the gun goes idle
        gun:SetTarget(nil)
        gun:SetTargetValid(false)
        gun:SetBotMode(false)
        gun:LeaveTurret(self)
    end
end
