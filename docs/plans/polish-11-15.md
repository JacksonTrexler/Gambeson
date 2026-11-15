# Polish (branch x-polish, 2026-11-15)

Four open follow-ups. Starting suite: 8070 checks, 0 failed (838 tests). Final: 8152 checks, 0 failed (844 tests).

## Readings

- `Behaviour.describe_as(c)` existed (route.md) and 16 behaviours already overrode it (not "none"); 22 more declare scaling terms (`terms()`) and still described at base rank.
- `Skill.decays` / `Battle.decay()` / `Applied.scale` were already built for Rejuvinate's own effects ("Effect strength set when cast", docs/todo/systems.md, ?12 recorded as "the decay is fixed when cast", kept). What wasn't generic: effects a *behaviour* puts on (`Cast.put()`) and an aura's.
- Rolls against an earlier total: `inspect()` (tile and the scramble), `investigate()`, `_borrowed()`'s fall, `_level_down()`. Burnout, Stun, Bandwagon, trap/dodge saves roll against a DC; left on `resolve()`.

## Calls

1. **describe_as.** The 22 behaviours with rank or stat terms now write their text once in `describe_as(c)` (`describe(rank)` = `describe_as(Cast.at(rank))`). Each number reads the channel apply() reads: bandwagon, bludgeon, efficiency, energize, heal, humble, illusionist, interject, move, poach, resuscitate, snapping turtle, spike, word to the wise: impact; clairvoyance (wisdom x k + range rank), peel (reach), sutemi, telepathy (reach + impact), molothrus (range + impact): range. Numbers apply() reads raw (Kick's effect turns, Hitch's tow, Peel's step count, Slam Jam's refund share) stay at the base rank on purpose. New helpers `Cast.at(r)` and `Cast.mod_text(stat, channel)`. Humble now says "{r:N} x 4" rather than "rank x 4". Zone (Darkstone) said nothing of its rank: now "N deep at its centre, one less a tile out" (found by the sweep).
2. **Facing cue.** `HUD.aspect` = `{unit, side}`, from `Unit.side_of()` of where the attacker would stand (the plan's `dest`, since a walk comes first), for a ready use of an attack (`attacks()` or a declared check) on a foe. Drawn as one word, `rear` or `flank`, over the foe in the tag's colour (Overlay.draw_top). Nothing from the front. Words are the existing `rear ??` / `flank ??` tag names without the marks (the Glossary entry carries them). No number: the rear edge is already in the odds.
   - Coordinator note: the facing chevron was too faint. Now 9 px out (past the sprite's arms), 3 px wide, alpha 0.8, dark rim 0.7 at 1 px.
3. **Earlier totals on the helper.** `Check.fixed(n)` is a side that spends no die (`is_fixed`); `Battle.check/odds/sides` take a number as `against` (b may be null), so `their_bonus`, `cut` and `ties` work and `odds()` weighs it (the exact sum has one face for it). Moved: `investigate()`, `inspect()` (both branches: the hider's roll rolls as a stat-less side with `their_bonus`; the scramble is a fixed total), `_borrowed()` (d20 + rank vs `last_stand`), `_level_down()` (`ties = false`: a roll must beat the bar). rng order is unchanged (a fixed side rolls nothing), no existing test moved. **Not done:** Level Down and investigating have no HUD/AI forecast: Level Down's bar is itself rolled per cast and declares no `SkillCheck`, so `hit_chance` has nothing to read. The helper now can answer them when a forecast is wanted. The DC rolls (Burnout, Stun, Bandwagon, dodges) could now use `check(.., against: dc)`; I left them.
4. **Decay generic.** `Cast.strength` (what `decays` leaves, set in `Battle.cast()` before paying: mana spent is no decay) is read by `Cast.put()` (every behaviour's effects) and by Aura (share x strength). The skill's own effects already read it. Call: the strength is computed against the original target; a reaction that swaps the target doesn't recompute it (as built before). Call: `decays` stays a number on effects only; instant HP and damage don't decay (the skill text says "strength" of effects).
5. **Frames:** `scratchpad/shot_x-polish/` (`crops.png`: front, rear, flank). The word sits a little right of the foe's centre; left as is.

## Tests

- `sweep_test.test_describes_as` (new, in the shared sweep): for every built skill's behaviours declaring a channel, a ρ↑/ρ↓/σ↓/σ↑ modifier changes `describe_as`. Mutation: Spike's number from `c.rank` fails it; Zone's missing rank failed it before the fix.
- `hud_test.test_forecast_side`: front, flank, rear, a walk to the front first, a non-attack. Mutation: ignoring `dest` fails it.
- `check_test.test_check_against_a_total`: fixed side's totals, one die, odds (ties, edge, their_bonus, cut) and the roll agree.
- `last_stand_test.test_level_down_ties_lose`; mutation (`ties = false` dropped) fails it.
- `bracing_test.test_investigate_close`: a near watcher at advantage, against the roll given. Mutation (edge dropped) fails it.
- `paladin_test.test_decay_reaches_behaviours`: Stun (behaviour put) and an aura. Mutation (`a.scale = strength` dropped) fails it.
- **Unproven by mutation:** `_borrowed()`'s `bonus = r`: its rank barely changes the outcome (the last stand is cut by the rank), so no cheap test tells it from zero.
- No existing test changed.
