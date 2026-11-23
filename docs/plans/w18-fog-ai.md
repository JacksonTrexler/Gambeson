# w18-fog-ai: known_ground reads explored

Calls:
- Sight on: `known_ground(u,c)` = PLAIN unless c in `explored[u.faction]` (then the old read rule: hidden/obscured -> plain). Sight off: unchanged.
- Fill: lazy, `_mark_seen(u)` adds u's own perception disc once per cell it plans from (`_marked_at[u]`); one disc (~hundreds of cells), not the side's union; no per-turn rebuild, no sight_cells() for AI. Teammates' discs join when they plan.
- Gap: ground a unit walked past but didn't plan from isn't marked until it plans again.
As built: Battle.known_ground/_mark_seen/_marked_at; Tests/sight_test.test_known_ground_follows_explored.
Mutation: explored check disabled -> test fails (1). Suite 11260ish -> 11326 checks/1065 tests, 0 failed.
busy_fight 15v15 (30 units): mean 20.5/p95 48.0 ms here -> 20.3/47.1 (target x4 82/192 -> 81/188); 20v20 23.5/51.8 -> 23.5/51.5.
