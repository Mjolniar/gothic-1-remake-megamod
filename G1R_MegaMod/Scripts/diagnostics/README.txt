Diagnostics - written while the game runs
=========================================
AI-generated. Bugs: see G1R_MegaMod\README.txt.

A flight recorder for problem reports. Not needed to play; everything except this
README.txt can be deleted (best with the game closed). When reporting a problem, send
the files of the session it happened in. They hold module log lines, errors, and how the
modules use the game. Mod paths are written as <mod>/..., hiding the install location.

Files
-----
session-YYYYMMDD-HHMMSS.log
    One per game start. Lines:  HH:MM:SS [module] text
    [repopulate], [markers] etc. are modules; [loader] and [diag] the mod itself. Holds
    every module line, breadcrumbs, errors with traceback (indented under ERROR), and
    notes when a fact is learned or changes ("note key = value (detail)").
    Normal lines are flushed every 20 s. A breadcrumb (text starting with ">") is written
    at once before a risky step, e.g. the first path lookup ("> lookup /Script/..."), and
    so is the next line. A log ENDING with a breadcrumb means the game most likely died in
    that step.
    Newest 5 kept (SessionFiles in Scripts/config.lua).

session-YYYYMMDD-HHMMSS.ops
    Last 256 operations of that start: every step that calls into the game for more than
    a moment (search of all objects, container round, map pin refresh). Fixed-length lines:
        00000042 > 12:19:44 repopulate containers: look at new objects (25 waiting)
                 ^ ">" step begun, "=" step finished
    Written and flushed before the step runs, so it survives a crash inside the step. The
    newest line has the highest number (ring file; after 256 lines the oldest are
    overwritten).
    After a crash: use the session BEFORE the newest (the restart made a new one). If its
    newest .ops line is ">", the game died in that step. An older ">" is a step that
    ended with an error (see the session log).
    Kept and deleted with its session log.

session-YYYYMMDD-HHMMSS.report.txt
    Last report of that start (same text as report-latest.txt), so the previous session's
    report survives a restart. Kept and deleted with its session log.

report-latest.txt
    Rewritten at game start, every 5 minutes, and by "g1r diag". Order: header (mod,
    version, time, minutes since load), modules (loaded or not, with error), module status
    lines, notes as "key = value (detail) [first seen HH:MM:SS]", counters per module,
    errors (count, first traceback), last 120 recorder lines.
    Counters: "lookups" = path searches (calls, first-time searches, not found, repeated
    after not found - each walks every game object -, total time, slowest path);
    "FindAllOf" / "FindFirstOf" calls and time; "callbacks" per kind (calls, errors, calls
    slower than SlowCallMs, longest); "registered" per kind (ok, failed).

report-YYYYMMDD-HHMMSS.txt
    Same report under its own name; only from "g1r diag".

dump-YYYYMMDD-HHMMSS.lua
    Only from "g1r dump": module state at that moment (tracked containers, map pins, ...)
    as a Lua table. "_meta" names the dumped module; unwritable values become
    "<refused: ...>" and are listed in "_meta.refused".

sessions.txt
    Session log names, oldest first. Used to delete old logs (the mod cannot list a
    folder). Only files named here and named like a session log are deleted, each with
    its .ops and .report.txt.

Console (UE4SS console)
-----------------------
g1r          module and diagnostics status
g1r diag     write a report now, show where
g1r dump     write a dump
g1r help     command list

Settings
--------
Scripts/config.lua, Config.Diagnostics. Level = "off" writes nothing; "verbose" writes
every line at once and records more (crash hunting). If this folder is not writable, the
mod notes it once in UE4SS.log and continues without files.
