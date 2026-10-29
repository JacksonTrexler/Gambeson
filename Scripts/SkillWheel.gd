class_name SkillWheel
extends Control

# A class's skill tree drawn as a wheel (the Adventurer's): one skill at the very centre, a ring of
# core skills around it (what the class starts with, and first choices open at any time), and its
# roots reaching out from there - Magic, Martial and Specialist, each in its own colour and sector
# (the typed slot colours), every skill further out than what it needs and the capstone on the rim.
# Learned skills are filled in, their rank beside them; skills that could be learned now are
# outlined brightly (ringed in gold while there's a point to spend on them), the rest dimly. Stubs,
# skills not built yet, show the open question they wait on ("?3"). Hover a skill for its tooltip;
# click it to pick it, and the skills screen shows what it does and what it takes (SkillTree).

signal picked(s: Skill)

const R := 6.0  # a skill's circle
const RING := 22.0  # the core ring's radius
const CORE := Color("#c9ced8")  # the centre and core ring
const GOLD := Color("#e8c547")
const STUB := Color("#7d8291")
const FILL := Color(0.075, 0.082, 0.106)
const GAP := 0.14  # radians left between sectors

var unit: Unit
var selected: Skill
var spend := false  # a point could be spent now: open skills get a gold ring
var _hover: Skill
var _spots: Dictionary = {}  # Skill -> Vector2, its circle's centre
var _tones: Dictionary = {}  # Skill -> Color: its root's, or CORE
var _lines: Array = []  # [from: Vector2, to: Vector2, Color, the Skill it leads to]
var _hubs: Array = []  # [at: Vector2, label, Color]
var _sectors: Array = []  # [from angle, to angle, Color, rim radius]


func _init() -> void:
	mouse_filter = MOUSE_FILTER_STOP
	custom_minimum_size = Vector2(196, 176)
	resized.connect(func():
		_layout()
		queue_redraw())


func show_unit(u: Unit, can_spend: bool, pick: Skill) -> void:
	unit = u
	spend = can_spend
	selected = pick
	_layout()
	queue_redraw()


# &"learned", &"open" (it could be learned now, points aside), &"locked" or &"stub".
func state_of(s: Skill) -> StringName:
	if s.stub:
		return &"stub"
	if unit.rank(s) > 0:
		return &"learned"
	return &"open" if unit.missing(s) == "" else &"locked"


# Every skill on the wheel, centre and core ring first.
func skills() -> Array:
	return _spots.keys()


func spot(s: Skill) -> Vector2:
	return _spots.get(s, Vector2(-1, -1))


func skill_at(p: Vector2) -> Skill:
	for s in _spots:
		if p.distance_to(_spots[s]) <= R + 1.5:
			return s
	return null


func _layout() -> void:
	_spots.clear()
	_tones.clear()
	_lines.clear()
	_hubs.clear()
	_sectors.clear()
	var role := unit.role if unit else null
	if not role:
		return
	var mid := size / 2.0
	var outer := minf(size.x, size.y) / 2.0 - R - 1.0
	var hub_r := RING + R + 14.0
	if role.center:
		_put(role.center, mid, CORE)
	var core: Array[Skill] = []
	for x in role.innate:
		if x and x.skill and x.skill not in core:
			core.append(x.skill)
	for s in role.core:
		if s and s not in core:
			core.append(s)
	var top := -PI / 2.0
	for i in core.size():  # half a step round, so the roots' spokes run between them
		_put(core[i], mid + Vector2.from_angle(top + TAU * (i + 0.5) / core.size()) * RING, CORE)
	var roots := role.roots.filter(func(r: SkillRoot): return r != null)
	var sector := TAU / maxi(roots.size(), 1)
	for k in roots.size():
		var root: SkillRoot = roots[k]
		var tone: Color = SkillSlot.TYPES.get(root.tag, CORE)
		var centre := top + sector * k
		var half := sector / 2.0 - GAP
		_sectors.append([centre - half, centre + half, tone, outer + R + 1.0])
		var hub := mid + Vector2.from_angle(centre) * hub_r
		_hubs.append([hub, root.name.to_upper(), tone])
		_lines.append([mid + Vector2.from_angle(centre) * (RING + R + 1.0), hub, tone, null])
		var deep := maxi(root.max_depth(), 1)
		var step := (outer - hub_r) / deep
		var order := root.skills()
		order.sort_custom(func(a: Skill, b: Skill): return root.depth(a) < root.depth(b))
		var angles := {}
		var first := order.filter(func(s: Skill): return root.depth(s) == 1)
		for i in first.size():
			angles[first[i]] = centre - half + 2.0 * half * (i + 0.5) / first.size()
		var fans := {}  # skills sharing what they come after fan out around it
		for s: Skill in order:
			if s in angles:
				continue
			var b := root.branch(s)
			var base := centre
			if not b.after.is_empty():
				base = b.after.reduce(func(sum: float, x: Skill): return sum + angles.get(x, centre), 0.0) / b.after.size()
			fans.get_or_add(snappedf(base, 0.001), []).append(s)
		for base in fans:
			var group: Array = fans[base]
			for i in group.size():
				angles[group[i]] = base + (i - (group.size() - 1) / 2.0) * 0.22
		for s: Skill in order:
			var at := mid + Vector2.from_angle(angles[s]) * (hub_r + step * root.depth(s))
			_put(s, at, tone)
			var b := root.branch(s)
			if b.after.is_empty() and b.needs == 0:
				_lines.append([hub, at, tone, s])
			for x in b.after:
				if x in _spots:
					_lines.append([_spots[x], at, tone, s])


func _put(s: Skill, at: Vector2, tone: Color) -> void:
	_spots[s] = at
	_tones[s] = tone


func _draw() -> void:
	if not unit or _spots.is_empty():
		return
	var mid := size / 2.0
	var font := get_theme_font(&"font")
	for sec in _sectors:  # faint wedges, with the rim the capstones sit on
		var pts := PackedVector2Array()
		var inner := RING + R + 4.0
		for i in 17:
			pts.append(mid + Vector2.from_angle(lerpf(sec[0], sec[1], i / 16.0)) * inner)
		for i in 17:
			pts.append(mid + Vector2.from_angle(lerpf(sec[1], sec[0], i / 16.0)) * sec[3])
		draw_colored_polygon(pts, Color(sec[2], 0.05))
		draw_arc(mid, sec[3] - R - 1.0, sec[0], sec[1], 24, Color(sec[2], 0.18), 1.0)
	draw_arc(mid, RING, 0.0, TAU, 48, Color(CORE, 0.12), 1.0)
	for l in _lines:
		var lit: bool = l[3] == null or unit.rank(l[3]) > 0
		draw_line(l[0], l[1], Color(l[2], 0.6 if lit else 0.2), 1.0)
	for h in _hubs:
		var w := font.get_string_size(h[1], HORIZONTAL_ALIGNMENT_LEFT, -1, 5).x
		var box := Rect2(h[0] - Vector2(w / 2.0 + 2.0, 4.0), Vector2(w + 4.0, 8.0))
		draw_rect(box, FILL)
		draw_rect(box, Color(h[2], 0.5), false, 1.0)
		draw_string(font, Vector2(box.position.x + 2.0, h[0].y + 2.0), h[1], HORIZONTAL_ALIGNMENT_LEFT, -1, 5, h[2].lightened(0.35))
	for s in _spots:
		_node(s, _spots[s], _tones[s], font)


func _node(s: Skill, at: Vector2, tone: Color, font: Font) -> void:
	var state := state_of(s)
	var fill := FILL
	var edge := Color(tone, 0.35)
	var ink := Color(tone.lightened(0.2), 0.45)
	match state:
		&"learned":
			fill = tone.darkened(0.1)
			edge = tone.lightened(0.35)
			ink = Color(0.05, 0.05, 0.07)
		&"open":
			edge = tone
			ink = tone.lightened(0.45)
		&"stub":
			edge = Color(STUB, 0.7)
			ink = STUB
	draw_circle(at, R, fill)
	if state == &"stub":
		for i in 8:  # dashed: not built yet
			draw_arc(at, R, TAU * i / 8.0, TAU * (i + 0.5) / 8.0, 3, edge, 1.0)
	else:
		draw_arc(at, R, 0.0, TAU, 24, edge, 1.0)
	if state == &"open" and spend:
		draw_arc(at, R + 1.5, 0.0, TAU, 24, Color(GOLD, 0.75), 1.0)
	if s == selected:
		draw_arc(at, R + 2.5, 0.0, TAU, 24, Color.WHITE, 1.0)
	elif s == _hover:
		draw_arc(at, R + 2.5, 0.0, TAU, 24, Color(1, 1, 1, 0.45), 1.0)
	var text := s.mark()
	var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 5).x
	draw_string(font, at + Vector2(-w / 2.0, 2.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 5, ink)
	var r := unit.rank(s)
	if r > 0:
		draw_string(font, at + Vector2(R - 1.0, R + 2.5), Skill.roman(r), HORIZONTAL_ALIGNMENT_LEFT, -1, 4, GOLD)


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
	var r := unit.rank(s)
	var why := unit.missing(s) if r == 0 and not s.stub else ""
	return "%s%s · tier %d\n%s%s" % [s.name, " " + Skill.roman(r) if r else "", unit.tier(s), s.describe(maxi(r, 1)), "\n" + why if why else ""]
