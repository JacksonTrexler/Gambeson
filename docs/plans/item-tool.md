# Item tool (y-itemtool, 2026-11-15)

Queue card "Item tool" (docs/todo/world.md:128, ?135). Read: item-icons.md, item-ranks.md, item-skills.md,
skill-tooling.md. Baseline suite: 8070 checks, 0 failed (838 tests).

## Readings
- Items were hand-written; `icon.py item` drew their art and `icon.py check` (run by `skill.py check`) caught a
  missing or orphan icon. `mechanic.py check` held enchanted/honed exclusivity for Items and Skills and every
  tag's colour; `item_icons_test` ran `icon.py check` and re-did its missing-icon loop in GDScript.
- Loot tables (`Loot/*.tres`) are items + weights (missing weights weigh 1); nothing checked them beyond
  unit.py's "every path a unit scene names exists".

## Calls
1. **One tool, `Util/item.py new` / `check`**, shaped like unit.py: `new` takes slot, rarity, rank, tags,
   `--enchanted | --honed` (argparse-exclusive, and refused again if both come in through `--tags`), `--skill`
   (lent, `Item.skills`), `--effect` (tres.effect_props), `--emblem` + `--scope`, `--damage-tag`, `--set
   key=value` for any other Item.gd field (validated against Item.gd's @export vars), `--loot table[:weight]`.
   No per-field flags for the long tail (heat, revives, restores...): `--set` keeps the tool from growing a
   flag per Item field.
2. **An emblem's scope goes on as a tag** (every existing emblem carries it: `&"sigil"`...), so `new` adds it.
   Emblem must be a Modifiers.SYMBOLS key or a coloured tag; scope one of Modifiers.SCOPES.
3. **A new item's tags must already be coloured** (`new` refuses otherwise, pointing at mechanic.py): the tool
   makes no tags; that stays mechanic.py's one place.
4. **`check` validates every item**: icon present / no orphan icon (icon.check_items, reused), every property
   an Item.gd field (typo guard), slot and rarity in Item.gd's enums (read off the file, so a new rarity needs
   no tool edit), tags known (an `&"word"` somewhere in Scripts/ or Behaviours/, as skill.py's rule) and
   coloured, enchanted/honed exclusive, emblem/scope paired and valid, lent skills are Skills/ files, every
   res:// path exists. Loot tables: every entry an Items/ file, not empty, no more weights than items. Any
   `res://Items/...` named in Scripts, Scenes, Roles, Races exists.
5. **Folded in:** `skill.py check` now runs `item.problems()` (a superset of the icon lines it ran), so the
   house rule "run skill.py check" covers items. `mechanic.py check` keeps exclusivity for Skills only; items'
   moved to item.py. `item_icons_test`: `test_icon_tool_check` removed (tooling_test.test_checks now runs
   `item.py check`, which includes it) and the GDScript missing-icon loop removed (same rule, same data);
   `test_every_item_has_an_icon` renamed `test_item_reads_its_icon` (it keeps the run-time lookups).
   Left: `quality_test.test_exclusive`'s loop over Items and Skills (Godot-side, reads `Tags.exclusive`
   itself; cheap, a second guard).
6. **No new items.** The tool's test is a dry run saved under user:// and loaded by Godot, so nothing touches
   Items/ or Loot/.
7. **Stale line for the coordinator** (I may not edit `.claude/` beyond new-item): new-mechanic/SKILL.md:33
   says items are "written by hand: no tool"; it should point at new-item / `item.py new`.
8. **CLAUDE.md line** (coordinator adds): in the tool list, `new-item` (`Util/item.py`: items, their icons,
   loot tables), i.e. "`new-unit` (`Util/unit.py`, factions too), `new-item` (`Util/item.py`, loot tables
   too), `new-mechanic` ...". Names to review: none (a probe's "Zz Probe ??" only in a dry run).

## Tests (lean)
- `tooling_test.test_checks` gains "item"; `tooling_test.test_item_tool` (new): `new --dry-run` loads as an
  Item with ??, enchanted rank +1, emblem + scope tag, the lent skill, a loot entry at its weight; enchanted
  with honed refused.
- Mutation spot-checks: dropping the scope-as-tag line fails `test_item_tool`; a bad rarity on
  execute_sigil.tres fails `test_checks`. On a throwaway real item (removed): wrong field, slot, rarity,
  unknown tag, enchanted+honed, lone scope, bad scope, a lent non-skill, too many loot weights, a loot entry
  for a missing item, missing and orphan icon each reported by `item.py check`.

## As built
Util/item.py (new), Util/skill.py (check_icons runs item.problems), Util/mechanic.py (Skills-only
exclusivity), Tests/tooling_test.gd, Tests/item_icons_test.gd, .claude/skills/new-item/SKILL.md.
