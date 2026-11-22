# Forecast: the will-consume drain, finished (branch `n-forecast`)

Five open items from `ui-v2.md` (will-consume, foresight), `hud-markers.md` (reserve bars) and `ai-support.md`
(`Behaviour.restores`). Baseline suite: 44752 checks, 0 failed (704 tests). Tests: `hud_test`
(forecast_fire_and_wounds, foresight_stat, help_order_reads_restores), `hud_markers_test.every_reserve`,
`foresight_test`. Frames: `scratchpad/shot_n-forecast/` (`crop_trap`, `crop_walk`, `crop_ap`, `crop_reserves`).

## Readings

- The map shows a unit's HP, Energy and reserve bars only; AP and movement are on the card (and saturation
  tiers). So `drain()` had a `move` and `ap` the map had nowhere to draw. The walk preview line already traces
  the path, but not what it costs.
- The trap estimate sat inline in `drain()`: known trap (`tile_view().trap`), dice average x times + bonus.
- `Skill.serves(&"supportive")` (Skill.gd, off limits: `m-core`) is what `Unit.intent_skill()` asks, and so
  what the HUD's HELP order and `intent_options()` read. It knows `heals()` (heal_mods, heal_bonus, restores),
  not behaviours, so Heal (a behaviour, no heal fields) never counted.

## Calls

1. **AP and movement on the map: pips, no bar, no text.** A strip of small pulsing pips right over the
   selected unit's bars (above the trim): a blue pip per point of AP (the card's AP colour), a grey one per
   point of movement (MV colour), the last one short for a fraction, a dark backing so they read on any
   ground, at most 8 each. AP is the lower row, movement above. Nothing draws without a plan, so there is no
   resting clutter. Chosen over a number ("-3") for "the less text the better", and over mini bars because
   the brief said add none. A cost it can't foresee shows as the muted "?" at the end of that row. (Pips are
   what will be spent, not what is left.)
2. **Foresight stat**, `Util/mechanic.py stat foresight --human` (the word was the user's, from the todo).
   Allowance = int mod + `unit.stat(&"foresight")` (`HUD.foresight_allowance()`); "below 0: plans as if safe"
   now reads the sum, so a bonus can lift a negative int mod to 0 and above. What a unit has *used* this turn
   stays in the HUD (`foresight_used`): it is knowledge of the player's side, not a Unit stat. No skill or
   item carries the stat yet.
3. **One estimate, `HUD.hazard(u, c)`**: a pool-by-pool dictionary for stepping onto c. A known trap: dice
   (times x average + bonus, as before) and its wounds' first tick: `bleed` (dice average + setter's mod, at
   least 1, else its amount) and `poison` (amount x max HP) on HP, `winded` on AP. Fire on the tile (`Battle.flames`):
   1d8's average + the setter's wis mod, at least 1. All before mitigation, as the estimate always was.
   `drain()` sums it along the path and uses the same pools for the "?" when foresight is spent. Calls:
   - Fire is treated as plainly visible to everyone: Read has no fire field and nothing hides a flame.
   - Only *trap* wounds, not `afflicts` of ordinary known ground, and only the first tick of a bleed (it
     lasts turns); "effects on other resources" found only `winded` (AP) beyond HP in the Effect stats.
   - A fire estimate spends a foresight like a trap's, because it is the same estimate.
   - Kept: the walk path itself is Battle's, so a route is not steered round fire or traps.
4. **Third and further reserves**: `Overlay._bar_for(unit, key)` maps HP, Energy, any held reserve (first,
   second, `more_bars[i-2]`); drain segments and "?" marks use it. The 1px sliver shows the segment as a lit
   line; the card row still carries the number.
5. **HELP reads restores**: `HUD.intent_skill(u, posture)` = `Unit.intent_skill()`, and for supportive any
   affordable hotbar skill with `AI.restoring()` (new, public: not passive, not hostile, `_restores()` not
   empty). Did not touch `Skill.serves()` or `Unit` (no Battle reference there; `restores()` needs a Cast).
   Call: "any restoring behaviour counts" includes Energize; so a HELP order to a unit whose only help is
   Energize isn't wasted, `AI.act(supportive)` now ends with `_replenish()` (it casts a restorer on itself
   when its pool is at half or less, else does nothing). Heal on an ally was already done by `_heal()`.
   `Skill.serves()` itself still says Heal is not supportive (Affinity postures read it); `m-core` may fold
   this in when it reworks Skill.

## As built

- `Scripts/HUD.gd` (`foresight_allowance`, `foresight`, `hazard`, `_owe`, `drain`, `intent_skill`),
  `Scripts/Overlay.gd` (`_bar_for`, `_pips`, `PIP`, `PIPS`), `Scripts/AI.gd` (`restoring`, `_replenish` in the
  HELP return), `Scripts/Effect.gd` (the `foresight` stat, doc comment), tests.
- No existing test changed.
