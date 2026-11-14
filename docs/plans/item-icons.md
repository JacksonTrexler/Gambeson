# Item icons (q-icons, 2026-11-14)

Todo: "Item sprites and icons"; emblems (Sigil, Insignia, Crest, Badge) had none either.

## Readings
- Skills read `Icons/Skills/<file>.png` (Skill.icon()) and `icon.py` draws placeholders; items had nothing.
- Item trim (`Item.trim()`, `Tags.color()`) already shows as a banner on the sheet, the card and the unit sprite.
- No item tool exists: items are hand-written `Items/<id>.tres`.

## Calls
1. **Icons are in colour, not white-on-clear.** Skill icons are tinted by state; items have no state, so the shape is drawn in a material colour with the trim colour as accent (armor band, weapon hilt/head, ring gem, pouch tie).
2. **Shape by slot and kind**: armor a tunic (cloth/medium/heavy body colour by weight tag); weapon by `damage_tag` (slash sword, pierce dagger, blunt mace); ring, book, shackles, heart (`hearts > 0`), potion (liquid by `restores`) by tag or field; anything else a pouch. Falls through in that order.
3. **Emblems** are a plaque by scope (sigil diamond, insignia disc, crest shield, badge square) in the trim colour, bearing the symbol (rho/sigma/lambda with arrows, added to the pixel font) or the tag's initial.
4. **icon.py reads Tags.gd and the .tres** for colour/trim (regex, no Godot), mirroring `Tags.mark()` (emblem first, weights and PLAIN skipped). If Tags.gd's layout changes, tag_table() needs the same edit.
5. **`icon.py check` fails an item without an icon** (and an icon for no item); `skill.py check` runs the same (one line in check_icons), since that is the check the house rule says to run.
6. **`Item.icon()`** reads `res://Icons/Items/<file>.png`; a run-time copy (no resource_path) falls back to the name's slug (apostrophes dropped), so Tactician's Playbook finds tacticians_playbook.
7. **Card shows every worn item's icon**, not only trimmed ones (`HUD.trims()` now returns [colour, name, icon] for all worn items; a clear colour draws no banner). Changed the test `tag_colors.test_trim_shows` (untrimmed ring: was "shows nothing", now "icon and no banner").
8. **Layout**: sheet rows 20px icon with the banner beside it; the card is cramped (portrait foot), so 10px icons with the banner drawn over the icon's top-right corner. The third icon still touches the word under the portrait by a pixel or two.
9. **Process line** in `.claude/skills/new-mechanic/SKILL.md` (closest to tags/Item.trim; new-unit has no item step): "A new item ... needs its icon: `icon.py item <id>`". `new-class/SKILL.md` got the one authorised line for `role.py god`.
10. Loot/stash: only the sheet's stash lists items (Loot.gd draws no list); it gets icons. The post-battle "Spoils" is a text line, left.

## As built
Util/icon.py (item, items, check), Util/skill.py (one line), Scripts/Item.gd (icon()), Scripts/UnitCard.gd (trim_mark icon arg), Scripts/CharacterSheet.gd, Scripts/HUD.gd (trims), Icons/Items/*.png (+.import), Tests/item_icons_test.gd, Tests/tag_colors_test.gd. Captures in the scratchpad shot_q-icons/.
