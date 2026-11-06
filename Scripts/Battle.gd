class_name Battle
extends Node2D

signal phase_changed(was: Phase, now: Phase)
signal turn_changed(was: Faction, now: Faction)
signal initiative_rolled(rolls: Dictionary[Faction, Array])
signal traveled(u: Unit, from: Vector2i, path: Array[Vector2i])
signal used(caster: Unit, skill: Skill, at: Variant, dealt: int)  # at: the target Unit, or a cell
signal sprung(c: Vector2i, by: Unit)
signal attacked(caster: Unit, target: Unit, d20: int, total: int, defense: int)  # an attack roll (cast())
signal contested(caster: Unit, target: Unit, total: int, against: int)  # a contest in place of one (Drown): won when total >= against
signal investigated(by: Unit, of: Unit, skill: Skill, total: int, against: int, close: bool)  # investigate(): seen through when total >= against
signal stalled(u: Unit, rank: int)  # u stalls the fight: Ramut's Ire builds on it, to this rank (_check_stall())
signal struggled(u: Unit, by: Unit, total: int, against: int)  # u, held, tries to move away from by's grip (_break_free()): free when total > against
signal gripped(u: Unit, by: Unit, dealt: int)  # u, still held as its turn ends, takes by's grip (_grip())
signal inspected(by: Unit, at: Vector2i, total: int, against: int)  # inspect(): by grows suspicious of the tile when total >= against
signal prayed(u: Unit, god: StringName, rank: int)  # pray(): u prays to its god (Pray)
signal untangled(by: Unit, of: Unit, total: int, against: int)  # inspect(): by, under Haluca, sees of's tags straight when total >= against
signal refused(u: Unit, leader: Unit)  # a traitor in leader's party won't do as it's told, or acted on its own side's turn (_refuse())
signal doubted(by: Unit, of: Unit, total: int, against: int)  # doubt(): by grows suspicious of `of` when total >= against
signal evaluated(u: Unit, skill: Skill, d20: int, total: int)  # an ally's Self-evaluation saw a roll u made using skill (evaluators())
signal downed(u: Unit)  # u took mortal damage with a heart left: it gets up as the turn ends (_on_downed())
signal revived(u: Unit, summoned: Unit)  # u got up, a heart spent; summoned: what came with it (a Regeneration Probe), or null
signal dropped(u: Unit, item: Item)  # u fell, leaving an item (its loot)
signal pulsed(u: Unit, healed: Dictionary)  # a Regeneration Pulse: unit -> HP it got back
signal channeled(u: Unit, skill: Skill, at: Vector2i)  # u began channeling a skill on a tile (Metea)
signal exploded(u: Unit, skill: Skill, at: Vector2i, hit: Dictionary)  # a channeled skill struck: unit -> damage taken
signal shattered(u: Unit, at: Vector2i)  # u broke a starpane, bludgeoning it
signal sapped(u: Unit, drained: Dictionary)  # Starsap: unit -> Energy (or HP) u drained from it
signal reverted(was: Unit, now: Unit)  # a Starman fell back into a Starmote
signal reformed(was: Unit, now: Unit)  # a Starmote reformed into a Starman
signal burned(u: Unit, hp: int, why: String)  # u took fire from a flame, a burning slot or a burning item
signal perfect(u: Unit)  # 36 Strike hits in a row: u healed PERFECT_HEAL
signal chanted(u: Unit, rank: int)  # u waited its turn out and chanted (Chant)
signal leveled(caster: Unit, target: Unit, levels: int)  # Level Down took levels off target (0: none)

enum Phase { INITIATIVE, TURNS, OVER }

const PLAIN := preload("res://Terrain/grass.tres")  # tiles with no terrain set
const UNIT := preload("res://Scenes/unit.tscn")
const MEDIUM := 3  # size assumed for a target not yet chosen
const PASS_SHARE := 0.1  # of the size penalty for moving through a unit, taken off per point of dex mod
const PERFECT_HITS := 36  # Strike hits in a row (Strike!'s three) for a Perfect...
const PERFECT_HEAL := 300  # ...healing this much at once, true (_chain())
const PULSE_REACH := 3  # tiles a Regeneration Pulse reaches (_pulse())
const STAR_SLOW := 2.0  # Power back on the star lattice, x its usual resting rate: linked to a source with any Power in it...
const STAR_FAST := 5.0  # ...up to a full one (an empty source gives nothing)
const STAR_ENERGY := 0.3  # regular Energy gets this share of what the boost adds (+10 for Power: +3)
const STAR_CAPACITY := 20  # Power a starpower source holds full
const SICKNESS: Effect = preload("res://Effects/resurrection_sickness.tres")
const REFORMING: Effect = preload("res://Effects/reforming.tres")
const ASPHYXIA: Effect = preload("res://Effects/asphyxia.tres")

@export var spawns: Dictionary[Faction, Vector2i] = {}  # where a player's starter joins each side
@export var rewards: Array[Item] = []  # what the player's side gets for winning (the victory screen; Game.stash)

var player: Unit  # the starter made on the entry screen; null when there's none
var spoils: Array = []  # [item, the side of whoever dropped it], as units fall (_on_died())
var fallen: Array[Unit] = []  # down with a heart spent, getting up as the turn ends (_on_downed())
@export var companions: Array[Role] = []  # starters of these classes join the fight beside the player, as their own side, but the player's class's (the Astral Envoy)
@export var companion_side: Faction  # theirs: allied with the player's (Faction.sides_with_player)
@export var companion_cells: Array[Vector2i] = []  # where they stand, in order
@export var starpanes: Array[Vector2i] = []  # tiles the star lattice crosses: starpanes, joined side-on to their neighbours (the Astral Envoy)
@export var starpower: Dictionary[Vector2i, float] = {}  # starpower sources on the lattice -> how full each starts (0 to 1)
var panes: Dictionary[Vector2i, bool] = {}  # starpanes still whole: a bludgeoning skill used on one with no target breaks it (attempt())
var charge: Dictionary[Vector2i, int] = {}  # Power in each starpower source, up to STAR_CAPACITY (Starsap fills them)

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
		turns_begun += 1
		for u in members(v):
			u.refresh()
			if u.channel:
				u.channel.turns += 1
		for u in members(v):
			_look_harder(u)
			_starkind(u, false)
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
const IRE: Skill = preload("res://Skills/ramuts_ire.tres")

# Ramut's Ire waits out this many stalled turns in a row, times the units still standing on the smallest
# side (stealth missions, quieter battles: more; < 0: never; _check_stall()).
@export var ire_grace := 1.0
var stalled_turns: Dictionary[Faction, int] = {}  # each side's turns in a row ended with none of its units making out a foe
var hastened: Dictionary[Faction, int] = {}  # turns taken off each side's wait for the Ire (Pray, to Ramut)
var turns_begun := 0  # sides' turns started so far this battle: when an effect was put on (Unit.Applied.since)
var stalling: Array[Unit] = []  # units stalling the fight as the last turn ended: Ramut's Ire builds on them (_check_stall())
var snares: Dictionary[Vector2i, Snare] = {}  # traps units have laid (lay()), over the ground
var debris: Dictionary[Vector2i, Debris] = {}  # evidence hiding units leave behind (_scatter())
var flames: Dictionary[Vector2i, Flame] = {}  # tiles on fire (Flamewall)
var earthworks: Dictionary[Vector2i, Earthwork] = {}  # disturbed earth a side prayed up (Pray, to Vetruvis): its enemies wade through
@export var area_tags: Array[StringName] = []  # what the whole battlefield is (indoors, city, forest, desert...): debris where its tiles say nothing

# What a hiding unit leaves on the ground, by the tags of the tile (then the area): the first that
# matches. Tiles matching none get none.
const DEBRIS_KINDS := [
	[[&"stone", &"indoors", &"city"], "Rubble"],
	[[&"tree", &"outdoors"], "Leaves"],
	[[&"grass", &"shrubbery", &"forest"], "Disturbed foliage, twigs"],
	[[&"mud", &"snow", &"sand", &"mountains", &"desert", &"taiga"], "Depressions"],
]
const CLEAN_HIDE := 15  # a hiding roll this high or more is a good job: little debris, further off
const FAIR_HIDE := 10  # ...this high, a middling one; below it, a poor one
# By how well it hid (good, middling, poor): [fewest, most] debris left, and [nearest, furthest] tiles off.
const LITTER := [[[1, 2], [2, 4]], [[2, 3], [1, 3]], [[3, 4], [1, 2]]]
const EARTHWORK_COST := 1.5  # disturbed earth: what entering it costs its side's enemies, times the usual


# Evidence a unit left hiding: whoever can make out the tile sees it (but not who left it).
class Debris:
	var kind: String
	var by: Unit
	var faction: Faction
	var since: int
	var far := 4  # how far off it could have been left: past this + its hider's dex mod, the trail's gone cold

	func _init(k: String, u: Unit, t: int) -> void:
		kind = k
		by = u
		faction = u.faction
		since = t


# Disturbed earth (Pray, to Vetruvis): its side's enemies wade through it, for some of that side's turns.
class Earthwork:
	var faction: Faction
	var turns: int

	func _init(f: Faction, t: int) -> void:
		faction = f
		turns = t


# A tile on fire (Flamewall): whoever enters it, or ends its turn on it, takes 1d8 + its setter's wis
# mod in fire. Burns out after its setter's side's turns.
class Flame:
	var by: Unit
	var faction: Faction
	var turns: int
	var bonus: int

	func _init(u: Unit, t: int) -> void:
		by = u
		faction = u.faction
		turns = t
		bonus = u.mod(&"wisdom")


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
	var allied := false  # conceals only its side's units in it, and not the ground (Pray, to Luun)

	func _init(k: StringName, l: Dictionary[Vector2i, int], t: int, f: Faction, a := false) -> void:
		kind = k
		levels = l
		turns = t
		faction = f
		allied = a

@onready var map: TileMapLayer = $Map


func _ready() -> void:
	for c in starpanes:
		panes[c] = true
	for c in starpower:
		charge[c] = roundi(clampf(starpower[c], 0.0, 1.0) * STAR_CAPACITY)
	if Game.starter:
		player = starter(Game.starter)
		$Units.add_child(player, true)
		_join_companions(Game.starter.role)
		Game.starter = {}  # used up
	for u: Unit in $Units.get_children():
		if u.with_player and player:
			u.faction = player.faction
			u._show_faction()
		if not move(u, u.cell):
			push_error("%s has no free cell at %s" % [u.name, u.cell])
			u.free()
			continue
		u.died.connect(_on_died)
		u.downed.connect(_on_downed)
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


# The player's starter unit from the entry screen: {faction, role, name}, wearing what it had on
# (Game.outfit), with the hearts it's been given (Game.hearts).
func starter(s: Dictionary) -> Unit:
	var u := from_role(s.faction, s.role, s.name)
	for slot in Game.outfit:  # what it had on last battle
		u.set(slot, Game.outfit[slot])
	refill(u)
	u.hearts += Game.hearts
	assert(s.faction in spawns, "no spawn for %s" % s.faction.name)
	u.cell = spawns[s.faction]
	return u


# A level 1 unit of a class: its stats and reserves, on side f.
func from_role(f: Faction, role: Role, nick: String) -> Unit:
	var u: Unit = UNIT.instantiate()
	u.name = nick.validate_node_name()
	u.nick = nick
	u.faction = f
	u.role = role
	for k in role.stats:
		assert(k in Unit.CORE, "role stat %s isn't a unit stat" % k)
		u.set(k, role.stats[k])
	u.reserves.merge(role.reserves)
	return u


# The other starters join (companions): one of each class but the player's, in its starting items, on
# companion_side - allied with the player's side for this battle.
func _join_companions(mine: Role) -> void:
	if not companion_side or companions.is_empty():
		return
	if companion_side.sides_with_player:
		companion_side.allies.assign([player.faction])
	var i := 0
	for role in companions:
		if role == mine or i >= companion_cells.size():
			continue
		var u := from_role(companion_side, role, role.name)
		for slot in role.outfit():
			u.set(slot, role.outfit()[slot])
		u.cell = companion_cells[i]
		$Units.add_child(u, true)
		i += 1


# --- Initiative and tie-breaks

# Each living unit rolls a d20 and its faction sums them (+ Wary-style bonus); highest goes first.
func roll_initiative() -> Array[Faction]:
	rolls.clear()
	unit_rolls.clear()
	for u in units.values():
		if u.faction and u.is_alive():
			if u.faction not in rolls:
				rolls[u.faction] = []
			unit_rolls[u] = roundi(rng.randi_range(1, 20) * (1.0 + u.stat(&"opening_ap")))  # a Dagger's edge counts here too
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

# Uses an active skill on a target in reach, paying its AP and cost. Used on a foe, an attack
# (Skill.attacks()) rolls first: d20 + the caster's attack mod against the target's Defense for the
# skill's tags. A natural 20 always hits and doubles the damage; a miss does nothing but give the
# target away (it was aimed at). Damage comes from the skill's tier for the caster's rank - at least
# 1 before the target's mitigation - once per rank for multi-hit skills (Strike III). A dual skill
# (the starter spells) puts its effects only on allies, and deals its damage only to foes. Effects
# put on the side whose turn it is get a turn more, since this one isn't among those counted. Skills
# that are investigated (Hide) are, by the enemies that could see the target as it was used: the
# target rolls once, d20 + its mod in the skill's stat + rank - its dissonance, and its effects keep
# that roll for whoever investigates them. A roll an ally's Self-evaluation is in reach of is seen
# (evaluated). A foe a hostile skill hurts, while it's fooled by the caster, looks harder at it
# (doubt()). A skill with a save (Haluca) has the foe save in place of the attack roll: passing, it
# grows suspicious of the caster; failing a curse's (Brainfog), it loses slots of its skills for a
# while (Unit.disable_order()). An automatic skill (Sing) is used on the caster and lands on the nearest units in range
# (auto_targets()), paid once. A traitor told to turn a hostile skill on its real allies refuses, or
# with a positive cha mod misses on purpose - and either way its leader looks harder at it.
func cast(caster: Unit, skill: Skill, target: Unit, spreading := false) -> bool:
	if not _acting(caster) or skill not in caster.actives or skill.on_tile() or not target.is_alive():
		return false
	if (skill.on_self(caster) or (skill.auto and not spreading)) and target != caster:
		return false
	if skill.auto and not spreading:
		var to := auto_targets(caster, skill)
		if to.is_empty() or not caster.pay_for(skill):
			return false
		for t in to:
			cast(caster, skill, t, true)
		return true
	if posing(caster) and target.faction == caster.faction and target != caster and skill.hostile:
		if caster.mod(&"charisma") <= 0 or not in_reach(caster, skill, target):
			_refuse(caster)
			return false
		if not caster.pay_for(skill):
			return false
		attacked.emit(caster, target, 1, 1 + caster.attack_mod(skill), target.defense(skill.tags))  # a miss, on purpose
		used.emit(caster, skill, target, 0)
		doubt(caster.follows, caster, -1)  # a whiff: hardly suspicious
		return true
	var foe := not Faction.friends(target.faction, caster.faction)
	if foe and not skill.for_foes() and read(caster, target).attitude(caster) == &"ally":
		foe = false  # support for a foe it takes for an ally (a Friendly stance)
	var mends := not foe and skill.god_tag and caster.deity() == &"eros"  # Eros's Smite heals allies
	if not (skill.for_foes() if foe else (skill.for_allies() or mends)) or not in_reach(caster, skill, target):
		return false
	var spot: Variant = drag_spot(caster, skill, target) if foe and skill.drags_to else null
	if foe and skill.drags_to and spot == null:
		return false
	if skill.opening and caster.activity() != &"rest":
		return false  # only as its turn opens (Flamedance)
	if not spreading and not caster.pay_for(skill):
		return false
	var r := caster.rank(skill)
	if &"warlock" in skill.tags:
		caster.chant_up = false  # a primed Chant goes into this one
	_burn(caster, skill)
	var before := target.hp
	if skill.aura or skill.retrieves or skill.humbles or (skill.boost_pool and not foe) or not skill.elements.is_empty():
		if not skill.elements.is_empty():
			imbue(caster, skill, r)
		elif skill.aura:
			_aura(caster, skill, r)
		elif skill.retrieves:
			_retrieve(caster, skill, r)
		elif skill.humbles:
			_humble(caster, skill, target, r)
		else:
			target.ap.append(AP.new(maxf(caster.mod(skill.boost_mod, skill.tags) + r, 0.0), skill.boost_pool))
		used.emit(caster, skill, target, before - target.hp)
		return true
	if mends:
		_smite_heal(caster, skill, target, r)
		used.emit(caster, skill, target, before - target.hp)
		return true
	var crit := false
	var tags := hit_tags(caster, skill)
	var saved_against := 0  # a save it failed (Haluca): what seeing through its effects must beat
	if spot != null:
		var mine := rng.randi_range(1, 20) + caster.mod(skill.stat(), skill.tags) + caster.check_bonus(skill.stat(), &"offensive") - drag_penalty(skill, r, Command.tiles(target.cell, spot))
		var theirs := rng.randi_range(1, 20) + target.mod(skill.stat(), skill.tags) + target.check_bonus(skill.stat(), &"defensive")
		contested.emit(caster, target, mine, theirs)
		if mine < theirs:
			_expose(target)
			_expose(caster)
			used.emit(caster, skill, target, 0)
			return true
		drag(caster, target, spot, skill.drags_to)
	var fog: Array[Array] = target.disable_order().slice(0, caster.rounded(sqrt(r))) if foe and skill.disables else ([] as Array[Array])
	if foe and skill.save:
		var mine := rng.randi_range(1, 20) + caster.mod(skill.stat(), skill.tags) + r + caster.check_bonus(skill.stat(), &"offensive")
		var theirs: int = rng.randi_range(1, 20) + target.mod(skill.save) + target.check_bonus(skill.save, &"defensive") + fog.reduce(func(sum: int, g: Array): return sum + target.slot_weight(g), 0)
		contested.emit(caster, target, mine, theirs)
		if theirs > mine:  # the caster wins ties
			_expose(caster)
			if read(target, caster).located():
				suspect(target, caster)  # it felt something try
			used.emit(caster, skill, target, 0)
			return true
		saved_against = mine
	if foe and skill.levels_down:
		_level_down(caster, skill, target, r)
		used.emit(caster, skill, target, 0)
		return true
	if foe and skill.kills:
		_death(caster, skill, target, r)
		used.emit(caster, skill, target, before - target.hp)
		return true
	for g in fog:
		for s: Skill in g:
			target.disable(s, skill.lasts(r, caster) + (1 if target.faction == turn else 0), true)
	if foe and skill.chain:  # Strike: a hit at a time (_chain())
		_chain(caster, skill, target, r, tags)
		_expose(target)
		_expose(caster)
		if before > 0 and not target.is_alive():
			caster.gain(&"kill", 1)
		caster.heading = Vector2i.ZERO
		_tidy_debris()
		used.emit(caster, skill, target, before - target.hp)
		if target.hp < before and target.is_alive() and read(target, caster).deceived:
			doubt(target, caster)
		return true
	var overage := 0  # what a roll beat Defense by (Irradiate)
	if foe and skill.attacks():
		var d20 := rng.randi_range(1, 20)
		if skill.advantage:
			d20 = maxi(d20, rng.randi_range(1, 20))
		var total := d20 + caster.attack_mod(skill) + skill.roll_per_rank * r + caster.check_bonus(caster.wielded(skill.stat(), skill.tags), &"offensive")
		var defense := target.defense(tags)
		overage = maxi(total - defense, 0)
		crit = d20 == 20
		attacked.emit(caster, target, d20, total, defense)
		_evaluate(caster, skill, d20, total)
		if not crit and total < defense:
			_expose(target)
			used.emit(caster, skill, target, 0)
			return true
	var eyes := watchers(target) if skill.investigated else ([] as Array[Unit])
	var put: Array[Unit.Applied] = []
	if not (skill.dual and foe):
		for e in skill.effects + (skill.grants.effects if skill.grants else ([] as Array[Effect])):
			var n := e.turns if e.turns else skill.lasts(r, caster)
			var a := target.afflict(e, n + (1 if n and target.faction == turn else 0), r)
			a.total = n
			a.fades = skill.fades
			a.until_move = skill.until_move
			a.lasting = skill.grip != Vector2i.ZERO  # held until it breaks free
			a.skill = skill
			a.by = caster
			a.since = turns_begun
			a.roll = saved_against
			put.append(a)
	if skill.investigated:
		var d20 := rng.randi_range(1, 20)
		var guise := d20 + target.mod(skill.stat(), skill.tags) + r - target.dissonance_penalty()
		var seen := _evaluate(target, skill, d20, guise)
		for a in put:
			a.roll = guise
			a.evaluated = seen
		investigate(target, skill, eyes, guise)
		if skill.effects.any(func(e: Effect): return e.stat == "concealment"):
			_scatter(target, guise)
	if foe and skill.pull and (not skill.resisted or _lured(caster, skill, target)):
		pull(target, caster, skill.pull * r)
	if skill.prays:
		pray(caster, r, target)
	if skill.links:
		_link(caster, skill, r)
	if not foe and skill.heals():
		mend(target, skill.healing(caster) if skill.heal_mods or skill.heal_bonus else 0, skill.clears(r), skill.per_wound * r)
		target.regain(skill.restores * r)
	var t := skill.tier(r) if foe or not skill.dual else null
	if t:
		assert(t.stat == &"" or t.stat in Unit.CORE, "%s scales on unknown stat %s" % [skill.name, t.stat])
		var hits := r if skill.hits_per_rank else 1
		var gross := 0
		for i in hits:
			if not target.is_alive():
				break
			var bonus := caster.mod(caster.wielded(t.stat, skill.tags), skill.tags) + caster.weapon_bonus(t.stat) if t.stat else 0
			var power := maxi(roundi((t.power + roll(t.dice) + bonus) * (1.0 + caster.stat(&"damage", tags))), 1) * (2 if crit else 1)
			gross += power
			if &"energy" in tags:
				target.drain(power, tags, caster, skill.carry * (r - 1))
			elif t.direct:
				target.damage(power)
			else:
				target.hit(power, tags, caster)
		if foe and gross > 0 and next_to(caster.cell, target.cell):
			_refill(caster, target, gross)
		if foe and skill.god_tag and gross > 0:
			_smite(caster, target, r, gross)
		var glow := roundi(caster.stat(&"irradiate"))
		if foe and glow > 0 and &"light" in tags and overage > 0 and target.is_alive():  # Irradiate
			target.hit(mini(overage, glow + caster.mod(&"charisma")), [&"light"] as Array[StringName], caster)
	if foe and &"curse" in skill.tags and caster.stat(&"breathless") > 0.0 and target.is_alive() and (not put.is_empty() or target.hp < before):
		_choke(caster, target)
	if foe:
		_expose(target)
		_expose(caster)
		if before > 0 and not target.is_alive():
			caster.gain(&"kill", 1)  # Sweet Nothings
	caster.heading = Vector2i.ZERO
	_tidy_debris()
	used.emit(caster, skill, target, before - target.hp)
	if foe and skill.hostile and target.hp < before and target.is_alive() and read(target, caster).deceived:
		doubt(target, caster)
	return true


# The tags a skill's damage carries for its caster: its own, plus its weapon's blows (Skill.weapon_tag:
# Strike - blunt bare-handed) and its god's (Skill.god_tag: Smite - Eros's love, Urlo's energy).
static func hit_tags(caster: Unit, skill: Skill) -> Array[StringName]:
	var out: Array[StringName] = skill.tags.duplicate()
	if skill.weapon_tag:
		var blow: StringName = (caster.weapon.damage_tag if caster.weapon else &"blunt")
		if blow and blow not in out:
			out.append(blow)
	var god: StringName = Unit.GOD_TAGS.get(caster.deity(), &"")
	if skill.god_tag and god and god not in out:
		out.append(god)
	return out


# What each god adds to a Smite that hits (Skill.god_tag), at rank r, gross its damage before the
# target's mitigation:
# Luun: a target left at r x 5% of its max HP or less dies (an execute). Sol: it burns for 20% x r of
# the damage as pure fire as its side's turn ends. Urlo: r of its enchantments come off (disenchant()),
# and the caster's own items get those r didn't find (Unit.enchant()). Drael: r ranks of its buffs
# come off (dispel()). Vetruvis: earth damage radiates from it to everyone within r tiles but the
# caster, the damage / (tiles away + 1).
func _smite(caster: Unit, t: Unit, r: int, gross: int) -> void:
	match caster.deity():
		&"luun":
			if t.is_alive() and t.hp <= t.max_hp * 0.05 * r:
				t.slain_from = t.hp
				t.hp = 0
		&"sol":
			if t.is_alive():
				var burn := Effect.new()
				burn.stat = "bleed"
				burn.name = "Sunburn"
				burn.tags = [&"fire"]
				burn.amount = maxf(roundf(gross * 0.2 * r), 1.0)
				var a := t.afflict(burn, 1 + (1 if t.faction == turn else 0))
				a.by = caster
				a.since = turns_begun
		&"urlo":
			caster.enchant(r - disenchant(t, r))
		&"drael":
			dispel(t, r)
		&"vetruvis":
			for o: Unit in units.values():
				var d := Command.tiles(o.cell, t.cell)
				if o != caster and o != t and o.is_alive() and d <= r:
					o.hit(gross / (d + 1.0), [&"earth"] as Array[StringName], caster)


# Eros's Smite on an ally: it heals what it would have dealt; past full, it overheals at r x 20% of
# what's left over (Unit.over_max).
func _smite_heal(caster: Unit, skill: Skill, t: Unit, r: int) -> void:
	var tier := skill.tier(r)
	if not tier:
		return
	var n := tier.power + roll(Vector2i(tier.dice.x * (r if skill.dice_per_rank else 1), tier.dice.y)) + (caster.mod(tier.stat, skill.tags) if tier.stat else 0)
	var room := t.max_hp + t.over_max - t.hp
	var over := maxi(n - room, 0)
	var extra := roundi(over * 0.2 * r)
	t.over_max = maxi(t.hp + mini(n, room) + extra - t.max_hp, t.over_max)
	t.heal(mini(n, room) + extra)


# Takes up to n enchantments off t's items, weapon first, then armor and trinket: each becomes its plain
# self (Item.enchant 0). How many came off.
func disenchant(t: Unit, n: int) -> int:
	var done := 0
	for slot in [&"weapon", &"armor", &"trinket"]:
		var it: Item = t.get(slot)
		if done < n and it and it.enchant > 0:
			it = it.duplicate()
			it.enchant = 0
			t.set(slot, it)
			done += 1
	t.refit()
	return done


# Starblade: a melee hit gives its wielder back Power - (gross damage / the target's base stat total)
# x the weapon's refills x (1 + its enchantment) of its max, rounded by luck.
func _refill(u: Unit, t: Unit, gross: int) -> void:
	if u.weapon and u.weapon.refills > 0.0:
		var share := float(gross) / maxi(t.base_total(), 1) * u.weapon.refills * (1 + u.weapon.enchant)
		u.energy += Luck.settle(share * u.max_energy, u.luck, true)


# Whom an automatic skill (Sing) lands on: the nearest units in range the caster can place, allies
# and foes alike, no more than its rank.
func auto_targets(caster: Unit, skill: Skill) -> Array[Unit]:
	var out: Array[Unit] = []
	for o: Unit in units.values():
		if o != caster and o.is_alive() and read(caster, o).located() and in_reach(caster, skill, o):
			out.append(o)
	out.sort_custom(func(x: Unit, y: Unit): return Vector2(x.cell).distance_to(Vector2(caster.cell)) < Vector2(y.cell).distance_to(Vector2(caster.cell)))
	return out.slice(0, caster.rank(skill))


# A traitor in the party of a leader on another side (Unit.follows): it acts on that leader's turn
# too, on whatever AP its own turn left it, pretending (Command).
func posing(u: Unit) -> bool:
	return u.follows != null and u.follows.faction != u.faction


# A traitor won't do as it's told, or acted on its own side's turn when it should have rested: its
# leader looks harder at it, at advantage.
func _refuse(u: Unit) -> void:
	refused.emit(u, u.follows)
	doubt(u.follows, u, 1)


# Whether foe t walks toward caster's skill (Sing): only enraptured - convinced the caster is its ally,
# with no suspicion of it - taking it for support. A suspicious one won't, but the song works on its
# suspicion: d20 + the caster's mod in the skill's stat against d20 + its mod in the skill's
# `resisted` stat (the caster wins ties) takes a stack off. One that isn't convinced, with none to
# take, the song does nothing to (it may well walk up to hit the caster all the same).
func _lured(caster: Unit, skill: Skill, t: Unit) -> bool:
	if t.suspects(caster) == 0:
		return read(t, caster).attitude(t) == &"ally"
	var mine := rng.randi_range(1, 20) + caster.mod(skill.stat(), skill.tags) + caster.check_bonus(skill.stat(), &"offensive")
	var theirs := rng.randi_range(1, 20) + t.mod(skill.resisted) + t.check_bonus(skill.resisted, &"defensive")
	contested.emit(caster, t, mine, theirs)
	if mine >= theirs:
		suspect(t, caster, -1)
	return false


# o grows n stacks more suspicious of t, a unit or a tile (fewer, for a negative n; none left, it
# trusts it again).
func suspect(o: Unit, t: Variant, n := 1) -> void:
	var who: Unit = t if t is Unit else unit_at(t)  # suspicion of a tile works on whoever hides there
	var pleased := n > 0 and who != null and who.faction != o.faction and (o.stat(&"unmask_gain") > 0 or o.stat(&"uncover_gain") > 0)
	var was: Read = read(o, who) if pleased else null
	var hid := _hidden_from(o, who) if pleased else 0
	var k := o.suspects(t) + n
	if k > 0:
		o.suspicion[t] = k
	else:
		o.suspicion.erase(t)
	if pleased:
		_dialysis(o, who, was, hid)


# Analysis Dialysis: o satisfies its patron, Sweet Nothings back for it, unmasking an enemy t it took
# for friendly or neutral (unmask_gain), or taking levels of concealment off one hiding (uncover_gain
# a level). was: o's read of t before; hid: the levels t hid from o by.
func _dialysis(o: Unit, t: Unit, was: Read, hid: int) -> void:
	var now := read(o, t)
	if was.attitude(o) in [&"ally", &"ignore"] and now.attitude(o) not in [&"ally", &"ignore"] and now.faction != null:
		o.gain(&"patron", roundi(o.stat(&"unmask_gain")))
	var off := hid - _hidden_from(o, t)
	if off > 0:
		o.gain(&"patron", roundi(o.stat(&"uncover_gain")) * off)


# The concealment levels t hides from o by, before o's senses.
func _hidden_from(o: Unit, t: Unit) -> int:
	return Perception._levels(self, t.cell, t, true, o).values().reduce(func(sum, x): return sum + x, 0)


# o looks harder at t, which fools it: d20 + its wis mod (the better of two within wis mod - lie tiles,
# or with edge 1; the worse of two with edge -1) against t's own check, d20 + its cha mod + its lie -
# its dissonance penalty (a less believable lie, the more it lies). The lie is its persona to its
# allies, its trickery to its enemies. Meeting it, o grows a stack more suspicious of t.
func doubt(o: Unit, t: Unit, edge := 0) -> bool:
	var lie := roundi(t.stat(&"persona")) if o.faction == t.faction else roundi(Perception.trickery(t, Read.new(), null, self))
	var d20 := rng.randi_range(1, 20)
	var other := rng.randi_range(1, 20)
	if edge < 0:
		d20 = mini(d20, other)
	elif edge > 0 or Command.tiles(o.cell, t.cell) <= o.mod(&"wisdom") - lie:
		d20 = maxi(d20, other)
	var total := d20 + o.mod(&"wisdom")
	var against := rng.randi_range(1, 20) + t.mod(&"charisma") + lie - t.dissonance_penalty()
	if total >= against:
		suspect(o, t)
	doubted.emit(o, t, total, against)
	return total >= against


# As its side's turn starts, u looks harder (doubt()) at each enemy it can place that fools it: the
# enraptured come round on their own, given time. And it inspects the nearest suspicious thing it
# hasn't before (_first_look()).
func _look_harder(u: Unit) -> void:
	if u.asleep():
		return
	for t: Unit in units.values():
		if t.faction != u.faction and t.is_alive():
			var r := read(u, t)
			if r.deceived and r.located():
				doubt(u, t)
	_first_look(u)


# Tiles where o makes out something suspicious but not what: a hint (a vague shape, a vibe) of a
# hidden trap or a hidden unit there, or one it already suspects and still can't make out; or an ally
# whose tags it sees scrambled (Haluca). Nearest first.
func suspicious(o: Unit) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for c in map.get_used_cells():
		var r := read(o, c)
		if c != o.cell and (r.hint != "" or (o.suspects(c) > 0 and r.net < 0)):
			out.append(c)
	for t: Unit in units.values():
		if t != o and t.is_alive() and t.cell not in out:
			var r := read(o, t)
			if r.located() and (r.hint != "" or (o.suspects(t) + o.suspects(t.cell) > 0 and r.net < 0) or (t.faction == o.faction and o.scrambles(t))):
				out.append(t.cell)
	out.sort_custom(func(x: Vector2i, y: Vector2i): return Vector2(x).distance_to(Vector2(o.cell)) < Vector2(y).distance_to(Vector2(o.cell)))
	return out


# The first time o sees something suspicious, it inspects the nearest such thing it hasn't yet.
func _first_look(o: Unit) -> void:
	for c in suspicious(o):
		if c not in o.noticed:
			o.noticed[c] = true
			inspect(o, c)
			return


# As its side's turn ends, o looks around (asleep, it doesn't): the nearest suspicious things within its
# wis mod in tiles, one of them - more often than not. With wis mod 0 or less it looks only at what's
# beside it, once every (1 - wis mod) turns: at 0, every turn; at -1, every other. Each turn in a row
# it has rested widens its look by a tile, takes in one thing more and adds +1 to its checks, up to
# its wis. Moving last with Eyes Forward, it looks ahead instead (_look_ahead()).
func _watch(o: Unit) -> void:
	if _look_ahead(o):
		return
	var m := o.mod(&"wisdom")
	if m <= 0:
		o.unwatched += 1
		if o.unwatched < 1 - m:
			return
	o.unwatched = 0
	survey(o, o.cell, o.rested_turns)


# o inspects around `center` as if it had rested `rested` turns in a row (capped at its wis): the
# suspicious things within max(wis mod, 1) + rested tiles of it, nearest the centre first, 1 + rested
# of them, at +rested. Its turn's end (_watch()).
func survey(o: Unit, center: Vector2i, rested: int) -> int:
	var r := mini(rested, roundi(o.stat(&"wisdom")))
	var reach := maxi(o.mod(&"wisdom"), 1) + r
	var near := suspicious(o).filter(func(c: Vector2i): return Command.tiles(center, c) <= reach)
	near.sort_custom(func(x: Vector2i, y: Vector2i): return Command.tiles(center, x) < Command.tiles(center, y))
	var n := 0
	for c in near.slice(0, 1 + r):
		o.noticed[c] = true
		inspect(o, c, center, r)
		n += 1
	return n


# Observe: o searches every tile within max(wis mod, 1) + rank of `center`, as if it had rested rank
# turns (+rank, capped at its wis) - not just what looks suspicious: where to look is its to judge.
func observe(o: Unit, center: Vector2i, rank: int) -> int:
	var r := mini(rank, roundi(o.stat(&"wisdom")))
	var reach := maxi(o.mod(&"wisdom"), 1) + r
	return search(o, map.get_used_cells().filter(func(c: Vector2i): return Command.tiles(center, c) <= reach), center, r)


# An investigation skill's look (Observe, Eyes Forward): o inspects every one of `cells` but its own,
# at +bonus, from `center`. How many it grew suspicious of.
func search(o: Unit, cells: Array, center: Variant = null, bonus := 0) -> int:
	var found := 0
	for c: Vector2i in cells:
		if c != o.cell and inspect(o, c, center, bonus):
			o.noticed[c] = true
			found += 1
	return found


# Eyes Forward: a unit ending its turn on a move looks ahead the way it went - rank + wis mod tiles on,
# rank to either side - inspecting every tile there, in place of looking around. False if it didn't.
func _look_ahead(o: Unit) -> bool:
	var rank := roundi(o.stat(&"eyes_forward"))
	var way := o.heading
	o.heading = Vector2i.ZERO
	if rank <= 0 or way == Vector2i.ZERO:
		return false
	var dir := Vector2(way).normalized()
	var ahead := rank + o.mod(&"wisdom")
	var strip: Array[Vector2i] = []
	for c in map.get_used_cells():
		var rel := Vector2(c - o.cell)
		var along := rel.dot(dir)
		if along > 0.0 and along <= ahead + 0.5 and absf(rel.cross(dir)) <= rank + 0.5:
			strip.append(c)
	search(o, strip)
	return true


# What looking at c from a distance costs o's check: nothing beside it; further off, a point a tile
# from `center` (where it's looking from, or around: Observe), cut to tiles / (rank + 1) by Special
# Eyes.
func distance_penalty(o: Unit, center: Vector2i, c: Vector2i) -> int:
	if Command.tiles(o.cell, c) <= 1:
		return 0
	return Command.tiles(center, c) / (roundi(o.stat(&"keen_eyes")) + 1)


# o investigates a tile: d20 + its wis mod + bonus - the distance penalty, against d20 + the
# concealment there - a hidden enemy's, or a trap's it wasn't told of. Meeting it, it grows a stack
# more suspicious of the tile (of what hides there), and of the enemy hiding on it. With nothing
# hidden there, there's nothing to find: no roll. An ally there whose tags o sees scrambled (Haluca):
# the same check against the spell's roll sets them straight (untangled).
func inspect(o: Unit, c: Vector2i, center: Variant = null, bonus := 0) -> bool:
	var t := unit_at(c)
	var hiding := Perception.cover(self, t) if t and t.faction != o.faction else 0
	var snare: Snare = snares.get(c)
	var trap := terrain(c).concealment if hidden(c) and not (snare and o in snare.known) else 0
	var mixed := t != null and t.faction == o.faction and o.scrambles(t)
	if hiding <= 0 and trap <= 0 and not mixed:
		return false
	var total := rng.randi_range(1, 20) + o.mod(&"wisdom") + bonus - distance_penalty(o, center if center != null else o.cell, c)
	if mixed and hiding <= 0 and trap <= 0:
		var a := o.scrambled()
		if total >= a.roll:
			a.through.append(t)
		untangled.emit(o, t, total, a.roll)
		return total >= a.roll
	var against := rng.randi_range(1, 20) + maxi(hiding, trap)
	if total >= against:
		suspect(o, c)
		if hiding > 0:
			suspect(o, t)
	inspected.emit(o, c, total, against)
	return total >= against


# u prays to its god (Unit.deity(); Pray), at rank r, on `target` (Drael's alone isn't on itself).
# Ramut: its side waits r turns less for the Ire. Eros: up to r units within r tiles that can see u -
# the nearest first - lose a stack of suspicion of it (only those that see it: it's no help in
# hiding). Sol: darkness within r tiles is gone. Urlo: enchants r unenchanted items of its allies
# within r tiles (Unit.enchant()). Luun: the ground within r tiles under darkness for r turns that
# conceals only its side, a level. Drael: r ranks of debuffs off the target, highest rank first
# (cleanse()). Vetruvis: the ground within r tiles is disturbed earth its enemies wade through, for r
# turns.
func pray(u: Unit, r: int, target: Unit = null) -> void:
	match u.deity():
		&"ramut":
			hastened[u.faction] = hastened.get(u.faction, 0) + r
		&"eros":
			var near: Array[Unit] = []
			for o: Unit in units.values():
				if o != u and o.is_alive() and o.suspects(u) > 0 and Command.tiles(o.cell, u.cell) <= r and not o.asleep() and read(o, u).located():
					near.append(o)
			near.sort_custom(func(x: Unit, y: Unit): return Command.tiles(x.cell, u.cell) < Command.tiles(y.cell, u.cell))
			for o: Unit in near.slice(0, r):
				suspect(o, u, -1)
		&"sol":
			for z in zones.filter(func(x: Zone): return x.kind == &"dark"):
				for c in z.levels.keys():
					if Command.tiles(u.cell, c) <= r:
						z.levels.erase(c)
			zones.assign(zones.filter(func(x: Zone): return not x.levels.is_empty()))
		&"urlo":
			var left := r
			var near := members(u.faction).filter(func(o: Unit): return Command.tiles(o.cell, u.cell) <= r)
			near.sort_custom(func(x: Unit, y: Unit): return Command.tiles(x.cell, u.cell) < Command.tiles(y.cell, u.cell))
			for o: Unit in near:
				left -= o.enchant(left)
		&"luun":
			var levels: Dictionary[Vector2i, int] = {}
			for c in map.get_used_cells():
				if Command.tiles(u.cell, c) <= r:
					levels[c] = 1
			zones.append(Zone.new(&"dark", levels, r, u.faction, true))
		&"drael":
			cleanse(target if target else u, r)
		&"vetruvis":
			for c in map.get_used_cells():
				if Command.tiles(u.cell, c) <= r:
					earthworks[c] = Earthwork.new(u.faction, r)
	prayed.emit(u, u.deity(), r)


# Takes r ranks of debuffs (effects that hurt it) off t, the highest-ranked first: each loses ranks
# until it has none left, or r runs out. Ramut's Ire isn't Drael's to lift. How many ranks came off.
func cleanse(t: Unit, r: int) -> int:
	return _strip(t, r, -1)


# The same for buffs (effects that help it): Drael's Smite.
func dispel(t: Unit, r: int) -> int:
	return _strip(t, r, 1)


# Takes r ranks of t's effects that help it (way 1) or hurt it (-1), the highest-ranked first. An
# effect easy to remove (Effect.ease: Level Down 2, Level Up 4) loses that many ranks for each spent.
func _strip(t: Unit, r: int, way: int) -> int:
	var those := t.timed.keys().filter(func(e: Effect): return e.helps() == way and e.stat != "ire")
	those.sort_custom(func(x: Effect, y: Effect): return t.timed[x].rank > t.timed[y].rank)
	var left := r
	for e: Effect in those:
		if left <= 0:
			break
		var a: Unit.Applied = t.timed[e]
		var off := mini(left * e.ease, a.rank)
		a.rank -= off
		left -= ceili(off / float(e.ease))
		if a.rank <= 0:
			t.timed.erase(e)
	t._arrange()  # a level effect may have gone
	t.refit()  # or Asphyxia
	return r - left


# A unit hid (its roll: a skill's investigated roll), or moved while hidden (`along` its path): it
# leaves debris on tiles around it - around the path, one fewer - by their tags (debris_kind()). How
# much and how far off goes by how well it hid (LITTER): a good job (CLEAN_HIDE or more) leaves 1-2,
# 2-4 tiles off; a middling one (FAIR_HIDE) 2-3, 1-3 off; a poor one 3-4, within 2.
func _scatter(u: Unit, roll: int, along: Array[Vector2i] = []) -> void:
	var band: Array = LITTER[0 if roll >= CLEAN_HIDE else (1 if roll >= FAIR_HIDE else 2)]
	var n := rng.randi_range(band[0][0], band[0][1]) - (1 if not along.is_empty() else 0)
	var from: Array[Vector2i] = along.duplicate()
	if from.is_empty():
		from.append(u.cell)
	var spots: Array[Vector2i] = []
	for c in map.get_used_cells():
		var d := 99
		for p in from:
			d = mini(d, Command.tiles(p, c))
		if c != u.cell and c not in along and d >= band[1][0] and d <= band[1][1] and debris_kind(c) != "":
			spots.append(c)
	for i in mini(n, spots.size()):
		var k := rng.randi_range(i, spots.size() - 1)
		var c := spots[k]
		spots[k] = spots[i]
		spots[i] = c
		debris[c] = Debris.new(debris_kind(c), u, turns_begun)
		debris[c].far = band[1][1]


# What u's hiding is worth, for the debris moving leaves: the roll its concealment was put on with
# (Hide's), else a fresh d20 + its dex mod.
func _hide_roll(u: Unit) -> int:
	var best := 0
	for e in u.timed:
		if e.stat == "concealment":
			best = maxi(best, u.timed[e].roll)
	return best if best > 0 else rng.randi_range(1, 20) + u.mod(&"dexterity")


# Debris goes once its hider is revealed (no concealment left, or fallen), or has gone further from
# it than it could have been left (Debris.far) + the hider's dex mod: the trail's cold.
func _tidy_debris() -> void:
	for c in debris.keys():
		var d: Debris = debris[c]
		if not is_instance_valid(d.by) or not d.by.is_alive() or Perception.cover(self, d.by) <= 0 \
				or Command.tiles(d.by.cell, c) > d.far + d.by.mod(&"dexterity"):
			debris.erase(c)


# A tag that only says what the ground is made of, for debris (DEBRIS_KINDS).
static func material(tag: StringName) -> bool:
	return DEBRIS_KINDS.any(func(k: Array): return tag in k[0])


# The debris a hiding unit leaves on c: by the tile's tags, then the area's (DEBRIS_KINDS); "" for none.
func debris_kind(c: Vector2i) -> String:
	for tags in [terrain(c).tags, area_tags]:
		for k in DEBRIS_KINDS:
			if k[0].any(func(t: StringName): return t in tags):
				return k[1]
	return ""


# Debris o can make out (it reads the ground there) that its own side didn't leave: clues to where
# enemies hide.
func evidence(o: Unit) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for c in debris:
		if debris[c].faction != o.faction and read(o, c).net >= 0:
			out.append(c)
	return out


# Its enemies that can see u: awake foes that make it out in plain sight (net -1 or better, seen).
func watchers(u: Unit) -> Array[Unit]:
	var out: Array[Unit] = []
	for o: Unit in units.values():
		if not Faction.friends(o.faction, u.faction) and o.is_alive() and not o.asleep():
			var r := read(o, u)
			if r.net >= -1 and r.seen:
				out.append(o)
	return out


# Each of `eyes` looks into what skill just did to u (Hide, Clever Disguise): d20 + its wis mod -
# the better of two d20s within (wis mod - rank) tiles of u - against the roll u made using it.
# Meeting it, it sees through the skill's effects on u for as long as they last.
func investigate(u: Unit, skill: Skill, eyes: Array[Unit], against: int) -> void:
	var r := u.rank(skill)
	for o in eyes:
		var close := Command.tiles(o.cell, u.cell) <= o.mod(&"wisdom") - r
		var d20 := rng.randi_range(1, 20)
		if close:
			d20 = maxi(d20, rng.randi_range(1, 20))
		var total := d20 + o.mod(&"wisdom")
		if total >= against:
			for e in skill.effects:
				if e in u.timed:
					u.timed[e].known_to.append(o)
		investigated.emit(o, u, skill, total, against, close)


# u's awake allies, itself among them, whose Self-evaluation reaches it: they see the rolls it makes.
func evaluators(u: Unit) -> Array[Unit]:
	var out: Array[Unit] = []
	for o: Unit in units.values():
		if o.faction == u.faction and o.is_alive() and not o.asleep() and o.evaluates() > 0 and Command.tiles(o.cell, u.cell) <= o.evaluates():
			out.append(o)
	return out


# A roll u just made using skill (d20, and its total), seen if one of its evaluators() is in reach.
func _evaluate(u: Unit, skill: Skill, d20: int, total: int) -> bool:
	if evaluators(u).is_empty():
		return false
	evaluated.emit(u, skill, d20, total)
	return true


# The chance (0-1) an attack with s by u hits t: the d20 rolls that reach t's Defense, a natural
# 20 always among them.
static func hit_chance(u: Unit, s: Skill, t: Unit) -> float:
	if not s.attacks():
		return 1.0
	var p := clampi(21 - (t.defense(s.tags) - u.attack_mod(s) - s.roll_per_rank * u.rank(s) - u.check_bonus(u.wielded(s.stat(), s.tags), &"offensive")), 1, 20) / 20.0
	return 1.0 - (1.0 - p) * (1.0 - p) if s.advantage else p


# A hostile skill aimed at a tile rather than at a unit the caster can make out (the player's
# Ctrl-click): whoever is there takes it as an ordinary cast. If it doesn't land - nobody there, or
# not quite in reach of what is - it's spent on thin air, as long as the tile itself was in reach
# of a Medium target. Returns &"hit", &"miss", or &"" when it couldn't be tried at all.
func attempt(caster: Unit, skill: Skill, c: Vector2i) -> StringName:
	if not _acting(caster) or skill not in caster.actives or not skill.for_foes() or skill.zone != &"" or not on_map(c):
		return &""
	var t := unit_at(c)
	if t and t != caster and cast(caster, skill, t):
		return &"hit"
	if Vector2(caster.cell).distance_to(Vector2(c)) > skill_range(caster, skill) + 0.0001 or not caster.pay_for(skill):
		return &""
	used.emit(caster, skill, c, 0)
	if not t and c in panes and &"blunt" in hit_tags(caster, skill):
		panes.erase(c)
		shattered.emit(caster, c)
		return &"shattered"
	return &"miss"


# Hitting a unit, or attacking, gives away where it is: a hidden one loses a level of concealment
# until its side's next turn starts.
func _expose(u: Unit) -> void:
	if Perception.cover(self, u) > 0:
		u.exposed += 1


# Skills cast on a cell, within area_reach(): area skills (Darkstone) lay their zone kind of
# concealment on the tiles around it (see zone_levels()); trap skills (Snare) lay a trap there (lay());
# channeled skills (Metea) begin channeling there, and once begun strike where they can (_detonate()).
func cast_at(caster: Unit, skill: Skill, c: Vector2i) -> bool:
	if not _acting(caster) or skill not in caster.actives or not skill.on_tile() or not on_map(c):
		return false
	if skill.channel and caster.channel and caster.channel.skill == skill:
		return _detonate(caster, skill, c)
	if Vector2(caster.cell).distance_to(Vector2(c)) > area_reach(caster, skill) + 0.0001:
		return false
	if skill.lays and (unit_at(c) or terrain(c).is_trap()):
		return false
	if not caster.pay_for(skill):
		return false
	_burn(caster, skill)
	if skill.flamewall:
		_flamewall(caster, skill, c)
	elif skill.cone > 0.0:
		_solar(caster, skill, c)
	elif skill.channel:
		caster.channel = Unit.Channel.new(skill, c)
		channeled.emit(caster, skill, c)
	elif skill.observes:
		observe(caster, c, caster.rank(skill))
	elif skill.lays:
		lay(caster, skill, c)
	else:
		zones.append(Zone.new(skill.zone, zone_levels(caster.rank(skill), c), skill.turns, caster.faction))
	caster.heading = Vector2i.ZERO
	used.emit(caster, skill, c, 0)
	return true


# A trap skill's trap, laid into the ground at c: the skill's `lays` with its concealment and dice
# multiplier times the setter's rank, plus the setter's mod in its bonus stat; its wounds (Snare:
# Bleeding) last rank + that mod turns, at least 1. The setter knows it;
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
	t.level = r
	t.wounds = plan.wounds
	t.wound_turns = maxi(r + (u.mod(plan.bonus_stat, skill.tags) if plan.bonus_stat else 0), 1)
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


# A channeled skill (Metea) strikes, for its smaller strike AP and cost: an explosion on c, which must be
# within (its side's turns since the channel began) tiles of where it was cast - only that tile, the turn
# it's cast - hitting every unit within rank tiles of it but the caster. The channel ends.
func _detonate(caster: Unit, skill: Skill, c: Vector2i) -> bool:
	var ch := caster.channel
	if Command.tiles(ch.at, c) > ch.turns or not caster.pay_strike(skill):
		return false
	caster.channel = null
	var r := caster.rank(skill)
	var t := skill.tier(r)
	var hit := {}
	for o: Unit in units.values():
		if o == caster or not o.is_alive() or Vector2(o.cell).distance_to(Vector2(c)) > skill.blast * r + 0.0001:
			continue
		var power := maxi(t.power + roll(t.dice) * (r if skill.dice_per_rank else 1) + (caster.mod(t.stat, skill.tags) if t.stat else 0), 1) if t else 0
		var was := o.hp
		o.hit(power * (1.0 + caster.stat(&"damage", skill.tags)), skill.tags, caster)
		hit[o] = was - o.hp
		_expose(o)
		if was > 0 and not o.is_alive() and o.faction != caster.faction:
			caster.gain(&"kill", 1)
	_expose(caster)
	used.emit(caster, skill, c, hit.values().reduce(func(sum, x): return sum + x, 0))
	exploded.emit(caster, skill, c, hit)
	return true


# Where a channeled skill can strike now: tiles within (turns since it began) of where it was cast.
func strike_tiles(u: Unit) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	if u.channel:
		for c in map.get_used_cells():
			if Command.tiles(u.channel.at, c) <= u.channel.turns:
				out.append(c)
	return out


# --- Items in battle

# Whether u's items can change now: on its side's turn, or once the battle is over.
func outfitting(u: Unit) -> bool:
	return phase == Phase.OVER or _acting(u)


# AP an item takes u to put on or use now (Item.ap_cost(): trinkets 1, weapons 2, armor 10 - dex mod):
# none once the battle's over.
func item_ap(it: Item, u: Unit = null) -> float:
	return it.ap_cost(u) if it and phase == Phase.TURNS else 0.0


# AP putting it on takes u now (taking things off is free).
func equip_ap(u: Unit, it: Item) -> float:
	return item_ap(it, u)


# Puts it on u, paying equip_ap() from its general AP. False (nothing changes) if it can't.
func equip(u: Unit, it: Item) -> bool:
	if not outfitting(u) or not u.can_wear(it) or u.ap_for(&"equip") < equip_ap(u, it) - 0.0001:
		return false
	u.pay(equip_ap(u, it), &"equip")
	u.equip(it)
	return true


# Takes what's in u's slot off, free. What came off, or null if it couldn't.
func unequip(u: Unit, slot: String) -> Item:
	var it: Item = u.get(slot)
	if not it or not outfitting(u):
		return null
	return u.unequip(slot)


# Uses an item, paying its AP: a consumable from the stash, used up (a Heart: an extra life for good),
# or the one in u's trinket slot that restores something (a potion: Item.restores; restore()), which
# empties it until the battle ends (Item.empty; refill()). False if it can't.
func use_item(u: Unit, it: Item) -> bool:
	if it == null or not outfitting(u) or not (it.slot == "consumable" or (it == u.trinket and it.restores and not it.empty)):
		return false
	if not u.pay(item_ap(it, u), &"equip"):
		return false
	u.hearts += it.hearts if it.slot == "consumable" else 0
	if it.restores:
		restore(u, it)
	if it == u.trinket:
		u.trinket = it.emptied()
	return true


# Emptied trinkets (potions) fill up again: as each battle ends, for everyone (and a starter's, as it's
# put on: starter()).
static func refill(u: Unit) -> void:
	if u.trinket and u.trinket.empty:
		u.trinket = u.trinket.filled()


# A potion's restoring: (its share x rank) of the max of what it restores, rounded by luck, + the
# user's mod in restore_mod + restore_flat (Health Potion: 15% of max HP + con mod; Sweet Something:
# 1 Sweet Nothing). What it gave back.
func restore(u: Unit, it: Item) -> int:
	var r: Reserve = it.reserve if it.restores == &"reserve" else null
	var most: int = u.max_hp if it.restores == &"hp" else (u.max_energy if it.restores == &"energy" else u.pools().get(r, 0))
	var n := maxi(u.rounded(most * it.restore_share * it.rank) + (u.mod(it.restore_mod) if it.restore_mod else 0) + it.restore_flat, 0)
	match it.restores:
		&"hp":
			var was := u.hp
			u.heal(n)
			return u.hp - was
		&"energy":
			var was := u.energy
			u.energy = mini(u.energy + n, u.max_energy)
			return u.energy - was
	if r:
		var was := u.store(r)
		u.set_store(r, was + n)
		return u.store(r) - was
	return 0


# What side f takes home from the battle: the items units of other sides dropped, and the scenario's
# rewards if it won.
func winnings(f: Faction) -> Array[Item]:
	var out: Array[Item] = []
	for pair in spoils:
		if pair[1] != f:
			out.append(pair[0])
	if won(f):
		out.append_array(rewards)
	return out


# How far from the caster an area skill can be centred: radius + radius_per_rank x rank.
func area_reach(caster: Unit, skill: Skill) -> float:
	return skill.span(caster)


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


# What o makes out of a unit or a tile. Linked by Coordinate, it makes out as much as the best of the
# others in its link do, up to the link's rank in levels better than it would alone (linked()).
func _linked_read(o: Unit, target: Variant) -> Read:
	var r := _read(o, target)
	var link := o.linked()
	if link == null or (target is Unit and target == o):
		return r
	var best := r.net
	for p in linked(o):
		if not (target is Unit and p == target):
			best = maxi(best, _read(p, target).net)
	var lift := mini(best - r.net, link.rank)
	return r if lift <= 0 else _read(o, target, lift)


# What o makes out, with what its synergized partners make out filling the gaps: the clearest of them.
func read(o: Unit, target: Variant) -> Read:
	var r := _linked_read(o, target)
	if target is Unit and target == o:
		return r
	for p in synergized(o):
		if not (target is Unit and p == target):
			var pr := _linked_read(p, target)
			if clearer(pr, r):
				r = pr
	return r


func _read(o: Unit, target: Variant, extra := 0.0) -> Read:
	return Perception.unit(self, o, target, extra) if target is Unit else Perception.tile(self, o, target, extra)


# The others o shares what it makes out with: those Coordinate linked along with it (the same caster's
# link, still on them), alive.
func linked(o: Unit) -> Array[Unit]:
	var out: Array[Unit] = []
	var link := o.linked()
	if link == null:
		return out
	for p: Unit in units.values():
		if p != o and p.is_alive() and p.linked() and p.linked().by == link.by:
			out.append(p)
	return out


# Coordinate: caster links up with its teammates within its cha mod in tiles (at least 1) and its
# leader, wherever it is, putting the skill's effects on each of them as on itself: they pool what they
# make out (read()).
func _link(caster: Unit, skill: Skill, r: int) -> void:
	var near := maxi(caster.mod(&"charisma"), 1)
	for o: Unit in units.values():
		if o == caster or not o.is_alive() or not teammates(caster, o):
			continue
		if Command.tiles(o.cell, caster.cell) <= near or o == caster.follows:
			for e in skill.effects:
				var n := skill.lasts(r, caster)
				var a := o.afflict(e, n + (1 if o.faction == turn else 0), r)
				a.skill = skill
				a.by = caster
				a.since = turns_begun


# Each takes the other for a teammate (Command: only teammates give each other orders or share a
# party). A persona's stance can put it on the wrong team in an ally's eyes (Read.attitude()); not
# making out its side at all, they still trust it.
func teammates(a: Unit, c: Unit) -> bool:
	return a == c or (_trusts(a, c) and _trusts(c, a))


func _trusts(o: Unit, t: Unit) -> bool:
	if o.stance == "Traitor" and o.faction != t.faction:
		return true  # it pretends to
	var r := read(o, t)
	return r.faction == null or r.attitude(o) == &"ally"


# Dice as Vector2i(count, sides): Vector2i(1, 6) is d6.
func roll(dice: Vector2i) -> int:
	var sum := 0
	for i in dice.x:
		sum += rng.randi_range(1, dice.y)
	return sum


# Skill range (Skill.span(): the starter spells' grows with int mod) + the caster's reach (its reach
# stat, +0.05 per size point) + 0.02 per size point of the target (bigger targets are easier to
# reach). No target: a Medium one.
func skill_range(caster: Unit, skill: Skill, target: Unit = null) -> float:
	var size: float = target.stat(&"size") if target else float(MEDIUM)
	return skill.span(caster) + caster.stat(&"reach") + 0.05 * caster.stat(&"size") + 0.02 * size


# Circle geometry. A near miss (within Luck.MARGIN) is rounding: in only if the caster is luckier.
func in_reach(caster: Unit, skill: Skill, target: Unit) -> bool:
	var over := Vector2(caster.cell).distance_to(Vector2(target.cell)) - skill_range(caster, skill, target)
	if over <= 0.0001:
		return true
	return over < Luck.MARGIN and caster.luck - target.luck > 0


# --- Movement

# Walks the straight line toward `dest` (see walk()), paying movement and the same AP per step.
# A trap it stops on springs. Ground a unit standing still passes by (Meander: Unit.passes_by())
# does nothing to it. Held, it must break free first (_break_free()). Returns the tiles passed.
func travel(u: Unit, dest: Vector2i) -> Array[Vector2i]:
	var passed: Array[Vector2i] = []
	if not _acting(u) or dest == u.cell:
		return passed
	if held_by(u) and not _break_free(u):
		return passed
	var w := walk(u, dest)
	passed = w.path
	if not passed.is_empty():
		var from := u.cell
		var touched := range(passed.size()).filter(func(i: int): return not u.passes_by(terrain(passed[i]), i + 1))
		u.walked(passed.size(), w.costs.reduce(func(sum, x): return sum + x, 0.0))
		move(u, passed[-1])
		for i in touched:  # stepping in happens on the unit's own turn, which isn't one of those counted
			for e in terrain(passed[i]).afflicts:
				u.afflict(e, (e.turns if e.turns else terrain(passed[i]).turns) + 1)
		u.heading = Vector2i(signi(passed[-1].x - from.x), signi(passed[-1].y - from.y))
		for c in passed:  # trodden into the ground
			debris.erase(c)
		for c in passed:  # walking into fire
			if c in flames and u.is_alive():
				_flame(u, flames[c], "walks into fire")
		if Perception.cover(self, u) > 0:
			_scatter(u, _hide_roll(u), passed)
		_tidy_debris()
		traveled.emit(u, from, passed)
		if terrain(u.cell).is_trap() and passed.size() - 1 in touched:
			spring(u.cell, u)
		if u.is_alive():
			_first_look(u)
	return passed


# The grip holding u (a grapple: Drown's effects), or null.
func held_by(u: Unit) -> Unit.Applied:
	for e in u.timed:
		var a := u.timed[e]
		if a.lasting and a.skill and a.skill.grip != Vector2i.ZERO:
			return a
	return null


# What trying to break free costs u in movement: 1 + its holder's mod in the grip's stat tiles (at
# least 1); 0 when nothing holds it.
func escape_cost(u: Unit) -> float:
	var a := held_by(u)
	if a == null:
		return 0.0
	return float(maxi(1 + a.by.mod(a.skill.stat(), a.skill.tags), 1)) if a.by else 1.0


# Held, u tries to move away from its holder: it spends escape_cost() movement, then d20 + its mod in
# the grip's stat against its holder's (the holder keeps it on a tie). Won, the grip's gone and it
# walks on with what movement it has left. A holder that's fallen, or isn't beside it, has let go.
func _break_free(u: Unit) -> bool:
	var a := held_by(u)
	var by := a.by
	var s := a.skill
	if not by or not by.is_alive() or not next_to(by.cell, u.cell):
		_let_go(u, s)
		return true
	var cost := escape_cost(u)
	if u.move_left() < cost - 0.0001:
		return false
	u.walked(0, cost)
	var theirs := rng.randi_range(1, 20) + u.mod(s.stat(), s.tags) + u.check_bonus(s.stat(), &"defensive")
	var mine := rng.randi_range(1, 20) + by.mod(s.stat(), s.tags) + by.check_bonus(s.stat(), &"offensive")
	struggled.emit(u, by, theirs, mine)
	if theirs > mine:
		_let_go(u, s)
		return true
	return false


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
	var left := u.move_left() - escape_cost(u)
	if held_by(u) and not expected:
		left = 0.0  # held: travel() breaks it free first
	var ln := line(u.cell, dest, u.luck, u)
	var from: Terrain = ground.call(u.cell)
	for c in ln:
		if not on_map(c) or left <= 0.0001:
			break
		var t: Terrain = ground.call(c)
		var cost := _cost(u, from, t) * wading(u, c)
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
		if t.is_trap() and not blocked.call(c) and not u.passes_by(t, path.size()):
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
# plus anyone in its blast, putting its wounds on them at its level (Snare: Bleeding). Units with Wary
# V (trap_power) make the traps they set off hit their enemies harder.
func spring(c: Vector2i, by: Unit) -> void:
	var t := terrain(c)
	if t.reveals:
		revealed[c] = true
	sprung.emit(c, by)
	var raw := roll(t.dice) * t.times + t.bonus
	for v in units.values().filter(func(x): return x == by or Vector2(x.cell).distance_to(Vector2(c)) <= t.blast + 0.0001):
		var boost := 1.0 + (by.stat(&"trap_power") if v.faction != by.faction else 0.0)
		v.hit(raw * boost, t.damage_tags)
		for e in t.wounds:  # + 1 on its own turn, which doesn't count
			var a: Unit.Applied = v.afflict(e, t.wound_turns + (1 if v.faction == turn else 0), t.level)
			a.by = snares[c].by if c in snares else null
			a.since = turns_begun


# Movement to step from one tile onto the next: leaving costs `from`'s exit, entering costs `to`'s
# enter, plus the unit's move_cost effects for that ground (u may be null: terrain only), times
# wading().
func step(u: Unit, from: Vector2i, to: Vector2i) -> float:
	return _cost(u, terrain(from), terrain(to)) * wading(u, to)


# Disturbed earth (Pray, to Vetruvis) costs its side's enemies EARTHWORK_COST times as much to enter,
# on top of whatever the ground and their effects already make it cost.
func wading(u: Unit, c: Vector2i) -> float:
	return EARTHWORK_COST if u and c in earthworks and earthworks[c].faction != u.faction else 1.0


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

# As a unit's side starts its turn: Resurrection Sickness takes 10% of its max HP (none if it's at full
# HP: it's cured), regen heals that fraction of its max HP (clearing wounds up to the
# rank of the strongest regen on it), then poison takes that fraction (each rounded by its luck).
func _mend(u: Unit) -> void:
	_pulse(u)
	for it in u.items():
		if it.heat and u.is_alive():  # Ignauldron
			burned.emit(u, u.hit(it.heat * it.rank, [&"fire"] as Array[StringName]), it.name)
		if it.burning and u.is_alive():
			var n := u.hit(maxi(u.rounded(0.1 * it.rank * u.max_hp), 1), [&"fire"] as Array[StringName])
			burned.emit(u, n, it.name)
	if SICKNESS in u.timed:  # gone if it starts the turn whole; else it takes its toll, never the last HP
		if u.hp >= u.max_hp:
			u.timed.erase(SICKNESS)
		else:
			u.hp = maxi(u.hp - maxi(roundi(SICKNESS.amount * u.max_hp), 1), 1)
	var regen := u.stat(&"regen")
	if regen > 0.0:
		var power := 0
		for pair in u._effects():
			if pair[0].stat == "regen":
				power = maxi(power, pair[1])
		mend(u, Luck.settle(regen * u.max_hp, u.luck, true), power)
	var poison := u.stat(&"poison")
	if poison > 0.0 and u.is_alive():
		u.damage(Luck.settle(poison * u.max_hp, u.luck, false))


# As its side's turn ends, each bleed on u takes its dice + the mod of whoever put it on (at least 1) -
# but not the turn it was put on.
func _bleed(u: Unit) -> void:
	for e in u.timed.keys():
		if e.stat == "bleed" and u.is_alive() and u.timed[e].since != turns_begun:
			var by := u.timed[e].by
			var n := roll(e.dice) + (by.mod(e.dice_mod) if by and e.dice_mod else 0) if e.dice != Vector2i.ZERO else roundi(e.amount)
			u.damage(maxi(n, 1))


# Regeneration Pulse, as u's side starts its turn: once every (its side's lives left, at least 1) of
# them - more often as its lives run out - it heals each ally within PULSE_REACH tiles, itself too,
# (1d4 + 5% of their max HP) x its pulse.
func _pulse(u: Unit) -> void:
	var k := roundi(u.stat(&"pulse"))
	if k <= 0:
		return
	u.pulse_wait += 1
	if u.pulse_wait < maxi(lives_left(u.faction), 1):
		return
	u.pulse_wait = 0
	var healed := {}
	for o in members(u.faction):
		if Command.tiles(o.cell, u.cell) <= PULSE_REACH:
			var was := o.hp
			o.heal(k * (roll(Vector2i(1, 4)) + Luck.settle(0.05 * o.max_hp, o.luck, true)))
			healed[o] = o.hp - was
	pulsed.emit(u, healed)


# A side's lives: the hearts of its units still on the field (fallen ones too), and how many are left.
func lives(f: Faction) -> int:
	var n := 0
	for u: Unit in units.values():
		if u.faction == f:
			n += u.lives()
	return n


func lives_left(f: Faction) -> int:
	var n := 0
	for u: Unit in units.values():
		if u.faction == f:
			n += u.lives_left()
	return n


# u took mortal damage with a heart left: it lies where it fell, holding its tile, beyond harm - no
# effects, nothing it was channeling - until the turn ends (end_turn()).
func _on_downed(u: Unit) -> void:
	u.timed.clear()
	u.disabled.clear()
	u.channel = null
	if u not in fallen:
		fallen.append(u)
	downed.emit(u)


# The fallen get up at full HP as the turn ends, each bringing what it summons (a Regeneration Probe)
# onto the nearest free tile. One getting up on its Red Spinel Ring (its last life) gets up at the ring's
# share of its max HP instead, with Resurrection Sickness.
func _revive() -> void:
	for u in fallen.duplicate():
		fallen.erase(u)
		if not is_instance_valid(u):
			continue
		u.reviving = false
		u.refit()  # what was on it (Asphyxia) went as it fell
		var ring: Item = u.trinket if u.ring_lives() > 0 and u.hearts_used > u.lives() - u.ring_lives() else null
		if ring:  # a Red Spinel Ring, spent last: rank x 10% of max HP, more than full past rank 10, and sick for rank turns
			var n := maxi(roundi(u.max_hp * ring.revives * ring.rank), 1)
			u.over_max = maxi(n - u.max_hp, 0)
			u.hp = n
			u.afflict(SICKNESS, ring.rank + (1 if u.faction == turn else 0), ring.rank)
		else:
			u.hp = u.max_hp
		var came: Unit = summon(u.summons, u.faction, u.cell) if u.summons else null
		revived.emit(u, came)


# Brings a unit of `scene` onto side f, on the free tile nearest c. Null if there's no room.
func summon(scene: PackedScene, f: Faction, c: Vector2i) -> Unit:
	var spot: Variant = free_near(c)
	if spot == null:
		return null
	var u: Unit = scene.instantiate()
	u.faction = f
	$Units.add_child(u, true)
	move(u, spot)
	u.died.connect(_on_died)
	u.downed.connect(_on_downed)
	if f == turn:
		u.refresh()
	return u


# The free tile on the map nearest c (c itself if it's free), or null.
func free_near(c: Vector2i) -> Variant:
	var best: Variant = null
	for x in map.get_used_cells():
		if not unit_at(x) and (best == null or Vector2(x).distance_to(Vector2(c)) < Vector2(best).distance_to(Vector2(c))):
			best = x
	return best


# The turn passes. Units that rested get energy back (Unit.recover()), and every unit awake looks
# around (_watch()); a traitor in another side's party that didn't rest gives
# itself away (_refuse()); held ones take their holder's grip (_grip()), and wounds bleed (_bleed());
# Ramut's Ire looks for a stall (_check_stall()); ground puts its turn-end
# effects on whoever is on it (Magic Stew); a sleeper with an ally beside it wakes up; then timed
# effects count down and zones wear off, and the fallen get back up (_revive()).
func end_turn() -> void:
	if phase != Phase.TURNS:
		return
	var side := members(turn)
	for u in side:
		var rested := u.activity() == &"rest"
		if rested:
			_chant(u)
			var vow := u.devotion()
			if vow and vow.satisfied_by == &"rest_whole" and u.hp >= u.max_hp:
				u.gain(&"patron", 1)  # Hogel: resting whole
		u.recover()
		_starlight(u)
		u.rested_turns = u.rested_turns + 1 if rested else 0
		if not u.asleep():
			_watch(u)
		if not rested and posing(u):
			_refuse(u)
	for u in side:
		_grip(u)
		_bleed(u)
		if u.is_alive() and u.cell in flames:
			_flame(u, flames[u.cell], "ends its turn in fire")
	side = members(turn)  # a grip can drown one, a wound bleed one out
	for u in side:
		for e in u.footing.at_end if u.footing else ([] as Array[Effect]):
			u.afflict(e, (e.turns if e.turns else u.footing.turns) + 1)  # + 1: the tick below takes this turn
	for u in side:
		if u.asleep() and side.any(func(o: Unit): return o != u and next_to(o.cell, u.cell)):
			u.wake()
	for u in side:
		u.tick()
	for u in members(turn):
		_sap(u)
		_synergize(u)
	for u in members(turn):
		_starkind(u, true)
	for z in zones.filter(func(x: Zone): return x.faction == turn):
		z.turns -= 1
	zones.assign(zones.filter(func(x: Zone): return x.turns > 0))
	for c in flames.keys():
		if flames[c].faction == turn:
			flames[c].turns -= 1
			if flames[c].turns <= 0:
				flames.erase(c)
	for c in earthworks.keys():
		if earthworks[c].faction == turn:
			earthworks[c].turns -= 1
			if earthworks[c].turns <= 0:
				earthworks.erase(c)
	_tidy_debris()
	_revive()
	_check_stall()
	if phase != Phase.TURNS:
		return
	turn = order[(order.find(turn) + 1) % order.size()]


# A side's turn ends. If none of its units could make out a single foe it would fight while enemies
# stand (only the Passive or Aggressive they seem to be counts too), the turn was stalled, by the foes
# hiding or posing (concealment, trickery, a front); a turn that wasn't starts its count over. Once
# more turns in a row have stalled than its grace(), Ramut's Ire builds a rank on each of them, a rank
# a stalled turn.
func _check_stall() -> void:
	var side := members(turn)
	var foes: Array = units.values().filter(func(t: Unit): return not Faction.friends(t.faction, turn) and t.is_alive())
	stalling.clear()
	if side.is_empty() or foes.is_empty() or foes.any(func(t: Unit): return side.any(_sees_foe.bind(t))):
		stalled_turns[turn] = 0
		return
	stalled_turns[turn] = stalled_turns.get(turn, 0) + 1
	for t: Unit in foes:
		if _hides(t):
			stalling.append(t)
	if ire_grace < 0.0 or stalled_turns[turn] <= grace(turn):
		return
	for u in stalling:
		_ire(u)


# Stalled turns in a row side f waits out before the Ire: the units still standing on the smallest side
# in the fight, times ire_grace, less whatever its prayers to Ramut took off (at least 0).
func grace(f: Faction) -> float:
	var counts := {}
	for u: Unit in units.values():
		if u.is_alive():
			counts[u.faction] = counts.get(u.faction, 0) + 1
	var fewest: int = counts.values().min() if not counts.is_empty() else 0
	return maxf(ire_grace * fewest - hastened.get(f, 0), 0.0)


func _sees_foe(o: Unit, t: Unit) -> bool:
	var r := read(o, t)
	return r.located() and r.attitude(o) == &"foe"


# Hides or poses: concealment, trickery or a front of its own.
func _hides(t: Unit) -> bool:
	var kinds: Array[StringName] = [&"dark", &"light", &"sound", &"sight"]
	return t.stat(&"concealment", kinds) > 0 or t.stat(&"trickery", kinds) > 0 or Perception.fronts(t)


# Ramut's Ire builds a rank on u, each defeating a rank of its concealment and trickery, against
# everyone, for the rest of the battle: what it took to stop the stall stays taken.
func _ire(u: Unit) -> void:
	var rank := 1
	for e in IRE.effects:
		rank = (u.timed[e].rank + 1) if e in u.timed else 1
		var a := u.afflict(e, 0, rank)
		a.skill = IRE
		a.lasting = true
	stalled.emit(u, rank)


# Still held as its side's turn ends (a grapple: Drown's effects), u takes the grip's dice + its
# holder's mod in the grip's stat - and, fooled by its holder, looks harder at it. A holder that's
# fallen, or isn't beside it any more, lets go.
func _grip(u: Unit) -> void:
	var a := held_by(u)
	if a == null:
		return
	var by := a.by
	var s := a.skill
	if not by or not by.is_alive() or not next_to(by.cell, u.cell):
		_let_go(u, s)
		return
	var before := u.hp
	u.hit(roll(s.grip) + by.mod(s.stat(), s.tags), s.tags, by)
	gripped.emit(u, by, before - u.hp)
	if u.is_alive() and u.hp < before and read(u, by).deceived:
		doubt(u, by)


func _let_go(u: Unit, s: Skill) -> void:
	for e in s.effects:
		u.timed.erase(e)


# Forced movement: t is drawn up to n tiles toward `to`, a step at a time, stopping beside it or at
# anything in the way (Sing). Ground it's dragged over does nothing to it.
func pull(t: Unit, to: Unit, n: int) -> void:
	for i in n:
		if next_to(t.cell, to.cell):
			return
		var d := to.cell - t.cell
		var c := t.cell + Vector2i(signi(d.x), signi(d.y))
		if not on_map(c) or not move(t, c):
			return


# A heal: its wounds of rank `power` or less cleared (an effect's wound flag), then hp back, plus
# per_wound for each wound cleared (First Aid: rank). Returns the wounds cleared.
func mend(t: Unit, hp: int, power: int, per_wound := 0) -> int:
	var n := 0
	for e in t.timed.keys():
		if e.wound and t.timed[e].rank <= power:
			t.timed.erase(e)
			n += 1
	t.heal(hp + per_wound * n)
	return n


# Where a dragging skill (Drown) would take t: the nearest free ground with its tag, by how far t
# must be dragged, that the caster could walk to (within its movement); null if there's none.
func drag_spot(caster: Unit, skill: Skill, t: Unit) -> Variant:
	var best: Variant = null
	for c in map.get_used_cells():
		if skill.drags_to not in terrain(c).tags or (unit_at(c) and unit_at(c) != t):
			continue
		if Command.tiles(caster.cell, c) > caster.stat(&"movement"):
			continue
		if best == null or Command.tiles(t.cell, c) < Command.tiles(t.cell, best) or (Command.tiles(t.cell, c) == Command.tiles(t.cell, best)
				and Command.tiles(caster.cell, c) < Command.tiles(caster.cell, best)):
			best = c
	return best


# Off a dragging skill's contest roll: 1 a tile it must drag the foe, less (rank - 1) a tile.
static func drag_penalty(skill: Skill, rank: int, n: int) -> int:
	return maxi(1 - (rank - 1), 0) * n


# Drags t onto `to` and the caster in beside it: onto free ground with the tag if there's any (Drown:
# submerging both), else the nearest free tile. Ground passed over does nothing to either.
func drag(caster: Unit, t: Unit, to: Vector2i, tag: StringName) -> void:
	move(t, to)
	var best := []
	for dx in [-1, 0, 1]:
		for dy in [-1, 0, 1]:
			var c := to + Vector2i(dx, dy)
			if c == to or not on_map(c) or (unit_at(c) and unit_at(c) != caster):
				continue
			var key := [int(tag in terrain(c).tags), -Command.tiles(caster.cell, c)]
			if best.is_empty() or key > best[0]:
				best = [key, c]
	if not best.is_empty() and best[1] != caster.cell:
		move(caster, best[1])


# What a persona of rank p can put forward through Personify: stances (Friendly from II, the wrong
# team from III), a level it claims (II), and a name from its pools (III).
static func stances(p: int) -> Array[String]:
	var out: Array[String] = [""]
	if p >= 2:
		out.append("Friendly")
	if p >= 3:
		out.append_array(["Enemy", "Aggressive", "Passive", "Traitor"])
	return out


# Personify's active half (Skill.hybrid): pays its AP, then changes what u's persona puts forward, as
# far as its persona rank allows - up to its Personify rank of changes a use (persona_changes()). It
# advertises while it puts anything forward, and stops once it puts nothing (or clears it all).
# changes: {vibe: Array[String] (I), stance: String (II: Friendly; III: the rest), shows_level: int
# (II; 0: none claimed), tags: Array[StringName] (identity, III), adjective, noun: String (III),
# clear: bool (everything off, as one change)}.
func personify(u: Unit, s: Skill, changes: Dictionary) -> bool:
	if not _acting(u) or not s.hybrid or u.rank(s) == 0 or persona_changes(u, s, changes) > u.rank(s) or not u.pay_for(s):
		return false
	var p := persona_rank(u, s)
	if changes.get("clear", false):
		changes = {vibe = [], stance = "", shows_level = 0, tags = [], adjective = "", noun = ""}
	if changes.get("stance", u.stance) in stances(p):
		u.stance = changes.get("stance", u.stance)
	if p >= 2:
		u.shows_level = maxi(changes.get("shows_level", u.shows_level), 0)
	if p >= 1 and changes.has("vibe"):
		u.shows_vibe.assign(changes.vibe)
	if p >= 3 and changes.has("tags"):
		u.shows_tags.assign(changes.tags)
	if p >= 3 and (changes.has("adjective") or changes.has("noun")):
		u.set_alias(changes.get("adjective", ""), changes.get("noun", ""))
	var forward := not (u.shows_vibe.is_empty() and u.shows_tags.is_empty()) or u.stance != "" or u.shows_level > 0 or u.alias != ""
	if forward != u.is_on(s):
		u.toggle(s)
	used.emit(u, s, u, 0)
	return true


# How many things `changes` changes about u's persona: its stance, the level it claims and the name it
# goes by count one each; each vibe word or identity tag put on or taken off, one each. Clearing it
# all is one.
static func persona_changes(u: Unit, _s: Skill, changes: Dictionary) -> int:
	if changes.get("clear", false):
		return 1
	var n := 0
	for k in ["stance", "shows_level"]:
		if changes.has(k) and changes[k] != u.get(k):
			n += 1
	if (changes.has("adjective") or changes.has("noun")) and (changes.get("adjective", "") + " " + changes.get("noun", "")).strip_edges() != u.alias:
		n += 1
	for pair in [["vibe", u.shows_vibe], ["tags", u.shows_tags]]:
		if changes.has(pair[0]):
			var now: Array = changes[pair[0]]
			n += now.filter(func(x): return x not in pair[1]).size() + pair[1].filter(func(x): return x not in now).size()
	return n


# u's persona rank with s switched on.
static func persona_rank(u: Unit, s: Skill) -> int:
	return roundi(u.stat(&"persona")) + (0 if u.is_on(s) else u.rank(s))


func _acting(u: Unit) -> bool:
	return phase == Phase.TURNS and (u.faction == turn or (posing(u) and u.follows.faction == turn)) and u.is_alive() and not u.asleep()


# Touching, diagonals included.
static func next_to(a: Vector2i, b: Vector2i) -> bool:
	return a != b and absi(a.x - b.x) <= 1 and absi(a.y - b.y) <= 1


# The sides in turn order that count toward the battle's end: all but neutral ones (Starmen).
func fighting() -> Array[Faction]:
	var out: Array[Faction] = []
	out.assign(order.filter(func(f: Faction): return not f.neutral))
	return out


# How many sides are still fighting, allies counting as one.
func sides_left() -> int:
	var heads: Array[Faction] = []
	for f in fighting():
		if not heads.any(func(h: Faction): return Faction.friends(h, f)):
			heads.append(f)
	return heads.size()


# A side holding the field once the battle's over (allies hold it together), or null.
func victor() -> Faction:
	var left := fighting()
	return left[0] if phase == Phase.OVER and sides_left() == 1 and not left.is_empty() else null


# Whether side f won: the battle's over, it's still standing, and it or an ally holds the field.
func won(f: Faction) -> bool:
	return victor() != null and Faction.friends(victor(), f) and members(f).size() > 0


# --- The star lattice (the Astral Envoy)

func on_lattice(c: Vector2i) -> bool:
	return c in panes or c in starpower


# The starpower source c draws on: itself, or the fullest source joined to it through whole starpanes,
# side-on. Null if it's off the lattice or linked to none.
func star_source(c: Vector2i) -> Variant:
	if not on_lattice(c):
		return null
	var seen := {c: true}
	var queue: Array[Vector2i] = [c]
	var best: Variant = null
	while not queue.is_empty():
		var at: Vector2i = queue.pop_front()
		if at in starpower and (best == null or charge[at] > charge[best]):
			best = at
		for d in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var n: Vector2i = at + d
			if n not in seen and on_lattice(n):
				seen[n] = true
				queue.append(n)
	return best


# How much faster Power comes back on c: x2 linked to a source with a little Power in it, up to x5 to a
# full one; x1 off the lattice, or linked only to empty sources.
func star_rate(c: Vector2i) -> float:
	var s: Variant = star_source(c)
	if s == null or charge[s] <= 0:
		return 1.0
	return lerpf(STAR_SLOW, STAR_FAST, charge[s] / float(STAR_CAPACITY))


# As its side's turn ends, on the lattice: Power back at star_rate() x its resting rate ((con mod +
# wis mod) / 2, at least 1), whatever it did; Energy that isn't Power gets STAR_ENERGY of the boost.
func _starlight(u: Unit) -> void:
	var m := star_rate(u.cell)
	if m <= 1.0:
		return
	var k := maxi(u.rounded((u.mod(&"constitution") + u.mod(&"wisdom")) / 2.0), 1)
	u.energy += u.rounded(k * m) if u.powered() else u.rounded(k * (m - 1.0) * STAR_ENERGY)


# How far a unit's sap reaches another: a tile side-on, +0.25 a size step past Medium of each, so
# larger units reach (and are reached on) diagonals.
func sap_reach(u: Unit, o: Unit) -> float:
	return 1.0 + 0.25 * (maxi(_size(u) - MEDIUM, 0) + maxi(_size(o) - MEDIUM, 0))


func _size(u: Unit) -> int:
	return roundi(u.stat(&"size")) if u.race else u.size


# Starsap, as its side's turn ends: it drains its sap in Energy (Power) from each unit of another side
# in sap_reach(), HP once their Energy runs out, into its own Power; what it can't hold fills the
# starpower sources, emptiest first. Once every source is full, it saps no more.
func _sap(u: Unit) -> void:
	var n := roundi(u.stat(&"sap"))
	if n <= 0 or (not charge.is_empty() and charge.values().all(func(x: int): return x >= STAR_CAPACITY)):
		return
	var drained := {}
	var got := 0
	for o: Unit in units.values():
		if Faction.friends(o.faction, u.faction) or not o.is_alive() or Vector2(o.cell).distance_to(Vector2(u.cell)) > sap_reach(u, o) + 0.0001:
			continue
		var off := mini(o.energy, n)
		o.energy -= off
		o.damage(n - off)
		drained[o] = n
		got += n
	if drained.is_empty():
		return
	var room := u.max_energy - u.energy
	u.energy += got
	got -= mini(got, room)
	var sources := charge.keys()
	sources.sort_custom(func(a: Vector2i, b: Vector2i): return charge[a] < charge[b])
	for c: Vector2i in sources:
		var put := mini(got, STAR_CAPACITY - charge[c])
		charge[c] += put
		got -= put
	sapped.emit(u, drained)


# Starkind, as its side's turn starts or ends: ending it off the lattice, it loses (1 - 0.2 x rank) of
# its max HP. On the lattice at full Power, it grows a Reforming stack each time; otherwise it loses
# one. Once its stacks reach its level, it reforms (Unit.reforms_into: a Starman) at full strength.
func _starkind(u: Unit, ending: bool) -> void:
	var k := u.starkind()
	if k <= 0 or not u.is_alive():
		return
	var on := on_lattice(u.cell)
	if ending and not on:
		u.damage(maxi(ceili(maxf(1.0 - 0.2 * k, 0.0) * u.max_hp), 1))
		if not u.is_alive():
			return
	var stacks: int = u.timed[REFORMING].rank if REFORMING in u.timed else 0
	stacks = stacks + 1 if on and u.energy >= u.max_energy else maxi(stacks - 1, 0)
	if stacks <= 0:
		u.timed.erase(REFORMING)
		return
	var a := u.afflict(REFORMING, 1, stacks)
	a.rank = stacks
	a.lasting = true
	if stacks >= u.lv() and u.reforms_into:
		var c := u.cell
		units.erase(c)
		u.get_parent().remove_child(u)
		var now := summon(load(u.reforms_into), u.faction, c)
		reformed.emit(u, now)
		u.queue_free()


# Breathtaking: a curse that lands gives its target a stack of Asphyxia - each 1% x the caster's
# Breathtaking rank of its max HP gone (Applied.scale) - holding for (1 + that rank) of its turns since
# the last, then falling a stack a turn.
func _choke(caster: Unit, t: Unit) -> void:
	var k := roundi(caster.stat(&"breathless"))
	var a: Unit.Applied
	if ASPHYXIA in t.timed:
		a = t.timed[ASPHYXIA]
		a.rank += 1
	else:
		a = t.afflict(ASPHYXIA, 1, 1)
	a.turns = 1 + k + (1 if t.faction == turn else 0)
	a.fades = true
	a.scale = maxf(a.scale, k)
	a.by = caster
	a.since = turns_begun
	t.refit()


# --- Strike

# A chain skill (Strike) on a foe: up to rank hits (one, with Brutal Strike's single), each rolling on
# its own - d20 + its attack mod (and bracing) - a hit in a row, against Defense; a miss ends it. Each
# hit landed in a row takes 1 off the rolls and damage after it. Its Strike passives (Effect stats)
# shape it: decisive (after a critical the rest land; damage by the higher of dex and str mod), brutal
# (the first hit + its weapon's rank + this), steady (the first this hits: no penalty, and a miss
# doesn't end it), featured (the first this hits + cha mod, up to this), recording (the first this hits
# try to curse the foe's leftmost skill: _record()), and its element (imbued, or Elemental Mastery:
# the element's tag, the first hit + its highest mental mod). Landing 12 hits with Strike! (restrike),
# it strikes again at once with restrike - 1 more (up to three times: a bowling game's strikes); 36 in
# all (PERFECT_HITS) is a Perfect: PERFECT_HEAL healed at once. How many hits landed.
func _chain(caster: Unit, skill: Skill, t: Unit, r: int, tags: Array[StringName], extra := 0, depth := 0) -> int:
	var tier := skill.tier(r)
	if not tier:
		return 0
	var hits := (1 if caster.stat(&"single") > 0.0 else r) + extra
	var steady := roundi(caster.stat(&"steady"))
	var featured := roundi(caster.stat(&"featured"))
	var recording := roundi(caster.stat(&"recording"))
	var decisive := caster.stat(&"decisive") > 0.0
	var brutal := roundi(caster.stat(&"brutal"))
	var elemental := caster.stat(&"elemental") > 0.0
	var element := caster.element if caster.element else (Unit.GOD_TAGS.get(caster.deity(), &"fire") as StringName)
	var imbued := caster.imbued > 0
	var blow := tags.duplicate()
	if (imbued or elemental) and element not in blow:
		blow.append(element)
	var mental := maxi(maxi(caster.mod(&"intelligence"), caster.mod(&"wisdom")), caster.mod(&"charisma"))
	var landed := 0
	var gross := 0
	var row := 0  # hits in a row so far
	var sure := false
	for i in hits:
		if not t.is_alive():
			break
		var penalty := 0 if i < steady else row
		var d20 := rng.randi_range(1, 20)
		var total := d20 + caster.attack_mod(skill) + caster.check_bonus(caster.wielded(skill.stat(), skill.tags), &"offensive") - penalty
		var defense := t.defense(blow)
		var crit := d20 == 20
		attacked.emit(caster, t, d20, total, defense)
		_evaluate(caster, skill, d20, total)
		if not (sure or crit or total >= defense):
			row = 0
			if i < steady:
				continue
			break
		if crit and decisive:
			sure = true
		var stat := tier.stat
		if decisive and stat and caster.mod(&"dexterity", skill.tags) > caster.mod(caster.wielded(stat, skill.tags), skill.tags):
			stat = &"dexterity"
		var power := tier.power + roll(tier.dice) - penalty
		if stat:
			power += caster.mod(caster.wielded(stat, skill.tags), skill.tags) + caster.weapon_bonus(stat)
		if i < featured:
			power += clampi(caster.mod(&"charisma"), 0, featured)
		if i == 0:
			power += (brutal + (caster.weapon.rank if caster.weapon else 0)) if brutal > 0 else 0
			power += mental * (int(imbued) + int(elemental))
		var dealt := maxi(roundi(power * (1.0 + caster.stat(&"damage", blow))), 1) * (2 if crit else 1)
		t.hit(dealt, blow, caster)
		gross += dealt
		landed += 1
		row += 1
		if i < recording and t.is_alive():
			_record(caster, t)
	if gross > 0 and next_to(caster.cell, t.cell):
		_refill(caster, t, gross)  # Starblade
	if imbued and depth == 0:
		caster.imbued -= 1
	var again := roundi(caster.stat(&"restrike"))
	if landed >= 12 and again > 0 and depth < 3 and t.is_alive():  # Strike!: a strike, bowled
		landed += _chain(caster, skill, t, r, tags, again - 1, depth + 1)
	if depth == 0 and landed >= PERFECT_HITS:  # three strikes in a row: a perfect game
		caster.heal(PERFECT_HEAL)
		perfect.emit(caster)
	return landed


# Record Striker: the foe's wis (and bracing) against the striker's highest mental mod; failing, the
# skill in its leftmost hotbar slot goes a rank down for its next turn (a curse).
func _record(caster: Unit, t: Unit) -> void:
	var first: Skill = null
	for s in t.hotbar:
		if s:
			first = s
			break
	if not first:
		return
	var mind: StringName = [&"intelligence", &"wisdom", &"charisma"].reduce(func(best: StringName, x: StringName): return x if caster.mod(x) > caster.mod(best) else best, &"intelligence")
	var mine: int = rng.randi_range(1, 20) + caster.mod(mind) + caster.check_bonus(mind, &"offensive")
	var theirs := rng.randi_range(1, 20) + t.mod(&"wisdom") + t.check_bonus(&"wisdom", &"defensive")
	contested.emit(caster, t, mine, theirs)
	if theirs > mine:
		return
	var e := Effect.new()
	e.stat = "rank"
	e.amount = -1.0
	e.name = "Recorded"
	e.skills = [first] as Array[Skill]
	var a := t.afflict(e, 1 + (1 if t.faction == turn else 0))
	a.by = caster
	a.since = turns_begun


# Elemental Strike: its user's next rank Strikes carry its element (Unit.element: picked as it's used,
# else the skill's first), the first hit of each + its highest mental mod.
func imbue(u: Unit, skill: Skill, r: int) -> void:
	if u.element not in skill.elements:
		u.element = skill.elements[0]
	u.imbued = r


# --- Sol's fire

# Fire a unit takes from a burning tile: 1d8 + its setter's wis mod (at least 1), fire and
# environmental (Flamedance wards it).
func _flame(u: Unit, f: Flame, why: String) -> void:
	var n := u.hit(maxi(roll(Vector2i(1, 8)) + f.bonus, 1), [&"fire", &"environmental"] as Array[StringName], f.by if is_instance_valid(f.by) else null)
	burned.emit(u, n, why)


# Flamewall, cast on c: c and rank tiles to either side of it, across the caster's line to it, catch
# fire for rank of the caster's side's turns. A unit standing on one makes a dex check against the
# caster's d20 + wis mod to get clear; failing, it burns at once.
func _flamewall(caster: Unit, skill: Skill, c: Vector2i) -> void:
	var r := caster.rank(skill)
	var d := Vector2i(signi(c.x - caster.cell.x), signi(c.y - caster.cell.y))
	var across := Vector2i(-d.y, d.x) if d != Vector2i.ZERO else Vector2i(1, 0)
	var tiles: Array[Vector2i] = [c]
	for i in range(1, r + 1):
		tiles.append(c + across * i)
		tiles.append(c - across * i)
	for t in tiles:
		if not on_map(t):
			continue
		flames[t] = Flame.new(caster, r)
		var u := unit_at(t)
		if u and u.is_alive():
			var mine := rng.randi_range(1, 20) + u.mod(&"dexterity") + u.check_bonus(&"dexterity", &"defensive")
			var theirs := rng.randi_range(1, 20) + caster.mod(&"wisdom", skill.tags) + caster.check_bonus(&"wisdom", &"offensive")
			contested.emit(u, caster, mine, theirs)
			if mine <= theirs:
				_flame(u, flames[t], "is caught in the wall")


# Solar, cast toward c: a cone of the skill's degrees (+ 15 a rank past I), its range long, from the
# caster; everyone in it - the caster too - takes d20 + the caster's wis score in fire.
func _solar(caster: Unit, skill: Skill, c: Vector2i) -> void:
	var r := caster.rank(skill)
	var half := deg_to_rad(skill.cone + 15.0 * (r - 1)) / 2.0
	var aim := Vector2(c - caster.cell).angle()
	var long := area_reach(caster, skill)
	var hit := {}
	for u: Unit in units.values():
		var to := Vector2(u.cell - caster.cell)
		if u == caster or (u.is_alive() and to.length() <= long + 0.0001 and absf(angle_difference(aim, to.angle())) <= half + 0.0001):
			hit[u] = u.hit(roll(Vector2i(1, 20)) + roundi(caster.stat(&"wisdom")), [&"fire"] as Array[StringName], caster)
	exploded.emit(caster, skill, c, hit)


# Using a skill from a burning slot (Unit.burning_slots()) burns its user.
func _burn(u: Unit, s: Skill) -> void:
	var i := u.hotbar.find(s)
	var hot := u.burning_slots()
	if i >= 0 and i in hot:
		var n := u.hit(hot[i][0], [&"fire"] as Array[StringName], hot[i][1])
		burned.emit(u, n, "its slot burns")


# A skill on its user that spreads its effects to every ally within rank tiles (Flamecharm,
# Flamedance) - from rank V of a splitting one (Flamecharm), only the nearest rank of them, its
# strength shared out (Applied.scale).
func _aura(caster: Unit, skill: Skill, r: int) -> void:
	var near: Array = units.values().filter(func(o: Unit): return o.is_alive() and Faction.friends(o.faction, caster.faction) and Command.tiles(o.cell, caster.cell) <= r)
	near.sort_custom(func(a: Unit, b: Unit): return Command.tiles(a.cell, caster.cell) < Command.tiles(b.cell, caster.cell))
	var share := 1.0
	if skill.splits and r >= 5:
		near = near.slice(0, r)
		share = 1.0 / maxi(near.size(), 1)
	for o: Unit in near:
		for e in skill.effects:
			var n := skill.lasts(r, caster)
			var a := o.afflict(e, n + (1 if o.faction == turn else 0), r)
			a.total = n
			a.scale = share
			a.skill = skill
			a.by = caster
			a.since = turns_begun


# The Burning Bag: the one there is, taken from whoever has it (or the stash) and put on its caster at
# the skill's rank; what the caster wore there goes to the stash, if it's the player's.
func _retrieve(caster: Unit, skill: Skill, r: int) -> void:
	var it := skill.retrieves
	for o: Unit in $Units.get_children():
		for slot in CharacterSheet.SLOTS:
			var worn: Item = o.get(slot)
			if worn and worn.name == it.name:
				o.unequip(slot)
	for x in Game.stash.duplicate():
		if x.name == it.name:
			Game.stash.erase(x)
	var mine: Item = it.duplicate()
	mine.rank = r
	var old: Item = caster.get(mine.slot)
	caster.equip(mine)
	if old and player and caster.faction == player.faction:
		Game.stash.append(old)


# Humble: t's max HP is capped at its HP now less 1% of its max (Effect humble: the cut), for rank x 4
# x (1 - the share cut) turns, at least 1: the less it loses, the longer it lasts.
func _humble(caster: Unit, skill: Skill, t: Unit, r: int) -> void:
	var cap := maxi(t.hp - maxi(ceili(0.01 * t.max_hp), 1), 1)
	var cut := t.max_hp - cap
	if cut <= 0:
		return
	var e := Effect.new()
	e.stat = "humble"
	e.name = "Humbled"
	e.amount = cut
	var n := maxi(ceili(r * 4.0 * (1.0 - float(cut) / t.max_hp)), 1)
	var a := t.afflict(e, n + (1 if t.faction == turn else 0), r)
	a.skill = skill
	a.by = caster
	a.since = turns_begun
	t.refit()
	if not Faction.friends(t.faction, caster.faction) and caster.stat(&"breathless") > 0.0:
		_choke(caster, t)


# Chant, as its side's turn ends with it having waited (rested) through it: its next rank Sweet
# Nothing gains each bring one more, and its next Warlock skill is used a rank higher.
func _chant(u: Unit) -> void:
	var r := roundi(u.stat(&"chant"))
	if r > 0:
		u.chant_gains = maxi(u.chant_gains, r)
		u.chant_up = true
		chanted.emit(u, r)


# --- Last stands, Level Down and Death

# A general defensive check of the whole unit: d20 + its average stat mod (Unit.average_mod()). Against
# an execute (Death, at its rank), cut by how hurt it is: x (HP left / max HP) / rank.
func last_stand(u: Unit, execute := 0) -> int:
	var roll := rng.randi_range(1, 20) + u.average_mod()
	if execute > 0:
		roll = floori(roll * (float(u.hp) / maxi(u.max_hp, 1)) / execute)
	return roll


# Level Down: rank rolls of d20 + the caster's mod, each beating the higher of the foe's average stat
# mod + level and its last stand. Each that does takes a level off it, for as many turns (rank - misses):
# the skill's level effect at that rank, brittle (easily cleansed).
func _level_down(caster: Unit, skill: Skill, t: Unit, r: int) -> void:
	var bar := maxi(t.average_mod() + t.lv(), last_stand(t))
	var hits := 0
	for i in r:
		var roll := rng.randi_range(1, 20) + caster.mod(skill.stat(), skill.tags) + caster.check_bonus(skill.stat(), &"offensive")
		contested.emit(caster, t, roll, bar)
		if roll > bar:
			hits += 1
	_expose(caster)
	_expose(t)
	if hits > 0:
		for e in skill.effects:
			var a := t.afflict(e, hits + (1 if t.faction == turn else 0), hits)
			a.total = hits
			a.skill = skill
			a.by = caster
			a.since = turns_begun
	leveled.emit(caster, t, hits)


# Death: the foe's last stand against an execute at the skill's rank, against d20 + the caster's mod
# (the caster wins ties). Failing, it takes 1 true damage and dies at once - keeping the HP it had for
# revival and die-hard effects (Unit.slain_from). A heart left, it goes down as usual.
func _death(caster: Unit, skill: Skill, t: Unit, r: int) -> void:
	var stand := last_stand(t, r)
	var mine := rng.randi_range(1, 20) + caster.mod(skill.stat(), skill.tags) + caster.check_bonus(skill.stat(), &"offensive")
	contested.emit(caster, t, mine, stand)
	_expose(caster)
	_expose(t)
	if stand > mine:
		return
	t.slain_from = t.hp
	t.damage(1)
	t.hp = 0
	caster.gain(&"kill", 1)


# --- Synergy

# The others o shares what it makes out with: its leader, or its party, where either of the two has
# Synergy (leaders share with their whole party, members with their leader) - within the leader's
# command range of its party (Command.party_reach_of(): a Quartz Ring makes it endless).
func synergized(o: Unit) -> Array[Unit]:
	var out: Array[Unit] = []
	for p: Unit in units.values():
		if p == o or not p.is_alive() or p.faction != o.faction or not (p.follows == o or o.follows == p):
			continue
		var lead := p if o.follows == p else o
		if (o.stat(&"synergy") > 0.0 or p.stat(&"synergy") > 0.0) and Command.tiles(o.cell, p.cell) <= Command.party_reach_of(lead):
			out.append(p)
	return out


# The clearer of two reads: more detail, then HP made out, then not fooled.
static func clearer(a: Read, b: Read) -> bool:
	if a.net != b.net:
		return a.net > b.net
	if (a.hp != null) != (b.hp != null):
		return a.hp != null
	return b.deceived and not a.deceived


# As its side's turn ends, o gets its own first look at what its synergized partners make out that it
# needs a check for: suspicious tiles (inspect()), and units under a deceiving skill they saw through
# (investigate(), against that skill's roll). Once each.
func _synergize(o: Unit) -> void:
	for p in synergized(o):
		for c in suspicious(p):
			if c not in o.noticed:
				o.noticed[c] = true
				inspect(o, c)
		for t: Unit in units.values():
			if t == o or o.noticed.has(t):
				continue
			for e in t.timed:
				var a: Unit.Applied = t.timed[e]
				if a.skill and a.skill.investigated and p in a.known_to and o not in a.known_to:
					o.noticed[t] = true
					investigate(t, a.skill, [o] as Array[Unit], a.roll)
					break


func _on_died(u: Unit) -> void:
	units.erase(u.cell)
	u.timed.clear()  # nothing ticks for the dead
	u.channel = null
	var it := u.loot.roll(rng) if u.loot else null
	if it:
		spoils.append([it, u.faction])
		dropped.emit(u, it)
	if u.reverts_to:  # a Starman falls back into a Starmote, keeping what Power it had
		var mote := summon(load(u.reverts_to), u.faction, u.cell)
		if mote:
			mote.energy = u.energy
			reverted.emit(u, mote)
	for o in units.values():
		if o.faction == u.faction:
			return  # faction still standing
	var i := order.find(u.faction)
	order.erase(u.faction)
	zones.assign(zones.filter(func(z: Zone): return z.faction != u.faction))  # nothing left to tick them
	if sides_left() < 2:
		phase = Phase.OVER
	elif turn == u.faction:
		turn = order[i % order.size()]


func _enter(p: Phase) -> void:
	match p:
		Phase.INITIATIVE:
			order = roll_initiative()
			phase = Phase.TURNS if sides_left() > 1 else Phase.OVER
		Phase.TURNS:
			turn = order[0]
		Phase.OVER:
			for u: Unit in $Units.get_children():
				refill(u)
