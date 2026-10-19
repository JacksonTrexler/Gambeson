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
var _coin: Dictionary[Faction, float] = {}  # last-resort tie-breaker, flipped once per roll

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


# Each living unit rolls a d20 and its faction sums them; highest total goes first.
func roll_initiative() -> Array[Faction]:
	rolls.clear()
	_coin.clear()
	for u in units.values():
		if u.faction and u.is_alive():
			if u.faction not in rolls:
				rolls[u.faction] = []
				_coin[u.faction] = rng.randf()
			rolls[u.faction].append(rng.randi_range(1, 20))
	var o: Array[Faction] = []
	o.assign(rolls.keys())
	o.sort_custom(func(a, b): return a == _first(a, b))
	print("Initiative: ", ", ".join(o.map(func(f): return "%s %d" % [f.name, total(f)])))
	initiative_rolled.emit(rolls)
	return o


func total(f: Faction) -> int:
	return rolls[f].reduce(func(sum, d): return sum + d, 0)


func _first(a: Faction, b: Faction) -> Faction:
	if total(a) != total(b):
		return a if total(a) > total(b) else b
	return settle_tie(a, b)


# Equal initiative totals: more dexterity on the field, then the best single die, then a coin flip.
func settle_tie(a: Faction, b: Faction) -> Faction:
	var da := _dexterity(a)
	var db := _dexterity(b)
	if da != db:
		return a if da > db else b
	var ba: int = rolls[a].max()
	var bb: int = rolls[b].max()
	if ba != bb:
		return a if ba > bb else b
	return a if _coin[a] > _coin[b] else b


func _dexterity(f: Faction) -> int:
	var sum := 0
	for u in units.values():
		if u.faction == f and u.is_alive():
			sum += u.dexterity
	return sum


func end_turn() -> void:
	if phase == Phase.TURNS:
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
