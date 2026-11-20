# w5-ai1: the AI weighs `cc` and `shove`; casts Chaser's interrupt and Heavy Strike's pool well (2026-11-19)

Cards: "The AI weighs `cc` and `shove`" (?192) and "The AI casts Chaser's interrupt and Heavy Strike's pool well" (?193, ?202), both in
`Scripts/AI.gd`. Read `w3-facing.md`, `w4-friction.md`, `ai-findings.md`, `r-sims.md`. No names made up, so no ` ??` (a tag, stat or skill: none new; the
constants `CC`, `BLOW`, `ATTACK_STATS`, `HELD`, `JAMMED_TURN` are numbers and lists).

## Readings
- **shove was already priced** (forced-forecast, ai-walks): `Battle.foresee()` reads a skill's behaviours and its shove/fear/entrance effect stats, so a drive's
  tiles are riders, a slam is `lo/hi`, a slam into an ally is negative `spill`; `_line_up` walks to the tile that tells most and `_shoved` keeps from foes' shoves.
  Nothing keyed on skill names. `ai_tactics_test.test_forced_moves_are_priced`, `test_kick_spill_and_drive`, `test_lines_up_a_shove` pin it; the `kick` sim is unchanged. So the
  shove half of the card is a check, no change.
- **cc was a flat rider**: Stun, Hitch and Slam Jam reported their odds as `riders` (1 HP-equivalent each, whoever the foe), Jam a flat rider, and a hostile skill with effects got
  a flat +1. Stunning a hard hitter was worth the same as stunning a weak foe, and a foe already stunned was worth stunning again.
- **Chaser's chase**: the AI picks through `Unit.actives`, which `Unit.allowed` already limits to the rank reach; that held. What it did not read: at the pick, `Unit.friction` is 0
  (`_end_use` cleared it; `_begin_use` sets it as the chase's use opens), so the forecast (the HUD's too) showed the chase's first roll without its friction, and nothing counted that a
  Strike's later rolls are at more.
- **Heavy Strike's pool**: `score()` read a Strike III as p x every hit's damage; a pooled use lands one blow only when its last roll does.

## Calls
1. **`afflicts`**, a new key of `Behaviour.foresee()` (summed in `Battle.foresee()`, capped at 1): the share of the target's next turn a cc takes, as likely as it lands. Stun p x 1
   (helpless), Hitch p x `HELD` 0.5 (a grip), Jam 0.25 and Slam Jam p x 0.25 (`JAMMED_TURN`: lost reactions). The four report `riders = 0` now. The shares are guesses of mine, constants in
   the behaviours. Alternative: one table by status stat in AI.gd (rejected: a behaviour knows what it applies).
2. **The price** (`AI._afflicting()`): share x `_threat()` / (1 + the cc it already bears). A skill carrying the `cc` tag whose behaviours foresee nothing (Brainfog, Interdict, Drown,
   Coalescing, Bludgeon, Sing) is worth `CC` 0.5 of the turn (a guess). A cc-tagged skill no longer gets the flat +1 for hostile effects (the price replaces it). Not hostile: none.
3. **"Already bears"** reads what the AI has read of the foe: `Unit.bearing(r.effects, cc)` (a static `Unit.afflicted()` now delegates to; statuses show at recon 3), plus the visible fact
   `t.stopped()` (none at all from a helpless foe). Not `t.afflicted()` on the true unit: that would read effects it can't make out. The card says `Unit.afflicted()`; this is that, over a Read.
4. **A foe's turn** (`_threat()`): the best hostile attack of `r.skills` (damage_range of the foe against u x its hit chance), else from its stats if shown (`BLOW` 5 + the best attack-stat
   modifier of `ATTACK_STATS`), else `BLOW`; never more than u's HP. At recon 0 (most units) every foe is a `BLOW`, so the price is flat there: it only tells foes apart once stats or skills are read.
5. **Friction forecast**: `Battle.friction_ahead(u, ahead)` (the chain's count in a use or an interrupt granted to carry a chain on, else `Unit.friction`), read by `attack_odds()` (new `ahead`,
   `plus` params) through `attack_check(.., friction)`. The HUD's odds get it for free: a chase's first roll now shows its friction.
6. **Pool forecast**: `Behaviour.Forecast` (a use's rolls, per-roll damage, the odds of roll i with friction, the chance of k landing: a chain stops at its first miss) and a new passive hook
   `Behaviour.forecasting(b, holder, rank, f)`; Heavy Strike sets `f.worth` = the pool + a success each + rank behind its last roll (its own odds, crit double, glance half). `AI._use_ratio()` is
   modelled worth / the same with the first roll's odds flat, and multiplies `dmg` in `score()`: 1 for a plain use (no friction, no pooler), so every other price is unchanged (sims identical, below).
   No per-skill case in AI.gd. Not modelled: a Strike's row penalty, crits on the first roll (as before), Strike!'s restrikes.
7. **Picks within reach**: nothing to change (the AI reads `actives`); pinned by a test with a far stronger blow outside the reach.
8. **Not built**: a defensive read of cc (backing off from a foe's Stun, as `_shoved` does for shoves). The card's wording could mean that; I read it as pricing the cc the AI casts.

## As built
`Scripts/AI.gd` (`CC`, `BLOW`, `ATTACK_STATS`; `score()`, `_afflicting()`, `_threat()`, `_use_ratio()`), `Scripts/Battle.gd` (`friction_ahead()`, `attack_odds()` `ahead`/`plus`, `attack_check()`
`friction`, `foresee()` `afflicts`), `Scripts/Behaviour.gd` (`Forecast`, `forecasting()`, `afflicts` in the `foresee()` doc), `Scripts/Unit.gd` (`bearing()`), `Behaviours/stun.gd`, `hitch.gd`,
`jam.gd`, `slam_jam.gd` (`afflicts`), `Behaviours/heavy_strike.gd` (`forecasting()`), `Tests/sims/ai_sim.gd` (`cc` at recon 0, 1, 3).

## Sim (Tests/sims/ai_sim.gd cc, 8 seeds; v(1) Strike + Stun vs a hard hitter and a weak foe, the hard hitter listed second)
| | before | after |
|---|---|---|
| recon 0 (nothing read) | first stun on the hard hitter 0.00; stuns hard/weak 2.25/2.00; Lancin HP 0.0, won 0 | 0.00; 2.62/1.62; HP 2.5, won 1 (a flat BLOW: a tie goes to the first listed) |
| recon 1 (stats) | 0.00; 2.75/2.00; HP 0.0, won 0 | 1.00; 3.62/1.38; HP 11.6, won 5 |
| recon 3 (skills) | 0.00; 2.75/2.00; HP 0.0, won 0 | 1.00; 4.25/0.50; HP 10.0, won 5 |
Idle turns 0.00 in every row (no unit went passive). Every other scenario (hunt, clash, ambush, kick, grudge, rider, armor, worn, hide) is identical before and after, and
`busy_fight 15 n=1 rounds=4` has the same digest, unit turn mean 57.0 -> 57.8 ms.

## Tests
New: `ai_tactics_test.test_prices_a_cc`, `chaser_test.test_ai_picks_the_best_in_reach`, `chaser_test.test_forecast_counts_friction`, `heavy_strike_test.test_forecast_pool` (a Monte Carlo of the
real casts against the forecast). Changed to the new rule: `check_test` (the stun/hitch/slam_jam forecast: `afflicts`, `riders == 0`), `ai_tactics_test.test_prices_the_rest` (Slam Jam's Jammed is an `afflicts`, not a rider).
Mutations (each failed, reverted): no discount for a cc already borne; a stopped foe still priced; no `CC` fallback; `_use_ratio` always 1; `friction_ahead` ignoring the interrupt's chain; Heavy Strike's hook off;
`Unit.allowed` unset in an interrupt.
