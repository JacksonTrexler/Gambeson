# w17-equip: make auto-equip explicit (?265 card), then a read stretch round _fill_bar

## Reading
- Cause of the w15 failure: `_fill_bar()`'s first `_slot_keys()` -> `lv()`/`_grants()` -> `stat()` -> `_touch_bar()` -> `_sync_new()`
  filled the bar in auto-equip order (equip_skill per slot, slots order) whenever the unit had a passive on that takes a slot;
  `_fill_bar`'s own passes then found it full. In a stretch `stat()` skips `_touch_bar`, so the passes ran instead: Icor got
  [Strike, Mana, Hex, ...] not [Strike, Hex, Mana, ...].
- Other read-side syncs: `equipped()`, `get_equipped()`, `_grants()` (via `_touch_bar`). Write-side ones already explicit:
  `unlock()`, `_sync_granted()` (refit: every equip, unequip, enchantment). Game code mutates `learned` only in `unlock()` and
  `from_dict()` (before the tree: `_fill_bar` covers it). Level-up slots go through `_arrange()`/`auto_fill()` (unchanged).

## As built
- `Unit._sync_new()` -> public `sync_bar()`: the one auto-equip hook. Removed from `equipped()`, `get_equipped()`; `_touch_bar()`
  deleted (stat() and `_grants()` no longer call anything). stat(), equipped(), get_equipped(), actives change nothing.
- `_fill_bar()` = begin_read(); `_fill()`; end_read(). `_fill()` calls `sync_bar()` explicitly where the read side effect used to
  fire (a passive on that takes a slot), so the order is the old one.
- `_held_fx()` also drops its stretch cache when the bar changed, only while `_filling` (`_fx_bar` = hotbar.hash()).
- HUD `_refresh_bar()`: `selected.get_equipped()` (was called for its sync) -> `selected.sync_bar()`.
- Tests: every line handing a unit a skill directly (`.learned/.innate/._role_slots` append/append_array/clear/erase/pop_back/
  insert/assign/=: 545 sites, 118 files) now ends `; <unit>.sync_bar()` (mechanical, script `S/w17_sync.py`). No check changed.
  equip_test.test_auto_equip: +2 checks (a read auto-equips nothing; sync_bar does). equip_test: dropped a no-op `u.get_equipped()`.

## Checks
- Suite: start 11086 checks, 0 failed (1047 tests); end 11088 checks, 0 failed (1047 tests).
- Time (A/B, alternating, origin/main worktree vs branch): base 62 s, 63 s; branch 60 s, 60 s. Saved ~2.5 s of ~62.5 s (~4%),
  not the ~10 s estimated.
- Order: a dump of every unit scene, 13 roles x levels 1/5/9/13/20 and the museum's units (89 bars) is identical on
  origin/main and the branch (temp test, not committed).
- Mutations: sync_bar back in equipped() -> test_auto_equip fails; no explicit sync in `_fill()` -> 8 fails (command_test bar
  tests, hud_markers, hud_test toggle); the `_filling` invalidation removed -> nothing fails (suite and 89-bar dump).
- reverse: meadows_test.test_camera / test_tower_difficulty crash (BattleCamera freed instance) identically on origin/main:
  pre-existing, not this card. skill.py check ok; launch clean (only "8 resources still in use").

## Calls (questions from 273)
- 273 One public hook `sync_bar()` (was `_sync_new`); whatever changes skills calls it (unlock, refit, `_fill_bar`, a test, the
  HUD's bar refresh). The HUD call stays as a belt for paths that never called it; no `learn()` API added.
- 274 Kept the w14 fill quirk exactly: a unit with a passive on (taking a slot) fills in auto-equip order, others by
  `_fill_bar`'s passes (pillars, actives/toggles, passives from the right, optional lends). Unifying to one order would move
  bars (Icor: Mana before Hex): for the user.
- 275 Tests that hand skills directly call `sync_bar()` on the same line (545 sites) rather than a helper: mechanical, no
  semantics change; noisy diff.
- 276 The bar-keyed stretch invalidation while filling is defensive (the stretch contract: no stale passives after a bar
  change); nothing exercises it today (no role has a slot-granting passive at setup). Keep or drop.
- 277 Gain is ~4% of the suite, not ~16%. Remaining setup cost is `refit()` / `_take_looks()` in `_ready` (they change the bar
  and HP: not a read stretch); not pursued.

## Undone
- Nothing on the card. Lead for more suite time: per-test museum setup outside `_fill_bar` (?277).
