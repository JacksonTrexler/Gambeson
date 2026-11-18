# Exhaustion retune, Burnout, Deathlust radius (branch w3-exhaust)

The user's words: `docs/agents/answers-2026-11-18b.md` item 5 (Burnout and exhaustion paragraphs) and item 10 (?182). `Burnout` is the user's name (`--human`).

## Readings

- The thresholds read as one pressure on the skill about to be used, normalised so 1 bites (`Exhaustion.of()`): each prior use weighs `1 / SAME` against the skill itself, `1 / IN_KIND` against other skills of its broad kind, `1 / ANY` against every other skill. With `SAME 1`, `IN_KIND 2`, `ANY 3`: the 2nd use of one skill, the 3rd caster (any kind) skill in a row, the 4th different skill in a turn each reach 1. Mixed patterns add (a Strike then a Crushing Blow put 0.83 on Kick).
- Below 1 the rate rises `MILD` (0.1) a unit of pressure; from 1 on `STEP` (0.5) a unit, so repeating one skill costs what it did before (x1.5, x2 ...). The jump at 1 is deliberate: the "bad things start" point.
- "In a row" and "in a turn" are read as the uses not yet got over (counts still fall 1 a side-turn, more resting), not a streak reset by an off-kind skill or a turn boundary: no new counter.
- A cost's exhaustion part rounds to nearest (`Exhaustion.raise()`), the base still rounds up: a mild wear under half a point adds nothing, where ceil would have turned 2 x 1.03 into 3. Old bite-zone numbers hold (2 x 1.5 = 3, 5 x 1.5 = 7.5 -> 8).
- Burnout: an `int`-tagged skill (`Burnout.of()`; 26 skills, all magical but tagged by the int stat). Same pressure and thresholds; the wear (rate - 1) times `Burnout.PENALTY` 1.25; on a cost paid from a reserve that burns, times `Reserve.burns` again (new Reserve field, Mana 1.5): a 3rd caster spell in a row costs 1.94x Mana, 1.63x Energy. AP is not harsher on Mana (the user said costs). `Burnout.penalty(u, s)` is the single read (`Exhaustion.penalty`, set by Unit): Cram multiplies there.
- Deathlust: radius = rank (rank I: adjacent, diagonals too, by `Command.tiles`); relief a share of every skill's count, `1 - 0.75^rank` (25%, 44%, 58%, 68%), through `rank_impact`; `Exhaustion.relieve_share()` on top of `relieve()`. Hooks `neutralized` / `wearing` kept.

## Calls (for the coordinator to number)

1. Old Burnout.gd (?121, recovery wears max) doesn't fit the new Burnout (skill-use cost): renamed rather than folded. It takes the user's own term **Recovery Endurance** (no ??, no made-up name): `Scripts/RecoveryEndurance.gd`, `Tests/recovery_endurance_test.gd`; the old `burnout` Glossary text is folded into `recovery_endurance`; Energize and Poach now link that term. HUD chip "Burnt -3 HP" and `Unit.burnt`/`burn()` kept as is.
2. Thresholds per the user, constants `SAME 1`, `IN_KIND 2`, `ANY 3`, `MILD 0.1`, `STEP 0.5`; general skills (Strike) are no longer special: every skill weighs `1/3` on every other (was: only general ones, 0.25; a no-kind skill now wears on others).
3. Exhaustion's added cost rounds to nearest (above).
4. Burnout numbers: `PENALTY 1.25`, Mana `burns 1.5`; Burnout applies to every cost source of an int skill's cost but only Mana is harsher; Energy standing in for Mana is not.
5. A tooltip note says "burnout x1.5" for an int skill, "exhausted x1.5" otherwise. The slot pips show pressure (a whole pip bites).
6. Burnout is a rule term, not a tag/status/property/stat: `mechanic.py` has no verb for editing a rule's Glossary term, so `burnout` was rewritten in `Glossary.gd` by hand.
7. Deathlust's curve `1 - 0.75^rank`; radius exactly rank (the prompt's reading of "1 tile per rank + 1").

## Tests

- `exhaustion_test.test_counts` rewritten to the thresholds; new `test_burnout`; `test_costs`, `test_channel_is_one_use` (Metea is int: Burnout numbers) updated; `stamina_test.test_eases_exhaustion` (3.5 -> 3.1 AP: Stamina now keeps a repeat below the bite); `deathlust_test.test_deaths_in_range` to radius and curve; `burnout_test` renamed `recovery_endurance_test`, unchanged.
- Mutation spot-checks, each failed and reverted: ANY 4; IN_KIND 3; no mild zone; Burnout penalty 1; Mana burns ignored; Deathlust flat share; Deathlust reach 2.

## As built / not done

- Suite: started 9756 checks, 0 failed (936 tests); after: 9767 checks, 0 failed (937 tests), before merging adventurer-skills; after the merge 9807 checks, 0 failed (942 tests).
- Not done: no museum-sim retune check (AI reads `rate()` unchanged); Cram's multiplier is the later card's.
