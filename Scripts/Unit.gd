class_name Unit
extends Node2D

signal hp_changed(was: int, now: int)
signal ep_changed(was: int, now: int)
signal died(u: Unit)

@export var cell: Vector2i
@export var team := 0

@export var max_hp := 10:
	set(m):
		max_hp = m
		if hp > m:
			hp = m
@export var max_ep := 10:
	set(m):
		max_ep = m
		if ep > m:
			ep = m

# Core stats. Full names: `int` is a builtin type and a `str` member would hide str().
@export_group("Stats")
@export var strength := 5
@export var dexterity := 5
@export var constitution := 5
@export var intelligence := 5
@export var wisdom := 5
@export var charisma := 5

# Starts at 0 and fills in _ready, so HP bars get an initial hp_changed(0, max_hp).
var hp := 0:
	set(v):
		v = clampi(v, 0, max_hp)
		if v == hp:
			return
		var was := hp
		hp = v
		hp_changed.emit(was, v)
		if v == 0:  # local v, not hp: a listener may have changed hp re-entrantly
			died.emit(self)

var ep := 0:
	set(v):
		v = clampi(v, 0, max_ep)
		if v == ep:
			return
		var was := ep
		ep = v
		ep_changed.emit(was, v)


func _ready() -> void:
	hp = max_hp
	ep = max_ep


func damage(d: int) -> void:
	hp -= maxi(d, 0)


# Dead units stay dead; use revive().
func heal(h: int) -> void:
	if is_alive():
		hp += maxi(h, 0)


func revive(h: int) -> void:
	if not is_alive():
		hp = maxi(h, 1)


# Pays an action cost; false (and nothing spent) if the unit can't afford it.
func spend(e: int) -> bool:
	if e < 0 or e > ep:
		return false
	ep -= e
	return true


func restore(e: int) -> void:
	ep += maxi(e, 0)


func is_alive() -> bool:
	return hp > 0
