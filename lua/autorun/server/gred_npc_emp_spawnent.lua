-- Handles the concommand that places a gred_npc_emp_spawner in the world.
if not SERVER then return end

concommand.Add("gred_npc_emp_spawnent", function(ply, cmd, args)
    if not IsValid(ply) then return end
    if not ply:IsAdmin() and not ply:IsSuperAdmin() then
        ply:PrintMessage(HUD_PRINTCONSOLE, "[Gred NPC Emp] Admin only.")
        return
    end

    local gunClass = args[1] or "gred_emp_m2"

    local tr = ply:GetEyeTrace()
    if not tr.Hit then return end

    local spawner = ents.Create("gred_npc_emp_spawner")
    spawner:SetPos(tr.HitPos + tr.HitNormal * 5)
    spawner:SetAngles(Angle(0, ply:EyeAngles().y, 0))
    spawner:SetNWString("GunClass", gunClass)
    spawner:Spawn()
    spawner:Activate()
end)
