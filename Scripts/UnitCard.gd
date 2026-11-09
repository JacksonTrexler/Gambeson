class_name UnitCard
extends VBoxContainer

# The selected unit: portrait, name, what it is, chips for how it stands with the player, an icon
# per effect on it, and a bar per thing that can be made out about it. HUD decides what's known;
# this only lays it out.

var _fills := {}  # Color -> StyleBoxFlat, one per bar colour
var face: Label  # a persona's stand-in sprite (";)"), over the portrait in place of its look
var effects: HFlowContainer  # what's timed on it, an icon each, under the chips
var note: Label  # an insightful read of how true its presentation is, under the rows

@onready var portrait: TextureRect = $Head/Portrait
@onready var title: Label = $Head/Names/Name
@onready var sub: Label = $Head/Names/Sub
@onready var chips: HFlowContainer = $Chips
@onready var rows: VBoxContainer = $Rows


func _ready() -> void:
	face = Label.new()
	face.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	face.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	face.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	face.add_theme_font_size_override(&"font_size", 12)
	portrait.add_child(face)
	effects = HFlowContainer.new()
	effects.add_theme_constant_override(&"h_separation", 2)
	effects.add_theme_constant_override(&"v_separation", 2)
	add_child(effects)
	move_child(effects, chips.get_index() + 1)
	note = Label.new()
	note.theme_type_variation = &"Muted"
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(note)


# info: {name, sub, look: Texture2D, face: String, shape: bool, chips: [[text, Color]], effects:
# [[mark, Color, tooltip, roll]], rows: [[label, value, max, Color]], note: String}. face: text
# standing in for the look (a persona's claimed name). shape: its side can't be told (the card's
# "Unknown" chip says so).
# roll: the roll an effect was put on with, in its icon's top right ("" when unknown). A row whose
# max is null shows its value as text alone. note: a line of prose under the rows (an insightful
# read). No info: nothing selected.
func set_info(info: Dictionary) -> void:
	face.text = info.get("face", "")
	portrait.texture = null if face.text else info.get("look")
	portrait.modulate = Color.WHITE
	title.text = info.get("name", "")
	sub.text = info.get("sub", "Nothing selected")
	for c in chips.get_children() + effects.get_children() + rows.get_children():
		c.get_parent().remove_child(c)
		c.queue_free()
	for chip in info.get("chips", []):
		var l := Label.new()
		l.theme_type_variation = &"Chip"
		l.text = chip[0]
		l.add_theme_color_override(&"font_color", chip[1])
		chips.add_child(l)
	for e in info.get("effects", []):
		effects.add_child(_effect(e[0], e[1], e[2], e[3]))
	effects.visible = effects.get_child_count() > 0
	for r in info.get("rows", []):
		rows.add_child(_row(r[0], r[1], r[2], r[3]))
	note.text = info.get("note", "")
	note.visible = note.text != ""


# An effect's icon: its mark in its colour, what it does as a tooltip, and the roll it was put on
# with (Self-evaluation) small in the top right.
func _effect(mark: String, color: Color, tip: String, roll: String) -> Control:
	var icon := PanelContainer.new()
	icon.add_theme_stylebox_override(&"panel", get_theme_stylebox(&"normal", &"Chip"))
	icon.tooltip_text = tip
	var h := HBoxContainer.new()
	h.add_theme_constant_override(&"separation", 1)
	h.mouse_filter = MOUSE_FILTER_IGNORE
	icon.add_child(h)
	var l := Label.new()
	l.text = mark
	l.add_theme_font_size_override(&"font_size", 5)
	l.add_theme_color_override(&"font_color", color)
	h.add_child(l)
	if roll:
		var n := Label.new()
		n.text = roll
		n.add_theme_font_size_override(&"font_size", 4)
		n.add_theme_color_override(&"font_color", SkillSlot.GOLD)
		n.size_flags_vertical = SIZE_SHRINK_BEGIN
		h.add_child(n)
	return icon


func _row(label: String, value: Variant, top: Variant, color: Color) -> Control:
	var h := HBoxContainer.new()
	h.add_theme_constant_override(&"separation", 3)
	var k := Label.new()
	k.theme_type_variation = &"Muted"
	k.text = label
	k.custom_minimum_size.x = 13
	h.add_child(k)
	if top == null:
		var t := Label.new()
		t.theme_type_variation = &"Muted"
		t.text = str(value)
		t.add_theme_color_override(&"font_color", color)
		h.add_child(t)
		return h
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.max_value = maxf(top, 0.001)
	bar.value = value
	bar.custom_minimum_size = Vector2(0, 3)
	bar.size_flags_horizontal = SIZE_EXPAND_FILL
	bar.size_flags_vertical = SIZE_SHRINK_CENTER
	bar.mouse_filter = MOUSE_FILTER_IGNORE
	bar.add_theme_stylebox_override(&"fill", _fill(color))
	h.add_child(bar)
	var n := Label.new()
	n.theme_type_variation = &"Muted"
	n.text = "%s/%s" % [Skill.num(value), Skill.num(top)]
	n.custom_minimum_size.x = 22
	n.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	h.add_child(n)
	return h


func _fill(c: Color) -> StyleBoxFlat:
	if c not in _fills:
		var box := get_theme_stylebox(&"fill", &"ProgressBar").duplicate() as StyleBoxFlat
		box.bg_color = c
		_fills[c] = box
	return _fills[c]
