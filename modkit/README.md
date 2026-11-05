# G1R_MegaMod for the official ModKit (0.4.0, not compiled yet)

This is an unofficial modification. It is not made, endorsed or supported by THQ Nordic.

Written entirely by AI; it may have bugs. Report problems as GitHub issues.

Since the game's 1.1 hotfix (2026-11-05) the game exits when UE4SS is loaded, so the UE4SS mod in `G1R_MegaMod/`
cannot run any more. This folder is the port to the game's own mod system (the ModKit of Feature Update 1): an
AngelScript mod package that the game compiles at start, with its settings in the game's own Options.

**State: written in the cloud, never compiled.** There is no AngelScript compiler outside the game. What was checked:
every type and member name against the ModKit's scripts and its native reference (`tools/check_as.py`: 0 unknown
names). Syntax, types and behaviour are known only after the first start with `-as-development-mode` (compile errors
are then listed). Every claim below about the game is SOURCE (the ModKit's scripts / reference) or UNKNOWN; nothing
is IN-GAME yet.

## Package

`G1R_MegaMod/` goes to `<game>/G1R/Mods/G1R_MegaMod/` (`deploy/install_modkit.py`, game closed).

| Folder | What |
|---|---|
| `GothicMod.json` | the package's description (name G1R_MegaMod, version 0.4.0) |
| `Script/G1R_MegaMod/Core` | shared helpers (`Mega::`), the notes queue, the game's original numbers (`UMegaMemory`) |
| `Script/G1R_MegaMod/Settings` | one settings class per module, generated from the module's `schema.lua` (`tools/gen_settings.lua`) |
| `Script/G1R_MegaMod/<Module>` | the modules |

## Modules

| Module | File | How it reaches the game | Not ported |
|---|---|---|---|
| xp | `Xp/MegaXp.as` | each experience gain is looked at 4x a second; the extra part goes through the game's `GiveExperience` | - |
| mining | `Mining/MegaMining.as` | the mining config's class default (ore per swing) from Strength, Dexterity, skill | extra-ore chance, endless veins, longer veins |
| magic | `Magic/MegaMagic.as`, `MegaMagicRules.as` | spell configs and definitions (class defaults, from the game's own numbers); damage: inheritance injection over `UGE_Ex_Damage` | - |
| locks | `Locks/MegaLocks.as`, `MegaLockData.as` | the hero's `AttributeSet_Lockpicking` (precision, durability) by skill level; "half" / "safe" read the lock of the running chest / door ability | the "put back now" button |
| movement | `Movement/MegaMovement.as` | `SpeedModifier` of hero and scavenger; the swim speed table's class default | - |
| intro | `Intro/MegaIntro.as` | inheritance injection over `ULoadingScreen_Intro`: the film's loading screen says it does not fit | the logos (they play before any script: the settings app's Game.ini line) |
| melee | `Melee/MegaMelee.as` | `m_FakeSloppyCombos` of the game's settings; freeze and shake tables of `UGenericMeleeFeedback` | storing the flow helper in the profile |
| regen | `Regen/MegaRegen.as` | Mana / Health with the game's `TrySetAttributeBaseValue`; `State.OutMana` taken off after a step from zero | method choice (one way only) |
| wait | `Wait/MegaWait.as` | `UGameTimeSubsystem.SkipTime` / `AdvanceToClockTime` on a key | menu buttons (keys only) |
| mount | `Mount/MegaMount.as` | whistle watch, auto fix (riding block, fear, idle routine); the name: a text override written by the installer | the "report now" button |
| repopulate: crime | `Repopulate/MegaCrime.as` | inheritance injection over `UCrimeProcessingSubsystem.GetCrimeDefinition` (stand-in rules, as crime.lua) | forgetting old crimes; owners who hear a chest / door |
| repopulate: herbs, items | `Repopulate/MegaRegrowth.as` (generated, not in the repository) + `MegaRegrowthHours.as` | the spawners given again with the settings' refill hours (`UGothicModExt_WorldPoints`) | - |
| repopulate: creatures, chests | - | - | not ported: needs facts only the game can give (how a respawned creature's id looks, mod state in saves, a container's inventory at run time) |
| general, timers, keys | `UI/MegaHud.as` | widget extension of the crosshair widget: notes box, effect timers (active effects with a duration), key list | letters choice, test note, pause-menu key line, other mods' keys, text size |
| markers (map pins) | - | - | not ported: its pictures are loose PNG files; the ModKit takes pictures only as cooked content (an Unreal project) |
| othermods | - | - | not needed (it kept UE4SS mods apart) |

## Settings

In the game: Options, one page per module ("MegaMod: Experience", "MegaMod: Time", ...): 234 settings. Choices are
numbers (the text of the setting lists them: "1 as the game has it, 2 none, ..."). Keys are numbers:

| Number | Key |
|---|---|
| 0 | none |
| 1-26 | A-Z (Y = 25) |
| 27-36 | 0-9 |
| 37-48 | F1-F12 (F3 = 39) |
| 49-58 | number pad 0-9 |

Settings are stored by the game (GameUserSettings.ini). The UE4SS mod's `config.lua` files are not read: values have
to be set once in Options.

## Tools (`tools/`)

| Tool | What |
|---|---|
| `gen_settings.lua <module> [--check]` | settings class from the module's schema (Lua 5.4) |
| `gen_lockdata.py [--check]` | `Locks/MegaLockData.as` from the locks module's `lockdata.lua` |
| `gen_regrowth.py <G1R-Modkit/Script>` | `Repopulate/MegaRegrowth.as` from the ModKit's item spawner config (holds the game's item lists: made where the package is built, not committed) |
| `check_as.py <G1R-Modkit/Script> <reference site>` | every type and member name known to the ModKit or declared here |

## License notes (ModKit LICENSE.txt)

- The notice above is required in every mod (3.4).
- 3.8: no decompiling or disassembling of the game except through the ModKit's tools. Parts of this project's facts
  (DISASM, the research tools of the UE4SS era) came from such work; new work uses the ModKit's scripts and reference.
- 3.9: game content may not be used to train AI.
