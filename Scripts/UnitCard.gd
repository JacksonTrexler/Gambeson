class_name UnitCard
extends VBoxContainer

# The selected unit: portrait, name, what it is, chips for how it stands with the player, and a
# bar per thing that can be made out about it. HUD decides what's known; this only lays it out.

var _fills := {}  # Color -> StyleBoxFlat, one per bar colour

@onready var portrait: TextureRect = $Head/Portrait
@onready var title: Label = $Head/Names/Name
@onready var sub: Label = $Head/Names/Sub
@onready var chips: HFlowContainer = $Chips
@onready var rows: VBoxContainer = $Rows


# info: {name, sub, look: Texture2D, chips: [[text, Color]], rows: [[label, value, max, Color]]}.
# A row whose max is null shows its value as text alone. No info: a prompt to pick someone.
func set_info(info: Dictionary) -> void:
	portrait.texture = info.get("look")
	title.text = info.get("name", "")
	sub.text = info.get("sub", "Click a unit to select it")
	for c in chips.get_children() + rows.get_children():
		c.get_parent().remove_child(c)
		c.queue_free()
	for chip in info.get("chips", []):
		var l := Label.new()
		l.theme_type_variation = &"Chip"
		l.text = chip[0]
		l.add_theme_color_override(&"font_color", chip[1])
		chips.add_child(l)
	for r in info.get("rows", []):
		rows.add_child(_row(r[0], r[1], r[2], r[3]))


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
