# w22-cast-at: why repeated Battle.cast_at of Startile failed in the w22-shots driver
Goal: reproduce, find cause, fix or explain.
## Root cause: correct behaviour (Exhaustion), no fix
- Repro: S/driver_cast_at.gd (w22-shots driver, mode map, real battle, Exhaustion.on): cast 1 at (1,3) true; casts 2-6 false. `fits_at` true, energy fine (price 1 -> 2), `_acting` true, AP pool 4.0.
- Cause: Exhaustion (Scripts/Exhaustion.gd): the 2nd cast of one skill bites, +STEP 0.5 x pressure of its AP and cost. Startile AP 4 -> 6.5 (headless numbers at AP 12: need 3.0, 4.875, 6.75, 8.625, 10.5, then 12.375 > 12 = false at the 6th). Driver's leader has 4 AP, so the 2nd cast already costs more than the whole pool: `Unit.pay` fails inside `pay_for`, after `fits_at` and the price check pass. Driver's "pre need 4.0" printed `ap_for(&"skill")` (the pool), not `ap_cost()` (the rate-raised price), which hid it.
- Why tests never saw it: `Test.calm()` sets Exhaustion.on = false; only exhaustion_test / combat_test / deathlust_test turn it on. Rule already pinned in exhaustion_test, so no new test (lean tests).
- Driver fix: lay with Battle.lay_star (as done), or `u.exhaustion.uses.clear()` before each cast_at.
## Calls
- No Battle/Unit change: the refusal is the designed rule.
- Self-explaining failure: HUD._short() ("Not enough AP for X") could say "needs 6.5, has 4" (HUD.gd, left to w22-hud-polish's area; one line: `"Not enough AP for %s (%s, has %s)" % [s.name, Skill.num(u.ap_cost(s, u.funding(s))), Skill.num(u.ap_for(&"skill"))]`). Not done: sibling owns HUD.gd.
## Tests
None added/changed (temp repro test deleted).
