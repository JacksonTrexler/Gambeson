class_name BattleCamera
extends Camera2D

# Follows the fight on a map bigger than the screen (the Meadows): centred on the player's unit (its
# side's commander, once the player's down), or on the active unit once it's far enough off centre -
# the one the player selects, or the last to act that the player's side makes out (one acting unseen
# doesn't draw the view: that would give it away). The arrow keys pan it (camera_left/right/up/down,
# rebindable in KeyBinds), and so does the mouse pushed to the screen's edge (edge_pan, a Setting; not
# over the HUD's side panels, nor with one open, nor when it's likely outside the window), a middle-drag
# (sideways, past the panels), a trackpad two-finger scroll and a two-finger touch drag; a panned view stays
# put until someone acts, the turn or the selection changes, or Home. Home refocuses on the selected unit; Home again goes back to the player's unit.

const FAR := 110.0  # how far off centre (world pixels) the active unit gets before the view goes to it
const EASE := 8.0  # how quickly it glides there
const PAN := 360.0  # how fast the keys pan it, world pixels a second
const EDGE := 3.0  # how far past a HUD panel's rect (design pixels) still counts as over it
const EDGE_DEAD := 0.88  # the edge zone starts outside this ellipse (a fraction of the view's half-size) and reaches full speed at 1.0
const GESTURE := 1.5  # world pixels a trackpad scroll's delta unit moves the view (before the map's gain)
const WINDOW_RING := 2  # screen pixels at a window's rim where windowed panning pauses (the cursor is likely off it)

static var edge_pan := true  # Settings: the mouse at the screen's edge pans (HUD sets it from Prefs)

var hud: Node  # HUD: who's the player's, who's selected
var battle: Battle
var focus: Unit  # Home's pick: the unit it keeps to, until Home goes back to the player's unit
var actor: Unit  # the active unit (above)
var panned := false  # moved by hand: it holds there
var _chasing: Unit  # the active unit it went to once far off centre, kept to till another takes over
var _selected: Unit  # the HUD's pick, as last seen
var _arrived := false
var _touches := {}  # finger index -> where it went down (a touch screen)
var _mouse: Variant = null  # the pointer in screen (HUD) space; null when it's left the window or hasn't moved


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
	if v == Vector2.ZERO and edge_pan and _mouse != null and hud and not (hud.has_method("_panel_open") and hud._panel_open()):
		if _pointer_in_window():
			v = edge_vec(_mouse, get_viewport_rect().size, hud_panels()) * map_gain(map_size(), get_viewport_rect().size)
	if v != Vector2.ZERO:
		pan(v * PAN * delta / zoom.x)
	var to := target()
	if to:
		var at := to.global_position
		if not _arrived:  # the first frame: straight there
			global_position = at
			_arrived = true
		global_position = global_position.lerp(at, 1.0 - exp(-EASE * delta))


# How hard, and which way, a pointer at p pushes the view (length 0..1): out from the view's centre, the
# edge zone being outside an ellipse (EDGE_DEAD of the half-size), its speed rising smoothly to 1 at the
# ellipse's own rim - so the middle of an edge and a corner move the view equally fast, the corner on the
# diagonal. Zero over one of `clear` (the HUD's panels sit on the edges).
static func edge_vec(p: Vector2, view: Vector2, clear: Array[Rect2]) -> Vector2:
	for r in clear:
		if r.grow(EDGE).has_point(p):  # a panel sits a few pixels in from the edge: its margin counts
			return Vector2.ZERO
	var q := (p - view / 2.0) / (view / 2.0)
	var r := q.length()
	if r <= EDGE_DEAD:
		return Vector2.ZERO
	return (q / r) * smoothstep(EDGE_DEAD, 1.0, r)


# How much faster a big map pans than a small one (edge and trackpad): the root of the map's longer side
# in views, kept between 0.75 and 2 - a map of one screen pans at 1, a four-screen one twice as fast.
static func map_gain(map_px: Vector2, view: Vector2) -> float:
	return clampf(sqrt(maxf(map_px.x / view.x, map_px.y / view.y)), 0.75, 2.0)


# How far a trackpad scroll of `delta` moves the view (world pixels).
static func gesture_by(delta: Vector2, zoom_x: float, gain: float) -> Vector2:
	return delta * GESTURE * gain / zoom_x


func map_size() -> Vector2:  # world pixels
	if not battle or not battle.map or not battle.map.tile_set:
		return Vector2.ZERO
	return Vector2(battle.map.get_used_rect().size * battle.map.tile_set.tile_size)


# Is the pointer inside the window (and, windowed, off its rim)? With no events once it has left, the last
# one can sit at the edge for ever; the OS cursor says where it really is.
func _pointer_in_window() -> bool:
	if DisplayServer.get_name() == "headless":
		return true
	var w := get_window()
	var rect := Rect2i(w.position, w.size)
	if w.mode != Window.MODE_FULLSCREEN and w.mode != Window.MODE_EXCLUSIVE_FULLSCREEN:
		rect = rect.grow(-WINDOW_RING)
	return rect.has_point(DisplayServer.mouse_get_position())


func hud_panels() -> Array[Rect2]:
	var out: Array[Rect2] = []
	for n in ["Root/Left", "Root/Right"]:
		var c := hud.get_node_or_null(n) as Control
		if c and c.visible:
			out.append(c.get_global_rect())
	return out


func _input(e: InputEvent) -> void:
	if e is InputEventMouse:
		_mouse = e.position
	if e is InputEventMouseMotion and e.button_mask & MOUSE_BUTTON_MASK_MIDDLE:  # the side panels cover the left and right edges: drag the view sideways too
		pan(drag_by(e.relative, zoom.x))
	elif e is InputEventPanGesture and _free_of_hud(e.position):  # two fingers on a trackpad
		pan(gesture_by(e.delta, zoom.x, map_gain(map_size(), get_viewport_rect().size)))
	elif e is InputEventScreenTouch:  # fingers on a touch screen: two or more drag the view
		if e.pressed:
			_touches[e.index] = e.position
		else:
			_touches.erase(e.index)
	elif e is InputEventScreenDrag and _touches.size() >= 2:
		pan(drag_by(e.relative / _touches.size(), zoom.x))


# Is p clear of the HUD's panels and screens (so a scroll there is the camera's, not a list's)?
func _free_of_hud(p: Vector2) -> bool:
	if hud and hud.has_method("_panel_open") and hud._panel_open():
		return false
	for r in hud_panels():
		if r.grow(EDGE).has_point(p):
			return false
	return true


# How far a middle-drag of `rel` design pixels moves the view: the ground follows the pointer.
static func drag_by(rel: Vector2, zoom_x: float) -> Vector2:
	return -rel / zoom_x


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_MOUSE_EXIT or what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		_mouse = null


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
