class_name Battle
extends Node2D

signal phase_changed(was: Phase, now: Phase)

enum Phase { PLAYER, ENEMY, OVER }

var phase := Phase.PLAYER:
	set(v):
		if v == phase:
			return
		var was := phase
		_exit(was)
		phase = v
		phase_changed.emit(was, v)  # before _enter, so a chained change arrives in order
		_enter(v)

# Which unit stands on which cell. TileSet custom data is per tile type, so it can't hold this.
var units: Dictionary[Vector2i, Unit] = {}

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


func _on_died(u: Unit) -> void:
	units.erase(u.cell)
	var teams := {}
	for o in units.values():
		teams[o.team] = true
	if teams.size() < 2:
		phase = Phase.OVER


func _enter(_p: Phase) -> void:
	pass


func _exit(_p: Phase) -> void:
	pass
