# Balance knobs (branch w4-knobs, 2026-11-19)

The user's words: `docs/agents/answers-2026-11-19.md`, "consider optional base/symbol scaling coefficient properties" to
"apply it to an obvious skill to test the feature itself and leave it alone for now". Built on skill-modifiers.md,
w4-density.md, param*.md. Baseline suite: 10080 checks, 0 failed (957 tests). Tools, not applied defensively.

## Readings and calls (for the coordinator to number)

1. **"Impact, Range, Modified" are the scaling channels** (SkillTerms: rank impact, rank range, and the stat channels,
   which the Glossary's Range entry calls "the user's mods"). `Skill.scaling` is a coefficient per word: `impact` (rank
   impact), `range` (rank range), `modified` (both stat channels). Default 1, no effect unless set.
2. **A coefficient is a factor on the channel's k**, the one number the symbols (Density...) already multiply and every read
   (`Modifiers.rank/irank/stat`, `Skill.reach_markup`, Pricing, the behaviours that read `k`) already takes, so no new call
   site: it stacks with a symbol (x2 coefficient and Density x1.5 read x3), and shows in the numbers ("0.5 x rank").
   Under 1 a rank never reads below rank I (`Modifiers.rank`): a weaker scaling still lets rank I be rank I (without it Kick
   at rank I would reach half a tile). 0 is "nullified" as before.
3. **β (beta)**: two Glossary tags, `beta_up` ("β+") and `beta_down` ("β-"), declared with `mechanic.py tag --human`
   (the names are the user's: no ??). Every channel's k x1.25 or / 1.25 (`Modifiers.BETA`): "scaling stronger or weaker".
   All four channels, not impact alone: read literally, "scaling". Stacks with coefficients and symbols.
4. **d (Cohen)**: tags `cohen_up` ("d+") and `cohen_down` ("d-"). Rank impact reads `COHEN / rank` (1.5 / r) more or less than
   the rank itself, before k: rank I 2.5, II 2.75, III 3.5, IV 4.4, V 5.3 up; down 1 (floored), 1.25, 2.5, 3.6, 4.7. A big
   early nudge, smoothing out as rank rises. Impact only ("a skill's impact"). On whole-number reads it rounds, so d- shows
   mostly at rank II-III. First cut, untuned (BETA .25, COHEN 1.5 are the dials).
5. **No Skill.gd flag for β and d** (tags). **One field for the coefficients**, `Skill.scaling`, in the Terms group:
   FLAG_CEILING 104 -> 105, a field every skill shares, as `no_density` was (a tag can't carry a number).
6. **Secret.** No int-gated visibility existed (grep: `very high` is only the cost vocabulary; Perception's gates read wisdom,
   insight, trickery), so the minimal gate: `Modifiers.sees_knobs(u)` = int score >= `VERY_HIGH_INT` 16 (the adventurer's 16
   in every stat qualifies; a Fighter at 8 doesn't). Only the *tag* is hidden: `Skill.markup(rank, with_spec, u)` leaves
   β and d off its "Tags:" line unless u (the holder, which is the commanded unit in every HUD tooltip) sees them, and shows
   them by name with the Glossary hover (`{k:beta_up}`: "β+"). The knob terms are kind `target`, which no Guide page lists.
   Not hidden: the numbers a knob changes (a coefficient's "0.5 x rank", β's effect on a range or tier), which are true to
   what the skill does; and a *foe's* skill is never described to the player today, so "viewer" is the holder. If the user
   wants the viewer's int (HUD.eyes()) rather than the holder's, `markup` needs a viewer argument.
7. **Price unchanged by a knob.** `Modifiers.priced()` (what Pricing reads `ap_at` / `cost_at` under) drops the skill's own
   knobs: a nerf shouldn't also make a priced skill cheaper. The skill is otherwise identical in `Unit.mods(s)`.
8. **Base values too.** `Modifiers.base(s)` replaces `Modifiers.NONE` where Skill.gd describes a skill with no holder, so the
   skills screen shows a knob's numbers. `SkillTerms.knobs` caches them; `Modifiers.of` seeds from them; `empty()` stays "no
   symbols or tags", so a knob is no emblem and never labelled (`Modifiers.label`).
9. **Declared and checked through the tools:** `skill.py knob <id> [--impact|--range|--modified X] [--beta +|-|off]
   [--cohen +|-|off] [--clear]` writes the .tres (tags and `scaling`) and prints terms; `skill.py knobs` lists them with what
   rank I-V reads as; `skill.py check` runs `terms.gd knobs-check` (`SkillTerms.knob_problems()`): a coefficient on a channel
   the skill doesn't scale by, 1 or negative, an unknown word, both + and -, β on a skill that scales by nothing, d on one with
   no rank impact. `skill.py terms` gains a knobs line. `mechanic.py check` passes (colours: two, #b8a9e8 / #a9d8e8; all four
   in `Tags.PLAIN` so they never trim an icon).

## Applied: one skill each, and why

| Knob | Skill | Why |
|---|---|---|
| `scaling range = 0.5` | **Kick** | docs/plans/ai-sim.md: "Kick dominates Strike on price even in the open"; its reach grew a tile a rank (4 tiles at IV for a 4-AP kick). Now 1, 1, 1.5, 2, 2.5 tiles. Hand tests of its riders at rank II read an untuned copy (see below). |
| `beta_up` | **Gank** | the weakest of the Slayer set: major penalty, 4 AP, its dice per rank the only growth, its backing-ally gate (share 0.08) rarely met; the sim never chose it. Dice at II go 2 -> 3. Hand-priced, so the price is untouched either way. |
| `cohen_up` | **Spike** | 6 AP / 2 cost for +rank damage; the cost calculator prices it 3 AP: dear and weak early. Rank I reads as III (+2 damage), II as III, III as IV, V as itself. |

Not applied anywhere else; `modified` has no skill (no obvious one).

## As built

- `Scripts/Modifiers.gd` (COEFFICIENTS, KNOBS, BETA, COHEN, VERY_HIGH_INT; `tuned_for`, `base`, `copy`, `priced`, `sees_knobs`;
  `rank`/`irank` read cohen and the floor; `of` seeds from the skill's knobs), `Scripts/SkillTerms.gd` (`knobs`,
  `knob_problems`), `Scripts/Skill.gd` (`scaling`, the Tags line, base reads), `Scripts/Unit.gd` (`mods`), `Scripts/Pricing.gd`,
  `Scripts/Glossary.gd` + `Scripts/Tags.gd` (four tags by `mechanic.py`), `Util/skill.py` (`knob`, `knobs`, check, ceiling),
  `Util/terms.gd` (knobs, knobs-check, terms line), `Skills/{kick,gank,spike}.tres`.
- Tests: new `param_test.test_knobs` (the table: coefficients, β, d, stacking, floor, ranks I-V; the three skills through a
  unit; price unchanged on a priced skill; a symbol stacking; who sees the tag; the check's complaints). `Test.untuned(id)`
  (static): a skill without its knobs. Changed to the new rule: `kick_test` and `ai_tactics_test` read `untuned("kick")` -
  they are Kick's rider and AI rules at rank II from two tiles, not its balance, and its reach at II is now one.
- Mutation spot-checks (each failed test_knobs, reverted): `priced()` returning self; cohen ignored; the Unit.mods gate off;
  the int gate dropped; the rank-I floor dropped (caught once the table read the float `rank()`, not just `irank()`, which
  hid it).
- `skill.py check`, `mechanic.py check`: ok. Not run: a screenshot of the tooltip (text only; test reads `describe`).

## Open

- Is the holder's int the viewer? Is 16 "very high"? Are the dials (BETA .25, COHEN 1.5) right?
- A coefficient at 1 is refused; to retune a value edit it with `skill.py knob <id> --range X`.
