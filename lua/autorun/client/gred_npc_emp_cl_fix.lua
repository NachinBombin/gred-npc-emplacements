-- gred_npc_emp_cl_fix.lua
-- Clientside fix: guards cl_init Think() against non-player shooters.
-- Uses a deferred Think hook because InitPostEntity fires before
-- Gredwitch finishes registering gred_emp_base clientside.

local function PatchBase()
    local reg = scripted_ents.GetStored("gred_emp_base")
    if not reg then return false end

    local ENT = reg.t or reg
    if not ENT or not ENT.Think then return false end

    if ENT._gredCLNPCPatched then return true end
    ENT._gredCLNPCPatched = true

    local orig_Think = ENT.Think
    function ENT:Think()
        -- Inject clientside stubs on any non-player shooter before base Think runs
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

        orig_Think(self)
    end

    return true
end

hook.Add("Think", "gred_npc_emp_patchbase_cl", function()
    if PatchBase() then
        hook.Remove("Think", "gred_npc_emp_patchbase_cl")
    end
end)
