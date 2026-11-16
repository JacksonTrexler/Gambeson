# Warcry picker (z-warcry)

## Readings
- Warcry (`Behaviours/warcry.gd`) marked toward the nearest rank visible foes. The design says "pick up to rank enemies the unit can see".
- Warcry is a self skill: its key selects it, the key again (or a click on the unit) casts. There was no aim state for self skills, only for tile skills (`HUD.aim`).

## Calls
1. Generic seam: `Behaviour.picks(c) -> int` (default 0) says how many targets the caster may pick by hand. `Cast.picked` carries them; `Battle.cast(..., picked)` passes them (member `_picked` for the outermost cast); `Battle.picks_of(caster, skill)` sums the behaviours' answers for the HUD. A later multi-target skill overrides `picks()` and reads `c.picked`.
2. Empty picks means the behaviour chooses (Warcry: the nearest rank), so a quick cast and the AI path are unchanged. Picks are validated in `Warcry.chosen`: alive, foe, still located, capped at rank, duplicates dropped; if none survive, the nearest.
3. HUD: the key of a skill with `picks > 0` sets `aim` (like a tile skill) and `picking()` is true; `intent()` returns `&"pick"` for a visible foe (toggle, cap = picks), Ctrl-click still strikes. Cast on the second key press or a click on the unit, as before. Cancel, select, slot change and a cast clear `picked`.
4. Default is not drawn (the hint says "the nearest N"); only picked foes show: red brackets and a number, and the hint line "Warcry: 2 of 3 picked". Minimal as asked.
5. Pickable = foe the caster `read()`s as located, the same filter Warcry uses, so a click never picks what the cast would drop.
6. Renamed Warcry's static `picks(b, caster, n)` to `nearest` (it clashed with the new instance `picks`).
7. Sight: `Skill.describe` now says "you choose them, else the nearest first".

## As built
Files: Behaviours/warcry.gd, Scripts/Behaviour.gd, Scripts/Battle.gd, Scripts/HUD.gd, Scripts/Overlay.gd, Tests/warcry_test.gd. Frames in `S/shot_z-warcry/`.
Tests (extending warcry_test.gd, no new file): Warcry picks/cap/default via Battle.cast; HUD toggling, cap, unpick, cast clears. AI path: existing `test_the_ai_lays_its_marks_before_it_advances` (nearest, no picks).
Mutation spot-checks: dropping the cap in `Warcry.chosen` fails the cap check; dropping the cap in `_toggle_pick` fails 3 HUD checks.
