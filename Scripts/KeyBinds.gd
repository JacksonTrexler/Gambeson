class_name KeyBinds
extends HBoxContainer

# Settings: rudimentary key rebinds. A dropdown of the bindable actions (the project's input map), the
# key on the one picked, and Rebind: a panel asks for the new key, and the next key pressed takes the
# action (Escape backs out). Saved to the user's settings and loaded as the game starts (load_saved()).

const SAVE := "user://keybinds.cfg"
const NAMES := {&"hotbar_1": "Hotbar 1", &"hotbar_2": "Hotbar 2", &"hotbar_3": "Hotbar 3", &"hotbar_4": "Hotbar 4",
		&"hotbar_5": "Hotbar 5", &"hotbar_6": "Hotbar 6", &"hotbar_7": "Hotbar 7", &"hotbar_8": "Hotbar 8", &"hotbar_9": "Hotbar 9",
		&"hotbar_10": "Hotbar 10", &"spellbook": "Spellbook", &"skills": "Skills", &"end_turn": "End turn", &"hold": "Hold",
		&"party": "Party", &"cancel": "Back out", &"next_unit": "Next unit", &"camera_home": "Camera: focus", &"hurry": "Hurry (hold)"}

var pick: OptionButton
var key_label: Label
var waiting: PanelContainer  # "Press a key for ...", while rebinding
var _action := &""


func _ready() -> void:
	add_theme_constant_override(&"separation", 4)
	var l := Label.new()
	l.text = "Keys"
	add_child(l)
	pick = OptionButton.new()
	pick.focus_mode = FOCUS_NONE
	for a in actions():
		pick.add_item(NAMES.get(a, String(a)))
		pick.set_item_metadata(pick.item_count - 1, a)
	pick.item_selected.connect(func(_i: int): _show())
	add_child(pick)
	key_label = Label.new()
	add_child(key_label)
	var b := Button.new()
	b.text = "Rebind"
	b.focus_mode = FOCUS_NONE
	b.pressed.connect(func(): listen(picked()))
	add_child(b)
	waiting = PanelContainer.new()
	waiting.visible = false
	var w := Label.new()
	w.name = "Prompt"
	waiting.add_child(w)
	add_child(waiting)
	_show()


# The bindable actions: the input map's own (not the engine's ui_ ones), in the order NAMES lists them.
static func actions() -> Array[StringName]:
	var out: Array[StringName] = []
	for a: StringName in NAMES:
		if InputMap.has_action(a):
			out.append(a)
	for a in InputMap.get_actions():
		if not String(a).begins_with("ui_") and a not in out:
			out.append(a)
	return out


func picked() -> StringName:
	return pick.get_item_metadata(pick.selected) if pick.selected >= 0 else &""


# The key on an action, as it reads ("S", "Space"); "-" for none.
static func key_of(action: StringName) -> String:
	for e in InputMap.action_get_events(action):
		if e is InputEventKey:
			var k: Key = e.physical_keycode if e.physical_keycode else e.keycode
			return OS.get_keycode_string(k)
	return "-"


func _show() -> void:
	key_label.text = key_of(picked())


# Waits for the next key for `action`.
func listen(action: StringName) -> void:
	_action = action
	(waiting.get_node("Prompt") as Label).text = "Press a key for %s (Esc: keep %s)" % [NAMES.get(action, String(action)), key_of(action)]
	waiting.visible = true


func _input(e: InputEvent) -> void:
	if not _action or not (e is InputEventKey) or not e.pressed or e.echo:
		return
	get_viewport().set_input_as_handled()
	if e.physical_keycode != KEY_ESCAPE:
		bind(_action, e.physical_keycode)
	_action = &""
	waiting.visible = false
	_show()


# Binds `action` to physical key `k` alone, and saves the binds.
static func bind(action: StringName, k: Key) -> void:
	var ev := InputEventKey.new()
	ev.physical_keycode = k
	for e in InputMap.action_get_events(action):
		if e is InputEventKey:
			InputMap.action_erase_event(action, e)
	InputMap.action_add_event(action, ev)
	var cfg := ConfigFile.new()
	cfg.load(SAVE)
	cfg.set_value("keys", String(action), int(k))
	cfg.save(SAVE)


# The binds saved last time, back on the input map.
static func load_saved() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE) != OK:
		return
	for a in cfg.get_section_keys("keys"):
		if InputMap.has_action(a):
			var ev := InputEventKey.new()
			ev.physical_keycode = cfg.get_value("keys", a)
			for e in InputMap.action_get_events(a):
				if e is InputEventKey:
					InputMap.action_erase_event(a, e)
			InputMap.action_add_event(a, ev)
