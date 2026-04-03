-- gred_npc_emp_hooks.lua
-- Patches gred_emp_base to allow NPCs to man emplacements.
-- Uses a deferred one-shot Think hook because InitPostEntity fires before
-- Gredwitch finishes registering its scripted entities.

local function PatchBase()
    local reg = scripted_ents.GetStored("gred_emp_base")
    if not reg then return false end

    -- In GMod, GetStored returns a table with a "t" key containing the ENT methods
    -- but only after the entity has been fully registered. Check both.
    local ENT = reg.t or reg
    if not ENT or not ENT.GrabTurret then return false end

    -- Already patched
    if ENT._gredNPCPatched then return true end
    ENT._gredNPCPatched = true

    ------------------------------------------------------------
    -- Patch: ShooterStillValid
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
    ------------------------------------------------------------
    local orig_GrabTurret = ENT.GrabTurret
    function ENT:GrabTurret(ply, shootOnly)
        if orig_GrabTurret then
            orig_GrabTurret(self, ply, shootOnly)
        end

        if not (IsValid(ply) and ply:IsNPC()) then return end

        if not ply._gredEmpStubsInjected then
            ply._gredEmpStubsInjected = true

            function ply:KeyDown(key)
                if key == IN_ATTACK then
                    local emp = self._gredActiveEmplacement
                    if IsValid(emp) then return emp:GetTargetValid() end
                end
                return false
            end

            function ply:IsPlayer() return false end

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
                        return util.QuickTrace(self:GetPos(), target:GetPos() - self:GetPos(), emp.Entities)
                    end
                end
                return util.QuickTrace(self:GetPos(), self:GetForward() * 1000, {})
            end

            function ply:DrawViewModel()         end
            function ply:GetPreviousWeapon()     return NULL end
            function ply:GetActiveWeapon()       return NULL end
            function ply:Give()                  return NULL end
            function ply:SelectWeapon()          end
            function ply:StripWeapon()           end
            function ply:SetActiveWeapon()       end
            function ply:CrosshairEnable()       end
            function ply:EnterVehicle()          end
            function ply:ExitVehicle()           end
            function ply:ChatPrint()             end
        end

        ply._gredActiveEmplacement = self
    end

    return true
end

-- Retry every Think tick until gred_emp_base is fully registered
hook.Add("Think", "gred_npc_emp_patchbase_sv", function()
    if PatchBase() then
        hook.Remove("Think", "gred_npc_emp_patchbase_sv")
    end
end)
