class_name SkillGrid
extends Control

# A tab of a skill tree drawn as rows of tiers, growing from the bottom (tier 0: what the unit starts
# with) toward the top, inside a scroll box on the skills screen (SkillTree). Its centre and core sit in
# a column of their own on the left, then a column per root in its colour (the typed slot colours),
# each with its name along the bottom; lines run up from what a skill comes after. Learned skills are
# filled in, their rank beside them; skills that could be learned now are outlined brightly (ringed in
# gold while there's a point to spend on them), the rest dimly; stubs are dashed. Hover a skill for its
# tooltip; click it to pick it (the skills screen's footer shows it). The same face as SkillWheel, which
# still draws the Adventurer's own tab.

signal picked(s: Skill)

const BOX := Vector2(70.0, 13.0)  # a skill's box
const GAP := Vector2(6.0, 9.0)  # between boxes, across and up
const LEFT := 16.0  # the tier labels' gutter
const BASE := 12.0  # the root names under the bottom row
const PAD := 4.0
const CORE := SkillWheel.CORE
const GOLD := SkillWheel.GOLD
const STUB := SkillWheel.STUB
const FILL := SkillWheel.FILL

var unit: Unit
var tab: SkillTab
var selected: Skill
var spend := false  # a point could be spent now: open skills get a gold ring
var _hover: Skill
var _boxes: Dictionary = {}  # Skill -> Rect2
var _tones: Dictionary = {}  # Skill -> Color
var _lines: Array = []  # [from Skill, to Skill, Color]
var _labels: Array = []  # [at: Vector2, text, Color]: root names along the bottom
var _top := 0  # the highest tier shown


func _init() -> void:
	mouse_filter = MOUSE_FILTER_STOP


func show_unit(u: Unit, can_spend: bool, pick: Skill, on: SkillTab) -> void:
	unit = u
	tab = on
	spend = can_spend
	selected = pick
	_layout()
	queue_redraw()


# &"learned", &"open" (it could be learned now, points aside), &"locked" or &"stub".
func state_of(s: Skill) -> StringName:
	if s.stub:
		return &"stub"
	if unit.base_rank(s) > 0:
		return &"learned"
	return &"open" if unit.missing(s) == "" else &"locked"


func skills() -> Array:
	return _boxes.keys()


func spot(s: Skill) -> Vector2:
	return _boxes[s].get_center() if s in _boxes else Vector2(-1, -1)


func skill_at(p: Vector2) -> Skill:
	for s in _boxes:
		if _boxes[s].grow(1.0).has_point(p):
			return s
	return null


# Where a tier's row sits: tier 0 at the bottom.
func row_y(t: int) -> float:
	return PAD + (_top - t) * (BOX.y + GAP.y)


func _tier(s: Skill) -> int:
	var t := tab.tier_of(s) if tab.general() else unit.tier(s)
	return maxi(t, 0)


func _layout() -> void:
	_boxes.clear()
	_tones.clear()
	_lines.clear()
	_labels.clear()
	if not unit or not tab:
		return
	var groups := []  # [Color, its skills, its root (null for the core), its name]
	var core: Array = ([tab.center] if tab.center else []) + tab.core.filter(func(s: Skill): return s != null)
	if not core.is_empty():
		groups.append([tab.tone() if tab.general() else CORE, core, null, "CORE" if not tab.general() else ""])
	for r: SkillRoot in tab.roots.filter(func(x: SkillRoot): return x != null):
		groups.append([SkillSlot.TYPES.get(r.tag, tab.tone() if tab.general() else CORE), r.skills(), r, r.name.to_upper()])
	_top = 0
	for g in groups:
		for s: Skill in g[1]:
			_top = maxi(_top, _tier(s))
	var x := LEFT + PAD
	for g in groups:
		var rows := {}  # tier -> its skills in this group
		for s: Skill in g[1]:
			rows.get_or_add(_tier(s), []).append(s)
		var wide := 1
		for t in rows:
			wide = maxi(wide, rows[t].size())
		for t in rows:
			for i in rows[t].size():
				var s: Skill = rows[t][i]
				_boxes[s] = Rect2(Vector2(x + i * (BOX.x + GAP.x), row_y(t)), BOX)
				_tones[s] = g[0]
		if g[3]:
			_labels.append([Vector2(x, row_y(0) + BOX.y + 8.0), g[3], g[0]])
		var root: SkillRoot = g[2]
		if root:
			for s: Skill in g[1]:
				for a in root.branch(s).after:
					_lines.append([a, s, g[0]])
		x += wide * (BOX.x + GAP.x) + GAP.x
	custom_minimum_size = Vector2(x + PAD, row_y(0) + BOX.y + BASE + PAD)


func _draw() -> void:
	if not unit or _boxes.is_empty():
		return
	var font := get_theme_font(&"font")
	for t in _top + 1:  # faint tier rows, numbered up the left
		var y := row_y(t)
		draw_line(Vector2(LEFT, y + BOX.y / 2.0), Vector2(size.x - PAD, y + BOX.y / 2.0), Color(1, 1, 1, 0.04), 1.0)
		draw_string(font, Vector2(2.0, y + BOX.y / 2.0 + 2.0), "T%d" % t, HORIZONTAL_ALIGNMENT_LEFT, -1, 5, Color(1, 1, 1, 0.3))
	for l in _lines:
		if l[0] in _boxes and l[1] in _boxes:
			var lit := unit.base_rank(l[1]) > 0
			var a: Rect2 = _boxes[l[0]]
			var b: Rect2 = _boxes[l[1]]
			draw_line(Vector2(a.get_center().x, a.position.y), Vector2(b.get_center().x, b.end.y), Color(l[2], 0.6 if lit else 0.22), 1.0)
	for lab in _labels:
		draw_string(font, lab[0], lab[1], HORIZONTAL_ALIGNMENT_LEFT, -1, 5, Color(lab[2].lightened(0.3), 0.8))
	for s in _boxes:
		_node(s, _boxes[s], _tones[s], font)


func _node(s: Skill, box: Rect2, tone: Color, font: Font) -> void:
	var state := state_of(s)
	var fill := FILL
	var edge := Color(tone, 0.35)
	var ink := Color(tone.lightened(0.2), 0.5)
	match state:
		&"learned":
			fill = tone.darkened(0.25)
			edge = tone.lightened(0.35)
			ink = Color(0.95, 0.96, 0.98)
		&"open":
			edge = tone
			ink = tone.lightened(0.45)
		&"stub":
			edge = Color(STUB, 0.7)
			ink = STUB
	draw_rect(box, fill)
	if state == &"stub":
		for i in int(box.size.x / 6.0):  # dashed: not built yet
			draw_line(box.position + Vector2(i * 6.0, 0), box.position + Vector2(i * 6.0 + 3.0, 0), edge, 1.0)
			draw_line(Vector2(box.position.x + i * 6.0, box.end.y), Vector2(box.position.x + i * 6.0 + 3.0, box.end.y), edge, 1.0)
	else:
		draw_rect(box, edge, false, 1.0)
	if state == &"open" and spend:
		draw_rect(box.grow(1.5), Color(GOLD, 0.75), false, 1.0)
	if s == selected:
		draw_rect(box.grow(2.5), Color.WHITE, false, 1.0)
	elif s == _hover:
		draw_rect(box.grow(2.5), Color(1, 1, 1, 0.45), false, 1.0)
	var r := unit.base_rank(s)
	var numeral := Skill.roman(r) if r > 0 else ("?" if s.stub else "")
	var nw := font.get_string_size(numeral, HORIZONTAL_ALIGNMENT_LEFT, -1, 5).x
	draw_string(font, box.position + Vector2(3.0, box.size.y / 2.0 + 2.0), s.name, HORIZONTAL_ALIGNMENT_LEFT, box.size.x - nw - 8.0, 6, ink)
	if numeral:
		draw_string(font, Vector2(box.end.x - nw - 2.0, box.position.y + box.size.y / 2.0 + 2.0), numeral, HORIZONTAL_ALIGNMENT_LEFT, -1, 5, GOLD if r > 0 else STUB)


func _gui_input(e: InputEvent) -> void:
	if not unit:
		return
	if e is InputEventMouseMotion:
		var s := skill_at(e.position)
		if s != _hover:
			_hover = s
			mouse_default_cursor_shape = CURSOR_POINTING_HAND if s else CURSOR_ARROW
			queue_redraw()
	elif e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
		var s := skill_at(e.position)
		if s:
			picked.emit(s)
			accept_event()


func _notification(what: int) -> void:
	if what == NOTIFICATION_MOUSE_EXIT and _hover:
		_hover = null
		queue_redraw()


func _get_tooltip(at: Vector2) -> String:
	var s := skill_at(at) if unit else null
	if not s:
		return ""
	var r := unit.base_rank(s)
	var why := unit.missing(s) if r == 0 and not s.stub else ""
	return "%s%s · T%d\n%s%s" % [s.name, " " + Skill.roman(r) if r else "", unit.tier(s), s.markup(maxi(r, 1)), "\n" + why if why else ""]


# Its tooltips are Glossary markup, shown rich.
func _make_custom_tooltip(for_text: String) -> Object:
	return Glossary.tooltip(for_text)
