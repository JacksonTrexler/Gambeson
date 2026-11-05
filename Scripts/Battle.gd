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
const DC := 10  # base difficulty of checks
const UNIT := preload("res://Scenes/unit.tscn")
const MEDIUM := 3  # size assumed for a target not yet chosen

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
		watches.assign(watches.filter(func(w: Watch): return w.caster.faction != v))  # set "until next round"
		turn_changed.emit(was, v)
		for u in members(v):  # after the signal: poison can end a side, and with it this turn
			_mend(u)

var order: Array[Faction] = []  # turn order, highest initiative first
var rolls: Dictionary[Faction, Array] = {}  # this battle's initiative d20s, per faction

# Which unit stands on which cell. TileSet custom data is per tile type, so it can't hold this.
var units: Dictionary[Vector2i, Unit] = {}

var rng := RandomNumberGenerator.new()
var zones: Array[Zone] = []  # areas laid by skills (Darkstone's darkness)
var exposed: Dictionary[Vector2i, int] = {}  # concealment levels tiles have lost (sprung traps)
var watches: Array[Watch] = []  # Ambush / Coordinate tiles


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

# Ambush / Coordinate: tiles where the caster uses `skill` on whoever it reads as an enemy (or ally)
# stepping in, until its side's next turn. Each tile fires once.
class Watch:
	var caster: Unit
	var skill: Skill
	var cells: Array[Vector2i]
	var any: bool  # on whoever enters, friend or foe

	func _init(c: Unit, s: Skill, at: Array[Vector2i], a: bool) -> void:
		caster = c
		skill = s
		cells = at
		any = a


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
	if not skill.sing and skill.hostile == (target.faction == caster.faction):
		return false
	if skill.sing and (target == caster or caster.stat(&"movement") - caster.moved < 1):
		return false  # Sing is paid for with movement
	if not in_reach(caster, skill, target):
		return false
	if not caster.pay_for(skill):
		return false
	caster.acted = true
	use(caster, skill, target)
	return true


# What a skill does to its target, already paid for (casts, reactions, watches). An attack from a
# unit the target can't make out costs the attacker a level of concealment and gives the target a
# free check to identify it.
func use(caster: Unit, skill: Skill, target: Unit) -> void:
	var r := caster.rank(skill)
	var t := skill.tier(r)
	var before := target.hp
	var unseen := false
	var trusted := false
	if skill.hostile:
		target.provoked = true
		var seen := read(target, caster)
		unseen = (t != null or skill.drown) and (seen.net < 0 or seen.deceived or seen.faction == null)
		trusted = seen.faction == target.faction
	for e in skill.effects + (skill.grants.effects if skill.grants else ([] as Array[Effect])):
		target.afflict(e, e.turns if e.turns else skill.turns, r)
	if skill.sing:
		_sing(caster, skill, target)
	if skill.drown:
		_grab(caster, skill, target)
	if t:
		assert(t.stat == &"" or t.stat in Unit.CORE, "%s scales on unknown stat %s" % [skill.name, t.stat])
		for i in (r if skill.hits_per_rank else 1):
			if not target.is_alive():
				break
			var power := maxi(t.power + roll(t.dice) + (caster.mod(t.stat, skill.tags) if t.stat else 0), 0)
			if trusted and skill.crit_trusting:
				power *= 2  # they never saw it coming
			if t.direct:
				target.damage(power)
			else:
				target.hit(power, skill.tags, caster)
	if skill.hostile:
		_expose(target)
		_expose(caster)
	if unseen and target.is_alive():
		Investigation.run(self, target, caster)
	used.emit(caster, skill, target, before - target.hp)


# Sing, paid for with all the caster's movement left. Allies come when called. Units it's fooling
# must pass a wis check (DC 10 + its cha mod) or take it for a blessing and walk over - and if they
# pass, they see it for what it is. Units onto it lose suspicion of it unless they pass that check.
func _sing(caster: Unit, skill: Skill, target: Unit) -> void:
	caster.moved = caster.stat(&"movement")
	var dc := DC + caster.mod(&"charisma")
	if target.faction == caster.faction:
		_lure(caster, target)
	elif read(target, caster).deceived:
		if check(target, dc):
			Investigation.succeed(self, target, caster)
		else:
			_lure(caster, target)
	elif not check(target, dc):
		target.forget(caster.cell, skill.sing)


# The lured walk up beside the caster, up to their own movement.
func _lure(caster: Unit, target: Unit) -> void:
	var spot: Variant = _beside(caster.cell, target)
	if spot != null:
		travel(target, spot, true)


# The free cell next to `c` that's cheapest for `u` to walk to (its own, if it's already there).
# Planning mustn't use up the battle's rng, so it's restored.
func _beside(c: Vector2i, u: Unit) -> Variant:
	var state := rng.state
	var best: Variant = null
	var best_cost := INF
	for dx in [-1, 0, 1]:
		for dy in [-1, 0, 1]:
			var at := c + Vector2i(dx, dy)
			if at == c or not on_map(at) or (unit_at(at) and unit_at(at) != u):
				continue
			var cost := 0.0
			var prev := u.cell
			for p in line(u.cell, at, u.luck, u):
				cost += step(u, prev, p)
				prev = p
			cost += dist(at, u.cell) * 0.001  # equal cost: nearer
			if cost < best_cost:
				best = at
				best_cost = cost
	rng.state = state
	return best


# Drown: a strength check against DC 10 + the target's str mod (only if it knows what it's facing).
# Grabbed, it's Grappled; unless it's already in water it's dragged into the nearest water within
# the caster's movement left, and the caster comes along (into the water if it can, else beside it).
# Underwater it takes the drown dice + the caster's str mod.
func _grab(caster: Unit, skill: Skill, target: Unit) -> void:
	var aware := not read(target, caster).deceived
	if not check(caster, DC + (target.mod(&"strength") if aware else 0), &"strength"):
		return
	target.grappler = caster
	var pool: Variant = target.cell if &"water" in target.ground else pool_near(target.cell, floori(caster.stat(&"movement") - caster.moved))
	if pool == null:
		return
	if pool != target.cell:
		caster.moved += steps(target.cell, pool)
		move(target, pool)
	if &"water" not in caster.ground or steps(caster.cell, pool) > 1:
		var dive: Variant = pool_near(pool, 1, caster.cell)
		if dive != null and steps(caster.cell, dive) <= caster.stat(&"movement") - caster.moved:
			caster.moved += steps(caster.cell, dive)
			move(caster, dive)
		elif steps(caster.cell, pool) > 1:
			var spot: Variant = _beside(pool, caster)
			if spot != null:
				move(caster, spot)  # dragging it there already took the steps
	var dice := skill.drown_aquatic if target.aquatic() else skill.drown
	target.hit(roll(dice) + caster.mod(&"strength"), [&"drown"], caster)


# The nearest free water tile within `reach` steps of `c`, nearest to `from` (default `c`). Null
# if none.
func pool_near(c: Vector2i, reach: int, from: Variant = null) -> Variant:
	var o: Vector2i = from if from != null else c
	var best: Variant = null
	for x in range(c.x - reach, c.x + reach + 1):
		for y in range(c.y - reach, c.y + reach + 1):
			var at := Vector2i(x, y)
			if not on_map(at) or unit_at(at) or &"water" not in terrain(at).tags:
				continue
			if best == null or dist(at, o) < dist(best, o):
				best = at
	return best


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
	caster.acted = true
	used.emit(caster, skill, c, 0)
	return &"miss"


# Hitting a unit, or attacking, gives away where it is: a hidden one loses a level of concealment
# until its side's next turn starts.
func _expose(u: Unit) -> void:
	if Perception.cover(self, u) > 0:
		u.exposed += 1


# Area skills, cast on a cell (Darkstone): within area_reach(), lays its zone kind of concealment
# on the tiles around the centre (see zone_levels()).
func cast_at(caster: Unit, skill: Skill, c: Vector2i) -> bool:
	if not _acting(caster) or skill not in caster.actives or skill.zone == &"" or not on_map(c):
		return false
	if dist(caster.cell, c) > area_reach(caster, skill) + 0.0001:
		return false
	if not caster.pay_for(skill):
		return false
	caster.acted = true
	zones.append(Zone.new(skill.zone, zone_levels(caster.rank(skill), c), skill.turns, caster.faction))
	used.emit(caster, skill, c, 0)
	return true


# How far from the caster an area skill can be centred: radius + radius_per_rank x rank.
func area_reach(caster: Unit, skill: Skill) -> float:
	return skill.radius + skill.radius_per_rank * caster.rank(skill)


# The levels an area skill of rank r lays around c: rank - distance on every tile that leaves above 0.
func zone_levels(r: int, c: Vector2i) -> Dictionary[Vector2i, int]:
	var levels: Dictionary[Vector2i, int] = {}
	for x in range(c.x - r, c.x + r + 1):
		for y in range(c.y - r, c.y + r + 1):
			var at := Vector2i(x, y)
			var lv := r - floori(dist(at, c))
			if lv > 0 and on_map(at):
				levels[at] = lv
	return levels


# Ambush / Coordinate: watch up to rank tiles within `skill`'s range (an offensive skill for an
# ambush, a support skill to coordinate). `any`: fire on whoever enters, not just those read as
# enemies (allies).
func set_watch(caster: Unit, which: Skill, skill: Skill, cells: Array[Vector2i], any := false) -> bool:
	if not _acting(caster) or which not in caster.actives or skill not in caster.actives or not which.watch:
		return false
	if skill.hostile != which.hostile or cells.is_empty() or cells.size() > caster.rank(which):
		return false
	for c in cells:
		if not on_map(c) or dist(caster.cell, c) > skill_range(caster, skill) + 0.0001:
			return false
	if not caster.pay_for(which):
		return false
	caster.acted = true
	watches.append(Watch.new(caster, skill, cells.duplicate(), any))
	return true


# A tile whose terrain still has concealment left (traps not yet fully exposed).
func hidden(c: Vector2i) -> bool:
	return terrain(c).concealment - exposed.get(c, 0) > 0


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
	var r := skill.radius + caster.stat(&"reach") + 0.05 * caster.stat(&"size") + 0.02 * size
	return r + (caster.mod(skill.radius_stat) if skill.radius_stat else 0)


static func dist(a: Vector2i, b: Vector2i) -> float:
	return Vector2(a).distance_to(Vector2(b))


# Steps between cells, diagonals counting as 1 (drags, grapples, being beside something).
static func steps(a: Vector2i, b: Vector2i) -> int:
	return maxi(absi(a.x - b.x), absi(a.y - b.y))


# d20 + a stat mod (wisdom unless said) against `dc`. Meeting it exactly passes, unless the unit's
# luck is negative (the unlucky fail checks they'd otherwise pass).
func check(u: Unit, dc: int, stat := &"wisdom") -> bool:
	var total := rng.randi_range(1, 20) + u.mod(stat)
	return total > dc or (total == dc and u.luck >= 0)


# Circle geometry. A near miss (within Luck.MARGIN) is rounding: in only if the caster is luckier.
func in_reach(caster: Unit, skill: Skill, target: Unit) -> bool:
	var over := dist(caster.cell, target.cell) - skill_range(caster, skill, target)
	if over <= 0.0001:
		return true
	return over < Luck.MARGIN and caster.luck - target.luck > 0


# --- Movement

# Walks the straight line toward `dest` (see walk()), paying movement and the same AP per step.
# A trap it stops on springs, a watched tile it crosses fires, and running into an enemy bumps it.
# Held (Drown), it must break free first. Ends with a look around (a contact check). `compelled`
# (lured): its full movement, paid for by whoever compelled it. Returns the tiles passed.
func travel(u: Unit, dest: Vector2i, compelled := false) -> Array[Vector2i]:
	var passed: Array[Vector2i] = []
	if not (compelled or _acting(u)) or dest == u.cell or not u.is_alive():
		return passed
	if u.grappler and not compelled and not _break_free(u):
		return passed
	var had: Variant = Investigation.lead(self, u)
	var w := walk(u, dest, false, compelled)
	passed = w.path
	if not passed.is_empty():
		var from := u.cell
		if not compelled:
			var total_cost: float = w.costs.reduce(func(sum, x): return sum + x, 0.0)
			u.moved += total_cost
			u.pay(total_cost, &"move")
		move(u, passed[-1])
		for c in passed:  # stepping in happens on the unit's own turn, which isn't one of those counted
			for e in terrain(c).afflicts:
				u.afflict(e, (e.turns if e.turns else terrain(c).turns) + 1)
		traveled.emit(u, from, passed)
		if terrain(u.cell).is_trap():
			spring(u.cell, u)
	if (not passed.is_empty() or w.bumped) and not compelled:
		u.acted = true
	for x: Watch in w.fired:  # in reach of the watched tile was checked when it fired
		if u.is_alive() and x.caster.is_alive():
			use(x.caster, x.skill, u)
	if w.bumped and u.is_alive():
		bump(u, w.bumped)
	if not passed.is_empty() and u.is_alive() and not compelled:  # the lured think nothing of it
		var now: Variant = Investigation.lead(self, u)
		if now != null and (typeof(now) != typeof(had) or now != had):
			Investigation.run(self, u, now)  # something new came into range
	return passed


# Held: breaking free costs the grappler's str mod in movement (at least 1), and a str check.
func _break_free(u: Unit) -> bool:
	var g := u.grappler
	if not g.is_alive() or steps(g.cell, u.cell) > 1:
		u.grappler = null
		return true
	var cost := maxf(g.mod(&"strength"), 1)
	if u.move_left() < cost:
		return false
	u.moved += cost
	u.pay(cost, &"move")
	u.acted = true
	if not check(u, DC + g.mod(&"strength"), &"strength"):
		return false
	u.grappler = null
	return true


# The walk toward `dest`: {line, path, costs, bumped, fired} - the straight line, the tiles kept,
# what each cost, the enemy it ran into (or null) and the watches it set off. Leaving a tile costs
# its exit, entering costs its enter (plus the unit's move_cost effects for that ground). Stops
# where movement or AP runs out, before a hole, short of other units, on a trap, on an ambushed
# tile and short of an enemy (allies can be passed). Short by a fraction, net luck can squeeze one
# more tile in - but never luckily onto ground the unit doesn't know is bad.
# `expected` gives the walk as `u` sees it coming: ground it can't make out counts as plain, units it
# can't locate aren't in the way, ambushes don't show, and the rng is left as it was (so the real
# walk takes this line). The real walk uses up the watched tiles it sets off.
func walk(u: Unit, dest: Vector2i, expected := false, compelled := false) -> Dictionary:
	var state := rng.state
	var ground := func(c: Vector2i) -> Terrain:
		return terrain(c) if not expected or read(u, c).net >= 0 else PLAIN
	var blocked := func(c: Vector2i) -> bool:
		var o := unit_at(c)
		return o != null and (not expected or read(u, o).located())
	var enemy := func(c: Vector2i) -> Unit:
		var o := unit_at(c)
		if not o or o == u:
			return null
		if not expected:
			return o if o.faction != u.faction else null
		var r := read(u, o)
		return o if r.located() and r.faction != u.faction else null
	var path: Array[Vector2i] = []
	var costs: Array[float] = []
	var bumped: Unit = null
	var fired: Array[Watch] = []
	var left := u.stat(&"movement") if compelled else u.move_left()
	var ln := line(u.cell, dest, u.luck, u)
	var from: Terrain = ground.call(u.cell)
	for c in ln:
		if not on_map(c) or left <= 0.0001:
			break
		bumped = enemy.call(c)
		if bumped:
			break
		var t: Terrain = ground.call(c)
		var cost := _cost(u, from, t)
		if cost > left + 0.0001:
			var unknown_bad := t.worth() < 0 and not read(u, c).known_bad()
			if Luck.settle(left / cost, u.luck, not unknown_bad, false) < 1:
				break
			cost = left  # squeezed in on what was left
		left -= cost
		costs.append(cost)
		path.append(c)
		from = t
		var w: Watch = null if expected else _watching(u, c)
		if w:
			fired.append(w)
			if w.skill.hostile:
				break  # ambushed
		if t.is_trap() and not blocked.call(c):
			break  # stepped on a trap
	while not path.is_empty() and blocked.call(path[-1]):  # units can be passed, not stood on
		path.pop_back()
		costs.pop_back()
	if expected:
		rng.state = state
	return {line = ln, path = path, costs = costs, bumped = bumped, fired = fired}


# Ran into an enemy: if the mover couldn't fully make it out, it loses two levels of concealment;
# a unit with a reaction passive (Opportunist) uses its first active on the mover.
func bump(u: Unit, e: Unit) -> void:
	if read(u, e).net < 0:
		e.exposed += 2
	if e.passives.any(func(s: Skill): return s.reaction) and not e.actives.is_empty():
		var s := e.actives[0]
		if s.hostile and in_reach(e, s, u):
			use(e, s, u)


# The first watch on `c` that fires on `u` (and uses up that tile). A watch whose caster can no
# longer reach the tile (it moved) lets the mover through.
func _watching(u: Unit, c: Vector2i) -> Watch:
	for w in watches:
		if c not in w.cells or w.caster == u or not w.caster.is_alive():
			continue
		if dist(w.caster.cell, c) > skill_range(w.caster, w.skill, u) + 0.0001:
			continue
		var r := read(w.caster, u)
		var fits: bool = w.any or (r.faction != null and (r.faction != w.caster.faction) == w.skill.hostile)
		if fits:
			w.cells.erase(c)
			return w
	return null


# A trap goes off: it loses two levels of concealment, and hits whoever stepped on it plus anyone
# in its blast. Units with Wary V (trap_power) make the traps they set off hit enemies harder.
func spring(c: Vector2i, by: Unit) -> void:
	var t := terrain(c)
	exposed[c] = exposed.get(c, 0) + 2
	sprung.emit(c, by)
	var raw := roll(t.dice)
	for v in units.values().filter(func(x): return x == by or dist(x.cell, c) <= t.blast + 0.0001):
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
	var n := ceili(dist(a, b) - 0.0001)
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
		if not u.acted and not u.asleep():
			Investigation.run(self, u)  # held still: looks around again
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
