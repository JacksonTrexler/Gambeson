# w22-reach-stars
Goal: Battle.reckon_reach reads a foe's reach across a powered Starway.
Built: in the Dijkstra, a settled tile `at` with `_exit_of(t, at) != at` and known portal (known_ground(o, at).tags, fog rule as _hops) puts its pair in at the same cost/bag (hop free); pairs kept in `landings`. Crow-line filter: tile ok if within budget of `from`, or within `budget - best[landing]` of a landing.
Calls: single hop, not chained beyond what Dijkstra finds; powered/free by _exit_of(t, ...) (t's walk rules); knowledge by o. No new helper (reused _exit_of, known_ground).
Test: starbuilding_test.test_ai_hops_starway +2 checks (dark: not across; powered: across). Mutation: landings ignored in filter -> powered check fails.
Not done: chained portals.
