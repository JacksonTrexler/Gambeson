class_name Battle
extends Node2D

signal phase_changed(was: Phase, now: Phase)
signal turn_changed(was: Faction, now: Faction)
signal initiative_rolled(rolls: Dictionary[Faction, Array])
signal traveled(u: Unit, from: Vector2i, path: Array[Vector2i])
signal used(caster: Unit, skill: Skill, at: Variant, dealt: int)  # at: the target Unit, or a cell
signal sprung(c: Vector2i, by: Unit)

enum Phase { INITIATIVE, TURNS, OVER }

const PLAIN := preload("res://Terrain/grass.tres")  # tiles with no terrain set
const UNIT := preload("res://Scenes/unit.tscn")
const MEDIUM := 3  # size assumed for a target not yet chosen
const PASS_SHARE := 0.1  # of the size penalty for moving through a unit, taken off per point of dex mod

@export var spawns: Dictionary[Faction, Vector2i] = {}  # where a player's starter joins each side

var player: Unit  # the starter made on the entry screen; null when there's none

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
		for u in members(v):  # after the signal: poison can end a side, and with it this turn
			_mend(u)

var order: Array[Faction] = []  # turn order, highest initiative first
var rolls: Dictionary[Faction, Array] = {}  # this battle's initiative d20s, per faction
var unit_rolls: Dictionary[Unit, int] = {}  # the same d20s, by who rolled them

# Which unit stands on which cell. TileSet custom data is per tile type, so it can't hold this.
var units: Dictionary[Vector2i, Unit] = {}

var rng := RandomNumberGenerator.new()
var zones: Array[Zone] = []  # areas laid by skills (Darkstone's darkness)
var revealed: Dictionary[Vector2i, bool] = {}  # sprung traps: no longer concealed
var snares: Dictionary[Vector2i, Snare] = {}  # traps units have laid (lay()), over the ground


# A trap a unit laid on a tile. Who knows of it sees it plainly; with Hazard Expert (`word`), its
# setter's allies who weren't told still get a vibe that traps were set there.
class Snare:
	var terrain: Terrain  # the ground with the trap in it, standing in for the map's (Battle.terrain())
	var by: Unit
	var faction: Faction
	var known: Dictionary[Unit, bool] = {}
	var word := false

	func _init(t: Terrain, u: Unit) -> void:
		terrain = t
		by = u
		faction = u.faction


# Concealment laid over tiles: levels by cell, lasting some of the caster faction's turns.
class Zone:
	var kind: StringName
	var levels: Dictionary[Vector2i, int]
	var turns: int
	var faction: Faction

	func _init(k: StringName, l: Dictionary[Vector2i, int], t: int, f: Faction) -> void:
		kind = k
		levels = l
		turns = t
		faction = f

@onready var map: TileMapLayer = $Map


func _ready() -> void:
	if Game.starter:
		player = starter(Game.starter)
		$Units.add_child(player, true)
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
	u.footing = terrain(c)
	u.ground = u.footing.tags
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
	unit_rolls.clear()
	for u in units.values():
		if u.faction and u.is_alive():
			if u.faction not in rolls:
				rolls[u.faction] = []
			unit_rolls[u] = rng.randi_range(1, 20)
			rolls[u.faction].append(unit_rolls[u])
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
	if not _acting(caster) or skill not in caster.actives or skill.on_tile() or not target.is_alive():
		return false
	if skill.hostile == (target.faction == caster.faction) or not in_reach(caster, skill, target):
		return false
	if not caster.pay_for(skill):
		return false
	var r := caster.rank(skill)
	var before := target.hp
	for e in skill.effects + (skill.grants.effects if skill.grants else ([] as Array[Effect])):
		target.afflict(e, e.turns if e.turns else skill.turns, r)
	var t := skill.tier(r)
	if t:
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
	if skill.hostile:
		_expose(target)
		_expose(caster)
	used.emit(caster, skill, target, before - target.hp)
	return true


# A hostile skill aimed at a tile rather than at a unit the caster can make out (the player's
# Ctrl-click): whoever is there takes it as an ordinary cast. If it doesn't land - nobody there, or
# not quite in reach of what is - it's spent on thin air, as long as the tile itself was in reach
# of a Medium target. Returns &"hit", &"miss", or &"" when it couldn't be tried at all.
func attempt(caster: Unit, skill: Skill, c: Vector2i) -> StringName:
	if not _acting(caster) or skill not in caster.actives or not skill.hostile or skill.zone != &"" or not on_map(c):
		return &""
	var t := unit_at(c)
	if t and t != caster and cast(caster, skill, t):
		return &"hit"
	if Vector2(caster.cell).distance_to(Vector2(c)) > skill_range(caster, skill) + 0.0001 or not caster.pay_for(skill):
		return &""
	used.emit(caster, skill, c, 0)
	return &"miss"


# Hitting a unit, or attacking, gives away where it is: a hidden one loses a level of concealment
# until its side's next turn starts.
func _expose(u: Unit) -> void:
	if Perception.cover(self, u) > 0:
		u.exposed += 1


# Skills cast on a cell, within area_reach(): area skills (Darkstone) lay their zone kind of
# concealment on the tiles around it (see zone_levels()); trap skills (Snare) lay a trap there (lay()).
func cast_at(caster: Unit, skill: Skill, c: Vector2i) -> bool:
	if not _acting(caster) or skill not in caster.actives or not skill.on_tile() or not on_map(c):
		return false
	if Vector2(caster.cell).distance_to(Vector2(c)) > area_reach(caster, skill) + 0.0001:
		return false
	if skill.lays and (unit_at(c) or terrain(c).is_trap()):
		return false
	if not caster.pay_for(skill):
		return false
	if skill.lays:
		lay(caster, skill, c)
	else:
		zones.append(Zone.new(skill.zone, zone_levels(caster.rank(skill), c), skill.turns, caster.faction))
	used.emit(caster, skill, c, 0)
	return true


# A trap skill's trap, laid into the ground at c: the skill's `lays` with its concealment and dice
# multiplier times the setter's rank, plus the setter's mod in its bonus stat. The setter knows it;
# for skills tagged trap, so do allies within its charisma mod in tiles (at least 1; trap_word
# multiplies that: Hazard Expert), and with trap_word, allies further off get a vibe of it.
func lay(u: Unit, skill: Skill, c: Vector2i) -> Snare:
	var r := u.rank(skill)
	var ground := terrain(c)
	var t: Terrain = ground.duplicate()
	var plan := skill.lays
	t.name = plan.name
	var tags: Array[StringName] = []
	tags.assign(ground.tags + plan.tags)
	t.tags = tags
	t.concealment = plan.concealment * r
	t.kind = plan.kind
	t.looks_like = StringName(ground.name)
	t.shape = plan.shape
	t.vibe = plan.vibe
	t.dice = plan.dice
	t.times = plan.times * r
	t.bonus = plan.bonus + (u.mod(plan.bonus_stat, skill.tags) if plan.bonus_stat else 0)
	t.damage_tags = plan.damage_tags
	t.blast = plan.blast
	t.reveals = plan.reveals
	var snare := Snare.new(t, u)
	snare.known[u] = true
	if &"trap" in skill.tags:
		var word := maxf(u.mod(&"charisma"), 1.0) * (1.0 + u.stat(&"trap_word"))
		for o in members(u.faction):
			if roundi(Vector2(o.cell).distance_to(Vector2(u.cell))) <= word:
				snare.known[o] = true
		snare.word = u.stat(&"trap_word") > 0.0
	snares[c] = snare
	revealed.erase(c)
	return snare


# How far from the caster an area skill can be centred: radius + radius_per_rank x rank.
func area_reach(caster: Unit, skill: Skill) -> float:
	return skill.radius + skill.radius_per_rank * caster.rank(skill)


# The levels an area skill of rank r lays around c: rank - distance on every tile that leaves above 0.
func zone_levels(r: int, c: Vector2i) -> Dictionary[Vector2i, int]:
	var levels: Dictionary[Vector2i, int] = {}
	for x in range(c.x - r, c.x + r + 1):
		for y in range(c.y - r, c.y + r + 1):
			var at := Vector2i(x, y)
			var lv := r - floori(Vector2(at).distance_to(Vector2(c)))
			if lv > 0 and on_map(at):
				levels[at] = lv
	return levels


# A tile whose terrain is still concealed (an unsprung trap).
func hidden(c: Vector2i) -> bool:
	return terrain(c).concealment > 0 and c not in revealed


func read(o: Unit, target: Variant) -> Read:
	return Perception.unit(self, o, target) if target is Unit else Perception.tile(self, o, target)


# Dice as Vector2i(count, sides): Vector2i(1, 6) is d6.
func roll(dice: Vector2i) -> int:
	var sum := 0
	for i in dice.x:
		sum += rng.randi_range(1, dice.y)
	return sum


# Skill range + the caster's reach (its reach stat, +0.05 per size point) + 0.02 per size point
# of the target (bigger targets are easier to reach). No target: a Medium one.
func skill_range(caster: Unit, skill: Skill, target: Unit = null) -> float:
	var size: float = target.stat(&"size") if target else float(MEDIUM)
	return skill.radius + caster.stat(&"reach") + 0.05 * caster.stat(&"size") + 0.02 * size


# Circle geometry. A near miss (within Luck.MARGIN) is rounding: in only if the caster is luckier.
func in_reach(caster: Unit, skill: Skill, target: Unit) -> bool:
	var over := Vector2(caster.cell).distance_to(Vector2(target.cell)) - skill_range(caster, skill, target)
	if over <= 0.0001:
		return true
	return over < Luck.MARGIN and caster.luck - target.luck > 0


# --- Movement

# Walks the straight line toward `dest` (see walk()), paying movement and the same AP per step.
# A trap it stops on springs. Returns the tiles passed.
func travel(u: Unit, dest: Vector2i) -> Array[Vector2i]:
	var passed: Array[Vector2i] = []
	if not _acting(u) or dest == u.cell:
		return passed
	var w := walk(u, dest)
	passed = w.path
	if not passed.is_empty():
		var from := u.cell
		var total_cost: float = w.costs.reduce(func(sum, x): return sum + x, 0.0)
		u.moved += total_cost  # a Relay boost can take it below what it's walked
		u.pay(maxf(total_cost, 0.0), &"move")
		move(u, passed[-1])
		for c in passed:  # stepping in happens on the unit's own turn, which isn't one of those counted
			for e in terrain(c).afflicts:
				u.afflict(e, (e.turns if e.turns else terrain(c).turns) + 1)
		traveled.emit(u, from, passed)
		if terrain(u.cell).is_trap():
			spring(u.cell, u)
	return passed


# The walk toward `dest`: {line, path, costs} - the straight line, the tiles kept, and what each
# cost. Leaving a tile costs its exit, entering costs its enter (plus the unit's move_cost effects
# for that ground), and moving through another unit costs pass_cost(). Stops where movement or AP
# runs out, before a hole, short of other units (they can be passed, not stood on), and on a trap.
# Short by a fraction, net luck can squeeze one more tile in - but never luckily onto ground the
# unit doesn't know is bad.
# `expected` gives the walk as `u` sees it coming: ground it can't make out counts as plain, units it
# can't locate aren't in the way, and the rng is left as it was (so the real walk takes this line).
func walk(u: Unit, dest: Vector2i, expected := false) -> Dictionary:
	var state := rng.state
	var ground := func(c: Vector2i) -> Terrain:
		return terrain(c) if not expected or read(u, c).net >= 0 else PLAIN
	var in_way := func(c: Vector2i) -> Unit:
		var o := unit_at(c)
		return o if o and o != u and (not expected or read(u, o).located()) else null
	var blocked := func(c: Vector2i) -> bool:
		return in_way.call(c) != null
	var path: Array[Vector2i] = []
	var costs: Array[float] = []
	var left := u.move_left()
	var ln := line(u.cell, dest, u.luck, u)
	var from: Terrain = ground.call(u.cell)
	for c in ln:
		if not on_map(c) or left <= 0.0001:
			break
		var t: Terrain = ground.call(c)
		var cost := _cost(u, from, t)
		var other: Unit = in_way.call(c)
		if other:
			cost += pass_cost(u, other)
		if cost > left + 0.0001:
			var unknown_bad := t.worth() < 0 and not read(u, c).known_bad()
			if Luck.settle(left / cost, u.luck, not unknown_bad, false) < 1:
				break
			cost = left  # squeezed in on what was left
		left -= cost
		costs.append(cost)
		path.append(c)
		from = t
		if t.is_trap() and not blocked.call(c):
			break  # stepped on a trap
	while not path.is_empty() and blocked.call(path[-1]):  # units can be passed, not stood on
		path.pop_back()
		costs.pop_back()
	if expected:
		rng.state = state
	return {line = ln, path = path, costs = costs}


# Extra movement for u to move through o's tile: o's size, less a share per point of dex mod - u's,
# and o's too if they're allies (it steps aside) - and per point of strength mod with Relay (u's,
# and an ally o's: it gives u a shove). Only Relay can take it below 0, a boost onward.
func pass_cost(u: Unit, o: Unit) -> float:
	var ally := o.faction == u.faction
	var off := PASS_SHARE * (u.mod(&"dexterity") + (o.mod(&"dexterity") if ally else 0))
	var relay := _relay(u) + (_relay(o) if ally else 0.0)
	var cost := o.stat(&"size") * (1.0 - off - relay)
	return cost if relay > 0.0 else maxf(cost, 0.0)


func _relay(u: Unit) -> float:
	return maxf(u.stat(&"relay") * u.mod(&"strength"), 0.0)


# A trap goes off: most are revealed for good (Terrain.reveals), and it hits whoever stepped on it
# plus anyone in its blast. Units with Wary V (trap_power) make the traps they set off hit their
# enemies harder.
func spring(c: Vector2i, by: Unit) -> void:
	var t := terrain(c)
	if t.reveals:
		revealed[c] = true
	sprung.emit(c, by)
	var raw := roll(t.dice) * t.times + t.bonus
	for v in units.values().filter(func(x): return x == by or Vector2(x.cell).distance_to(Vector2(c)) <= t.blast + 0.0001):
		var boost := 1.0 + (by.stat(&"trap_power") if v.faction != by.faction else 0.0)
		v.hit(raw * boost, t.damage_tags)


# Movement to step from one tile onto the next: leaving costs `from`'s exit, entering costs `to`'s
# enter, plus the unit's move_cost effects for that ground (u may be null: terrain only).
func step(u: Unit, from: Vector2i, to: Vector2i) -> float:
	return _cost(u, terrain(from), terrain(to))


func _cost(u: Unit, from: Terrain, to: Terrain) -> float:
	return maxf(from.exit + to.enter + (u.stat(&"move_cost", to.tags) if u else 0.0), 0.0)


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
	if c in snares:
		return snares[c].terrain
	var d := map.get_cell_tile_data(c)
	var t: Terrain = d.get_custom_data("terrain") if d else null
	return t if t else PLAIN


# --- Turns

# As a unit's side starts its turn: regen heals that fraction of its max HP, then poison takes that
# fraction (each rounded by its luck).
func _mend(u: Unit) -> void:
	var regen := u.stat(&"regen")
	if regen > 0.0:
		u.heal(Luck.settle(regen * u.max_hp, u.luck, true))
	var poison := u.stat(&"poison")
	if poison > 0.0 and u.is_alive():
		u.damage(Luck.settle(poison * u.max_hp, u.luck, false))


# The turn passes. Ground puts its turn-end effects on whoever is on it (Magic Stew); a sleeper
# with an ally beside it wakes up; then timed effects count down and zones wear off.
func end_turn() -> void:
	if phase != Phase.TURNS:
		return
	var side := members(turn)
	for u in side:
		for e in u.footing.at_end if u.footing else ([] as Array[Effect]):
			u.afflict(e, (e.turns if e.turns else u.footing.turns) + 1)  # + 1: the tick below takes this turn
	for u in side:
		if u.asleep() and side.any(func(o: Unit): return o != u and next_to(o.cell, u.cell)):
			u.wake()
	for u in side:
		u.tick()
	for z in zones.filter(func(x: Zone): return x.faction == turn):
		z.turns -= 1
	zones.assign(zones.filter(func(x: Zone): return x.turns > 0))
	turn = order[(order.find(turn) + 1) % order.size()]


func _acting(u: Unit) -> bool:
	return phase == Phase.TURNS and u.faction == turn and u.is_alive() and not u.asleep()


# Touching, diagonals included.
static func next_to(a: Vector2i, b: Vector2i) -> bool:
	return a != b and absi(a.x - b.x) <= 1 and absi(a.y - b.y) <= 1


func _on_died(u: Unit) -> void:
	units.erase(u.cell)
	u.timed.clear()  # nothing ticks for the dead
	for o in units.values():
		if o.faction == u.faction:
			return  # faction still standing
	var i := order.find(u.faction)
	order.erase(u.faction)
	zones.assign(zones.filter(func(z: Zone): return z.faction != u.faction))  # nothing left to tick them
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
