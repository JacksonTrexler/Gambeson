# w21-books-ai: AI units read books on calm turns
Calls:
1. An AI unit's "stash" = `Unit.pack` (already its carried items; spills as loot on death, so unread books drop). No Game.stash for AI.
2. Hook `AI._study(b,u,log)`: first readable book in pack -> `Battle.study`; erased pass or fail; pass -> `u.tweak(u.fancy(r.tweaks))`. One a turn; study {} (no AP) leaves it.
3. Calm = the two spots where AI already skips striking: full turn `not _could_strike` branch (before _dress) and `_prowl` (far, _far). NOT _dress's tail call (after strikes = danger) nor _drill.
4. Cost: loop over pack only; empty pack = no work. ai_sim default output identical before/after.
Tests: Tests/books_test.gd test_ai_reads (pass, fail, foe adjacent -> book kept). Mutation: gate removed -> foe case fails.
Undone: no scene carries books yet; no _drill (calm follower) reading; pack not saved (autospec-save sibling).
