# Param tail: what the card still held (z-param, 2026-11-15)

Card: "Param: the deferred skills" (docs/queue.md). Checked against the code first.

## Already built (nothing done)
- The 6 deferred skills (Beastshape, Burning Bag, Elemental Strike, Emergency Exit, Waltz of Vapors, Relay): r-route, "r-param leftovers" in docs/plans/route.md; `route_test.test_deferred_six`.
- The UNSAID markup: `Tests/skills_test.gd` UNSAID is `[]`.
- `describe_as` (?148).

## Readings and calls (for review)
1. **`skill.py modifiers` count: 28 before, 28 after.** Strike and Elemental Strike were already eligible (Strike: hits_per_rank, tier stat; Elemental Strike: `elements`), Rift (radius_per_rank), Alluring (effects) too, so the count cannot fall; what changes is *which* modifier acts. Rift gains rho_up, Strike's chain reads a stat-impact `element` term, Alluring's rank-impact list gains `practised look`. The 28 left are the concrete/build-gate ones of docs/plans/param.md.
2. **Strike and the elemental reads.** The first hit's element bonus (imbued, or Elemental Mastery: the highest mental mod) now goes through the Strike's own modifiers as stat impact (`m.stat(mental, &"stat_impact")` in `_chain`), and SkillTerms declares `element` (stat_impact) for any `chain` skill. Call: the bonus is Strike's, not Elemental Strike's, since Elemental Strike only sets `imbued`/`element` and does not make the hit. So Elemental Strike stays rho-only (its uses); I did not add a `sigma` read to its behaviour, which would need a stored mental bonus on the unit (a bespoke counter). Strike passives' per-hit extras (steady, featured, brutal) are Effect stats, left as route.md said.
3. **Rift** difficulty and turns (`open_rift`, `close_rift`, the description's turns) read rank through the caster's modifiers as rank_impact; SkillTerms declares `domain`. Call: the "over walls from rank III" gate and the reach stay on the real rank and rank_range (a gate, not an amount); the difficulty clamp (1.5) still caps what a modifier can buy.
4. **Look's dissonance rank** (`Unit.dissonance_penalty()`: the rank of a practised look) and its text ("counts N less") read rank_impact; SkillTerms declares `practised look`.
5. **`Behaviour.missed(c: Cast)`**, one generic hook, the counterpart of `apply()`. `Battle._miss(c)` runs it (and sets `c.hit` false) before `used` on every cast path that fails: a drag, engulf or skill contest lost, a save passed, an attack roll missed (also the roll that hit a reaction's first target and misses its new one), a Strike chain with no hit, Level Down with no level taken, Death that didn't kill; and, in `area_blow`, a victim that dodged (`share == 0`, a Cast of the victim's own). Not run on a cast refused or stopped before it is tried (the posing whiff, a channel stopped by recast, a paid-for skill that is `whole()`), nor on tile skills with no victim. The `_land` call is untouched. No skill uses it yet; the hook exists so a refund or rider can (call: no content invented).

## As built
- Scripts: Battle.gd (`_miss`, miss call sites, `open_rift`/`close_rift`, `_chain`'s mental), Behaviour.gd (`missed`), Unit.gd (`dissonance_penalty`), Skill.gd (Look and Rift lines read `ri`), SkillTerms.gd (`domain`, `practised look`, `element`).
- Tests (extends Tests/route_test.gd; 3 tests, no new file): `test_missed` (lost/won save, Strike chain), `test_rift_look` (Rift turns and description under Density; a look's penalty and text), `test_strike_element` (element bonus under Concentrated). Existing tests unchanged.
- Mutation spot-checks (each failed its test, then reverted): drop `_miss` on the contest path; drop it on the chain; Rift reads raw rank; the look reads raw rank; the element bonus skips `m.stat`; `_land` also calls `missed`.
