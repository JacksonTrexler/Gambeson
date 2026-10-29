class_name SkillTree
extends PanelContainer

# A unit's skill points and the skills on offer to it, by where they come from: its class, its
# species, and what it's come to know (Unit.sources()). A class with a skill tree (the Adventurer)
# shows it as a wheel (SkillWheel): the skill picked there shows beside it - what it does, what
# learning it takes - with its Unlock or Rank up button. Other classes list their skills, as do
# species and knowledge. Unlocking spends a point; raising a skill from rank r costs 1 + r^2.

signal unlocked(skill: Skill)
signal raised(skill: Skill)
signal leveled  # the debug level-up

const LIST_SIZE := Vector2(300, 220)
const TREE_SIZE := Vector2(404, 232)

var unit: Unit
var picked: Skill  # the wheel's pick, shown in the detail column
var can_spend := false

@onready var heading: Label = %SkillsTitle
@onready var points: Label = %SkillPoints
@onready var footer: Label = %SkillsHint
@onready var level_button: Button = %LevelUp
@onready var wheel: SkillWheel = %Wheel
@onready var act: Button = %DetailButton


func _ready() -> void:
	%SkillsClose.pressed.connect(hide)
	level_button.pressed.connect(leveled.emit)
	wheel.picked.connect(pick)
	act.pressed.connect(_act)


func open(u: Unit, title: String, spend: bool) -> void:
	if u != unit:
		picked = null
	unit = u
	fill(title, spend)
	show()


func fill(title: String, spend: bool) -> void:
	can_spend = spend
	heading.text = "Skills · " + title
	var n := unit.skill_points
	points.text = "%d skill point%s" % [n, "" if n == 1 else "s"]
	points.add_theme_color_override(&"font_color", SkillSlot.GOLD if n > 0 else Color(1, 1, 1, 0.45))
	var tree := unit.role != null and unit.role.has_tree()
	_resize(TREE_SIZE if tree else LIST_SIZE)
	%ClassCol.visible = not tree
	%WheelCol.visible = tree
	%DetailCol.visible = tree
	var all := unit.sources()
	var columns := [
		[%SpeciesTitle, %SpeciesList, &"species", "SPECIES" + (" · " + unit.race.name.to_upper() if unit.race else "")],
		[%KnowledgeTitle, %KnowledgeList, &"knowledge", "KNOWLEDGE"],
	]
	var role_name := " · " + unit.role.name.to_upper() if unit.role else ""
	if tree:
		%WheelTitle.text = "CLASS" + role_name
	else:
		columns.push_front([%ClassTitle, %ClassList, &"class", "CLASS" + role_name])
	for col in columns:
		col[0].text = col[3]
		var list: VBoxContainer = col[1]
		for c in list.get_children():
			list.remove_child(c)
			c.queue_free()
		for s: Skill in all[col[2]]:
			list.add_child(_entry(s))
		if list.get_child_count() == 0:
			var none := Label.new()
			none.theme_type_variation = &"Muted"
			none.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			none.text = "Skills it learns of will show here." if col[2] == &"knowledge" else "Nothing on offer."
			list.add_child(none)
	if tree:
		wheel.show_unit(unit, can_spend and n > 0, picked)
		if not picked or picked not in wheel.skills():
			picked = _first_pick()
			wheel.selected = picked
		_show_pick()
	footer.text = "A skill point comes with each level; rank r to r + 1 costs 1 + r² points." if can_spend \
			else "Only your party's skills can be chosen."
	level_button.visible = can_spend and OS.is_debug_build()


# Shows s in the detail column (a click on the wheel).
func pick(s: Skill) -> void:
	picked = s
	wheel.selected = s
	wheel.queue_redraw()
	_show_pick()


func _show_pick() -> void:
	var s := picked
	%DetailCol.visible = s != null
	if not s:
		return
	var r := unit.rank(s)
	%DetailName.text = s.name + (" " + Skill.roman(r) if r else "")
	%DetailState.text = state(s)
	%DetailText.text = s.plan if s.stub else s.describe(maxi(r, 1))
	act.visible = not s.stub and (r == 0 or unit.can_raise(s))
	var cost := unit.raise_cost(s)
	var why := ""
	if not can_spend:
		why = "Only your party's skills can be chosen"
	elif r == 0 and unit.missing(s) != "":
		why = unit.missing(s)
	elif unit.skill_points < cost:
		why = "Needs %d skill point%s" % [cost, "" if cost == 1 else "s"]
	act.text = ("Unlock" if r == 0 else "Rank %s" % Skill.roman(r + 1)) + " · %d pt%s" % [cost, "" if cost == 1 else "s"]
	act.disabled = why != ""
	act.tooltip_text = why if why else ("Learn %s" % s.name if r == 0 else "Raise %s to rank %s" % [s.name, Skill.roman(r + 1)])


# Where s stands for this unit, in a line: its tier, then learned (and at what rank), learnable now,
# or what it needs.
func state(s: Skill) -> String:
	var tier := "Tier %d · " % unit.tier(s)
	if s.stub:
		return tier + "Not built yet. " + s.waits()
	var r := unit.rank(s)
	if r > 0:
		return tier + "Learned, rank %s%s" % [Skill.roman(r), "" if unit.can_raise(s) else " (its highest)"]
	var why := unit.missing(s)
	return tier + (why if why else "Can be learned now")


func _act() -> void:
	if picked:
		if unit.rank(picked) == 0:
			unlocked.emit(picked)
		else:
			raised.emit(picked)


# The skill to show first: the first on the wheel the unit could learn now, else the first it has.
func _first_pick() -> Skill:
	var all := wheel.skills()
	for s: Skill in all:
		if not s.stub and unit.rank(s) == 0 and unit.missing(s) == "":
			return s
	for s: Skill in all:
		if unit.rank(s) > 0:
			return s
	return all[0] if not all.is_empty() else null


func _resize(to: Vector2) -> void:
	offset_left = -to.x / 2.0
	offset_right = to.x / 2.0
	offset_top = -to.y / 2.0
	offset_bottom = to.y / 2.0


func _entry(s: Skill) -> Control:
	var r := unit.rank(s)
	var card := PanelContainer.new()
	card.theme_type_variation = &"Card"
	card.tooltip_text = "%s · tier %d\n%s" % [s.name, unit.tier(s), s.describe(maxi(r, 1))]
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
		if unit.can_raise(s):
			var cost := unit.raise_cost(s)
			var up := _button("+", can_spend and unit.skill_points >= cost)
			up.tooltip_text = "Raise %s to rank %s: %d point%s" % [s.name, Skill.roman(r + 1), cost, "" if cost == 1 else "s"]
			up.pressed.connect(func(): raised.emit(s))
			row.add_child(up)
	else:
		var can := can_spend and unit.skill_points > 0 and unit.missing(s) == ""
		var b := _button("Unlock", can)
		b.tooltip_text = "Spend a skill point to learn %s" % s.name if can else (unit.missing(s) if unit.missing(s) else "Needs a skill point")
		b.pressed.connect(func(): unlocked.emit(s))
		row.add_child(b)
		card.modulate.a = 1.0 if can else 0.7
	return card


func _button(text: String, enabled: bool) -> Button:
	var b := Button.new()
	b.text = text
	b.disabled = not enabled
	b.focus_mode = FOCUS_NONE
	b.size_flags_vertical = SIZE_SHRINK_CENTER
	return b
