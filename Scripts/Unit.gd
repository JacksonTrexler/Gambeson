class_name Unit
extends Node2D

signal health_changed(old_value: int, new_value: int)
signal energy_changed(old_value: int, new_value: int)
signal died

@export var max_health: int = 100
@export var max_energy: int = 100

var health: int = max_health
var energy: int = max_energy


func _ready() -> void:
	health = max_health
	energy = max_energy


func _process(_delta: float) -> void:
	pass


func set_health(value: int) -> void:
	var new_value := clampi(value, 0, max_health)
	if new_value == health:
		return
	var old_value := health
	health = new_value
	health_changed.emit(old_value, new_value)
	if health == 0:
		died.emit()


func set_energy(value: int) -> void:
	var new_value := clampi(value, 0, max_energy)
	if new_value == energy:
		return
	var old_value := energy
	energy = new_value
	energy_changed.emit(old_value, new_value)


func change_health(amount: int) -> void:
	set_health(health + amount)


func change_energy(amount: int) -> void:
	set_energy(energy + amount)


func is_alive() -> bool:
	return health > 0
