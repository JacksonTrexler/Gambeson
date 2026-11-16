# AI prices what it ignores (z-aiprice, 2026-11-15)

Branch `z-aiprice`. Work in progress: readings first, then "as built".

## Readings
- `AI.score` takes the chance to hit from `Battle.hit_chance` with the target's true Defense; the HUD shows it only when
  `_defense_shows` (net >= 0). `Read` has no Defense.
- `Behaviour.rebate(c)` / `refunds(c, p)` carry a share of the AP price only; Energy / Focus costs, Poach's regain on a
  neutralizing blow (`felled`) and Slam Jam's interrupt are unpriced. Kick's foresee ignores the trap's blast and the push distance.
- `_starve` covers only the last-foe case; Final Act's `foils` only lowers the kill's pull.
