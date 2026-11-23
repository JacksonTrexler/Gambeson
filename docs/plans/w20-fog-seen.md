# w20-fog-seen: explored marks ground walked past (?316)
Calls:
- travel() (Battle.gd), sight on: `_mark_seen(u, passed[i])` for every passed cell but the last (the last is marked lazily when u plans: known_ground). `_mark_seen` takes `from := u.cell`.
- One disc per step, not a path-cell set: sight at each step; no whole-map loop.
- Applies to every unit with sight on (player side's explored also filled by sight_cells; harmless dup).
Bench busy_fight 15v15 lead, unit turn mean here: 18.7 base -> 18.6 (p95 48.4->50.5 noise); 30v30 25.0 -> 25.2/24.8. Flat.
Test: Tests/sight_test.test_walk_marks_ground_passed (new, in existing file). Mutation: marking call -> pass: fails.
