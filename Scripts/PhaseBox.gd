class_name PhaseBox
extends PanelContainer

# The box at the top of the HUD that says what a phase of the battle is for: a title ("Preparing") and,
# under it, a smaller line for each thing the player can do in it ("Study: 1 ally, 2 foes or tiles").
# The phase supplies both (HUD.prep_uses for preparation); this only lays them out, and hides itself
# when it has no title, so a new use of a phase never edits the layout.

var title: Label
var lines: VBoxContainer


func _init() -> void:
	name = &"PhaseBox"
	theme_type_variation = &"Tip"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	grow_horizontal = Control.GROW_DIRECTION_BOTH
	position.y = 2
	var col := VBoxContainer.new()
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_theme_constant_override(&"separation", 0)
	add_child(col)
	title = Label.new()
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override(&"font_size", 9)
	title.add_theme_color_override(&"font_color", Color("#e8c547"))
	col.add_child(title)
	lines = VBoxContainer.new()
	lines.add_theme_constant_override(&"separation", 0)
	col.add_child(lines)
	hide()


# Show `heading` over one smaller line per entry of `sub` (blank ones skipped); no heading hides the box.
func show_lines(heading: String, sub: Array[String]) -> void:
	for l in lines.get_children():
		lines.remove_child(l)
		l.queue_free()
	if heading == "":
		hide()
		return
	title.text = heading
	for s in sub:
		if s == "":
			continue
		var l := Label.new()
		l.text = s
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.add_theme_font_size_override(&"font_size", 6)
		l.add_theme_color_override(&"font_color", Color("#9aa0ae").lerp(Color.WHITE, 0.4))
		lines.add_child(l)
	show()
	reset_size()


# What the box says now: [title, sublines], or [] hidden (for tests and screenshots).
func said() -> Array:
	if not visible:
		return []
	return [title.text, lines.get_children().map(func(l: Label): return l.text)]
