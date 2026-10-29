extends Control

# Start screen: pick a side, a starter class and a name; Play (or Enter) opens the battle with that
# starter. It starts on the demo's defaults, so Enter alone starts the demo: the name box shows the
# default name muted (its placeholder) and uses it until something else is typed.

const HUMAN := preload("res://Races/human.tres")

@export var sides: Array[Faction] = []
@export var roles: Array[Role] = []
@export_file("*.tscn") var next_scene := "res://Scenes/play.tscn"
@export var default_side: Faction  # Lancin
@export var default_role: Role  # Adventurer
@export var default_name := "Shrike"

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
	starter_name.text_submitted.connect(_submit.unbind(1))
	play.pressed.connect(_play)
	side.pick(default_side)
	role.pick(default_role)
	starter_name.placeholder_text = default_name
	_check()
	starter_name.grab_focus.call_deferred()


func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventKey and e.pressed and not e.echo and e.keycode in [KEY_ENTER, KEY_KP_ENTER]:
		get_viewport().set_input_as_handled()
		_submit()


# Enter: play, if everything's chosen.
func _submit() -> void:
	if not play.disabled:
		_play()


func _check() -> void:
	play.disabled = side.value == null or role.value == null


# What's typed, or the default name while the box is blank.
func chosen_name() -> String:
	var typed := starter_name.text.strip_edges()
	return typed if typed else default_name


func _play() -> void:
	Game.starter = {faction = side.value, role = role.value, name = chosen_name()}
	if next_scene:
		get_tree().change_scene_to_file(next_scene)
