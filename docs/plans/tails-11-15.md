# Guide rings and check tests (z-tails, 2026-11-15)

Card: docs/queue.md "Guide rings and check tests". Sources: hud-glow-guide.md ("Left"), checks-tail.md ("Unproven").

## Built
- `Scripts/Guide.gd`, the brackets paragraph: one sentence on the near-miss rings (dashed Luck.MARGIN ring past the reach ring; a unit's circle bright when the caster's luck rounds it in, faint when not).
- `Tests/check_test.gd`, in `test_dc_and_rider_forecasts` (one seam, no new file): Hitch's `apply()` rolled 2000 times at rank 4 holds as often as `Battle.odds(.., HITCH.FOE_STATS, HITCH.grapple(c))` (foe's dex above str so the better-of-two matters). Level Down: `hit_chance` equals `level_odds` at the rank impact; an ally gets 1.0.

## Calls
1. Rank 4 and stats 14 vs str 10 / dex 14 so each dropped option moves the chance by more than the 0.035 tolerance (rank 2 moved it only 0.043).
2. No separate Guide test: `ui_small_test.test_guide_key` covers the page's substitution; the line is prose.

## Mutation spot-checks (each failed, then reverted)
- Hitch `apply()` passing `{}` instead of `grapple(c)`: failed (0.573 vs 0.700).
- Hitch `apply()` rolling `&"strength"` instead of `FOE_STATS`: failed (0.747 vs 0.660).
- `hit_chance` Level Down branch with rank 1 instead of the rank impact: failed (0.475 vs 0.724).
- `hit_chance` Level Down branch removed: failed (1.000 vs 0.724).
