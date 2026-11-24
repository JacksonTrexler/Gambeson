# w22-negative: Negative Energy and `seal`

Goal (user, follow-up.md F1): any reserve may go into debt where allowed; debt is paid before gains count, at efficiency 1 - 0.5 x (debt/max); `seal` locks N of a pool until its source is destroyed (startiles, Starnest, summons).

## Readings and calls
- "Energy, Power, Mana" = Energy (Power is Energy of a powered unit: `powered`), and every `Reserve` (mana, stamina, focus...). One rule, no per-pool branches: a pool is `&"energy"` or a `Reserve`; `Unit.pool_id()` names it (`energy`, `mana`, `sweet_nothings`).
- Seam: the two setters (`energy` setter, `set_store`) both call `_level_to(pool, was, v)`. So EVERY gain (rest/regen, grants, kills, patrons, Energy Transfer, carry) hits the rule; no call site changed. Any set that raises a debt level is a gain; `set_exact()` sets without it (tests, resets).
- Floor: `-floor(raw max x allow)`, allow = clamp(share, 0..1) -> floor = -max at most. Where allowed: a `debt` Effect stat tagged with the pool (share of max; 1.0 = -max; as a status/passive/item), or a `seal` bearing tag `debt`. Default: floor 0 (nothing changed for existing content).
- Efficiency uses the debt at the START of a gain. Filling the debt costs D/eff of the gain; what is left past 0 comes whole (efficiency does not tax the part beyond debt). Fractions carry (`gain_carry`, per pool) so +1 at efficiency 0.5 twice = 1 point; floor, never round up.
- Spending into debt: NOT added to pay_for/covers(): you can't pay a skill with a pool at or below 0, and cost checks are untouched. Debt arises from seals (below) and effects that lower the pool via the setters (a `debt` effect lets `energy -= n` go negative). A later card that wants "pay into debt" sets the `debt` effect and spends through the setters.
- Drain/siphon read `max(level, 0)` so a debtor can't be "drained" upward.
- `seal` (user-given: --human): Effect stat, tags = [pool, optional `debt`], amount points (op add) or share of max (op mul), x rank with per_rank. `Unit.afflict(e, turns, rank, source)` routes it to `Unit.seal(pool, points, source, share, debt)`: NOT a timed status (so each seal stacks, one per tile); `turns` ignored. Returns a throwaway Applied.
- Seal semantics: usable max = raw max - locked; the locked points also leave what the pool holds (more than it holds: the rest is lost, or debt if the seal bears `debt`; Starnest at 100% of Power on an empty pool = debt). Lifting does NOT refill the pool: points come back by regen. `Unit.locked(pool)`, `usable_max(pool)`, `sealed()` was taken (slot seals) so `locked`.
- Source link (generic): `Unit.holds(source)`: a Callable (true while held: a tile check `func(): return battle.terrain_at(c) == tile`), an Object (freed = gone; a Unit also needs `is_alive()`: a summon dying lifts it), or null (until the battle ends). Pruned in `tick()` / `prune_seals()`, and `locked()` ignores gone ones at once. Cleared at battle start.
- Max percent vs absolute: both (points vs op mul share of RAW max, rounded up).
- Regen/rest/Full-checks use `usable_max` (a sealed unit is "full" at its usable max; rest stops there).
- HUD: Unit map bars: a pool in debt shows an empty bar on a red back (`_debt_back`). Bar max stays the raw max (the locked part is just empty). The HUD info row shows the negative number ("EN -3/10") unchanged; no locked marker (undone).
- No new Skill.gd field; two Effect stats via mechanic.py (`seal`, `debt`), titles "Seal", "Debt", both described in `Effect.value()`.

## As built
- Scripts/Unit.gd (Seal class, `_level_to`, `seal`, `holds`, `debt_floor`, `set_exact`, bars), Scripts/Effect.gd (stats, titles, describe), Tests/resources_test.gd (`test_debt_all_pools`: table over Energy, Mana, Stamina; `test_seal`).
- Mutation spot-checks (resources test fails): efficiency 0.5 -> 0.25 (4 fail); floor -> 0 (18); `holds` always true (4); gain rule off (10).
- Undone: no skill uses it yet (Starnest, startiles belong to w22-signal / later cards); startile tile-source Callable is a pattern, not wired; locked-portion bar marker; paying a skill cost into debt.
