Module "othermods" - other mods' settings (G1R_MegaMod)
=======================================================
AI-generated. Bugs: see G1R_MegaMod\README.txt.

Function
  Two values of two other mods, set from the settings app:
  * FocusNearbyPickups (in PLuaModLoader) highlight distance: maxRadius in
    FocusNearbyPickups.ini (mod default 10 m);
  * G1R_AutoPickUpItemNative pick-up distance: AreaLootingRadius in
    G1R_AutoPickUpItemNative.ini (mod default 5 m).
  Each mod reads its file once at game start. On Save with the game closed, the app
  writes only that one line (nothing else in the file or folder) and keeps the original
  as <file>.before-G1R_MegaMod. Applies from the next start. While the game runs the app
  writes nothing and says so.
  A switch that is off leaves the mod's file alone. To return to the mod's default, set
  10 m / 5 m and save, or restore the .before-G1R_MegaMod file.
  This module only reads the two files; UE4SS.log notes once if a file does not match
  the settings yet.
  Console: othermods (status), othermods reload (re-read config.lua).

Not in the in-game mod menu
  The other mods read their files only at game start.

Settings: Scripts/config.lua (app page "Other mods")
  Enabled          module on (true)
  SetHighlight     write the highlight distance (false)
  HighlightMeters  highlight distance, metres (10; 0 = no limit)
  SetLoot          write the pick-up distance (false)
  LootMeters       pick-up distance, metres (5)
