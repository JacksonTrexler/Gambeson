---
name: new-unit
description: Add a unit (an NPC, monster or champion) to Gambeson - writes Scenes/<id>.tscn with its bio (behaviour, appearance, adjectives, properties, clout), stats, skills and a placeholder sprite, optionally a faction of its own and a place in a battle. Use for any new unit or side.
---

# Adding a unit

1. **Pin down the design.** Who it is in a line or two (its bio text), then its bio (`Scripts/Bio.gd`):
   - **behaviour** - its AI's temper: `timid` (waits for a stronger ally, backs off the aggressive),
     `brave` (charges the strongest), `aggressive` (presses the weakest, heals last), `helpful` (goes to
     the wounded to heal them), `stoic` (holds, striking only what comes). A new temper is code: Bio.BEHAVIOURS,
     AI.act(), Util/unit.py's BEHAVIOURS - ask first.
   - **appearance** and **adjectives** - how it looks to whoever can't make out its class ("Injured
     Soldier"); the AI guesses from them (Bio.STANDING, Bio.ADJECTIVES: Knight reads stronger, Horrific
     ominous, Injured hurt). Words outside those tables are flavour.
   - **properties** - what it's made of (`Properties/*.tres`: Aquatic, Energized, Radiant, Rotting),
     always on it: resistances, weaknesses. A new one: `mechanic.py property` (new-mechanic).
   - **clout** - standing with sides (`lancin=2`): its persona goes further with that side, its lies
     with its foes, and doubting it is harder.
   Then its class and level - or, for a monster (no class): `--tags monster` (it reads as a Beast),
   `--level`, `--hp`, stats, and every skill it uses including `--skill strike:1` (a class gives Strike;
   nothing else does). Its side. Named by the user: `--human`; else it gets `??` (shown through its nick).

2. **A side of its own?** `python3 Util/unit.py faction <id> --name ... --color "#rrggbb" [--allies ...] [--human]`.

3. **Write it:**
   ```
   python3 Util/unit.py new <id> --name Blinthe --human --role bard --level 16 --faction unaligned \
       --behaviour timid --appearance Minstrel --adjectives Beloved --properties rotting --clout lancin=3 \
       --skill bandwagon:3 --skill persona:3 --stats "cha=18" [--bio "..."] [--color "#b07acc" | --look Doebour] \
       [--into museum --at 5,3 --side nemes] [--set key=value] [--dry-run]
   ```
   `--help` has the rest (tags, vibe, aura, tends, strategy, intention, hp, energy). A class unit takes
   its class's sprite unless given `--color` (a 20x25 placeholder, `Units/<Name>.png`, replaceable) or
   `--look`. `--into` places it in a battle scene - think twice about `museum`: every test starts from it.

4. **Fill in its test** (`Tests/<id>_test.gd`, stubbed by the tool, `STUB(unit.py)` until done; the tool
   already imported). `bring()` summons it (it hears hits and heals: Battle._listen) and stages its
   side's turn. Check its bio, what reads of it show (`b.read(o, u)`) and how its AI acts (`AI.act(b, u)`
   returns its log). Recipes (`bio_test.gd`, `blinthe_test.gd` are the neighbours):
   - **reads**: an observer without recon can't make out levels or classes - it sees `looks`; give it
     `sharp(o)` (recon 3) to see the level, class, properties.
   - **brave / aggressive / strategies**: the AI weighs targets by the level it reads: `sharp(u)` first, or
     two villagers look alike and it just takes the nearest.
   - **helpful**: the ally it heals must be on its side (`b.summon(other, side, cell)`), out of its heal's
     reach, and hurt (`hurt_to(ally)`); its log starts "<name> goes to <ally>".
   - **timid / stoic**: no foe or stronger ally near, its cell doesn't change.
   A scene's bio is shared between instances: `u.bio = u.bio.duplicate(true)` before a test changes it.

5. **Check, then run:** `python3 Util/unit.py check`, `python3 Util/skill.py check`, its tests, the full
   suite, and a windowed launch if it's placed in a scene (`godot --path . --quit-after 120`).

6. **Record the calls you made** that the user didn't, for review (CLAUDE.md). The next question number
   N is one past the highest in use: `grep -oE '^- [0-9]+' todo.md | sort -k2 -n | tail -1` (questions are
   numbered across todo.md and docs/todo/*.md). Add to todo.md's "Built on judgement" list:
   `- N <Topic> (<date>): <each call, with the choice made>.` Put the item itself, ending `(?N)`, in the
   docs/todo file for its area (world.md), and add N to that file's row of the table at the bottom of todo.md.
