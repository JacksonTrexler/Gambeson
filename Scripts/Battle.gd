class_name Battle
extends Node2D

signal phase_changed(was: Phase, now: Phase)
signal turn_changed(was: Faction, now: Faction)
signal initiative_rolled(rolls: Dictionary[Faction, Array])

enum Phase { INITIATIVE, TURNS, OVER }

var phase := Phase.INITIATIVE:
	set(v):
		if v == phase:
			return
		var was := phase
		_exit(was)
		phase = v
		phase_changed.emit(was, v)  # before _enter, so a chained change arrives in order
		_enter(v)

# Whose turn it is.
var turn: Faction:
	set(v):
		if v == turn:
			return
		var was := turn
		turn = v
		turn_changed.emit(was, v)

var order: Array[Faction] = []  # turn order, highest initiative first
var rolls: Dictionary[Faction, Array] = {}  # this battle's initiative d20s, per faction

# Which unit stands on which cell. TileSet custom data is per tile type, so it can't hold this.
var units: Dictionary[Vector2i, Unit] = {}

var rng := RandomNumberGenerator.new()

@onready var map: TileMapLayer = $Map


func _ready() -> void:
	for u: Unit in $Units.get_children():
		u.died.connect(_on_died)
		move(u, u.cell)
	_enter(phase)


func unit_at(c: Vector2i) -> Unit:
	return units.get(c)


# The one place a unit's cell changes, so `units` and positions never drift apart.
func move(u: Unit, c: Vector2i) -> bool:
	var other := unit_at(c)
	if other and other != u:
		return false
	if unit_at(u.cell) == u:
		units.erase(u.cell)
	u.cell = c
	units[c] = u
	u.position = map.map_to_local(c)
	return true


# Each living unit rolls a d20 and its faction sums them (+ Wary-style bonus); highest goes first.
func roll_initiative() -> Array[Faction]:
	rolls.clear()
	for u in units.values():
		if u.faction and u.is_alive():
			if u.faction not in rolls:
				rolls[u.faction] = []
			rolls[u.faction].append(rng.randi_range(1, 20))
	var o: Array[Faction] = []
	o.assign(contest(rolls.keys(), [total]))
	print("Initiative: ", ", ".join(o.map(func(f): return "%s %d" % [f.name, total(f)])))
	initiative_rolled.emit(rolls)
	return o


func total(f: Faction) -> int:
	return rolls[f].reduce(func(sum, d): return sum + d, 0) + initiative_bonus(f)


# Faction-wide and non-stacking: the best bonus any living member brings.
func initiative_bonus(f: Faction) -> int:
	var best := 0
	for u in members(f):
		best = maxi(best, u.initiative_bonus())
	return best


# Orders sides best-first. Each key is tried in turn, then the side's best luck, then its total
# dexterity; a coin decides only sides still tied after all of that.
# A side is a Unit, a Faction, or an Array of Units (e.g. "Company A").
func contest(sides: Array, keys: Array[Callable] = []) -> Array:
	var chain: Array = keys.duplicate()
	chain.append_array([best_luck, dexterity])
	var groups := [sides.duplicate()]
	for key: Callable in chain:
		var split := []
		for g: Array in groups:
			if g.size() < 2:
				split.append(g)
				continue
			var by := {}
			for side in g:
				by.get_or_add(snappedf(float(key.call(side)), 0.0001), []).append(side)  # 10 == 10.0
			var values := by.keys()
			values.sort()
			values.reverse()
			for v in values:
				split.append(by[v])
		groups = split
	var out := []
	for g: Array in groups:
		out.append_array(_flip(g))
	return out


func best_luck(side) -> int:
	var best := -999
	for u in members(side):
		best = maxi(best, u.luck)
	return best


func dexterity(side) -> int:
	var sum := 0
	for u in members(side):
		sum += u.dexterity
	return sum


# Living units on a side.
func members(side) -> Array[Unit]:
	var pool: Array = []
	if side is Unit:
		pool = [side]
	elif side is Faction:
		pool = units.values().filter(func(u): return u.faction == side)
	elif side is Array:
		pool = side
	var out: Array[Unit] = []
	out.assign(pool.filter(func(u): return u.is_alive()))
	return out


# Coin flips for a still-tied group (a shuffle when more than two).
func _flip(g: Array) -> Array:
	g = g.duplicate()
	for i in range(g.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var t = g[i]
		g[i] = g[j]
		g[j] = t
	return g


# Uses an active skill on a target in range. Direct damage skips mitigation.
func cast(caster: Unit, skill: Skill, target: Unit) -> bool:
	if phase != Phase.TURNS or caster.faction != turn:
		return false
	if skill not in caster.actives or not caster.is_alive() or not target.is_alive():
		return false
	if skill.hostile == (target.faction == caster.faction):
		return false
	if not in_radius(caster.cell, target.cell, skill.radius):
		return false
	if not caster.spend(skill.cost):
		return false
	for e in skill.effects:
		target.afflict(e)
	target.damage(skill.damage)
	return true


# Circle, not diamond: straight-line distance between cell centres.
func in_radius(a: Vector2i, b: Vector2i, r: float) -> bool:
	return Vector2(a).distance_to(Vector2(b)) <= r + 0.0001


# Straight-line move up to `movement` tiles (a circle; luck past 1 adds 0.1 reach per point).
# Each tile of movement passes the nearest tile on the line; when tiles are equally near, the
# lucky pick better ground, the unlucky worse, and luck 0 flips a coin. Returns the tiles passed.
func travel(u: Unit, dest: Vector2i) -> Array[Vector2i]:
	var passed: Array[Vector2i] = []
	if not u.is_alive() or dest == u.cell or unit_at(dest) or not on_map(dest):
		return passed
	var d := Vector2(u.cell).distance_to(Vector2(dest))
	if d > u.movement + Luck.reach(u.luck) + 0.0001:
		return passed
	var steps := ceili(d - 0.0001)
	var avoid: Array[Vector2i] = [u.cell, dest]  # don't "pass" the start, or reach the end early
	for k in range(1, steps + 1):
		if k == steps:
			avoid.erase(dest)
		var c := _nearest(Vector2(u.cell).lerp(Vector2(dest), float(k) / steps), u.luck, avoid)
		if not on_map(c):
			passed.clear()  # holes in the map block the line
			return passed
		passed.append(c)
	move(u, dest)
	return passed


func on_map(c: Vector2i) -> bool:
	return map.get_cell_source_id(c) != -1


# Tile custom data "effect": -1 bad, 0 neutral, +1 good.
func tile_effect(c: Vector2i) -> int:
	var t := map.get_cell_tile_data(c)
	return t.get_custom_data("effect") if t else 0


# The tile nearest a point on the path, never one of `avoid` (start tile, or the destination
# before the last step) if anything else is as near. Ties go through contest() on tile effect:
# lucky units want the best ground, unlucky the worst, luck 0 leaves it to the coin.
func _nearest(p: Vector2, luck: int, avoid: Array[Vector2i] = []) -> Vector2i:
	var near: Array[Vector2i] = []
	for x in _axis(p.x):
		for y in _axis(p.y):
			if on_map(Vector2i(x, y)):
				near.append(Vector2i(x, y))
	if near.is_empty():
		return Vector2i(p.round())
	var fresh := near.filter(func(c): return c not in avoid)
	if not fresh.is_empty():
		near.assign(fresh)
	return contest(near, [func(c: Vector2i) -> int: return signi(luck) * tile_effect(c)])[0]


# Cells nearest a coordinate: one, or both neighbours when it sits exactly between them.
func _axis(v: float) -> Array[int]:
	var out: Array[int] = [roundi(v)]
	if is_equal_approx(v - floorf(v), 0.5):
		out.assign([floori(v), ceili(v)])
	return out


func end_turn() -> void:
	if phase != Phase.TURNS:
		return
	for u in members(turn):
		u.tick()
	turn = order[(order.find(turn) + 1) % order.size()]


func _on_died(u: Unit) -> void:
	units.erase(u.cell)
	for o in units.values():
		if o.faction == u.faction:
			return  # faction still standing
	var i := order.find(u.faction)
	order.erase(u.faction)
	if order.size() < 2:
		phase = Phase.OVER
	elif turn == u.faction:
		turn = order[i % order.size()]


func _enter(p: Phase) -> void:
	match p:
		Phase.INITIATIVE:
			order = roll_initiative()
			phase = Phase.TURNS if order.size() > 1 else Phase.OVER
		Phase.TURNS:
			turn = order[0]


func _exit(_p: Phase) -> void:
	pass
