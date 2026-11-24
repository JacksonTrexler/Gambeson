# w22-bar-fixes
Goal: (1) disabled Manifest drops the second bar; (2) auto-equip while a second bar is up never lands a non-tag skill on it.
## Calls
- Root 1: `Unit.want_bar()` = alt tag of a toggle that is on AND not in `disabled`, else "". `sync_alt_bar()` = show_bar(want_bar()); called from toggle, disable, tick (after release), Battle._on_downed (disabled.clear). Comes back up when the disabling ends.
- Root 2: `Unit._auto_put(s)` used by equip_skill and auto_fill: if bar_takes(s) -> hotbar; else into the saved regular layout `bars[""]` (laid over hotbar briefly). Full regular bar -> not equipped.
- Battle.gd: one line (u.sync_alt_bar() after disabled.clear()).
## Tests
- test_starchitect_bar +3 checks (disable drops/returns, bar back when disabling ends, learned plain skill goes to regular bar and is there after toggle off). Mutations: want_bar ignoring disabled -> fails; _auto_put always on hotbar -> fails.
