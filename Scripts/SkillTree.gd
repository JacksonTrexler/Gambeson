class_name SkillTree
extends PanelContainer

# A unit's skill points and the skills on offer to it, by where they come from: its class, its
# species, and what it's come to know (Unit.sources()). Each entry shows what it does; Unlock
# spends a point on it. Skills it has already show their rank.

signal unlocked(skill: Skill)
signal leveled  # the debug level-up

var unit: Unit

@onready var heading: Label = %SkillsTitle
@onready var points: Label = %SkillPoints
@onready var footer: Label = %SkillsHint
@onready var level_button: Button = %LevelUp


func _ready() -> void:
	%SkillsClose.pressed.connect(hide)
	level_button.pressed.connect(leveled.emit)


func open(u: Unit, title: String, can_spend: bool) -> void:
	unit = u
	fill(title, can_spend)
	show()


func fill(title: String, can_spend: bool) -> void:
	heading.text = "Skills · " + title
	var n := unit.skill_points
	points.text = "%d skill point%s" % [n, "" if n == 1 else "s"]
	points.add_theme_color_override(&"font_color", SkillSlot.GOLD if n > 0 else Color(1, 1, 1, 0.45))
	var all := unit.sources()
	var columns := [
		[%ClassTitle, %ClassList, &"class", "CLASS" + (" · " + unit.role.name.to_upper() if unit.role else "")],
		[%SpeciesTitle, %SpeciesList, &"species", "SPECIES" + (" · " + unit.race.name.to_upper() if unit.race else "")],
		[%KnowledgeTitle, %KnowledgeList, &"knowledge", "KNOWLEDGE"],
	]
	for col in columns:
		col[0].text = col[3]
		var list: VBoxContainer = col[1]
		for c in list.get_children():
			list.remove_child(c)
			c.queue_free()
		for s: Skill in all[col[2]]:
			list.add_child(_entry(s, can_spend and n > 0))
		if list.get_child_count() == 0:
			var none := Label.new()
			none.theme_type_variation = &"Muted"
			none.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			none.text = "Skills it learns of will show here." if col[2] == &"knowledge" else "Nothing on offer."
			list.add_child(none)
	footer.text = "A skill point comes with each level." if can_spend else "Only your party's skills can be chosen."
	level_button.visible = can_spend and OS.is_debug_build()


func _entry(s: Skill, can_unlock: bool) -> Control:
	var r := unit.rank(s)
	var card := PanelContainer.new()
	card.theme_type_variation = &"Card"
	card.tooltip_text = "%s\n%s" % [s.name, s.describe(maxi(r, 1))]
	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 4)
	card.add_child(row)
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
	title.clip_text = true
	text.add_child(title)
	var line := Label.new()
	line.theme_type_variation = &"Muted"
	line.text = ("Passive" + (" · toggle" if s.toggle else "")) if s.passive else s.summary()
	line.clip_text = true
	text.add_child(line)
	if r > 0:
		var known := Label.new()
		known.text = Skill.roman(r)
		known.add_theme_color_override(&"font_color", SkillSlot.GOLD)
		row.add_child(known)
	else:
		var b := Button.new()
		b.text = "Unlock"
		b.disabled = not can_unlock
		b.focus_mode = FOCUS_NONE
		b.size_flags_vertical = SIZE_SHRINK_CENTER
		b.tooltip_text = "Spend a skill point to learn %s" % s.name if can_unlock else "Needs a skill point"
		b.pressed.connect(func(): unlocked.emit(s))
		row.add_child(b)
		card.modulate.a = 1.0 if can_unlock else 0.7
	return card
