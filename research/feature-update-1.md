# The game's Feature Update 1 (2026-10-29) and the official ModKit

Checked in the cloud on 2026-10-30 for megamod 0.3.6. What is written here comes from the ModKit (SOURCE); nothing of
it has been seen in a session on the new version yet.

## What came with the update

- Feature Update 1 of Gothic 1 Remake: Marvin mode (the cheat mode: Esc, type MARVIN; menu commands for time, locks,
  spawning, teleporting), photo mode (pause menu or L), new hairstyles and tattoos, waiting on benches, quest and bug
  fixes (press reports of the update; the patch notes themselves were not reachable from the cloud).
- The official ModKit: <https://github.com/AlkimiaInteractive/G1R-Modkit> (documentation, **the game's AngelScript
  sources as shipped**: 7280 files, commit of 2026-10-29) and its rendered site
  <https://alkimiainteractive.github.io/G1R-Modkit/> (branch `gh-pages`: guides, example mods, and a Doxygen
  reference of the native classes the scripts can reach - 6398 classes with their public members).
- Official mods: a mod package is a folder under `G1R/Mods/<name>/` (or a Steam Workshop item) with `GothicMod.json`
  (name, title, author, version, dependencies such as `{"name": "G1R", "requiredVersion": "1.0.5a"}`, load order),
  `Script/` (new .as files, compiled by the game at start), `ScriptPatches/` (unified diffs against the base scripts),
  `Config/` (.ini), `Content/` (cooked .pak). "Inheritance injection" (`UCLASS(meta=(ReplaceParentClass))`) replaces a
  base script class by a subclass (stackable across mods). The game has a Mod Management UI (`-ModManagementUI`),
  can upload to the Steam Workshop, and injects mod settings into its own "Game" options (example mod "Settings").
- Launch flags of note: `-no-intro-cinematic` (skips the intro film of a new game: what the module intro's
  SkipNewGameFilm does), `-Mods=`, `-ModsDirectory=`, `-as-development-mode`, `-console`, `-ingametools`.
- The official mods live in `G1R/Mods/`; UE4SS mods stay in `G1R/Binaries/Win64/ue4ss/Mods/`: no overlap of folders.

## What the cloud compared, and the result

`dev/tools/modkit_check.py <ModKit>/Script [--site <gh-pages>]` repeats every comparison below; the lock tables come
from `dev/tests/locks/tools/make_tables.py <ModKit>/Script <solver>`.

| Part | Compared | Result |
|---|---|---|
| repopulate containers (`data/chests.lua`, 528) | contents kept per container | three changed: `IO_CR_CHEST_01-03` (the crypt's chests got their items shuffled) - updated |
| repopulate creature points (`data/creature_points.lua`) | place, handler, what each point spawns | all 401 unchanged; one new point `NEF_SNAPPER_SPAWN_01_CH2` (a chapter 2 snapper beside the world-start one) - added (402) |
| repopulate item spots (`data/item_points.lua`) | refill, event, ordinary items | `Spawner_TST_Third_Subzone_Weapons_21` now fills on `OnSleeperTempleTaken` (event-spawned: left out); 12 spots with ordinary items whose siblings were in the table but not they (new in the update, as far as the cloud can tell): added as never refilled by the game (2506) |
| locks (`lockdata.lua`, 346 locks) | pieces and connections of every lock, which locks chests and doors name | all unchanged; the lock of the Cutter chest is spelt `OC_Chest_CUTTER_Lock` now (its chest still says `OC_Chest_Cutter_Lock`; the module looks names up without regard to capitals). Random locks still off |
| magic (all classes the module touches) | damage, steps by circle, mana, casting times, speeds, reach, stance force, heal map, circle prices | numbers unchanged; **the price property is `m_SPCost` now** (was `SPCost`; the native class got an overridable `GetSPCost`): fixed in magic 1.0.2; the heal map is spelt `m_HealAmountByMagicCircle` (no matter: names are found without regard to capitals) |
| timers | every effect class (1020) through the module's rules | nothing new shown under a wrong name; the Light's timer code unchanged |
| movement | swimming speeds, the speed factor of hero and creatures | unchanged (100 / 150 / 220; 1.0) |
| mining | swing, low-vein rule, vein sizes, skill costs | unchanged (3, 1 at 5 or fewer, 15 / 10 / 5, 30 / 50 ore) |
| map pins (`npcs.lua`, 181) | every id a unique name of the game | all there; Gorn is spelt `NC_SLD_Gorn_699` now (the list says `NC_SLD_GORN_699`; the lookup ignores capitals); no new named teacher or trader |
| intro | `LoadingScreen_Intro`, `LoadingScreenHelperSubsystem` Get/SetCurrentLoadingScreenType | there |
| the native members our facts name | the reference's member lists | the functions the modules call are there; private properties are not in the reference, so these stay open: `GothicPlayerControllerBase.m_Widget` (keys: now also `GetPlayerWidget()`), `PersistentDataSubsystem.m_CurrentProfileId` (repopulate, melee: now also `GetCurrentProfileId()`), `G1RGameState.m_WorldDefinition` (mining: `GetWorldDefinition` first, as before), `DataModuleLibrary.GetContainerDataModule` (a fallback only) |

## What only the player's PC can tell

1. Whether the UE4SS fork "AngelScript Fix 0.4" still runs on the new executable (it finds the engine by searching
   the program's code; a new build can move what it searches for). If the game crashes at start or UE4SS.log shows
   errors before the mods load, nothing of the megamod runs. Replacing the fork is the player's decision (CLAUDE.md).
2. The private properties above, the widget blueprints the map pins and the scavenger's name read (`W_MapBoundingBox`,
   the map's buttons, `Text_CharacterName`) and the packed config: a session's notes and log tell, or a new usmap.
3. The app's `StartupLoadingScreen.txt` is the packed `StartupLoadingScreen` value of the game's DefaultGame.ini:
   remake it from the new paks (`app/tools/make_startup_screen.py`) and compare. If it changed and the logos are
   skipped (Game.ini holds the app's lines), Game.ini still carries the old value until the app saves the new one.
4. The other authors' mods (HUDMap, SharedModMenu, FocusNearbyPickups in PLuaModLoader, G1R_AutoPickUpItemNative,
   G1R_PutAwayTorchRedux): whether they still run; the native (C++) ones are the most likely to break.
5. A diff of the old decompiled scripts (`<proj>\as-src`, Build83) against the ModKit's `Script` folder shows every
   change of the update at once; it settles whether the 12 item spots and the snapper point are new.

## Overlaps with the new game features

- Waiting: the game now lets the hero wait on benches; Marvin mode can change the time. The module wait stays as it is
  (keys, buttons, console).
- Marvin mode opens locks and spawns items; nothing of it touches what the modules change.
- Photo mode is on L: no module or listed mod uses L.

## The official way, for later (a decision of the player)

Most modules could be official mod packages instead of UE4SS Lua: experience, magic numbers, lock picking, mining,
regeneration, waiting and the movement speeds are script classes and their defaults (inheritance injection or a
script patch); the effect timers and the key list are UMG widgets AngelScript can build; settings could go into the
game's own options (example "Settings"). Such mods need no UE4SS, load through the game's own mod system and the
Steam Workshop, and a game update only breaks a script patch that no longer applies. The work is large (a new
language and toolchain; every module rewritten and tested anew; the settings app would write the mods' .ini files);
nothing of it is started.
