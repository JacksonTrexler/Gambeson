extends Control

# Start screen: pick a side, a starter class and a name; Play opens the battle with that starter.

const HUMAN := preload("res://Races/human.tres")

@export var sides: Array[Faction] = []
@export var roles: Array[Role] = []
@export_file("*.tscn") var next_scene := "res://Scenes/museum.tscn"

@onready var side: Choice = %Side
@onready var role: Choice = %Role
@onready var starter_name: LineEdit = %Name
@onready var play: Button = %Play


func _ready() -> void:
	for f in sides:
		side.add(f.name, f.icon, f)
	for r in roles:
		role.add(r.name if not r.race or r.race == HUMAN else "%s\n%s" % [r.name, r.race.name], r.look, r)
	side.changed.connect(_check.unbind(2))
	role.changed.connect(_check.unbind(2))
	starter_name.text_changed.connect(_check.unbind(1))
	play.pressed.connect(_play)
	_check()


func _check() -> void:
	play.disabled = side.value == null or role.value == null or starter_name.text.strip_edges().is_empty()


func _play() -> void:
	Game.starter = {faction = side.value, role = role.value, name = starter_name.text.strip_edges()}
	if next_scene:
		get_tree().change_scene_to_file(next_scene)
