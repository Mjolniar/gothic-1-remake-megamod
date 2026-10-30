Module "magic" (magic balancing 1.0) - Gothic 1 Remake, UE4SS Lua
=================================================================
AI-generated. Bugs: see G1R_MegaMod\README.txt.

Function
  Changes spell values: damage, mana cost, cast/charge time, projectile speed, range,
  stagger, heal amount, magic circle prices, ice spells that freeze on every hit.
  Ships with every multiplier 1.0 and every switch off: the spell data is not read.

Settings (Scripts\config.lua; app page "Combat", groups "Magic: ..."; in-game menu
"G1R Combat"; menu at once, file ~5 s; applies from the next cast)
  Value = game value (or your own, where offered)
          x all-spells multiplier x kind multiplier (fire, ice, energy, wind)
          x single-spell multiplier.
  Damage and mana are integers in the game data; multipliers have 3 decimals. A product
  within 0.025 of an integer becomes it (90 x 2.778 = 250.02 -> 250).

  Magic: all spells
    Enabled           false = off; game values in place
    Damage            all damage spells (0.1 to 10)
    ManaCost          cast cost and per-second cost of held spells (0 to 10; 0 = free)
    WholeMana         true = round changed costs to whole points, never 0 unless a
                      multiplier is 0; false = exact product (2 x 1.25 = 2.5)
    CastTime          cast time and charge time per level (0.1 to 10; 0.5 = twice as fast)
    ProjectileSpeed   fire bolt, ice bolt, fire ball, ball lightning, storm of fire
                      (0.25 to 5)
    Range             targeting range (sleep, charm, shrink, heal, pyrokinesis, chain
                      lightning, telekinesis, control) and spread of storm fist, death to
                      the undead, Uriziel's wave of death (0.25 to 4). Others unchanged.
    Stagger           stance damage of spell hits (0 to 20)
    HealAmount        health per heal step (0.1 to 10)
    SchoolFire        fire bolt, fire ball, pyrokinesis, storm of fire, rain of fire
    SchoolIce         ice bolt, ice block, ice wave
    SchoolEnergy      ball lightning, chain lightning, Uriziel's wave of death, death to
                      the undead
    SchoolWind        fist of wind, storm fist, breath of death

  Magic: fire / ice / energy / wind spells - per damage spell (FireBolt, FireBall,
  Pyrokinesis, StormOfFire, FireRain, IceBolt, IceBlock, IceWave, BallLightning,
  ChainLightning, Uriziel, DeathToTheUndead, WindFist, StormFist, BreathOfDeath):
    <Spell>Damage     damage (0.1 to 10)
    <Spell>Mana       mana cost (0 to 10)
    <Spell>CastTime   cast/charge time (0.1 to 10; fist of wind has none)
  and
    IceBoltFreeze, IceBlockFreeze, IceWaveFreeze
                      true = every hit freezes, even ice-resistant foes. false = game:
                      freezes when damage fills the foe's ice counter (50)
    BallLightningSpeed  ball speed at every charge level, units/s; 0 = game (300 to 450)
    WindFistStagger   fist of wind stagger (0 to 20; game 200, storm fist 250)

  Magic: fire bolt and ice bolt by caster circle
    FireBoltSteps     true = the four values below are fire bolt damage (multipliers
                      still apply)
    FireBoltStep0     below circle 2     (game: 35)
    FireBoltStep2     from circle 2      (40)
    FireBoltStep4     from circle 4      (50)
    FireBoltStep6     circle 6           (65)
    IceBoltSteps, IceBoltStep0 / 2 / 4 / 6   (game: 20 / 30 / 40 / 50)

  Magic: learning the circles
    CircleCosts       true = the prices below apply
    CircleCostBasics  basics before circle 1 (game: 5)
    CircleCost1 ... CircleCost6   learning points per circle (game: 10, 15, 20, 25, 30, 40)

  Magic: on screen, log
    ShowMessage       note when a changed setting reaches the game
    LogChanges        UE4SS.log line per changed or restored value
    In-game menu button "Write what is changed right now into UE4SS.log": module state
    and all changed values.

  Hidden (add to config.lua by hand):
    Config.SearchesPerLook = 4      game data objects searched per look (1 - 32). Each
                                    search costs a few ms, once per run; set 1 or 2 if
                                    the game stutters after start or a setting change
    Config.CheckSeconds = 60        re-check interval of changed values (0 - 3600;
                                    0 = only after a map change)
    Config.LookMilliseconds = 250   work check interval (50 - 5000; read at game start)

  Console (UE4SS console):  magic          on/off, changed count, objects not found
                            magic values   same plus every changed value
                            magic reload   re-read config.lua
                            (g1r_magic = magic)

Behaviour
  - Values apply to everyone using the same spells. Human mages use the same runes:
    damage x2 doubles their fire balls too; larger range keeps them further away.
  - Creatures, orc shamans, golems, demons and final-fight companions have their own
    spells; unchanged.
  - A spell in flight keeps its starting values.
  - Rune/scroll tooltips probably show changed damage and mana; not checked.
  - Nothing saved. Back at 1.0 or module off = game value restored at once.

From G1R_MageBalance
  One balance mod at a time. While "G1R_MageBalance" is enabled this module is not
  loaded (UE4SS.log: "magic left to the separate mod G1R_MageBalance"). To switch,
  disable it. Its absolute values become multipliers here (30 for a game 20 = x1.5); bolt
  damage and circle prices can be absolute. Its fractional mana (1.25, 2.5) needs
  WholeMana = false.

How it works
  Spell values are the default objects of each spell's definition class (damage, also
  by circle; flight speed; stance force), its config class (mana, cast time, range), the
  ice hit effect, and the circle skill effects. The game reads them per cast, hit or
  circle learned. The module writes them:
  - an object is searched only when a related setting is not neutral; max 4 per look;
    each once per run;
  - the first value read is kept as the game's; new values are computed from it;
  - a value is written only if it holds the game's or the module's last value; values
    set by others (another mod) are left and listed in the status;
  - every write is read back; failures logged once;
  - 2 s after a map change and every minute, values are re-checked and re-set;
  - game and module values are also kept in a UE4SS shared variable, so a Lua reload
    does not multiply twice.
  No hooks, no replaced functions.

In the game
  Ran with megamod 0.2.1 (140 min, 2026-10-04: 24 single-spell settings, one always-
  freeze ice spell, custom circle prices). Seen: all 33 objects found; game values read
  (diagnostics: magic.original.<name>); every write type read back - 73 values; all still
  set after each of 8 map loads.
  Not shown by any note (read from scripts and executable only): that the game uses the
  changed values in effect (damage, mana, cast time, price, freeze). Check in a fight.
  How the game handles fractional mana is unknown - hence WholeMana.
  Diagnostics: magic.original.<name>, magic.write.*, magic.after_load in
  Scripts\diagnostics\.
