Module "mining" (mining rework 1.0) - Gothic 1 Remake, UE4SS Lua
================================================================
AI-generated. Bugs: see G1R_MegaMod\README.txt.

Function
  Sets ore per pickaxe swing and vein life:
    * ore per swing = base + 1 per N Strength + 1 per N Dexterity + trained/master bonus,
      clamped to min/max, with a chance of +1;
    * endless veins, or veins lasting several times as long.
  Ships neutral: mining as in the game; game not read.

Game values
  A swing gives 3 ore; 1 when 5 or fewer are left. Veins hold 5, 10 or 15 and stay empty.
  The mining skill (untrained, trained, master) does not affect yield. Only ore can be
  mined.

Settings (Scripts\config.lua; app page "Resources"; in-game menu "G1R Resources"; live,
from the next swing)
    Enabled          false = off

  Ore per swing
    YieldEnabled     true = values below decide the yield
    BaseAmount       base per swing (3 = game)
    StrengthPerOre   +1 ore per this many Strength (0 = ignored; 2.5 allowed)
    DexterityPerOre  same for Dexterity
    TrainedBonus     bonus for a trained miner
    MasterBonus      bonus for a master (instead of TrainedBonus)
    ExtraChance      % chance of +1 ore
    MinAmount        minimum per swing
    MaxAmount        maximum per swing
    LowVeinRule      true = 1 per swing at 5 or fewer left (game); false = full amount

    Example: BaseAmount 0, StrengthPerOre 4, DexterityPerOre 6 = Strength/4 +
    Dexterity/6 (each rounded down): 3 ore at 10/10, 13 at Strength 40 / Dexterity 22.

  Vein life
    EndlessVeins     true = the vein is refilled: never runs out, every swing gives the
                     full amount (even above capacity), emptied veins return when swung at
    VeinLastsTimes   vein yields this many times its ore (1 = game). Part of each swing
                     is put back: with 3, two of every three. Ignored with EndlessVeins.

  On screen and log
    ShowMessage      note when a swing differs from the game:  Mining: 7 ore (the game gives 3)
    LogSwings        UE4SS.log line per swing

  Hidden (add to config.lua by hand):
    VeinMethod       how ore is put into a vein: "auto" (game function, else first slot
                     count), "function" or "slot". Only "function" can revive an empty
                     vein; "slot" prevents running out but cannot refill an empty one.
    RefreshSeconds   Strength/Dexterity read interval when idle (5)
    CheckMilliseconds  swing check interval (250); read at game start

  Console (UE4SS console):  mining          status
                            mining reload   re-read config.lua

Behaviour
  - Without endless veins a swing never exceeds what the vein holds (20 per swing from a
    15-vein gives 15, then nothing).
  - Ore arrives the game's way, with the game's display.
  - Only vein swings give ore; looting, trading, rewards unchanged.
  - Settings never change ore already owned. Off restores game values at once.
  - VeinLastsTimes loses the last fraction (15 x 3 gives slightly under 45).
  - The game redraws a vein only when a swing ends. With endless veins a mined-down vein
    looks whole after the first full swing (kept one below full for that swing, as the
    game does not redraw a full vein). Ore put back by VeinLastsTimes shows from the end
    of the next swing.
  - Endless veins are filled early for the next swing, so a vein you leave (or turn the
    module off at) may hold one swing more than the game gave it. It stays there.

Other mining mods
  One at a time. While "BetterMining" is enabled this module is not loaded (UE4SS.log:
  "mining left to the separate mod BetterMining"). To switch, disable it. Its settings:
      StrPerOre = 4           ->  StrengthPerOre = 4
      AgiPerOre = 6           ->  DexterityPerOre = 6
      (its formula)           ->  YieldEnabled = true, BaseAmount = 0,
                                  MinAmount = 0, LowVeinRule = false
      PreventExhaustion=true  ->  EndlessVeins = true

How it works
  The game keeps three mining values in one object: yield from a full vein, yield from a
  nearly empty one, and the "nearly empty" threshold. Its code reads them at the end of
  every swing. The module writes the first two (read back), keeps the game's values and
  restores them when the feature is off. No hooks.
  Swings are detected by checking the mining ability 4 times a second (active, which
  vein); during a swing the vein's ore is counted - a drop means ore was handed out.
  Endless: the vein is filled during the swing up to "original amount + this swing".
  Longer veins: part of the ore is put back after the swing. No save writes; the game
  saves veins normally.

In the game
  Ran with megamod 0.2.1 (2026-10-04). Seen: game values read (3 per swing, 1 at 5 or
  fewer); module values written and still set at every later check; Strength, Dexterity
  and mining skill readable; the mining ability found in the hero's ability list. No vein
  was mined in a logged session. Not seen:
    - that a swing gives the written amount (the module compares and logs differences);
    - that ore can be put into a vein (two ways tried) and that the game saves it;
    - a mined-down vein looking whole after one swing with endless veins;
    - whether the game allows swinging at an empty vein (if not, empty veins cannot be
      revived by swinging);
    - whether the mining skill can be learned at all.
  Failures are logged once and that part is left alone. Diagnostics:
  Scripts\diagnostics\.
