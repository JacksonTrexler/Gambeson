extends Control

# Start screen: pick a side, a starter class, a scenario and a name; Play (or Enter) opens the battle
# with that starter. It starts on the demo's defaults, so Enter alone starts the demo: the name box shows the
# default name muted (its placeholder) and uses it until something else is typed.

const HUMAN := preload("res://Races/human.tres")
const RING := preload("res://Items/red_spinel_ring.tres")  # every player starts with one in the stash

@export var sides: Array[Faction] = []
@export var roles: Array[Role] = []
@export_file("*.tscn") var next_scene := "res://Scenes/play.tscn"  # the first scenario's
# Scenarios by name: the scene each opens (a battle with the HUD).
@export var scenarios: Dictionary[String, String] = {"Museum": "res://Scenes/play.tscn", "Astral Envoy": "res://Scenes/envoy_play.tscn"}
@export var default_side: Faction  # Lancin
@export var default_role: Role  # Adventurer
@export var default_name := "Shrike"

@onready var side: Choice = %Side
@onready var role: Choice = %Role
@onready var scenario: Choice = %Scenario
@onready var starter_name: LineEdit = %Name
@onready var play: Button = %Play


func _ready() -> void:
	for f in sides:
		side.add(f.name, f.icon, f)
	for r in roles:
		role.add(r.name if not r.race or r.race == HUMAN else "%s\n%s" % [r.name, r.race.name], r.look, r)
	for k in scenarios:
		scenario.add(k, null, scenarios[k])
	scenario.pick(next_scene)
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
	Game.outfit = role.value.outfit()  # a new starter, in its class's starting items
	Game.hearts = 0
	if not Game.stash.any(func(it: Item): return it == RING):
		Game.stash.append(RING)  # the player's own trinket: a life once a battle
	if next_scene:  # empty: stay (tests)
		get_tree().change_scene_to_file(scenario.value if scenario.value else next_scene)
