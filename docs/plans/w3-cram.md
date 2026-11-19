# Cram and caster bonus slots (branch w3-cram, 2026-11-19)

The user's words: `docs/agents/answers-2026-11-18b.md` item 5 (the Cram paragraphs); `docs/agents/answers-2026-11-19.md`
("slot count doubles under density emblem for Cram? OK. The penalties scale too: a unit's entire hotbar could end up getting
disabled"). Built on w3-traits (`bar_size()`, pillar/trait checks) and w3-exhaust (`Burnout.penalty(u, s)`).
`Cram`, `Caster Skill Slot` and `pillar` are the user's words (no ??); `bonus_slots` (the Effect stat) is the user's
"caster bonus slots" shortened.

Baseline suite: 9918 checks, 0 failed (945 tests).

## Readings

1. **"Caster Skill Slot +1 + rank" and "converts rank regular skill slots into caster bonus slots" both taken literally.**
   Cram grants 1 + rank Caster Skill Slots (the existing typed `slots` Effect, tag `magical`, the same slot Basic Magic
   Skill Slot +1 grants: they hold only caster skills) *and* converts rank of the unit's sure slots into caster bonus slots.
   Rank II: Cram takes one sure slot, adds three caster slots, and turns two sure slots into bonus slots. The other reading
   (the "+ rank" slots *are* the converted ones, no net gain) would make Cram a pure cost, against "a mage using cram to
   cast 1 or two spells a turn from an expanded list"; a third (the +rank new slots are themselves the bonus slots, no
   conversion) drops "converts regular slots" and "a unit's entire hotbar could end up getting disabled".
2. **Pillar already did half of it.** `pillar` exists (Tags, Powerful, Physical Intelligence); `Unit.disable()` already takes
   every pillar skill when one goes. So "disabled if any other Pillar skill is disabled" needed nothing new.
3. **Density composes through the one rank read.** The conversion count and the penalty multiplier read
   `mods(s).irank(rank, rank_impact)`, as `_grants()` already does for the slots granted; so a Density emblem grows the
   slots granted, the slots converted and the penalty together, and can convert a whole hotbar (capped by the sure slots
   to Cram's left).

## Calls (for the coordinator to number)

1. **One generic Effect stat, `bonus_slots`** (`mechanic.py stat --human`), tagged with the slot type, amount per rank:
   any skill or later item on the bar can convert slots of any type; nothing names Cram. Read in `Unit.bonus_slots()`
   (index -> [type, rank]).
2. **Which slots convert:** the sure slots to the converting skill's left, right to left, skipping pillar skills and slots
   already converted. "To its left" (not "the rightmost past the pillars") because an always-on passive already at the bar's
   bottom (Favour) can push Cram one slot in, and the user's "making it easier to disable skills to the left".
3. **Cram's place:** the existing generic pillar rule (last free sure slot at setup or auto-equip), not forced into the very
   last slot: a passive already at the bottom keeps its slot.
4. **A bonus slot holds anything** (bar_place accepts a non-caster); a skill there is not equipped (`equipped()` asks
   `bonus_off()`) while it lacks the type or while *any* pillar skill on the bar is disabled. Generic read over the bar's
   pillars, no Cram case. A "caster" skill = tagged `magical` (`Skill.tagged`).
5. **The penalty multiplies the whole Burnout.penalty()** (exhaustion's wear) by the slot's rank, int skill or not
   (`Unit.slot_penalty()`): a magical skill that isn't int still wears x rank there. At rank I the multiplier is 1.
6. **AI and auto-equip:** one rule, `Unit._suits()`: by itself (auto-equip, a unit setting up) a skill goes in a bonus slot
   only if it would work there. AI reads `actives` (equipped()), so it never casts from an off bonus slot. No swapping
   of skills already on the bar when Cram arrives: a non-caster left in a converted slot just stops working.
7. **Tree:** no Student tree at the tip (w3-student is making it), so Cram is on the Mage's general tree
   (`Trees/general_caster.tres`, "Caster"), tier 7, beside Elemental Mastery; `max_rank = 3` (my call), passive, priced by
   the calculator (passives: 0). Move or mirror it onto Student once that tree exists.
8. **HUD:** a bonus slot gets a dashed rim in its type's colour (purple for caster), "caster bonus" when empty, a tooltip
   (only caster skills work, none while a pillar is disabled, wear x rank, and why not now); its skill dims as a disabled
   one while it doesn't work, and clicking it says why.

## As built

- `Scripts/Unit.gd`: `bonus_slots()` (cached on the hotbar's hash, dropped by `_arrange()`; a busy flag for the Sigil
  modifier's `equipped()` call), `bonus_why()`, `bonus_off()`, `slot_penalty()`, `_suits()` (used by `free_slot()` and
  `_auto_slot()`); `equipped()` asks `bonus_off()`.
- `Scripts/Burnout.gd`: `penalty()` x `u.slot_penalty(s)`. `Scripts/Effect.gd`: the `bonus_slots` stat and its text.
- `Skills/cram.tres` + icon; `Trees/general_caster.tres`.
- `Scripts/SkillSlot.gd` (`set_bonus()`, dashed rim, brightness), `Scripts/HUD.gd` (`_refresh_bar`, `use_slot`).
- Test: `equip_test.test_cram` (one seam, 10 checks: slots granted, slots converted, non-caster off, caster works, penalty
  x rank, any disabled pillar, Cram disabled, under Density, auto-equip). Mutation spot-checks (each failed, reverted):
  pillar check dropped; `slot_penalty` 1; `_suits` ignoring bonus slots; Density ignored (raw rank); `equipped()` not
  asking `bonus_off()`.
- Visual: `scratchpad/shot_w3-cram` (a Mage with Cram II and Kick: Mana and Kick in dashed purple bonus slots, Kick dimmed;
  Cram disabled: both bonus slots and Cram dim, and the granted caster slots go with Cram, as any disabled slot-granter's do).
- Final suite: 9931 checks, 0 failed (946 tests); `skill.py check`, `mechanic.py check` ok; launch clean (only the known
  "resources still in use"). adventurer-skills merge: already up to date.

## Undone

- Cram on the Specialist Student tree (w3-student builds it): put it there, or let Student compose into Mage general.
- No swap when Cram arrives on a full bar: a non-caster already in a converted slot just stops working (call 6).
