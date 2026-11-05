# Gothic 1 Remake MegaMod

> [!CAUTION]
> **Does not run on the current game.** Since the game's 1.1 hotfix (November 2026) Gothic 1 Remake refuses injected
> code at start ("Potentially malicious code injection found ... please use the provided API") and names UE4SS.dll:
> every UE4SS mod, this one included, stops the game. The game's official mod system (the
> [ModKit](https://github.com/AlkimiaInteractive/G1R-Modkit)) is the way forward: the port is in
> [`modkit/`](modkit/README.md) (0.4.0, written, not compiled or tested in the game yet).

> [!WARNING]
> **AI-generated.** Mod, settings app and tools written by AI. Tested offline and in a few play sessions. Expect bugs.
> Report them as [issues](https://github.com/Mjolniar/gothic-1-remake-megamod/issues) with `UE4SS.log` and
> `G1R_MegaMod/Scripts/diagnostics/`.

UE4SS Lua modules for Gothic 1 Remake, plus a Windows settings app. One switch per module. All settings apply while
the game runs.

| Module | Function |
|---|---|
| repopulate | Respawns creatures, herbs, world items, chest contents. Skips named NPCs, quest and story items. |
| markers | Named NPCs on the map at their current position. |
| general | On-screen note style and font. |
| regen | Mana and health regeneration. |
| magic | Spell damage, mana cost, cast time, projectile speed, range, stagger. |
| melee | Melee assist, hit stop, camera shake. |
| mining | Ore per swing from attributes and mining skill. |
| xp | XP multiplier. |
| locks | Lock picking based on skill. |
| wait | Skip game time on a key. |
| mount | Scavenger name; whistle fix. |
| movement | Walk, run, swim and scavenger speed. |
| intro | Skip startup logos. |
| keys | Mod key list (F3). |
| timers | Remaining effect durations. |
| othermods | Settings for some other mods. |

Details per module: `G1R_MegaMod/modules/<name>/README.txt`.

## Install

1. Requires UE4SS fork "AngelScript Fix 0.4" (UE4SS v3.0.1 beta).
2. Copy `G1R_MegaMod` to `<game>/G1R/Binaries/Win64/ue4ss/Mods/`.
3. Configure in the settings app, the in-game menu (F2, needs SharedModMenu), or
   `modules/<name>/Scripts/config.lua`. Newer modules change nothing until configured.

Check: `UE4SS.log` has one load line per module.

## Layout

| Path | Contents |
|---|---|
| `G1R_MegaMod/` | Mod folder for `ue4ss/Mods`: loader, kit, settings service, diagnostics, modules |
| `G1R_MegaMod/dev/` | Game facts (`FACTS.md`, `facts/`), offline tests, tools |
| `app/` | Settings app (C#, .NET 8, WinForms) |
| `deploy/` | Installer and audit for the author's PC |
| `research/` | Game research method and tools |
| `docs/` | Author's PC notes, old plans |
| `HANDOFF.md` | Current state and work queue |
| `CLAUDE.md` | Rules for Claude Code sessions |

## Develop

Offline tests. Linux or WSL, Lua 5.4, Python 3, path without spaces or apostrophes:

```
sudo apt-get install -y lua5.4 python3 zip unzip
python3 G1R_MegaMod/dev/run_tests.py
```

Expected: `ALL PASSED`, lint 0 errors.

Read first: `G1R_MegaMod/dev/AI_GUIDE.md`, then `dev/MODULES.md`, then `dev/SETTINGS.md`. Every game fact is tagged
with its source: IN-GAME, DISASM, SOURCE, OFFLINE or UNKNOWN.

Settings app:

```
dotnet publish app/src/G1R_Repopulate_Settings.csproj -c Release -r win-x64 --self-contained false -o <out>
dotnet run --project app/filetests -- --selftest <config.lua> <report>
python3 app/tools/linux_check.py    # Linux: file tests + full compile, needs dotnet-sdk-8.0
```

## Not included

- Game files: scripts, usmap, executable, pak contents. Research tools read your own copy (`research/README.md`).
- `app/src/StartupLoadingScreen.txt`: generate from your game with `app/tools/make_startup_screen.py`.
- Other authors' mods: no code, text or images. `deploy/` retires some overlapping mods on the author's PC and
  migrates their settings.
