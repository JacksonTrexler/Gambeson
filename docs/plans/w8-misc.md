# w8-misc: five follow-ups (builder notes)

## 1. Preparation tests the plan left out
`Tests/prep_test.gd` `test_doubt_sides`: a trickster's 30-point `inquire` check bonus does not reach its side of `doubt()` (`their_tags = []`);
an Inquisition use via `prepare()` wins about 264/400 against 210/400 for a plain doubt (leader far from the siren, so no "close" edge).
Mutations: dropping `their_tags = []` fails it; `prepare` passing edge 0 fails it (gap 8 vs 54). Margin chosen: +30. No rules change.

## 2. Units carrying a pack
Two new units, via `unit.py new` (Fighter role, faction nemes, `--color` sprite, names " ??"): **Scrapper ??** (level 3, brave, Scrap Plating 3, pack Brigandine + Habergeon)
and **Bulwarker ??** (level 5, stoic, Power Armor 2, pack Half Plate + Plate). Calls:
- No new items and no loot: the existing armors (Items/) are the pack, so `item.py` had nothing to add. Dropping a defeated unit's pack as loot is not built (a new rule).
- `unit.py --set` cannot write an item array (needs ext resources), so the `pack =` line and its ext_resources were added to the two .tscn by hand after the tool ran (`unit.py check` ok).
- Their stats are the villager's (12s; Bulwarker str/con 14): at the default 5s the unit has 4 AP and armor costs 10 - dex mod, so it could never afford to dress.
  This also says armor-in-battle is dear: a unit with no dex will never dress (a design note, not changed).
- They are placed in no battle scene (every test starts from the museum). Checked in battle by `plating_test.test_packs`: each, summoned out of reach, dresses its slot through `AI.act`.

## 3. Sim: Skeleton with the foe in walking reach
`Tests/sims/ai_sim.gd`: `_host` now calls `_hosts(n, foe_x, name)`; new scenario `hostnear` (soaker 5 tiles off, caster at 4,3, 10 rounds). Names: none made up.
`Tests/sims/sweep.sh BODY "0 5" hostnear` (BODY 0 = the AI before `_summon()`), damage to a 900 HP soaker that never hits back:
| | bodies | damage (n=8) | damage (n=24) |
|---|---|---|---|
| BODY 0 (never raises) | 0 | 30.50 | 30.83 |
| BODY 5 (today) | 6.0 | 30.25 | 32.83 |
| SUMMON_CAP 4 (n=8) | 2.0 | 41.62 | |
| SUMMON_CAP 12 (n=8, today) | 6.0 | 30.25 | |
Reading: with the foe in reach, raising a host is about neutral on damage over 10 rounds (the caster's AP goes to casts rather than its own Strikes, and Skeletons strike weakly); a small
cap (fewer casts) does clearly better here (+35%). The soaker never fights back, so what bodies are worth as targets and blockers is not measured. Call: left BODY, SUMMON_SEEN and SUMMON_CAP
as they are (the value of a body is a design call; if damage is what matters, a cap near 4 is the number to look at). Question for the user.
