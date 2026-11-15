# Checks and contests (docs/plan.md Phase 1 item 1; docs/todo/systems.md "Checks and contests")

Starting suite: 45664 checks, 0 failed (816 tests).

## Readings

- `Check.gd` is the roll (resolve / beats). Every d20-vs-d20 site builds its two `Check.side()`s by hand:
  Drown's drag and Coalescing's engulf (cast()), the `save` block (Haluca, Brainfog, Interdict,
  Phantasm, Phantasmal Force, Showstopper, Switcheroo), Sing's `_lured()`, `doubt()`, `_break_free()`,
  Record Striker (`_record()`), Flamewall's dodge, Death (vs a last stand), Hitch, Slam Jam and
  `Behaviour.Reaction.contest()`. Each picks its own tags, kinds and tie rule.
- The HUD's odds and the AI's score read `Battle.hit_chance()`, which answers 1.0 for anything not an
  attack roll: a save skill's or Drown's chance was never forecast.

## Plan

1. **One helper.** `Battle.check(a, stat, b, against, o) -> Check.Contest` rolls; static
   `Battle.odds(...)` gives the same check's chance without rolling; both build their two sides in one
   static `Battle.sides()`. Options `o`: `role` (a's kind, offensive by default; b rolls the other),
   `bonus` / `their_bonus`, `edge` / `their_edge`, `tags` / `their_tags` (check tags; b gets a's unless
   told), `penalty` x `tiles` (range penalty), `cut` (an execute's share of b), `kind` (Check.Kind),
   `ties` (a wins ties unless false). A stat `&""` is a side's bonus alone (a last stand); an Array of
   stats takes the better (Hitch). `Check.odds(a, b, ties)` is the exact sum over the d20 faces,
   advantage included.
2. **Skills declare a check.** `SkillCheck` (Scripts/SkillCheck.gd, a Resource): `stat` (empty: the
   skill's), `against` (empty: the same), `save` (a Save, else a Contest), `ranked` (+ rank impact on
   the caster's side), `edge`, `range_penalty` (per tile), `tags` (check tags), `drags_to` (won: drags
   the foe there), `suspicion` (rolled only on a foe suspicious of the caster: Sing). `Skill.check`
   replaces `save`, `resisted`, `drags_to`. `Battle.skill_opts()` turns it into helper options as cast()
   reads them (zeal, contingency, execute cut, Brainfog's slot weight).
3. **Move every site above onto it.** Death too. Left on `resolve()`: rolls against a total rolled
   earlier (investigation, the last-stand fall, Level Down's bar), which aren't two fresh d20s.
4. **Forecast.** `hit_chance()` answers a declared check's odds; the HUD's brackets and "N% to win",
   and `AI.score()`, read it.

## Calls

- Class name `SkillCheck`, field `Skill.check`: code names, no `??` (no player sees them).
- `FLAG_CEILING` 128 -> 126: three fields removed, one (`check`) added.
- The range penalty is per tile less 1 a rank past I (Drown's rule, now the general one): rank impact.
  Its distance: tiles dragged for a drag, else tiles between caster and target past the first.
- Tie rules kept per site: the actor wins, except where a rule says otherwise (Hitch: the foe; a grip:
  the holder; Flamewall: the wall). Not made uniform: each is written into its skill's text.
- Tags kept per site (Sing's foe and a reaction's attacker roll without the actor's tags).
- `doubt()`: the fooling unit's side now uses its cha check mod (defensive) rather than its bare mod,
  so defensive bracing counts on a deceiving roll, as ?68 says it should. The only number that moves.
