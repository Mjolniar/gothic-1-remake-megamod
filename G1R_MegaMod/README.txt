G1R_MegaMod 0.3.6 - Gothic 1 Remake, UE4SS Lua
===============================================

AI-generated: written entirely by AI. Expect bugs. Report them as GitHub issues:
https://github.com/Mjolniar/gothic-1-remake-megamod/issues
Include: what you did, what happened, UE4SS.log, the folder Scripts\diagnostics.

One mod folder, 16 modules and a flight recorder. One switch per module. All settings
apply while the game runs. The newer modules (general to othermods) ship neutral: they
change nothing and do not read the game until you set something.

Modules (details: modules\<name>\README.txt)
-------
  repopulate   Respawns creatures at their own spawn points (35 % per missing creature
               per 24 in-game hours; Shadowbeasts, Swampsharks, Skeleton Mages 15 %).
               Herbs regrow after 24 h. World items return (~15 %/day). Emptied chests
               restock original contents (30 %/day in camps and mines, 10 % elsewhere).
               Optional switch: theft, trespassing, drawn-weapon crimes off.
               Never touched: named NPCs, humans, orcs, bosses, unique creatures, quest
               and story spawns, quest/unique/key/map/writing items.
  markers      Map shows all 181 named NPCs at their current position. Teachers blue,
               traders gold, others red, orcs green; colour key bottom left. World map
               groups nearby people into numbered badges (hover for names).
  general      Look of on-screen notes (box, game line, off), corner, duration; font of
               all mod text: "gothic" (default), "book", "plain".
  regen        Mana and health regeneration: amount per step (% and/or points),
               interval, cap, delay after spending/damage; mana by magic circle; slower
               or off with a weapon drawn.
  magic        Spell damage, mana cost, cast time, projectile speed, range, stagger -
               for all spells, per kind (fire, ice, energy, wind) and per spell; heal
               amount; circle prices; ice spells that always freeze.
  melee        Flow helper (mirrored follow-up swings) game/off/on; hit stop 0-300 %;
               camera shake on melee hits off. Damage and combos unchanged.
  mining       Ore per swing from base, Strength, Dexterity, mining skill, with min/max;
               endless or longer-lasting veins.
  xp           XP multiplier 0-10, optional separate multiplier for large gains.
  locks        Per skill level: lock connections removed and wrong moves per pick, or
               picks never break.
  wait         Four time skips (two by minutes, two to an hour of day), each with key,
               menu button and console word. Blocked in fights, talks, cutscenes unless
               allowed.
  mount        Name over your scavenger. Logs every whistle; when it does not come,
               fixes the cause (stuck riding block, fear, lost caller) without restart.
  movement     Speed multipliers: hero on foot, swimming, scavenger (1.00 = game).
  intro        Skip startup logos (written to Game.ini by the settings app) and the new
               game film. Both off by default. Settings app only.
  keys         F3 (configurable) shows a key list for this mod and known other mods
               (SharedModMenu, HUDMap, FocusNearbyPickups, G1R_AutoPickUpItemNative,
               G1R_PutAwayTorchRedux). Pause menu shows one line naming the key.
  timers       Box with remaining effect times: heal/mana over time, burning, frozen,
               electrified, wind, slowed, knocked out, asleep, afraid, charmed, Light,
               alcohol, swampweed. Switch per kind; corner and offset.
  othermods    Distances of FocusNearbyPickups (highlight) and G1R_AutoPickUpItemNative
               (pick-up), written by the settings app. Both off by default.
  diagnostics  Log, errors and findings in Scripts\diagnostics\ (plain text; newest 5
               sessions, max 4 MB each). Stays on your PC. After a crash the session's
               .ops file names the step that was running. See its README.txt.

The mod never writes save files.

Known limits
------------
  Game path should be plain English characters. Umlauts, Cyrillic etc. may stop the mod
  finding its files (UE4SS.log: "could not be read"). Not tested.

Requirements
------------
  Gothic 1 Remake (Steam), build Build83_CL174209.
  UE4SS v3.0.1 Beta, build "AngelScript Fix 0.4"
  (UE4SS.log starts with "UE4SS - v3.0.1 Beta #0 - Git SHA #c838a8ac").
  Other game or UE4SS builds: untested.

Install
-------
  1. Close the game.
  2. Copy G1R_MegaMod into  <game>\G1R\Binaries\Win64\ue4ss\Mods\
     so that ...\Mods\G1R_MegaMod\Scripts\main.lua exists.
  3. enabled.txt switches the mod on. (mods.txt line:  G1R_MegaMod : 1 )
  4. Start the game. UE4SS.log shows:
       [G1R_MegaMod] v0.3.6 loaded: repopulate ok, markers ok, general ok, regen ok, ... | diagnostics normal -> ...

  A module is NOT loaded while a mod doing the same job is enabled (load line: "left to
  the separate mod ..."):

      module       skipped while this mod is enabled
      repopulate   G1R_Repopulate
      markers      NPCMarkers
      regen        G1R_RegenMana
      magic        G1R_MageBalance
      mining       BetterMining
      xp           EXPModifier
      locks        SkillfulLocks
      wait         G1R_WaitOnT

  To switch: disable the other mod and configure this module (other mods' settings are
  not read). For G1R_Repopulate and NPCMarkers you can copy Scripts\config.lua (and for
  G1R_Repopulate Scripts\state\) into modules\repopulate\Scripts\ or
  modules\markers\Scripts\.

Settings
--------
  Three ways, same files:

  1. Files (plain text, every setting commented):
       Scripts\config.lua                  modules loaded; diagnostics level; one engine
                                           switch, off (read at game start)
       modules\<name>\Scripts\config.lua   one per module; re-read within ~5 s
                                           (repopulate 15 s; markers at game start)
  2. Settings app (Windows): modules\repopulate\G1R_Repopulate_Settings.exe, if installed.
     Categories: Overview; World (Creatures, Herbs and items, Containers, Crime,
     Advanced); Combat (Regeneration, Magic, Fire, Ice, Energy and Wind spells, Circles,
     Melee); Resources (Mining); Hero (Experience, Lock picking, Mount, Movement); Time
     (Waiting, Rules); Map (Map pins, People, Colour key, Advanced); Interface (Notes on
     screen, Game start, Key list, Effect timers); Other mods (Other mods).
  3. In-game mod menu (needs SharedModMenu): "G1R General", "G1R Combat",
     "G1R Resources", "G1R Experience", "G1R Lock picking", "G1R Time". Applies at once
     and writes the files. Keys and texts cannot be set there.

  Key format: "Y", "F6", "CTRL+Y", "SHIFT+NUM_FIVE".

  Menu saves write config.lua.tmp, read it back, then replace config.lua.
  config.lua.bak = previous file. Both deletable with the game closed.

  Presets (settings app, box "Preset"): "1 - Base game" (hardest, game values) to
  "5 - Easiest" (every setting at its easiest end). "Apply preset" sets difficulty
  settings on all pages (respawn, crime, regen, magic, mining, XP, lock picking). Keys,
  notes, log switches, melee, waiting and per-species respawn stay. Nothing is written
  until Save. The box shows the matching preset ("- in use") or "Your own settings".
  All values: PRESETS.txt.

Console (UE4SS console, if enabled in UE4SS-settings.ini; nothing depends on it)
-------
  g1r            module and diagnostics status
  g1r diag       write a diagnostics report
  g1r dump       write module state to a file
  g1r help       command list
  repop          repopulate status (repop now | items | reload | crime | save)
  regen, magic, melee, mining, xp, locks, wait, mount, movement, intro, keys, timers,
  othermods      module status; "<module> reload" re-reads its config.lua.
                 More: wait 30, wait until 8, locks restore, mount report, mount fix

Uninstall
---------
  Close the game, delete G1R_MegaMod. Respawned creatures and items stay as normal game
  objects. Crime switch is gone next start. Other changes live only in the running game,
  except these - reset them BEFORE removing the mod:
    - melee FlowHelper "off"/"on": stored in your game profile. "game" restores the
      profile value in the same session; otherwise set "on" (game default).
    - locks: a save made with changed numbers keeps them until the game rewrites them
      (console: locks restore; modules\locks\README.txt, "Saves").
    - XP, mana, health, ore and time gained stay.
    - intro "Skip the logos": the Game.ini lines stay. Switch off in the app and Save
      with the game closed, or delete the lines between the two
      "G1R_MegaMod: skip the logos" lines in
      %LOCALAPPDATA%\G1R\Saved\Config\Windows\Game.ini.

Tested in the game
------------------
  0.2.1 (from 2026-10-03; 9 sessions, longest 140 min, no mod errors). Seen working
  (evidence: dev\facts\, dev\FACTS.md):
    - loader, diagnostics, settings service, notes, keys;
    - repopulate: refill settings on 2496 item spots; 62 creatures respawned at their
      spawn points; 81 containers restocked in one session and kept after reload;
      crime switch for theft, trespassing, weapons;
    - markers: pins, pools, names, hover lists on world and camp maps (0-4 units off the
      game's own player arrow on a 1400-1600 wide map);
    - regen: mana and health via the game's own path; casting block removed at zero
      mana; game pause detected;
    - magic: 73 values in 33 game objects changed, kept after every map load;
    - mining: game values read and replaced;
    - xp: 70 gains multiplied;  locks: module value set at 11 locks;  wait: 2 key skips.
  0.2.2 / 0.2.3 (2026-10-05, 3 sessions, longest 84 min): engine handover via map load
  hooks, controller and subsystems from the engine, begin/end-of-play tracking for
  containers and creatures; mount: whistle, scavenger came, name lookup and tags worked.
  0.3.0 (2026-10-06): all 16 modules loaded; pause menu found, key list shown (5 other
  mods read); effects, alcohol and Light timer read, timer box shown; blackletter font
  set; swim speeds and scavenger factor written and read back. Player reports led to
  0.3.1 (menu text cut off, key list too big and always on, mana cost shown as
  "Burning", map names hard to read).
  0.3.1 / 0.3.2 (2026-10-06, 24 and 131 min, no mod errors): scavenger speed set once
  (0.3.1 multiplied it twice via the save; 0.3.2 fixed), 65 drawn map pictures loaded,
  Light time read from the engine timer, two more whistles answered. "Frozen" on every
  hit led to 0.3.4.

  Not seen in the game yet:
    - movement: hero speed (HeroSpeed stayed 1.00); a scavenger summon under 0.3.2.
    - intro (0.3.0): whether the game takes the start list from Game.ini (UE4SS.log says
      "this start of the game skipped the logos"); whether the new-game film is swapped.
    - 0.3.1: menu texts fitting SharedModMenu columns, F3 key list and its pause menu
      line, timers without spell mana cost and with Light to its end, map names in game
      font.
    - 0.3.2: how drawn pins, badges, names and colour key look (they load; no report).
    - 0.3.3: scavenger name over it.
    - 0.3.4: "Frozen" only for a real freeze.
    - mount: a fix when the scavenger does not come (never needed yet).
    - 0.2.2: fallbacks when the engine does not answer, end of play for a container,
      kept pictures, .ops file after a crash.
    - Everything since 0.3.3: offline tests only (~7400 checks against a game model built
      from its scripts, data layout and code).
    - herbs and items actually returning; crime switch stopping people who walk over;
      a mined vein; melee changes in effect; changed magic values in a fight.
  Each module README lists its assumptions. A module that cannot do its job says so
  once in UE4SS.log and leaves the game alone.

Credits
-------
  Map pins idea: "Active NPCMarkers" (Nexus Mods, Gothic 1 Remake, mod 270). The markers
  module is a new implementation with none of its files.
  regen, magic, mining, xp, locks, wait do jobs also done by G1R_RegenMana,
  G1R_MageBalance, BetterMining, EXPModifier, SkillfulLocks, G1R_WaitOnT. Written anew;
  none of their code, text or data. The locks table is computed from the game's lock
  data.
  Spawn points, item spots, container contents, NPC names, map correction data: derived
  from the game's scripts and data.
  Runs on UE4SS (RE-UE4SS).
