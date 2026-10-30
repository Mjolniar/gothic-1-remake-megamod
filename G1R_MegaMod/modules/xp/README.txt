Module "xp" (experience multiplier 1.0) - Gothic 1 Remake, UE4SS Lua
====================================================================
AI-generated. Bugs: see G1R_MegaMod\README.txt.

Function
  Multiplies every XP gain (fights, quests, lock picking, ...): 2.0 = double, 0.5 = half.
  1.0 (shipped) or off = game XP unchanged.
  Note after a gain:  +90 experience  (30 -> 120, x4.0)

Settings (Scripts\config.lua; app page "Experience"; in-game menu "G1R Experience";
file ~5 s, menu at once)
    Enabled              false = off
    Multiplier           0 to 10; 1.0 = unchanged
    LargeGainFrom        gains at least this size count as large (quest rewards);
                         0 = no distinction
    LargeGainMultiplier  multiplier for large gains (0 to 10); only if LargeGainFrom > 0
    ShowMessage          on-screen note (look set on page "General")
    LogGains             UE4SS.log line per gain
  Hidden (add to config.lua by hand):
    MaxGain              larger jumps are not treated as gains (50000)
    SettleSeconds        no multiplying this long after loading (10)
    CheckMilliseconds    check interval (250)
  Console (UE4SS console):  xp          status
                            xp reload   re-read config.lua

Behaviour
  - The game's "+ experience" popup shows the unmultiplied amount; the character screen
    total is multiplied.
  - A level unlocked by added XP is granted on your next XP gain (the game checks then).
  - Never multiplied: jumps from loading a save or starting a new game; gains while off
    or at 1.0. Changing the multiplier never changes existing XP.

Other XP multipliers
  One at a time. While "EXPModifier" is enabled this module is not loaded (UE4SS.log:
  "xp left to the separate mod EXPModifier"). To switch, disable it.

How it works
  XP is a level progression attribute of the hero's player state, read 4 times a second.
  On a plausible rise (max 50000) it adds gain x (multiplier - 1). Nothing else changed;
  no hooks; no save writes.

In the game
  Ran with megamod 0.2.1 (140 min, 2026-10-04, x10): 70 gains multiplied, +121590 XP
  total; XP found via the player state; every write read back. Not seen: standing down
  for another multiplier (none installed). Diagnostics: Scripts\diagnostics\.
