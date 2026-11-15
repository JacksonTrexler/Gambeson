# Dissonance by how far the lie is (y-dissonance)

Source: docs/todo/systems.md ("harder to pretend to be something you very much aren't: a wolf in
sheep's clothing, not a scary dog"), docs/plan.md Phase 5 item 17, docs/queue.md Wave 1.

## Readings
- Before: `Unit.dissonance()` counted 1 per thing the persona put forward at its rank (each vibe word;
  stance and claimed level; each identity tag and the alias), +1 each for Embellish and Brood, plus
  `extra_dissonance`.
- It feeds three places, unchanged: `Perception.insight()` (1: pretending; 2+: what it pretends),
  `Unit.dissonance_penalty()` (minus a practised look's rank) into `Battle.doubt()` and the
  investigation contest in `Battle.gd` (no edits there).
- What a unit "is": `vibe` (comma words), `bio.adjectives`, `Perception.kind_noun()` (appearance,
  class noun, Beast, Everyman), `tags`, `race.name`, `aura`.
- docs/plans/silhouettes-glow.md and clairvoyance.md: nothing on dissonance.

## Calls (first guesses, all for review)
1. **Distance per claim** (`Perception.lie()`): true (the claim is one of its own words) 0; near
   (shares a nature with any own word) 0.5; far (a nature opposed to any own word's) 1.5; anything else,
   or a word the table doesn't list, the default 1 - so unknown content behaves as the old tally. Near
   beats far when both apply (a siren claiming "serene" while it is "calm" would be near).
2. **Sum rounded up**, so any lie at all still reads as at least 1 ("pretending").
3. **Natures ??** (the similarity table, `Perception.NATURES`, `OPPOSED`): gentle ??, fell ??, fair ??,
   foul ??, bright ??, dead ??, holy ??, unholy ??, hot ??, cold ??, wet ??, folk ??, beast ??, made ??,
   small ??, big ??, calm ??. Opposed pairs: gentle-fell, fair-foul, holy-unholy, holy-dead, bright-dead,
   hot-cold, folk-beast, folk-made, small-big. Covers the persona panel's VIBES and TAGS, Bio adjectives,
   class nouns and the shipped scenes' vibes and tags. Internal keys, not shown to players.
4. **Aura joins the truth** as "ominous" (below 0) / "benevolent" (above 0), so a benevolent unit
   claiming "menacing" is far and an ominous one claiming "harmless" is far.
5. **Stance** stays a flat 1 (a side has no nature to measure). **Claimed level**: its own 0, within 1
   near, 2-3 default, 4+ off far. **Alias**: the worse of its words (adjective, noun). Embellish and
   Brood stay 1 each; `extra_dissonance` added after rounding.
6. **Glossary term "Dissonance"** (an existing in-game word, not a new name) with the rule in a line;
   Alluring's description links it. Colour #c9a0dc via `mechanic.py color`.
7. **Balance, a question**: the Siren (briny, hungry monster claiming harmless, serene, safe,
   beautiful, holy) goes from dissonance 7 to 9, its penalty after Alluring IV from 3 to 5 - exactly
   the wolf in sheep's clothing, so its lure is doubted more often. Left as is; if it's too much, LIE_FAR
   1.25 or a practised look cutting more are the knobs.

## As built
- `Scripts/Perception.gd`: NATURES, OPPOSED, OMINOUS_WORD, BENEVOLENT_WORD, LIE_* constants; `lie()`.
- `Scripts/Unit.gd`: `dissonance()` sums `lie()` per claim; `true_words()`.
- `Scripts/Glossary.gd`, `Scripts/Tags.gd`, `Scripts/Skill.gd` (Alluring's line links the term).
- Tests: `persona_test.test_dissonance_distance` (truth, near, far, fallback, the wolf vs the scary
  dog, tags, claimed level). Updated: `persona_test.test_insight` (Siren 7 -> 9, penalty 3 -> 5);
  `lure_test.test_stall_lifts` pins the Siren's lie 2 easier (`extra_dissonance = -2`) so the seeded
  doubt roll doesn't see through it - that test is about stalls, not doubt.
- Mutation spot-checks (each failed the new test, then reverted): near -> default; far -> default;
  unknown word -> 0; no "true" short-circuit.
