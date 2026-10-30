Module "regen" (mana and health regeneration 1.0) - Gothic 1 Remake, UE4SS Lua
==============================================================================
AI-generated. Bugs: see G1R_MegaMod\README.txt.

Function
  Every few seconds the hero regains some mana and health. Per value: amount per step
  (% of max, flat points, or both), interval, cap, delay after spending/damage. Mana can
  scale with magic circle; both can slow or stop with a weapon or spell drawn.
  Ships with every amount 0: nothing regenerates. Off or all 0 = the game is not read.

Settings (Scripts\config.lua; app page "Combat"; in-game menu "G1R Combat"; file reload
~5 s, menu at once)
    Enabled            false = module off

    ManaEnabled        false = no mana regeneration
    ManaPercent        % of max mana per step (0 - 100)
    ManaFlat           points per step, added to the % (0 - 1000)
    ManaSeconds        seconds between steps (0.5 - 600)
    ManaUpTo           stop at this % of max (0 - 100)
    ManaPause          seconds to wait after mana went down (0 - 3600)
    ManaArmedPercent   % of the amount with weapon, fists or spell drawn (100 = same,
                       0 = none)

    ManaByCircle       true = amount depends on magic circle:
    ManaCircleNone       % without magic training
    ManaCircleNovice     % with the basics, before circle 1
    ManaCircleFirst      % in circle 1
    ManaCircleStep       % added per further circle
                       (100 and 10 = 100, 110, 120 ... 150 % in circle 6)

    HealthEnabled, HealthPercent, HealthFlat, HealthSeconds, HealthUpTo,
    HealthPause, HealthArmedPercent
                       same for health

    ShowMessage        note when regeneration starts after a wait and when it hits the cap
    LogSteps           one UE4SS.log line per step

  Example - mana 2 % every 3 s up to 75 %, 15 s after a spell; health 1 point + 1 %
  every 5 s up to 50 %, 30 s after damage:
    Config.ManaPercent = 2.0      Config.HealthPercent = 1.0
    Config.ManaSeconds = 3.0      Config.HealthFlat = 1.0
    Config.ManaUpTo = 75          Config.HealthSeconds = 5.0
    Config.ManaPause = 15         Config.HealthUpTo = 50
                                  Config.HealthPause = 30

Hidden settings (add to config.lua by hand)
    Method = "auto"             "auto" = game's own way, direct write if that fails;
                                "game" = game's way only; "direct" = direct write only
    ManaClearBlock = true       false = leave the out-of-mana casting block to the game
    StopWhenPaused = true       false = also count while the engine is paused
    StopWhenClockStands = true  false = also count while the game clock stands still
    SettleSeconds = 5           minimum wait after loading
    LookSeconds = 0.5           how often values are read (0.25 - 5 s)

Console (UE4SS console)
    regen          status, incl. why time is not counted (paused, clock stopped) and
                   time counted since start
    regen reload   re-read config.lua

Behaviour
  - Whole points only (game stores integers). Fractions carry over (2 % of 30 = 0.6 per
    step = 3 points in 5 steps).
  - Cap never passed (75 % of 30 = 22). Values above the cap (potion, sleep) are left.
  - Play seconds only: nothing in the pause menu, map loads or while the game clock
    stands. Sleep and time skips give nothing extra.
  - After loading, the wait (ManaPause / HealthPause, min 5 s) runs once first.
  - Every loss restarts the wait. Continuous drain (poison, held spell, extreme hunger)
    blocks regeneration until it stops.
  - Shortening a running wait cuts it at once (not below SettleSeconds); lengthening
    applies from the next loss.
  - Dead or unconscious hero: nothing. Dead hero never healed.
  - Out of mana, the game blocks casting until its own effect restores mana. The module
    removes that block with its first point, so regenerated mana is usable.
  - "Drawn" = the game's combat state (weapon in hand, fists up, spell ready), not
    "enemies nearby".

Other regeneration mods
  One at a time. While "G1R_RegenMana" is enabled this module is not loaded (UE4SS.log:
  "regen left to the separate mod G1R_RegenMana"). To switch, disable it and copy its
  values (see example). Not available here: its bar marker (use ShowMessage) and its
  item requirement.

How it works
  Mana and health are attributes of the hero's player state, read twice a second. A due
  step goes through the attribute set's TrySetAttributeBaseValue: the game rounds,
  limits and updates the bars. If unavailable, the values are written directly (bars may
  lag). Every change is read back; after three failed writes the module stops for that
  value until restart, a Method change, or toggling ManaEnabled/HealthEnabled. A Method
  change also retries the game's way after a fallback. Not re-armed without restart:
  unreadable tags and an unremovable casting block (each dropped after 3 failures). No
  hooks, no replaced functions, no save writes.

In the game
  Ran with megamod 0.2.1 (140 min, 2026-10-04; mana +2 % / 3 s to 75 %, health +1 and
  +1 % / 5 s to 50 %). Seen:
    - mana +60 in 60 steps, health +74 in 15 steps, all via the game's ability system;
    - hero tags readable;
    - casting block at zero mana found and removed 7 times;
    - menus pause the engine; counting stopped;
    - the game clock stood still ~5 of 140 min while the engine ran; regeneration
      waited. If values stop while you play, run "regen": if the clock stands, set
      StopWhenClockStands = false.
  Not seen: mana by circle, slower regeneration with weapon drawn, dead/unconscious hero
  at a step, the direct-write fallback.
  Diagnostics: Scripts\diagnostics\ (notes regen.*) and "regen".

Not included
  Sleep restoration: the game rounds attribute values to integers when set its way (the
  bed's 12.5 %/hour would become 0 or 100 %), and the bed ignores direct writes after
  sleeping. The bed stays as the game made it.
