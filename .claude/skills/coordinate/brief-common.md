# Common brief for Gambeson builders (2026-11-12)

S = the host session's scratchpad (the host gives the absolute path in each prompt)

## Where
- Work ONLY in your own worktree `S/wt-<name>` on branch `<name>` (given in your prompt). Never touch `/Users/jtrex/projects/Gambeson` (the user and other sessions edit it). Never push.
- Read `CLAUDE.md` in your worktree first. It is the house guidance: new content only through the tools and processes in `.claude/skills/` (`new-skill` / `Util/skill.py`, `new-mechanic` / `Util/mechanic.py` for tags, statuses, properties, Effect stats, `new-class` / `Util/role.py`, `new-unit` / `Util/unit.py`, `new-tile`); `--human` for names the user gave; " ??" after any name you make up; Unit, Battle and HUD talk through signals; big files (Battle.gd, HUD.gd, Unit.gd) grep and read ranges, never whole.
- Prior plans live in `docs/plans/*.md`; read only the ones your prompt names.

## Design principle from the user (verbatim, applies to every call you make)
"please feel empowered to make any composability calls that would enable future development / emerging gameplay, players should be delighted in finding powerful new synergies and creative approaches to solving problems during their runs, as long as we don't over-abstract. I'd like to keep 'unit does a thing and gets a hoagie token, which is only used for hoagie skills' to a minimum. skills that give benefits / negative effects to units with certain tagged debuffs ('love', 'cursed', 'light', 'heavy metal') are fine, there may be skills that apply them to a wider range of skills than usual. Basically: it's better for unintended interactions to happen compared to sandboxed and boring but tightly coupled systems."
So: prefer shared tags and one generic hook over a bespoke counter or a one-off flag; let a rule read tags on whatever it meets, so later content joins in without knowing about you.

## Tests
- `godot --headless --path . --import` once first, again after adding a script with a class_name or new art.
- ALWAYS wrap runs in `caffeinate -dims` (on battery the Mac sleeps and a 40 s run takes 30 min).
- Targeted: `caffeinate -dims S/t.sh S/wt-<name> <words>` (words match `file.test_name`). Full (~60 s): `caffeinate -dims S/t.sh S/wt-<name>` (ends "N checks, M failed (T tests)"; must end at 0 failed; note the starting count first). It hangs on compile errors; t.sh kills the run and prints them. There is no `timeout` command on this Mac.
- Existing tests that encode a rule you were asked to change: update them to the new rule, never delete or weaken them; list them in your report.
- Before your last commit: every Util tool `check` you touched plus `python3 Util/skill.py check`, then `godot --path . --quit-after 120 > S/launch-<name>.log 2>&1` and grep it for ERROR (only "N resources still in use at exit" is known and fine).
- Visual changes: capture frames per `/Users/jtrex/.claude/projects/-Users-jtrex-projects-Gambeson/memory/visual-check-godot-ui.md` (adapt the newest `S/driver*.gd`; load Battle.gd before Game.gd in the driver) into `S/shot_<name>/` and look at them.

## Lean tests (the user, 2026-11-14: "a lot of tests for not a lot of game")
- Hardware (the user, 2026-11-16): tests run on an M3, about 4x the target consumer device. Lean on the hardware over test count: one larger sim (`Tests/sims/`) beats many small tests; budgets at target speed = M3 time x 4.
- Prefer extending the shared coverage over new files: `Tests/sweep_test.gd` (every skill cast or applied), table tests (`Tests/capstones_test.gd`), tool `check`s for wiring. One test per seam (rule), not per content item.
- A stub `Tests/<id>_test.gd` that `skill.py new` writes for a data-only skill the sweep already covers: delete it. Keep a file only for a behaviour's own rule.
- Prove a test earns its place: break the rule, see it fail, revert (a mutation spot-check). List them in your plan.
- Logic: lift one-off code into a generic hook or data where it's cheap; don't add per-skill branches in Battle, AI or HUD.

## Docs and commits
- Do not edit `todo.md`, `CLAUDE.md` or `.claude/`. In `docs/` write only your own `docs/plans/<name>.md`: your readings and calls first, then "as built". Every judgement call goes there; the coordinator turns them into questions.
- Commit early and often on your branch, one-line messages ending with a blank line and the trailer `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`. Commit new `.gd.uid` / `.import` files too.

## Report
Under the word limit your prompt gives: what was built, every judgement call, tests changed, files touched, the suite's final line, commit hashes, anything undone.
