# Fixes: end_turn double pass, helpless units, God constants, Waterstrike's tag, the wiring test

Branch `n-fix`. Baseline suite: 42616 checks, 0 failed (648 tests). Final: 42645 checks, 0 failed (657 tests).

## Readings and calls

1. **end_turn double pass.** `_on_died` passed the turn when a side's last unit fell on its own turn, and
   `end_turn` then advanced from the new turn: with three or more sides one was skipped (and the units of the
   next side were refreshed mid-teardown, `turn_changed` fired twice).
   - Call: `end_turn` sets `Battle.ending_turn`; `_on_died` doesn't pass the turn while it's set, and `end_turn`
     passes it once at the end, to the first side after the one that was ending (in the order as it was) that is
     still standing. A side dying outside `end_turn` (a skill, on its own turn) still passes the turn at once, as before.
   - The rest of `end_turn` (zones, flames, `Downed.end_round`, `_check_stall`) keeps reading `turn` as the ending
     side, which is what it meant all along.
   - Test first (failed: Demons, `turn_changed` twice), `turn_test`.
2. **Helpless units.** The rule (2026-11-12): tapped can't act or take orders; helpless taps unless a permit lets it act.
   - Calls:
     - *A leader that is `stopped()` (helpless, no permit left) gives no orders and gathers no one* (`Command.could_order`,
       `can_join`). Mindless Fury is a permit, so a berserker under it can still lead, in a reduced capacity (its
       mental mods are already cut by `Unit.mod()`).
     - *One generic query, `Unit.reacts()`* (not jammed, not stopped): Jam already named "reactions" (dodge, guard,
       obstruct), so a helpless unit loses the same three rather than a second list. Dodging (`Battle.evade`), guarding
       (`Unit.guarding`) and obstructing (`Battle.obstruction`) read it. Obstruct was not asked for; it is a reaction
       by Jam's own definition, so it follows (a sleeping or Stunned Vanguard no longer holds a zone).
     - *The guard is suspended, not ended*: `Unit.guard` stays, so a Stunned shield-bearer's stance returns when the
       Stun is healed or cleansed (tapped lifts the moment its cause does). Jam, an interrupt, still ends it.
     - *A helpless unit still watches* (`_watch`): seeing isn't acting, a Stunned or Downed unit still notices things as
       its turn ends. Only sleep skipped it already. Not changed.
     - A permit keeps reactions until spent (`stopped()`, not `helpless()`).
   - Glossary "Helpless" says it (one line).
3. **God constants.** `Unit.GODS` (domains) and `Unit.GOD_TAGS` moved onto `God` (`domains`, `tag` exports in `Gods/<id>.tres`),
   readers through `God.pantheon()`, `God.tag_of(id, fallback)` and `God.of(id).domains`. Patrons have neither. `role.py god` takes
   `--domains` and `--tag`; `role.py check` fails a pantheon god without them. No behaviour change.
4. **Waterstrike's tag.** Only reader of the word `bludgeon` was `skill.py`'s FLAVOUR exemption (a note said "likely
   meant blunt"). Data fixed to `blunt`, FLAVOUR entry removed. A visible consequence: Waterstrike is a blunt blow, so it
   breaks a starpane and brittle terrain it's aimed at (`stars_test.test_waterstrike_shatters`). Unrelated to the
   sibling's Bludgeon skill.
5. **Wiring test.** `Test.tool_check(tool)` tries `python3`, `python`, then `/usr/bin`, `/opt/homebrew/bin`, `/usr/local/bin`; with none,
   it is a **failed check** naming the problem, not a skip. Util doesn't search for python (it assumes it's running),
   so there was nothing to copy. `skills_test.test_wiring` and `tooling_test.test_checks` both use it.

## As built

- `Battle.ending_turn`, `end_turn()`/`_on_died()`; `Tests/turn_test.gd` (three sides, off-turn death, two sides).
- `Unit.reacts()`; `Command.could_order/can_join`; `Tests/helpless_test.gd` (leader, permit, reactions, sleep/Jam, still sees).
- `God.domains/tag/pantheon()/tag_of()`; Gods/*.tres; `Util/role.py`.
- Tests changed to the new rule: `watch_test`, `gods_test`, `god_slots_test` (read `God` instead of `Unit.GODS`); none weakened.
- Also touched: `Util/skill.py` (FLAVOUR), `Scripts/Glossary.gd` (helpless line), `Scripts/Effect.gd` (a comment).

## Not done

- Whether `Unit.guard` should end (not just pause) on going helpless.
- Other reactions (opportunity-style) don't exist yet; they should read `reacts()` when they do.
