Module "general" - shared note settings (G1R_MegaMod)
=====================================================
AI-generated. Bugs: see G1R_MegaMod\README.txt.

Function
  Shared look of the short on-screen notes other modules show (XP added, time skipped,
  ore mined, ...). Whether a module shows notes is that module's own switch.

Settings (Scripts/config.lua; app page "General"; in-game menu "G1R General"; live)
    NoteStyle      "box"       small box in a corner (black frame, pale yellow, black
                               text); falls back to the game's line if it cannot show
                   "subtitle"  the game's own line at the top
                   "off"       no notes
    NotePosition   "top right", "top left", "bottom right", "bottom left"
    NoteSeconds    1 to 10
    Letters        font of mod boxes (notes, key list, effect timers):
                   "gothic"    game blackletter (default)
                   "book"      game body text font
                   "plain"     engine font (as up to 0.2.3)
                   Map names have their own setting (markers, NameLetters).
  In-game menu button: "Show a note now".

Not tested in the game
  The box is built from plain engine widgets; its look is unconfirmed. If it cannot be
  built, UE4SS.log says "notes on screen are not available (...)" once and notes use the
  game's line. Whether the game fonts are found is unconfirmed; if not, text keeps the
  engine font (diagnostics: kit.letters).
