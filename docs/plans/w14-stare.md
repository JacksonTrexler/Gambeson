# AI stare (w14-stare, 2026-11-23)
Goal: 30 a side side-turn player stare p95 < 1000 ms (M3 x4); was mean 743-894 / p95 3133-3662. Tool `busy_fight 15 30 lead`. Base origin/main f217c8b.

## Readings (PERF accumulators, 30 lead, 679 acts)
- 87% of act time is `Battle.read` (0.22 ms each, 128k calls = 188 per act). Callers: `travel` -> `_sightings` (read of mover by every unit) + `_first_look` -> `suspicious` (reads every unit): 59k; `AI._reads` 17k; `_look_harder` 15k; drill 8k; `_hunt` re-read all 4k; `_check_stall` 6k.
- Round 1-2: 18 of 30 per side go full (followers beyond party reach not calm), each hunts (no foe in sight, 12 tiles): `_reads` 14 ms + `_hunt` 44 ms (approach 8 + re-read all).
- `in_range` (sight, side-shared) 0.06 ms, builds `members()` each call.
- end_turn here: stall 27 ms, tick 26, watch 40 per side turn.

## As built (steps; busy_fight 15 / 30 lead, n=2, M3 x4)
1. `Battle.read` of a foe beyond sight (in_range 0) = `Perception.nothing()`; in sight but past half range (1) with no concealment (`Battle._plain`) = `Perception.vague()`; both skip Perception.unit (0.2 ms). `in_range` uses an eyes list kept per read stretch (`_eyes`, keyed by `Unit._epoch`).
2. `travel`: `_sightings` (59 reads) only if `_may_hide`; `suspicious` (first look after every walk) reads nobody `_plain` says is far/plain; `_check_stall` by in_range, side-shared.
3. `Unit.tick`: `_arrange`/`refit` only when an effect/disabling ended (0.85 ms a unit).
4. `AI._far` / `_prowl`: no foe in sight (all `_plain` 0/1), no nature/cc/hold: reads foes + allies within reach, heal, support, search/scry/hunt, strike. `_hunt` goes straight past move_left + HUNT_FAR. Drill reads allies within reach + 1 only.

## Calls (for the coordinator)
- "Far from a foe" (`AI._far`): the unit has no nature (`behaviour`), no temper, is not Downed/channeling/Restless/posing/held/holding/cc'd, holds no assumed side (`Unit.assumed`), sight is limited, and EVERY living non-friend is `Battle._plain` 0 or 1: beyond its side's sight (`in_range` 0), or in it but past half range (1: only a vague shape, so it cannot be a foe to strike) with nothing hiding it (no zone over its tile, no concealment effect on it), recon >= -2, no lie to weigh (trickery, clout, a front when its wisdom mod <= -3), no ping. One foe in plain sight (or any doubt) = a full turn.
- Far turn (`AI._prowl`): reads foes (cheap) and allies within longest reach + 1; heal, support, search/scry/hunt, strike what it comes to make out, replenish, dress. Skips temper, tending, summon, line_up, steady, starve, switch (nothing in sight to weigh them on).
- `HUNT_FAR` 2.0 tiles: a hunt's goal farther than move_left + 2 is headed for straight (travel to the last-seen tile), not by the tile beside it (`_approach`, 6 ms, cannot be reached this turn anyway).
- Drill and far turn read an ally only within reach + 1 (was walk + reach + 2): `_heal`, `_support` cast from where it stands.
- Reads of a foe far off are NOT the same object as before: `Perception.nothing()` (net -4) and `Perception.vague()` (net -2: where, a hint, aura) skip `deceived`/`doubt` bookkeeping for a far foe a persona front at wisdom mod <= -3 could fool (guarded to the real read) and `heard`, `twist` (trickery guarded). `read()` of a friend or a near foe is untouched.
- `travel`: `_sightings` (observers who watch it vanish) only when `_may_hide` (cover now or at the end, ground effects, afflicting ground, fire, marks). A vanish caused by a mark's or an afflicting tile's effect it steps on is still caught (those make it true).
- `suspicious()` (a unit's first look after each walk): no read for a foe/ally `_plain` calls far or plain; same list otherwise (test pins it).
- `_check_stall`: foes read only by sides that make them out (in_range 2) or hold an assumed side.
- `Unit.tick` refits only when a disabling or effect ended or fell a rank (or a postponement landed). A stat changed outside tick and expected to be refitted by it is no longer: none in the suite.
- Decisions change: far units walk straight at far hunts and skip the full phases; 15/30-a-side fights end a little different (30 lead: 47.5 -> 48 fallen, 8.0 -> 10.0 left of Nemes).

## Measure (A/B x2 interleaved `S/ab-w14s.sh`, base f217c8b, busy_fight 15 30 lead n=2, M3 x4)
| side stare on the target | before mean / p95 | after mean / p95 |
|---|---|---|
| 15 a side lead | 230 / 790 | 142 / 268 |
| 30 a side lead | 800 / 3380 | 231 / 754 |
| 30 a side, n=6 lead | - | 215 / 614 |
| 30 a side, no parties | 916 / 4343 | 351 / 1842 (over: full turns boxed in by their own column, ~150 ms each, no walk to cover them) |
Unit turn CPU 30 lead: 197 -> 118 mean (p95 354 -> 273); end_turn 30 lead: 400 -> 159 mean (p95 1111 -> 326). OUTCOME ok every run (no stuck unit, fights end).
Reads were 87% of act time (128k reads, 188 an act); now ~45%.

## Tests
- New `ai_tactics_test.test_far_reads_and_turn` (34 checks): shortcut read == `_read` (table in_range 2/1/0, concealed, low recon, assumed), `suspicious` list, `_far` table (nature, temper, cc, plain-sight foe, sight off), far turn ends where `_full` ends, tick refits only on a change. Mutations all caught: `_may_hide` false (vanish_test), tick never refits, concealment check off, recon check off, assumed guard off, stall never near (lure_test), vague skipped in suspicious.
- Changed: none. `astral_test.test_envoy` loops until its battle ends (21 -> 23 turns, 401 -> 372 checks); suite 11017 checks vs 11012 before.
- Suite: 11017 checks, 0 failed (1034 tests). skill.py check ok; launch log: only "8 resources still in use".

## Not done / next
- No-party 30 a side p95 1.8 s: full turns of units boxed in by allies (approach, line_up, stretch ~ 150 ms with no walk). Lever: skip far allies' reads in `_full` for temper "" (only `_tend`, `_starve` use them), `_approach`/`_line_up` early-out when boxed in.
- end_turn per unit still ~1.3 ms (`recover`, `exhaustion.recover`, `_starlight`, `_watch`: stats read outside a stretch).
