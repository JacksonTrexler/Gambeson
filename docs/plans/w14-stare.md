# AI stare (w14-stare, 2026-11-23)
Goal: 30 a side side-turn player stare p95 < 1000 ms (M3 x4); was mean 743-894 / p95 3133-3662. Tool `busy_fight 15 30 lead`. Base origin/main f217c8b.

## Readings (PERF accumulators, 30 lead, 679 acts)
- 87% of act time is `Battle.read` (0.22 ms each, 128k calls = 188 per act). Callers: `travel` -> `_sightings` (read of mover by every unit) + `_first_look` -> `suspicious` (reads every unit): 59k; `AI._reads` 17k; `_look_harder` 15k; drill 8k; `_hunt` re-read all 4k; `_check_stall` 6k.
- Round 1-2: 18 of 30 per side go full (followers beyond party reach not calm), each hunts (no foe in sight, 12 tiles): `_reads` 14 ms + `_hunt` 44 ms (approach 8 + re-read all).
- `in_range` (sight, side-shared) 0.06 ms, builds `members()` each call.
- end_turn here: stall 27 ms, tick 26, watch 40 per side turn.
