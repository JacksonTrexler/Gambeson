# w13-tests: loosen concrete tests, consolidate 20/80

Goal (user 2026-11-23): "make sure tests aren't overly concrete / 20/80 and consolidate tests dont take things too far".
Start: full run 11017 checks, 1037 tests, 106 s (M3, `caffeinate`). Top times: hud_test.test_every_tab_draws_its_skills 6.8 s, combat_test.test_battles 6.7 s (invariants, kept).

## Calls
- Kept: rule arithmetic (defense/respec/xp curve/Pricing formulas), bug repros, AI relation tests (ai_tactics already inequality/relation based; its `answers_as_before` tests are equivalence of fast path vs long form, kept).
- Content pins -> relations to the data (loot table text, tower portal enemies/rewards, princess level/weapon names).
- Sampling loops sized to 3-sigma of the seeded binomial, not 1500 casts.

## Done (commits e1bce87 .. HEAD)
1. Content pins -> relations to the data: tower portal menu (= Dungeon.enemy_lines()/rewards_at()), Loot.describe (every item named, shares sum to 100), astral princess (no level/weapon names), champions Icor/Alabaster stat blocks (high/low, not 18/8/12), hud tabbed screen (tab names, Rogue skill count -> structure), per-class tree tier numbers (hogel, last_stand, paladin, specialist, fighter, warlock, adventurer hazard, casters, actualization, capstones, heal, illusionist, megaheal, nature, energy_transfer, command, sol table, ~20 pins) -> order relations; quality RANK_COST table -> monotone; water depths -> order.
2. Consolidated: bio_test.test_timid_waits folded into stance_test.test_craven (same temper path); 3 describe-text tests (final_act, gallantry, snapping_turtle) removed (sweep test_describes covers describe; gallantry tier covered by paladin_test); aquatic "water costs 1" asserted once (aquatic_test), pike/seaborn/druid form keep the tag check only.
3. Seconds: hud_test.test_every_tab_draws_its_skills redraws via skills.show_tab (what a tab click does) instead of full h._refresh (6.8 -> 3.5 s, same 76 checks); last_stand level_down 1500 -> 600 casts; heavy_strike pool 500 -> 250; combat replay 4 -> 3 fights; doubt/whiff samples 400 -> 200-250.
4. Left alone on purpose: rule arithmetic (defense, xp curve, respec, Pricing, slam), AI relation tests in ai_tactics (inequalities already; `answers_as_before` are fast-path equivalence), exact AI "stays put" cells (compare to start cell), champions' skill lists (user spec), lent DEFENSE table (formula by weight class), sims_test (one 6-unit round, already lean). hex_iii kept at 60 seeds: 40 sees no natural 20.

## Numbers
Start 11017 checks, 1037 tests, 106 s (1:46). End 11012 checks, 1033 tests, 101 s (1:41), 0 failed.
Lead, not done (game code, not tests): per-test floor is 41 ms = museum add_child (Battle/Unit _ready); 1033 tests = ~43 s of the 100. A cheaper fresh museum is the one big cut left.

## Mutation spot-checks (break rule, see fail, revert)
- SkillGrid.skills() drops one -> every_tab fails per tab (8 drawn, 9 laid out). Also covers show_tab swap.
- AI._emboldened timid test off -> stance_test.test_craven (3 checks incl. the folded timid-by-bio) fail.
- Loot.describe shares halved -> items_test.test_loot fails.
- GamutsTower rewards join changed -> tower_test.test_portal_menu fails.
- Not mutated: tier relations, level_down tolerance (seeded, passes at 3-sigma).

## Undone
Tiny-test merges (137 tests with <=2 checks; ~40 ms each saved) not done: merging staged tests leaks state; "don't take too far".
