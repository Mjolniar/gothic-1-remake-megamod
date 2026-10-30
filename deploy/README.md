# deploy

> AI-generated.

Installer, independent audit and rehearsal for the author's PC (Windows Python).

| File | Function |
|---|---|
| `install_megamod.py` | Installs/updates G1R_MegaMod and the settings app from a `-dev` package. Retires other authors' mods a module replaced and migrates their settings. Backs up every replaced file with a rollback script. Refuses while the game runs. |
| `audit_megamod.py` | Checks the PC independently of the installer: Mods folder, save hashes, UE4SS.dll, settings app, desktop shortcut. Last line `AUDIT OK`. |
| `sim_megamod.py` | Builds a mock PC in a temp folder and runs installer, rollback and audit against it. `--pc-mods` / `--pc-backup`: rehearsal on copies of the real folders. |

Paths go in `deploy_settings.json` next to the scripts (not in the repository). Copy `deploy_settings.example.json`:

| Key | Value |
|---|---|
| `game` | Gothic 1 Remake folder (contains `G1R`) |
| `saves` | Save folder (`...\AppData\Local\G1R\Saved\SaveGames`) |
| `project` | Work folder: `megamod\` with packages; backup folders go here |
| `shortcut` | Settings app desktop shortcut |

`python install_megamod.py --check` shows the plan without changes. Run without `--check` only with the game closed, then
`python audit_megamod.py`.
