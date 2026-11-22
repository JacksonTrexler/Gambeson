# w2-teststubs: Option A for test stubs (?144)

The user's answer to ?144: "A, 20/80 it. If there are functionally identical skills with different flavoring (...) should
depend on tests targeting the actual core skills and mechanics."

## Readings
- `Tests/sweep_test.gd` already casts or applies every built skill (test_passives, test_actives, test_item_skills,
  test_describes), so a data-only skill is covered the day it exists.
- `skill.py new` stubbed `Tests/<id>_test.gd` for every skill; `unit.py new` and `mechanic.py tag|property|effect|stat`
  stubbed one each; `item.py`, `role.py`, `tile.py` stub none (role.py and tile.py only print a hint).
- No `STUB(` marker was left in any existing test, so there were no untouched stubs to delete.
- 150 test files; per-skill ones either test a behaviour of their own or a rule that only has that skill as its vehicle
  (Perception, Reserve, Command, Battle._smite...). Only three held a copy of a rule another test already pins.

## Calls
1. **Stub rule.** `skill.py new` writes a test only when it also stubs a NEW `Behaviours/<b>.gd` (a skill that reuses
   an existing behaviour, e.g. heal, boost, is data-only); `--test` forces one. `unit.py` and `mechanic.py`: opt-in
   `--test` (replacing mechanic.py's `--no-test`). Their "next:" lines say where the test goes instead. A mechanic's rule
   still gets a test, just beside the system that reads it (new-mechanic step 4); the stub was the per-item part.
2. **item.py, role.py, tile.py untouched.** item.py stubs nothing. role.py and tile.py only print a hint; a class or tile
   is a rule-bearing seam (starting screen, ground), left as the user placed it.
3. **Data pins that restate the user's placement stay** (tree tiers, `after`/`needs`: megaheal `test_gated`, slam_jam's
   `test_uptree_from_jam`, persona `test_trees`): `skill.py check` doesn't know a design placement.
4. **Rule tests that merely use a skill as vehicle stay** (coordinate, drone, mindless_fury, stamina, focus, brainfog,
   haluca, smite per-god, borrowed_time, prestidigitation = the only test of Behaviours/boost.gd): the skill is the one
   instance of the rule, not a flavoured duplicate.

## Tests folded or deleted
| what | why | proof |
|---|---|---|
| `double_bluff_test.gd` deleted (1 test, 1 check) | Double Bluff is a passive `embellish +rank`; the rule "embellish puts on a front" is `Perception.fronts`, which `persona_test.test_embellish` (Embellish, the same stat) pins | mutation: drop `embellish` from `Perception.fronts` -> `persona_test.test_embellish: but it fools an ally that isn't insightful` fails; reverted |
| `megaheal_test.test_heal` + `test_megaheal` merged into one table `test_dice` (rows Heal moderate, Megaheal severe); `test_place`'s "Megaheal costs more" cost pin removed | one rule (`Behaviours/heal.gd`, d8s by magnitude), two data rows; the cost comparison is a price pin the calculator owns | mutations in `Behaviours/heal.gd`: magnitude forced to moderate -> `test_dice: Megaheal II` fails; dice count +1 -> `test_dice: Heal II` fails; reverted |
| `intervention_test.test_intervention` deleted (4 checks) | "three Bless effects", `bless` tag in the Glossary, on Eros, describe string: all data the sweep (effects land, weighed), `skill.py check` (tag known), `tag_colors_test` (every Glossary term) and `test_describes` cover; the rules (`test_seam`, `test_downed`: check-tag seam, downed regen, hale executes) stay | the kept tests build their Bless through `bless()` and read the three effects' rules; unchanged and passing |

## As built
- Util/skill.py, Util/unit.py, Util/mechanic.py as above; CLAUDE.md test line and `.claude/skills/new-skill`,
  `new-unit`, `new-mechanic` say the rule.
- Tried in this worktree and removed (nothing committed): `skill.py new` data-only wrote no test file; with a new
  `--behaviour` it wrote `Tests/<id>_test.gd`; with an existing behaviour name, none; `unit.py new --dry-run` writes none
  unless `--test`.
- All Util `check`s ok.
- `tag_colors_test.test_tool` passed `--no-test` to mechanic.py (now the default): the flag removed from its three calls.
- Suite: 8663 checks / 927 tests, 0 failed, before; 8655 checks / 924 tests, 0 failed, after (-8 checks, -3 tests: double_bluff -1 check/-1 test, intervention -4/-1, megaheal -3/-1).

## Undone
- A wider sweep for per-skill data pins (tree tiers, describe strings) across other files was left: they encode the
  user's placement decisions, not duplicate rules; a later lean pass could move them into one table.
