class_name SkillSlot
extends Button

# One hotbar slot: its number key, the skill in it (or nothing), and that skill's state. Skills are
# dragged in from the spellbook or another slot; dragging one off the bar, or right-clicking it,
# empties the slot. Clicking it (or its number key) uses it - see HUD.use_slot().

signal dropped(index: int, skill: Skill, from: int)  # from: the slot it came from, -1 the spellbook
signal cleared(index: int)

# Stripe colour by a skill's first tag that has one.
const TINTS := {
	&"magic": Color("#a179f2"), &"dark": Color("#7b6fe0"), &"physical": Color("#c9ced8"),
	&"earth": Color("#c8a165"), &"sound": Color("#4fc1b0"), &"sight": Color("#62b6e8"),
	&"light": Color("#f3da72"),
}
const PLAIN_TINT := Color("#8a90a0")
const GOLD := Color("#e8c547")
const ON := Color("#3fbf4f")

var index := 0
var skill: Skill
var rank := 0
var armed := false  # waiting for a target
var on := false  # a toggled passive that's switched on
var usable := true  # the unit can use it now (takes orders, can pay)
var editable := true  # skills can be dragged in and out
var _dragging := false


static func tint(s: Skill) -> Color:
	for t in s.tags:
		if t in TINTS:
			return TINTS[t]
	return PLAIN_TINT


# A small label for dragging a skill around.
static func chip(s: Skill, th: Theme) -> Control:
	var p := PanelContainer.new()
	p.theme = th
	p.theme_type_variation = &"Tip"
	var l := Label.new()
	l.text = s.name
	l.add_theme_color_override(&"font_color", tint(s).lerp(Color.WHITE, 0.4))
	p.add_child(l)
	return p


func _init() -> void:
	custom_minimum_size = Vector2(0, 13)
	focus_mode = FOCUS_NONE
	gui_input.connect(_on_gui_input)


func set_state(i: int, s: Skill, r: int, is_armed: bool, is_on: bool, can_use: bool, can_edit: bool) -> void:
	index = i
	skill = s
	rank = r
	armed = is_armed
	on = is_on
	usable = can_use
	editable = can_edit
	tooltip_text = ("[%s] %s %s\n%s" % [_key(), s.name, Skill.roman(r), s.describe(r)]) if s else \
			"[%s] Empty - drag a skill here from the spellbook (B)" % _key()
	queue_redraw()


func _draw() -> void:
	var font := get_theme_font(&"font")
	var fs := 6
	var mid := (size.y - font.get_height(fs)) / 2.0 + font.get_ascent(fs)
	draw_rect(Rect2(2, 2, 9, size.y - 4), Color(1, 1, 1, 0.07))
	draw_string(font, Vector2(2, mid), _key(), HORIZONTAL_ALIGNMENT_CENTER, 9, fs, Color(1, 1, 1, 0.55))
	if not skill:
		draw_string(font, Vector2(15, mid), "empty", HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(1, 1, 1, 0.22))
		return
	var dim := 1.0 if usable and (on or not skill.passive) else 0.45
	draw_rect(Rect2(12, 2, 1.5, size.y - 4), tint(skill) * Color(1, 1, 1, dim))
	var right := size.x - 3
	var numeral := Skill.roman(rank)
	var nw := font.get_string_size(numeral, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	draw_string(font, Vector2(right - nw, mid), numeral, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, GOLD * Color(1, 1, 1, dim))
	right -= nw + 2
	if skill.passive:
		draw_circle(Vector2(right - 2, size.y / 2.0), 1.6, ON if on else Color(1, 1, 1, 0.25))
		right -= 6
	draw_string(font, Vector2(16, mid + 0.5), skill.name, HORIZONTAL_ALIGNMENT_LEFT, right - 16, 7,
			Color(0.92, 0.93, 0.96, dim))
	if armed:
		draw_rect(Rect2(Vector2(0.5, 0.5), size - Vector2.ONE), GOLD, false, 1.0)


func _key() -> String:
	return str((index + 1) % 10)


func _get_drag_data(_at: Vector2) -> Variant:
	if not skill or not editable:
		return null
	_dragging = true
	set_drag_preview(chip(skill, theme_of(self)))
	return {skill = skill, from = index}


func _can_drop_data(_at: Vector2, data: Variant) -> bool:
	return editable and data is Dictionary and data.get("skill") is Skill and data.skill.fits_bar()


func _drop_data(_at: Vector2, data: Variant) -> void:
	dropped.emit(index, data.skill, data.from)


func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END and _dragging:
		_dragging = false
		if not get_viewport().gui_is_drag_successful():
			cleared.emit(index)  # dropped off the bar


func _on_gui_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_RIGHT and skill and editable:
		cleared.emit(index)
		accept_event()


# The theme a control draws with: its own, or the nearest ancestor's (for drag previews, which
# live outside the HUD).
static func theme_of(n: Node) -> Theme:
	while n:
		if n is Control and n.theme:
			return n.theme
		n = n.get_parent()
	return null
