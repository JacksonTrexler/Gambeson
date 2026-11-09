class_name BattleCamera
extends Camera2D

# Follows the fight on a map bigger than the screen (the Meadows): centred on the player's unit (its
# side's commander, once the player's down), or on the unit being commanded once it's far enough off
# centre. Home refocuses on the selected unit; Home again goes back to the player's unit.

const FAR := 110.0  # how far off centre (world pixels) the commanded unit gets before the view goes to it
const EASE := 8.0  # how quickly it glides there

var hud: Node  # HUD: who's the player's, who's selected
var battle: Battle
var focus: Unit  # Home's pick: the unit it keeps to, until Home goes back to the player's unit


func _ready() -> void:
	battle = get_parent().get_node_or_null("Battle")
	position_smoothing_enabled = false


func _process(delta: float) -> void:
	if not hud:
		for n in get_tree().get_nodes_in_group(&"hud"):
			hud = n
	var to := target()
	if to:
		var at := to.global_position
		if not _arrived:  # the first frame: straight there
			global_position = at
			_arrived = true
		global_position = global_position.lerp(at, 1.0 - exp(-EASE * delta))


var _arrived := false


# Whom the view keeps to: Home's pick while it lasts; the unit being commanded, once it's far off
# centre; else the player's unit (its commander, once it's down).
func target() -> Unit:
	if focus and is_instance_valid(focus) and focus.is_alive():
		return focus
	focus = null
	var selected: Unit = hud.selected if hud else null
	if selected and is_instance_valid(selected) and selected.is_alive() and selected != player() \
			and selected.global_position.distance_to(global_position) > FAR:
		return selected
	return player()


func player() -> Unit:
	if battle and battle.player and is_instance_valid(battle.player) and battle.player.is_alive():
		return battle.player
	return hud.observer() if hud and hud.has_method("observer") else null


# Home: the selected unit; again, back to the player's unit.
func home() -> void:
	var selected: Unit = hud.selected if hud else null
	if focus == null and selected and selected != player():
		focus = selected
	else:
		focus = null
		var p := player()
		if p:
			global_position = p.global_position


func _unhandled_input(e: InputEvent) -> void:
	if e.is_action_pressed(&"camera_home"):
		home()
		get_viewport().set_input_as_handled()
