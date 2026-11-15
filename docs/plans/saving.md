# Saving (x-save, 2026-11-15)

Plan.md Phase 4 item 14, and the systems.md and world.md todos "Saving".
Baseline suite: 8070 checks, 0 failed (838 tests).

## Readings and calls

1. **Format: JSON at `user://save.json`**, not a ConfigFile. The data is nested (items with rank and enchant,
   lists), and a version field and a plain "is this a dictionary" check make a bad file easy to refuse.
   Settings stay in `Prefs` (`settings.cfg`) and `KeyBinds`; the save is progress only. `Save.gd` (class `Save`,
   static functions, `Save.PATH` a `static var` as `Prefs.SAVE` is).
2. **What is saved**: level, xp, hearts, outfit (slot to item), stash (in order), and the hero. Not saved:
   `Game.dungeon` and `Game.difficulty` (the portal just taken, not progress); learned skills (a starter
   re-learns them each battle from its level's points: `Battle.starter()`), so there is nothing to keep.
3. **The hero: new `Game.hero`** `{faction, role, name}`. `Game.starter` is "used up" by `Battle` as it starts
   (so by the time anything changes, it is empty); a record that survives is needed to say who the save
   is. Entry sets `hero` beside `starter`. Saved as the faction's and role's `.tres` paths. Call: a new static
   rather than not consuming `starter` (tests and `Battle` rely on it being used up).
4. **Load on start**: `Entry._ready` calls `Save.load_once()` (once per process: coming back to the entry
   screen after a battle does not reload over what is in memory). The stash was already kept when a new starter
   was started in one session (Entry keeps it and only adds the ring), so loading it makes that last across
   runs. **Continue**: a button on the entry screen, shown when a hero was saved ("Continue: Shrike, Adventurer,
   level 3"): plays the saved starter in the picked scenario, with its saved level, outfit, hearts and stash. Play
   still starts a new starter (outfit, hearts, level and xp over; stash kept) and saves it at once.
   Call: without a Continue button, loading the statics alone would be thrown away by Play.
5. **When it saves**: Play; each equip, unequip and use of an item from the sheet (`HUD`, beside
   `_keep_outfit`, for any of the player's side's units: the stash changes either way); the battle's end
   (`_on_phase` OVER: spoils, level, xp); and `NOTIFICATION_WM_CLOSE_REQUEST` in Entry and HUD. It writes a temp file and renames
   it. **`Save.save()` does nothing until a hero is picked**, so a scene played straight from the editor (F6)
   cannot blank a real save with an empty `Game`.
6. **Versioning**: `VERSION := 1`. A file that is not JSON, not a dictionary, has no integer version, or
   another version, is **moved to `save.json.bad`** with a `push_warning`, and counts as no save (so a newer
   game's save is never overwritten by an older one's next write). Call: set aside rather than just ignored.
   Within a good file, things that are gone (an item or a hero's class renamed or deleted, an item in the wrong
   slot) are dropped with a log line and the rest loads.
7. **Items by id**: `{item: "res://Items/<id>.tres", rank, enchant}`. A copy (Pray's `Unit.enchant()` and
   `disenchant()` duplicate) has no `resource_path`, so `Save.id()` finds the one file in `Items/` of its name
   (cached). On load the file's own item is used (the same instance, as the game compares `it == RING`), and a
   copy only when rank or enchant differ. An item with no file (made in code) is left out with a log line.
   Item-lent skills (`Item.skills`) come back by being the item's. Call: tags and other fields are the file's;
   only rank and enchant are mutated in play.
8. **Equipped-set hook** (for x-equip): `Save._equipped_out()` returns `[]` and `Save._equipped_in(ids)` does
   nothing, both marked `HOOK (x-equip)`; `pack()` writes the `equipped` key (skill ids) and `unpack()` calls
   `_equipped_in`, and a file without the key is fine. x-equip fills the two functions (and may save on its own
   changes: `Save.save()`).
9. **Tests never touch the real files**: `Tests/run.gd` points `Save.PATH` at `user://save_test_<pid>.json`
   and **`KeyBinds.SAVE` at `user://keybinds_test_<pid>.cfg`** (was a `const`; now a `static var`; the tests
   that removed `KeyBinds.SAVE` had been deleting the player's real binds), and wipes all of them (and
   `.bad`, `.tmp`) before each test and at the end. `run.gd` sets both through `load(...).set()`: naming `Save` or
   `KeyBinds` in `run.gd` compiles Role and Item before Skill, which trips a script cycle at `Unit.GENERAL_TREES`.
   Driver scripts outside `run.gd` (screenshots) use the real paths unless they set the same.

## As built

- `Scripts/Save.gd` (new), `Scripts/Game.gd` (`hero`), `Scripts/Entry.gd` + `Scenes/entry.tscn` (Continue),
  `Scripts/HUD.gd` (saves), `Scripts/KeyBinds.gd` (`SAVE` a `static var`), `Tests/run.gd`, `Tests/save_test.gd` (new).
- Tests: `save_test.gd`, 5 tests, 30 checks: round trip (hero, level, xp, hearts, outfit, stash, a copy's enchant
  and rank, lent skills, the hook's key), never blank / no-file items, bad file (five bad forms, set aside; missing
  names dropped), the per-process paths, the entry flow (Play saves, Continue). No existing test changed.
- Mutation spot-checks (each failed the named test, then reverted): version check off (bad_file), enchant not
  restored (round_trip), run.gd's `Save.PATH` not set (test_paths), the hero guard off (never_blank).
- Suite: 8100 checks, 0 failed (843 tests).
- Undone: the equipped-set hook is empty; no "delete save" / "new game" button; no save when quitting from
  inside a Gamut's Tower scene (it has no HUD; the last change was already saved, only mid-battle XP is lost).
