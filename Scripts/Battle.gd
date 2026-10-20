class_name Battle
extends Node2D

signal phase_changed(was: Phase, now: Phase)
signal turn_changed(was: Faction, now: Faction)
signal initiative_rolled(rolls: Dictionary[Faction, Array])

enum Phase { INITIATIVE, TURNS, OVER }

const PLAIN := preload("res://Terrain/grass.tres")  # tiles with no terrain set
const UNIT := preload("res://Scenes/unit.tscn")

@export var spawns: Dictionary[Faction, Vector2i] = {}  # where a player's starter joins each side

var phase := Phase.INITIATIVE:
	set(v):
		if v == phase:
			return
		var was := phase
		phase = v
		phase_changed.emit(was, v)  # before _enter, so a chained change arrives in order
		_enter(v)

# Whose turn it is. Its units get fresh AP and movement as it starts.
var turn: Faction:
	set(v):
		if v == turn:
			return
		var was := turn
		turn = v
		for u in members(v):
			u.refresh()
		turn_changed.emit(was, v)

var order: Array[Faction] = []  # turn order, highest initiative first
var rolls: Dictionary[Faction, Array] = {}  # this battle's initiative d20s, per faction

# Which unit stands on which cell. TileSet custom data is per tile type, so it can't hold this.
var units: Dictionary[Vector2i, Unit] = {}

var rng := RandomNumberGenerator.new()

@onready var map: TileMapLayer = $Map


func _ready() -> void:
	if Game.starter:
		$Units.add_child(starter(Game.starter), true)
		Game.starter = {}  # used up
	for u: Unit in $Units.get_children():
		if not move(u, u.cell):
			push_error("%s has no free cell at %s" % [u.name, u.cell])
			u.free()
			continue
		u.died.connect(_on_died)
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


# The player's starter unit from the entry screen: {faction, role, name}.
func starter(s: Dictionary) -> Unit:
	var u: Unit = UNIT.instantiate()
	u.name = s.name.validate_node_name()
	u.nick = s.name
	u.faction = s.faction
	u.role = s.role
	for k in s.role.stats:
		assert(k in Unit.CORE, "role stat %s isn't a unit stat" % k)
		u.set(k, s.role.stats[k])
	assert(s.faction in spawns, "no spawn for %s" % s.faction.name)
	u.cell = spawns[s.faction]
	return u


# --- Initiative and tie-breaks

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
		best = maxi(best, roundi(u.stat(&"initiative")))
	return best


# Orders sides best-first. Each key is tried in turn, then the side's best luck, then its total
# dexterity; a coin decides only sides still tied after all of that.
# A side is a Unit, a Faction, an Array of Units (e.g. "Company A"), or anything the keys rank.
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
		sum += roundi(u.stat(&"dexterity"))
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
	out.assign(pool.filter(func(u): return u is Unit and u.is_alive()))
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


# --- Skills

# Uses an active skill on a target in reach, paying its AP and cost. Damage comes from the skill's
# tier for the caster's rank, once per rank for multi-hit skills (Strike III).
func cast(caster: Unit, skill: Skill, target: Unit) -> bool:
	if not _acting(caster) or skill not in caster.actives or not target.is_alive():
		return false
	if skill.hostile == (target.faction == caster.faction) or not in_reach(caster, skill, target):
		return false
	if not caster.pay_for(skill):
		return false
	var r := caster.rank(skill)
	for e in skill.effects + (skill.grants.effects if skill.grants else ([] as Array[Effect])):
		target.afflict(e, skill.turns, r)
	var t := skill.tier(r)
	if not t:
		return true
	assert(t.stat == &"" or t.stat in Unit.CORE, "%s scales on unknown stat %s" % [skill.name, t.stat])
	var hits := r if skill.hits_per_rank else 1
	for i in hits:
		if not target.is_alive():
			break
		var power := maxi(t.power + roll(t.dice) + (caster.mod(t.stat, skill.tags) if t.stat else 0), 0)
		if t.direct:
			target.damage(power)
		else:
			target.hit(power, skill.tags, caster)
	return true


# Dice as Vector2i(count, sides): Vector2i(1, 6) is d6.
func roll(dice: Vector2i) -> int:
	var sum := 0
	for i in dice.x:
		sum += rng.randi_range(1, dice.y)
	return sum


# Skill range + the caster's reach (its reach stat, +0.05 per size point) + 0.02 per size point
# of the target (bigger targets are easier to reach).
func skill_range(caster: Unit, skill: Skill, target: Unit) -> float:
	return skill.radius + caster.stat(&"reach") + 0.05 * caster.stat(&"size") + 0.02 * target.stat(&"size")


# Circle geometry. A near miss (within Luck.MARGIN) is rounding: in only if the caster is luckier.
func in_reach(caster: Unit, skill: Skill, target: Unit) -> bool:
	var over := Vector2(caster.cell).distance_to(Vector2(target.cell)) - skill_range(caster, skill, target)
	if over <= 0.0001:
		return true
	return over < Luck.MARGIN and caster.luck - target.luck > 0


# --- Movement

# Walks the straight line toward `dest`, paying movement and the same AP per step: leaving a tile
# costs its exit, entering costs its enter (plus the unit's move_cost effects for that ground).
# Stops where movement or AP runs out, before a hole, and short of other units. Short by a
# fraction, net luck can squeeze one more tile in - but never luckily onto secretly bad ground.
# Returns the tiles passed.
func travel(u: Unit, dest: Vector2i) -> Array[Vector2i]:
	var passed: Array[Vector2i] = []
	if not _acting(u) or dest == u.cell:
		return passed
	var left := minf(u.stat(&"movement") - u.moved, u.ap_for(&"move"))
	var spent: Array[float] = []
	var at := u.cell
	for c in line(u.cell, dest, u.luck, u):
		if not on_map(c) or left <= 0.0001:
			break
		var t := terrain(c)
		var cost := step(u, at, c)
		if cost > left + 0.0001:
			var trap := t.hidden and t.worth() < 0
			if Luck.settle(left / cost, u.luck, not trap, false) < 1:
				break
			cost = left  # squeezed in on what was left
		left -= cost
		spent.append(cost)
		passed.append(c)
		at = c
	while not passed.is_empty() and unit_at(passed[-1]):  # units can be passed, not stood on
		passed.pop_back()
		spent.pop_back()
	if not passed.is_empty():
		var total_cost: float = spent.reduce(func(sum, x): return sum + x, 0.0)
		u.moved += total_cost
		u.pay(total_cost, &"move")
		move(u, passed[-1])
	return passed


# Movement to step from one tile onto the next: leaving costs `from`'s exit, entering costs `to`'s
# enter, plus the unit's move_cost effects for that ground (u may be null: terrain only).
func step(u: Unit, from: Vector2i, to: Vector2i) -> float:
	var t := terrain(to)
	return maxf(terrain(from).exit + t.enter + (u.stat(&"move_cost", t.tags) if u else 0.0), 0.0)


# The straight line from a to b as ceil(distance) distinct tiles, each the one nearest its point
# on the line (never one already passed). Equally near tiles go through contest(): better and
# cheaper ground (entering and leaving it) for the lucky, worse for the unlucky, a coin at luck 0.
func line(a: Vector2i, b: Vector2i, luck: int, u: Unit = null) -> Array[Vector2i]:
	var path: Array[Vector2i] = []
	var n := ceili(Vector2(a).distance_to(Vector2(b)) - 0.0001)
	var s := signi(luck)
	for k in range(1, n):
		var p := Vector2(a).lerp(Vector2(b), float(k) / n)
		var near := []
		for x in [floori(p.x), ceili(p.x)]:
			for y in [floori(p.y), ceili(p.y)]:
				var c := Vector2i(x, y)
				if c not in near and c != a and c != b and c not in path:
					near.append(c)
		if near.is_empty():
			near = [Vector2i(p.round())]
		var prev: Vector2i = path.back() if path else a
		path.append(contest(near, [
			func(c: Vector2i) -> float: return -snappedf(Vector2(c).distance_to(p), 0.0001),
			func(c: Vector2i) -> int: return int(on_map(c)),
			func(c: Vector2i) -> int: return s * terrain(c).worth(),
			func(c: Vector2i) -> float: return -s * (step(u, prev, c) + terrain(c).exit),
		])[0])
	if n > 0:
		path.append(b)
	return path


func on_map(c: Vector2i) -> bool:
	return map.get_cell_source_id(c) != -1


func terrain(c: Vector2i) -> Terrain:
	var d := map.get_cell_tile_data(c)
	var t: Terrain = d.get_custom_data("terrain") if d else null
	return t if t else PLAIN


# --- Turns

func end_turn() -> void:
	if phase != Phase.TURNS:
		return
	for u in members(turn):
		u.tick()
	turn = order[(order.find(turn) + 1) % order.size()]


func _acting(u: Unit) -> bool:
	return phase == Phase.TURNS and u.faction == turn and u.is_alive()


func _on_died(u: Unit) -> void:
	units.erase(u.cell)
	u.timed.clear()  # nothing ticks for the dead
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
