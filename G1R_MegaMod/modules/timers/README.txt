Module "timers" - remaining effect times (G1R_MegaMod)
======================================================
AI-generated. Bugs: see G1R_MegaMod\README.txt.

Function
  A small box lists active effects and time left, e.g. "Burning 7 s", "Healing 1:12",
  "Light 4:32", "Alcohol 1:00":
  * healing and mana over time from food and potions;
  * burning, frozen, electrified, wind, slowed;
  * knocked out; sleep, fear or charm on you;
  * Light spell (game's own spell timer; if unreadable, the module counts itself - that
    count keeps running during conversations, the game's does not);
  * alcohol and swampweed: time until worn off (from level and decay rate);
  * optionally every other timed effect, by the game's own name.
  Shown only while something is active. Read twice a second; nothing written.
  Console: timers (status), timers reload (re-read config.lua).

Seen in the game (0.3.0 and 0.3.2, 2026-10-06)
  Effect list read from the hero's ability system with time left; Light time from the
  engine's spell timer. Two effects had wrong names (spell mana cost as "Burning", hit
  counter as "Frozen"): excluded since 1.0.1 and 1.0.2.

Not tested in the game
  Alcohol and swampweed countdowns after a drink; effect kinds nobody has had in a logged
  session. If the box stays empty while burning or drinking, send UE4SS.log and
  G1R_MegaMod's Scripts/diagnostics (notes timers.* show which part failed).

Settings: Scripts/config.lua (app page "Interface > Effect timers"; in-game menu "Effect
timers")
  Enabled        module on (true)
  ShowFood       healing and mana over time (true)
  ShowElements   burning, frozen, electrified, wind, slowed (true)
  ShowMind       knocked out, asleep, afraid, charmed (true)
  ShowLight      Light spell (true)
  ShowDrinks     alcohol and swampweed (true)
  ShowOthers     every other timed effect (false)
  Position       box corner: "bottom left" (default), "top left", "bottom right",
                 "top right"
  DistanceX      distance from the side, screen units (24)
  DistanceY      distance from top or bottom (200) - adjust to sit above the health bar
  Font: page "Notes on screen" (module general: gothic, book, plain).
