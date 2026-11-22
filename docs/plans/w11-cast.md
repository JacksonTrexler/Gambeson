# AI turn cost: the cast (w11-cast, 2026-11-22)
Goal: unit turn down (15v15 n=2 `busy_fight`, M3); digest 3296533323 must not change; suite 0 failed, count not dropped. No cross-stretch cache.
Files: Scripts/AI.gd, Battle.gd, Unit.gd, Perception.gd, Tests/ai_tactics_test.gd.
Tools: `S/ab-w11.sh [n]` interleaved A/B (base-w11 = tip 8ed1542 vs this worktree); perf copies `S/perf-w11*` (perfwrap.py + get_stack tallies).

## Profile (tip, 15v15 n=2; counts over 2 fights, 267 unit turns, 43 ms mean)
Stat machinery dominates: ~214K `_on_passives` (21 us), ~180K `_gather_effects` (25 us) a fight, from held-fx builds (one per unit per stretch/epoch) and r0 gathers.
Builds by epoch opener: reacts<react_with 14.4K (one per react_with), read<_hunt 13.9K, _line_up 11.8K, _reads 11.4K, suspicious<_first_look 13.4K, _look_harder 7.4K, _sightings<travel 8.5K, ...
r0 gathers (70K): settle<restless<disturbed 10K, cover 11K (_fight/_lose_cover/inspect/travel), evaluators 5.5K, slot_count/lv 6K...
Reads 29K: suspicious 6.9K, _reads 5.6K, _tile_read 5K, _sightings 4.2K, _look_harder 2.7K.

## Steps (A/B unit turn mean, base ~42-43)
