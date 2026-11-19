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

2. **Say it in terms** (`Scripts/SkillTerms.gd`, `docs/plans/skill-modifiers.md`), so the cost calculator
   prices it and modifiers (the six symbols, tag emblems) can act on it:
   - **intensity** of its damage: `low`, `moderate_low`, `moderate`, `high`, `extreme` (`--intensity`,
     with `--stat` for the mod it adds; it writes the rank I tier);
   - how it **scales**, by channel: rank -> range (`--range-per-rank`, `reach_scale`, `blast`), rank ->
     impact (more tiers, `roll_per_rank`, `turns_per_rank`, `push`, per-rank effects), stat -> range
     (`radius_mod`), stat -> impact (a tier's stat, `heal_mods`, `turns_mod`, `by_mod`). Prefer these fields
     to a fixed number: a skill that scales by nothing fits no symbol;
   - a **requirement** if it's contingent ("below half HP", "within rank tiles of an ally", "from
     concealment"): `--requires "test=<test> share=<permissive share> hit= damage= edge="`
     (`Scripts/Requirement.gd`) - lambda modifiers tighten or loosen it;
   - its unique effect's **impact** (`--impact tame|impactful`) and any **penalty** (`--penalty
     minor|major|severe`), when its fields don't say (they're derived otherwise).
   It's **priced** by the calculator (`Scripts/Pricing.gd`): its terms come to points, its baseline budget.
   Its **cost profile** (`--cost "..."`, stored as `Skill.costs`; `docs/plans/w2-cost.md`) says how that budget
   is spent, in plain words - its cost is part of its identity. Turn the design's description into
   comma-separated clauses, `[level] [only|prefers] <dimension>`:
   - levels: `no`, `low`, `moderate` (the default; unstated dimensions are moderate), `high`, `very high`
     (`free`/`cheap`/`light`/`heavy`, `very heavy` too);
   - dimensions: `ap`; `cost` (whatever its tags let pay: Energy, or a reserve); or a reserve - `mana`,
     `stamina`, `focus`, `sweet nothings`. A reserve named plainly is **preferred** (paid with first when its
     holder has it); `X only` means nothing else pays (the tool writes `needs` for it). One resource per skill;
     no health costs (a mechanic first: new-mechanic);
   - rank: `flat rank` (every rank costs as rank I), `steep rank` (rank's growth doubled); default: as its terms scale;
   - `even`: the baseline (the default).
   So "high mana cost, low AP cost" -> `--cost "high mana, low ap"`; "AP heavy, cheap" -> `--cost "high ap, low cost"`;
   "a Warlock's dear curse, Sweet Nothings only" -> `--cost "high sweet nothings only"`. The words are absolute:
   "high mana" alone makes it dearer overall, "high mana, low ap" spends the same budget differently.
   Change one later with `python3 Util/skill.py cost <id> "<profile>"` (it prints AP and cost at ranks I-III);
   `cost <id> hand --ap 4 --points 2` (or `new --hand-priced --ap 4 --cost 2`) sets a hand price, with a reason. A behaviour declares its own terms in `terms(t)` and reads scaled values through its Cast
   (`c.impact_rank()`, `c.range_rank()`, `c.stat_mod(m)`, `c.tags`) - never `c.rank` or `c.skill.tags` raw
   where a modifier should reach (see `Behaviours/kick.gd`).

3. **Data or a behaviour?** If existing `Skill.gd` fields and `Effect` stats already say it (damage
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

4. **Write it:**
   ```
   python3 Util/skill.py new <id> --tags physical,blunt,str,martial --intensity low --stat strength --range-per-rank 1 --cost "high stamina, low ap" \
       [--requires "test=target_hp_below share=0.5 hit=2"] [--impact tame] [--penalty minor] [--effect "stat=luck amount=-1 per_rank=true"] [--behaviour <name>] [--passive] \
       --tree <Trees/ or Roles/ file stem> --after <skill id> [--prereq <id>] [--branch-tier N] [--role <class>] \
       [--glyph Kk] [--human] [--set key=value]
   ```
   `--help` lists the rest (`--root`, `--dry-run`). `--after` places it in the file; `--prereq` is what must
   be learned first. It writes the skill, its icon
   (`Icons/Skills/<id>.png`: its glyph or initials, white on clear - replace the PNG with art any time,
   same path), the behaviour stub (and, only for a new behaviour, its test stub), wires it onto the tree, imports, shows its terms, price and
   the modifiers it fits (`python3 Util/skill.py terms <id>` any time), then checks. The first
   skill on a new, empty tree needs no `--after`.

5. **Fill in the stubs** (`STUB(skill.py)` in the behaviour and, if it has one, `Tests/<id>_test.gd`), in the style of a
   neighbouring test. **Tests are lean:** a data-only skill (fields and effects, or an existing behaviour such as
   `heal` or `boost`) gets no test file - `Tests/sweep_test.gd` casts or applies every built skill, and a rule it
   shares with another skill (a basic tagged attack, heal or buff) is tested once, on the core mechanic, not per
   skill. Only a skill with a new `Behaviours/*.gd` gets `Tests/<id>_test.gd` (stubbed for you; `--test` asks for one
   anyway), for that behaviour's rule. Mind that the rule's existing test may be the better home. Then: `describe()` says in Glossary markup what `apply()`/the hooks do, at a rank (a
   passive's too). Markup (`Scripts/Glossary.gd`): `{k:attack}` a term (`{k:check|Checks}` in other
   words), `{o:str mod}` the user's mod, `{d:wis mod}` the target's, `{r:3}` a number growing with rank,
   `{t:3 turns}` a duration, `{x:fire}` a damage tag. Data-only skills describe themselves from their
   fields. Test cheat sheet (`Tests/Test.gd`): `v(1)`..`v(4)` villagers (1-2 Lancin, 3-4 Nemes),
   `stage(side, {unit: cell})`, `slot(skill, rank)` to learn one, `b.cast(u, skill, target)`,
   `b.read(o, t)`, `sharp(u)` (recon 3), `effect("stat", amount)`; a tier's `stat` adds the *mod*;
   which tree offers it: `SkillRoot.branch(skill)`, `SkillTab.offers(skill)`. Reusable
   statuses go in `Effects/*.tres` (`mechanic.py effect`), a new condition's name in `Glossary.TERMS`
   (`mechanic.py tag`).

6. **Check, then test:**
   ```
   python3 Util/skill.py check                               # wiring: ids, reachability, tags, uids, stubs, icons, counts
   python3 Util/skill.py modifiers                           # information: skills no modifier fits, and why - yours shouldn't be one
   python3 Util/skill.py drift                               # information: hand prices against the calculator's
   python3 Util/skill.py cost <id> "high ap, low cost"       # set or change a cost profile (check parses every one)
   godot --headless --path . -s Tests/run.gd -- <id> skills_test   # then the full suite: no words
   ```
   A new `class_name` or file needs `godot --headless --path . --import` first; a compile error hangs the run.

7. **Record the calls you made** that the user didn't, for review (CLAUDE.md). The next question number
   N is one past the highest in use: `grep -rhoE '^- [0-9]+|\(\?[0-9]+\)' todo.md docs/todo | grep -oE '[0-9]+' | sort -n | tail -1` (questions are
   numbered across todo.md and docs/todo/*.md). Append to todo.md (its append list of questions):
   `- N <Topic> (<date>): <each call, with the choice made>.` Put the item itself, ending `(?N)`, in the
   docs/todo file for its area (classes.md for a class's skill, systems.md for a general one), and add N to that file's row of the table at the bottom of todo.md.

A skill that is a trait (always on, no hotbar slot) is declared explicitly: `python3 Util/skill.py new --trait` for a new one, `python3 Util/skill.py trait <id> [--off]` for an existing one; `check` fails a trait that is a toggle, hybrid or pillar. Tags on a skill and its statuses: `python3 Util/mechanic.py carry <tag> --skills --effects --inline skill:stat`; tag `cc` on anything that impairs a unit's ability to act, `shove` only where a skill's force itself moves a unit.
