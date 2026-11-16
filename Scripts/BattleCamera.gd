class_name BattleCamera
extends Camera2D

# Follows the fight on a map bigger than the screen (the Meadows): centred on the player's unit (its
# side's commander, once the player's down), or on the active unit once it's far enough off centre -
# the one the player selects, or the last to act that the player's side makes out (one acting unseen
# doesn't draw the view: that would give it away). The arrow keys pan it (camera_left/right/up/down,
# rebindable in KeyBinds); a panned view stays put until someone acts, the turn or the selection
# changes, or Home. Home refocuses on the selected unit; Home again goes back to the player's unit.

const FAR := 110.0  # how far off centre (world pixels) the active unit gets before the view goes to it
const EASE := 8.0  # how quickly it glides there
const PAN := 360.0  # how fast the keys pan it, world pixels a second

var hud: Node  # HUD: who's the player's, who's selected
var battle: Battle
var focus: Unit  # Home's pick: the unit it keeps to, until Home goes back to the player's unit
var actor: Unit  # the active unit (above)
var panned := false  # moved by hand: it holds there
var _chasing: Unit  # the active unit it went to once far off centre, kept to till another takes over
var _selected: Unit  # the HUD's pick, as last seen
var _arrived := false


func _ready() -> void:
	battle = get_parent().get_node_or_null("Battle")
	position_smoothing_enabled = false
	if battle:
		battle.traveled.connect(func(u: Unit, _from: Vector2i, _path: Array[Vector2i]): acted(u))
		battle.used.connect(func(u: Unit, _s: Skill, _at: Variant, _dealt: int): acted(u))
		battle.turn_changed.connect(func(_was: Faction, _now: Faction): _let_go())


func _process(delta: float) -> void:
	if not hud:
		for n in get_tree().get_nodes_in_group(&"hud"):
			hud = n
	var picked: Unit = hud.selected if hud else null
	if picked != _selected:
		_selected = picked
		if picked:
			acted(picked)
	var v := Input.get_vector(&"camera_left", &"camera_right", &"camera_up", &"camera_down")
	if v != Vector2.ZERO:
		pan(v * PAN * delta / zoom.x)
	var to := target()
	if to:
		var at := to.global_position
		if not _arrived:  # the first frame: straight there
			global_position = at
			_arrived = true
		global_position = global_position.lerp(at, 1.0 - exp(-EASE * delta))


# Moves the view by hand; it holds there (target() is null) until something draws it back.
func pan(by: Vector2) -> void:
	panned = true
	focus = null
	_arrived = true
	global_position += by


# u acted (moved, used a skill) or was selected: the active unit, if the player's side makes it out.
func acted(u: Unit) -> void:
	if not is_instance_valid(u) or (hud and hud.has_method("view") and u != _selected and not hud.view(u).located()):
		return
	actor = u
	panned = false


# A new turn: back to the player's unit until someone acts.
func _let_go() -> void:
	panned = false
	actor = null
	_chasing = null


# Whom the view keeps to: Home's pick while it lasts; nobody while panned; the active unit, once it's
# far off centre (and from then on, till another's active); else the player's unit (its commander,
# once it's down).
func target() -> Unit:
	if focus and is_instance_valid(focus) and focus.is_alive():
		return focus
	focus = null
	if panned:
		return null
	var a: Unit = actor if actor and is_instance_valid(actor) and actor.is_alive() else null
	if a and a != player() and (a == _chasing or a.global_position.distance_to(global_position) > FAR):
		_chasing = a
		return a
	_chasing = null
	return player()


func player() -> Unit:
	if battle and battle.player and is_instance_valid(battle.player) and battle.player.is_alive():
		return battle.player
	return hud.observer() if hud and hud.has_method("observer") else null


# Home: the selected unit; again, back to the player's unit.
func home() -> void:
	panned = false
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
