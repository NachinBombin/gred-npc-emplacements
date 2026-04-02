-- gred_npc_emp_init.lua
-- Initialises the NPC emplacement controller system.
-- Hooks into the world to let NPC controllers spawn alongside gred emplacements.

if not SERVER then return end

gred_npc_emp = gred_npc_emp or {}

-- Registry: maps a gred emplacement entity (gun entity) -> its NPC controller
gred_npc_emp.Controllers = {}

-- Registers a controller for a given gun entity
function gred_npc_emp.RegisterController(gun, controller)
    gred_npc_emp.Controllers[gun] = controller
end

function gred_npc_emp.GetController(gun)
    return gred_npc_emp.Controllers[gun]
end

-- Clean up dead entries
hook.Add("EntityRemoved", "gred_npc_emp_cleanup", function(ent)
    if gred_npc_emp.Controllers[ent] then
        local ctrl = gred_npc_emp.Controllers[ent]
        if IsValid(ctrl) then ctrl:Remove() end
        gred_npc_emp.Controllers[ent] = nil
    end
end)
