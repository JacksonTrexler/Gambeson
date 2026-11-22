# w9-grave: Grave Aura (persona: undead; allied undead make no checks against it)

## Goal
User: "warlock necromancy death-cleric t3: grave aura: persona: undead. allied undead units don't make checks against persona."

## Readings
- Persona = Effect stat `persona` (rank) + Skill.shows_tags put on Unit.shows_tags by Unit._take_looks (as Alluring). No new mechanic.
- The persona check is Battle.doubt() (wis vs persona). Undead.witness (noticing) is a flat-DC check, not against persona: untouched.

## Decisions (calls)
- Skill grave_aura (`--human`, no ??): passive (not a trait tag: traits are tree-less innates, equip_test), persona +1/rank, shows_tags [undead].
- Placement: Trees/mortis_arcalis.tres (the necromancy tree; only Skeleton on it) as a second root-level branch, NOT tier 3: the tree has one skill, no chain to make tier 3. Warlock role has no necromancy tree choice.
- death-cleric tree: none exists (Cleric has the Death skill, no tree of that name): not invented, not placed.
- Rule: Battle.doubt(o, t) returns false with no check (no suspicion, no `doubted`) when o has tag undead, t.shows_tags has undead and the two factions are friends. Generic: any persona claiming undead, not just this skill.
- Holder not noticed as hostile when Disturbed-restless: not done (not required).

## Done
- Skills/grave_aura.tres (+icon), tree wiring, Battle.doubt line, Tests/undead_test.gd test_grave_aura (3 checks).
- Mutation: rule disabled -> test_grave_aura fails 2; reverted.
