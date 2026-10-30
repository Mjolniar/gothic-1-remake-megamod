Module "intro" - game start (G1R_MegaMod)
=========================================
AI-generated. Bugs: see G1R_MegaMod\README.txt.

Function
  * Skip the logos (Alkimia, THQ Nordic, legal screen). They are the start list of the
    game's loading screen. The game reads Game.ini (%LOCALAPPDATA%\G1R\Saved\Config\Windows)
    over its packed config, so the settings app writes the start list without the logos
    there, between two marker lines:
      ; ---- G1R_MegaMod: skip the logos at game start (begin) ----
      ...
      ; ---- G1R_MegaMod: skip the logos at game start (end) ----
    Written on Save with the game closed (while running it waits and says so); exactly
    those lines are removed when switched off. Nothing else in Game.ini changes. The first
    prior Game.ini is kept as Game.ini.before-G1R_MegaMod; a Game.ini the app created is
    removed when switched off. Applies from the next start. The engine's loading picture
    still shows while the menu loads. If Game.ini already sets a start list (another tool,
    by hand), the app leaves it and says so.
  * Skip the new-game film: a new game shows the usual loading screen instead. The game
    picks its loading screen by a type set before the map loads; at the start of the map
    load the module turns "game intro" into the usual type. Loading a save is unaffected.
    (The game also lets you skip the film: hold Space, Esc or left mouse for a second.)
  * The module never writes Game.ini or any game file; it only reads Game.ini and logs
    whether this start skipped the logos.
  * Nothing saved.
  * Console: intro (status), intro reload (re-read config.lua).

Not tested in the game
  Whether the game takes the start list from Game.ini: after the first start with the
  setting on, UE4SS.log says "this start of the game skipped the logos" or "... played
  the logos". Whether the film type is already chosen when the module looks: with the
  setting on, each map load notes the type (diagnostics: intro.loading_type); a new game
  that still shows the film means it was. In either case send UE4SS.log and
  G1R_MegaMod's Scripts/diagnostics.

Cost
  Both off: reads Game.ini once at start. Skip logos: one check of the start list after
  the first map load. Skip film: one query at the start of every map load.

Settings: Scripts/config.lua (app page "Interface > Game start"; not in the in-game menu -
logos cannot change while the game runs)
  Enabled          module on (true)
  SkipLogos        skip startup logos (false)
  SkipNewGameFilm  skip the new-game film (false)

Removing the mod
  First switch "Skip the logos" off in the app and Save with the game closed, or delete
  the lines between the two marker lines in Game.ini.
