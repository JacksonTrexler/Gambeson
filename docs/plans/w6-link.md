# Item links: `optional` and `innate` (w6-link, 2026-11-20)

The user's words (?196, 2026-11-20): "not a bad idea, just keep them light. Armor may provide skills that can be optionally added to
hotbar in the future (`optional`), or skills that don't need a hotbar slot (`innate`). those tags are associated with an
equipment's association to a skill rather than the skill itself (Igna may be provided for no equip cost by a robe, and with a slot
equip cost on a medium armor set)".
Baseline suite: 10265 checks, 0 failed (972 tests).

## Readings and calls

1. **The flags live on the item's link.** `Item.innate` and `Item.optional` are two `Array[Skill]` fields on Item, each a subset of
   `Item.skills` (the lent-skill entry). No new Skill.gd field, no new Resource class (a per-link Resource would have changed every
   `skills =` line); `Item.link(s)` reads them (`&"innate"`, `&"optional"`, `&""`). Call: parallel arrays over a link resource,
   as the lightest way to hang a flag on a lent entry.
2. **Meanings.** plain (neither): as before, a slot, put on the bar by itself. `optional`: lent and working only once the wearer
   puts it on the bar; auto-equip, auto-fill and unit setup leave it (`_auto_slot()`, `_fill_bar()`); the spellbook offers it.
   `innate`: no slot, always equipped while worn (suppressed with traits, as Armor was), listed with the unit's traits.
3. **`Unit.link(s)` and `Unit.slot_cost(s)`.** `slot_cost()` is the one place a skill's price in slots is worked out (0 for a trait or an
   innate lend, else 1: the multi-slot card changes it there). `bar_place`, `equip_skill`, `auto_fill`, `_fill_bar`, the spellbook drag
   and the bar's drop all ask it instead of `Skill.fits_bar()`; `equipped`, `disable`, `disable_order`, `counts`, `traits`
   follow it where they asked `is_trait()`.
4. **Calls on the edges.** (a) Innate means something only for an always-on passive (nothing can work a cast or toggle without a bar
   slot yet): on an active or toggle it reads as plain, and `item.py check` flags it. The user's Igna (an active) is therefore not
   innate-able yet; that needs a way to cast from outside the bar (a question for the user, and for the multi-slot card). (b) Two worn
   items linking the same skill: innate beats plain beats optional (generosity; one armor slot makes it rare). (c) A skill learned as well
   as lent is the unit's own: the link is ignored, it takes a slot. (d) A lend that turns innate gives up its bar slot (not announced
   as lost: it still works); one that turns plain is new again and auto-equips (`_freed`, `_sync_new()`). (e) The skill's rank is
   still the best item's (`granted()`), whatever the link.
5. **Armor's own `equipment` skill is innate.** `Skill.is_trait()` no longer includes `equipment` (the tag stays: Defense, the
   Glossary, `Unit.traits()` skipping it); every armor lends Armor innate (`item.py lend armor --slot armor --as innate`, nine
   items), and `item.py check` (which `skill.py check` runs) fails any item lending an equipment skill that isn't in its `innate`:
   the old "Armor never takes a hotbar slot" hold, read through the link. `armor_skills(item)` also accepts the item's own innate
   link, so armor in a Plating slot (not in `items()`) still works.
6. **Tooling.** `item.py new --skill kick:innate|optional`; `item.py lend <skill> --as innate|optional` (also flags items that
   already lend it); `check` for a flag on a skill not lent, innate on a non-passive, both flags, equipment not innate.
7. **No demonstration item for `optional` or `innate` beyond Armor.** Hobnail Boots' Kick is an active, so only `optional` would fit,
   and that would change how the boots play (Kick no longer auto-equips): a design call, not made. Armor is the innate example.

## Tests

`Tests/lent_test.gd` gains `test_links` (one test, 24 checks): plain, innate (off the bar, working, traits list, not disableable,
traits suppressed), the same skill swapped between items, innate on an active reading plain, optional (off the bar, auto-fill
leaves it, placing it works), plain beats optional, a learned skill ignores the link. `lender()` flags equipment skills innate.
Changed to the new rule: `Tests/equip_test.gd` (the trait list loses `armor`: Armor is innate by its link, not a trait),
`Tests/lent_test.gd` (Armor "fits no hotbar slot" now reads `slot_cost`), `Tests/test.gd` (`bulwark()` lends Armor innate).
Mutation spot-checks (each failed `lent`, then reverted): `slot_cost` ignoring the link (9 fail); `_auto_slot` not skipping optional (2).

## As built

Scripts/Item.gd (`innate`, `optional`, `link()`), Scripts/Skill.gd (`is_trait()`, comments), Scripts/Unit.gd (`link`, `slot_cost`,
`equipped`, `_auto_slot`, `auto_fill`, `bar_place`, `equip_skill`, `_fill_bar`, `_sync_new`, `_sync_granted`, `_freed`, `traits`,
`disable`, `disable_order`, `counts`, `armor_skills`), Scripts/SkillEntry.gd, SkillSlot.gd, SkillDetail.gd, nine Items/*.tres armor,
Util/item.py, Util/skill.py (docstring), Tests/lent_test.gd, equip_test.gd, test.gd.
Not done: an innate active (casting without a slot); no item uses `optional`; `SkillTerms` and `Skill.describe()` still decide
"Trait" from the skill alone (Armor reads "Always on" now, which no screen shows).
