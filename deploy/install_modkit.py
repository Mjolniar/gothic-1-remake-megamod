"""Installs the official MegaMod package (modkit/G1R_MegaMod) into the game's mod folder, on the player's PC.

    python install_modkit.py --check                 what would be done, nothing written
    python install_modkit.py                         install (game closed)
    python install_modkit.py --disable-ue4ss         also move UE4SS's loader DLL out of the game folder
    python install_modkit.py --scavenger-name "Name" also give the rideable scavenger that name (a text override)
    python install_modkit.py --rollback <backup>     put a backup folder of this script back

Windows Python. The places come from deploy_settings.json next to this script ("game", "project").
- The game, the mod manager and the settings app must be closed (tasklist); otherwise nothing is done.
- <game>/G1R/Mods/G1R_MegaMod is replaced by modkit/G1R_MegaMod; the folder it replaces goes to
  <project>/modkit-install-backup-<time>/Mods/G1R_MegaMod first. Nothing else of the game is touched.
- --disable-ue4ss: since the game's 1.1 hotfix the game exits when UE4SS is loaded. The loader DLL next to the game's
  executable (the one that loads ue4ss/UE4SS.dll: dwmapi.dll, else another known proxy name) is moved into the same
  backup folder. The ue4ss folder itself stays as it is (UE4SS.dll keeps its hash).
- --scavenger-name: the game names a character from its text table by its unique name (mount facts M9); the package
  gets a text override for Scavenger_Adult_Rideable (Config/Game.ini mount point + Story/Names/text/*.textdb.yaml, the
  ModKit's localization override). Without it the scavenger keeps the game's name.
- Herb regrowth needs Script/G1R_MegaMod/Repopulate/MegaRegrowth.as, made by modkit/tools/gen_regrowth.py from a
  clone of the official ModKit; without it the install goes on and says so.
- Saves are not touched; copy them yourself before the first load on a new game version.
"""
import argparse
import datetime
import hashlib
import json
import os
import shutil
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
SOURCE = os.path.normpath(os.path.join(HERE, "..", "modkit", "G1R_MegaMod"))
PROXIES = ("dwmapi.dll", "xinput1_3.dll", "xinput1_4.dll", "d3d11.dll", "dxgi.dll", "version.dll", "winmm.dll")
BLOCKERS = ("g1r-win64-shipping.exe", "g1r.exe", "isklauncher.app.exe", "g1r_repopulate_settings.exe")


def refuse(text):
    print("REFUSED: " + text + " Nothing changed.")
    sys.exit(1)


def running():
    try:
        r = subprocess.run(["tasklist", "/FO", "CSV", "/NH"], stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=60)
    except Exception:
        return None
    if r.returncode != 0:
        return None
    return [line.strip()[1:].split('"', 1)[0].lower() for line in r.stdout.decode("ascii", "replace").splitlines()
            if line.strip().startswith('"')]


def sha(path):
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for block in iter(lambda: f.read(1 << 20), b""):
            h.update(block)
    return h.hexdigest()


def files_of(root):
    out = {}
    for d, _, fs in os.walk(root):
        for f in fs:
            p = os.path.join(d, f)
            out[os.path.relpath(p, root).replace("\\", "/")] = sha(p)
    return out


LANGUAGES = ("english", "german", "french", "spanish", "russian")


def write_name(target, name):
    """The text override that names the rideable scavenger (ModKit example Example-LocalizationOverride)."""
    os.makedirs(os.path.join(target, "Config"), exist_ok=True)
    with open(os.path.join(target, "Config", "Game.ini"), "w", encoding="utf-8", newline="\r\n") as f:
        f.write("[/Script/AlkimiaStoryFileImport.AlkimiaLocalizationSubsystem]\n")
        f.write('+MountPoints=(MountPoint="/G1R_MegaMod", Module="G1R_MegaMod", MountPath="/Story/Names")\n')
    folder = os.path.join(target, "Story", "Names", "text")
    os.makedirs(folder, exist_ok=True)
    with open(os.path.join(folder, "megamod_names.textdb.yaml"), "w", encoding="utf-8", newline="\n") as f:
        f.write("Scavenger_Adult_Rideable:\n")
        for lang in LANGUAGES:
            f.write('  %s: "%s"\n' % (lang, name))


def main():
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--check", action="store_true")
    ap.add_argument("--disable-ue4ss", action="store_true")
    ap.add_argument("--rollback")
    ap.add_argument("--scavenger-name")
    a = ap.parse_args()
    try:
        with open(os.path.join(HERE, "deploy_settings.json"), encoding="utf-8") as f:
            places = json.load(f)
        game, project = places["game"], places["project"]
    except (OSError, ValueError, KeyError):
        refuse("deploy_settings.json next to this script is missing or has no \"game\" / \"project\".")
    win64 = os.path.join(game, "G1R", "Binaries", "Win64")
    mods = os.path.join(game, "G1R", "Mods")
    target = os.path.join(mods, "G1R_MegaMod")
    if not os.path.isdir(win64):
        refuse("no game at " + game + ".")
    names = running()
    if names is None:
        refuse("the list of running programs could not be read (tasklist).")
    busy = [n for n in BLOCKERS if n in names]
    if busy:
        refuse("close these first: " + ", ".join(busy) + ".")

    if a.rollback:
        back = a.rollback
        if not os.path.isdir(back):
            refuse("no backup folder " + back + ".")
        steps = []
        if os.path.isdir(os.path.join(back, "Mods", "G1R_MegaMod")):
            steps.append(("mod", os.path.join(back, "Mods", "G1R_MegaMod"), target))
        for p in PROXIES:
            if os.path.isfile(os.path.join(back, "Win64", p)):
                steps.append(("loader", os.path.join(back, "Win64", p), os.path.join(win64, p)))
        for kind, src, dst in steps:
            print("put back %s: %s -> %s" % (kind, src, dst))
            if a.check:
                continue
            if kind == "mod":
                if os.path.isdir(dst):
                    shutil.rmtree(dst)
                shutil.copytree(src, dst)
            else:
                shutil.copy2(src, dst)
        print("ROLLBACK CHECKED (nothing written)" if a.check else "ROLLBACK DONE")
        return 0

    if not os.path.isfile(os.path.join(SOURCE, "GothicMod.json")):
        refuse("no package at " + SOURCE + ".")
    stamp = datetime.datetime.now().strftime("%Y%m%d-%H%M%S")
    backup = os.path.join(project, "modkit-install-backup-" + stamp)
    loader = None
    if a.disable_ue4ss:
        for p in PROXIES:
            if os.path.isfile(os.path.join(win64, p)):
                loader = p
                break
    regrowth = os.path.join(SOURCE, "Script", "G1R_MegaMod", "Repopulate", "MegaRegrowth.as")
    if not os.path.isfile(regrowth):
        print("NOTE: no MegaRegrowth.as (run modkit/tools/gen_regrowth.py <G1R-Modkit/Script> first): herbs and items regrow as the game has it")
    name = (a.scavenger_name or "").strip()
    if any(c in name for c in '"\\\r\n') or len(name) > 40:
        refuse("the scavenger's name must be at most 40 letters, without quotes, backslashes or line breaks.")
    new = files_of(SOURCE)
    old = files_of(target) if os.path.isdir(target) else {}
    print("package: %s (%d files)" % (SOURCE, len(new)))
    print("into:    %s (%s)" % (target, "replaces %d files" % len(old) if old else "new"))
    print("backup:  %s" % backup)
    if name:
        print("scavenger: named \"%s\" (text override)" % name)
    if a.disable_ue4ss:
        print("UE4SS loader: %s" % ("moves to the backup: " + os.path.join(win64, loader) if loader else "none of %s found next to the game: nothing to move" % ", ".join(PROXIES)))
    if a.check:
        print("CHECK OK (nothing written)")
        return 0
    os.makedirs(backup)
    if old:
        shutil.copytree(target, os.path.join(backup, "Mods", "G1R_MegaMod"))
        shutil.rmtree(target)
    os.makedirs(mods, exist_ok=True)
    shutil.copytree(SOURCE, target)
    if loader:
        os.makedirs(os.path.join(backup, "Win64"), exist_ok=True)
        shutil.move(os.path.join(win64, loader), os.path.join(backup, "Win64", loader))
    if files_of(target) != new:
        refuse("the installed files differ from the package (copy failed); the backup is " + backup + ".")
    if name:
        write_name(target, name)
    with open(os.path.join(backup, "README.txt"), "w", encoding="utf-8") as f:
        f.write("Backup of install_modkit.py, %s.\nRollback: python install_modkit.py --rollback \"%s\"\n" % (stamp, backup))
    print("INSTALLED: %d files; backup %s" % (len(new), backup))
    return 0


if __name__ == "__main__":
    sys.exit(main())
