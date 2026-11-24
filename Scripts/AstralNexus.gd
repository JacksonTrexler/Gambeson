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
# (Battle.circuit_ends()). 4 to 6 hostile starmen wait on the circuit; the battle is won when they're all down.
# It lays itself out in its _ready, before the Battle's (so the Battle's own lattice setup finds it done).
# Gamut's Tower picks the difficulty and the rewards (Game.difficulty, Game.dungeon), as for the Meadows.

const WIDTH := 29
const HEIGHT := 17
const GENS := Vector2i(4, 6)  # how many generators, least to most
const SPACING := 6  # tiles at least between two generators (either axis), and from the landing
const EDGE := 3  # a generator stays this far in from the edge: its platform fits
const PLATFORM := 2  # a generator's startile platform, tiles out (Manhattan)
const REACH := 5  # its signal: its rank, full (Battle.signal_sources())
const DUST := 0.3  # of the rest of its reach's floor lying as Stardust
const WALK := Vector2(0.4, 0.3)  # beside a wire: startile walkway, Stardust (the rest floor)
const FLOOR := 2  # stone floor this far round the circuit
const VOIDED := 0.15  # of that floor left void
const START := Vector2i(1, 8)  # where the party lands: a startile, wired in like a generator
const GENERATOR: Terrain = preload("res://Terrain/starpower_generator.tres")
const STARDUST: Terrain = preload("res://Terrain/stardust.tres")
const STONE := Vector2i(4, 0)  # the ground under the lattice: its tile in the scene's set (source 0: Tiles/placeholder.png; source 1: the void's own)
const STARMAN := "res://Scenes/starman.tscn"
const HOSTILE := "res://Factions/unaligned.tres"

@export var seed := 0  # 0: a fresh nexus each time
@export var least := 4
@export var most := 6

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
	for c in generators:
		battle.ready.connect(func() -> void: battle.charge[c] = Battle.STAR_CAPACITY, CONNECT_ONE_SHOT)  # full: the Battle has registered them by then
	_muster()


# Which tile each cell is, then painted: the circuit (generators, startiles, starpanes) and Stardust over
# stone, stone floor round them, void elsewhere.
func _lay() -> void:
	_sprinkle()
	var lattice := {START: true}
	startiles.append(START)
	for g in generators:
		lattice[g] = true
	for g in generators:  # its platform
		for c in _diamond(g, PLATFORM):
			_put(c, startiles, lattice)
	for e in _wires():
		var a: Vector2i = e[0]
		var b: Vector2i = e[1]
		var bend := Vector2i(b.x, a.y) if rng.randf() < 0.5 else Vector2i(a.x, b.y)
		for leg in [[a, bend], [bend, b]]:
			var at: Vector2i = leg[0]
			while true:
				_put(at, panes, lattice)
				if at == leg[1]:
					break
				at += (leg[1] - at).sign()
	var dusty := {}
	for p in panes:  # the walkway beside the wires: in their signal
		for d in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var c: Vector2i = p + d
			if _inside(c) and c not in lattice and c not in dusty:
				var r := rng.randf()
				if r < WALK.x:
					_put(c, startiles, lattice)
				elif r < WALK.x + WALK.y:
					dusty[c] = true
	for g in generators:  # Stardust over the rest of its reach
		for c in _diamond(g, REACH):
			if _inside(c) and c not in lattice and c not in dusty and rng.randf() < DUST:
				dusty[c] = true
	dust.assign(dusty.keys())
	for x in WIDTH:
		for y in HEIGHT:
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


# Generators sprinkled at random, SPACING apart (and from the landing), EDGE in from the sides.
func _sprinkle() -> void:
	var n := rng.randi_range(GENS.x, GENS.y)
	for i in 400:
		if generators.size() >= n:
			break
		var c := Vector2i(rng.randi_range(EDGE, WIDTH - 1 - EDGE), rng.randi_range(EDGE, HEIGHT - 1 - EDGE))
		if (generators + [START]).all(func(o: Vector2i): return maxi(absi(o.x - c.x), absi(o.y - c.y)) >= SPACING):
			generators.append(c)


# c onto the lattice as `list`'s tile, unless it's on already (a generator, an arm, a crossing wire).
func _put(c: Vector2i, list: Array[Vector2i], lattice: Dictionary) -> void:
	if c not in lattice:
		lattice[c] = true
		list.append(c)


# The wires: the landing and the generators joined nearest first (a spanning tree, by tile distance), and
# the shortest pair left over joined too, closing a loop - a circuit.
func _wires() -> Array:
	var nodes: Array[Vector2i] = [START]
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


# The cells within r of c, Manhattan, in bounds.
func _diamond(c: Vector2i, r: int) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for dx in range(-r, r + 1):
		for dy in range(-(r - absi(dx)), r - absi(dx) + 1):
			if _inside(c + Vector2i(dx, dy)):
				out.append(c + Vector2i(dx, dy))
	return out


func _inside(c: Vector2i) -> bool:
	return c.x >= 0 and c.y >= 0 and c.x < WIDTH and c.y < HEIGHT


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
	var seen := {START: true}
	var queue: Array[Vector2i] = [START]
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


# 4 to 6 starmen on the circuit (starkind: off the lattice they fade), well away from the landing, none on a generator.
func _muster() -> void:
	var spots: Array[Vector2i] = []
	for c in startiles + panes:
		if c.x >= WIDTH / 3:
			spots.append(c)
	var hostile: Faction = load(HOSTILE)
	var scene: PackedScene = load(STARMAN)
	var n := rng.randi_range(least, most)
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
