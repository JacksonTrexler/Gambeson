# w11-icons
Cause: all 4 icons (disturbance, grave_aura, opportunist, seaborn) + .import are tracked. Test used load(), which needs .godot/imported cache; worktree's copied cache predates them -> null. Not a missing-commit bug.
Fix: Tests/tooling_test.gd test_icons checks png + .import exist per skill (no cache). Intent kept.
Verified: every Skills/*.tres has tracked png + .import.
