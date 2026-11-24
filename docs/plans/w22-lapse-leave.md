# w22-lapse-leave: AI leaves a lapsing bridge; no teeter for the dead; HUD AP needed vs held
## Calls
1. `AI._leave(b,u,log)` (new, before the strike/walk phases, only if not rooted, self-directed or ordered alike): if `b.gives_way(u.cell)` and not floating/flight, walk (`b.walk(..., true)`) to the reachable tile not itself `gives_way` with the least `hazard(..., ends=true)` hp owed (x100) then fewest steps; refresh reads. Reuses gives_way + hazard (same pricing as ending a walk on a hazard); no per-skill branch. Stays if no such tile. Player units untouched (AI.gd only).
2. `_teeter`: after `break_layer`, `if not u.is_alive(): return` (it fell via `_restack`; `layer_broke` already logs the break). No teetered signal for the dead.
3. HUD `_short`: AP case reads "Not enough AP for X (needs N, has M)" with `u.ap_cost(s, fund)` (the charged price, Exhaustion included) vs `u.ap_for(pool)`; the suffix only when need > has (else the shortage is elsewhere, e.g. a move-only pool). Energy case unchanged.
## Tests (mutation each fails)
- starbuilding_test.test_ai_leaves_lapsing_bridge; test_teeter_dead_unit_silent; hud_test.test_short_says_ap.
## Undone
- Not leaving when it could rather strike from the bridge; it always leaves first (a fall is worse). Leaving picks nearest safe tile, not the best tactical one.
