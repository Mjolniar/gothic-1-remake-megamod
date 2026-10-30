Module "repopulate" (G1R_Repopulate 1.4) - Gothic 1 Remake, UE4SS Lua
======================================================================
AI-generated. Bugs: see G1R_MegaMod\README.txt.

Defaults
  Creatures   each missing creature: 35 % per 24 in-game hours. Elites (Shadow Beasts,
              Swampsharks, Skeleton Mages): 15 %. Per-species chance/interval or off.
  Corpses     a returning creature removes one corpse of its kind at that spot (generic
              creatures only; never humans, NPCs, orcs, named/boss/quest; never within
              40 m of you)
  Herbs       plants, berries, mushrooms regrow after 24 in-game hours
  Items       other world items return, ~15 % per in-game day
  Containers  emptied chests/crates/corpses restock original contents: 30 %/day in camps
              and mines (Old, New, Swamp, Bandit Camp, Old and Free Mine), 10 %
              elsewhere. Your own stored items untouched. Nothing added while you stand
              at the container.
  Crime       optional switch (Config.Crime). On = game rules. See below.

  1 in-game day ~ 96 real minutes; sleeping counts.

Settings
  Scripts\config.lua (commented): chances and timers per group and species, corpses,
  containers, crime, advanced. Settings app G1R_Repopulate_Settings.exe (in this folder)
  edits the same file (presets, scale all chances/timers). Reloaded within ~15 s
  (UE4SS.log: "settings reloaded").

Looted before install
  - Item spots: the game stores when each was emptied; they refill on your next visit
    once due.
  - Containers: already missing items when first seen = emptied 3 days ago
    (RetroactiveDays); rolls at once.
  - Creatures: dead creatures stay "dead" in the save, so their points count as
    populated.
  Base state = the game's own data (container, item spot, spawn point definitions). No
  old save needed.

Crime and restocked loot
  Opening/picking an owned chest is judged by the chest as usual. Restocked items carry
  no owner mark of their own; whether taking them counts as theft is not checked in game.
  Regrown items on owned spots get owners from the spot. Theft memory fades after
  12-72 in-game hours. One-time owned spots (e.g. Gomez's rooms) become repeatable.

Crime switch (Config.Crime in Scripts\config.lua)
  Enabled = true (default): game rules; crime system untouched.
  Enabled = false turns off (each can stay on):
    DisableTheft        stealing, pickpocketing, lockpicking, using others' things
    DisableTrespassing  others' huts and areas, sneaking
    DisableWeapons      drawn weapons or fists, threatening, blocking the way
    ForgetOldCrimes     also wipes your past crimes of those kinds
  Always counts: hitting and killing people. Story fights and defeat bookkeeping
  untouched. Already hostile people stay so until it ends.
  DisableTheft/DisableTrespassing also stop the owner/guard who hears you at an owned
  chest, door or place and walks over.
  Not covered: noisy items in someone's area still draw them; bed owners still wake you.
  How: each crime is looked up in one rule table on the crime subsystems (yours and every
  witness's). Off points the rule at the "no victim" entry, so the crime is dropped
  before it is recorded. On restores the rules. The game rebuilds the table on every
  load; the mod reapplies ~1 s later. Never stored in a save. Forgotten crimes are removed
  with the game's own function and stay forgotten when saved.
  The noise walk-over is a separate response module; while off it is made to require a
  tag only the player has. Memory only; undone by switching on or restarting.
  Follows the setting within ~15 s.

Never touched
  Named NPCs, humans, orcs and orc dogs, bosses and unique creatures (Prime / Named /
  Queen / golems / demons / Homer's lurker / Viran's bloodflies / ...), quest or story
  spawns, Sleeper Temple, Xardas' tower. Quest, unique, key, map and writing items, and
  items placed by story events.

How it works
  Data from the game's scripts (since 0.3.6 checked against the Feature Update 1 ModKit
  sources): 402 generic creature spawn points (815 creatures), 2506 item spots,
  528 containers. Game functions only:
  - creatures: WorldPointScript SpawnAIAgent, only at points populated in this
    playthrough, never above the original count, never within 40 m of you; corpses via
    the NPC state's RemoveFromWorld (as the level scripts do);
  - item spots: the game's own refill (m_Refillable / m_RefillHours), set after every
    load; turning a group off restores game values;
  - containers: counted with HasItemMain, refilled via DataModule_Container
    Multicast_AddNewItem. Item classes come from each container's default contents.
  The game saves creatures and items normally. A container is saved only when you open
  it; until then the mod remembers "restocked, not opened" and re-adds the same items on
  reload (no new roll). The mod never writes saves; its progress is in Scripts/state/.

Progress file
  Scripts\state\profile_<n>.lua, one per game profile. Written to .tmp, read back, then
  replaced; previous file kept as .bak and used if the newest cannot be read. An
  unreadable file is kept as .bad and the module starts fresh. To reset: close the game,
  delete profile_<n>.lua and profile_<n>.lua.bak.

Object safety (1.4)
  The game streams world parts constantly, fastest while riding. Up to 1.3 the module
  kept found objects; three crashes (2026-10-04/05) ended in a call on such an object or
  in a search of all objects. Since 1.4:
  - containers and creatures are tracked from the game's begin-play to end-play calls;
    afterwards they are not touched;
  - hero, clock, profile, crime rule sets and item spot list come from the engine, not
    searches;
  - the one remaining search (creature count, once per roll) waits after map loads and
    mass unloads;
  - mounting, dismounting, leaving a bed: waits 3 s and continues. Restarts on map load
    (incl. loading a save), clock going back, or profile change. Idle while paused;
  - main menu (no clock): clock searches back off from 2 s to 2 min.
  If the engine or these calls do not answer, the module falls back to 1.3 behaviour and
  says so in UE4SS.log and "repop" ("objects in play: ...", "this run: ...").

Console (UE4SS console)
  repop          status
  repop now      run a creature cycle now (testing)
  repop items    re-apply item refill settings
  repop reload   re-read config.lua
  repop crime    crime switch status (re-check now)
  repop save     write the state file now

UE4SS.log lines
  [G1R_Repopulate] v1.5.1 loaded: 402 creature spawn points ...
  [G1R_Repopulate] session started at day N hh:mm | state profile_X.lua ...
  [G1R_Repopulate] session reset N (map load | the game clock went back |
                   another player controller | the profile changed)
  [G1R_Repopulate] the game's begin / end of play calls are not used any
                   more (reason); objects are found and checked the old way
  [G1R_Repopulate] world items: 2506 spots set refillable ...
  [G1R_Repopulate] creature cycle (timer, due 24h x1): ... respawning N
  [G1R_Repopulate] settings reloaded: creatures on 35%/24h ...
  [G1R_Repopulate] containers: N here, N waiting to restock, N restocked
                   and not opened yet | session: ...   (on change, max every 5 min)
  [G1R_Repopulate] containers: first emptied container noticed (IO_...,
                   N item(s) missing)
  [G1R_Repopulate] restocked IO_... (settlement): N item(s)
  [G1R_Repopulate] restocking IO_... did not work (N of M item(s) arrived)
  [G1R_Repopulate] containers: the item classes of IO_... cannot be read
                   from the game's data; containers like it are left alone
  [G1R_Repopulate] crime: OFF for theft, trespassing, weapons - N rules
                   switched in M rule sets, N noise reactions off
  [G1R_Repopulate] crime: noise reaction not switched (reason)
  [G1R_Repopulate] crime: N earlier crimes forgotten
  [G1R_Repopulate] crime: back to the game's own rules
  [G1R_Repopulate] crime: switch not applied completely (reason)
                   = failed; game rules still active

Turning it off
  Repopulate = false in the mod's Scripts\config.lua (or remove the mod). Returned
  creatures and items stay as normal game objects. Crime switch is gone next start
  (forgotten crimes stay forgotten).
