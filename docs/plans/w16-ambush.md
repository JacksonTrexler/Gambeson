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
1. Stretch = since its side's turn began (Unit.ambush_rolls zeroed with `exposed`, which is when lost concealment returns). Still hidden next turn: a fresh ambush. Re-hiding mid-turn does not reset it.
2. A miss spends the ambush (roll_attack counts any roll that ambushed).
3. Counted per attack roll (Battle.roll_attack): checks/saves and area blows with no attack roll don't spend it (they keep the tag while concealed). Auto multi-target: each target is a roll, so only the first.
4. Fusillade's extra `rank` rolls ambush seen or not, same turn window.
5. Ambush skill: kept on Ranger (after Snare); now a melee dex blow 1d10/rank + weapon tag, contingency test=ambush edge=1 (new generic Requirement test: any skill can be authored to pay off on an ambush), priced "flat rank" = 3 AP 2 cost every rank. Lost the `defensive` tag (AI._defend no longer casts it).
6. Sally: Slayer tree after Gank + Rogue's own Blade root after Backstab (Rogue has no Slayer tree). Ambush Fusillade: Slayer after Sally, prereq Sally.
7. Forecast: Battle.damage_range (HUD + AI) now multiplies by u's `damage` stat on the blow's hit_tags when given t and b (was ignored before: every damage effect now shows in forecasts, not only Sally).
8. Glossary ambush text rewritten to the user's rule.

## As built
- 6d95ebc: Unit.ambush_rolls; Battle.ambushes() first-roll + fusillade; roll_attack counts; _chain strips tag + re-reads contingency; Requirement test ambush (+ skill.py REQUIRES); Effect stat fusillade (mechanic.py); Sally, Ambush Fusillade (skill.py --human); Skills/ambush.tres rewritten; removed Behaviours/ambush.gd, Mark.halts/skill, walk halt, _trigger tripped, Behaviour.waylays/tripped, AI._waylay.
- damage_range applies the damage stat; Tests/ambush_test.gd rewritten: first_roll_only (advantage, Sally 60% at III, AI score drop, turn reset), chain, fusillade, who.
- Mutations: ambushes always true -> 4 fail; no roll count -> 5 fail; chain strip off -> test_chain fails; damage_range more=0 -> AI price check fails.
- busy_fight 15: OUTCOME ok; unit turn mean 19.4 / p95 45.6 ms vs main 20.4 / 45.4 (flat).
- Suite 11041 checks, 0 failed (1040 tests). Launch: only the known "resources still in use".
