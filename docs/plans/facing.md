# Facing (branch u-facing, 2026-11-14)

`docs/plan.md` Phase 2 item 8 and the systems.md todo "Facing and direction". Names I make up get ` ??`.

## Readings

- `Unit.guard` (Vector2) is Shields Up!'s cone, set by `Battle._guard()`; `Unit.guarding(cell)` is a 90 degree cone test read in `Unit.hit()`.
- `Unit.heading` (Vector2i) is the net direction of the last walk, cleared by any cast; only Eyes Forward (`Battle._look_ahead`) reads it.
- `Battle.hit_tags()` is where the hit's tags are made (`ambush` joins there); `Unit.defense(tags)` is the one place every hit roll, forecast and AI score reads Defense. So a tag on the hit plus a rule in `defense(tags)` reaches all of them.

## Calls

1. **One facing.** `Unit.facing: Vector2` (zero = none yet), a normalised direction, precise not snapped to 8 ways (an attack on a target at (5,2) faces that angle). Set by: a walk (the last step's direction), any skill aimed at another unit or tile (turn toward it, as it is paid for, so a miss turns too), Shields Up! (the tile it is aimed at).
2. **`heading` folded in.** `heading` goes; Eyes Forward reads `facing` gated by a new `Unit.striding` (true after a walk, cleared by any cast, as `heading` was). A strip now follows the last step, not the net displacement.
3. **`guard` folded in.** `Unit.guard` becomes a bool (the shield is up); its cone is the *front* cone of `facing`. So the shield turns with the unit (walk or attack toward a foe and the shield faces it). Alternative: pin the shield where Shields Up! aimed it. I chose the shared facing because "guard reads the same cone" is the brief and a shield you carry points where you point.
4. **The cone** (`Unit.side_of(cell)`, the derived query): the angle between `facing` and the direction to the cell: within 45 degrees is `front`, within 45 of the opposite is `rear`, the two 90 degree arcs between are `flank`. Edges inclusive (the old guard test had 45 inside). No facing, or the same tile: `front`.
5. **Hit tags** `flank ??` and `rear ??` (via mechanic.py, kind check, Glossary names "Flank ??", "Rear ??"). `Battle.hit_tags()` adds one when the foe's `side_of(caster.cell)` says so, like `ambush`. Effects tagged flank/rear (damage, defense, mitigate...) and any rule asking for the tag count on them with no new code.
6. **Built-in edge:** a rear attack needs 1 less: `Unit.defense(tags)` takes `REAR_EDGE = 1` off when `&"rear"` is in the tags (+1 to hit, 5 points of d20). Flank: tag only, no built-in number. It applies to every attack roll, ranged included. Defense read with no tags (the sheet) is unchanged.
7. **Not turned by being hit.** Only acting turns a unit. A unit placed in a battle that hasn't acted keeps no facing (front from every side) unless the battle opens by turning it (see as built).
8. **Reactions:** see as built.
9. **Draw:** a small tick on the unit's tile edge toward its facing, in the map's own draw, faint.
10. **AI:** `_approach` picks among a target's adjacent tiles by distance; each point of Defense the tile's aspect takes off the target (`defense(plain) - defense([tag])`, the same numbers `hit_chance` reads) pulls the tile 0.4 nearer, under a step, so it only decides ties and near-ties. `Battle.hit_chance` itself already reads rear since the tags carry it.

## As built

Built as called, with these particulars:

- `Unit.facing` (Vector2, setter redraws the tick), `face(cell)`, `side_of(cell)`, `REAR_EDGE = 1`, `striding`, `guard: bool`. `heading` is gone. `Battle.travel()` faces the last step; `_cast()` turns the caster toward its target once paid, `_cast_at()` toward the tile (so Shields Up!, Darkstone, Snare, a flamewall all turn it); `_guard()` sets `guard` and faces the tile.
- **Reactions (call 8):** a unit that takes a blow in another's place (Interject, Gallantry: `Battle._swapped()`) turns to face the attacker, *after* the blow's side is read, so the roll it faces is still judged by how it stood. Final Act and Snapping Turtle attack through `cast()`, so they turn as any attack does. Dodging, being hit and being healed turn nobody.
- **Opening facing (call 7):** `Battle._line_up()`, at set-up, turns each unit that has no facing toward the nearest foe by faction. Units added later (summons) have none: front from every side until they act. `Tests/test.gd` `stage()` clears facing so staged tests stay as they were.
- **Draw (call 9):** `Unit.heading_tick`, a child of the sprite (so a silhouette hides it): a small white chevron, 55% alpha with a faint dark rim, 7 px from the centre. Captured in `shot_u-facing/`: reads as a pointer, quiet beside the HP bars.
- **AI (call 10):** `AI._opening(t, c)` = `t.defense() - t.defense([side])`, `FLANKING = 0.4` tiles per point, in `_approach()` only. Strikes already read the rear through `Battle.hit_chance()` since the hit tags carry it. It does not walk to a side for a better shot (the AI picks a tile adjacent to its target by distance; the pull only breaks ties of under half a step).
- **Tag names:** `rear ??` and `flank ??` are AI-made (Glossary "Rear ??", "Flank ??"; colours #8a5a7e, #7e6a9a, kind check).
- **Shields Up!'s recorded design** ("faces the tile ... 90 degree cone", docs/todo/classes.md) is unchanged for the cast turn. What differs: the shield now follows the unit's facing when it later walks or attacks, until its next turn is through.

Tests changed to the new shape (not weakened): `fighter_test` (guard is a bool, facing set; re-stage sets facing), `jam_test`, `helpless_test` (`guard = true` plus `facing`), `watch_test` (`striding` and `facing` for `heading`), `Tests/test.gd` (`stage()` clears facing). New: `Tests/facing_test.gd` (moves, attacks, cone at each angle, tags and the rear edge, effects tagged rear, Shields Up! via the cone, Interject turning, line-up, AI approach).

Suite: started 45664 checks, 0 failed (816 tests); now 45731 checks, 0 failed (825 tests).

Not done: the HUD's hit forecast shows the rear's +1 only through the number (no "from behind" label); a unit that is hit doesn't turn; forced moves (push, pull, send, teleport) don't turn; no skill yet carries a flank/rear rider (Gank's ambush analogue).
