extends Behaviour

# The Starbuilding verb (docs/plans/w22-astral1.md): lays star tiles on a cell the caster aims at, paid in Power (Unit.pays_power()), each
# tile sealing some of its Power until the tile is destroyed (Battle.lay_star()). `shape` says where:
#   point   the cell (Startile; Starpower Generator: `layer` the generator, its power the skill's rank)
#   line    from the caster toward the cell, every tile of it (Starpanel)
#   bridge  between the powered star tile aimed at and the nearest one beyond the gap toward the caster, rank tiles wide (Starbridge)
#   pair    the cell and the startile its caster stands on, paired portals (Starway)
# Startiles it lays last rank rounds out of the signal (`lapses`).

const SPAN := 12  # how far a bridge looks for its other end
const SIDES: Array[Vector2i] = [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]

@export var shape := &"point"
@export var layer: Terrain  # what it lays
@export var points := 1  # Power each tile seals...
@export var share := 0.0  # ...plus this share of the pool's max, per rank (Generator: 10%)
@export var lapses := false  # the tiles last rank rounds unpowered


func tile_target() -> StringName:
	return &"tile"


func fits_at(b: Battle, caster: Unit, cell: Vector2i) -> bool:
	var s := _skill(caster)
	if s == null or not caster.pays_power(s):
		return false
	var pool: Variant = caster.power_pool()
	return not _plan(b, caster, cell, caster.rank(s)).is_empty() and caster.usable_max(pool) >= _need(caster, pool, caster.rank(s))


func apply_at(c: Cast, cell: Vector2i) -> void:
	var b := c.battle
	var u := c.caster
	var pool: Variant = u.power_pool()
	var rank := c.rank
	var laid: Array[Vector2i] = []
	for at in _plan(b, u, cell, c.impact_rank()):
		if u.usable_max(pool) < _need(u, pool, c.rank):
			break  # no Power left to seal
		b.lay_star(at, layer, u, points, share * c.rank, c.impact_rank() if lapses else 0, rank if layer.power_rank > 0 else 0)
		laid.append(at)
	if shape == &"pair" and laid.size() == 2:
		b.pair_portals(laid[0], laid[1])


# The tiles it would lay on `cell` at rank r (a bridge's width, a pair's ends): none if it can't.
func _plan(b: Battle, u: Unit, cell: Vector2i, r: int) -> Array[Vector2i]:
	if layer == null or not b.on_map(cell):
		return []
	var out: Array[Vector2i] = []
	match shape:
		&"line":
			for at in _line(u.cell, cell):
				out.append(at)
		&"bridge":
			if not b.powered_star(cell):
				return []
			var far := _other_end(b, u, cell)
			if far == cell:
				return []
			var along := Vector2i((far - cell).sign())
			var across := Vector2i(along.y, along.x).abs()
			var n := maxi(absi(far.x - cell.x), absi(far.y - cell.y))
			var half := floori(maxi(r, 1) / 2.0)
			for k in range(1, n):
				for w in range(-half, maxi(r, 1) - half):
					out.append(cell + along * k + across * w)
		&"pair":
			var here := u.cell
			if cell == here or not _startile(b, cell) or not _startile(b, here) or b.portals.has(cell) or b.portals.has(here):
				return []
			if b.sight and not b.sight_cells(u.faction).has(cell):
				return []  # a startile it perceives
			return [cell, here] as Array[Vector2i]
		_:
			out.append(cell)
	return out.filter(func(at: Vector2i): return b.on_map(at) and not b.layers.get(at, []).any(func(l: Battle.Layer): return l.terrain == layer))


func _startile(b: Battle, c: Vector2i) -> bool:
	return b.layers.get(c, []).any(func(l: Battle.Layer): return l.terrain.source and &"star" in l.terrain.tags and l.terrain.power_rank == 0)


# The cells from `a` (not itself) to `z` in a straight line, a step in the longer axis each.
func _line(a: Vector2i, z: Vector2i) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	var n := maxi(absi(z.x - a.x), absi(z.y - a.y))
	for k in range(1, n + 1):
		var at := Vector2i((Vector2(a) + Vector2(z - a) * k / n).round())
		if at not in out:
			out.append(at)
	return out


# The powered star tile a bridge from `cell` meets: scanning toward the caster along the longer axis of the way between,
# the first powered star tile past at least one gap tile; `cell` itself if none within SPAN.
func _other_end(b: Battle, u: Unit, cell: Vector2i) -> Vector2i:
	var d := u.cell - cell
	var step := Vector2i(signi(d.x), 0) if absi(d.x) >= absi(d.y) else Vector2i(0, signi(d.y))
	if step == Vector2i.ZERO:
		return cell
	for k in range(2, SPAN + 1):
		var at := cell + step * k
		if not b.on_map(at):
			break
		if b.powered_star(at):
			return at
	return cell


# The Power each tile seals at rank r: its points, and its share of the pool's max.
func _need(u: Unit, pool: Variant, r: int) -> int:
	return points + ceili(share * r * u.raw_max(pool) - 0.0001)


func _skill(u: Unit) -> Skill:
	for s in u.actives:
		if self in s.behaviours:
			return s
	return null


func footprint(c: Cast, cell: Vector2i) -> Array[Vector2i]:
	return _plan(c.battle, c.caster, cell, c.impact_rank())


# It lasts and seals by its tiles; its rank is rank impact (a bridge's width, rounds unpowered), its reach the skill's.
func terms(t: SkillTerms) -> void:
	t.add(&"rank_impact", "star tiles")
	if t.impact == &"":
		t.impact = &"tame"


func describe(rank: int) -> String:
	return _say(rank, rank)


func describe_as(c: Cast) -> String:
	return _say(c.impact_rank(), c.rank)


func _say(wide: int, rank: int) -> String:
	var tile := layer.name.to_lower() + "s" if layer else "star tiles"
	var seals := "Each seals %d Power" % points if share == 0.0 else "Each seals %d + %d%% Power" % [points, roundi(share * rank * 100.0)]
	var rounds := " Lasts {t:%d rounds} outside the %s" % [wide, Glossary.term(&"signal", "signal")] if lapses else ""
	match shape:
		&"line":
			return "Lays %s from the caster toward a tile, all along it. %s until it is destroyed.%s" % [tile, seals, rounds]
		&"bridge":
			return "On a powered star tile, bridges the gap to the next one toward the caster with %s, {r:%d} tiles wide. %s until it is destroyed.%s" % [tile, wide, seals, rounds]
		&"pair":
			return "On a star tile it can see, lays a pair of %s with the startile it stands on: stepping on one that is powered comes out on the other. They break as star flooring does" % tile
		_:
			return "Lays %s on a tile in range. %s until it is destroyed.%s" % [tile, seals, rounds]
