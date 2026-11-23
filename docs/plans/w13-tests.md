# w13-tests: loosen concrete tests, consolidate 20/80

Goal (user 2026-11-23): "make sure tests aren't overly concrete / 20/80 and consolidate tests dont take things too far".
Start: full run 11017 checks, 1037 tests, 106 s (M3, `caffeinate`). Top times: hud_test.test_every_tab_draws_its_skills 6.8 s, combat_test.test_battles 6.7 s (invariants, kept).

## Calls
- Kept: rule arithmetic (defense/respec/xp curve/Pricing formulas), bug repros, AI relation tests (ai_tactics already inequality/relation based; its `answers_as_before` tests are equivalence of fast path vs long form, kept).
- Content pins -> relations to the data (loot table text, tower portal enemies/rewards, princess level/weapon names).
- Sampling loops sized to 3-sigma of the seeded binomial, not 1500 casts.

## Done
1. (batch 1) tower_test portal menu = Dungeon.enemy_lines()/rewards_at() instead of literal text; items_test loot.describe: every item named, shares sum to 100; astral princess: no level/name pins; last_stand level_down n 1500->600 tol .07; combat replay 4 fights->3; heavy_strike forecast n 500->250 tol .2. (~2 s)

## Mutation spot-checks
(see below)
