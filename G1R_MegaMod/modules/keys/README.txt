Module "keys" - key list (G1R_MegaMod)
======================================
AI-generated. Bugs: see G1R_MegaMod\README.txt.

Function
  * F3 (configurable) toggles a small box at top left listing your keys and what they do.
    Works in the pause menu and in play; a map load hides it.
      - keys of this mod's modules that have one set (the list key, waits, scavenger);
      - keys of known other mods, read from their settings files each time the list opens:
        SharedModMenu (mod menu), HUDMap (HUD map, its settings), FocusNearbyPickups in
        PLuaModLoader (nearby items, corpses, chests, quick loot while on),
        G1R_AutoPickUpItemNative (pick up, auto pick up), G1R_PutAwayTorchRedux (torch);
      - any other UE4SS mod is listed as "keys not known".
    Key changes in those files show the next time the list opens. The box takes no clicks.
  * In the pause menu one small line at top left names the key ("F3 - list of keys").
    With no key set, the pause menu shows the whole list.
  * F3 is unused by the game (its key mappings use only F5 and F9 of the function keys)
    and by the known mods.
  * The pause menu is checked 4 times a second via the game's widgets (main player widget
    and the pause menu stack); nothing is kept. Nothing written.
  * Console: keys (status and list), keys reload (re-read config.lua).

Seen in the game (0.3.0, 2026-10-06)
  Pause menu found, list shown above it, five other mods read. 1.1.0 (key, line, smaller
  box): offline tests only.

Cost
  While the line or list shows: 4 property reads a second. Other mods' files are read when
  the list opens.

Settings: Scripts/config.lua (app page "Interface > Key list"; in-game menu "Key list")
  Enabled        module on (true)
  ListKey        key that toggles the list ("F3"; "" = none)
  InPauseMenu    pause menu line naming the key (true)
  OtherMods      include other mods' keys (true)
  TextSize       letter size (10; 8 to 16; notes use 12)
  ShowKey        1.0.0 key; unused (replaced by ListKey so the new key reaches files that
                 had "")
