# w16-swarm (2026-11-23)
Goal (the user: "fodder and army units need to take their turns more simply and quickly ... contingent on a leader or ... log(n)"):
group plan shared by like units (once per side turn), cheap member step that sticks together; incrementally kept targeting
superlatives (lowest HP / physical / magical Defense); fodder turns leader-contingent or cheap. Measure busy_fight A/B vs origin/main eb55c72.
Files: Scripts/AI.gd, Scripts/Ranks.gd (new), Scripts/Battle.gd (one var), Tests/sims/busy_fight.gd (swarm mode), Tests/ai_tactics_test.gd.

## Readings
- AI.act order: `_calm` -> `_drill` (skilled leader's followers), `_far` -> `_prowl` (no foe in sight), else `_full`.
- `_full` for a plain unit reads all foes + allies within reach + 1; `_targeting` loops every read foe; `_approach` past move + 3 is unpriced.
- No rat/goblin units exist; busy_fight fields 12 classes round-robin (30 a side: 2-3 of each class a side).
- Defense: `Unit.defense(tags)`; physical = defense([physical]), magical = defense([magical]) (armor_mind counts for magical).

## Calls
- Like units (`AI._kind`): same side, same Role, same Race ([faction, role, race]). Tags/persona not compared (a "swarm" tag
  would gate it to authored content; any 3 alike already behave alike). HERD = 3 alike and alive on the side, else no herd.
- Leader-contingent first: `_calm` followers of a skilled leader still drill (unchanged). Order: calm -> herd -> far -> full.
  A herd beats `_far` (no foe in plain sight): the herd heads for the nearest shape / last sighting (no search, scry, heal, support).
- Plan (`_herd_plan`, cached in Battle meta `herds` keyed by turns_begun + side; one O(n) grouping pass a side turn, one plan
  per kind on first ask): members, centre (mean cell), foes its side can place (in_range >= 1), walk = rep's move_left + longest
  reach, key, target, goal. Target: per foe side, walk `Battle.ranks.lowest(key)` from the front to the first plainly seen
  (in_range 2) foe within walk + COHESION of the centre; lowest of those. Key: HP for strategy `weakest`, else magical Defense
  if most of its foe skills are tagged magical, else physical. None in range: nearest plainly seen to the centre, else nearest
  shape, else nearest last-seen cell (no target), else no plan.
- Info call: the index holds true HP/Defense; it is only consulted for foes the side plainly sees (in_range 2), where a Read at
  net >= 0 shows Defense anyway. HP of a plainly seen foe is taken as known (a guess the full turn would make from `healthy`).
- Member eligible (`_herded`): `_ordinary` (no behaviour/temper, faction, not Downed/channeling/Restless/posing/assumed/cc/held/
  holding; shared with `_far` now), not hurt since its last act (calm_hp), not struck last by its own side, no hunts, strategy
  only `weakest`, and no placed foe within walk + 1 of it. Else full turn (as the task says: a foe in reach = a fight).
- Member step (`_herd`): no reads, no route pricing: travel to the free tile beside the goal nearest it (`_beside`, lifted out of
  `_approach`'s far branch). COHESION 3.0: a member more than 3 tiles nearer the goal than the centre is waits ("waits for its
  herd"). Sets meta aim = target (followers of a herd member drill on it).
- Ranks (`Scripts/Ranks.gd`, `Battle.ranks`): per side, Arrays sorted ascending by (value, instance id) for hp / physical /
  magical (defense([physical]) / defense([magical])). HP kept on Unit.hp_changed (bsearch out, bsearch in; <= 0 leaves).
  Defenses + new units rebuilt once per side turn (lazy on first ask after turns_begun changes): a Defense change mid-turn is
  seen next side turn. Sorted array, not a heap: O(log n) find, memmove insert (n <= ~100), and in-order walks are free.

- busy_fight `swarm=M`: Lancin fields M fighters ("rats": RAT_HP 4, Strike only) in a 6-wide block vs N mixed Nemes. Measured
  60 v 15 (60 v 10 ended in 4 rounds: too few side turns for a p95).
- A herd member whose plan's target fell this turn takes its own turn (no walking on a corpse's cell).

## As built (4960fae + follow-up)
- AI: `_ordinary` (shared by `_far`), `_kind`, `_herd_plan`/`_plan`, `_herded`, `_herd`, `_beside`; act order calm -> herd -> far -> full.
- Scripts/Ranks.gd + `Battle.ranks`. busy_fight `swarm=M`.

## Measure (A/B x2 interleaved `S/ab16.sh`, base origin/main eb55c72 + this busy_fight, M3 x4; stare mean / p95 ms, unit turn mean)
| fight | before | after |
|---|---|---|
| 30 no party | 199-215 / 741-803; turn 104-109 | 147-154 / 293-298; turn 103-107 |
| 30 lead | 162-168 / 528-555; turn 90-92 | 135-136 / 292-305; turn 96 |
| 15 no party | 87-88 / 187-189; turn 79-80 | 87 / 182-186; turn 79 |
| 60 rats v 15 (n=3) | 159-161 / 310-311; turn 69-70 | 111-112 / 293; turn 56-57 |
OUTCOME ok every run. Winners: 30 no party Nemes both (10 -> 9 left); 30 lead flipped (0 v 9 -> 7.5 v 1: sides even, sane);
15 same; swarm rats win (52.3 -> 50 left). 15 a side: kinds of 1-2 a side, no herds (HERD 3): unchanged, as expected.
Swarm stare now mostly the 15 mixed Nemes' full turns reading 60 rats (not herds); the rats' own herd step ~2.5 ms (M3).

## Tests
- New `ai_tactics_test.test_herds` (20 checks): one plan shared, ranks pick (softer foe not nearer), < HERD no plan, exception
  table (hurt, cc, temper, strategy, hunts, foe in reach) each off/on, members herd, one ahead waits, aim set, hurt -> full turn.
- New `ai_tactics_test.test_ranks_match_a_scan` (9 checks): each list == brute-force sorted scan at start, after hits/heal/fall
  (no new turn), after a Defense change + next side turn; fallen leave the HP list.
- Mutations, all caught: hp not reinserted; order reversed; hurt check off; cohesion wait off; plan per unit (crash);
  ranks pick ignored; foe-in-reach check off.
- Changed: none (no pinned AI output broke). Suite 11057 -> 11086 checks, 0 failed (1045 -> 1047 tests). skill.py check ok;
  launch log: only "8 resources still in use".

## Not done / next
- Non-herd units facing a swarm still read every rat in a full turn (all-pairs on their side): Ranks could serve their
  `_targeting` too, or a "foes within walk + reach" spatial cut.
- Herd members in a fight take full turns (task's rule); a drill-shaped local turn for them (reads within walk + reach) is
  the next lever if melee swarms get slow. A straight walk through allies still stalls (w15 note).
- No visual check (no layout change).
