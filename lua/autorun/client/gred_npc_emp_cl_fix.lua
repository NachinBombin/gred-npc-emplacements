-- gred_npc_emp_cl_fix.lua
-- Clientside fix for cl_init.lua:275 crash.
-- When the shooter is a non-player entity (NPC), KeyDown doesn't
-- exist on the client, causing "attempt to call method 'KeyDown' (a nil value)".
-- We wrap the base ENT Think to inject safe stubs before the base code runs.

hook.Add("InitPostEntity", "gred_npc_emp_cl_patchbase", function()
    local base = scripted_ents.Get("gred_emp_base")
    if not base then return end
    local ENT = base.t

    local orig_Think = ENT.Think
    function ENT:Think()
        if not self.Initialized then
            self:Initialize()
            return
        end

        local ply = self:GetShooter()
        if IsValid(ply) and not ply:IsPlayer() then
            if not ply._gredCLStubsInjected then
                ply._gredCLStubsInjected = true
                function ply:KeyDown()       return false end
                function ply:IsPlayer()      return false end
                function ply:EyeAngles()     return self:GetAngles() end
                function ply:Alive()         return IsValid(self) end
                function ply:GetViewEntity() return self end
                function ply:GetEyeTrace()
                    return util.QuickTrace(self:GetPos(), self:GetForward() * 1000, {})
                end
            end
        end

        if orig_Think then
            orig_Think(self)
        end
    end
end)
