Module "movement" - walk, run, swim and scavenger speed (G1R_MegaMod)
=====================================================================
AI-generated. Bugs: see G1R_MegaMod\README.txt.

Function
  * Hero on foot: the hero's speed factor (movement attribute SpeedModifier; 1.00 from
    his character definition, lowered a few % by tiredness) x multiplier: walk, run,
    sneak.
  * Swimming: the hero's three swim speeds (slow, normal, fast: 100, 150, 220) x
    multiplier, in the default object of LocomotionSpeedSettings_Swim_Laying_Player.
  * Scavenger: its speed factor (SpeedModifier, 1.00; tiredness moves it a few %) x
    multiplier, ridden or following. Found by the game's name lookup (as in "mount"), no
    search of all objects.
  * 1.00 = game. Back to 1.00 or module off restores game values.
  * The factor set is always 1.00 x multiplier (the definition's 1.00). New attributes
    (summon, loaded save) get that value, never multiplied again (1.0.0 compounded it on
    every summon).
  * A value changed by someone else (another mod, the game) is left alone - logged once -
    until the next setting change or new attributes.
  * Nothing saved.
  * Console: movement (status), movement reload (re-read config.lua).

Seen in the game (1.0.0 and 1.1.0, 2026-10-06)
  Swim table and scavenger factor found and written; the player saw a faster scavenger
  (too fast after several summons: fixed in 1.1.0). 1.1.0 found the factor at 1.00 and
  set 1.30 once (MountSpeed 1.30). A summon under 1.1.0 not seen yet. Hero factor (1.1.0):
  offline tests only.

Not tested in the game
  Whether changed swim speeds and factors apply at once or only to a hero/scavenger
  created later (e.g. after loading). If a setting seems to do nothing, reload the save;
  if still nothing, send UE4SS.log and G1R_MegaMod's Scripts/diagnostics.

Cost
  None at 1.00. Otherwise one check every 2 s: hero factor, swim table (3 values),
  scavenger factor.

Settings: Scripts/config.lua (app page "Hero > Movement"; in-game menu "Movement"; live)
  Enabled        module on (true)
  HeroSpeed      hero on foot, times (1.00; 0.50 - 3.00)
  SwimSpeed      swimming, times (1.00; 0.50 - 3.00)
  MountSpeed     scavenger, times (1.00; 0.50 - 3.00)
  LogChanges     UE4SS.log line per change or restore (false)
  Not part of the settings app presets.
