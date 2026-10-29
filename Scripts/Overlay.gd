class_name Overlay
extends Node2D

# What the HUD marks on the battlefield, drawn between the map and the units: the hovered tile, the
# selected unit, the leader and its party, allies taking orders and how far orders reach, where the
# selected unit can walk and the move being planned, the foe a click would attack, an armed skill's
# reach and targets, and tiles where something is only suspected.
# Floating numbers and sleepers' "zZ" go on `top`, above the units; walking is animated here too.

const TILE := 32.0
const STEP_TIME := 0.07  # seconds per tile when a unit walks
const GOLD := Color("#e8c547")
const MOVE := Color("#7cc4ff")
const FOE := Color("#ff6b5e")
const FRIEND := Color("#6fdc8c")
const ZONE := Color("#5b3f9e")
const DUBIOUS := Color("#b39ddb")
const SHADE := {&"safe": 0.16, &"unsure": 0.26, &"bad": 0.45}  # reach shading strength by ground

var hud: HUD
var top: Node2D
var _recent: Dictionary[Unit, Array] = {}  # [time, how many] to stack numbers popping together
var _walks: Dictionary[Unit, Tween] = {}


func _process(_delta: float) -> void:
	queue_redraw()  # selection pulses
	if top:
		top.queue_redraw()


func _draw() -> void:
	if not hud or not hud.command:
		return
	var b := hud.battle
	var cmd := hud.command
	var sel := hud.selected
	var pulse := 0.6 + 0.4 * sin(Time.get_ticks_msec() / 1000.0 * 4.0)
	var mine := hud.my_turn()
	for c in hud.dubious:
		draw_rect(_rect(c, 2), Color(DUBIOUS, 0.12))
		draw_string(ThemeDB.fallback_font, _center(c) + Vector2(-3, 4), "?", HORIZONTAL_ALIGNMENT_CENTER, 6, 10,
				Color(DUBIOUS, 0.25 + 0.2 * pulse))
	if hud.hover != HUD.NOWHERE:
		draw_rect(_rect(hud.hover, 0.5), Color(1, 1, 1, 0.3), false, 1.0)
	if mine:
		for u in b.members(cmd.faction()):
			if u != cmd.leader and cmd.can_order(u) and u not in cmd.ordered:
				draw_rect(_rect(u.cell, 2), Color(HUD.shade(cmd.faction().primary), 0.22))
		if sel and sel.faction == cmd.faction() and not hud.armed:
			var at := _center(cmd.leader.cell)
			_ring(at, (cmd.reach() + 0.5) * TILE, Color(1, 1, 1, 0.3), false)
			_ring(at, (floorf(cmd.party_reach()) + 0.5) * TILE, Color(GOLD, 0.35), true)
	if not hud.reach.is_empty():
		_draw_reach(sel)
	if not hud.plan.is_empty():
		_draw_plan(sel)
	if hud.charge != HUD.NOWHERE:
		_brackets(_rect(hud.charge, 1.5), Color(FOE, pulse), 6.0)
		draw_rect(_rect(hud.charge, 1.5), Color(FOE, 0.15))
	if sel and hud.armed:
		_draw_targeting(sel, hud.armed, pulse)
	for c in hud.traps:
		_caltrop(c, GOLD if hud.traps[c] else FOE)
	for u in cmd.party:
		_badge(u.cell, false)
	if cmd.leader.is_alive():
		_badge(cmd.leader.cell, true)
	if sel and sel.is_alive():
		_brackets(_rect(sel.cell, 0.5), Color(GOLD if hud.known(sel) else Color.WHITE, pulse), 7.0)



# Tiles the selected unit expects to reach, shaded by how the ground is judged (HUD.ground()),
# with a line around the area.
func _draw_reach(sel: Unit) -> void:
	var inside := func(c: Vector2i) -> bool: return c in hud.reach or c == sel.cell
	var sides := [[Vector2i.UP, 0, 1], [Vector2i.RIGHT, 1, 2], [Vector2i.DOWN, 2, 3], [Vector2i.LEFT, 3, 0]]
	for c in hud.reach:
		var r := _rect(c)
		var kind: StringName = hud.grounds.get(c, &"safe")
		draw_rect(r.grow(-1), Color(HUD.GROUND[kind], SHADE[kind]))
		var corners := [r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]
		for s in sides:
			if not inside.call(c + s[0]):
				draw_line(corners[s[1]], corners[s[2]], Color(MOVE, 0.7), 1.0)


func _draw_plan(sel: Unit) -> void:
	var path: Array = hud.plan.path
	var ln: Array = hud.plan.line
	var prev := _center(sel.cell)
	for i in ln.size():
		var p := _center(ln[i])
		var kept := i < path.size()
		draw_line(prev, p, Color(MOVE, 0.85) if kept else Color(FOE, 0.3), 1.5 if kept else 1.0)
		prev = p
	for i in ln.size():
		var kept := i < path.size()
		draw_circle(_center(ln[i]), 2.0 if kept else 1.5, MOVE if kept else Color(FOE, 0.45))
	if not path.is_empty():
		_brackets(_rect(path[-1], 2), MOVE, 5.0)


func _draw_targeting(sel: Unit, s: Skill, pulse: float) -> void:
	var b := hud.battle
	var col := GOLD if s.dual else (FOE if s.hostile else FRIEND)
	if s.on_tile():
		_ring(_center(sel.cell), b.area_reach(sel, s) * TILE, Color(GOLD, 0.6), true)
		var c := hud.hover
		if c != HUD.NOWHERE and hud.why_not(sel, s, c) == "":
			if s.lays:
				_brackets(_rect(c, 1.5), Color(GOLD, pulse), 6.0)
				_caltrop(c, Color(GOLD, 0.5 + 0.3 * pulse))
			else:
				var levels := b.zone_levels(sel.rank(s), c)
				for at in levels:
					draw_rect(_rect(at, 1), Color(ZONE, 0.18 + 0.12 * levels[at]))
		return
	_ring(_center(sel.cell), b.skill_range(sel, s) * TILE, Color(col, 0.55), true)
	for u in hud.marked:
		var mark := (FOE if hud.foe(u) else FRIEND) if s.dual else col
		_brackets(_rect(u.cell, 1.5), Color(mark, pulse), 6.0)
		if u.cell == hud.hover:
			draw_rect(_rect(u.cell, 1.5), Color(mark, 0.18))


# The tile's centre in this node's space (the map sits at the battle's origin, as this does).
func _center(c: Vector2i) -> Vector2:
	return hud.battle.map.position + hud.battle.map.map_to_local(c)


func _rect(c: Vector2i, inset := 0.0) -> Rect2:
	var half := TILE / 2.0 - inset
	return Rect2(_center(c) - Vector2(half, half), Vector2(half, half) * 2.0)


func _brackets(r: Rect2, col: Color, arm := 6.0, w := 1.5) -> void:
	var corners := [r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]
	var dirs := [Vector2(1, 1), Vector2(-1, 1), Vector2(-1, -1), Vector2(1, -1)]
	for i in 4:
		draw_line(corners[i], corners[i] + Vector2(dirs[i].x * arm, 0), col, w)
		draw_line(corners[i], corners[i] + Vector2(0, dirs[i].y * arm), col, w)


func _ring(at: Vector2, radius: float, col: Color, dashed: bool) -> void:
	if not dashed:
		draw_arc(at, radius, 0.0, TAU, 72, col, 1.0)
		return
	var n := maxi(int(TAU * radius / 5.0), 8)
	for i in range(0, n, 2):
		draw_arc(at, radius, TAU * i / n, TAU * (i + 1) / n, 3, col, 1.0)


# Drawn on `top`, above the units: a "zZ" by the bars of each unit seen to be asleep.
func draw_top() -> void:
	if not hud:
		return
	var font := ThemeDB.fallback_font
	var col := Color(HUD.SLEEP, 0.6 + 0.4 * sin(Time.get_ticks_msec() / 1000.0 * 3.0))
	for u in hud.sleepers:
		var at := u.position + Vector2(13, -TILE / 2.0 + 4)
		for z in [["z", Vector2.ZERO, 6], ["Z", Vector2(3, -4), 8]]:
			top.draw_string_outline(font, at + z[1], z[0], HORIZONTAL_ALIGNMENT_LEFT, -1, z[2], 2, Color(0, 0, 0, 0.7))
			top.draw_string(font, at + z[1], z[0], HORIZONTAL_ALIGNMENT_LEFT, -1, z[2], col)


# A known trap: a little four-spiked caltrop low in the tile (gold for your side's own).
func _caltrop(c: Vector2i, col: Color) -> void:
	var at := _center(c) + Vector2(0, 9)
	for i in 4:
		var d := Vector2.from_angle(TAU * i / 4.0 + PI / 4.0) * 4.0
		draw_line(at - d, at + d, Color(0, 0, 0, 0.5), 2.5)
	for i in 4:
		var d := Vector2.from_angle(TAU * i / 4.0 + PI / 4.0) * 4.0
		draw_line(at, at + d, col, 1.5)
	draw_circle(at, 1.5, col)


# A diamond in the tile's top-left corner: filled for the leader, hollow for party members.
func _badge(c: Vector2i, filled: bool) -> void:
	var o := _rect(c).position + Vector2(5, 5)
	var pts := PackedVector2Array([o + Vector2(0, -3), o + Vector2(3, 0), o + Vector2(0, 3), o + Vector2(-3, 0)])
	if filled:
		draw_colored_polygon(pts, GOLD)
	pts.append(pts[0])
	draw_polyline(pts, Color(0, 0, 0, 0.6) if filled else GOLD, 1.0)


# A number (or word) that rises off a unit and fades. Ones that pop together stack upward.
func float_text(u: Unit, text: String, col: Color) -> void:
	var now := Time.get_ticks_msec() / 1000.0
	var n := 0
	if u in _recent and now - _recent[u][0] < 0.5:
		n = _recent[u][1] + 1
	_recent[u] = [now, n]
	var l := Label.new()
	l.text = text
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override(&"font_size", 8)
	l.add_theme_color_override(&"font_color", col)
	l.add_theme_color_override(&"font_outline_color", Color(0, 0, 0, 0.9))
	l.add_theme_constant_override(&"outline_size", 3)
	l.size = Vector2(48, 12)
	l.position = u.position + Vector2(-24, -30 - 8 * n)
	top.add_child(l)
	var tw := l.create_tween()
	tw.tween_property(l, "position:y", l.position.y - 10, 0.9).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(l, "modulate:a", 0.0, 0.35).set_delay(0.55)
	tw.tween_callback(l.queue_free)


# Battle.traveled: the unit's already on its new cell; walk its sprite there tile by tile.
func walk(u: Unit, from: Vector2i, path: Array[Vector2i]) -> void:
	if u in _walks and _walks[u].is_valid():
		_walks[u].kill()
	var map := hud.battle.map
	u.position = map.map_to_local(from)
	var tw := u.create_tween()
	for c in path:
		tw.tween_property(u, "position", map.map_to_local(c), STEP_TIME)
	_walks[u] = tw


func fade(u: Unit) -> void:
	u.create_tween().tween_property(u, "modulate:a", 0.0, 0.6)
