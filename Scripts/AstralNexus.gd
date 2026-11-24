class_name AstralNexus
extends Node

# The Astral Nexus (Scenes/astral_nexus.tscn), a child of its Battle: starpower generators (dark orange,
# a star, full: rank 5, signal 5 tiles out) sprinkled through it, wired into one circuit of the Astral
# Envoy's lattice tiles. Star flooring lies only where signal reaches (Battle.radiate(),
# docs/plans/w22-signal.md): each generator stands on a startile platform (PLATFORM tiles out, Manhattan),
# Stardust scattered over the rest of its reach; starpane wires (rank 1: their own tile of signal, while
# the circuit's live) run from one generator to the next (L-shaped, a nearest-neighbour tree plus one
# loop) with a walkway of startiles and Stardust beside them. Stardust regrows into startiles in the
# signal, a round a tile from the nearest source. Stone floor lies round the circuit, some of it void;
# void beyond. Ending a turn in a live generator's signal, a unit feels its Power Siphon
# (Battle.circuit_ends()). Hostile starmen wait on the circuit; the battle is won when they're all down.
# Difficulty (battle.difficulty, 0.5 to 1.5; docs/plans/w24-layout.md) scales linearly: the map, the generators' and starpanes' ranks,
# the starmen. 2 to 3 generators in a big map: pockets of empty void between; a few bridges of startiles alone, 2 wide, 2 x the
# starpanes' rank long, cut into the wires between starpanes. A very rare (RARE) neutral Astral Princess comes with a much larger horde.
# It lays itself out in its _ready, before the Battle's (so the Battle's own lattice setup finds it done).
# Gamut's Tower picks the difficulty and the rewards (Game.difficulty, Game.dungeon), as for the Meadows.

const SIZE := Vector2i(33, 21)  # the map at difficulty 1...
const SIZE_STEP := Vector2i(8, 6)  # ...plus this per 1.0 of difficulty above (below: less)
const GENS := Vector2i(2, 3)  # how many generators, least to most
const GEN_RANK := Vector2i(4, 1)  # a generator's rank (signal reach, tiles, to SIGNAL_FULL) at difficulty 1, plus this per 1.0 of difficulty above
const PANE_RANK := Vector2i(2, 1)  # a starpane's: the same
const BRIDGES := Vector2i(1, 3)  # startile bridges cut into the wires, least to most (as many as fit)
const HORDE := Vector2i(3, 5)  # starmen, least to most, at difficulty 1: x difficulty
const RARE := 0.04  # chance the nest has a neutral Astral Princess...
const RARE_HORDE := 1.75  # ...and this much more of a horde
const PRINCESS := "res://Scenes/astral_princess.tscn"
const WANDERERS := "res://Factions/wanderers.tres"
const SPACING := 6  # tiles at least between two generators (either axis), and from the landing
const EDGE := 3  # a generator stays this far in from the edge: its platform fits
const PLATFORM := 2  # a generator's startile platform, tiles out (Manhattan)
const REACH := 5  # its signal at most: SIGNAL_FULL (Battle.signal_sources()); a generator reaches its rank
const DUST := 0.3  # of the rest of its reach's floor lying as Stardust
const WALK := Vector2(0.4, 0.3)  # beside a wire: startile walkway, Stardust (the rest floor)
const FLOOR := 2  # stone floor this far round the circuit
const VOIDED := 0.3  # of that floor left void
const GENERATOR: Terrain = preload("res://Terrain/starpower_generator.tres")
const STARDUST: Terrain = preload("res://Terrain/stardust.tres")
const STONE := Vector2i(4, 0)  # the ground under the lattice: its tile in the scene's set (source 0: Tiles/placeholder.png; source 1: the void's own)
const STARMAN := "res://Scenes/starman.tscn"
const HOSTILE := "res://Factions/unaligned.tres"

@export var seed := 0  # 0: a fresh nexus each time
@export var least := HORDE.x
@export var most := HORDE.y
@export var rare := RARE  # chance of the neutral princess (0: never, 1: always)

var battle: Battle
var map: TileMapLayer  # the battle's (its own @onready isn't set until after this one's _ready)
var rng := RandomNumberGenerator.new()
var generators: Array[Vector2i] = []
var startiles: Array[Vector2i] = []
var panes: Array[Vector2i] = []
var dust: Array[Vector2i] = []  # Stardust over stone, off the circuit
var floor_cells: Array[Vector2i] = []  # stone, off the circuit
var voids: Array[Vector2i] = []
var starmen: Array[Unit] = []
var princess: Unit
var bridges: Array[Vector2i] = []  # the startiles of the bridges
var width := SIZE.x
var height := SIZE.y
var start := Vector2i(1, 10)  # where the party lands: a startile, wired in like a generator
var gen_rank := 4
var pane_rank := 2


func _ready() -> void:
	battle = get_parent()
	map = battle.get_node("Map")
	if Game.difficulty > 0.0:
		battle.difficulty = Game.difficulty
		Game.difficulty = 0.0
	if Game.dungeon:
		battle.rewards = Game.dungeon.rewards_at(battle.difficulty)
		Game.dungeon = null
	rng.seed = seed if seed else randi()
	_lay()
	battle.ready.connect(func() -> void:  # the Battle has registered the layers by then. Ranks first: the signal's cached by what hashes, and the charge is last
		for c in panes:
			_rank_layer(c, Battle.STARPANE, pane_rank)
		for c in generators:
			_rank_layer(c, GENERATOR, gen_rank)
		for c in generators:
			battle.charge[c] = ceili(float(Battle.STAR_CAPACITY) * gen_rank / Battle.SIGNAL_FULL), CONNECT_ONE_SHOT)  # full for its rank
	_muster()


# Which tile each cell is, then painted: the circuit (generators, startiles, starpanes) and Stardust over
# stone, stone floor round them, void elsewhere.
func _lay() -> void:
	var d := battle.difficulty if battle else 1.0
	width = SIZE.x + roundi(SIZE_STEP.x * (d - 1.0))
	height = SIZE.y + roundi(SIZE_STEP.y * (d - 1.0))
	start = Vector2i(1, height / 2)
	gen_rank = clampi(GEN_RANK.x + roundi(GEN_RANK.y * (d - 1.0)), 1, Battle.SIGNAL_FULL)
	pane_rank = clampi(PANE_RANK.x + roundi(PANE_RANK.y * (d - 1.0)), 1, Battle.SIGNAL_FULL)
	_sprinkle()
	var lattice := {start: true}
	startiles.append(start)
	for g in generators:
		lattice[g] = true
	dust.assign(layout(generators, _wires(), rng, _inside, lattice, startiles, panes, gen_rank))
	_bridge(lattice)
	var dusty := {}
	for c in dust:
		dusty[c] = true
	for x in width:
		for y in height:
			var c := Vector2i(x, y)
			if c in lattice or c in dusty:
				continue
			if (_near(c, lattice) or _near(c, dusty)) and rng.randf() >= VOIDED:
				floor_cells.append(c)
			else:
				voids.append(c)
	_connect()
	for c in generators + startiles + panes + dust + floor_cells:
		map.set_cell(c, 0, STONE)
	for c in voids:
		map.set_cell(c, 1, Vector2i.ZERO)
	var tiles := TileStack.new()
	tiles.terrain = Battle.STARTILE
	tiles.cells.assign(startiles)
	tiles.mode = "overlay"
	var gens := TileStack.new()
	gens.terrain = GENERATOR
	gens.cells.assign(generators)
	gens.mode = "overlay"
	var gaps := TileStack.new()
	gaps.terrain = Battle.STARPANE
	gaps.cells.assign(panes)
	gaps.mode = "overlay"
	var dusted := TileStack.new()
	dusted.terrain = STARDUST
	dusted.cells.assign(dust)
	dusted.mode = "overlay"
	battle.stacked.assign([gaps, tiles, gens, dusted])


# The Nexus's star flooring rules (docs/plans/w22-signal.md), for anything building a nest of generators (the Nexus; Starnest,
# Behaviours/star_place.gd): round each of `gens` a startile platform (PLATFORM out), along each of `wires` (pairs of cells) a
# starpane run (an L, bent at random; straight where they line up), beside the panes a walkway (WALK: startile, Stardust), and
# Stardust over DUST of the rest of each generator's REACH. Cells taken (`lattice`, which gets the new ones) are skipped;
# `inside` says which cells exist. Appends to `startiles` and `panes`; returns the Stardust cells.
static func layout(gens: Array[Vector2i], wires: Array, rng: RandomNumberGenerator, inside: Callable, lattice: Dictionary, startiles: Array[Vector2i], panes: Array[Vector2i], reach := REACH) -> Array[Vector2i]:
	for g in gens:  # its platform
		for c in diamond(g, PLATFORM, inside):
			_put_on(c, startiles, lattice)
	for e in wires:
		var a: Vector2i = e[0]
		var b: Vector2i = e[1]
		var bend := Vector2i(b.x, a.y) if rng.randf() < 0.5 else Vector2i(a.x, b.y)
		for leg in [[a, bend], [bend, b]]:
			var at: Vector2i = leg[0]
			while true:
				_put_on(at, panes, lattice)
				if at == leg[1]:
					break
				at += (leg[1] - at).sign()
	var dusty := {}
	for p in panes:  # the walkway beside the wires: in their signal
		for d in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var c: Vector2i = p + d
			if inside.call(c) and c not in lattice and c not in dusty:
				var r := rng.randf()
				if r < WALK.x:
					_put_on(c, startiles, lattice)
				elif r < WALK.x + WALK.y:
					dusty[c] = true
	for g in gens:  # Stardust over the rest of its reach
		for c in diamond(g, reach, inside):
			if c not in lattice and c not in dusty and rng.randf() < DUST:
				dusty[c] = true
	var out: Array[Vector2i] = []
	out.assign(dusty.keys())
	return out

# Generators sprinkled at random, SPACING apart (and from the landing), EDGE in from the sides.
func _sprinkle() -> void:
	var n := rng.randi_range(GENS.x, GENS.y)
	for i in 400:
		if generators.size() >= n:
			break
		var c := Vector2i(rng.randi_range(EDGE, width - 1 - EDGE), rng.randi_range(EDGE, height - 1 - EDGE))
		if (generators + [start]).all(func(o: Vector2i): return maxi(absi(o.x - c.x), absi(o.y - c.y)) >= SPACING):
			generators.append(c)


# c onto the lattice as `list`'s tile, unless it's on already (a generator, an arm, a crossing wire).
static func _put_on(c: Vector2i, list: Array[Vector2i], lattice: Dictionary) -> void:
	if c not in lattice:
		lattice[c] = true
		list.append(c)


# The wires: the landing and the generators joined nearest first (a spanning tree, by tile distance), and
# the shortest pair left over joined too, closing a loop - a circuit.
func _wires() -> Array:
	var nodes: Array[Vector2i] = [start]
	nodes.append_array(generators)
	var joined := [0]
	var out := []
	var dist := func(i: int, j: int) -> int: return absi(nodes[i].x - nodes[j].x) + absi(nodes[i].y - nodes[j].y)
	while joined.size() < nodes.size():
		var best := [-1, -1]
		for i in joined:
			for j in nodes.size():
				if j not in joined and (best[0] < 0 or dist.call(i, j) < dist.call(best[0], best[1])):
					best = [i, j]
		joined.append(best[1])
		out.append([nodes[best[0]], nodes[best[1]]])
	var spare := [-1, -1]
	for i in range(1, nodes.size()):
		for j in range(i + 1, nodes.size()):
			if not out.any(func(e: Array): return (e[0] == nodes[i] and e[1] == nodes[j]) or (e[0] == nodes[j] and e[1] == nodes[i])) \
					and (spare[0] < 0 or dist.call(i, j) < dist.call(spare[0], spare[1])):
				spare = [i, j]
	if spare[0] >= 0:
		out.append([nodes[spare[0]], nodes[spare[1]]])
	return out


# The cells within r of c, Manhattan, that `inside` takes.
static func diamond(c: Vector2i, r: int, inside: Callable) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for dx in range(-r, r + 1):
		for dy in range(-(r - absi(dx)), r - absi(dx) + 1):
			if inside.call(c + Vector2i(dx, dy)):
				out.append(c + Vector2i(dx, dy))
	return out


func _inside(c: Vector2i) -> bool:
	return c.x >= 0 and c.y >= 0 and c.x < width and c.y < height


# Within FLOOR of the circuit.
func _near(c: Vector2i, lattice: Dictionary) -> bool:
	for dx in range(-FLOOR, FLOOR + 1):
		for dy in range(-FLOOR, FLOOR + 1):
			if c + Vector2i(dx, dy) in lattice:
				return true
	return false


# Whatever the party's start can't walk to is void: no stranded lattice.
func _connect() -> void:
	var open := {}
	for c in generators + startiles + panes + dust + floor_cells:
		open[c] = true
	var seen := {start: true}
	var queue: Array[Vector2i] = [start]
	while not queue.is_empty():
		var at: Vector2i = queue.pop_front()
		for d in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var n: Vector2i = at + d
			if n in open and n not in seen:
				seen[n] = true
				queue.append(n)
	for list in [generators, startiles, panes, dust, floor_cells]:
		for c: Vector2i in list.duplicate():
			if c not in seen:
				list.erase(c)
				voids.append(c)


# Bridges: in a straight run of starpanes, 2 x the starpanes' rank of them (a pane run's middle) become startiles, 2 wide, panes
# at both ends, widened to 2 there (a startile bridge joins the panes either side). As many as fit, BRIDGES least to most.
func _bridge(lattice: Dictionary) -> void:
	var want := rng.randi_range(BRIDGES.x, BRIDGES.y)
	var len := 2 * pane_rank
	var cands: Array = []
	for p in panes:
		for d in [Vector2i.RIGHT, Vector2i.DOWN]:
			cands.append([p, d])
	while want > 0 and not cands.is_empty():
		var cd: Array = cands.pop_at(rng.randi() % cands.size())
		var p: Vector2i = cd[0]
		var d: Vector2i = cd[1]
		var side := Vector2i(d.y, d.x) * (1 if rng.randf() < 0.5 else -1)
		var far := p + d * (len + 1)
		var ok := far in panes
		for e in [p + side, far + side]:  # the panes widen to 2 there, so the whole bridge is in their signal
			ok = ok and _inside(e) and (e not in lattice or e in startiles or e in dust)
		for k in range(1, len + 1):
			var at := p + d * k
			ok = ok and at in panes and _inside(at + side) and (at + side not in lattice or at + side in startiles or at + side in dust)
		if not ok:
			continue
		for e in [p + side, far + side]:
			dust.erase(e)
			startiles.erase(e)
			panes.append(e)
			lattice[e] = true
		for k in range(1, len + 1):
			var at := p + d * k
			panes.erase(at)
			for c in [at, at + side]:
				dust.erase(c)
				if c not in startiles:
					startiles.append(c)
				lattice[c] = true
				bridges.append(c)
		want -= 1
	var lit := func(c: Vector2i) -> bool:  # still in some source's signal
		return panes.any(func(o: Vector2i): return absi(o.x - c.x) + absi(o.y - c.y) <= pane_rank) \
				or generators.any(func(o: Vector2i): return absi(o.x - c.x) + absi(o.y - c.y) <= gen_rank)
	for list in [startiles, dust]:  # a walkway beside a pane that became a bridge may have lost its signal
		for c: Vector2i in list.duplicate():
			if c != start and not lit.call(c):
				list.erase(c)
				lattice.erase(c)


# The ranked layer of terrain t on c, its rank set (a generator's or starpane's signal reach).
func _rank_layer(c: Vector2i, t: Terrain, rank: int) -> void:
	for l: Battle.Layer in battle.layers.get(c, []):
		if l.terrain == t:
			l.power = rank


# Starmen on the circuit (starkind: off the lattice they fade), well away from the landing, none on a generator. Their count
# scales with difficulty; rarely a neutral Astral Princess stands among a much larger horde.
func _muster() -> void:
	var spots: Array[Vector2i] = []
	for c in startiles + panes:
		if c.x >= width / 3:
			spots.append(c)
	var hostile: Faction = load(HOSTILE)
	var scene: PackedScene = load(STARMAN)
	var d := battle.difficulty
	var n := roundi(rng.randi_range(least, most) * d)
	var rare_nest := rng.randf() < rare
	if rare_nest:
		n = roundi(n * RARE_HORDE)
	for i in n:
		if spots.is_empty():
			break
		var c: Vector2i = spots.pop_at(rng.randi() % spots.size())
		var u: Unit = scene.instantiate()
		u.cell = c
		u.faction = hostile
		u.name = "Starman%d" % (i + 1)
		battle.get_node("Units").add_child(u)
		starmen.append(u)
	if rare_nest and not spots.is_empty():
		princess = (load(PRINCESS) as PackedScene).instantiate()
		princess.cell = spots.pop_at(rng.randi() % spots.size())
		princess.faction = load(WANDERERS)
		princess.name = "AstralPrincess"
		battle.get_node("Units").add_child(princess)
