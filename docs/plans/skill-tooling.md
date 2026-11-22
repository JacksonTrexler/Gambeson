# Skill tooling, Kick, and CLAUDE.md

Take the repeated steps out of adding a skill, prove it on Kick, then write down how skills are
composed in under four lines. Starts once Downed is merged (Tenacity and Grudge are the worked example).

## What adding a skill costs today

- **Data only** (Strategist, Tactician): the `Skills/<name>.tres` file; in the tree file an ext_resource,
  a Branch sub_resource and an entry in `branches`. A new effect stat adds three edits in `Effect.gd`
  (enum, header comment, `TITLES`) and its reader. `progress_test.gd` lists what some classes are offered.
- **New behaviour** (most actives): a flag on `Skill.gd` (about 90 today), a branch in `Battle.cast()`
  or `_use_on_tile`, a matching branch in `Skill.describe()`, and often `HUD.why_not()` / `_forecast()`
  and the AI. The flag and its description live apart and drift.

## What to build

1. **`Util/skill.py new`**: one command that writes the `.tres` from a few arguments (name, tags, AP,
   cost, effects, tier dice), adds it to a tree after a named skill, writes a test stub, and runs the
   import. It edits text with anchors and fails loudly if one is missing.
2. **`Util/skill.py check`**, also run as a test (`skills_test.gd`): every skill is on a tree or
   granted by something, every tag is known to the Glossary, every flag set on a skill has a line in
   its description, no stub has gone stale.
3. **A behaviour seam** (seam 3 in `docs/plan-composability.md`): `Skill.behaviours`, small scripts
   with `apply(cast)` and `describe(rank)` side by side, run by `Battle.cast()` beside the flags. New
   skills use behaviours; old flags move over only when touched.
4. **An agent skill** (`.claude/skills/new-skill/SKILL.md`): when to use data alone, when a behaviour,
   the commands above, the traps (typed arrays in `.tres`, the import step, `progress_test`).

## Kick

An attack at rank range. What it does depends on the tile between the kicker and the target, read
through one behaviour (`Behaviours/kick.gd`) from `TileStack` tags. First set, open for review:
loose ground (leaves, debris, sand) is thrown up and blinds; water splashes and soaks; a trap is
kicked into the target and springs on it; an edge or hole means the target is pushed; nothing in
between, plain damage. Adjacent targets have no tile between: plain damage and a 1-tile push.

## CLAUDE.md

Under four lines: skills are data first; behaviour goes in a behaviour script with its description
beside it, never a new `Skill.gd` flag; use `Util/skill.py new` and `check`; where the tests go.

## Order

1 and 2 first (no rule changes), then 3 with Kick as its first user, then 4 and CLAUDE.md. ?88 holds
the calls made.

## Built

- `Util/skill.py new` writes the skill, a behaviour stub, a test stub, the tree branch (ext_resource,
  Branch, `branches` entry; `--after` or `--root`, `--prereq`, `--branch-tier`) and `--role` options, then
  imports and checks. `check` (about 0.1 s; `skills_test.test_wiring` runs it): ids resolve, paths exist,
  every skill reachable, tags known to the scripts (or shared by 2+ skills), `.gd.uid` present and
  committed, behaviours have both halves and a user, `Skill.gd` flags under a ceiling, no `STUB(skill.py)`
  left, the Adventurer wheel count in `hud_test` matches the data. `skills_test.test_flags_described`:
  every field a skill sets changes its description (legacy gaps listed in `UNSAID`, to shrink).
- Seam: `Scripts/Behaviour.gd` (`apply(Cast)`, `describe(rank)`, `Cast.put()`), `Skill.behaviours`,
  run by `Battle._behave()` once a skill lands (not on the early-return paths: Strike's chain, contests).
- Kick: General Martial tier 1; range rank, 4 AP, 1 Energy, 1d4 + str; the tile at the kicker's feet on
  the line: trap springs on the foe, water Soaked (movement -rank), leaves/sand/debris Blinded (offensive
  checks -rank), off-map or hole/edge/pit tags push rank; adjacent push 1. `Effects/blinded.tres`, `soaked.tres`.
- Agent skill `.claude/skills/new-skill/SKILL.md`; `CLAUDE.md`.
