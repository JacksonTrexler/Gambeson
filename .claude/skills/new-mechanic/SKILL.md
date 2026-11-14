---
name: new-mechanic
description: Add a game mechanic's building block to Gambeson - a tag (with its Glossary term), a unit property, a reusable status effect, or a new Effect stat - each in its one place, then wire the rule that reads it. Use before a skill, tile or unit needs a word or number the rules don't have yet.
---

# Adding a mechanic

1. **Find the smallest piece that says it.** In order of preference:
   - an existing **Effect stat** with tags (`mitigate` tagged `fire` is fire resistance; below 0, a
     weakness) - read `Scripts/Effect.gd`'s comments; no code at all;
   - a **tag** a rule already asks about (`grep -rn '&"<tag>"' Scripts Behaviours`);
   - a new **tag** (a word things carry, defined in the Glossary), a **property** (what a unit is made of),
     a **status** (a reusable timed effect), or a new **Effect stat** (a number a rule reads) - below;
   - new behaviour: a skill's verb is a `Behaviours/*.gd` (new-skill); a moment passives react to is a
     hook on `Scripts/Behaviour.gd`, reached by a Unit signal that Battle listens to (`taking_hit`,
     `being_healed`). Decouple through signals - no new references between Unit and Battle - and never
     a new `Skill.gd` flag.
   Named by the user: `--human`; else names get `??`.

2. **Write it:**
   ```
   python3 Util/mechanic.py tag acid --kind damage --define "Eats through armor: Defense counts half." --color "#7fd04a" [--parent physical]
   python3 Util/mechanic.py color acid "#7fd04a"   # set or retune any tag's colour
   python3 Util/mechanic.py property rotting --effect "stat=mitigate amount=-0.5 tags=fire" [--tags undead] [--text "..."]
   python3 Util/mechanic.py effect scorched --effect "stat=poison amount=0.05"
   python3 Util/mechanic.py stat word_reach --doc "tiles more its word carries (Battle.spread())"
   ```
   Every tag has a colour (`Tags.COLOR`, read by `Tags.color()`): `--color` is required unless `--parent`
   (a child takes its parent's). Pick it to sit with its family (elements by convention, the UI's
   resource and faction colours; see the table's groups); it shows on Glossary links, damage numbers and
   as trim on items carrying it (`Item.trim()`). A plain word (material, form, weight) also goes in
   `Tags.PLAIN` so it never trims. `mechanic.py check` fails a tag with no colour.
   A tag's `--kind` decides which skills a modifier of it (an emblem: "Fire Insignia") can go on, with no
   code (`Modifiers.why_not()`): `damage` - skills that deal damage; `check` - skills with an attack roll,
   save or contest (execute, taps); `condition` - skills putting effects on a target; `ground` - skills
   aimed at a tile; `target` - never. Pick the kind for what the tag acts on, and it works as a modifier
   at once (`python3 Util/skill.py modifiers` lists skills nothing fits).
   Definitions are plain sentences, no square brackets or double quotes (BBCode). Each writes a test stub,
   `Tests/<id>_test.gd` (`--no-test` to skip). A property's or unit's `--tags` are just words on it: they
   need a Glossary term only once a rule or description names them.

3. **Wire the rule** that reads it, in the one place it acts. Where things are read:
   - Defense an attack must meet: `Unit.defense(tags)` (the tags are the skill's: `Battle.hit_chance()`);
     damage taken: `Unit.hit()` / `mitigation(tags)`; any stat: `Unit.stat(&"name", tags)`.
   - Initiative: `Battle.initiative_bonus()` - a side's best unit's, floored at 0, rolled as the battle
     starts: a status lowering it mid-battle does nothing live. Check the reader for clamps like that
     before trusting a new stat or status to work; say so in a test.
   - Word of suspicion: `Battle.spread()`; perception: `Perception.unit()`; the AI: `AI.gd`.
   Grep for the neighbouring rule and read that range only. Say it in the Glossary or the reading
   function's comment, the house style.

4. **Fill in its test stub** (`STUB(mechanic.py)` until done) where it acts (a test beside the system's: `defense_test`, `word_test`...), then give it to
   what carries it (new-skill, new-tile, new-unit).

5. **Check, then run:** `python3 Util/mechanic.py check`, `python3 Util/skill.py check` (it flags tags
   the rules don't know), then the full suite.

6. **Record the calls you made** that the user didn't, for review (CLAUDE.md). The next question number
   N is one past the highest in use: `grep -rhoE '^- [0-9]+|\(\?[0-9]+\)' todo.md docs/todo | grep -oE '[0-9]+' | sort -n | tail -1` (questions are
   numbered across todo.md and docs/todo/*.md). Add to todo.md's "Built on judgement" list:
   `- N <Topic> (<date>): <each call, with the choice made>.` Put the item itself, ending `(?N)`, in the
   docs/todo file for its area (systems.md or rules.md), and add N to that file's row of the table at the bottom of todo.md.
