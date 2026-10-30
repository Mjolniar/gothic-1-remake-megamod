"""Checks the megamod's data from the game's scripts against the official G1R ModKit (after a game update).

    git clone --depth 1 https://github.com/AlkimiaInteractive/G1R-Modkit <modkit>
    python3 dev/tools/modkit_check.py <modkit>/Script [--site <folder of the ModKit's gh-pages branch>]

Run from G1R_MegaMod/. The ModKit holds the game's AngelScript sources as shipped; its gh-pages branch the scripting
reference (native classes and their members). Nothing here is written; the tables are made by hand or by their own
generators (the lock tables: dev/tests/locks/tools/make_tables.py, which takes the same Script folder).

Compared:
  chests      modules/repopulate/Scripts/data/chests.lua: every container and the contents kept for it
  creatures   data/creature_points.lua: every spawn point's place, handler and what it spawns; points of the game that
              spawn only creature kinds of the table, unconditionally, and are not in it (to look at by hand)
  items       data/item_points.lua: every item spot's refill and event; world-start spots with ordinary items that are
              not in the table (to look at by hand)
  effects     the timers module's rules (KINDS / SKIP of its main.lua) over every effect class of the game: what each
              kind would show
  npcs        modules/markers/Scripts/npcs.lua: every id is a unique name of the game (without regard to capital
              letters, as the game compares names)
  members     with --site: every `Class.member` named in dev/FACTS.md and dev/facts/*.md that the reference or the
              scripts know the class of, but not the member
Exit status 1 when a table differs from the game (the lists "to look at by hand" do not count).
"""
import argparse
import glob
import html
import os
import re
import sys

MOD = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", ".."))
DATA = os.path.join(MOD, "modules", "repopulate", "Scripts", "data")
DECL = re.compile(r'^\s*(?:UCLASS\([^)]*\)\s*)?(?:class|struct)\s+(\w+)\s*(?::\s*(\w+))?', re.M)


def scripts_of(root):
    """Class name -> (file, body, parent) over every .as file."""
    out = {}
    for d, _, files in os.walk(root):
        for f in files:
            if not f.endswith(".as"):
                continue
            path = os.path.join(d, f)
            text = open(path, encoding="utf-8", errors="replace").read()
            found = list(DECL.finditer(text))
            for i, m in enumerate(found):
                end = found[i + 1].start() if i + 1 < len(found) else len(text)
                out.setdefault(m.group(1), (os.path.relpath(path, root), text[m.end():end], m.group(2)))
    return out


def check_chests(classes):
    ours = {}
    text = open(os.path.join(DATA, "chests.lua"), encoding="utf-8").read()
    for m in re.finditer(r'\["([^"]+)"\]\s*=\s*\{\s*s\s*=\s*\w+,\s*k\s*=\s*"\w+",\s*i\s*=\s*\{(.*?)\}\s*\}\s*,?\n', text):
        ours[m.group(1)] = dict((k, int(v)) for k, v in re.findall(r'\{\s*"(\w+)",\s*(\d+)\s*\}', m.group(2)))
    game = {}
    for _, (_, body, _) in classes.items():
        name = re.search(r'm_UniqueName\s*=\s*n"([^"]+)"', body)
        if not name or "AddToInventory" not in body:
            continue
        items = {}
        for item, n in re.findall(r'AddToInventory\(\s*U(\w+)(?:::StaticClass\(\))?\s*,\s*(\d+)\s*\)', body):
            items[item] = items.get(item, 0) + int(n)
        game.setdefault(name.group(1), items)
    bad = 0
    for c, items in sorted(ours.items()):
        g = game.get(c)
        if g is None:
            print("  chests: %s is not a container of the game any more" % c)
            bad += 1
            continue
        diff = ["%s %s -> %s" % (i, n, g.get(i, "-")) for i, n in items.items() if g.get(i) != n]
        if diff:
            print("  chests: %s: %s (the game has: %s)" % (c, ", ".join(diff), ", ".join("%s %d" % kv for kv in g.items())))
            bad += 1
    print("chests: %d containers, %d differ" % (len(ours), bad))
    return bad


def spawns_of(body):
    out = {}
    for d, r in re.findall(r'SpawnAIAgent\(\s*U(SpawnAIAgentDefinition_\w+)::StaticClass\(\)\s*(?:,\s*(?:dailyRoutine\s*=\s*)?U(\w+)\(\))?', body):
        out[(d, r or "")] = out.get((d, r or ""), 0) + 1
    return sorted((d, r, n) for (d, r), n in out.items())


def check_creatures(root, classes):
    ours = {}
    text = open(os.path.join(DATA, "creature_points.lua"), encoding="utf-8").read()
    for m in re.finditer(r'^  \["([^"]+)"\] = \{ c = "([^"]+)", x = ([-\d.]+), y = ([-\d.]+), z = ([-\d.]+), ch = (\w+), s = \{(.*)\} \},?$', text, re.M):
        spawns = sorted((d, r.strip('"') if r != "nil" else "", int(n))
                        for d, r, n in re.findall(r'd = "(\w+)", r = (nil|"\w+"), u = "[^"]*", e = \w+, n = (\d+)', m.group(7)))
        ours[m.group(1)] = (m.group(2), tuple(float(v) for v in m.group(3, 4, 5)), m.group(6) == "true", spawns)
    places = {}
    for path in glob.glob(os.path.join(root, "Map", "**", "*.as"), recursive=True):
        text = open(path, encoding="utf-8", errors="replace").read()
        for m in re.finditer(r'AddWorldPoint\(n"([^"]+)"\);\s*(?:default\s+AddWorldScene\([^;]*\);\s*)?default\s+AddWorldPosition\(FRotator\([^)]*\),\s*'
                             r'FVector\(([-\d.]+),\s*([-\d.]+),\s*([-\d.]+)\)', text):
            places.setdefault(m.group(1), tuple(float(v) for v in m.group(2, 3, 4)))
    points = {name[1:]: body for name, (_, body, parent) in classes.items() if parent == "UWorldPointScript"}
    bad = 0
    for name, (cls, place, chapter, spawns) in sorted(ours.items()):
        problems = []
        body = points.get(cls)
        if body is None:
            problems.append("no script class")
        else:
            if ("OnChapterRespawn" if chapter else "OnWorldStart") not in body:
                problems.append("no " + ("OnChapterRespawn" if chapter else "OnWorldStart"))
            if spawns_of(body) != spawns:
                problems.append("spawns %s -> %s" % (spawns, spawns_of(body)))
        p = places.get(name)
        if p is None:
            problems.append("no place")
        elif max(abs(a - b) for a, b in zip(p, place)) > 1.0:
            problems.append("moved %s -> %s" % (place, p))
        if problems:
            print("  creatures: %s: %s" % (name, "; ".join(problems)))
            bad += 1
    print("creatures: %d spawn points, %d differ" % (len(ours), bad))
    kinds = {d for _, _, _, spawns in ours.values() for d, _, _ in spawns}
    known = {cls for cls, _, _, _ in ours.values()}
    for name, body in sorted(points.items()):
        if name in known or re.search(r'\bif\s*\(|Quest|Chapter\s*[<>=]', body) or not re.search(r'void\s+(OnWorldStart|OnChapterRespawn)\s*\(', body):
            continue
        sp = spawns_of(body)
        # (the table leaves out the Sleeper Temple, Xardas' tower and the test maps)
        if sp and all(d in kinds for d, _, _ in sp) and name in places and "_TST_" not in name and not name.startswith(("ST_", "XT_")):
            print("  creatures, to look at: %s spawns %s and is not in the table" % (name, ", ".join("%s x%d" % (d[23:], n) for d, _, n in sp)))
    return bad


def check_items(root):
    ours = {m.group(1): (m.group(2), int(m.group(3)))
            for m in re.finditer(r'\["([^"]+)"\] = \{ p = "(\w+)", r = (\d+) \}', open(os.path.join(DATA, "item_points.lua"), encoding="utf-8").read())}
    path = os.path.join(root, "Map", "MainMap", "ItemSpawnManagerConfig_MainMap.as")
    game = {}
    for part in re.split(r'default\s+SetWorldPoint\(', open(path, encoding="utf-8", errors="replace").read())[1:]:
        refill = re.search(r'SetRefill\((\d+)\)', part)
        game[re.match(r'n"([^"]+)"', part).group(1)] = (int(refill.group(1)) if refill else 0, re.findall(r'AddItemsEvent\(n"([^"]+)"\)', part),
                                                        re.findall(r'AddItem\(\d+,\s*U(\w+)::StaticClass', part))
    bad = 0
    for name, (kind, refill) in sorted(ours.items()):
        g = game.get(name)
        problems = []
        if g is None:
            problems.append("not a spot of the game any more")
        else:
            if kind != "loose" and g[0] != refill:
                problems.append("refill %d -> %d" % (refill, g[0]))
            if g[1] != ["OnWorldStart"]:
                problems.append("events %s" % g[1])
        if problems:
            print("  items: %s: %s" % (name, "; ".join(problems)))
            bad += 1
    print("items: %d spots, %d differ" % (len(ours), bad))
    allowed = {item for name in ours if name in game for item in game[name][2]}
    for name, (refill, events, items) in sorted(game.items()):
        if name not in ours and events == ["OnWorldStart"] and items and all(i in allowed for i in items) and "test" not in name.lower():
            print("  items, to look at: %s (refill %d: %s) is not in the table" % (name, refill, ", ".join(items)))
    return bad


def check_effects(classes):
    main = open(os.path.join(MOD, "modules", "timers", "Scripts", "main.lua"), encoding="utf-8").read()
    skip = re.findall(r'"([^"]+)"', re.search(r'local SKIP = \{(.*?)\}', main, re.S).group(1))
    rules = []
    for label, body in re.findall(r'\{ label = "([^"]+)", group = "\w+", fits = function\(n\) return (.*?) end \}', main):
        expr = re.sub(r'has\(n, "([^"]+)"\)', r'("\1" in n)', body).replace("~=", "!=")
        expr = re.sub(r'n == "([^"]+)"', r'(n == "\1")', expr)
        rules.append((label, expr))

    def effect(c):
        seen = set()
        while c in classes and c not in seen:
            seen.add(c)
            c = classes[c][2]
            if c in ("UGameplayEffect", "UGothicGameplayEffect"):
                return True
        return False

    def policy(c):
        while c in classes:
            m = re.search(r'default\s+DurationPolicy\s*=\s*EGameplayEffectDurationType::(\w+)', classes[c][1])
            if m:
                return m.group(1)
            c = classes[c][2]
        return "?"
    shown, count = {}, 0
    for c in sorted(classes):
        if not (effect(c) or c.startswith("UGE_")):
            continue
        count += 1
        n = c[1:]
        if policy(c) in ("Instant", "Infinite") or n.endswith("Stack") or any(s in n for s in skip):
            continue
        label = next((lab for lab, expr in rules if eval(expr, {}, {"n": n})), None)      # the module's own rules
        if label:
            shown.setdefault(label, []).append(n)
    print("effects: %d effect classes; what the timers would show:" % count)
    for label, names in shown.items():
        print("  %-12s %s" % (label, ", ".join(names)))
    return 0


def check_npcs(root):
    ours = re.findall(r'id = "([^"]+)"', open(os.path.join(MOD, "modules", "markers", "Scripts", "npcs.lua"), encoding="utf-8").read())
    names = set()
    for path in glob.glob(os.path.join(root, "**", "*.as"), recursive=True):
        names.update(n.lower() for n in re.findall(r'm_UniqueName\s*=\s*n"([^"]+)"', open(path, encoding="utf-8", errors="replace").read()))
    gone = [i for i in ours if i.lower() not in names]
    for i in gone:
        print("  npcs: %s is not a unique name of the game" % i)
    print("npcs: %d ids, %d not in the game" % (len(ours), len(gone)))
    return len(gone)


def check_members(site, classes):
    ref = os.path.join(site, "script-reference")
    native = {}
    for js in glob.glob(os.path.join(ref, "class_*.js")) + glob.glob(os.path.join(ref, "struct_*.js")):
        page = js[:-3] + ".html"
        if not os.path.exists(page):
            continue
        m = re.search(r'<title>G1R AngelScript: (\w+) (?:Class|Struct) Reference</title>', open(page, encoding="utf-8", errors="replace").read(4000))
        if m:
            native[m.group(1)] = set(re.findall(r'\[ "([^"]+)"', open(js, encoding="utf-8", errors="replace").read()))

    def has(cls, member):
        for start in (cls, "U" + cls, "A" + cls, "F" + cls):
            c, seen = start, set()
            while c and c not in seen:
                seen.add(c)
                if member in native.get(c, ()):
                    return True
                if c in classes and re.search(r'\b' + re.escape(member) + r'\b', classes[c][1]):
                    return True
                c = classes[c][2] if c in classes else None
        return False
    facts = glob.glob(os.path.join(MOD, "dev", "facts", "*.md")) + [os.path.join(MOD, "dev", "FACTS.md")]
    pairs = {}
    for f in facts:
        for m in re.finditer(r'`([A-Z]\w+)\.(\w+)`', open(f, encoding="utf-8").read()):
            if m.group(2) != "as":
                pairs.setdefault((m.group(1), m.group(2)), set()).add(os.path.basename(f))
    missing = 0
    for (c, member), where in sorted(pairs.items()):
        if any(x in native or x in classes for x in (c, "U" + c, "A" + c, "F" + c)) and not has(c, member):
            print("  members: %s.%s (%s): the reference and the scripts do not name it (a private property, or gone)" % (c, member, ", ".join(sorted(where))))
            missing += 1
    print("members: %d pairs named in the facts, %d not named by the game's reference or scripts" % (len(pairs), missing))
    return 0


def main():
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("script", help="the ModKit's Script folder")
    ap.add_argument("--site", help="the ModKit's gh-pages branch (for the members check)")
    a = ap.parse_args()
    if not os.path.isdir(a.script):
        print("not a folder: " + a.script)
        return 2
    classes = scripts_of(a.script)
    bad = check_chests(classes) + check_creatures(a.script, classes) + check_items(a.script) + check_effects(classes) + check_npcs(a.script)
    if a.site:
        check_members(a.site, classes)
    print("TABLES MATCH THE GAME" if bad == 0 else "TABLES DIFFER FROM THE GAME: %d" % bad)
    return 0 if bad == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
