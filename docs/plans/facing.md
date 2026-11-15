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

(filled in below)
