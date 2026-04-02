-- Adds a spawn menu tool to configure the gun class before placing a spawner.
if not SERVER then return end

hook.Add("PopulateToolMenu", "gred_npc_emp_toolmenu", function()
    -- Nothing server-side needed; the client side panel drives this
end)
