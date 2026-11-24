# w22-hud-polish
Goal: 5 HUD fixes from w22-shots. Files: HUD.gd, SkillSlot.gd, SkillGrid.gd, Util/role.py, Scenes/entry.tscn, Tests/hud_test.gd.
## Calls
- 1 Names: SkillSlot.name_font(): shrink 7 -> 5 min to fit the slot, no rename, no wrap.
- 2 Grid: SkillGrid.BAR (9px) added to min height so the h-scrollbar sits under T1. Tree still opens scrolled to the bottom (trees grow from the bottom; T9 above the fold by design; TreeScroll 176px kept). Not changed: open position.
- 3 Startile at charge 0: pane note is the tile's own name ("Startile") + rate, "% full" only when charge > 0.
- 4 Wizard: role.py NPC_ONLY drops "wizard" (Icor still uses it); add_to_entry("wizard") put it in entry.tscn roles.
- 5 Stardust swatch: HUD._tile_icon blends the top layer's own art over the ground atlas swatch (as the map draws it), cached per [key, art].
## Tests (hud_test only, +4 checks, no new files)
- test_layer_pane: uncharged source note; Stardust swatch differs from bare ground; name_font table.
- test_adventurer_skills_screen: grid keeps BAR under T1.
- Mutations (each fails its check): "% full" always; blend off; name_font -> 7; BAR removed.
- Wizard on entry: role.py check (was failing without entry).
