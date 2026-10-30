# Research material (Gothic 1 Remake, build Build83_CL174209, UE 5.4.3)

> AI-generated.

Not part of the mod: what is known about the game and the other mods on the player's PC. Never start the game from here
or on the PC. Every game claim needs a source; the source sets its status in the facts file (`dev/FACTS.md`):

| Status | Meaning | Source |
|---|---|---|
| IN-GAME | seen working in a real session | a line in one of the UE4SS logs below |
| DISASM | read from the game executable / UE4SS.dll | `research/re-tools/*.py` |
| SOURCE | game scripts, property layout, UE4SS source | `as-src`, `usmap.py`, `binds_strings.txt`, RE-UE4SS |
| OFFLINE | only exercised by our tests against a model | - |
| UNKNOWN | not known | - |

## The game

- **Scripts (AngelScript, 7317 files):** `<as-src>/` (`grep -rn`). Abilities, effects, formulas, UI. Script classes
  are in `/Script/Angelscript`.
- **Property layout:** `python3 research/usmap.py <Class>` (`--find`, `--prop`, `--enum`, `--sub`). From build
  169686, slightly older than the installed game.
- **Native functions callable from scripts:** `grep -n "Name" research/re-tools/binds_strings.txt` (e.g.
  `void SkipTime(const FInGameTime& Duration)`; owner type = nearest `/Script/...` line above; check context).
- **Native UFunctions with parameters:** `cd research/re-tools && python3 params.py SkipTime`
  -> `('0x14993b690', 1, 8, '0x4420401', ['Duration:Struct@0[ref,const]'])` (address, parameter count, size, flags,
  parameters as name:kind@offset[ret|out|ref|const]). Listed = callable from Lua via UE4SS and hookable with
  `RegisterHook`. ~2 s per call. Flags: 0x400 native, 0x04000000 BlueprintCallable, 0x2000 static.
- **Pak:** `G1R-Windows.pak` (version 11, index unencrypted, mostly Oodle) holds the packed config
  (`G1R/Config/DefaultGame.ini`, `DefaultInput.ini`, ...); assets are in the IoStore files beside it.
  `python re-tools/pakread.py <pak> --list <text>` lists; `--oodle <oo2core_9_win64.dll> --out <dir> <path>` extracts
  (Windows Python; the game links Oodle statically, so the DLL comes from another game). Read 2026-10-06: logo start
  list (`dev/facts/intro.md`, IN1).
- **Executable:** `research/re-tools/game.exe` with `pe.py`, `scan.py` (`find_all`), `xref.py` (`callers`),
  `redis_.py` (`dis`), `props.py` (`prop_info`). Last resort.
- **Other data:** `<proj>/re/InteractionSpots.json`, textures in `<work>/tex`, respawn research in
  `<proj>/respawn-research/`.

## UE4SS

- Installed: v3.0.1 Beta, fork "AngelScript Fix 0.4", git c838a8ac. Settings: `<mods-snapshot>/UE4SS-settings.ini`.
- Upstream source (newer than the fork; same Lua API for what we use): `<RE-UE4SS source>/` -
  `UE4SS/src/Mod/LuaMod.cpp` (globals), `UE4SS/src/LuaType/` (object, array, struct wrappers), `docs/lua-api/`.
- Known behaviour of this build: `dev/FACTS.md` section 2 (U1 - U13). Read it.

## Other mods on the PC (facts may be used; code may not)

Snapshot 2026-10-01: `<mods-snapshot>/<Name>/` - BetterMining, BystanderXP, EXPModifier, G1R_MageBalance,
G1R_WaitOnT, HUDMap, SharedModMenu, SkillfulLocks, PLuaModLoader, G1R_PutAwayTorchRedux, G1R_AutoPickUpItemNative;
`mods.txt` is the PC's list. Native mods (G1R_RegenMana, G1R_RenderBridge, G1R_ShowItemValueNative) are not in the
snapshot; G1R_RegenMana is known only from its log lines (below).

What another mod does and which game functions it calls is a game fact (cite it). Its code, texts and data are its
author's: no copying, no line-by-line translation. Our modules are new, do more or different things, and every
feature is a setting.

## Real session logs (the only IN-GAME evidence)

- `research/session1/UE4SS-20261003-205934.log` and `session1/diagnostics/`: first megamod session, 2026-10-03
  20:44, 0.2.1. All ten modules loaded, 0 errors.
- Later sessions, copied read-only (hashes checked) into the project's `megamod\` (`<proj>` in CLAUDE.md):
  `first-session-20261003-2044\` (0.2.1, same as session1), `live-session-20261005-1542\` (0.2.1 + hotfix, 130 min,
  0 errors: how often 0.2.1 searched all objects - why 0.2.2 asks the engine), `first-session-0.2.2-20261005-1824\`
  (0.2.2, 82 min, engine paths seen), `first-session-0.2.3-20261005-2107\` and `session-0.2.3-20261005-2214\` (0.2.3,
  58 and 84 min, mount whistles), `first-session-0.3.0-20261006-0848\` (0.3.0, interim `at-*` copies: the player's
  0.3.1 requests), `session-0.3.1-20261006-0946\` (0.3.1, 24 min, 0 errors: scavenger factor kept in the save),
  `session-0.3.2-20261006-1033\` (0.3.2, 131 min, no mod errors: drawn pictures loaded, scavenger x1.30 set once,
  Light by engine timer). Each has `end\` with UE4SS.log, session log, report, .ops file and a progress file copy;
  HANDOFF.md says what was read from each.
- `<proj>/re/crash-20261001-1942/UE4SS.log` (10 min, crash caused by another mod: U2 in FACTS)
- `<proj>/re/UE4SS-log-copy.txt`, `UE4SS-log-copy2.txt`
- `<proj>/original/UE4SS-before-uninstall.log`

`grep -n "\[SkillfulLocks\]\|\[EXPModifier\]\|\[BetterMining\]\|G1R_WaitOnT\|G1R_RegenMana"` shows each mod's log
lines. A mod that only logged its load line proves its hooks registered, not that they do anything.

## The megamod

- Source: `G1R_MegaMod/`. Read `dev/AI_GUIDE.md`, `dev/FACTS.md`, `dev/MODULES.md`, `dev/SETTINGS.md`. Worked
  example: `modules/xp` with `dev/tests/xp/harness.lua`.
- Tests: `lua5.4 dev/tests/<suite>/harness.lua`; all: `python3 dev/run_tests.py`.
- Pre-0.3.0 findings (objects, functions, files per new feature; what stays UNKNOWN until a session):
  `q3/feasibility-0.3.0.md` (skip intro, key list, Gothic font, other mods' distances), `q3/spell-timers.md` (effect
  timers). Results: `dev/facts/intro.md`, `keys.md`, `timers.md`, `othermods.md`, `movement.md`, K18 / K19 / M16 (kit,
  markers).
- Official game scripts since Feature Update 1 (2026-10-29): ModKit
  (<https://github.com/AlkimiaInteractive/G1R-Modkit>, `Script/`; branch `gh-pages` = native class reference). SOURCE
  from that version on (the PC's decompiled `as-src` is Build83; older fact line numbers refer to it). Update impact
  and check: `feature-update-1.md`; re-check after later updates: `G1R_MegaMod/dev/tools/modkit_check.py`.

## Player's settings of the replaced mods

The installer migrates these into our modules' `config.lua`; each module must be able to express them (its handoff
maps the keys):

- EXPModifier: `<mods-snapshot>/EXPModifier/EXPModifier.ini` (ExpMultiplier=4.0, ShowBonusMessage=true)
- BetterMining: `<mods-snapshot>/BetterMining/BetterMining.ini` (Enabled=true, StrPerOre=4, AgiPerOre=6, PreventExhaustion=true)
- G1R_WaitOnT: no settings file; key Y and half an hour are in its `Scripts/main.lua`
- SkillfulLocks: `<mods-snapshot>/SkillfulLocks/Scripts/config.lua`
- G1R_MageBalance: `<mods-snapshot>/G1R_MageBalance/Scripts/config.lua`
- G1R_RegenMana (native C++): `research/thirdparty/G1R_RegenMana.ini` (from the PC, 2026-10-02) and its log lines in
  `G1R_RegenMana.log-lines.txt` beside it. No code available.
