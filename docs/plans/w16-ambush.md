# w16-ambush: Ambush as the first attack roll out of concealment (2026-11-23)
User (verbatim): "not sure what it means by tile marks? for now just make ambush advantage. rogue, slayer skill: Sally: + rank * 20% damage on 'ambush'. ambushes are the first attack rolls out of concealment. It usually only works on the first attack: subsequent strikes aren't boosted. Ambush Fussilade: 'Ambush' and triggered effects from 'Ambush' proc on rank subsequent attack rolls / skills."
User typed "Fussilade": skill named "Ambush Fusillade".

## Reading
- `Battle.ambushes(caster, target)` + `hit_tags()` ambush tag already exist (Gank, Wary's mitigate, Glossary). True whenever concealed/unseen/unplaced: no first-roll limit.
- One attack-roll site: `Battle.roll_attack()` (cast, _chain, Heavy Strike).
- Contingency system (`Requirement`, `--requires`): data payoff (hit/damage/edge) read by cast, forecasts, AI, pricing.
- Rogue has no Slayer tree (Ranger, Fighter have it).

## Plan
1. Stretch: `Unit.ambush_rolls` (attack rolls made as ambushes since its side's turn began; zeroed with `exposed`). `ambushes()`: 0 used -> concealment test (as before); n used -> n <= `fusillade` stat (Ambush Fusillade). `roll_attack()` counts it. `_chain` drops the tag (and re-reads the contingency) once used up.
2. Requirement test `ambush` (data; skill.py REQUIRES): any skill can pay off on an ambush. Ambush skill -> attack, `test=ambush edge=1`.
3. Sally: passive, Effect damage 0.2 per_rank tags [ambush]. Ambush Fusillade: passive, new Effect stat `fusillade` 1 per_rank.
4. Remove Mark.halts/skill, Behaviour.tripped/waylays, AI._waylay, Behaviours/ambush.gd, old tests.
5. Tests in Tests/ambush_test.gd; busy_fight 15; suite.

## Calls
