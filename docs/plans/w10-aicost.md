# AI turn cost: the per-read floor (w10-aicost, 2026-11-22)
Goal: unit turn / end_turn down further (15v15 n=2 `busy_fight`, M3 shared CPU); digest must not change; suite 0 failed.
Files: Scripts/Unit.gd (so far).

## Baseline (tip 90e374e)
Digest is **3296533323** at this tip (card said 47676114: that was before w9-aiplate/typing merges changed AI decisions; same on 3 runs here, so it is the reference now).
unit turn mean 62.2 / p95 ~102; end_turn 77 / p95 230. Suite 10789 checks, 0 failed (1025 tests).

## Profile (in-stretch micro-bench, `S/bench_w10.gd`, us per call)
kit 205 cold / 91 in stretch (a read asks it twice), defense 47, `mod` 27 (!), `insightful` 28: `mod()` -> `scaling()` loops `on_passives`, which was rebuilt (22 us) on EVERY call, even in a stretch.
gather 24, r0 gathers (no stretch) 138K of 218K in a 15v15 (react/helpless/stopped/affinity...).

## Done
1. `kit` and `defense()` (no tags) held per stretch (`held`/`hold`; kit returns a copy). read 363 -> 192 us.
2. `on_passives` found once per stretch, with the effects (`_held_fx` builds it with the null viewer entry; `_gather_effects` takes it). mod 27 -> 5 us, read 192 -> 119 us.
Result: unit turn 62.2 -> 47.0, end_turn 77 -> 59.5, digest same.
