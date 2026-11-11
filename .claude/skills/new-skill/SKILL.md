---
name: new-skill
description: Add a skill (active or passive) to Gambeson - writes Skills/<id>.tres and its icon, puts it on a tree or role, stubs its behaviour and test, and checks the wiring. Use for any new skill or any edit to which trees/roles offer one.
---

# Adding a skill

Follow the steps in order; each ends in something you can check.

1. **Pin down the design.** Say in one or two sentences what it does at rank 1 and how rank grows it,
   who gets it (a class's tree, a general tree, a role's options, a unit), and what it costs (AP,
   Energy). Is it active (cast) or passive (always on, or switched on)? If the user named it, it's
   `--human`; anything you named gets `??` (the tool marks it `ai = true`; CLAUDE.md).

2. **Data or a behaviour?** If existing `Skill.gd` fields and `Effect` stats already say it (damage
   tiers, effects, range, push...), it's data only. Anything new it *does* goes in a behaviour,
   `Behaviours/<name>.gd` (`extends Behaviour`), never a new `Skill.gd` flag (check fails past its
   ceiling):
   - an active skill's verb: `apply(c: Cast)` (runs as it lands; see `Behaviours/kick.gd`);
   - a passive's: Behaviour's hooks - `lets_word` (word of suspicion: `bandwagon.gd`), `hurt` (hits it
     takes), `healing` (heals others get: `molothrus.gd`), `affinity` (what a picked tree's skill costs to
     rank: `illusionist.gd`). A new kind of moment gets a new hook in
     `Scripts/Behaviour.gd`, called by `Battle` from a signal (`Unit.taking_hit`, `Unit.being_healed`):
     units emit, Battle dispatches - no Battle reference in Unit.
   A new Effect stat, tag or status: `.claude/skills/new-mechanic` first. Don't read `Battle.gd`/`HUD.gd`/
   `Unit.gd` whole: grep and read ranges.

3. **Write it:**
   ```
   python3 Util/skill.py new <id> --tags physical,blunt,str,martial --ap 4 --cost 1 --range-per-rank 1 \
       --tier 1:1d4+strength [--effect "stat=luck amount=-1 per_rank=true"] [--behaviour <name>] [--passive] \
       --tree <Trees/ or Roles/ file stem> --after <skill id> [--prereq <id>] [--branch-tier N] [--role <class>] \
       [--glyph Kk] [--human] [--set key=value]
   ```
   `--help` lists the rest (`--root`, `--dry-run`). `--after` places it in the file; `--prereq` is what must
   be learned first. It writes the skill, its icon
   (`Icons/Skills/<id>.png`: its glyph or initials, white on clear - replace the PNG with art any time,
   same path), the behaviour and test stubs, wires it onto the tree, imports, then checks. The first
   skill on a new, empty tree needs no `--after`.

4. **Fill in the stubs** (`STUB(skill.py)` in the behaviour and `Tests/<id>_test.gd`), in the style of a
   neighbouring test: `describe()` says in Glossary markup what `apply()`/the hooks do, at a rank (a
   passive's too). Markup (`Scripts/Glossary.gd`): `{k:attack}` a term (`{k:check|Checks}` in other
   words), `{o:str mod}` the user's mod, `{d:wis mod}` the target's, `{r:3}` a number growing with rank,
   `{t:3 turns}` a duration, `{x:fire}` a damage tag. Data-only skills describe themselves from their
   fields. Test cheat sheet (`Tests/Test.gd`): `v(1)`..`v(4)` villagers (1-2 Lancin, 3-4 Nemes),
   `stage(side, {unit: cell})`, `slot(skill, rank)` to learn one, `b.cast(u, skill, target)`,
   `b.read(o, t)`, `sharp(u)` (recon 3), `effect("stat", amount)`; a tier's `stat` adds the *mod*;
   which tree offers it: `SkillRoot.branch(skill)`, `SkillTab.offers(skill)`. Reusable
   statuses go in `Effects/*.tres` (`mechanic.py effect`), a new condition's name in `Glossary.TERMS`
   (`mechanic.py tag`).

5. **Check, then test:**
   ```
   python3 Util/skill.py check                               # wiring: ids, reachability, tags, uids, stubs, icons, counts
   godot --headless --path . -s Tests/run.gd -- <id> skills_test   # then the full suite: no words
   ```
   A new `class_name` or file needs `godot --headless --path . --import` first; a compile error hangs the run.

6. **Record the calls you made** that the user didn't, for review (CLAUDE.md). The next question number
   N is one past the highest in use: `grep -rhoE '^- [0-9]+|\(\?[0-9]+\)' todo.md docs/todo | grep -oE '[0-9]+' | sort -n | tail -1` (questions are
   numbered across todo.md and docs/todo/*.md). Add to todo.md's "Built on judgement" list:
   `- N <Topic> (<date>): <each call, with the choice made>.` Put the item itself, ending `(?N)`, in the
   docs/todo file for its area (classes.md for a class's skill, systems.md for a general one), and add N to that file's row of the table at the bottom of todo.md.
