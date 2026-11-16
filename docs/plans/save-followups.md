# Save follow-ups (z-savefu, 2026-11-15)

## Readings and calls
1. **New game**: a "New game" button on the entry screen (`%Delete`), shown when a hero or a save file exists. Confirm is a second press (the text turns to "Sure? Press again to delete the save"), not a dialog: one node, testable. `Save.erase()` removes the save, `.bad` and `.tmp`, and calls new `Game.reset()` (every static back to its default). Call: `Game.reset()` lives in Game so a later static is added beside its declaration.
2. **Tower quit**: `GamutsTower._notification` saves on `NOTIFICATION_WM_CLOSE_REQUEST`, as Entry and HUD do. Battles inside the tower already save at their end; this keeps anything changed between.
3. **Allied glow picker**: already in `Prefs` (`ally_glow`, name key, HUD.gd settings; covered by ui_small_test). Nothing to do.
4. **Driver save path**: guarded in `Save.PATH`: a `-s` script (main loop has a script, or none yet while it loads) gets `user://save_driver.json`. run.gd still sets its own. Call: code guard over a memory note; Prefs and KeyBinds not guarded (out of scope).
5. Equipped-set hook untouched.

## As built
- `Scripts/Save.gd` (erase, PATH guard), `Scripts/Game.gd` (reset), `Scripts/Entry.gd`, `Scenes/entry.tscn`, `Scripts/GamutsTower.gd`, `Tests/save_test.gd` (test_new_game, test_tower_quit_saves).
- Mutation spot-checks: `Game.reset()` removed fails test_new_game; tower save removed fails test_tower_quit_saves.
