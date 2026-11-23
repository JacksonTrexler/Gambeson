# w18-leaks: running list of leaked nodes

Goal: Tests/run.gd root sweep (w17-reverse) also records each leak in Tests/leaks.txt; never fails the run.

## Built
- run.gd: sweep collects `test<TAB>Class<TAB>path` (class = script global name or engine class; `@` stripped from the path), `_record_leaks` merges after the run.
- Merge: read existing lines, add only new, sort (order-stable across forward/reverse), rewrite only if something was added.
- Write: per-process `leaks.txt.<pid>.tmp` (*.tmp is gitignored) then rename: atomic; missing file = empty list; open failure prints, no fail.

## Calls
- Committed (not gitignored): user wants a running list for batch fixing; .gitignore only holds generated/cache files. Starts as a one-line `#` header: the suite leaks nothing now (w17-reverse fixed Test.hud), so the first run's contents are empty.
- Sorted rather than append order: reverse/forward give the same file.
- Parallel runs: read-modify-write can lose a line to a race; the next run re-adds it. Judged fine vs. locking.
- Header kept as a "line" by the merge (no comment parsing); sorts first.

## Checks
- Deliberate leak (`tree.root.add_child(Node.new())` in prep_test.test_studies): run 1 added `prep_test.test_studies	Node	/root/Node2`, run 2 added none. Removed. Full: 11088 checks, 0 failed (1047 tests).
