# w10-typing (2026-11-22)
Goal: the 27 untyped declarations, safety only. Re-count (S/untyped.py): still 27 (Save 12, Unit 5, Battle 4, Game 3, Skill 2, PartyPanel 1) -> 0.
## Calls
- `d.get(..)`/`fielded.get`/dict-index values: `: Variant` (they are checked with `is` right after); `load(..)`: `: Resource` (checked with `is`/has_method).
- Battle `best_luck/dexterity/members(side)`: `side: Variant` (takes Unit, Faction or Array); `_flip` swap temp `t: Variant`. No shared dict params typed, no helper needed.
- Mechanical only; no logic touched. Tests unchanged.
## Result
busy_fight 15 rounds=10 digest 3296533323 before and after. Suite 10814 checks, 1 failed (1029 tests): tooling_test.test_icons (4 skills lack icons: disturbance, grave_aura, opportunist, seaborn) fails identically at the tip without my edits.
