# Lent skills: enchantment, armor as equipment, prerequisites (w3-lent, 2026-11-18)

The user's words (answers-2026-11-18b, item 8, first half, ?143): the item is enchanted, so the skills it lends are enchanted too
(+1 rank unless a lent skill has its own explicit enchantment effect); the armor effect is an `equipment` skill the item lends,
generally one granting +armor; lent skills count as prerequisites, and if the unit loses one for any reason (item unequipped,
disabled, traits suppressed) the skills that depend on it are disabled too.
Baseline suite: 9756 checks, 0 failed (936 tests).

## Readings and calls

1. **Enchanted lends (a).** Already so for +1 rank: `Item.skill_rank()` is `ranked()` plus 1 for Pray's enchant on a weapon or
   armor (a trinket's is in `ranked()`; an item tagged `enchanted` has it in `ranked()` too). Pray never raised an armor's own rank,
   so drag stays; an item authored with the tag `enchanted` still does (item-ranks.md, unchanged). New: the exemption. A skill with
   its own enchanted effect keeps the item's plain rank: `Behaviour.owns_enchant()` (one generic hook, `Skill.enchants()` reads
   it), applied in `skill_rank()` as -1 for an enchanted item. Call: the "explicit enchant effect" is a behaviour hook, not a new
   Skill.gd flag or an Effect field. Armor is the first user (call 3). An item's own `enchanted_as` stays the item-level form.
2. **`equipment` tag (b).** Declared with `mechanic.py tag equipment --human --kind target` (the user's word: no ??). Colour
   `#a7a79a` (grey, beside trait): my pick.
3. **Armor is a skill.** `Skills/armor.tres` ("Armor ??", passive, tagged `equipment`, `ai = true`) with `Behaviours/armor.gd`
   (new hook `Behaviour.armor(holder, rank, item)`, `NO_ARMOR` default). The formula moved out of `Unit.armor_defense()` into it
   unchanged; `armor_defense()` now adds up what the equipment skills the worn armor lends set (`Unit.armor_skills()`), and with none
   working is unarmored (dex mod + con mod). Armor owns its enchantment: +1 Defense when the item `enchanted()` (it used to be
   `armor.enchant`, Pray's count). Calls: (a) an armor authored with the tag `enchanted` now gets +1 Defense as well (it got
   only the rank before; no item in Items/ is one); (b) the skill is not ranked up by the enchantment (call 1); (c) the item's
   other fields (weight tag, `no_dex`, `full_dex`, `mind_stat`, `eases`) stay on the Item, read by the behaviour: the table is
   data on the armor, the skill is the carrier. Power Armor and Scrap Plating can sit another equipment skill beside it, or cap what
   it sets; `armor_defense()` sums them. `mind_stat` (Robe's magical Defense) and `tagged_defense()` follow `armor_skills()` too.
4. **Equipment behaves as a trait.** `Skill.is_trait()` is true for it (always equipped, no hotbar slot, not disabled by skill
   disabling), so *traits suppressed* takes armor's Defense away: the user's own example of how a lent skill is lost. It is not
   listed in `Unit.traits()` (the HUD trait strip would show every armored unit's Armor); `Skill.is_equipment()` says which.
   `Tests/equip_test.gd` listed the skills that are traits: Armor joined.
5. **Migration.** `Util/item.py lend armor --slot armor` (new subcommand: lend a skill to every item of a slot, or `--ids`)
   wrote it onto all nine armor items in one table-driven step; `item.py check` now fails an armor lending no equipment skill. There
   is no fallback for an armor with none (it sets no Defense): hand-built test armor gets it (`Tests/test.gd: bulwark()`). Also
   `skill.py new --lent` (a skill only items lend: on no tree or role) and "armor" among skill.py's hook names.
   Proof the behaviour is identical: Defense of all nine armors at level 1/9/30 x dex 6/10/14/20, plain and Pray-enchanted, and
   Robe's magical Defense, matched between the old tip (28ae12a) and this (114 lines, same); `lent_test` pins the corners.
6. **Prerequisites (c).** One read: `Unit.counts(x)` (it has x: learned, or lent and working: lent, not in `disabled`, not a
   trait while traits are suppressed). `reached()` (a branch's `after`), the root's `needs` count, the general tree's tier and
   category needs and `min_tier` read it, so a lent skill opens exactly what a learned one would. What was learned on a lent skill
   is marked at unlock (`Unit.leaned`, by asking `missing()` with nothing lent: `_bare`); `lapsed(s)` (which already stopped
   waiver-learned skills, and `actives` / `passives` already read it) is now also true for a leaned skill whose prerequisites no
   longer hold. No per-skill code. Dependents of a lapsed skill lapse too (a lapsed skill doesn't count, and was marked
   because the bare read doesn't count what was learned on a lent one). A skill learned with its prerequisites on its own never
   leans. It is all dynamic: the lent skill back, the skill works again. Calls: (a) a lapsed skill keeps its rank and its slot, it is
   only switched off (like a lapsed waiver); (b) authored units (scenes) never lean (only `unlock()` marks), so an NPC that has a
   skill without its prerequisites isn't switched off; (c) `lapsed()` reads no effects (they read it): `counts()` reads raw slot
   ranks and `_skippable()` (Reckless Abandon) stands down while `_judging`, so a unit leaning on a lent skill doesn't get Abandon's
   skipped steps in that judgement (rare; noted); (d) `Unit.leaned` isn't saved (nor is `waived`); a loaded unit that learned on a
   lent skill won't lapse when it loses it (saving doesn't carry it yet); (e) Pray's enchant on a lent prerequisite doesn't
   matter (rank only). Respec (taking a purchase back) doesn't exist, so `leaned` has no removal.

## Tests

- `Tests/lent_test.gd` (new, 3 tests, 72 checks): enchanted lends (slot x how, table); Defense of every armor pinned from the old
  rule, Armor beside suppression and no armor; lent prerequisites (a chain and a count, three ways of losing, and back).
- Changed: `Tests/test.gd` (`bulwark()` lends Armor), `Tests/equip_test.gd` (traits list gains armor), `Tests/sweep_test.gd`
  (`test_item_skills`: a passive lent skill is checked as one, armor slot cleared first).
- Mutation spot-checks (each failed the new test, then reverted): lent skills never count; leaned never lapses; no `owns_enchant`
  exemption; Armor's +1 removed; `disabled` not read by `counts()`.

## As built

(filled in below at the end)
