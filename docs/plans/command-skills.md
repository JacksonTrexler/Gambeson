# Command skills and trinkets

Leadership skills and items stand in for charisma a leader lacks.
Code: `Scripts/Command.gd` (`ally_cap()`, `order_cap()`, `cha()`), effect stats `strategy`, `tactics`,
`command_mod` (`Scripts/Effect.gd`), `Item.worth()`. Tests: `Tests/command_test.gd`, `Tests/items_test.gd`.

## The rules as built

- A leader commands max(cha mod, 1) allies a turn, max(cha mod, 1) orders each. Bonuses add on top of
  that floor: a cha -1 leader with Strategist II commands 3 allies.
- **Strategist** (passive): +1 ally a turn per rank. **Tactician** (passive): +1 order per ally per rank.
  Both on the Specialist general tree, tier 3, beside Discipline; the usual point curve, no rank cap.
- **Strategy Guide**, **Tactician's Playbook** (trinkets, uncommon): the same, by item rank.
- **Grand Design** (trinket, legendary): +1 per rank to the leader's cha mod wherever Command reads it:
  reach, party reach and size, slots, both limits, Synergy's range. The charisma stat is untouched, so
  checks and skills don't change.
- **Legendary** rarity: drop pull 0.05 (rare is 0.15); each rank is worth four of a common item's
  (`Item.worth()` = rank x 4).
- A refused order says where the limit comes from: "charisma -1, +2 from skills and items".

## Calls made on judgement (?86)

- Bonuses sit above the floor of 1, not inside it; otherwise rank I does nothing at low charisma.
- Tier 3 Specialist: only Adventurer, Bard, Rogue and Ranger have that tree natively (a Fighter or
  Paladin needs Journeyman IV). The base General tree would open the skills to every class.
- The trinkets drop from the Astral Princess, the only table with a trinket: Heart Up 21%, Heart 62%,
  the two books 8% each, Grand Design 1% (hearts were 25% / 75%).
- Grand Design is a trinket, so it can't be worn with a Guide or Playbook; it stacks with both skills.

## Left to do

- Nothing ranks items up yet, so nothing calls `Item.worth()`.
- No screenshot taken of the Specialist tree with three skills at tier 3.
