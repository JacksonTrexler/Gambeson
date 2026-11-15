# Price folds refunds (y-price, 2026-11-15)

## Readings and calls
1. **One hook, `Behaviour.rebate(c) -> Vector2`**: x = share of the price off before the roll (sure), y = share back on a hit. `refunds(c, p)` (the AI's read) is now derived: x + y * p. Poach and Slam Jam override `rebate` only; no per-skill branch in Battle, HUD or AI.
2. **Where the sure share is taken**: `Battle.rebate()` sums the behaviours; `Battle._cast` passes x to `Unit.pay_for(s, cut)`, and `ap_cost` / `cost_from` take an optional `cut`. The HUD's `drain()` asks the same `Battle.rebate()` for the hovered target, so forecast and payment cannot drift. Poach no longer refunds in `aim()`.
3. **Roll-dependent y stays a refund** (`Unit.refund()` from apply()); `drain()` adds `on_hit: {ap, key}` and the card row shows "on hit: −N" beside the drain segment (UnitCard `_row`, a 6th row element). Slam Jam's energy share floors as the refund does.
4. `Unit.paid_cut` remembers the cut so a later refund is a share of what was actually paid.
5. **Not done (call)**: `can_afford` and the AI's affordability still use the full price, so a unit with exactly half of Poach's AP cannot start it; the price shown at hover is the discounted one. Only `_cast` (single target) takes the cut; `pay_for` on auto/spread/tile paths pays full (no target to ask).
6. Pricing.gd untouched: the cost calculator prices a skill by its terms (already tapering Poach's contingency); the per-cast discount is a target fact, so it sits beside it, not in it.

## Tests
`poach_test.test_price_beforehand` (one seam: rebate -> forecast -> payment, Slam Jam on hit). Existing ai_tactics/slayer/slam_jam/poach tests pass unchanged. Mutations: `_cast` paying full (3 fail), HUD ignoring the cut (1), Slam Jam refund removed (slam_jam test fails).
