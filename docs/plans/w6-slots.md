# Multi-slot skills (w6-slots, 2026-11-20)

The user's words (2026-11-20): "Multi slot skills: some skills take up multiple slots. if no slots property / tag is specified it's default 1 /
restricted as usual (martial skills may use martial bonus slots etc). Skills with a rarity take up multiple slots by default: Rare: 2,
Epic / Very Rare: 3, Legendary: 4, Mythic: 5" and "most often, this will come up for high tier skills that need to be nerfed in some fashion."
Baseline suite: 10279 checks, 0 failed (973 tests).

## Readings and calls

1. **Skills have no rarity today.** Only `Item.rarity` (an enum: common ... mythic) exists; no skill carries one. So the rarity is a set of
   shared tags, named as the user wrote them (`--human`, no ??): `rare`, `epic`, `very_rare` (a child of `epic`, so it counts as it; shown
   "Very Rare"), `legendary`, `mythic`. Glossary terms (kind `target`: never a modifier's target), colours, and in `Tags.PLAIN` (never
   trim an item or stripe the hotbar). `Skill.RARITY_SLOTS` maps them to 2, 3, 4, 5. Call: tags over a Skill field (the user: "slots property /
   tag"; `Item.rarity` stays an enum, not unified with these: a later call). Two rarity tags on one skill: the dearer wins.
2. **The explicit override is a behaviour, not a field.** `Behaviours/slot_cost.gd` (`@export var slots`) answers a new `Behaviour.slots_taken()`
   hook; it stands over the rarity either way (1 on a rare skill makes it ordinary; 3 on a plain one makes it dear). No new Skill.gd field, so
   no `skill.py ceiling`. Its `describe()` says the cost. Call: a behaviour over an Effect stat (an active's `effects` go on its target, so an
   Effect on one reads wrongly) and over numbered `slots_2` tags. `skill.py check` allows it to have no skill using it yet
   (`UNUSED_OK`): the user's first nerfed skill will be the first.
3. **`Skill.slots_taken()`** is the skill's own price; **`Unit.slot_cost(s)`** (the one function w6-link made) is the unit's: 0 for a trait or an
   innate lend (so a rare passive lent innate costs nothing), else `slots_taken()`. A **pillar always takes 1** (call): pillars are pinned to the
   last sure slots one at a time; a rare pillar skill (Cram) isn't made wider by the tag.
4. **Representation: first slot only.** The hotbar stays an `Array[Skill]` of ids: a multi-slot skill is in its first slot and the slots after
   it hold `null`, "covered" (`Unit.covered()`, cached by the bar's hash; `anchor(i)`, `skill_at(i)`, `slot_free(i)`, `span(s)`). Call: not the
   skill repeated in each slot. Everything that walks the hotbar for skills (Sigil, Chaser, Command, `disable_order`) keeps seeing it once, and a
   save keeps ids as before: `get_equipped()` / `set_equipped()` round-trip it with no change to Save, Game or `to_dict` (w6-party).
5. **A run of slots, of one kind.** Placing needs `_run_ok(s, i)`: the slots from i exist, work, fit the skill (typed slots hold their type) and
   share one *kind of slot*: all sure slots, or all one granting skill's slots (Cram's three caster slots are one run; two Magic Slot skills'
   are not), never across the clover slot. Call: the source restriction comes from `_arrange()` keeping each granting skill's slots as one
   queue; allowing a run across two grants would mean re-sorting by span.
6. **Placing, displacing, swapping.** `bar_place(s, i)`: s takes the run from i; every skill with a slot in it (spanning it or sitting in it)
   comes off, announced. A skill already on the bar that lands on exactly one skill swaps with it as before: that skill takes the slots s left
   if it fits them there, else it comes off. A pillar in the run refuses. `bar_clear(i)` on any covered slot clears the whole skill.
   `free_slot` / `_auto_slot` (auto-equip, auto-fill, `_fill_bar`, `equip_skill`) look for a free run: actives the first, passives the last.
   A skill with no run on the bar stays learned, unequipped (the spellbook still lists it); a drop that fails says so.
7. **The sort (`_arrange()`).** Slots come and go (a level, a granting skill, a Density emblem). A multi-slot skill goes through the sort as
   that many copies, side by side, and `_gather()` puts back one first slot or, if any copy was cut off, takes it off the bar whole (announced).
8. **Working.** `equipped(s)`: every slot of its run is unsealed and not idling in a bonus slot. In **Cram's caster bonus slots**, a skill
   spanning them works only if it carries the type for each slot (`bonus_why(i)` asks the skill that has slot i, covered or not); its Burnout wear
   is the highest bonus rank among its slots (`slot_penalty`). Placement accepts a bonus slot (it holds anything), as before.
   **Density** doubles what a skill's rank grants (slots, bonus slots, wear) and leaves its price alone: a rare skill costs 2 under any emblem (call;
   a cost that scaled with rank_impact would be a different nerf). A burning slot (`Battle._burn`) burns a skill once if any slot of its run
   burns.
9. **Disabling.** One multi-slot skill is one entry in `disable_order()`, so one slot's worth disables it whole (`disable()` was already by
   skill). Call: a disabling effect counts slots as it ever did (one group per slot of its ordering), so a 3-slot skill is *cheaper* to reach
   than three 1-slot ones: part of the nerf, and a number to tune later (`slot_weight` is rank alone).
10. **HUD.** A covered slot shows "(continued)" dimmed with the skill's stripe and a tooltip naming whose it is (`SkillSlot.cover`); a
    number key or click on it uses the skill; right-click unequips it whole; a drop is `bar_place` on the slot clicked (the skill's first slot).
    A failed multi-slot drop says "takes N slots side by side". The skill's tooltip says "Takes N hotbar slots ..." (`Skill.slots_line()`, from the
    rarity in `markup()`, from `SlotCost.describe()` when it sets the number). Guide hotbar text gained a sentence. Kept simple: no wider slot.
11. **AI.** It places nothing (it reads `actives` / `kit`, which follow `equipped()`); NPC and monster bars set up through `_fill_bar()`, which
    now looks for runs, so a multi-slot skill on a unit with no run is simply left off.

## Existing content

No skill carries a rarity tag or SlotCost, so **0 existing skills take more than one slot** and no bar overflows today. Nothing re-tiered.
For the user: with 4 sure slots at level 1 (5 at level 4), a Mythic skill (5) can't go on a bar before level 4 and a Legendary (4) takes
the whole of a level 1 bar: whichever skill is tagged first decides whether that is meant.

## Tests

`Tests/equip_test.gd` gains `test_multi_slot` (30 checks, one test): the price table (every rarity, SlotCost over it, pillar, two rarities),
the description, free-run placement, covered slots, drop and swap and displace, the save round trip, clearing from any slot, the sort (slot
more / fewer, a cut run drops whole and is announced), the disabling order and a disabled skill, the HUD's covered slot and its clear,
innate link (free) vs plain (full price), typed slots, Cram bonus slots (a skill idles if a slot lacks the type; penalty x rank; auto-placement
leaves a bad run), Density leaving the price alone. No test changed to a new rule; the sweep's `test_describes` holds `slot_cost.gd` to a
description. Mutation spot-checks (each failed `equip_test.test_multi_slot`, reverted): `slot_free` ignoring covered (2 fail); `_gather`
not dropping a cut run (2); `equipped` reading only the first slot (1); `bar_clear` not finding the anchor (crash).

## As built

Scripts/Skill.gd (`RARITY_SLOTS`, `slots_taken()`, `slots_line()`, `markup()`), Behaviour.gd (`slots_taken()` hook), Behaviours/slot_cost.gd, Tags.gd,
Glossary.gd (five tags), Unit.gd (`slot_cost`, `covered`/`anchor`/`skill_at`/`slot_free`/`span`, `_run_ok`, `_room`, `free_slot`, `_auto_slot`,
`bar_place`, `bar_clear`, `equipped`, `bonus_why`, `slot_penalty`, `_arrange`/`_gather`), Battle.gd (`_burn`), HUD.gd (`use_slot`, `_refresh_bar`,
`_on_dropped`), SkillSlot.gd (`cover`), Guide.gd, Util/skill.py (hook, `UNUSED_OK`), Tests/equip_test.gd.
Not done: runs across two granting skills' slots; a wider slot in the HUD; `Item.rarity` as the same tags; a way to tag or SlotCost from
`skill.py new` (edit the .tres; it is data); `ai` placement of a multi-slot skill beyond auto-fill.
