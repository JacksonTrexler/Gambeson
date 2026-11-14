class_name Overlay
extends Node2D

# What the HUD marks on the battlefield, drawn between the map and the units: the hovered tile, the
# selected unit, the leader and its party, allies taking orders and how far orders reach, where the
# selected unit can walk and the move being planned, the foe a click would attack, an armed skill's
# reach and targets, tiles where something is only suspected, debris hiding units left, disturbed
# earth and the star lattice.
# Floating numbers and sleepers' "zZ" go on `top`, above the units; walking is animated here too.

const TILE := 32.0
const STEP_TIME := 0.07  # seconds per tile when a unit walks
const GOLD := Color("#e8c547")
const MOVE := Color("#7cc4ff")
const FOE := Color("#ff6b5e")
const FRIEND := Color("#6fdc8c")
const ZONE := Color("#5b3f9e")
const DUBIOUS := Color("#b39ddb")
const DEBRIS := Color("#c9a66b")
const EARTH := Color("#8a6a45")
const STAR := Color("#bfe3ff")  # the star lattice: panes and their links
const STARPOWER := Color("#ffe48a")
const SHADE := {&"safe": 0.16, &"unsure": 0.26, &"bad": 0.45}  # reach shading strength by ground
const LEAF := [Color("#7d9a3c"), Color("#a3842f"), Color("#5f7d33"), Color("#b0662e")]  # leaves' greens and browns
const GLASS := Color("#cfeaff")

var hud: HUD
var top: Node2D
var _recent: Dictionary[Unit, Array] = {}  # [time, how many] to stack numbers popping together
var _walks: Dictionary[Unit, Tween] = {}
var _walks_end := 0.0  # when the last walk started finishes, in seconds (walking_left())
var _dice := RandomNumberGenerator.new()  # spinning dice, kept off the global RNG


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
	var loud := hud.suspicious_marks or hud.high_contrast  # accessibility: a plain, bold ? on every suspicious tile
	for c in hud.dubious:
		_suspect_mark(c, DUBIOUS, pulse, loud)
	for c in hud.suspect:  # concealed ground it suspects is more than it looks: a translucent ? placeholder
		_suspect_mark(c, GOLD, pulse, loud)
	_layers(b)
	_lattice(b, pulse)
	for c in b.earthworks:
		_earth(c)
	for c in b.debris:
		if hud.tile_view(c).net >= 0:
			_debris(c)
	if hud.hover != HUD.NOWHERE:
		draw_rect(_rect(hud.hover, 0.5), Color(1, 1, 1, 0.3), false, 1.0)
	if mine:
		for u in b.members(cmd.faction()):
			if u != cmd.leader and cmd.can_order(u) and u not in cmd.ordered:
				draw_rect(_rect(u.cell, 2), Color(HUD.shade(cmd.faction().primary), 0.22))
		if sel and sel.faction == cmd.faction() and not hud.aiming():
			var at := _center(cmd.leader.cell)
			_ring(at, (cmd.reach() + 0.5) * TILE, Color(1, 1, 1, 0.3), false)
			_ring(at, (floorf(cmd.party_reach()) + 0.5) * TILE, Color(GOLD, 0.35), true)
	if not hud.reach.is_empty() and not hud.aiming():
		_draw_reach(sel)
	if not hud.plan.is_empty():
		_draw_plan(sel)
	if hud.charge != HUD.NOWHERE:
		_brackets(_rect(hud.charge, 1.5), Color(FOE, pulse), 6.0)
		draw_rect(_rect(hud.charge, 1.5), Color(FOE, 0.15))
	if sel and hud.aiming():
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
# A ? marking a suspicious tile: faint and tinted by default, bold and fuller in high-contrast /
# "mark suspicious" mode (an overlay stands in for a real grit texture for now).
func _suspect_mark(c: Vector2i, tint: Color, pulse: float, loud: bool) -> void:
	draw_rect(_rect(c, 2), Color(tint, 0.2 if loud else 0.12))
	var a := (0.85 if loud else 0.25) + 0.2 * pulse
	draw_string(ThemeDB.fallback_font, _center(c) + Vector2(-3, 4), "?", HORIZONTAL_ALIGNMENT_CENTER, 6,
			12 if loud else 10, Color(tint if not loud else Color(1, 1, 1), a))


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
			elif s.observes:  # what it would look over: wis mod (at least 1) + rank tiles around c
				_ring(_center(c), (maxi(sel.mod(&"wisdom"), 1) + sel.rank(s)) * TILE, Color(FRIEND, 0.4 + 0.3 * pulse), false)
				_brackets(_rect(c, 1.5), Color(FRIEND, pulse), 6.0)
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


# A few short strokes scattered low in the tile: debris (Battle.debris).
func _debris(c: Vector2i) -> void:
	var at := _center(c)
	for s in [[Vector2(-8, 6), 0.4], [Vector2(-1, 10), -0.6], [Vector2(6, 5), 1.1]]:
		var d := Vector2.from_angle(s[1]) * 2.5
		draw_line(at + s[0] - d, at + s[0] + d, Color(0, 0, 0, 0.45), 2.5)
		draw_line(at + s[0] - d, at + s[0] + d, DEBRIS, 1.2)


# Disturbed earth (Battle.earthworks): a brown wash, furrowed.
# The star lattice (Battle.panes, Battle.starpower): a faint pane on each tile, a line to each lattice
# neighbour side-on, and on each source a star that brightens as it fills.
func _lattice(b: Battle, pulse: float) -> void:
	for c in b.panes:
		draw_rect(_rect(c, 5), Color(STAR, 0.08))
		draw_rect(_rect(c, 5), Color(STAR, 0.3), false, 1.0)
	for c in b.panes.keys() + b.starpower.keys():
		for d in [Vector2i.RIGHT, Vector2i.DOWN]:
			if b.on_lattice(c + d):
				draw_line(_center(c), _center(c + d), Color(STAR, 0.35), 1.0)
	for c in b.starpower:
		var full := b.charge[c] / float(Battle.STAR_CAPACITY)
		var at := _center(c)
		var pts := PackedVector2Array()
		for i in 10:
			var rad := (7.0 if i % 2 == 0 else 3.0) * (0.8 + 0.2 * pulse)
			pts.append(at + Vector2.from_angle(-PI / 2 + i * PI / 5) * rad)
		draw_colored_polygon(pts, Color(STARPOWER, 0.35 + 0.55 * full))


# The layers laid over tiles, bottom up (Battle.layers): leaves as scattered leaves (faint while someone
# stands in them: they're see-through then), glass as a pale sheen, a cracked startile as cracked
# glass with its repair's progress. Starpanes and startiles are drawn as the lattice (_lattice()).
func _layers(b: Battle) -> void:
	for c: Vector2i in b.layers:
		var st: Array = b.layers[c]
		for i in range(st.size() - 1, -1, -1):
			var l: Battle.Layer = st[i]
			var t := l.terrain
			if t.pane or t.source:
				continue
			if t.unstable:
				_glass(c, l)
			elif t.obscures:
				_leaves(c, b.unit_at(c) != null)


func _leaves(c: Vector2i, trodden: bool) -> void:
	var r := _rect(c, 2)
	var seed := absi(c.x * 73856093 ^ c.y * 19349663)
	for i in 9:
		var k := (seed >> (i * 3)) & 0xFFFF
		var at := r.position + Vector2(fmod(k * 0.61, r.size.x), fmod(k * 0.37 + i * 7.3, r.size.y))
		var ang := float(k % 628) / 100.0
		var col: Color = LEAF[(k + i) % LEAF.size()]
		var pts := PackedVector2Array()
		for j in 6:
			var a := ang + j * TAU / 6.0
			pts.append(at + Vector2(cos(a) * 3.2, sin(a) * 1.6).rotated(ang))
		draw_colored_polygon(pts, Color(col, 0.28 if trodden else 0.85))


func _glass(c: Vector2i, l: Battle.Layer) -> void:
	var r := _rect(c, 1.5)
	draw_rect(r, Color(GLASS, 0.16))
	draw_rect(r, Color(GLASS, 0.5), false, 1.0)
	draw_line(r.position + Vector2(4, r.size.y * 0.45), r.position + Vector2(r.size.x * 0.45, 4), Color(1, 1, 1, 0.35), 1.0)
	if l.terrain.repairs_into != "":  # a cracked startile: cracks, and how far its mending's come
		var m := r.get_center()
		for d in [Vector2(-9, -6), Vector2(8, -8), Vector2(7, 9), Vector2(-8, 7)]:
			draw_polyline(PackedVector2Array([m, m + d * 0.5 + Vector2(d.y, -d.x) * 0.15, m + d]), Color(1, 1, 1, 0.55), 1.0)
		if l.repair_goal > 0:
			draw_arc(m, 5.0, -PI / 2, -PI / 2 + TAU * float(l.repairing) / l.repair_goal, 24, Color(STARPOWER, 0.9), 1.5)


func _earth(c: Vector2i) -> void:
	var r := _rect(c, 1)
	draw_rect(r, Color(EARTH, 0.22))
	for i in 3:
		var y := r.position.y + r.size.y * (i + 1) / 4.0
		draw_line(Vector2(r.position.x + 4, y), Vector2(r.end.x - 4, y - 3), Color(EARTH, 0.5), 1.0)


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
	var l := _float(u, text, col)
	var tw := l.create_tween()
	tw.tween_property(l, "position:y", l.position.y - 10, 0.9).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(l, "modulate:a", 0.0, 0.35).set_delay(0.55)
	tw.tween_callback(l.queue_free)


# A roll an ally's Self-evaluation saw, tallied up above u like the initiative dice: the d20
# spins, lands, then its mods take it to the total, which holds a moment and fades.
func float_roll(u: Unit, d20: int, total: int) -> void:
	var l := _float(u, "?", Color.WHITE)
	var tw := l.create_tween()
	tw.tween_method(func(_i: int): l.text = str(_dice.randi_range(1, 20)), 0, 8, 0.36)
	tw.tween_callback(func():
		l.text = str(d20)
		l.add_theme_color_override(&"font_color", GOLD if d20 == 20 else (FOE if d20 == 1 else Color.WHITE)))
	tw.tween_interval(0.3)
	tw.tween_callback(func(): l.text = "%d %s %d = %d" % [d20, "+" if total >= d20 else "-", absi(total - d20), total])
	tw.tween_interval(0.9)
	tw.tween_property(l, "modulate:a", 0.0, 0.35)
	tw.tween_callback(l.queue_free)


func _float(u: Unit, text: String, col: Color) -> Label:
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
	l.size = Vector2(64, 12)
	l.position = u.position + Vector2(-32, -30 - 8 * n)
	top.add_child(l)
	return l


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
	_walks_end = maxf(_walks_end, Time.get_ticks_msec() / 1000.0 + path.size() * STEP_TIME)


# Seconds till the last walk under way is done (HUD: units moving together).
func walking_left() -> float:
	return maxf(_walks_end - Time.get_ticks_msec() / 1000.0, 0.0)


func fade(u: Unit) -> void:
	u.create_tween().tween_property(u, "modulate:a", 0.0, 0.6)
