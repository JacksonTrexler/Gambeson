# HUD glow and Guide bundle (z-hudglow)

Card: docs/queue.md "HUD glow and Guide bundle". Tests: `hud_test` (test_area_glow, test_skill_glow, test_command_glow_stand_in,
test_tile_effects, test_self_evaluation_ui), `ui_small_test` (test_near_miss_scale, test_guide_key), `exhaustion_test.test_costs`.

## Already built (checked against the code)
- The allied glow stronger on grass maps: `HUD.ALLY_GLOW` is a pale mint, `ALLY_BOOST` lifts it, and there is a saved picker in Settings
  (hud-markers.md, ui-small.md).
- Holder views (spellbook entries, hotbar) show the exhaustion-adjusted price: `Skill.spec(u, rank)` multiplies by `Exhaustion.rate()`.
- Strike's forced charge: Ctrl-click on a foe already walks the unsure way (`strike_at`).
- Warcry's marks on a busy board: re-checked by screenshot (`shot_z-hudglow/warcry`): the red brackets and numbers read over the glow,
  the reach rings and a shaded cone. The only snag is the tile pane covering a mark at the bottom right; the hint line also counts the picks.

## Built
1. **Glow for area skills.** New hook `Behaviour.footprint(cast, cell) -> Array[Vector2i]` (default empty; the area `apply_at()` would
   cover), with `Skill.footprint(battle, caster, cell)` the union. Cone and Zone implement it. While an area skill is aimed, `HUD.caught`
   (`_caught()`, refreshed in `_replan()` on a hover change) is whoever the player makes out standing in the footprint of the hovered tile,
   and `glow_of()` lights them fully. The overlay shades the cone's tiles (it drew a rank-sized circle before).
2. **Somewhat, forced.** Ctrl-click on an ally whose only way is an unsure walk now walks it and uses the skill (`_use_intent(..., force)`).
   Foes were already covered by `strike_at`.
3. **Command glow reach.** `_into_command` judges the leader's walk by the larger of the party/plain reach and `command.reach_for(u)`
   (a stand-in mod, Word to the Wise), as `Command.in_range` does.
4. **Guide keys.** `{action}` placeholders in a Guide page are replaced with the key bound now (`Guide.keys()`): next_unit, cancel, party,
   hold, end_turn, spellbook as well as hurry. Rebinding follows.
5. **Near-miss circles.** To scale: each unit's circle is the size it adds to the range (0.05 a point of the caster's, 0.02 of the
   target's); Luck.MARGIN is a dashed ring past the reach ring and the near miss shows only inside it. Bright when the caster is luckier
   (it rounds in), faint when not.
6. **Museum tile hover error.** The cell under a hover can lose its tile (a pocket ending erases its cells); `_show_pane` then called
   `_tile_icon` with source -1 and read `get_cell_tile_data(c).modulate` on null. The pane now hides when the hovered tile is off the map
   and `_tile_icon` guards the source.
7. **Jammed ?? chip.** A condition's chip with no skill of its own takes two letters and keeps the " ??" a made-up name wears ("Ja ??").
8. **Skills screen cost note.** `Skill.base_note()` (grid and wheel tooltips, the detail pane) adds "Costs more now: exhausted xN" for a
   skill the unit has worn (`Exhaustion.note()`).
9. **Guide text** for Ctrl-click walking, aiming and "caught" glow.

## Profiling the reach map (Meadows, 14,400 cells, debug build, headless)
`HUD._find_reach` (runs on a `_mark`, cached per selected unit; the same cost armed or not, 359 ms vs 353 ms for a whole `_refresh`):
move 5: 90 ms (29 tiles); move 10: 320 ms (198 tiles). A hover (`_replan`) is 0.3 ms. Per walk 0.7 ms (224 walks 155 ms): `line()` 23 ms,
`route()` 8 ms, the strides 18 ms, so the rest, about 100 ms, is `read()` per step (0.026 ms each, three a step). Left alone: it is
bounded to a box around the unit, cached, and a few hundred ms only for a boosted unit in a debug build. If it bites: a per-refresh read
cache for `walk(expected)`, or one flood fill in place of a walk per tile.

## Calls
1. Footprint is a Behaviour hook, not a per-skill branch in the HUD, so a later area behaviour joins by implementing it. Only Cone and
   Zone have one (Flamewall, Well-up, Guard, Observe, Rifts and traps do not); they keep the old overlay.
2. A caught unit glows fully whatever its side (an ally in a hostile cone too): the glow says "caught", the unit's own colour says who.
3. "A party member with its own reach": read as the command reach the leader has for that ally (`reach_for`), not a party member walking.
4. The chip shows the first two letters plus " ??" rather than the whole name (a 5 pt chip); the full name stays in the tooltip/Glossary.
5. Near miss now shows within Luck.MARGIN (0.5) instead of 1 tile; beyond that luck cannot help, so the picture would mislead.
6. Skills-screen note kept short: "Costs more now: exhausted x2".

## Mutation spot-checks
Dropping the `force` branch, the `reach_for` term, the cone's width, the on-map guard, the chip's ??, the Guide's substitution and the
exhaustion note each failed its test.

## Left
- The Guide has no line for the near-miss rings.
- Meadows' reach cost (above) if it is felt in a release build.
