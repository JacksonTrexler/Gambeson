extends Behaviour

# The Starbuilding verb (docs/plans/w22-astral1.md): lays star tiles on a cell the caster aims at, paid in Power (Unit.pays_power()), each
# tile sealing some of its Power until the tile is destroyed (Battle.lay_star()). `shape` says where:
#   point   the cell (Startile; Starpower Generator: `layer` the generator, its power the skill's rank)
#   line    from the caster toward the cell, every tile of it (Starpanel)
#   bridge  between the powered star tile aimed at and the nearest one beyond the gap toward the caster, rank tiles wide (Starbridge)
#   pair    the cell and the startile its caster stands on, paired portals (Starway)
#   nest    rank generators from the cell, SPACING apart, each wired to the one it grew from by a straight starpane run, star flooring
#           laid over whatever is there by the Nexus's rules (AstralNexus.layout(): platforms, walkways, Stardust) (Starnest)
# `seal`, a seal Effect (tags [power, debt]: whichever pool is its Power, into debt), is put on the caster once a cast, held while
# any tile it laid that cast holds (Starnest: 20% x rank of max Power).
# Startiles it lays last rank rounds out of the signal (`lapses`).

const SPAN := 12  # how far a bridge looks for its other end
const SIDES: Array[Vector2i] = [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]

@export var shape := &"point"
@export var layer: Terrain  # what it lays
@export var points := 1  # Power each tile seals...
@export var share := 0.0  # ...plus this share of the pool's max, per rank (Generator: 10%)
@export var lapses := false  # the tiles last rank rounds unpowered
@export var seal: Effect  # put on the caster once a cast, at the cast's rank, held by what it laid (Starnest)


func tile_target() -> StringName:
	return &"tile"


func fits_at(b: Battle, caster: Unit, cell: Vector2i, _fall := false) -> bool:
	var s := _skill(caster)
	if s == null or not caster.pays_power(s):
		return false
	var pool: Variant = caster.power_pool()
	var ri := caster.mods(s).irank(caster.rank(s), &"rank_impact")
	return not _plan(b, caster, cell, ri).is_empty() and caster.usable_max(pool) >= _need(caster, pool, ri)


func apply_at(c: Cast, cell: Vector2i) -> void:
	var b := c.battle
	var u := c.caster
	var pool: Variant = u.power_pool()
	var laid: Array[Vector2i] = []
	var held: Array = []  # [cell, layer, terrain] it laid: what holds its cast's seal
	var r := c.impact_rank()
	if shape == &"nest":
		var nest := _nest(b, cell, r)
		for t: Terrain in nest:
			for at: Vector2i in nest[t]:
				held.append([at, b.lay_star(at, t, u, 0, 0.0, r if lapses and t == Battle.STARTILE else 0, 5 if t.power_rank > 1 and t.source else 0), t])
	else:
		for at in _plan(b, u, cell, r):
			if u.usable_max(pool) < _need(u, pool, r):
				break  # no Power left to seal
			held.append([at, b.lay_star(at, layer, u, points, share * r, r if lapses else 0, r if _ranked() else 0), layer])
			laid.append(at)
	if shape == &"pair" and laid.size() == 2:
		b.pair_portals(laid[0], laid[1])
	if seal and not held.is_empty():
		u.afflict(seal, 0, r, func() -> bool: return held.any(func(h: Array): return h[1] in b.layers.get(h[0], []) and h[1].terrain == h[2]))


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
		&"nest":
			var nest := _nest(b, cell, r)
			for t in nest:
				out.append_array(nest[t])
			return out
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


# A Starnest at `cell`, rank r: {terrain: cells} - r generators (`layer`; the first on the cell), each grown SPACING from one
# laid before in a random straight line and wired to it, the Nexus's flooring round them (AstralNexus.layout()). Cells off
# the map or holding star tiles already are left as they are. Seeded by the cell and rank: what it shows is what it lays.
func _nest(b: Battle, cell: Vector2i, r: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([cell, r])
	var free := func(at: Vector2i) -> bool: return b.on_map(at) and not b.has_star(at)
	var gens: Array[Vector2i] = []
	var wires := []
	if free.call(cell):
		gens.append(cell)
	for k in 40:
		if gens.size() >= maxi(r, 1) or gens.is_empty():
			break
		var from := gens[rng.randi() % gens.size()]
		var at := from + SIDES[rng.randi() % SIDES.size()] * AstralNexus.SPACING
		if free.call(at) and gens.all(func(g: Vector2i): return maxi(absi(g.x - at.x), absi(g.y - at.y)) >= AstralNexus.SPACING):
			gens.append(at)
			wires.append([from, at])
	if gens.is_empty():
		return {}
	var lattice := {}
	for g in gens:
		lattice[g] = true
	var tiles: Array[Vector2i] = []
	var panes: Array[Vector2i] = []
	var dust := AstralNexus.layout(gens, wires, rng, free, lattice, tiles, panes)
	return {layer: gens, Battle.STARTILE: tiles, Battle.STARPANE: panes, AstralNexus.STARDUST: dust}


# A source whose power is its skill's rank (a generator): not a pane, which carries its own.
func _ranked() -> bool:
	return layer != null and layer.source and layer.power_rank > 0


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
	if lapses or shape in [&"bridge", &"nest"] or _ranked():
		t.add(&"rank_impact", "star tiles")
	if t.impact == &"":
		t.impact = &"tame"


func describe(rank: int) -> String:
	return _say(rank)


func describe_as(c: Cast) -> String:
	return _say(c.impact_rank())


func _say(r: int) -> String:
	var tile := layer.name.to_lower() + "s" if layer else "star tiles"
	var seals := "Each seals %d Power" % points if share == 0.0 else "Each seals %d + %d%% Power" % [points, roundi(share * r * 100.0)]
	var rounds := " Lasts {t:%d rounds} outside the %s." % [r, Glossary.term(&"signal", "signal")] if lapses else ""
	var sealed := " Seals %s of max Power, into debt if it must, while any of it stands." % ("%d%%" % roundi(seal.amount * r * 100.0) if seal.op == "mul" else str(roundi(seal.amount * r))) if seal else ""
	match shape:
		&"nest":
			return "Builds a Starnest on a tile in range: {r:%d} full generators, %d tiles apart, wired in straight rows or columns by starpanes, with star flooring laid over what is there (platforms, walkways, Stardust).%s" % [r, AstralNexus.SPACING, sealed]
		&"line":
			return "Lays %s from the caster toward a tile, all along it. %s until it is destroyed" % [tile, seals]
		&"bridge":
			return "On a powered star tile, bridges the gap to the next one toward the caster with %s, {r:%d} tiles wide. %s until it is destroyed.%s" % [tile, r, seals, rounds]
		&"pair":
			return "On a star tile it can see, lays a pair of %s with the startile it stands on: stepping on one that is powered comes out on the other. They break as star flooring does" % tile
		_:
			var power := " Radiates {r:%d} tiles of %s." % [r, Glossary.term(&"signal", "signal")] if _ranked() else ""
			return "Lays a %s on a tile in range.%s %s until it is destroyed.%s" % [tile.trim_suffix("s"), power, seals, rounds]
