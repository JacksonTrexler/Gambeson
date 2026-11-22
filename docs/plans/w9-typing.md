# w9-typing (pilot: does stricter typing help?)

## Goal
`untyped_declaration` warn in project.godot; count; type AI/Perception hot paths; measure before/after.

## Findings
- Headless/--check-only/--import/--editor print NO GDScript warnings here (tried 4 ways), so counts come from `S/untyped.py` (regex: untyped `var`, params, returns; approx of UNTYPED_DECLARATION). Setting is in project.godot (`[debug] gdscript/warnings/untyped_declaration=1`) for editor users.
- Untyped declarations total 27 (of ~thousands): Save.gd 12, Unit.gd 5, Battle.gd 4, Game.gd 3, Skill.gd 2, PartyPanel.gd 1. AI.gd/Perception.gd 0. Codebase is already ~fully typed (AI.gd 213 `:=`, 0 untyped signatures).
- Real gap was Variant-valued loop vars: `for s in u.actives.filter(...)` (filter/slice/values/keys/Dictionary iteration return untyped). Typed `for s: Skill in`, `for t: Unit in reads`, `for c: Vector2i in`, `dx: int` (76 lines AI.gd, 4 in Perception).
- `reads` param `Dictionary` -> `Dictionary[Unit, Read]` (44 sites AI.gd; `_reads`, `_reachable` return; `near` local). Needs `AI.reads_from(d)` for tests that hand-build reads (13 test files, mechanical).

## Measurements (busy_fight 15 rounds=10, unit-turn mean ms here; digest 47676114 same before/after)
- Before x3: 69.0 69.7 69.1; ai_sim wall 38.7 37.7 38.0 s. Variance ~1%.
- After x3: 69.2 68.6 68.3; ai_sim 38.6 38.8 39.0 s.
- Back-to-back A/B x4 (baseline copy vs typed): 67.1/67.1, 67.4/67.4, 67.0/67.1, 66.8/67.3. No speedup (an earlier 64 ms reading was machine noise from other builders).
- Hot cost is Unit.stat / Perception / walk logic, already typed; Godot 4.7 typed loops/dicts add no measurable speed here.

## Bugs exposed
None in game logic. Typed dict params rejected untyped `{}` literals at runtime in 13 tests and one internal local (`_last_blows`' `near`): a strictness benefit (shape errors fail loudly), cost is churn.

## Done
Setting; AI.gd/Perception loops + reads typing; tests' reads wrapped; suite 10720 checks, 0 failed.

## Recommendation
Do not expand for speed (0%). Expand only for safety, cheaply: loop-var typing and the 27 declarations (Save.gd first). Don't type shared dict params like `reads` unless a helper exists; churn exceeds value. Revisit if warnings become visible in CI.
