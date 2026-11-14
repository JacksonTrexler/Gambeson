class_name SkillGrid
extends Control

# A tab of a skill tree drawn as rows of tiers, growing from the bottom (tier 0: what the unit starts
# with) toward the top, inside a scroll box on the skills screen (SkillTree). Its centre and core sit in
# a column of their own on the left, then a column per root in its colour (the typed slot colours),
# each with its name along the bottom; lines run up from what a skill comes after. Each skill is an
# icon box: its glyph or initials (Skill.mark()) as a placeholder icon, its name in its tooltip and the
# footer. Learned skills are filled in, their rank in the corner; skills that could be learned now are
# outlined brightly (ringed in gold while there's a point to spend on them), the rest dimly; stubs are
# dashed. Hover a skill for its tooltip; click it to pick it (the skills screen's footer shows it). On
# a class's own tab, each of its choices of trees (Role.choices) is a darkened box headed "Pick up to x",
# holding each tree's tier 0 root: click one to choose it (chose), and the footer offers to pick it. The
# same face as SkillWheel, which still draws the Adventurer's own tab.

signal picked(s: Skill)
signal chose(c: TreeChoice, t: SkillTab)  # a tree's root in a choice's box was clicked

const BOX := Vector2(16.0, 16.0)  # a skill's icon box
const GAP := Vector2(5.0, 8.0)  # between boxes, across and up
const LEFT := 16.0  # the tier labels' gutter
const BASE := 12.0  # the root names under the bottom row
const PAD := 4.0
const HEAD := 10.0  # a choice's box reaches this far above its row, for its heading
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
var _head := 0.0  # room above the top row for a choice's heading, when a box sits on it
var selected_tree: SkillTab  # the tree root picked in a choice's box, if that's what the footer shows
var _hover_tree: SkillTab
var _entries: Dictionary = {}  # SkillTab -> [Rect2, its TreeChoice]: trees' roots in the choices' boxes
var _choice_boxes: Array = []  # [Rect2, heading, Color, the skill opening it or null]


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
	return PAD + _head + (_top - t) * (BOX.y + GAP.y)


func _tier(s: Skill) -> int:
	var t := tab.tier_of(s) if tab.general() else unit.tier(s)
	return maxi(t, 0)


func _layout() -> void:
	_boxes.clear()
	_tones.clear()
	_lines.clear()
	_labels.clear()
	_entries.clear()
	_choice_boxes.clear()
	if not unit or not tab:
		return
	var groups := []  # [Color, its skills, its root (null for the core), its name]
	var core: Array = ([tab.center] if tab.center else []) + tab.core.filter(func(s: Skill): return s != null)
	if not core.is_empty():
		groups.append([tab.tone() if tab.general() else CORE, core, null, "CORE" if not tab.general() else ""])
	for r: SkillRoot in tab.roots.filter(func(x: SkillRoot): return x != null):
		groups.append([SkillSlot.TYPES.get(r.tag, tab.tone() if tab.general() else CORE), r.skills(), r, r.name.to_upper()])
	var choices: Array = unit.role.choices.filter(func(c: TreeChoice): return c != null) if unit.role and tab.kind == "" and not tab.radial else []
	_top = 0
	for g in groups:
		for s: Skill in g[1]:
			_top = maxi(_top, _tier(s))
	for c: TreeChoice in choices:
		_top = maxi(_top, _choice_row(c))
	_head = HEAD if choices.any(func(c: TreeChoice): return _choice_row(c) == _top) else 0.0
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
		var name_w := 0.0
		if g[3]:
			_labels.append([Vector2(x, row_y(0) + BOX.y + 8.0), g[3], g[0]])
			name_w = get_theme_font(&"font").get_string_size(g[3], HORIZONTAL_ALIGNMENT_LEFT, -1, 5).x + 4.0
		var root: SkillRoot = g[2]
		if root:
			for s: Skill in g[1]:
				for a in root.branch(s).after:
					_lines.append([a, s, g[0]])
		x += maxf(wide * (BOX.x + GAP.x), name_w) + GAP.x  # wide enough for its name along the bottom
	for c: TreeChoice in choices:  # a box per choice, its trees' roots in a row
		var row := _choice_row(c)
		var cap := unit.pick_cap(c)
		var heading := "%s · %s" % [c.name.to_upper(), "LEARN " + c.by.name.to_upper() if c.by and unit.rank(c.by) == 0 else "PICK UP TO %d" % cap]
		var start := x + 3.0
		var offered: Array = unit.offered(c)  # a god slot: what its god offers (a Paladin sees only the Prowess its god suits)
		var burn := unit.burnable(c)
		if burn:
			offered.append(burn.duplicate())  # a Warlock's own patron, to burn a flex slot into (its own entry: drawn burned)
		if c.slot():  # a slot leaves out what's open through another (an Eros Paladin's Domain, Eros, from its Flex)
			offered = offered.filter(func(t: SkillTab): return not unit.open_tab(t) or unit.picks(c).has(t))
		for i in offered.size():
			var t: SkillTab = offered[i] if offered[i] not in _entries else offered[i].duplicate()  # a tree in two boxes: an entry in each
			_entries[t] = [Rect2(Vector2(start + i * (BOX.x + GAP.x), row_y(row)), BOX), c]
		var inner := offered.size() * (BOX.x + GAP.x) - GAP.x
		var heading_w := get_theme_font(&"font").get_string_size(heading, HORIZONTAL_ALIGNMENT_LEFT, -1, 5).x
		var tone: Color = offered[0].tone() if not offered.is_empty() else CORE
		_choice_boxes.append([Rect2(Vector2(x, row_y(row) - HEAD), Vector2(maxf(inner, heading_w) + 6.0, BOX.y + 13.0)), heading, tone, c.by])
		x += maxf(inner, heading_w) + 6.0 + GAP.x * 2.0
	custom_minimum_size = Vector2(x + PAD, row_y(0) + BOX.y + BASE + PAD)
	set_process(_entries.keys().any(func(t: SkillTab): return burn_entry(t) and unit.burned(t) > 0))  # a burned tree quivers


func _process(_delta: float) -> void:
	queue_redraw()


# The tier a choice's box sits on: 0, or just above the skill that opens it (a Wizard's Divinity).
func _choice_row(c: TreeChoice) -> int:
	return _tier(c.by) + 1 if c.by else 0


# The tree whose root is at p in a choice's box, or null.
func entry_at(p: Vector2) -> SkillTab:
	for t in _entries:
		if _entries[t][0].grow(1.0).has_point(p):
			return t
	return null


# A tree root's state, as a skill's: &"learned" (picked), &"open" (it could be picked now) or &"locked".
func entry_state(t: SkillTab) -> StringName:
	var why := unit.pick_missing(_entries[t][1], t)
	return &"learned" if why == "Picked" else (&"open" if why == "" else &"locked")


func _draw() -> void:
	if not unit or _boxes.is_empty():
		return
	var font := get_theme_font(&"font")
	for t in _top + 1:  # faint tier rows, numbered up the left
		var y := row_y(t)
		draw_line(Vector2(LEFT, y + BOX.y / 2.0), Vector2(size.x - PAD, y + BOX.y / 2.0), Color(1, 1, 1, 0.04), 1.0)
		draw_string(font, Vector2(2.0, y + BOX.y / 2.0 + 2.0), "T%d" % t, HORIZONTAL_ALIGNMENT_LEFT, -1, 5, Color(1, 1, 1, 0.3))
	for cb in _choice_boxes:  # each choice's box darkens the tree behind it, its heading saying how many
		var r: Rect2 = cb[0]
		draw_rect(r, Color(0, 0, 0, 0.38))
		draw_rect(r, Color(cb[2], 0.45), false, 1.0)
		draw_string(font, r.position + Vector2(3.0, 7.0), cb[1], HORIZONTAL_ALIGNMENT_LEFT, -1, 5, Color(cb[2].lightened(0.3), 0.85))
		if cb[3] and cb[3] in _boxes:  # up from the skill that opens it
			var from: Rect2 = _boxes[cb[3]]
			var lit := unit.rank(cb[3]) > 0
			draw_line(Vector2(from.get_center().x, from.position.y), Vector2(r.position.x + 8.0, r.end.y), Color(cb[2], 0.6 if lit else 0.22), 1.0)
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
	for t in _entries:
		_entry(t, _entries[t][0], font)


# Whether entry t is the tree its unit took up, offered in a burning choice (TreeChoice.burns): drawn
# darkened, with the cursed look of a disabled skill (SkillSlot: dimmed, a gentle quiver).
func burn_entry(t: SkillTab) -> bool:
	var b := unit.burnable(_entries[t][1]) if t in _entries else null
	return b != null and b.name == t.name and b.kind == t.kind


# A tree's tier 0 root in a choice's box: its glyph in its tree's colour, filled once picked; a burn's
# darkened, quivering once a slot is burned into it, its count in the corner.
func _entry(t: SkillTab, box: Rect2, font: Font) -> void:
	var tone := t.tone()
	var state := entry_state(t)
	var burns := burn_entry(t)
	var n := unit.burned(t) if burns else 0
	if burns:
		tone = tone.darkened(0.6)
		if n > 0:
			state = &"learned"
			var at := Time.get_ticks_msec() / 1000.0
			draw_set_transform(Vector2(sin(at * 23.0) * 0.6, sin(at * 17.0 + 1.3) * 0.35))
	var fill := tone.darkened(0.25) if state == &"learned" else FILL
	var edge := tone.lightened(0.35) if state == &"learned" else (tone if state == &"open" else Color(tone, 0.35))
	var ink := Color(0.95, 0.96, 0.98) if state == &"learned" else (tone.lightened(0.45) if state == &"open" else Color(tone.lightened(0.2), 0.5))
	draw_rect(box, fill)
	draw_rect(box, edge, false, 1.0)
	if state == &"open" and spend:
		draw_rect(box.grow(1.5), Color(GOLD, 0.75), false, 1.0)
	if t == selected_tree:
		draw_rect(box.grow(2.5), Color.WHITE, false, 1.0)
	elif t == _hover_tree:
		draw_rect(box.grow(2.5), Color(1, 1, 1, 0.45), false, 1.0)
	var text := t.mark()
	var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 6).x
	draw_string(font, box.get_center() + Vector2(-w / 2.0, 2.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 6, ink * Color(1, 1, 1, 0.25 if burns else 1.0))
	if n > 0:
		var count := "x%d" % n
		var cw := font.get_string_size(count, HORIZONTAL_ALIGNMENT_LEFT, -1, 4).x
		draw_string(font, box.end + Vector2(-cw - 1.0, -1.5), count, HORIZONTAL_ALIGNMENT_LEFT, -1, 4, Color(1, 1, 1, 0.5))
	draw_set_transform(Vector2.ZERO)


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
		for i in int(box.size.x / 4.0):  # dashed all round: not built yet
			var a := i * 4.0
			draw_line(box.position + Vector2(a, 0), box.position + Vector2(a + 2.0, 0), edge, 1.0)
			draw_line(Vector2(box.position.x + a, box.end.y), Vector2(box.position.x + a + 2.0, box.end.y), edge, 1.0)
			draw_line(box.position + Vector2(0, a), box.position + Vector2(0, a + 2.0), edge, 1.0)
			draw_line(Vector2(box.end.x, box.position.y + a), Vector2(box.end.x, box.position.y + a + 2.0), edge, 1.0)
	else:
		draw_rect(box, edge, false, 1.0)
	if state == &"open" and spend:
		draw_rect(box.grow(1.5), Color(GOLD, 0.75), false, 1.0)
	if s == selected:
		draw_rect(box.grow(2.5), Color.WHITE, false, 1.0)
	elif s == _hover:
		draw_rect(box.grow(2.5), Color(1, 1, 1, 0.45), false, 1.0)
	var tex := s.icon()
	if tex:
		draw_texture_rect(tex, box.grow(-2.0), false, ink)
	else:
		var text := s.mark()
		var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 6).x
		draw_string(font, box.get_center() + Vector2(-w / 2.0, 2.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 6, ink)
	var r := unit.base_rank(s)
	var numeral := Skill.roman(r) if r > 0 else ("?" if s.stub else "")
	if numeral:  # its rank in the corner (a stub's question mark)
		var nw := font.get_string_size(numeral, HORIZONTAL_ALIGNMENT_LEFT, -1, 4).x
		draw_string(font, box.end + Vector2(-nw - 1.0, -1.5), numeral, HORIZONTAL_ALIGNMENT_LEFT, -1, 4, GOLD if r > 0 else STUB)


func _gui_input(e: InputEvent) -> void:
	if not unit:
		return
	if e is InputEventMouseMotion:
		var s := skill_at(e.position)
		var t := entry_at(e.position)
		if s != _hover or t != _hover_tree:
			_hover = s
			_hover_tree = t
			mouse_default_cursor_shape = CURSOR_POINTING_HAND if s or t else CURSOR_ARROW
			queue_redraw()
	elif e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
		var s := skill_at(e.position)
		var t := entry_at(e.position)
		if s:
			picked.emit(s)
			accept_event()
		elif t:
			chose.emit(_entries[t][1], t)
			accept_event()


func _notification(what: int) -> void:
	if what == NOTIFICATION_MOUSE_EXIT and (_hover or _hover_tree):
		_hover = null
		_hover_tree = null
		queue_redraw()


func _get_tooltip(at: Vector2) -> String:
	var t := entry_at(at) if unit else null
	if t:
		var why := unit.pick_missing(_entries[t][1], t)
		if burn_entry(t):
			return "%s, burned · %d\nBurn a slot into your patron: an efficiency stack on its tree (+1 Affinity, every tier)%s" % [
					t.title(), unit.burned(t), "\n" + why if why else ""]
		return "%s · T0\n%s%s" % [t.title(), SkillTree.opens(t), "\n" + why if why else ""]
	var s := skill_at(at) if unit else null
	if not s:
		return ""
	var r := unit.base_rank(s)
	var why := unit.missing(s) if r == 0 and not s.stub else ""
	return "%s%s · T%d\n%s%s" % [s.title(), " " + Skill.roman(r) if r else "", unit.tier(s), s.markup(maxi(r, 1)), "\n" + why if why else ""]


# Its tooltips are Glossary markup, shown rich.
func _make_custom_tooltip(for_text: String) -> Object:
	return Glossary.tooltip(for_text)
