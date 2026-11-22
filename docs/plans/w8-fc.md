# w8-fc: First Chair forecast, Cadence shown, rounding styles on heals and the log

Queue cards "Forecast First Chair and show Cadence" and "Rounding style on the other heals and the log" (docs/queue.md, from
?220 and ?224). Starting suite: 10652 checks, 0 failed (1004 tests), the w8-icons tip.

## Readings and calls

1. **One seam for the forecast: `Battle.damage_range()`.** The HUD's span (`_hurt`), the AI's score and its other reads
   (`Final Act`, `Poach`, a foe's threat) all go through it, so First Chair is added there, not in each. `Battle.impact_ahead(caster, skill)` is
   the impact a use would carry were it opened now: the use under way's own (`use_of`), else the same `opening()` hook `_begin_use()`
   asks (`_open()`, now shared), on a `Volley` nothing keeps. No per-skill case in Battle, AI or HUD: any passive that adds impact at
   `opening()` is forecast. Added to the `bonus` of every blow, so `lo`/`hi`/`avg` rise by impact x hits. Not a `Behaviour.Forecast`
   (that is the AI's per-roll odds object; impact is a per-blow amount, and the HUD needs it too).
   Call: with no `Battle` passed (`damage_range(u, s)`) there are no passives to ask, as before. A foe's threat read on our turn is
   not "first" (`first_to_act` needs the caster's side's turn), so it adds nothing: right.
2. **No heal preview exists** (the HUD previews damage only), so First Chair's +impact on a heal is not forecast anywhere. Nothing to do.
3. **Cost.** `impact_ahead` runs on every damage read the AI makes. First cut (`members()` twice, `hooks()` arrays) cost 2-3%;
   it now reads `members()` once and walks `on_passives` directly.
4. **Cadence shown: two ways, both generic.** (a) The status chip on the unit card carries the stack as its corner numeral for any
   `per_rank` effect with rank above 1 and no roll of its own (Self-evaluation's roll keeps the corner; ranks of Charge, Winded,
   Soaked etc. now show too: call, one rule rather than a Cadence case). (b) Harmony signs each build through the existing passive
   plumbing (`Battle.passive(unit, Harmony, +1, &"cadence")`): "Harmony +1 cadence" floats over each unit it grew on, lights
   the slot on the viewed holder. Call: the sign is on every unit grown (up to a few a pass), not only the holder.
5. **Heals carry `rounded`.** `Unit.heal(h, heard, rounded)`: the `being_healed` dict is `{hp, rounded}`. Threaded from every
   path that luck rounds: a potion (`restore`), a skill's stat mods (`Skill.heal_raw()` split out of `healing()`, `_cast`), regen
   (`_mend`), Regeneration Pulse, all through `Battle.mend(..., rounded)`. Call: the **Heal** skill (d8s + stat mod) and Lovely
   Caster are not luck-rounded (`Modifiers.stat` is a plain `roundi`, a roll is a roll), so they stay plain, as does Resuscitate.
   The HUD keeps the heal dict (`_on_being_healed`, as it keeps blows) and styles the "+n" floater when the dict's final `hp` (after a
   cut by Molothrus or Recovery Endurance) is all of the change, else plain.
6. **The log.** Its two RichTextLabels (`Log`, `LogLine`) get italics and bold faces from `Overlay.face()` (the floaters' slanted and
   emboldened variations of the log's own font, built once, shared with the floaters). `HUD.amount_text()` wraps an amount in `[i]` or
   `[b]`. A use's log line sums the blows its target took that frame (`_taken`): styled only if they all rounded one way and
   their (post-cut) sum is the amount shown. Applied to a use's damage, a grip, a blast's per-unit amounts and a pulse's heals.
   Call: a mix of up and down in one line is plain (no net direction can be named).
7. **Previews: not styled.** A preview is a span over rolls, each end rounded its own way; no one rounding can be named. Held, as asked.

## Performance

`Tests/sims/busy_fight.gd -- 15 20 n=3`, headless, ms on the M3. Digests identical throughout (2121111823, 129203950).

| | base | task 1 (first cut) | task 1 (final) x2 | task 2 x2 |
|---|---|---|---|---|
| 15v15 unit turn mean | 69.0 | 70.4 | 69.6 / 69.7 | 69.3 / 69.2 |
| 15v15 side end_turn mean | 238.3 | 240.1 | 237.4 / 237.7 | 236.3 / 236.1 |
| 20v20 unit turn mean | 80.8 | 83.0 | 81.3 / 81.6 | 81.4 / 81.4 |
| 20v20 side end_turn mean | 467.0 | 472.5 | 463.5 / 465.1 | 462.8 / 463.8 |

Within run-to-run noise (about 1%). The HUD side only runs in a window and does a dict write per blow and per heal.

## As built

- `Scripts/Battle.gd`: `impact_ahead`, `_open`, `first_to_act(side)`, `damage_range` adds it; `mend`/`restore`/`_mend`/`_pulse`/`_cast`
  carry `rounded`. `Scripts/Unit.gd`: `heal(..., rounded)`. `Scripts/Skill.gd`: `heal_raw()`.
- `Behaviours/harmony.gd`: the sign. `Scripts/HUD.gd`: chip numeral, `_on_being_healed`, `_taken`, `amount_text`, log faces.
  `Scripts/Overlay.gd`: `face()` static.
- Tests: `Tests/harmony_test.gd` (`test_first_chair_forecast`, `test_cadence_shown`), `Tests/passive_signs_test.gd`
  (`test_rounded_heals_and_log`).
- Mutation spot-checks (each failed the test it should, then reverted): `impact_ahead` dropped from `damage_range`; the chip
  numeral dropped; `mend` not passing `rounded`; `restore` not passing it; `_healed_rounded` always 0; `_taken_rounded` not
  checking the sum.
- Screenshots: `S/shot_w8-fc/`.
- Suite: 10672 checks, 0 failed (1007 tests; +2 in harmony_test, +1 in passive_signs_test). Plain launch: no ERROR beyond
  "8 resources still in use at exit".
- Screenshots (`S/shot_w8-fc/`): 01 a heal's three numbers (+3 plain, +5 bold, +4 slanted) and the log (a bold "+5", the
  italic/bold amounts); 02 the "Ca ??" chip with its rank 2 in the corner and the "Harmony +1 cadence" sign.

Undone: no heal preview exists to forecast First Chair on; the Heal skill's and Lovely Caster's heals have no luck rounding to show;
previews unstyled (call 7).
