# AI stare 2 (w15-stare2, 2026-11-23)
Goal: no-party 30 a side side-turn stare p95 < 1000 ms (M3 x4); was mean 303-320 / p95 1876-1915. Tool `busy_fight 30`. Base origin/main d99a3c9. Read docs/plans/w14-stare.md first.

## Readings (PERF accumulators, 30 no-party, n=1)
- Slow turns: the whole column acts at once in round 2 (30 acts x 35-60 ms), many `moves []`: a unit walks a straight line through allies, `walk()` pops trailing tiles occupied by allies and nothing is left. ~35 ms each with no walk to cover them.
- Per `_full` act that walks (31 ms): reads 9, `_approach`+travel 10.5, `_stretch` 4.2, `_line_up` 2, switch 1, rally .8, steady .7, heal/support .7.
- end_turn is 21 ms here (84 on the target), 0 ms of stare (it runs under the walks): not a lever, dropped.

## As built
1. `_reads(b, u, near)`: allies beyond `near` tiles unread. `_full` for a plain unit (posture "", no behaviour, no temper, a faction) reads allies only within longest reach + 1 (as `_prowl`, now one call of it). `_waylay` took its allies' cells from `reads`: now from `b.units`.
2. `_approach`: a foe farther than move_left + `APPROACH_FAR` (3.0) -> the nearest free tile beside it, no route pricing (flanking, dread, struck, wary of the tiles it won't end on).
3. `_stretch`: asks for the self-only stride skills first (most units have none), before reading the blows.
4. `_line_up`: foes farther than ceil(move_left) + longest drive reach + `LINE_UP_MARGIN` (2) are dropped before the 8-tile loop.

## Calls (for the coordinator)
- Far-approach threshold move_left + 3 and the margin 2: judgement, no tuning. Decisions change slightly: far units pick the nearest side of a far foe rather than the cheapest/flanking tile; fights end a little different (30 a side: 51.0 -> 51.5 fallen, winner side unchanged in kind).
- Allies past reach + 1 are not read in a plain full turn: nothing in `_full` for temper "" and no behaviour uses an ally farther than a cast reaches (`_heal`, `_support` cast from where it stands; `_tend` is helpful-only, `_flee`/`_emboldened` timid-only). A timid, helpful, skittish ... unit still reads everyone.
- end_turn per-unit stat reads left alone (not in the stare, < 5%).
- Ablation (30 no-party, 2 runs, target p95 stare / mean unit turn): all four on 861-897 / 115-117; no reads lever 1264-1283 / 131-133; no approach shortcut 1355-1397 / 130-132; no stretch reorder 1000-1003 / 120; no line_up early-out 1012-1034 / 121. The last two are ~4% of the mean unit turn but 15% of the stare p95: kept (one-line each).

## Measure (A/B x2 interleaved `S/ab15.sh`, base d99a3c9, busy_fight n=2, M3 x4; stare mean / p95 ms, unit turn mean)
| fight | before | after |
|---|---|---|
| 30 no party | 338-342 / 2050-2105; turn 152 | 244-248 / 939-959; turn 120 (first A/B runs: 303-320 / 1876-1915 -> 229-233 / 855-871) |
| 15 no party | 89 / 172; turn 103 | 96 / 194; turn 87 |
| 15 lead | 123 / 228; turn 83 | 130-143 / 236-264; turn 78-85 |
| 30 lead | 180-195 / 540-579; turn 111-118 | 179-180 / 537-543; turn 104-105 |
Stare at 15 a side is a hair worse though every unit turn is cheaper: the fights play out differently (fewer units walk into the first volley; stare counts only acts a walk doesn't cover), all within the 1000 ms budget. OUTCOME ok every run. 30 no-party p95 is under 1000 with ~5% margin.

## Tests
- New `ai_tactics_test.test_crowd_shortcuts` (4 checks): `_reads` near filter, far `_approach` nearest tile and a taken tile. Mutations caught: far approach off, ally filter off. `_stretch`/`_line_up` early-outs are only skips of work: covered by the sim and the suite (no pin).
- Changed: none. Suite 11034 checks (11030 before), 0 failed (1039 tests). skill.py check ok; launch log: only "8 resources still in use".

## Not done
- A unit whose straight line to a far foe runs through its allies still does not move (walk pops the occupied tail): a path round the column would fix that (quality, not time).
