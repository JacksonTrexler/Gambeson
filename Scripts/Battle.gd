class_name Battle
extends Node2D

signal phase_changed(was: Phase, now: Phase)
signal turn_changed(was: Faction, now: Faction)
signal initiative_rolled(totals: Dictionary[Faction, int])

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


# Each living unit rolls a d20 and its faction sums them; highest total goes first. Ties re-roll.
func roll_initiative() -> Array[Faction]:
	var totals: Dictionary[Faction, int] = {}
	while true:
		totals.clear()
		for u in units.values():
			if u.faction and u.is_alive():
				totals[u.faction] = totals.get(u.faction, 0) + rng.randi_range(1, 20)
		var distinct := {}
		for t in totals.values():
			distinct[t] = true
		if distinct.size() == totals.size():
			break
	var o: Array[Faction] = []
	o.assign(totals.keys())
	o.sort_custom(func(a, b): return totals[a] > totals[b])
	print("Initiative: ", ", ".join(o.map(func(f): return "%s %d" % [f.name, totals[f]])))
	initiative_rolled.emit(totals)
	return o


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
