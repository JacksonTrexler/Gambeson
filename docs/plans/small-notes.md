# Small pieces (?57, ?60, ?63, ?68, ?80, ?82)

Six small changes the user asked for in the 2026-11 answers. Each section: what was read, the calls
made, then what was built.

## 57 Meditation: a trade between core stats

User: "meditation to only permit units to tweak core stats, they may decrease -> increase one stat
point per rank per use".

Meditate existed (`Skills/meditate.tres`, `respecs = true`): after it, each core stat could shift up
to rank *from where it was born*, independently (a free +2 everywhere was allowed at rank II).

Calls:
- "decrease -> increase" read as a trade: the points taken out pay for the points put in exactly
  (the changes sum to 0). Up to rank points moved a use (rank II: str +2, cha -2; or str +2, dex -1,
  wis -1).
- The limit is per use, not a lifetime band around birth stats: meditating again moves rank more.
  `Unit.respec` still records the running shift from birth.
- No stat goes below 1.
- Kept the earlier self-knowledge gate (a use moves no more than the unit knew itself before it,
  so Self-reflection still opens the first one). The user didn't mention it; dropping it would leave
  Self-reflection with nothing to do.

As built: `Unit.respec_by()` (zero-sum, moved <= limit, nothing below 1, all or nothing),
`Battle.respec()` unchanged but its comment, the skill's description (`Skill.markup()`), and the HUD
panel (`HUD._respec_window()`): each stat steps within room of where it is now, and Shift stays
disabled until the points balance. Tests updated: `actualization_test` (test_meditate,
test_self_reflection_first), `derived_test.test_respec`.

## 63 Magnitudes: severe, not extreme

User: "intense 2.5, severe 3". The 3 x rank word renamed from `extreme` to `severe` everywhere:
`Difficulty.MAGNITUDE`, `Glossary.TERMS` ("Severe"), `Skill.dice_scale`'s comment, Wildfire's data,
`difficulty_test`. Intense stays 2.5. No call made.
