---
name: new-skill
description: Add a skill (active or passive) to Gambeson - writes Skills/<id>.tres, puts it on a tree or role, stubs its behaviour and test, and checks the wiring. Use for any new skill or any edit to which trees/roles offer one.
---

# Adding a skill

1. **Decide: data or a behaviour.** If existing `Skill.gd` fields and `Effect` stats already say what it
   does (damage tiers, effects, range, push...), it is data only. Anything new it *does* goes in a
   behaviour, `Behaviours/<name>.gd` (`extends Behaviour`: `apply(c: Cast)` and `describe(rank)` side by
   side; see `Behaviours/kick.gd`). Never add a flag to `Skill.gd` (check fails past its ceiling), and
   don't read `Battle.gd`/`HUD.gd`/`Unit.gd` whole: grep and read ranges.

2. **Write it:**
   ```
   python3 Util/skill.py new <id> --tags physical,blunt,str,martial --ap 4 --cost 1 --range-per-rank 1 \
       --tier 1:1d4+strength [--effect "stat=luck amount=-1 per_rank=true"] [--behaviour <name>] \
       --tree <Trees/ or Roles/ file stem> --after <skill id> [--branch-tier N] [--prereq <id>] [--role <class>]
   ```
   `--help` lists the rest (`--root`, `--set key=value`, `--passive`, `--dry-run`). It imports, so the
   `.gd.uid` files exist; commit them.

3. **Fill in the stubs** (`STUB(skill.py)` in the behaviour and `Tests/<id>_test.gd`), in the style of a
   neighbouring test. Reusable statuses go in `Effects/*.tres`, a new condition's name in `Glossary.TERMS`.

4. **Check, then test:**
   ```
   python3 Util/skill.py check                               # wiring: ids, reachability, tags, uids, stubs, counts
   godot --headless --path . -s Tests/run.gd -- <id> skills_test   # then the full suite: no words
   ```
   A new `class_name` or file needs `godot --headless --path . --import` first; a compile error hangs the run.
