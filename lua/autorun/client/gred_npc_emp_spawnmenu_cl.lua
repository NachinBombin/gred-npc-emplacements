-- Client-side spawn menu panel for choosing which gred_emp_* gun class to use.
if not CLIENT then return end

local GUNS = {
    { class = "gred_emp_m2",         label = "M2 Browning .50 cal" },
    { class = "gred_emp_mg42",       label = "MG42" },
    { class = "gred_emp_mg34",       label = "MG34" },
    { class = "gred_emp_dshk",       label = "DShK" },
    { class = "gred_emp_nskv",       label = "NSV" },
    { class = "gred_emp_ksp58",      label = "KSP58" },
    { class = "gred_emp_m1919",      label = "M1919" },
    { class = "gred_emp_bren",       label = "Bren" },
    { class = "gred_emp_vickers",    label = "Vickers" },
    { class = "gred_emp_maxim",      label = "Maxim" },
    { class = "gred_emp_mg08",       label = "MG08" },
    { class = "gred_emp_zpu1",       label = "ZPU-1 (AA)" },
    { class = "gred_emp_zpu2",       label = "ZPU-2 (AA)" },
    { class = "gred_emp_zpu4",       label = "ZPU-4 (AA)" },
    { class = "gred_emp_m1",         label = "M1 Bofors 40mm (AA)" },
    { class = "gred_emp_flakvierling",label = "Flakvierling 38 (AA)" },
    { class = "gred_emp_pak40",      label = "PaK 40" },
    { class = "gred_emp_zis3",       label = "ZiS-3" },
    { class = "gred_emp_m101",       label = "M101 Howitzer" },
    { class = "gred_emp_d30",        label = "D-30 Howitzer" },
    { class = "gred_emp_mortar60",   label = "60mm Mortar" },
    { class = "gred_emp_mortar81",   label = "81mm Mortar" },
    { class = "gred_emp_mortar120",  label = "120mm Mortar" },
}

hook.Add("AddToolMenuTabs", "gred_npc_emp_tab", function()
    spawnmenu.AddToolTab("Emplacements", "Emplacements", "icon16/gun.png")
end)

hook.Add("AddToolMenuCategories", "gred_npc_emp_cat", function()
    spawnmenu.AddToolCategory("Emplacements", "NPC Emplacements", "NPC Emplacements")
end)

hook.Add("PopulateToolMenu", "gred_npc_emp_panel", function()
    spawnmenu.AddToolMenuOption("Emplacements", "NPC Emplacements", "gred_npc_emp_spawner", "NPC Gun Spawner", "", "", function(panel)
        panel:ClearControls()
        panel:AddControl("Label", { Text = "Select gun class to spawn:" })

        local selectedClass = "gred_emp_m2"

        local combo = panel:AddControl("ComboBox", {
            Label   = "Gun Class",
            Options = {}
        })

        if IsValid(combo) then
            for _, gun in ipairs(GUNS) do
                combo:AddChoice(gun.label, gun.class)
            end
            combo.OnSelect = function(self_combo, index, value, data)
                selectedClass = data
            end
        end

        panel:AddControl("Button", {
            Label = "Place NPC Gun Spawner",
            Command = "gred_npc_emp_spawn"
        })

        -- Store selection so the concommand can read it
        concommand.Add("gred_npc_emp_setclass", function(ply, cmd, args)
            selectedClass = args[1] or selectedClass
        end)

        concommand.Add("gred_npc_emp_spawn", function()
            RunConsoleCommand("gred_npc_emp_spawnent", selectedClass)
        end)
    end)
end)
