class_name AstralNexus
extends Node

# The Astral Nexus (Scenes/astral_nexus.tscn), a child of its Battle: starpower generators (dark orange,
# a star, full) sprinkled through it, wired into one circuit of the Astral Envoy's lattice tiles. Each
# generator: a startile `arm` (1 or 2) out each side, row and column alike, starpanes on its diagonals;
# starpane wires run on from the arms to the next generator (L-shaped, a nearest-neighbour tree plus one
# loop). Stone floor lies round the circuit, some of it void; void beyond. Ending a turn on the live
# circuit, a unit feels its generators' Power Siphon (Battle.circuit_ends()). 4 to 6 hostile starmen wait
# on the circuit; the battle is won when they're all down.
# It lays itself out in its _ready, before the Battle's (so the Battle's own lattice setup finds it done).
# Gamut's Tower picks the difficulty and the rewards (Game.difficulty, Game.dungeon), as for the Meadows.

const WIDTH := 29
const HEIGHT := 17
const GENS := Vector2i(4, 6)  # how many generators, least to most
const SPACING := 6  # tiles at least between two generators (either axis), and from the landing
const EDGE := 3  # a generator stays this far in from the edge: its arms fit
const FLOOR := 2  # stone floor this far round the circuit
const VOIDED := 0.15  # of that floor left void
const START := Vector2i(1, 8)  # where the party lands: a startile, wired in like a generator
const GENERATOR: Terrain = preload("res://Terrain/starpower_generator.tres")
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


# Which tile each cell is, then painted: the circuit (generators, startiles, starpanes) over stone, stone
# floor round it, void elsewhere.
func _lay() -> void:
	_sprinkle()
	var lattice := {START: true}
	startiles.append(START)
	for g in generators:
		lattice[g] = true
	for g in generators:  # the rule, row and column alike: pane..., tile x arm, Gen, tile x arm, pane...
		var arm := rng.randi_range(1, 2)
		for d in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			for k in range(1, arm + 1):
				_put(g + d * k, startiles, lattice)
		for d in [Vector2i(1, 1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(-1, -1)]:
			_put(g + d, panes, lattice)  # diagonals: panes
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
	for x in WIDTH:
		for y in HEIGHT:
			var c := Vector2i(x, y)
			if c in lattice:
				continue
			if _near(c, lattice) and rng.randf() >= VOIDED:
				floor_cells.append(c)
			else:
				voids.append(c)
	_connect()
	for c in generators + startiles + panes + floor_cells:
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
	battle.stacked.assign([gaps, tiles, gens])


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
	for c in generators + startiles + panes + floor_cells:
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
	for list in [generators, startiles, panes, floor_cells]:
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
