# Gred NPC Emplacements

Makes every gun from [Gredwitch's Emplacement Pack](https://steamcommunity.com/sharedfiles/filedetails/?id=593428013) usable by Combine soldiers and other hostile NPCs — no player needed.

## Requirements

- **Gredwitch's Emplacement Pack** (workshop) must be installed and loaded.
- Garry's Mod server/single-player.

## How it works

Each gun from the pack already has a full **bot mode** (`SetBotMode`, `SetTarget`, `GrabTurret`).  
This addon attaches an invisible `gred_npc_emp_controller` entity to the gun, which:

1. Calls `gun:GrabTurret(self)` and `gun:SetBotMode(true)` to take ownership as a fake shooter.
2. Implements all player-method stubs (`IsPlayer`, `KeyDown`, `EyeAngles`, etc.) so the gun's `Think()` runs cleanly.
3. Searches a 2500-unit sphere around the muzzle every 0.25 s for the closest visible hostile NPC or player.
4. Sets `gun:SetTarget(enemy)` — the pack's own `GetShootAngles()` then handles all aiming math (yaw/pitch, progressive turn, ballistic arcs for cannons).
5. Feeds `KeyDown(IN_ATTACK) = GetTargetValid()` and `KeyDown(IN_RELOAD) = ammo <= 0` so firing and reloading happen automatically.

## Placing guns

### Spawn Menu
Open the **Emplacements → NPC Emplacements** tab in the tool menu, pick the gun from the dropdown, and click **Place NPC Gun Spawner**.  
The spawner is admin-only.

### Console
```
gred_npc_emp_spawnent gred_emp_m2
```
Replace `gred_emp_m2` with any valid gred_emp class.

## Supported gun classes

| Class | Name |
|---|---|
| gred_emp_m2 | M2 Browning .50 cal |
| gred_emp_mg42 | MG42 |
| gred_emp_mg34 | MG34 |
| gred_emp_dshk | DShK |
| gred_emp_nskv | NSV |
| gred_emp_ksp58 | KSP58 |
| gred_emp_m1919 | M1919 |
| gred_emp_bren | Bren |
| gred_emp_vickers | Vickers |
| gred_emp_maxim | Maxim |
| gred_emp_mg08 | MG08 |
| gred_emp_zpu1 | ZPU-1 (AA) |
| gred_emp_zpu2 | ZPU-2 (AA) |
| gred_emp_zpu4 | ZPU-4 (AA) |
| gred_emp_m1 | M1 Bofors 40mm (AA) |
| gred_emp_flakvierling | Flakvierling 38 (AA) |
| gred_emp_pak40 | PaK 40 |
| gred_emp_zis3 | ZiS-3 |
| gred_emp_m101 | M101 Howitzer |
| gred_emp_d30 | D-30 Howitzer |
| gred_emp_mortar60 | 60mm Mortar |
| gred_emp_mortar81 | 81mm Mortar |
| gred_emp_mortar120 | 120mm Mortar |

## Architecture

```
gred_npc_emp_spawner  (point entity, invisible)
    └── spawns: gred_emp_<class>  (the actual gun, owned by the pack)
    └── spawns: gred_npc_emp_controller  (invisible, parented to gun)
            │
            ├── GrabTurret(self)  →  gun.GetShooter() == controller
            ├── SetBotMode(true)  →  gun.Think() uses bot path
            ├── SetTarget(enemy)  →  gun.GetShootAngles() aims at enemy
            └── KeyDown stubs     →  gun fires + reloads automatically
```

## Extending

To make any new gred_emp_* gun work, simply add its class to the GUNS list in  
`lua/autorun/client/gred_npc_emp_spawnmenu_cl.lua`. No other changes needed.
