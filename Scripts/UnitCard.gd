class_name UnitCard
extends VBoxContainer

# The selected unit: portrait, name, what it is, chips for how it stands with the player, an icon
# per effect on it, and a bar per thing that can be made out about it. HUD decides what's known;
# this only lays it out.

var _fills := {}  # Color -> StyleBoxFlat, one per bar colour
var face: Label  # a persona's stand-in sprite (";)"), over the portrait in place of its look
var effects: HFlowContainer  # what's timed on it, an icon each, under the chips
var trims: HBoxContainer  # a little banner per item it wears with a trim (Item.trim()), over the portrait's foot
var note: Label  # an insightful read of how true its presentation is, under the rows
var _shown: Variant = null  # the info last shown (set_info())

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
	trims = HBoxContainer.new()
	trims.add_theme_constant_override(&"separation", 1)
	trims.set_anchors_and_offsets_preset(PRESET_BOTTOM_LEFT)
	trims.grow_vertical = GROW_DIRECTION_BEGIN
	portrait.add_child(trims)
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
# [[mark (text, or a Texture2D drawn in the colour), Color, tooltip, roll]], rows: [[label, value, max, Color]], note: String,
# trims: [[Color, tooltip]] (the items it's seen wearing with a trim: a banner each)}. face: text
# standing in for the look (a persona's claimed name). shape: its side can't be told (the card's
# "Unknown" chip says so). silhouette: only a black shape of it shows (Read.silhouette()).
# roll: the roll an effect was put on with, in its icon's top right ("" when unknown). A row whose
# max is null shows its value as text alone. note: a line of prose under the rows (an insightful
# read). No info: nothing selected. The same info again changes nothing, so a tooltip being hovered
# isn't pulled out from under the pointer and its delay (1 s, project settings) isn't restarted.
func set_info(info: Dictionary) -> void:
	if _shown is Dictionary and info == _shown:
		return
	_shown = info.duplicate(true)
	face.text = info.get("face", "")
	portrait.texture = null if face.text else info.get("look")
	portrait.modulate = Color(0.03, 0.03, 0.03) if info.get("silhouette", false) else Color.WHITE
	title.text = info.get("name", "")
	sub.text = info.get("sub", "Nothing selected")
	for c in chips.get_children() + effects.get_children() + rows.get_children() + trims.get_children():
		c.get_parent().remove_child(c)
		c.queue_free()
	for chip in info.get("chips", []):
		var l := Label.new()
		l.theme_type_variation = &"Chip"
		l.text = chip[0]
		l.add_theme_color_override(&"font_color", chip[1])
		chips.add_child(l)
	for t in info.get("trims", []):
		trims.add_child(trim_mark(t[0], t[1]))
	for e in info.get("effects", []):
		effects.add_child(_effect(e[0], e[1], e[2], e[3]))
	effects.visible = effects.get_child_count() > 0
	for r in info.get("rows", []):
		rows.add_child(_row(r[0], r[1], r[2], r[3], r[4] if r.size() > 4 else null))
	note.text = info.get("note", "")
	note.visible = note.text != ""


# An item's trim as a little banner (Item.draw_banner()), its tooltip the item: the unit card, the
# character sheet. A clear colour: an empty space the same size, so rows line up.
static func trim_mark(c: Color, tip: String) -> Control:
	var m := Control.new()
	m.custom_minimum_size = Vector2(7, 10)
	m.tooltip_text = tip
	m.mouse_filter = MOUSE_FILTER_PASS
	if c.a > 0.0:
		m.draw.connect(func() -> void: Item.draw_banner(m, Vector2(0.5, 0.5), c, Color("#1d1a12")))
	return m


# An effect's icon: its mark in its colour, what it does as a tooltip, and the roll it was put on
# with (Self-evaluation) small in the top right.
func _effect(mark: Variant, color: Color, tip: String, roll: String) -> Control:
	var icon := PanelContainer.new()
	icon.add_theme_stylebox_override(&"panel", get_theme_stylebox(&"normal", &"Chip"))
	icon.tooltip_text = tip
	var h := HBoxContainer.new()
	h.add_theme_constant_override(&"separation", 1)
	h.mouse_filter = MOUSE_FILTER_IGNORE
	icon.add_child(h)
	if mark is Texture2D:  # a status with art of its own (Suspicion's eye: Icons/Effects/)
		var pic := TextureRect.new()
		pic.texture = mark
		pic.modulate = color
		pic.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
		pic.mouse_filter = MOUSE_FILTER_IGNORE
		h.add_child(pic)
	else:
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


# drain: what a planned action would consume of it (HUD.drain()): a pulsing segment at the end of its
# bar; "?": it can't be foreseen - the row goes muted and a ? flashes after the number.
func _row(label: String, value: Variant, top: Variant, color: Color, drain: Variant = null) -> Control:
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
	if drain is float or drain is int:
		var seg := ColorRect.new()  # the part about to be spent
		seg.color = Color(1, 1, 1, 0.9)
		seg.mouse_filter = MOUSE_FILTER_IGNORE
		seg.anchor_left = clampf((value - drain) / maxf(top, 0.001), 0.0, 1.0)
		seg.anchor_right = clampf(value / maxf(top, 0.001), 0.0, 1.0)
		seg.anchor_bottom = 1.0
		seg.name = &"Drain"
		bar.add_child(seg)
		_pulse(seg, 0.25)
	elif drain == "?":
		k.modulate = Color(1, 1, 1, 0.55)
		bar.modulate = Color(1, 1, 1, 0.55)
		n.modulate = Color(1, 1, 1, 0.55)
		var q := Label.new()
		q.theme_type_variation = &"Muted"
		q.text = "?"
		q.name = &"Unsure"
		h.add_child(q)
		_pulse(q, 0.1)
	return h


# Flashes a control between full and `low` opacity, for as long as it lives.
func _pulse(c: CanvasItem, low: float) -> void:
	var tw := c.create_tween().set_loops()
	tw.tween_property(c, "modulate:a", low, 0.45)
	tw.tween_property(c, "modulate:a", 1.0, 0.45)


func _fill(c: Color) -> StyleBoxFlat:
	if c not in _fills:
		var box := get_theme_stylebox(&"fill", &"ProgressBar").duplicate() as StyleBoxFlat
		box.bg_color = c
		_fills[c] = box
	return _fills[c]
