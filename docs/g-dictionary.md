# Gambeson dictionary

Preferred terms for stubbing and naming (skills, schools, trees, tiles, units, docs). Use the term in the first column; the last column lists what not to write instead. Add a row when the user rules on a word. In-game rules text lives in `Scripts/Glossary.gd`; lore lives in `docs/g-glossary.md`.

| Term | Meaning | Use instead of |
|---|---|---|
| Arcalís | The user's word for anything arcane or magic broadly; a school is e.g. "Mortis Arcalís" | Arcane, Magic, Sorcery (as a school name) |
| ` ??` suffix | After every name an AI makes up (skills with `ai = true` show "Name ??"), until a person reviews it | an unmarked invented name |
| `--human` | The tools' flag for a name the user gave: it goes in as written, no ` ??` | |
| Energy | The default resource every unit has (`Unit.energy`, `max_energy`) | mana/stamina when no reserve is meant |
| Reserve | An extra energy type a unit holds (`Reserve` resources: Mana, Stamina, Focus, Sweet Nothings) | "second energy", "resource type" |
| Power | Energy that never regenerates on its own (Powerful units); easier to siphon | |
| Mana / Stamina | Replacement reserves: a toggle passive swaps them for Energy; Mana pays caster skills only, Stamina martial and specialist | |
| Exhaustion | Repeating a skill costs more each use (`Scripts/Exhaustion.gd`) | fatigue, spam penalty |
| Wear | What exhaustion does to a skill's price (AI code: `_wear`) | |
| Burnout | Recovering Energy or HP by any means but resting wears the pool's max | |
| Tapped | Derived, never stored: out of AP, at its order cap, or helpless with no permit; lifts when its cause does | stunned (a source of helpless, not a synonym) |
| Helpless | Can't act, move, order, dodge or guard: Stunned, asleep, or Downed without a will to fight | disabled (a skill slot switched off) |
| Downed | Down but not out: on its last life, 0 HP or below, lingers some rounds; healed above 0 it is saved | "dying", "knocked out" |
| `neutralized` | Battle signal `(u, by, how)`: u left the fight; `how` is `&"downed"` (turn-end getup), `&"down"` (Downed) or `&"killed"` | "died" for the generic case (`Unit.died` is the death itself) |
| Killed | Dead for good; one `how` of `neutralized` | |
| Ambush | An attack from concealment, or at a target that can't see or place it; effects tagged `ambush` count on it | sneak attack |
| Rank | A skill's level; many numbers grow "per rank" (`{r:}` in descriptions) | level (that is the unit's) |
| Tag | A shared word on a skill, effect or item that rules read (damage tags, kinds: martial, specialist, magical); prefer one over a bespoke flag | per-skill flags |
| Behaviour | A `Behaviours/*.gd` script giving a skill something new, with `apply()` and `describe()` | a new `Skill.gd` field |
