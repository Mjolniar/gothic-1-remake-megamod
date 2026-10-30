Module "locks" (lock picking that follows the hero's skill 1.0) - Gothic 1 Remake, UE4SS Lua
============================================================================================
AI-generated. Bugs: see G1R_MegaMod\README.txt.

Function
  A lock is a row of connected pieces to bring to the middle; moving one drags others.
  The game removes connections by skill: none for untrained, the first for skilled, the
  first two for master. A pick survives 2 / 4 / 6 wrong moves (moves a piece cannot make).
  This module sets both per skill level: connections removed, and wrong moves per pick
  (or picks never break). A note says what changed when a lock starts.
  Ships "as the game has it". Off or all levels at game values = game not read.

Settings (Scripts\config.lua; app page "Lock picking"; in-game menu "G1R Lock picking";
file ~5 s, menu at once; applies from the next lock, never to a lock in progress)
    Enabled                false = off

    UntrainedConnections   connections removed while untrained / skilled / master:
    SkilledConnections
    MasterConnections
        "as the game has it"   untrained none, skilled 1, master 2
        "none"                 none removed (harder for skilled and master)
        "1", "2"               first one / first two
        "all"                  every piece moves alone
        "half"                 half of this lock's connections
        "safe"                 as many as this lock is proven solvable with (below)

    PicksNeverBreak        true = picks never break mid-lock
    UntrainedWrongMoves    wrong moves per pick:
    SkilledWrongMoves      0 = game (2 / 4 / 6), or 1 to 99
    MasterWrongMoves       (ignored while PicksNeverBreak is true)

    ShowMessage            note when a changed lock starts
    LogLocks               UE4SS.log line per lock started, with changes

  In-game menu choices are numbers: 1 = as the game has it, 2 = none, 3 = 1, 4 = 2,
  5 = half, 6 = safe, 7 = all. Button: "Put the game's own values back now" (see Saves).
  In config.lua choices are quoted text: Config.SkilledConnections = "2", not = 2.

  Example - untrained as the game, skilled as easy as each lock allows, master with no
  connections:
    Config.SkilledConnections = "safe"
    Config.MasterConnections = "all"

  Hidden (add to config.lua by hand):
    LookSeconds = 1    hero check interval (0.25 to 10 s)

  Console (UE4SS console):  locks            status
                            locks reload     re-read config.lua
                            locks restore    restore game values (see Saves)

Which choices are safe
  Removing connections can make a lock unsolvable. Choices were checked against the
  game's 346 lock definitions (332 on chests or doors; 14 for a disabled random-lock
  feature):
  - "none", "1", "2", "all": every one of the 332 locks stays solvable. "1" and "2" are
    the game's own skilled/master values.
  - Fixed 3, 4, 5 ... not offered: 78 of 332 locks become unsolvable at some value from 3
    up to all.
  - "safe": per lock, the largest proven value (solvable at it and every smaller value).
    For 267 of 346 locks that is all connections; others 1 to 6.
  - "half": half the connections (rounded down), capped at "safe".
  - "half" and "safe" never remove fewer than the game does at the hero's level, for
    every chest or door lock. (One unused test lock is unsolvable at the master value
    even in the unchanged game; the table holds its largest solvable value.)
  "Solvable" was checked by a program trying every lock position; the test suite plays a
  solution for every lock at every value the module can write. Based on the minigame
  rules read from the game's code (see In the game).
  "half"/"safe" values are in Scripts\lockdata.lua, for this game version. Locks not in
  the file stay as the game has them. After a game update that changes locks, use "all"
  or "as the game has it" until the file is rebuilt. An unsolvable lock is not damaged:
  leave it, change the setting, start again (the lock's reset key restores its pieces).

Behaviour
  - "half"/"safe" apply to chests only; doors get the game's values with these two
    choices (the door's lock is not known early enough). Fixed choices work for both.
  - A setting changed mid-lock applies from the next lock. A pick breaking mid-lock does
    not change the lock either.
  - When the hero learns the next skill level, its values are written within a second.
  - The game consumes picks two ways: breaking after its wrong-move limit, and losing a
    pick with at least one wrong move when leaving without opening. These settings
    change only the first; giving up after a wrong move still costs the pick. Opening
    keeps it.
  - Unchanged: XP for picking, who notices you, picks in the inventory.

Saves
  Both values are hero attributes and are saved.
  - With a fixed choice or wrong-move count active, saves hold the changed value. No
    effect while the module stays on.
  - With "half"/"safe" the value is changed only while a chest lock is open; a save then
    holds that lock's value. Between locks the module restores the game value when it
    finds another (logged once), so one lock's value never meets another lock - which
    could make a door unsolvable.
  - Turning the module off (Enabled = false) or a level back to "as the game has it"
    while running: the game values for the hero's level are restored first (at once, or
    after the current lock), then the module stops. Later saves are clean.
  - A changed value can stay in a save if the game closes or crashes while changed and
    the module is off or removed before that save is loaded. The game's code suggests it
    resets its values on load, which would fix this - not confirmed in game.
  - Fix, if lock picking is still changed with the module off: keep the mod installed and
    this module loaded (Enabled may be false), load the save, press "Put the game's own
    values back now" (in-game menu "G1R Lock picking") or type  locks restore  in the
    UE4SS console. Then save. If the module cannot tell the hero's level, name it:
    locks restore untrained  /  locks restore skilled  /  locks restore master.
  - Before removing the mod for good: turn this module off in game, wait a second, save.
  A leftover value does not damage the save: locks are easier or harder until the game
  rewrites its values (when the hero learns a skill level). Worse case: a leftover
  "half"/"safe" value (save made mid chest lock) with the module off or removed can make
  a few locks unsolvable. The fix above repairs that too.

Other lock picking mods
  One at a time. While "SkillfulLocks" is enabled this module is not loaded (UE4SS.log:
  "locks left to the separate mod SkillfulLocks"). To switch, disable it and carry over:
    untrained: left alone   ->  UntrainedConnections = "as the game has it"
    skilled: "auto"         ->  SkilledConnections = "safe"
    master: "all"           ->  MasterConnections = "all"
  "safe" is this module's own check of the same question. Difference: at doors the
  skilled hero gets the game's lock (1 removed), not an easier one.

How it works
  The values are hero player state attributes LockpickPrecision and LockpickDurability,
  read by the game when a lock is set up. Once a second the module reads the skill level
  (a tag), whether a lock is in progress (another tag) and both attributes; a differing
  value is written and read back. Nothing is written mid-lock. Own values are tracked
  and the game's restored before stopping.
  "half"/"safe" need the lock before setup: the module hooks the function that starts a
  chest lock (once, only while such a choice is in use), reads the lock name and writes
  its value; the game's value returns when the lock ends. If the hook fails or never
  fires, these choices leave locks as the game has them and say so (UE4SS.log, locks).
  Nothing else is registered: no notifications, no repeated name searches. (A
  2026-10-01 crash came from another mod repeating a search for a missing function at
  every lock.)

In the game
  Ran with megamod 0.2.1 (2026-10-04; master lock picker, "all" for master).
  - Seen: 11 locks started, each with the module's value (99) set; level read from skill
    tags; the game wrote its value (2) back 7 times and the module re-set it. Chest lock
    names match lockdata.lua (seen in a session with another author's mod).
  - Read from the game's code and data, not seen in the game: the minigame rules behind
    "safe"; setting wrong moves the same way; the hooked function for "half"/"safe";
    untrained and skilled settings.
  - Unknown: what the lock screen shows for picks with far more than 2 to 6 wrong moves.
  If tags cannot be read, the level is inferred from the game's values and locks in
  progress are not detected (no note; changes do not wait for the lock to end);
  "half"/"safe" then leave every lock as the game has it. They also do so when tags
  answer but show no skill level (logged once). Unwritable values are left and logged
  once.
  Diagnostics (Scripts\diagnostics\): how the level was read, whether values were set at
  lock start, whether the hook ran, hero values after a load.
