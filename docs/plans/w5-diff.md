# One table of difficulty words (branch w5-diff, 2026-11-19)

The user (?204): "that sounds about right. Let's standardize 'high, very high' etc with obvious synonyms, based on previous
scaling table for check difficulty: the same reference for setting difficulty checks on imposed effects, attack rolls, world
interactions etc should be used". Baseline suite: 10225 checks, 0 failed (966 tests). No balancing: nothing's number moved.

## Readings and calls (for the coordinator to number)

1. **The ladder is the reference; the five "levels" are five of its seven rungs.** Four vocabularies already counted "how
   much": the check LADDER (trivial, easy, approachable, standard, difficult, unfair, impossible), the cost levels
   (none/low/moderate/high/very high, Pricing weights 0/.5/1/1.5/2), the user's damage intensities (low, moderate low,
   moderate, high, extreme -> MAGNITUDE) and the int gate (very high). They agree by position, so `Difficulty.WORDS` maps every
   word to a rung: none = trivial, low = easy, moderate low = approachable (the user's own word for the rung between), moderate =
   standard, high = difficult, very high = unfair, extreme = impossible. Pricing's weights now hang on the rung (trivial 0,
   easy .5, standard 1, difficult 1.5, unfair 2), so every old word has its old weight; approachable and impossible have no
   cost weight and stay "no level" in a profile (no prices invented).
2. **Synonyms chosen (mine, plain words, no ??: they are words, not content names; please review)**: trivial: none, effortless;
   easy: low, light, simple; approachable: moderate low; standard: moderate, medium, normal, average; difficult: high, hard,
   heavy; unfair: very high, very hard, very heavy, very difficult; impossible: extreme, extremely high, extremely hard. The
   cost-only words (no, free, cheap, even) stay Pricing's (`level_words`), not difficulty words. Case, `_` and spacing are free
   (`Difficulty.word("Moderate_Low")`).
3. **One lookup**: `Difficulty.word(name)` (rung or &""), `Difficulty.dc()` and `formula()` take any word (so `Skill.difficulty
   = &"hard"` works), `Difficulty.index()`, `Difficulty.magnitude(word)` (the rung's place less one on MAGNITUDE: low faint, moderate low
   mild, moderate moderate, high strong, extreme severe, exactly the user's five, and very high reads intense, which no one
   had named), `Difficulty.stat_at(word)`. `SkillTerms.INTENSITY` is gone (its test reads `magnitude`).
4. **The int threshold is a named entry, not derived**: `Difficulty.STAT_SCORE := {unfair: 16}`, read as `very high`
   (`Modifiers.KNOB_SIGHT`; `VERY_HIGH_INT` is gone, `sees_knobs` reads `stat_at`). No natural mapping: as a DC, very high is
   20 flat (a Difficult flat DC happens to be 16, but "high" is difficult). The user agreed 16 is very high, so a stat
   scale of its own, filled in only as used. Other rungs read 0 (not set).
5. **Display canonicalises**: Glossary names of a skill's difficulty or a lock's `picks` / `prised` go through `word()` (Cone, Item,
   Skill's binds line, the character sheet), so a synonym in a .tres prints as its rung.
6. **Bare numbers**: Recovery Endurance's `CHECK_DC := 12` is now `&"standard"` through `Difficulty.dc()` (flat, 12: unchanged).
   Left alone, called out: Density's `DENSE_CHECK` 5 / `DILUTE_CHECK` 3 (shifts in DC points x f, not a difficulty: a rung gap is
   not constant), Stun's `roll_bonus -5` and the minor/major/severe penalties (attack-roll penalties are their own scale, "very
   difficult attack" in Stun's test is only a phrase), `Gallantry`/`Interject`/`Snapping Turtle` (contests against the attacker's
   roll, no DC; ?191 still open on a `bonus` for the latter two), Battle's wis check at standard (already a rung).
7. **`skill.py` reads the table, doesn't restate it**: `LEVELS` and `INTENSITY` are built by parsing `Difficulty.WORDS`,
   `LADDER`, `MAGNITUDE` and Pricing's `levels` / `level_words`; `skill.py check` gains `check_difficulty_words` (a skill's
   `difficulty`, an item's `picks` / `prised` must be a word). Its docstring mentions the shared words. `.claude/skills/new-skill`
   still lists the five levels (still true; not edited: `.claude/` is off limits to builders).
8. **Modifiers.eligible** still refuses only the rungs and magnitudes themselves as tags, not their synonyms: `light` and
   `heavy` are real tags (the user's examples) and must stay usable as modifiers.

## As built

- `Scripts/Difficulty.gd` (WORDS, STAT_SCORE, word, index, magnitude, stat_at; dc and formula take synonyms), `Scripts/Pricing.gd`
  (levels by rung, `level_words`, `level_weight`, `level_names`), `Scripts/Modifiers.gd` (KNOB_SIGHT), `Scripts/SkillTerms.gd`,
  `Scripts/RecoveryEndurance.gd`, display sites in `Behaviours/cone.gd`, `Scripts/Item.gd`, `Scripts/Skill.gd`,
  `Scripts/CharacterSheet.gd`, `Util/skill.py`.
- Tests: new `difficulty_test.test_words` (the synonym rows, every rung and word resolves, dc of a synonym, a snapshot of the
  old DCs at ranks 0-5, Recovery Endurance's 12, the intensities, the old cost words' weights, a profile through shared words,
  the 16). Changed to the new names: `modifiers_test` (INTENSITY -> `Difficulty.magnitude`), `param_test.test_knobs` (the
  threshold through `stat_at(KNOB_SIGHT)`, three lines).
