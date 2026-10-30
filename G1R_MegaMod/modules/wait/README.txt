Module "wait" (skip game time 1.0) - Gothic 1 Remake, UE4SS Lua
===============================================================
AI-generated. Bugs: see G1R_MegaMod\README.txt.

Function
  Skip game time without a bed. Four waits, each with its own key and amount:

    short wait           minutes (shipped: 30)
    long wait            minutes (240 = four hours)
    wait until morning   to an hour of day (8 = 08:00)
    wait until evening   to an hour of day (20 = 20:00)

  "Until" = the next time the clock shows that hour: today if still ahead, else
  tomorrow, judged at the key press. A press just before the hour (the clock reaches it
  before the skip, ~0.5 s later) skips nothing. Only a press in the last 1/20 s before the
  hour, or during a hitch, can count as after it: then it waits until tomorrow.

  Note after a skip:  30 minutes later - 14:30

  Ships WITHOUT keys; set them in the settings. Without keys:
    - in-game mod menu (SharedModMenu), page "G1R Time": a button per wait ("Wait the
      short time now", ...);
    - console:  wait 30        skip 30 minutes (1 to 1440)
                wait until 8   skip to the next 08:00 (hour 0 to 23)
      (needs UE4SS's or the game's console enabled).

Settings (Scripts\config.lua; app page "Time"; in-game menu "G1R Time", no keys there;
live within ~5 s)
    Enabled              false = off
    Cooldown             seconds between skips (0 to 60, shipped 2)
    ShortKey             short wait key, "" = none
    ShortMinutes         1 to 1440
    LongKey, LongMinutes same for the long wait
    MorningKey           "wait until morning" key
    MorningHour          target hour, 0 to 23
    EveningKey, EveningHour   same for "wait until evening"
    NotInFight           no skip with a weapon drawn
    NotInConversation    no skip while talking
    NotInCutscene        no skip in a cutscene
    NotWhenClockStopped  no skip while the game lets no time pass
    ShowMessage          note after a skip
    ShowRefused          also a note when a skip was refused, with the reason
    LogSkips             UE4SS.log line per skip

  Key format: "Y", "F6", "CTRL+Y", "SHIFT+NUM_FIVE" (CTRL, SHIFT, ALT plus one key). A key
  bound without CTRL does not fire while CTRL is held.
  Never during map loads. Pause is checked once, when the press is taken up: paused =
  no skip. A pause starting in the 0.25 s before the skip, or one the engine cannot
  report, shows only as a stopped clock - that is NotWhenClockStopped.
  The four "Not..." switches ship on; turn one off if it blocks you.
  Note look: page "General".

  Console:  wait           status, last skip, why the last one was refused
            wait reload    re-read config.lua

Behaviour
  - The skip comes ~0.5 s after the key (clock check first).
  - Only the clock moves, as when sleeping. NPCs switch to their schedule for the new
    hour (nearby ones walk there); game-time timers advance, including repopulation.
  - Not sleep: no rest, no healing. Hunger, thirst and tiredness count the skipped hours
    in full.
  - Nothing happens? UE4SS.log says why ("[G1R_Wait] no time skipped: ..."), or turn on
    ShowRefused.

Other wait mods
  One at a time. While "G1R_WaitOnT" is enabled this module is not loaded (UE4SS.log:
  "wait left to the separate mod G1R_WaitOnT"). To switch, disable it.

How it works
  The clock is one value in the time subsystem; the game's SkipTime adds to it and
  everything clock-based catches up next step. The module calls SkipTime and reads the
  clock back. If unchanged, a second way of passing the amount is tried, then a direct
  write of the clock (all SkipTime does). The working method is remembered until exit.
  One press never skips twice. No replaced functions, no save writes.

In the game
  Ran with megamod 0.2.1 (2026-10-04): two key skips - Y for 30 minutes, another key to
  08:00 ("6 hours 48 minutes, day 12 01:12 -> day 12 08:00"). Key received, clock moved
  by the requested amount right after the call, hero states readable before the skip.
  NOT seen yet:
    - NPC behaviour right after a skip; hunger, thirst, tiredness after one (code says
      they count the hours);
    - a refusal for drawn weapon, conversation or cutscene (if unreadable, logged once
      and those switches do nothing);
    - menu buttons and console words.
  Diagnostics: Scripts\diagnostics\.
