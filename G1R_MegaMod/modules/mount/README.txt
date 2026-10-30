Module "mount" - your scavenger (G1R_MegaMod)
=============================================
AI-generated. Bugs: see G1R_MegaMod\README.txt.

Name
  "Name of your scavenger" (settings app, page Mount; not in the in-game menu): shown over
  your scavenger instead of the game's. Empty = game name. Max 40 letters. Wild
  scavengers unchanged. Applied to the name widget at most 0.25 s after the game shows
  it (new in 1.1.0; not seen in the game yet).

Problem
  Sometimes the scavenger ignores the whistle until a restart. Three causes:
    1. You carry the riding block (State.RidingBlocked). Set in camps and no-riding
       areas, removed on exit; a missed exit leaves it until reload, and the follow
       routine gives up while you have it.
    2. It fears you: your own hit landed on it, it marked you hostile and flees.
       Cleared by restart.
    3. The whistle reached nobody: the follow routine waits for a caller forever.
  None is caused by this mod. The module finds which one and fixes it without restart.

Function
  * Each whistle (the game tags you with Action.CallMount for 3 s) logs one line, e.g.
      [G1R_Mount] whistle 3: you: riding block no, mounted no | scavenger:
                  42 m away, fears you no
    and a second line with the distance 8 s later ("Look again after").
  * If by then the scavenger is not here, not closer, and you are not riding, it is fixed
    ("When it did not come"):
      full  - riding block removed from you, fear removed from the scavenger, scavenger
              reset to its idle routine (friendly again). Note: "whistle again".
      safe  - same without touching the riding block (keeps camps no-riding; key or
              console still remove it).
      off   - log only.
    If the distance cannot be read, nothing is done.
  * A key ("Key that puts the scavenger right") and console words act at once:
      mount           status
      mount report    one check of you and the scavenger (also on screen)
      mount fix       fix now (as "full")
      mount reload    re-read config.lua
    In-game menu buttons: "Report the scavenger now", "Put the scavenger right now".

Cost
  One tag query per 0.25 s (like regen, locks, mining). The scavenger is looked up only
  on a whistle, by the game's name lookup - no search of all objects. With a name set: a
  check of the HUD name widgets per 0.25 s, plus the lookup while one shows.

Settings: Scripts/config.lua (settings app page "Mount" or in-game menu; live)
  Name           name over your scavenger ("" = game's)
  Enabled        watch whistles (true)
  AutoFix        "full" | "safe" | "off" (full)
  WaitSeconds    seconds from whistle to second check (8; 4 - 20)
  FixKey         the key ("" = none)
  ShowNotes      note when something was fixed (true)

If it still does not come, send
  UE4SS.log and Mods\G1R_MegaMod\Scripts\diagnostics\ (whistle lines, notes mount.*).
  They show which cause it was, or that it was none.
