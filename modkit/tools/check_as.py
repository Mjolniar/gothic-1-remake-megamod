"""Checks the names the official mod's AngelScript uses against the game (nothing can be compiled outside the game).

    python3 modkit/tools/check_as.py <ModKit>/Script <ModKit gh-pages folder>

Every type (U.., A.., F.., E.., T..), every member after "." and every name after "::" in modkit/G1R_MegaMod/Script
must be named by the game's scripts, by the reference of its native classes, or by our own scripts. A name none of
them knows is reported with its file and line: an invented or misspelt name, the most likely compile error. Syntax
and types are not checked - the game reports those when it compiles the scripts (start it with -as-development-mode).
Exit status 1 when a name is unknown.
"""
import html
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
OURS = os.path.normpath(os.path.join(HERE, "..", "G1R_MegaMod", "Script"))
IDENT = re.compile(r"[A-Za-z_][A-Za-z0-9_]*")
# what the language and the engine bring without the reference naming it
BUILTIN = {
    "TArray", "TMap", "TSet", "TSubclassOf", "TSoftObjectPtr", "TSoftClassPtr", "TWeakObjectPtr", "TOptional",
    "FString", "FName", "FText", "FVector", "FVector2D", "FRotator", "FTransform", "FLinearColor", "FColor", "FKey",
    "FMargin", "FGeometry", "FGameplayTag", "FGameplayTagContainer", "FTimerHandle", "UObject", "UClass", "AActor",
    "Num", "Add", "AddUnique", "Remove", "RemoveAt", "Contains", "Find", "FindOrAdd", "Empty", "Reset", "IsEmpty",
    "IsValid", "Get", "Set", "Value", "Key", "ToString", "IsNone", "Len", "Abs", "Max", "Min", "Clamp", "Floor",
    "RoundToInt", "FloorToInt", "TruncToInt", "CeilToInt", "Sqrt", "Pow", "DefaultObject", "StaticClass",
    # engine keys (EKeys::...)
    *[chr(c) for c in range(ord("A"), ord("Z") + 1)],
    "Zero", "One", "Two", "Three", "Four", "Five", "Six", "Seven", "Eight", "Nine",
    *["F%d" % i for i in range(1, 13)],
    *["NumPad" + d for d in ("Zero", "One", "Two", "Three", "Four", "Five", "Six", "Seven", "Eight", "Nine")],
}


def strip(text):
    """The code without comments and string literals (their contents are no names)."""
    text = re.sub(r"/\*.*?\*/", lambda m: "\n" * m.group(0).count("\n"), text, flags=re.S)
    text = re.sub(r"//[^\n]*", "", text)
    return re.sub(r'(?:[nf]?)"(?:[^"\\\n]|\\.)*"', '""', text)


def index_game(scripts, site):
    names = set()
    for d, _, files in os.walk(scripts):
        for f in files:
            if f.endswith(".as"):
                names.update(IDENT.findall(strip(open(os.path.join(d, f), encoding="utf-8", errors="replace").read())))
    ref = os.path.join(site, "script-reference")
    tag = re.compile(r"<[^>]+>")
    for f in os.listdir(ref):
        if f.endswith(".html") or f.endswith(".js"):
            names.update(IDENT.findall(html.unescape(tag.sub(" ", open(os.path.join(ref, f), encoding="utf-8", errors="replace").read()))))
    return names


def main():
    if len(sys.argv) != 3:
        print(__doc__)
        return 2
    known = index_game(sys.argv[1], sys.argv[2]) | BUILTIN
    files = []
    for d, _, fs in os.walk(OURS):
        for f in sorted(fs):
            if f.endswith(".as"):
                files.append(os.path.join(d, f))
    ours = set()
    code = {}
    for p in files:
        text = strip(open(p, encoding="utf-8").read())
        code[p] = text
        # our own declarations: classes, structs, enums, namespaces, functions, members, variables, parameters
        ours.update(re.findall(r"\b(?:class|struct|enum|namespace)\s+(\w+)", text))
        ours.update(re.findall(r"\b[A-Za-z_][\w<>, ]*[\w>&]\s+(\w+)\s*[(=;,)]", text))
        for body in re.findall(r"\benum\s+\w+\s*\{([^}]*)\}", text):
            ours.update(IDENT.findall(body))
    bad = 0
    for p, text in code.items():
        rel = os.path.relpath(p, OURS)
        for n, line in enumerate(text.split("\n"), 1):
            seen = set()
            for m in re.finditer(r"\b([UAFET][A-Z]\w*)\b", line):
                seen.add(m.group(1))
            for m in re.finditer(r"(?:\.|::)\s*([A-Za-z_]\w*)", line):
                seen.add(m.group(1))
            for name in sorted(seen):
                if name not in known and name not in ours and not name.isdigit():
                    print("%s:%d: unknown name %s" % (rel, n, name))
                    bad += 1
    print("%d file(s), %d unknown name(s)" % (len(files), bad))
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main())
