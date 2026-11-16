# Foe bio look-over (z-lookover)

Calls
- Shift-click is taken: `HUD.intent(inspect)` selects a foe rather than attacking it (docs/plans/ui-v2.md), so the look-over uses two other gestures: middle-click on a tile, and a new rebindable input action `look_over` (default L, listed in KeyBinds.NAMES as "Look over") on the hovered tile. Middle-click itself is not rebindable (KeyBinds binds keys only).
- `HUD.look_over(c)`: the unit `unit_seen(c)` makes out there (the same gate as the unit card), the sheet opened read-only with `null` (whole bio) for the player's own side, else `view(u)` (eyes(): the commanded unit's, as the card). Nothing leaks beyond `Bio.line()`'s own gates (unknown name: nothing; deceived: persona only).
- No new text.

Tests: bio_test.test_look_over (own unit, disguised foe, unknown foe, empty tile). Mutation: passing null for foes too failed the disguised check.

As built: see commits.
- The sheet itself leaked: its header named the unit's real name, XP, hearts, and showed its kit. With a Read (r != null) it now shows only the Read's name (else looks, else "Something"), level (or ?), and the bio line; no equipment or stash. Mutation: the old sheet failed the new header check.
