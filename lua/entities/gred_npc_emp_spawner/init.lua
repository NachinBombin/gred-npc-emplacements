-- gred_npc_emp_spawner/init.lua
-- An invisible point entity that spawns a chosen gred_emp_* gun
-- and immediately attaches an NPC controller to it.
-- Place this in the world or spawn it via the context menu.

AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

local IsValid = IsValid

function ENT:Initialize()
    self:SetNoDraw(true)
    self:SetNotSolid(true)
    self:SetMoveType(MOVETYPE_NONE)

    -- Wait one tick so the map is fully loaded before spawning the gun
    timer.Simple(0.1, function()
        if not IsValid(self) then return end
        self:SpawnGun()
    end)
end

function ENT:SpawnGun()
    local gunClass = self:GetNWString("GunClass", "gred_emp_m2")

    local gun = ents.Create(gunClass)
    if not IsValid(gun) then
        -- Fallback: class not registered yet, retry next tick
        timer.Simple(1, function()
            if not IsValid(self) then return end
            self:SpawnGun()
        end)
        return
    end

    gun:SetPos(self:GetPos())
    gun:SetAngles(self:GetAngles())
    gun:Spawn()
    gun:Activate()

    self.Gun = gun

    -- Create and attach the NPC controller
    local ctrl = ents.Create("gred_npc_emp_controller")
    ctrl:SetPos(gun:GetPos())
    ctrl:Spawn()
    ctrl:Activate()
    ctrl:AttachToGun(gun)

    self.Controller = ctrl
end

function ENT:OnRemove()
    if IsValid(self.Controller) then self.Controller:Remove() end
    if IsValid(self.Gun)        then self.Gun:Remove() end
end
