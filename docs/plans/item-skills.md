# Skills on items (u-itemskills, 2026-11-14)

Plan.md Phase 4 item 11, and the systems.md todos "Skills on items" and "Urlo's enchantments, the rest".
Baseline suite: 45664 checks, 0 failed (816 tests).

## Readings and calls

1. **`Item.skills: Array[Skill]`** are granted while the item is worn. `Unit.slots` is the old merge (role,
   innate, learned: now `Unit._own()`) plus `Unit.granted()`: one `Slot` per skill, built from the worn items
   and cached in `_granted` (keyed by skill, so a toggle's `on` survives an enchantment swapping the item
   for a copy; the entry goes with the item, so re-wearing it starts the toggle fresh). The slot carries
   `Slot.from: Item`, the flag meaning "on loan": non-null means it can't be ranked.
2. **Rank.** A granted slot's rank is `Item.skill_rank()`: `ranked()` (rank + enchanted/honed + Pray's
   enchant on a trinket) and +1 more when Pray's numeric `enchant` is on a weapon or armor (so an enchanted
   weapon's skills rank up without Pray also raising armor drag, the open question in item-ranks.md).
   Capped at the skill's `max_rank` when it has one.
3. **No ranking.** `raise`, `can_raise`, `raise_cost`, `points_in` and `unlock` read `_own()` only
   (`own_rank()`), so an item skill is never raised and never costs points. Where a skill is both learned
   and granted, the higher rank wins (a tie goes to the learned one); `rank()` reads whichever wins.
4. **On loan doesn't count as learned.** Prerequisite counts (`missing`'s learnt count, `_learned_on`,
   `_general_need`) read `_own()`: lending a capstone's skill doesn't open the capstone. `options()` still
   skips what it has (`rank > 0`): you can't buy what you wear. Call.
5. **The hotbar.** `refit()` (every equip, unequip, enchant) runs `_sync_granted()`: a newly granted skill
   goes into the first free slot that fits (if any; otherwise it's in the spellbook, draggable); a skill that
   is no longer held comes off the bar. At setup `_fill_bar()` sees them like any other slot.
6. **Mid-channel / mid-toggle.** `Unit.lost_skills(u, skills)` is emitted when granted skills go; Battle
   listens and `end_channel()`s a channel whose skill went (a Rift's count starts, as always). A toggle's
   state goes with its slot; a Mana-like switch in progress is a channel, so it just ends (nothing was
   moved yet: carry-over happens as it completes). A passive that was switched on stops working with the item
   (effects read `on_passives`), so a worn "Mana" passive going off returns the unit to running on Energy.
7. **Burning Bag** doesn't grant skills, only typed/plain slots (`slots` effect); `burning_slots()` already
   reads `granted_slots()`. Left alone: item skills fill the bag's slots like any other skill, so a burning
   bag and an item skill compose (a skill in a burning slot burns).
8. **Urlo's enchantment** (`Unit.enchant()`): weapon, armor, then trinket. `Item.scales()` says whether
   there's anything to scale: a weapon or armor always does (+1); a trinket does if it carries skills, a
   rank-scaled effect, revives, heat, burning, an emblem or an `enchanted_as`; **Heart Up, Heart Up-Link
   (hearts only) and the like are skipped** (a +1 rank would change nothing), and don't use up Pray's count. An item's
   own `enchanted_as` is used if it has one; else weapons/armor take the numeric +1 and a trinket takes
   enchant = 1, which `ranked()` reads as rank +1. `disenchant()` already clears `enchant`.
9. **Modifiers.** Emblems read `Unit.mods(s)` per skill and Sigil walks `u.hotbar`; item skills sit on the
   hotbar so they need nothing special (a worn-emblem mark and a granted mark are separate).
10. **Hotbar mark.** `SkillSlot.granted` draws a small clasp (a short pip at the slot's lower-left edge,
    cool silver-blue) distinct from the gold `modded` diamond at upper right; the tooltip says "From <item>".
11. **Example item:** "Tinderbox ??" (an AI-named trinket, tag fire?) granting an existing skill; see as built.
