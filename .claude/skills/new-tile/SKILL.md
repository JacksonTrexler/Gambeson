---
name: new-tile
description: Add a kind of ground (a tile) to Gambeson - writes Terrain/<id>.tres and its placeholder art Tiles/<id>.png, optionally a tile in a scene's tile set, and checks it. Use for any new terrain, trap, layer or ground effect.
---

# Adding a tile

1. **Pin down the design.** What a unit on it feels: movement to enter (`enter`), extra to leave
   (`exit`), what's on whoever stands there (`effects`), steps on it (`afflicts`, for `turns`) or ends a
   turn there (`at_end`); its tags (`water`, `wet`, `rough`, `sticky`, `beneficial`/`detrimental` - the
   AI walks round known-bad ground). Hidden (`concealment`, `looks_like`), a trap (`dice`, `damage_tags`),
   a layer over other ground (`passes`, `drag`, `brittle`...)? `Scripts/Terrain.gd`'s fields are the whole
   vocabulary: read its comments. Named by the user: `--human`; else it gets `??` - and so does an
   effect's `name=` (the tool adds it; underscores for spaces).
   - **Intents to stats** (`Scripts/Effect.gd` has them all): hurts over time - `bleed` (flat HP as its
     side's turn ends, from the turn it steps on; `dice` for a roll) or `poison` (a share of max HP as its
     turn starts); heals - `regen`; slows - `movement` below 0 or `enter`/`exit`; weakens - a stat below 0.
   - **Tags the rules react to** (the tool lists what reads each tag you give): `water`, `wet`, `moist`
     (water's reach, Oceanic's penalties lift, Undine ground), `fire` (burns; Ifrit ground for motes),
     `sticky`, `rough`, `shrubbery`, `loose`/`sand` and `hole`/`edge`/`pit` (Kick), `beneficial` /
     `detrimental` (the AI avoids known-bad ground). A tag nothing reads is flavour.

2. **Anything new it does?** A tag the rules don't know yet, an Effect stat or status: do
   `.claude/skills/new-mechanic` first. Behaviour on a tile that no field covers is code in the system it
   touches (Battle's ground/layer functions; grep, don't read Battle.gd whole) - keep it small and ask.

3. **Write it:**
   ```
   python3 Util/tile.py new <id> --tags sand,loose,rough --enter 2 --color "#d8c48a" [--glyph Sa] \
       [--effect "stat=regen amount=0.1"] [--afflicts "stat=luck amount=-1 name=Sandblind" --turns 2] \
       [--at-end ...] [--set exit=1] [--set concealment=2] [--scene museum] [--human] [--dry-run]
   ```
   It writes `Terrain/<id>.tres` with `look` set to `Tiles/<id>.png`, a flat-colour 32x32 placeholder
   (replace the PNG with art any time, same path), and imports. `Battle.paint(c, terrain)` places it
   anywhere from its look; `--scene` also adds it to that scene's tile set for painting by hand. Putting
   it into the Meadows' generation is `Meadows.TILES`/`ground_at()`: a design call - ask.

4. **Test it** (`Tests/<id>_test.gd`, `extends Test`; run `godot --headless --path . --import` once it
   exists): paint it (`b.paint(c, load("res://Terrain/<id>.tres"))`), move a unit onto it (`b.move(u, c)` /
   `b.travel`), and check what it does: cost, effects, what reads of it show (`b.read(u, c)`).
   `ground_test.gd` is the neighbour to copy. A unit knows ground is bad only from recon 1
   (`v(1).afflict(effect("recon", 1), 5)`); the AI's path round it is `AI._approach()`. Whether to paint it
   into a map (the museum, the Meadows) is a design call: ask.

5. **Check, then run:** `python3 Util/tile.py check`, `python3 Util/skill.py check`,
   `godot --headless --path . -s Tests/run.gd -- <id>`, then the full suite (`-- quick` skips the slow tier
   while you iterate).

6. **Record the calls you made** that the user didn't, for review (CLAUDE.md). The next question number
   N is one past the highest in use: `grep -oE '^- [0-9]+' todo.md | sort -k2 -n | tail -1` (questions are
   numbered across todo.md and docs/todo/*.md). Add to todo.md's "Built on judgement" list:
   `- N <Topic> (<date>): <each call, with the choice made>.` Put the item itself, ending `(?N)`, in the
   docs/todo file for its area (world.md), and add N to that file's row of the table at the bottom of todo.md.
