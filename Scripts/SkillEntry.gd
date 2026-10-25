class_name SkillEntry
extends PanelContainer

# A skill in the spellbook: rank numeral, name and a one-line summary (the full text is the
# tooltip). Skills with an active part drag onto the hotbar; toggled passives switch from here.

signal switched(skill: Skill)

var skill: Skill
var draggable := false


func _init(s: Skill, rank: int, on: bool, can_drag: bool, can_switch: bool) -> void:
	skill = s
	draggable = can_drag and s.fits_bar()
	theme_type_variation = &"Card"
	tooltip_text = "%s %s\n%s" % [s.name, Skill.roman(rank), s.describe(rank)]
	if draggable:
		tooltip_text += "\nDrag onto the hotbar."
		mouse_default_cursor_shape = CURSOR_DRAG
	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 4)
	add_child(row)
	var numeral := Label.new()
	numeral.text = Skill.roman(rank)
	numeral.custom_minimum_size.x = 14
	numeral.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	numeral.add_theme_color_override(&"font_color", SkillSlot.GOLD)
	row.add_child(numeral)
	var stripe := ColorRect.new()
	stripe.color = SkillSlot.tint(s)
	stripe.custom_minimum_size = Vector2(1.5, 0)
	stripe.mouse_filter = MOUSE_FILTER_IGNORE
	row.add_child(stripe)
	var text := VBoxContainer.new()
	text.add_theme_constant_override(&"separation", 0)
	text.size_flags_horizontal = SIZE_EXPAND_FILL
	row.add_child(text)
	var title := Label.new()
	title.text = s.name
	text.add_child(title)
	var line := Label.new()
	line.theme_type_variation = &"Muted"
	line.text = s.summary()
	text.add_child(line)
	if s.passive and s.toggle:
		var b := Button.new()
		b.text = "On" if on else "Off"
		b.toggle_mode = true
		b.button_pressed = on
		b.disabled = not can_switch
		b.focus_mode = FOCUS_NONE
		b.custom_minimum_size.x = 20
		b.size_flags_vertical = SIZE_SHRINK_CENTER
		b.tooltip_text = "Switch %s on or off" % s.name if can_switch else "Only on your turn, for units taking orders"
		b.pressed.connect(func(): switched.emit(skill))
		row.add_child(b)


func _get_drag_data(_at: Vector2) -> Variant:
	if not draggable:
		return null
	set_drag_preview(SkillSlot.chip(skill, SkillSlot.theme_of(self)))
	return {skill = skill, from = -1}
