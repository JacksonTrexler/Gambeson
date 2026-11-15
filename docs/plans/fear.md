# Fear, shove and entrance (branch x-fear, 2026-11-15)

`docs/plan.md` Phase 2 item 6 and the systems.md todo "Fear, shove and entrance effects". The user named all
three words, so the tags and Effect stats carry no ` ??`.

## Readings

- `Battle.displace()` (consolidation B5) is the one forced-move primitive; `pull`, `push` and `send` wrap it, and
  `Behaviours/displace.gd` calls it (Sing's draw, Send Off, any carrier). Forced moves turn nobody (facing.md).
- A grapple is a lasting effect whose `Applied.skill.holds()` (`Battle.held_by()`, `_let_go()`); Hitch's tow
  and Drown use it. A grip already ends at turn end if the two aren't adjacent (`_within_grip`), but late.
- Effects reach units by `Unit.afflict()`, and its callers set `a.by` after it returns (`cast()`'s effect loop,
  `Behaviour.Cast.put()`, `_trigger()` for marks). So an effect can't move its holder inside `afflict()`: it
  doesn't know its source yet.
- Nothing in the todo docs wants a fear, shove or entrance skill (grep: no hits beyond the todo line itself).
  Sing already draws (entrance) and Kick / Send Off already push, through `Displace`.
- The AI's `_away()` walks the unit's own movement; it doesn't fit a forced move, which spends none.

## Calls

1. **Three Effect stats, `shove`, `fear`, `entrance`** (`mechanic.py stat --human`), carried by any Effect: a skill's
   `effects`, `Behaviour.Cast.put()`, a mark's `effects`. `Battle.drive(u, e, a)` is called after `a.by` is set at
   those three sites and moves the holder `amount` tiles (x rank with `per_rank`, x the effect's strength) straight
   away (shove, fear) or toward (entrance) whoever put it on, through `displace()`. An effect with no source (a
   flame) moves no one. Aura and Coordinate's effect loops don't call it (neither carries one today).
2. **Shove is instant, fear and entrance are statuses.** Shove is erased once it has moved its target. Fear and
   entrance last their `turns` and `Battle._frighten()` drives the holder again as each of its own turns starts,
   not the turn it was put on, from where the source stands then (the shape of `_bleed()`). So the three differ by
   direction and by whether they keep working, and share one primitive. Fear and shove are the same direction:
   the only difference is the repeat and the slam rule (call 4), which suits "fear is a status, shove is a blow".
3. **Tags.** `shove`, `fear` and `entrance` (Glossary kind `condition`) ride on the move: `displace()` takes
   `tags` and `by`, and tells them in a new signal `Battle.driven(u, by, tags, went, hit)` (loose coupling: a
   later reaction or HUD can listen without touching `Battle`; I did not touch the reaction seam, per x-gaps).
   They also ride on collision damage, so an effect tagged `shove` (`mitigate` -50% tagged shove) counts. A
   `Displace` behaviour tells `shove` going away and `entrance` going toward, so Kick, Send Off and Sing
   already speak them. I did not put the tags on skills' own `tags` (that is the cast's tag set; a separate call).
4. **Collision damage: yes.** A push (away, walking; never a draw or a teleport) stopped short by a unit or the
   map's edge deals `Battle.SLAM = 2` blunt HP per tile unspent to the pushed unit, and the same to the unit it
   struck. It is a normal `hit()`, tagged blunt plus the move's tags, credited to the driver, so mitigation and
   `taking_hit` passives see it. Cost: it changes Kick and Send Off near walls too (no existing test broke).
   Chosen because a shove that does nothing against a wall is the weakest outcome, and tagged damage gives
   effects something to key off. Number is a first guess, one constant to retune.
5. **A grapple ends when either party actually moves** (`_break_grips()` inside `displace()`): the held one driven
   off is let go, and a holder driven off lets go of everyone it holds, through `_let_go()`. A push that goes
   nowhere keeps the grip. This covers every caller of `displace()`, not only the new effects. Hitch's tow
   (a walk, not `displace()`) is untouched.
6. **No skills.** None fit the todo docs, so the effects are data-ready only (an Effect `.tres` or a skill's effect
   is enough; no stub skill was made). No new names, so no ` ??`.
7. **AI untouched.** `_away()` spends the unit's own movement and does not fit; the AI neither seeks nor avoids
   these effects yet (forecasts don't foresee the move or slam).

## As built

- `Scripts/Effect.gd`: stats `shove`, `fear`, `entrance` (doc, title, `value()` text, `HARMFUL`).
- `Scripts/Battle.gd`: `SLAM`, `DRIVES`, `driven` signal, `drive()`, `_frighten()` (in `_mend()`), `displace(..., tags,
  by)` with `_slam()`, `holding()`, `_break_grips()`; `push`/`pull` take optional tags and by.
- `Scripts/Behaviour.gd` (`Cast.put()` calls `drive()`), `Behaviours/displace.gd` (tags and by).
- `Scripts/Tags.gd`, `Scripts/Glossary.gd`: the three tags.
- `Tests/forced_test.gd` (5 tests, 25 checks). No existing test changed.

## Mutation spot-checks (each reverted)

| Break | Failed |
|---|---|
| no `_break_grips` | 3 (held, holder, frightened grappler) |
| no `_slam` | 5 |
| no `_frighten` in `_mend` | 2 |
| entrance direction flipped | 2 |
| Displace drops its tags | 1 |
| shove left on the unit | 1 |
| cast loop not calling `drive` | 7 |
| `Cast.put` not calling `drive` | 2 |
| `_trigger` not calling `drive` | 1 |
