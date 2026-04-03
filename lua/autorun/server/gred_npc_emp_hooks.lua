-- gred_npc_emp_hooks.lua
-- Server-side hooks that:
--   1. Inject KeyDown/IsPlayer/EyeAngles stubs onto any NPC that grabs a turret
--   2. Patch ShooterStillValid to accept live NPCs
--   3. Guard CalcAmmoType KeyDown calls for non-player shooters
-- This file must be loaded AFTER gred_emp_base, so we use a hook on
-- InitPostEntity to safely override the base methods.

hook.Add("InitPostEntity", "gred_npc_emp_patchbase", function()

    local base = scripted_ents.Get("gred_emp_base")
    if not base then return end
    local ENT = base.t

    ------------------------------------------------------------
    -- Patch: ShooterStillValid
    -- Original only handles players. We extend it to also keep
    -- NPCs alive as valid shooters.
    ------------------------------------------------------------
    local orig_ShooterStillValid = ENT.ShooterStillValid
    function ENT:ShooterStillValid(ply, botmode)
        if IsValid(ply) and ply:IsNPC() then
            return ply:Alive()
        end
        if orig_ShooterStillValid then
            return orig_ShooterStillValid(self, ply, botmode)
        end
        return IsValid(ply)
    end

    ------------------------------------------------------------
    -- Patch: CalcAmmoType
    -- Guards IN_RELOAD and IN_ATTACK2 calls so they don't error
    -- when the shooter is an NPC (which has no real KeyDown).
    ------------------------------------------------------------
    local orig_CalcAmmoType = ENT.CalcAmmoType
    function ENT:CalcAmmoType(ammo, IsReloading, ct, ply)
        if IsValid(ply) and ply:IsNPC() then
            if ammo < self.Ammo and self.Ammo > 0 and not IsReloading then
                self:Reload()
            end
            return
        end
        if orig_CalcAmmoType then
            orig_CalcAmmoType(self, ammo, IsReloading, ct, ply)
        end
    end

    ------------------------------------------------------------
    -- Patch: GrabTurret
    -- After the original runs, if the new shooter is an NPC,
    -- inject the stubs it needs so the gun's Think doesn't error.
    ------------------------------------------------------------
    local orig_GrabTurret = ENT.GrabTurret
    function ENT:GrabTurret(ply, shootOnly)
        if orig_GrabTurret then
            orig_GrabTurret(self, ply, shootOnly)
        end

        if IsValid(ply) and ply:IsNPC() then
            if not ply._gredEmpStubsInjected then
                ply._gredEmpStubsInjected = true

                function ply:KeyDown(key)
                    if key == IN_ATTACK then
                        local emp = self._gredActiveEmplacement
                        if IsValid(emp) then
                            return emp:GetTargetValid()
                        end
                        return false
                    end
                    return false
                end

                function ply:IsPlayer()
                    return false
                end

                function ply:EyeAngles()
                    local emp = self._gredActiveEmplacement
                    if IsValid(emp) then
                        local target = emp:GetTarget()
                        if IsValid(target) then
                            return (target:GetPos() - self:GetPos()):Angle()
                        end
                    end
                    return self:GetAngles()
                end

                function ply:GetEyeTrace()
                    local emp = self._gredActiveEmplacement
                    if IsValid(emp) then
                        local target = emp:GetTarget()
                        if IsValid(target) then
                            local startPos = self:GetPos()
                            local endPos   = target:GetPos()
                            return util.QuickTrace(startPos, endPos - startPos, emp.Entities)
                        end
                    end
                    return util.QuickTrace(self:GetPos(), self:GetForward() * 1000, {})
                end

                function ply:DrawViewModel() end
                function ply:GetPreviousWeapon() return NULL end
                function ply:GetActiveWeapon()   return NULL end
                function ply:Give()              return NULL end
                function ply:SelectWeapon()      end
                function ply:StripWeapon()       end
                function ply:SetActiveWeapon()   end
                function ply:CrosshairEnable()   end
                function ply:EnterVehicle()      end
                function ply:ExitVehicle()       end
                function ply:ChatPrint()         end
            end

            ply._gredActiveEmplacement = self
        end
    end

end)
