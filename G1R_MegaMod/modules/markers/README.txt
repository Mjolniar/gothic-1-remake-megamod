Module "markers" (NPCMarkers 2.7) - Gothic 1 Remake, UE4SS Lua
===============================================================
AI-generated. Bugs: see G1R_MegaMod\README.txt.

Function
  Map (M) shows every named NPC (181, Scripts/npcs.lua) at their current position:
    blue pin            teacher        name "(T)- Name"
    gold pin            trader         name "(M)- Name"
    blue/gold pin       both           name "(T/M)- Name"
    red pin (smaller)   other named NPC
    green pin (smaller) orc
  PinLook: "drawn" (default; hand-inked pins, numbers and names, parchment colour key,
  like the game's maps) or "classic" (coloured dots, white name plates).
  Names use the game's text font (Noto Serif); NameLetters "gothic" = blackletter.
  Colour key at bottom left, left of the game's buttons (below them if no room).
  World map and camp maps (Old Camp, New Camp, Swamp Camp, Orc Enclave, Sleeper Temple).
  Dead NPCs hidden. NPCs not yet created are hidden, except a few with a known routine
  spot, shown faded there.

Overlap
  World map: 4+ people within 26 map units form one numbered badge ("pool"). Hover to
  list them, teachers and traders first. Blue/yellow dot = teacher/trader inside. Badges
  avoid the game's camp names. Lone people keep a semi-transparent pin without a name.
  Camp maps: slightly transparent pins; names only where they fit.
  Hover any pin: it and nearby pins turn solid and their names list under the mouse.

Changes
  2.7  drawn look (default): 469 pictures in Scripts/Assets/Drawn (same names/sizes as
       classic; made by dev/tools/drawn/drawn.py); missing picture = classic. PinLook and
       NameLetters in config.lua and the app (Map > Map pins)
  2.6  map names in the game's text font again (NameLetters "game"; "gothic" for 2.5's
       blackletter)
  2.5  blackletter names while the megamod font is gothic
  2.4  stability: pin pictures kept alive all session (fix for a 2026-10-04 crash); pins
       and names shown only once their image is set (no white boxes); crowded name lists
       built over several updates; map screen not searched among all objects; unknown
       people not searched right after a map load. No visual change.
  2.3  world map pools with hover lists; pins 16 units (was 8; sized for 3840, map is
       1600); colour key at intended size, clear of the button row
  2.2  tiny world pins, transparency until hover, hover lists, camp names only where they
       fit, colour key
  2.1  same pin size on all maps; all 181 named NPCs (was 12); names from localization,
       roles from the glossary; lazy widgets
  2.0  pins at live positions using the game's map projection

Placement
  Same math as the game's player arrow (from G1R-Win64-Shipping.exe, with the GORE
  toolkit):
    position = map bounding box inverse transform of the NPC location * 0.02
    corrected = position + (R,G of the map's correction texture)/255*1.2 - 0.6
  Correction textures are in Scripts/data (exported with GORE). Pins live on their own
  canvas: the game's markers, filters, hover animations and saves are untouched. Nothing
  written to saves.

Settings: Scripts/config.lua
  PinLook                      "drawn" (default) | "classic"
  NameLetters                  "game" (default) | "gothic"
  AreaLabels, WorldLabels      "always" | "auto" | "hover" | "off"
  HoverNames, HoverGroupRadius, HoverListMax, HoverPinScale
  AreaPinSize, WorldPinSize, OtherPinScale, AreaPinOpacity, WorldPinOpacity
  WorldPools, PoolLinkDistance, PoolMinSize, PoolPinSize, PoolOpacity,
  PoolListRows, PoolListMax
  LabelScale, LabelGap, ShowLegend, LegendScale, LegendLeft, LegendBottom,
  LegendAvoidButtons
  ShowOtherNPCs, OtherNPCsOnWorldMap, ShowOrcs, HideIds, ExtraNPCs
  RefreshSeconds, MaxNewWidgetsPerTick, ShowFallbackPins, FallbackOpacity,
  HideDeadNPCs, Verbose

UE4SS.log lines
  [NPCMarkers] v2.7.0 loaded: 181 named NPCs (52 teachers/traders) ...
  [NPCMarkers] Map_World map Area (...): ... | N single pins, N pools with
               N people ... | canvas 1600x900, pin 16 units
  [NPCMarkers] Hover detected on <name | a pool of N> (canvas fast path |
               per-pin polling)
  Self-test numbers (A / B UI px) compare this math with the game's player arrow; near
  0 = exact match.
