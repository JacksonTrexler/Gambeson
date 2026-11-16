# Guards (z-guards)

## Calls
- Tree wiring: `skill.py check_reachable` already fails a skill nothing offers (tree, role, item, another skill's grant). Mutation: removed Switcheroo from `Trees/legerdemain.tres`, `check` failed "Skills/switcheroo.tres: on no tree...", reverted. So no new check.
- Deleted `trickster_test` (a name/order snapshot of the Rogue tab) and `slam_jam_test.test_tree` (prerequisite edge and name). Call: their wiring is covered; the exact layout/prereq snapshots are not, but were the "lots of tests" kind. Say if you want the Jam prerequisite kept.
- Driver guard: `Prefs.SAVE` and `KeyBinds.SAVE` get `*_driver.cfg` when the main loop has a script (or none yet), the same expression as `Save.PATH`. run.gd still overrides all three.
- Mutation check: driver guard verified by a -s script printing the paths (see below).
