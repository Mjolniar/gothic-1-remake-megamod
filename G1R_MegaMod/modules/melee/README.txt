Module "melee" (melee clean-ups 1.0) - Gothic 1 Remake, UE4SS Lua
================================================================
AI-generated. Bugs: see G1R_MegaMod\README.txt.

Function
  Three melee feel settings. Damage, combos and their timing are unchanged.

  1. Flow helper (mirrored follow-up swings). Game option (internally "fake sloppy
     combos"), on by default: repeating a direction as a swing ends starts a mirrored
     swing that looks like a combo but is not. Off: the same swing restarts; chains only
     from real combos. Leave to the game, or force off/on.
  2. Hit stop. Both fighters freeze ~1/20 s when a blow lands. Length in % of the game's:
     100 = unchanged, 0 = none, 200 = double.
  3. Camera shake on hits. Jolt and short zoom when a melee blow lands or hits the hero.
     Can be turned off for melee only; other shakes stay.

  Ships neutral (game, 100, true): nothing changed, game not read. Same when off.

Settings (Scripts\config.lua; app page "Combat"; in-game menu "G1R Combat"; file ~5 s,
menu at once; not applied during map loads or pause; first applied once a game runs)
    Enabled       false = off; changes reverted
    FlowHelper    "game" = untouched
                  "off" / "on" = set and re-set if changed (max 5 times in a row)
                  (in-game menu: 1 = game, 2 = off, 3 = on)
    HitStop       0 to 300, % of game length; 100 = unchanged
    HitShake      false = no camera shake on melee hits
    ShowMessage   note when a value is changed or restored

  Hidden (add to config.lua by hand):
    Config.CheckSeconds = 3      flow helper check interval (1 - 60 s)
    Config.VerifySeconds = 30    hit stop / shake re-read interval (5 - 3600 s)
    Config.FlowMethod = "auto"   "auto" = game function, else write the value; "option" =
                                 game function only; "direct" = value only (not stored
                                 by the game)
    Config.ActWhilePaused = false   true = also change while paused

  Console (UE4SS console):  melee          status
                            melee reload   re-read config.lua

Behaviour
  - Every setting is reversible: neutral value or module off restores the game. Hit stop
    and shake also reset on game restart (only changed in memory).
  - Flow helper is a game option stored per profile. While "off"/"on", changes in the
    game's options menu are undone within 3 s - change it here. If reverted 5 times in a
    row (something else insists), the module stops, logs once, and retries when you pick
    FlowHelper again. "game" restores the profile's previous value and frees the menu.
    Closing the game while "off"/"on" leaves that value in the profile (the previous
    value is only remembered while running); then "game" or removing the mod changes
    nothing - set "on" (game default) once or use the game's menu.
  - Several profiles: each is set when played; "game" restores only the current one (log
    names the others).
  - Lua reload while hit stop/shake are changed (UE4SS option, off by default): game
    values unknown, tables left as they are (HitStop 50 stays 50), noted in log and
    status. Restart to change again. Flow helper stays as set.
  - The game's own camera shake option (all shakes) overrides: off = no shake regardless.
    HitShake = false removes only melee shakes, incl. squashing a meat bug.
  - HitStop 0 also removes the slow-down of deflected blows. Bows have separate values,
    untouched.
  - Not possible (no safe switch): combo window timing, draw/swing speed, untrained clumsy
    swings (animation files, skill progression), knockback (one value for all fighters
    and bosses).

How it works
  The hero is not changed. Flow helper is set via the game's options function, so the
  game stores and shows it. Hit stop and shake are values and names in four small tables
  read on every blow; the module stores the originals, writes "game value x %" (never
  compounding), reads back, and re-checks every 30 s and after map loads. A table that
  cannot be read, written or verified is restored and left alone, with one log line.

In the game
  Loaded in every 0.2.1 session with nothing to change (all neutral), so it never read
  the game. None of its changes have run in game. Assumptions (from program and scripts):
  - the game's flow helper function is callable from a mod (else the value is written
    directly - not stored by the game - else left alone with a note);
  - whether and under which name the options menu shows the flow helper (another tool
    calls it "Close Combat Flow Helper");
  - the four tables are where expected and writable (another mod changes spell values
    the same way; these tables untried);
  - whether map loads restore game values (checked after every load; re-set if so).
  Status: console "melee" and Scripts\diagnostics\.
