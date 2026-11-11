---
name: new-class
description: Add a class (Role) to Gambeson - writes Roles/<id>.tres, its own skill tree Trees/<tree>.tres, a placeholder sprite, puts it on the starting screen, then fills the tree with skills via new-skill. Use for any new playable or NPC class.
---

# Adding a class

1. **Pin down the design.** Its focus (martial, caster, specialist: starting stats and general trees),
   what it looks like to those who can't tell (`--noun`: Soldier, Caster, Tradefolk, Scout), its god and
   how it heals (`--tends`), what a starter wears (`--items`), and its tree: its own root(s) and which
   existing trees it borrows (`--roots`). List 4-8 skills for its own tree before writing any: names,
   one line each, which need a behaviour. Named by the user: `--human`; else names get `??`.

2. **Write the class:**
   ```
   python3 Util/role.py new <id> --focus martial --noun Brawler --tree "Open Palm" [--roots protector] \
       [--general martial,specialist] [--god ramut] [--tends loyal] [--stats "dex=14"] [--items gambeson,dagger] \
       [--look Journeyer | --color "#a08060"] [--no-entry] [--human] [--dry-run]
   ```
   It writes the class, an empty tree (`Trees/<tree>.tres`), a 20x25 placeholder sprite
   (`Units/<Name>.png` - replace it with art any time, same path), its tab colour (`SkillTab.CLASSES`,
   keyed by its shown name: rename both on review) and adds it to `Scenes/entry.tscn`. Its check names
   the empty tree until the first skill goes on - expected. `--help` shows each focus's stats.
   An NPC-only class: `--no-entry`, and add it to `NPC_ONLY` in `Util/role.py`. Choices of trees (a
   Paladin's Prowess, a Druid's biomes) and tabs are `TreeChoice`/`SkillTab` sub-resources: copy them from
   `Roles/druid.tres` or `Roles/ranger.tres` by hand.

3. **Fill its tree:** each skill through `.claude/skills/new-skill`, with `--tree <tree file>`; the first
   goes in alone. `--after <skill>` only says where a skill sits in the file: what must be learned first
   is `--prereq <skill>` - without it a skill opens from the start of the root. A class feature everyone
   of it starts with goes in `innate` (as Strike does). Moving or removing a skill has no tool yet: edit
   the tree's `branches` list and its Branch sub-resource by hand, then `skill.py check`.

4. **Test it** (`Tests/<id>_test.gd`): a unit of it (`load("res://Roles/<id>.tres")` on a villager,
   or `Battle.from_role()`), its stats, its tree offers its skills (`role.all_tabs()`,
   `SkillRoot.branch(skill)`). On the starting screen: `Tests/champions_test.gd` `test_entry` lists every
   class's name and sprite - add it there.

5. **Check, then run:** `python3 Util/role.py check` (a tree left empty fails), `python3 Util/skill.py check`,
   the class's tests, then the full suite.

6. **Record the calls you made** that the user didn't, for review (CLAUDE.md). The next question number
   N is one past the highest in use: `grep -rhoE '^- [0-9]+|\(\?[0-9]+\)' todo.md docs/todo | grep -oE '[0-9]+' | sort -n | tail -1` (questions are
   numbered across todo.md and docs/todo/*.md). Add to todo.md's "Built on judgement" list:
   `- N <Topic> (<date>): <each call, with the choice made>.` Put the item itself, ending `(?N)`, in the
   docs/todo file for its area (classes.md), and add N to that file's row of the table at the bottom of todo.md.
