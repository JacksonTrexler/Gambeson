# AI walks: wear for heals and supports, shove positioning, one price (q2-aiwalks, 2026-11-16)

Branch `q2-aiwalks`. Cards "Exhaustion wear for heals and supports" and "AI positioning for forced moves, and the other walks on route()'s price" (docs/queue.md). Baseline 8592 checks, 0 failed (916 tests). No names made up, so no ` ??`.

## Calls (each open for review)

1. **Wear for heals and supports.** `AI._wear` is HP (AP and cost points), taken off a blow's HP worth. A heal's worth is a share of an ally's HP and a support has no worth to take it off, so these weigh by a share: `AI._fresh(u, s) = max(1/rate, 1 - WORN)`, 1 fresh, down to 0.2. `_heal` multiplies a heal's want by it (a lone worn heal is still cast: it only orders skills); `_support` tries its skills least worn first (its own order on a tie). *Call:* a share, not `_wear()`'s subtraction, because the two aren't in the same unit; WORN's floor is reused, not a new constant.
