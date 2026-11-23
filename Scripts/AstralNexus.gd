class_name AstralNexus
extends Node

# The Astral Nexus (Scenes/astral_nexus.tscn), a child of its Battle: a few starpower generators (orange,
# full), a somewhat broken grid of startiles round each, starpanes filling most of the gaps, and astral void
# beyond and between. 4 to 6 hostile starmen wait on the lattice; the battle is won when they're all down.
# It lays itself out in its _ready, before the Battle's (so the Battle's own lattice setup finds it done).
# Gamut's Tower picks the difficulty and the rewards (Game.difficulty, Game.dungeon), as for the Meadows.

const WIDTH := 23
const HEIGHT := 13
const GENERATORS: Array[Vector2i] = [Vector2i(5, 6), Vector2i(11, 6), Vector2i(17, 6)]
const REACH := 4  # a generator's grid: this far in each direction (a square), a startile on every even offset
const BROKEN := 0.25  # of the grid's startiles missing
const VOIDED := 0.15  # of the gaps (and the missing startiles) left void rather than a starpane
const START := Vector2i(1, 6)  # where the party lands
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


# Which tile each cell is, then painted: ground (stone) under the lattice, void elsewhere.
func _lay() -> void:
	var grid := {}
	for g in GENERATORS:
		for dx in range(-REACH, REACH + 1):
			for dy in range(-REACH, REACH + 1):
				var c := g + Vector2i(dx, dy)
				if c.x >= 0 and c.y >= 0 and c.x < WIDTH and c.y < HEIGHT and (dx % 2 == 0 or dy % 2 == 0):
					grid[c] = true
	grid[START] = true
	for x in WIDTH:
		for y in HEIGHT:
			var c := Vector2i(x, y)
			if c in GENERATORS:
				generators.append(c)
			elif c in grid and (c == START or rng.randf() >= BROKEN):
				startiles.append(c)
			elif _near_grid(c, grid) and rng.randf() >= VOIDED:
				panes.append(c)
			else:
				voids.append(c)
	_connect()
	for c in generators + startiles + panes:
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


# A gap is a cell at least one side of which touches the grid (so the panes fill its holes, not the dark beyond).
func _near_grid(c: Vector2i, grid: Dictionary) -> bool:
	var n := 0
	for d in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
		n += int((c + d) in grid)
	return n >= 2


# Whatever the party's start can't walk to is void: no stranded lattice.
func _connect() -> void:
	var open := {}
	for c in generators + startiles + panes:
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
	for list in [generators, startiles, panes]:
		for c: Vector2i in list.duplicate():
			if c not in seen:
				list.erase(c)
				voids.append(c)


# 4 to 6 starmen on the lattice, well away from the landing, none on a generator.
func _muster() -> void:
	var spots: Array[Vector2i] = []
	for c in startiles + panes:
		if c.x >= 9:
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
