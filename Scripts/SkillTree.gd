class_name SkillTree
extends PanelContainer

# A unit's skill points and the skills on offer to it, a tab at a time along the top, coloured like
# browser tabs: its class's tree (Role.trees(): the Rogue's own and its Calling: Freedom; a class
# without a tree, its list of options), its species', what it's come to know, then on the far right the
# general trees it gets (Unit.general_trees()). Each shows growing from the bottom, tier 0, toward the
# top (SkillGrid), scrolling where it's tall - but the Adventurer's own, drawn as a wheel (SkillWheel).
# The skill picked there shows in the footer: its spec (target, range, AP, cost - the same order on
# every skill), what it does in Glossary markup (terms, offense and defense mods, rank in colour), what
# it needs, and its Unlock or Rank up button with the cost in a square, lit when it can be bought.
# Unlocking spends a point; raising a skill from rank r costs 1 + r^2 (the Guide explains; the "i").
# Each tab takes its tree's colour (SkillTab.tone()): its text in it, its background and the tree's
# behind it darker.

signal unlocked(skill: Skill)
signal raised(skill: Skill)
signal leveled  # the debug level-up

var unit: Unit
var picked: Skill  # the tree's pick, shown in the footer
var tab := 0  # the tab shown (tabs())
var can_spend := false
var _title := ""

const DARK := 0.72  # how much darker than its tab's colour the shown tab and its tree are

@onready var heading: Label = %SkillsTitle
@onready var points: Label = %SkillPoints
@onready var level_button: Button = %LevelUp
@onready var wheel: SkillWheel = %Wheel
@onready var grid: SkillGrid = %Grid
@onready var scroll: ScrollContainer = %TreeScroll
@onready var act: CostButton = %DetailButton


func _ready() -> void:
	%SkillsClose.pressed.connect(hide)
	level_button.pressed.connect(leveled.emit)
	wheel.picked.connect(pick)
	grid.picked.connect(pick)
	act.pressed.connect(_act)
	%DetailText.meta_clicked.connect(_term)


func open(u: Unit, title: String, spend: bool) -> void:
	if u != unit:
		picked = null
		tab = 0
	unit = u
	fill(title, spend)
	show()


# Its tabs, left to right: its class's (Unit.class_trees()), its species' and what it knows (where it has
# any), then its general trees.
func tabs() -> Array[SkillTab]:
	var out := unit.class_trees()
	var all := unit.sources()
	for pair in [[&"species", "Species", unit.race.name if unit.race else "Species"], [&"knowledge", "Knowledge", "Knowledge"]]:
		if not all[pair[0]].is_empty():
			var t := SkillTab.new()
			t.kind = pair[1]
			t.name = pair[2]
			t.core.assign(all[pair[0]])
			out.append(t)
	out.append_array(unit.general_trees())
	return out


# The tree view showing now: the wheel (the Adventurer's own tab) or the grid.
func view() -> Control:
	return wheel if wheel.visible else grid


func fill(title: String, spend: bool) -> void:
	_title = title
	can_spend = spend
	heading.text = "Skills · " + title
	var n := unit.skill_points
	points.text = "%d skill point%s" % [n, "" if n == 1 else "s"]
	points.add_theme_color_override(&"font_color", SkillSlot.GOLD if n > 0 else Color(1, 1, 1, 0.45))
	var all := tabs()
	tab = clampi(tab, 0, all.size() - 1)
	_fill_tabs(all)
	var t := all[tab]
	_tint(t.tone())
	wheel.visible = t.radial
	scroll.visible = not t.radial
	if t.radial:
		wheel.show_unit(unit, can_spend and n > 0, picked, t)
	else:
		grid.show_unit(unit, can_spend and n > 0, picked, t)
		_scroll_to_bottom()
	if not picked or picked not in view().skills():
		picked = _first_pick()
		wheel.selected = picked
		grid.selected = picked
	_show_pick()
	level_button.visible = can_spend and OS.is_debug_build()


# Trees grow from the bottom: open on tier 0, once the scroll box has taken the tree's new height (its
# bar's range settles a frame or two later).
func _scroll_to_bottom() -> void:
	for i in 2:
		await get_tree().process_frame
	scroll.scroll_vertical = int(scroll.get_v_scroll_bar().max_value)


# A tab per part of its trees, like a browser's: each in its tree's colour (general trees by category),
# the one shown bright and joined to the tree below; more than fit across wrap to another row (a Mage's).
func _fill_tabs(all: Array[SkillTab]) -> void:
	var box: HFlowContainer = %WheelTabs
	for c in box.get_children():
		box.remove_child(c)
		c.queue_free()
	var group := ButtonGroup.new()
	for i in all.size():
		var t := all[i]
		var b := Button.new()
		if not t.kind:
			b.text = "CLASS · " + t.name.to_upper()
		elif t.kind == t.name:
			b.text = t.name.to_upper()
		else:
			b.text = "%s · %s" % [t.kind.to_upper(), t.name.to_upper()]
		var tone := t.tone()
		for state in [&"normal", &"hover", &"pressed", &"hover_pressed"]:
			var on: bool = state in [&"pressed", &"hover_pressed"]
			var style := StyleBoxFlat.new()
			style.bg_color = tone.darkened(DARK) if on else tone.darkened(0.82 if state == &"normal" else 0.74)
			style.border_color = tone.darkened(0.35) if on else tone.darkened(0.65)
			style.set_border_width_all(1)
			style.border_width_bottom = 0
			style.corner_radius_top_left = 3
			style.corner_radius_top_right = 3
			style.content_margin_left = 5
			style.content_margin_right = 5
			style.content_margin_top = 1
			style.content_margin_bottom = 1
			b.add_theme_stylebox_override(state, style)
		b.toggle_mode = true
		b.button_group = group
		b.button_pressed = i == tab
		b.focus_mode = FOCUS_NONE
		b.add_theme_font_size_override(&"font_size", 6)
		b.add_theme_color_override(&"font_color", Color(tone, 0.6))
		b.add_theme_color_override(&"font_hover_color", Color(tone, 0.85))
		b.add_theme_color_override(&"font_pressed_color", tone)
		b.add_theme_color_override(&"font_hover_pressed_color", tone)
		b.tooltip_text = t.title()
		b.pressed.connect(show_tab.bind(i))
		box.add_child(b)


# The tree's background: the tab's colour, darker, joined to the tab above it.
func _tint(tone: Color) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = tone.darkened(DARK)
	style.border_color = tone.darkened(0.35)
	style.set_border_width_all(1)
	style.corner_radius_bottom_left = 3
	style.corner_radius_bottom_right = 3
	style.set_content_margin_all(2)
	(%Body as PanelContainer).add_theme_stylebox_override(&"panel", style)


func show_tab(i: int) -> void:
	if i != tab:
		tab = i
		picked = null
		fill(_title, can_spend)


# Shows s in the footer (a click on the tree).
func pick(s: Skill) -> void:
	picked = s
	wheel.selected = s
	grid.selected = s
	view().queue_redraw()
	_show_pick()


func _show_pick() -> void:
	var s := picked
	%DetailCol.visible = s != null
	if not s:
		return
	var r := unit.base_rank(s)
	%DetailName.text = s.name + (" " + Skill.roman(r) if r else "")
	%DetailState.text = state(s)
	_fill_spec(s)
	%DetailText.text = Glossary.rich(s.plan if s.stub else s.markup(maxi(r, 1), false))
	act.visible = not s.stub and (r == 0 or unit.can_raise(s))
	var cost := unit.raise_cost(s)
	var why := ""
	if not can_spend:
		why = "Only your party's skills can be chosen"
	elif r == 0 and unit.missing(s) != "":
		why = unit.missing(s)
	elif unit.skill_points < cost:
		why = "Needs %d skill point%s" % [cost, "" if cost == 1 else "s"]
	act.set_offer("Unlock" if r == 0 else "Rank %s" % Skill.roman(r + 1), cost)
	act.disabled = why != ""
	act.tooltip_text = why if why else ("Learn %s for %d point%s" % [s.name, cost, "" if cost == 1 else "s"] if r == 0
			else "Raise %s to rank %s for %d points" % [s.name, Skill.roman(r + 1), cost])


# Its spec as chips, the same order on every skill: its target, range, AP and cost.
func _fill_spec(s: Skill) -> void:
	var box: HBoxContainer = %DetailSpec
	for c in box.get_children():
		box.remove_child(c)
		c.queue_free()
	for part in s.spec():
		var l := RichTextLabel.new()
		l.bbcode_enabled = true
		l.fit_content = true
		l.autowrap_mode = TextServer.AUTOWRAP_OFF
		l.scroll_active = false
		l.add_theme_font_size_override(&"normal_font_size", 6)
		l.text = Glossary.rich(Skill.spec_part(part))
		l.meta_clicked.connect(_term)
		var chip := PanelContainer.new()
		var style := StyleBoxFlat.new()
		style.bg_color = Color(1, 1, 1, 0.06)
		style.set_corner_radius_all(2)
		style.content_margin_left = 3
		style.content_margin_right = 3
		chip.add_theme_stylebox_override(&"panel", style)
		chip.add_child(l)
		box.add_child(chip)


# A term clicked in the footer: the Guide's page for it.
func _term(meta: Variant) -> void:
	var id := StringName(String(meta).trim_prefix("term:"))
	get_tree().call_group(&"guide", &"open_guide", Glossary.page(id), id)


# Where s stands for this unit, in a line: its tier, then learned (or at its highest rank), or what it
# needs. Nothing more when it can be learned now: the button says so.
func state(s: Skill) -> String:
	var tier := "T%d" % unit.tier(s)
	if s.stub:
		return tier + " · Not built yet. " + s.waits()
	var r := unit.base_rank(s)
	if r > 0:
		return tier + (" · Learned" if unit.can_raise(s) else " · Highest rank")
	var why := unit.missing(s)
	return tier + (" · " + why if why else "")


func _act() -> void:
	if picked:
		if unit.base_rank(picked) == 0:
			unlocked.emit(picked)
		else:
			raised.emit(picked)


# The skill to show first: the first in the tree the unit could learn now, else the first it has.
func _first_pick() -> Skill:
	var all: Array = view().skills()
	for s: Skill in all:
		if not s.stub and unit.base_rank(s) == 0 and unit.missing(s) == "":
			return s
	for s: Skill in all:
		if unit.base_rank(s) > 0:
			return s
	return all[0] if not all.is_empty() else null
